// ========================================================================================================
// File Name			: scalar_fpdivsqrt.sv
// Author				: HYF
// How to Contact		: hyf_sysu@qq.com
// Created Time    		: May 11th 2024, 09:35:44
// Last Modified Time   : 2024-05-27 @ 09:36:06
// ========================================================================================================
// Description	:
// A Scalar Floating Point Divider/Sqrt based on Minimally Redundant Radix-4 SRT Algorithm.
// It supports f16/f32/f64.

// ========================================================================================================
// ========================================================================================================
// Copyright (C) 2024, HYF. All Rights Reserved.
// ========================================================================================================
// This file is licensed under BSD 3-Clause License.
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
// Redistribution and use in source and binary forms, with or without modification, 
// are permitted provided that the following conditions are met:
// 
// 1. Redistributions of source code must retain the above copyright notice, this list of 
// conditions and the following disclaimer.
// 
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of 
// conditions and the following disclaimer in the documentation and/or other materials provided 
// with the distribution.
// 
// 3. Neither the name of the copyright holder nor the names of its contributors may be used 
// to endorse or promote products derived from this software without specific prior written permission.
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES 
// OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL 
// THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, 
// EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE 
// GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND 
// ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, 
// EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
// ========================================================================================================

// include some definitions here

module scalar_fpdivsqrt #(
	// Put some parameters here, which can be changed by other modules
	parameter FDIV_QDS_ARCH = 2,
	// TODO: Now we only support "UF_BEFORE_ROUNDING"
	parameter UF_AFTER_ROUNDING = 0
)(
	input  logic 			start_valid_i,
	output logic 			start_ready_o,
	input  logic 			flush_i,
	// [0]: f16
	// [1]: f32
	// [2]: f64
	input  logic [ 3-1:0] 	fp_format_i,
	input  logic 			is_fdiv_i,
	// f16: src should be put in opa[15:0]/opb[15:0], opa[63:16]/opb[63:16] will be ignored
	// f32: src should be put in opa[31:0]/opb[31:0], opa[63:32]/opb[63:32] will be ignored
	// f64: src should be put in opa[63:0]/opb[63:0]
	// fsqrt: src should be put in opa, opb will be ignored
	input  logic [64-1:0] 	opa_i,
	input  logic [64-1:0] 	opb_i,
	input  logic [ 3-1:0] 	rm_i,

	output logic 			finish_valid_o,
	input  logic 			finish_ready_i,
	input  logic 			busy_o,
	output logic [64-1:0] 	fpdivsqrt_res_o,
	output logic [ 5-1:0] 	fflags_o,

	input  logic 			clk,
	input  logic 			rst_n
);

// ================================================================================================================================================
// (local) parameters begin

localparam F64_FRAC_W = 52 + 1;
localparam F32_FRAC_W = 23 + 1;
localparam F16_FRAC_W = 10 + 1;

localparam F64_EXP_W = 11;
localparam F32_EXP_W = 8;
localparam F16_EXP_W = 5;

// F64: We would get 4 * 13 + 2 = 54-bit root -> We need 54 + 2 = 56-bit REM.
localparam FSQRT_F64_REM_W = 2 + 54;
// F32: We would get 4 * 6 + 2 = 26-bit root -> We need 26 + 2 = 28-bit REM.
localparam FSQRT_F32_REM_W = 2 + 26;
// F16: We would get 4 * 3 + 2 = 14-bit root -> We need 14 + 2 = 16-bit REM.
localparam FSQRT_F16_REM_W = 2 + 14;

// F64: The root could be 55-bit in the early stage {1.00, 52'b0}, but finally the significant digits must be 54. (0.1, 53'bx)
localparam F64_FULL_ROOT_W = FSQRT_F64_REM_W - 1;
localparam F64_ROOT_W = F64_FULL_ROOT_W - 1;
// F32: The root could be 27-bit in the early stage {1.00, 24'b0}, but finally the significant digits must be 26. (0.1, 25'bx)
localparam F32_FULL_ROOT_W = FSQRT_F32_REM_W - 1;
localparam F32_ROOT_W = F32_FULL_ROOT_W - 1;
// F16: The root could be 15-bit in the early stage {1.00, 12'b0}, but finally the significant digits must be 14. (0.1, 13'bx)
localparam F16_FULL_ROOT_W = FSQRT_F16_REM_W - 1;
localparam F16_ROOT_W = F16_FULL_ROOT_W - 1;


// F64: it will generate 6 * 9 + 2 = 56-bit QUOT in total. But QUOT[55:54] MUST BE 2'b01 in the end.
localparam F64_QUOT_W = 54;
// F32: it will generate 6 * 4 + 2 = 26-bit QUOT in total. But QUOT[25:24] MUST BE 2'b01 in the end.
localparam F32_QUOT_W = 24;
// F16: it will generate 6 * 2 + 2 = 14-bit QUOT in total. But QUOT[13:12] MUST BE 2'b01 in the end.
localparam F16_QUOT_W = 12;

localparam QUOT_ROOT_W = 54;

// {-2, -1, 0, +1, +2}
localparam QUOT_ROOT_DIG_W = 5;

// f464_frac[52] <=> 2 ^  0
// f464_frac[51] <=> 2 ^ -1
// f464_frac[50] <=> 2 ^ -2
// ...
// f464_frac[ 1] <=> 2 ^ -52
// f464_frac[ 0] <=> 2 ^ -53
// The field of the "REM" used in iter is:
// [59]: sign
// [58]: 2 ^ 1
// [57]: 2 ^ 0
// [56:4]: (2 ^ -1) ~ (2 ^ -53)
// [3:1]: (2 ^ -54) ~ (2 ^ -56) -> for operand scaling, we need to do "frac * (2 ^ -3)"
// [0]: add 1-bit as LSB for initialization -> The 1st quot could only be +1 or +2, so we make "1st_rem[0] = 1". Thus the 1st CSA is simplified
localparam FDIV_F64_REM_W = 3 + 53 + 3 + 1;
localparam FDIV_F32_REM_W = 3 + 24 + 3 + 1;
localparam FDIV_F16_REM_W = 3 + 11 + 3 + 1;

// FDIV_REM_W >= FSQRT_F64_REM_W
localparam GLOBAL_REM_W = FDIV_F64_REM_W;


localparam FSM_W = 5;
localparam FSM_PRE_0 	= (1 << 0);
localparam FSM_PRE_1 	= (1 << 1);
localparam FSM_ITER  	= (1 << 2);
localparam FSM_POST_0 	= (1 << 3);
localparam FSM_POST_1 	= (1 << 4);

localparam FSM_PRE_0_BIT 	= 0;
localparam FSM_PRE_1_BIT	= 1;
localparam FSM_ITER_BIT 	= 2;
localparam FSM_POST_0_BIT 	= 3;
localparam FSM_POST_1_BIT 	= 4;

// Used when we find that the op is the power of 2 and it has an odd_exp.
localparam [54 - 1:0] SQRT_2_WITH_ROUND_BIT = 54'b1_01101010000010011110011001100111111100111011110011001;

// If "r_shift_num" of quot is greater than or equal to this value, then the whole quot would be sticky_bit
// 54 = 1 + 52 + 1
localparam LIMITTED_R_SHIFT_NUM = 6'd54;

localparam RM_RNE = 3'b000;
localparam RM_RTZ = 3'b001;
localparam RM_RDN = 3'b010;
localparam RM_RUP = 3'b011;
localparam RM_RMM = 3'b100;

// (local) parameters end
// ================================================================================================================================================

// ================================================================================================================================================
// signals begin

// Some abbreviations:
// quot = quotient
// rem = remainder
// D = divisor
// f = frac
// f_r = frac_rem
// f_r_s = frac_rem_sum
// f_r_c = frac_rem_carry
// ext = extended
// nr = non_redundant
// QDS = Quotient Digit Selection
// dn = dn
// nm = nm
// uf = underflow
// of = overflow

logic start_handshaked;
logic [FSM_W-1:0] fsm_d;
logic [FSM_W-1:0] fsm_q;
logic has_dn_in;

logic is_fdiv_d;
logic is_fdiv_q;

logic res_exp_en;
logic [13 - 1:0] res_exp_d;
logic [13 - 1:0] res_exp_q;
logic [13 - 1:0] nxt_res_exp_pre_0;
logic [13 - 1:0] nxt_res_exp_pre_1;
logic [12 - 1:0] res_exp_mul_2_fsqrt;

logic [13 - 1:0] exp_diff_nm_in;
logic [13 - 1:0] exp_diff_nm_in_m1;
logic [13 - 1:0] exp_diff_dn_in_pre_0;
logic [13 - 1:0] exp_diff_dn_in_pre_1;
logic [13 - 1:0] exp_diff_dn_in_pre_1_m1;

logic res_exp_nm_in_fdiv_is_dn;
logic res_exp_nm_in_fdiv_is_of;

logic res_exp_dn_in_fdiv_is_dn;
logic res_exp_dn_in_fdiv_is_of;

logic res_exp_nm_in_fdiv_is_dn_m1;
logic res_exp_nm_in_fdiv_is_of_m1;

logic use_limitted_r_shift_num_nm_in;
logic [13 - 1:0] r_shift_num_nm_in_temp;
logic [6 - 1:0] r_shift_num_nm_in;
logic use_limitted_r_shift_num_nm_in_m1;
logic [13 - 1:0] r_shift_num_nm_in_temp_m1;
logic [6 - 1:0] r_shift_num_nm_in_m1;
logic [6 - 1:0] r_shift_num_pre_0;

logic res_exp_dn_in_fdiv_is_dn_m1;
logic res_exp_dn_in_fdiv_is_of_m1;

logic use_limitted_r_shift_num_dn_in;
logic [13 - 1:0] r_shift_num_dn_in_temp;
logic [6 - 1:0] r_shift_num_dn_in;
logic use_limitted_r_shift_num_dn_in_m1;
logic [13 - 1:0] r_shift_num_dn_in_temp_m1;
logic [6 - 1:0] r_shift_num_dn_in_m1;
logic [6 - 1:0] r_shift_num_pre_1;

logic opa_sign;
logic opb_sign;
logic [11 - 1:0] opa_exp;
logic [11 - 1:0] opb_exp;
logic [11 - 1:0] opa_exp_adjusted;
logic [11 - 1:0] opb_exp_adjusted;
logic [12 - 1:0] opa_exp_plus_bias;
logic opa_exp_is_zero;
logic opb_exp_is_zero;
logic opa_exp_is_max;
logic opb_exp_is_max;
logic opa_is_zero;
logic opb_is_zero;

logic opa_frac_is_zero_pre_0;
logic opa_frac_is_zero_pre_1;
logic opb_frac_is_zero_pre_0;
logic opb_frac_is_zero_pre_1;

logic opa_is_inf;
logic opb_is_inf;
logic opa_is_qnan;
logic opb_is_qnan;
logic opa_is_snan;
logic opb_is_snan;
logic opa_is_nan;
logic opb_is_nan;
logic opa_is_dn;
logic opb_is_dn;

logic f16_pre_0;
logic f32_pre_0;
logic f64_pre_0;
logic f16_after_pre_0;
logic f32_after_pre_0;
logic f64_after_pre_0;

logic [F64_FRAC_W - 1:0] opa_frac_lzc_data_in;
logic [F64_FRAC_W - 1:0] opb_frac_lzc_data_in;

logic opa_frac_lt_opb_frac;

logic [F64_FRAC_W-1:0] opa_frac_unshifted;
logic [F64_FRAC_W-1:0] opb_frac_unshifted;
logic [$clog2(F64_FRAC_W)-1:0] opa_frac_l_shift_num;
logic [$clog2(F64_FRAC_W)-1:0] opb_frac_l_shift_num;
logic [$clog2(F64_FRAC_W)-1:0] opa_frac_l_shift_num_temp;
logic [$clog2(F64_FRAC_W)-1:0] opb_frac_l_shift_num_temp;
logic [(F64_FRAC_W-1)-1:0] opa_frac_l_shifted;
logic [(F64_FRAC_W-1)-1:0] opb_frac_l_shifted;

logic [3 - 1:0] scaling_factor_idx;

logic [F64_FRAC_W - 1:0] opa_frac_prescaled_pre_0;
logic [F64_FRAC_W - 1:0] opb_frac_prescaled_pre_0;
logic [F64_FRAC_W - 1:0] opa_frac_prescaled_pre_1;
logic [F64_FRAC_W - 1:0] opb_frac_prescaled_pre_1;
logic [F64_FRAC_W - 1:0] opa_frac_prescaled;
logic [F64_FRAC_W - 1:0] opb_frac_prescaled;

logic [55:0] opa_frac_prescaled_rsh_0;
logic [55:0] opa_frac_prescaled_rsh_1;
logic [55:0] opa_frac_prescaled_rsh_2;
logic [55:0] opa_frac_prescaled_rsh_3;
logic [55:0] opb_frac_prescaled_rsh_0;
logic [55:0] opb_frac_prescaled_rsh_1;
logic [55:0] opb_frac_prescaled_rsh_2;
logic [55:0] opb_frac_prescaled_rsh_3;

logic [55:0] opa_frac_scaled_csa_in_0;
logic [55:0] opa_frac_scaled_csa_in_1;
logic [55:0] opa_frac_scaled_csa_in_2;
logic [55:0] opb_frac_scaled_csa_in_0;
logic [55:0] opb_frac_scaled_csa_in_1;
logic [55:0] opb_frac_scaled_csa_in_2;

logic [55:0] opa_frac_scaled_sum;
logic [55:0] opa_frac_scaled_carry;
logic [55:0] opb_frac_scaled_sum;
logic [55:0] opb_frac_scaled_carry;

logic [56:0] opa_frac_scaled;
logic [56:0] opb_frac_scaled;

logic [GLOBAL_REM_W - 1:0] opb_frac_scaled_ext;
logic [GLOBAL_REM_W - 1:0] opb_frac_scaled_ext_mul_neg_1;
logic [GLOBAL_REM_W - 1:0] opb_frac_scaled_ext_mul_neg_2;

logic [6 - 1:0] rem_msb_1st_quot_opa_frac_ge_opb_frac_temp;
logic [5 - 1:0] rem_msb_1st_quot_opa_frac_ge_opb_frac;
logic [6 - 1:0] rem_msb_1st_quot_opa_frac_lt_opb_frac_temp;
logic [5 - 1:0] rem_msb_1st_quot_opa_frac_lt_opb_frac;

logic quot_1st_is_p2_opa_frac_ge_opb_frac;
logic quot_1st_is_p2_opa_frac_lt_opb_frac;
logic quot_1st_is_p2;

logic exp_is_odd_fsqrt;
logic [(F64_FRAC_W - 1) - 1:0] frac_fsqrt;
logic root_dig_n2_1st;
logic root_dig_n1_1st;
logic root_dig_z0_1st;

logic rem_msb_nxt_cycle_1st_srt_en;
logic [7 - 1:0] rem_msb_nxt_cycle_1st_srt_d;
logic [7 - 1:0] rem_msb_nxt_cycle_1st_srt_q;
logic [8 - 1:0] rem_msb_nxt_cycle_1st_srt_before_iter;
logic [7 - 1:0] rem_msb_nxt_cycle_1st_srt_after_iter;

logic a0_before_iter;
logic a2_before_iter;
logic a3_before_iter;
logic a4_before_iter;

logic m_common_en;
logic [5 - 1:0] m_n1_nxt_cycle_1st_srt_d;
logic [5 - 1:0] m_n1_nxt_cycle_1st_srt_q;
logic [4 - 1:0] m_z0_nxt_cycle_1st_srt_d;
logic [4 - 1:0] m_z0_nxt_cycle_1st_srt_q;
logic [3 - 1:0] m_p1_nxt_cycle_1st_srt_d;
logic [3 - 1:0] m_p1_nxt_cycle_1st_srt_q;
logic [4 - 1:0] m_p2_nxt_cycle_1st_srt_d;
logic [4 - 1:0] m_p2_nxt_cycle_1st_srt_q;

logic [7 - 1:0] m_n1_nxt_cycle_1st_srt_before_iter;
logic [7 - 1:0] m_z0_nxt_cycle_1st_srt_before_iter;
logic [7 - 1:0] m_p1_nxt_cycle_1st_srt_before_iter;
logic [7 - 1:0] m_p2_nxt_cycle_1st_srt_before_iter;
logic [7 - 1:0] m_n1_nxt_cycle_1st_srt_after_iter;
logic [7 - 1:0] m_z0_nxt_cycle_1st_srt_after_iter;
logic [7 - 1:0] m_p1_nxt_cycle_1st_srt_after_iter;
logic [7 - 1:0] m_p2_nxt_cycle_1st_srt_after_iter;

logic [GLOBAL_REM_W - 1:0] f_r_s_before_iter_fdiv;
logic [GLOBAL_REM_W - 1:0] f_r_c_before_iter_fdiv;

logic [QUOT_ROOT_W - 1:0] quot_before_iter;
logic [QUOT_ROOT_W - 1:0] quot_m1_before_iter;
logic [QUOT_ROOT_W - 1:0] quot_before_iter_opb_frac_is_zero_pre_0;
logic [QUOT_ROOT_W - 1:0] quot_before_iter_opb_frac_is_zero_pre_1;

logic [F64_FULL_ROOT_W - 1:0] root_before_iter;
logic [F64_FULL_ROOT_W - 1:0] root_m1_before_iter;

logic [FSQRT_F64_REM_W - 1:0] f_r_s_before_iter_pre_fsqrt;
logic [FSQRT_F64_REM_W - 1:0] f_r_s_before_iter_fsqrt;
logic [FSQRT_F64_REM_W - 1:0] f_r_c_before_iter_fsqrt;


logic quot_dig_p2_1st;
logic quot_dig_p1_1st;
logic quot_dig_z0_1st;
logic quot_dig_n1_1st;
logic quot_dig_n2_1st;
logic quot_dig_p2_2nd;
logic quot_dig_p1_2nd;
logic quot_dig_z0_2nd;
logic quot_dig_n1_2nd;
logic quot_dig_n2_2nd;
logic quot_dig_p2_3rd;
logic quot_dig_p1_3rd;
logic quot_dig_z0_3rd;
logic quot_dig_n1_3rd;
logic quot_dig_n2_3rd;

logic [GLOBAL_REM_W - 1:0] f_r_s_1st_fdiv;
logic [GLOBAL_REM_W - 1:0] f_r_s_2nd_fdiv;
logic [GLOBAL_REM_W - 1:0] f_r_s_3rd_fdiv;
logic [GLOBAL_REM_W - 1:0] f_r_c_1st_fdiv;
logic [GLOBAL_REM_W - 1:0] f_r_c_2nd_fdiv;
logic [GLOBAL_REM_W - 1:0] f_r_c_3rd_fdiv;

logic [FSQRT_F64_REM_W - 1:0] f_r_s_1st_fsqrt;
logic [FSQRT_F64_REM_W - 1:0] f_r_c_1st_fsqrt;
logic [FSQRT_F64_REM_W - 1:0] f_r_s_2nd_fsqrt;
logic [FSQRT_F64_REM_W - 1:0] f_r_c_2nd_fsqrt;

logic [56 - 1:0] quot_1st;
logic [56 - 1:0] quot_2nd;
logic [56 - 1:0] quot_3rd;
logic [56 - 1:0] quot_m1_1st;
logic [56 - 1:0] quot_m1_2nd;
logic [56 - 1:0] quot_m1_3rd;

logic [54 - 1:0] root_1st;
logic [53 - 1:0] root_m1_1st;
logic [54 - 1:0] root_2nd;
logic [53 - 1:0] root_m1_2nd;


// ================================================================================================================================================
// Some special cases

logic op_invalid_fdiv;
logic op_invalid_fsqrt;

logic res_is_nan_fdiv;
logic res_is_inf_fdiv;
logic res_is_exact_zero_fdiv;

logic res_is_nan_fsqrt;
logic res_is_inf_fsqrt;
logic res_is_exact_zero_fsqrt;

logic res_is_sqrt2_pre_0;
logic res_is_sqrt2_pre_1;

logic early_finish_to_post_1_fdiv_pre_0;
logic early_finish_to_post_0_fdiv_pre_0;
logic early_finish_to_post_1_fsqrt_pre_0;
logic early_finish_to_post_0_fsqrt_pre_0;
logic early_finish_to_post_1_pre_0;
logic early_finish_to_post_0_pre_0;

logic early_finish_fdiv_pre_1;
logic early_finish_fsqrt_pre_1;
logic early_finish_pre_1;
logic divided_by_zero;


logic res_is_nan_d;
logic res_is_nan_q;

logic res_is_inf_d;
logic res_is_inf_q;

logic res_is_exact_zero_d;
logic res_is_exact_zero_q;

logic opb_is_power_of_2_en;
logic opb_is_power_of_2_d;
logic opb_is_power_of_2_q;

logic res_is_sqrt2_en;
logic res_is_sqrt2_d;
logic res_is_sqrt2_q;

logic op_invalid_d;
logic op_invalid_q;

logic divided_by_zero_d;
logic divided_by_zero_q;

logic need_denormalization;

// ================================================================================================================================================

logic res_sign_d;
logic res_sign_q;
logic [3-1:0] fp_format_d;
logic [3-1:0] fp_format_q;
logic [3-1:0] rm_d;
logic [3-1:0] rm_q;

logic f_r_s_en;
logic [GLOBAL_REM_W-1:0] f_r_s_d;
logic [GLOBAL_REM_W-1:0] f_r_s_q;
logic f_r_c_en;
logic [GLOBAL_REM_W-1:0] f_r_c_d;
logic [GLOBAL_REM_W-1:0] f_r_c_q;

// 57 = F64_FRAC_W + 4
logic frac_D_en;
logic [57 - 1:0] frac_D_d;
logic [57 - 1:0] frac_D_q;

logic [57 - 1:0] nxt_frac_D_before_iter_fdiv;
logic [57 - 1:0] nxt_frac_D_before_iter_fsqrt;
logic [57 - 1:0] nxt_frac_D_iter;
logic [57 - 1:0] nxt_frac_D_post_0;

logic quot_root_iter_en;
logic [QUOT_ROOT_W - 1:0] quot_root_iter_d;
logic [QUOT_ROOT_W - 1:0] quot_root_iter_q;

logic quot_root_m1_iter_en;
logic [QUOT_ROOT_W - 1:0] quot_root_m1_iter_d;
logic [QUOT_ROOT_W - 1:0] quot_root_m1_iter_q;

logic iter_num_en;
// f64: iter_num_needed = 9, 9 - 1 = 8
// f32: iter_num_needed = 4, 4 - 1 = 3
// f16: iter_num_needed = 2, 2 - 1 = 1
// So a 4-bit counter is enough.
logic [4 - 1:0] iter_num_d;
logic [4 - 1:0] iter_num_q;

logic [4 - 1:0] iter_num_fdiv_pre_0;
logic [4 - 1:0] iter_num_fdiv_pre_1;
logic [4 - 1:0] iter_num_fsqrt_pre_0;
logic [4 - 1:0] iter_num_fsqrt_pre_1;
logic [4 - 1:0] iter_num_fdiv;
logic [4 - 1:0] iter_num_fsqrt;
logic final_iter;

logic [GLOBAL_REM_W - 1:0] nr_f_r;
logic [(GLOBAL_REM_W - 2) - 1:0] f_r_xor;
logic [(GLOBAL_REM_W - 2) - 1:0] f_r_or;
logic rem_is_not_zero_post_0;
logic rem_is_not_zero_post_1;

logic [54 - 1:0] quot_unshifted;
logic [54 - 1:0] quot_m1_unshifted;
logic [(2 * 54) - 1:0] quot_shifted;
logic [(2 * 54) - 1:0] quot_m1_shifted;
logic [6 - 1:0] r_shift_num_post_0;

logic select_quot_m1;
logic select_root_m1;
logic [53 - 1:0] correct_quot_frac_shifted;
logic [54 - 1:0] sticky_without_rem;

logic [53 - 1:0] quot_root_inc_res;

logic [52 - 1:0] quot_before_inc;
logic [52 - 1:0] quot_m1_before_inc;
logic [52 - 1:0] quot_m1_inc_res;
logic [53 - 1:0] root_m1_inc_res;
logic [53 - 1:0] root_before_inc;
logic [52 - 1:0] quot_root_before_inc;
logic [52 - 1:0] inc_poisition_fsqrt;
logic [52 - 1:0] inc_poisition_fdiv;
logic [52 - 1:0] inc_poisition;


logic carry_after_round_fdiv;
logic carry_after_round_fsqrt;
logic [11 - 1:0] exp_rounded_fsqrt;
logic of;
logic of_to_inf;


logic inexact;
logic inexact_fdiv;
logic inexact_fsqrt;

logic quot_l;
logic quot_g;
logic quot_s;
logic quot_m1_l;
logic quot_m1_g;
logic quot_m1_s;
logic quot_need_rup;
logic quot_m1_need_rup;
logic quot_inexact;
logic quot_m1_inexact;

logic [53 - 1:0] quot_rounded;
logic [52 - 1:0] quot_m1_rounded;
logic [53 - 1:0] root_rounded;
logic [53 - 1:0] root_m1_rounded;

logic root_l;
logic root_g;
logic root_s;
logic root_need_rup;
logic root_inexact;
logic root_m1_l;
logic root_m1_g;
logic root_m1_s;
logic root_m1_need_rup;
logic root_m1_inexact;

logic [52 - 1:0] frac_rounded_post_0_fsqrt;
logic [52 - 1:0] frac_rounded_post_0_fdiv;
logic [52 - 1:0] frac_rounded_post_0;

logic [F16_EXP_W - 1:0] exp_res_post_0_f16;
logic [F32_EXP_W - 1:0] exp_res_post_0_f32;
logic [F64_EXP_W - 1:0] exp_res_post_0_f64;

logic [10 - 1:0] frac_res_post_0_f16;
logic [23 - 1:0] frac_res_post_0_f32;
logic [52 - 1:0] frac_res_post_0_f64;

logic [F16_EXP_W - 1:0] exp_res_post_1_f16;
logic [F32_EXP_W - 1:0] exp_res_post_1_f32;
logic [F64_EXP_W - 1:0] exp_res_post_1_f64;

logic [10 - 1:0] frac_res_post_1_f16;
logic [23 - 1:0] frac_res_post_1_f32;
logic [52 - 1:0] frac_res_post_1_f64;

logic [16 - 1:0] final_res_post_0_f16;
logic [32 - 1:0] final_res_post_0_f32;
logic [64 - 1:0] final_res_post_0_f64;

logic [16 - 1:0] final_res_post_1_f16;
logic [32 - 1:0] final_res_post_1_f32;
logic [64 - 1:0] final_res_post_1_f64;

logic [64 - 1:0] final_res_post_0;
logic [64 - 1:0] final_res_post_1;


logic fflags_invalid_operation;
logic fflags_div_by_zero;
logic fflags_of;
logic fflags_uf;
logic fflags_inexact;

// signals end
// ================================================================================================================================================

// ================================================================================================================================================
// FSM ctrl
// ================================================================================================================================================
always_comb begin
	unique case(fsm_q)
		FSM_PRE_0:
			fsm_d = 
			start_valid_i ? (
				early_finish_to_post_1_pre_0 ? FSM_POST_1 :
				early_finish_to_post_0_pre_0 ? FSM_POST_0 :
				has_dn_in ? FSM_PRE_1 :
				FSM_ITER
			) : 
			FSM_PRE_0;
		FSM_PRE_1:
			fsm_d = early_finish_pre_1 ? FSM_POST_0 : FSM_ITER;
		FSM_ITER:
			fsm_d = final_iter ? FSM_POST_0 : FSM_ITER;
		FSM_POST_0:
			fsm_d = need_denormalization ? FSM_POST_1 : (finish_ready_i ? FSM_PRE_0 : FSM_POST_0);
		FSM_POST_1:
			fsm_d = finish_ready_i ? FSM_PRE_0 : FSM_POST_1;
		default:
			fsm_d = FSM_PRE_0;
	endcase

	if(flush_i)
		// flush has the highest priority.
		fsm_d = FSM_PRE_0;
end

// The only reg that need to be reset.
always_ff @(posedge clk or negedge rst_n) begin
	if(~rst_n)
		fsm_q <= FSM_PRE_0;
	else
		fsm_q <= fsm_d;
end

assign start_ready_o = fsm_q[FSM_PRE_0_BIT];
assign start_handshaked = start_valid_i & start_ready_o;
assign finish_valid_o = fsm_q[FSM_POST_1_BIT] | (fsm_q[FSM_POST_0_BIT] & ~need_denormalization);
// When we are doing fsqrt, res_exp_q[12] MUST be 1'b0
assign need_denormalization = res_exp_q[12];

assign f16_pre_0 = fp_format_i[0];
assign f32_pre_0 = fp_format_i[1];
assign f64_pre_0 = fp_format_i[2];
assign f16_after_pre_0 = fp_format_q[0];
assign f32_after_pre_0 = fp_format_q[1];
assign f64_after_pre_0 = fp_format_q[2];

// ================================================================================================================================================
// SRC unpacking
// ================================================================================================================================================
assign opa_sign = f16_pre_0 ? opa_i[15] : f32_pre_0 ? opa_i[31] : opa_i[63];
assign opb_sign = f16_pre_0 ? opb_i[15] : f32_pre_0 ? opb_i[31] : opb_i[63];
assign opa_exp = f16_pre_0 ? {6'b0, opa_i[14:10]} : f32_pre_0 ? {3'b0, opa_i[30:23]} : opa_i[62:52];
assign opb_exp = f16_pre_0 ? {6'b0, opb_i[14:10]} : f32_pre_0 ? {3'b0, opb_i[30:23]} : opb_i[62:52];

assign opa_exp_adjusted = 
f16_pre_0 ? {6'b0, opa_i[14:11], opa_i[10] | opa_exp_is_zero} : 
f32_pre_0 ? {3'b0, opa_i[30:24], opa_i[23] | opa_exp_is_zero} : 
{opa_i[62:53], opa_i[52] | opa_exp_is_zero};
assign opb_exp_adjusted = 
f16_pre_0 ? {6'b0, opb_i[14:11], opb_i[10] | opb_exp_is_zero} : 
f32_pre_0 ? {3'b0, opb_i[30:24], opb_i[23] | opb_exp_is_zero} : 
{opb_i[62:53], opb_i[52] | opb_exp_is_zero};

assign opa_exp_plus_bias = {1'b0, opa_exp_adjusted[10:0]} + (f16_pre_0 ? 12'd15 : f32_pre_0 ? 12'd127 : 12'd1023);

assign opa_exp_is_zero = (opa_exp == 11'b0);
assign opb_exp_is_zero = (opb_exp == 11'b0);
assign opa_exp_is_max = (opa_exp == (f16_pre_0 ? 11'd31 : f32_pre_0 ? 11'd255 : 11'd2047));
assign opb_exp_is_max = (opb_exp == (f16_pre_0 ? 11'd31 : f32_pre_0 ? 11'd255 : 11'd2047));
assign opa_is_zero = opa_exp_is_zero & opa_frac_is_zero_pre_0;
assign opb_is_zero = opb_exp_is_zero & opb_frac_is_zero_pre_0;
assign opa_is_dn = opa_exp_is_zero & ~opa_frac_is_zero_pre_0;
assign opb_is_dn = opb_exp_is_zero & ~opb_frac_is_zero_pre_0;

assign opa_is_inf = opa_exp_is_max & opa_frac_is_zero_pre_0;
assign opb_is_inf = opb_exp_is_max & opb_frac_is_zero_pre_0;
assign opa_is_qnan = opa_exp_is_max & (f16_pre_0 ? opa_i[9] : f32_pre_0 ? opa_i[22] : opa_i[51]);
assign opb_is_qnan = opb_exp_is_max & (f16_pre_0 ? opb_i[9] : f32_pre_0 ? opb_i[22] : opb_i[51]);
assign opa_is_snan = opa_exp_is_max & ~opa_frac_is_zero_pre_0 & (f16_pre_0 ? ~opa_i[9] : f32_pre_0 ? ~opa_i[22] : ~opa_i[51]);
assign opb_is_snan = opb_exp_is_max & ~opb_frac_is_zero_pre_0 & (f16_pre_0 ? ~opb_i[9] : f32_pre_0 ? ~opb_i[22] : ~opb_i[51]);
assign opa_is_nan = (opa_is_qnan | opa_is_snan);
assign opb_is_nan = (opb_is_qnan | opb_is_snan);

assign op_invalid_fdiv = (opa_is_inf & opb_is_inf) | (opa_is_zero & opb_is_zero) | opa_is_snan | opb_is_snan;
assign op_invalid_fsqrt = (opa_sign & ~opa_is_zero & ~opa_is_qnan) | opa_is_snan;

assign res_is_nan_fdiv = opa_is_nan | opb_is_nan | op_invalid_fdiv;
assign res_is_inf_fdiv = (opa_is_inf & ~opb_is_nan) | (~opa_is_nan & opb_is_zero);
// assign res_is_exact_zero_fdiv = (opa_is_zero & ~opb_is_nan) | (~opa_is_nan & opb_is_inf);
assign res_is_exact_zero_fdiv = opa_is_zero | opb_is_inf;

assign res_is_nan_fsqrt = opa_is_nan | op_invalid_fsqrt;
assign res_is_inf_fsqrt = opa_is_inf;
assign res_is_exact_zero_fsqrt = opa_is_zero;

// {opa_is_dn, res_is_sqrt2_pre_0} can't be 2'b11 in PRE_0
assign res_is_sqrt2_pre_0 = opa_frac_is_zero_pre_0 & ~opa_exp[0];
// In PRE_1, opa has already been a nm number
assign opa_frac_is_zero_pre_1 = (quot_root_iter_q[0 +: (F64_FRAC_W - 1)] == '0);
assign res_is_sqrt2_pre_1 = opa_frac_is_zero_pre_1 & iter_num_q[0];

assign early_finish_to_post_1_fdiv_pre_0 = 
  res_is_nan_fdiv
| res_is_inf_fdiv
| res_is_exact_zero_fdiv;
assign early_finish_to_post_0_fdiv_pre_0 = (opb_frac_is_zero_pre_0 & ~opb_exp_is_zero & ~opb_exp_is_max) & (~opa_exp_is_zero & ~opa_exp_is_max);

assign early_finish_to_post_1_fsqrt_pre_0 = 
  res_is_nan_fsqrt
| res_is_inf_fsqrt
| res_is_exact_zero_fsqrt;
// assign early_finish_to_post_0_fsqrt_pre_0 = res_is_sqrt2_pre_0 & ~opa_exp_is_zero;
assign early_finish_to_post_0_fsqrt_pre_0 = opa_frac_is_zero_pre_0 & ~opa_exp_is_zero;

assign early_finish_to_post_1_pre_0 = (early_finish_to_post_1_fdiv_pre_0 & is_fdiv_i) | (early_finish_to_post_1_fsqrt_pre_0 & ~is_fdiv_i);
assign early_finish_to_post_0_pre_0 = (early_finish_to_post_0_fdiv_pre_0 & is_fdiv_i) | (early_finish_to_post_0_fsqrt_pre_0 & ~is_fdiv_i);


// In PRE_1, opa and opb have already been 2 nm numbers
assign opb_frac_is_zero_pre_1 = (quot_root_m1_iter_q[0 +: (F64_FRAC_W - 1)] == '0);
assign early_finish_fdiv_pre_1 = opb_frac_is_zero_pre_1;
assign early_finish_fsqrt_pre_1 = opa_frac_is_zero_pre_1;
// assign early_finish_fsqrt_pre_1 = res_is_sqrt2_pre_1;

// In PRE_1, we always "early_finish to POST_0"
assign early_finish_pre_1 = (early_finish_fdiv_pre_1 & is_fdiv_q) | (early_finish_fsqrt_pre_1 & ~is_fdiv_q);

// When result is not nan, and dividend is not inf, "dividend / 0" should lead to "DIV_BY_ZERO" exception.
// When "divided_by_zero = 1", "res_is_inf_fdiv" is also 1, so it will also lead to "early_finish"
assign divided_by_zero = ~res_is_nan_fdiv & ~opa_is_inf & opb_is_zero & is_fdiv_i;
assign has_dn_in = opa_is_dn | (opb_is_dn & is_fdiv_i);

// Follow the rule in riscv-spec, just produce default NaN.
assign res_sign_d = (res_is_nan_fdiv & is_fdiv_i) | (res_is_nan_fsqrt & ~is_fdiv_i) ? 1'b0 : ~is_fdiv_i ? opa_sign : (opa_sign ^ opb_sign);
assign fp_format_d = {f64_pre_0, f32_pre_0, f16_pre_0};
assign rm_d = rm_i;

assign res_is_nan_d = (res_is_nan_fdiv & is_fdiv_i) | (res_is_nan_fsqrt & ~is_fdiv_i);
assign res_is_inf_d = (res_is_inf_fdiv & is_fdiv_i) | (res_is_inf_fsqrt & ~is_fdiv_i);
assign res_is_exact_zero_d = (res_is_exact_zero_fdiv & is_fdiv_i) | (res_is_exact_zero_fsqrt & ~is_fdiv_i);

assign op_invalid_d = (op_invalid_fdiv & is_fdiv_i) | (op_invalid_fsqrt & ~is_fdiv_i);
assign divided_by_zero_d = divided_by_zero;
assign is_fdiv_d = is_fdiv_i;
always_ff @(posedge clk) begin
	if(start_handshaked) begin		
		res_sign_q <= res_sign_d;
		fp_format_q <= fp_format_d;
		rm_q <= rm_d;
		is_fdiv_q <= is_fdiv_d;

		res_is_nan_q <= res_is_nan_d;
		res_is_inf_q <= res_is_inf_d;
		res_is_exact_zero_q <= res_is_exact_zero_d;
		op_invalid_q <= op_invalid_d;
		divided_by_zero_q <= divided_by_zero_d;
	end
end

// Don't use "is_fdiv" here to simplify "en" signal
assign opb_is_power_of_2_en = start_handshaked | fsm_q[FSM_PRE_1_BIT];
assign opb_is_power_of_2_d  = fsm_q[FSM_PRE_0_BIT] ? opb_frac_is_zero_pre_0 : opb_frac_is_zero_pre_1;
always_ff @(posedge clk)
	if(opb_is_power_of_2_en)
		opb_is_power_of_2_q <= opb_is_power_of_2_d;
	
// Don't use "~is_fdiv" here to simplify "en" signal
assign res_is_sqrt2_en = start_handshaked | fsm_q[FSM_PRE_1_BIT];
assign res_is_sqrt2_d  = fsm_q[FSM_PRE_0_BIT] ? res_is_sqrt2_pre_0 : res_is_sqrt2_pre_1;
always_ff @(posedge clk)
	if(res_is_sqrt2_en)
		res_is_sqrt2_q <= res_is_sqrt2_d;


// EXP logic for FDIV
assign exp_diff_nm_in = {1'b0, opa_exp_plus_bias} - {2'b0, opb_exp_adjusted};
assign res_exp_nm_in_fdiv_is_dn = (exp_diff_nm_in[11:0] == '0) | exp_diff_nm_in[12];
assign res_exp_nm_in_fdiv_is_of = (exp_diff_nm_in[11:0] >= (
	  ({(12){f16_pre_0}} & 12'd31)
	| ({(12){f32_pre_0}} & 12'd255)
	| ({(12){f64_pre_0}} & 12'd2047)
));
assign exp_diff_nm_in_m1 = exp_diff_nm_in - 13'd1;
assign res_exp_nm_in_fdiv_is_dn_m1 = (exp_diff_nm_in_m1[11:0] == '0) | exp_diff_nm_in_m1[12];
assign res_exp_nm_in_fdiv_is_of_m1 = (exp_diff_nm_in_m1[11:0] >= (
	  ({(12){f16_pre_0}} & 12'd31)
	| ({(12){f32_pre_0}} & 12'd255)
	| ({(12){f64_pre_0}} & 12'd2047)
));

// Here we calculate the "REAL" "r_shift_num".
// The 2's form of -(12'd54) is "12'b111111001010". When("exp_diff" <= -54), we should use "LIMITTED_R_SHIFT_NUM", instead of "1 - exp_diff"
assign use_limitted_r_shift_num_nm_in = (exp_diff_nm_in[11:0] <= 12'b111111001010) & exp_diff_nm_in[12];
assign r_shift_num_nm_in_temp = 13'd1 - exp_diff_nm_in[12:0];
assign r_shift_num_nm_in = use_limitted_r_shift_num_nm_in ? LIMITTED_R_SHIFT_NUM : r_shift_num_nm_in_temp[5:0];

assign use_limitted_r_shift_num_nm_in_m1 = (exp_diff_nm_in_m1[11:0] <= 12'b111111001010) & exp_diff_nm_in_m1[12];
assign r_shift_num_nm_in_temp_m1 = 13'd1 - exp_diff_nm_in_m1[12:0];
assign r_shift_num_nm_in_m1 = use_limitted_r_shift_num_nm_in_m1 ? LIMITTED_R_SHIFT_NUM : r_shift_num_nm_in_temp_m1[5:0];

assign r_shift_num_pre_0 = opa_frac_lt_opb_frac ? r_shift_num_nm_in_m1 : r_shift_num_nm_in;


// If the timing is bad, maybe we should do "- opa_frac_l_shift_num + opb_frac_l_shift_num" in PRE_1 ??
assign exp_diff_dn_in_pre_0 = exp_diff_nm_in - {7'b0, opa_frac_l_shift_num[5:0]} + {7'b0, opb_frac_l_shift_num[5:0]};


// In PRE_1, res_exp_q[12:0] = exp_diff_dn_in_pre_0[12:0]
assign exp_diff_dn_in_pre_1 = res_exp_q;
assign res_exp_dn_in_fdiv_is_dn = (exp_diff_dn_in_pre_1[11:0] == '0) | exp_diff_dn_in_pre_1[12];
assign res_exp_dn_in_fdiv_is_of = (exp_diff_dn_in_pre_1[11:0] >= (
	  ({(12){f16_after_pre_0}} & 12'd31)
	| ({(12){f32_after_pre_0}} & 12'd255)
	| ({(12){f64_after_pre_0}} & 12'd2047)
));
assign exp_diff_dn_in_pre_1_m1 = exp_diff_dn_in_pre_1 - 13'd1;
assign res_exp_dn_in_fdiv_is_dn_m1 = (exp_diff_dn_in_pre_1_m1[11:0] == '0) | exp_diff_dn_in_pre_1_m1[12];
assign res_exp_dn_in_fdiv_is_of_m1 = (exp_diff_dn_in_pre_1_m1[11:0] >= (
	  ({(12){f16_after_pre_0}} & 12'd31)
	| ({(12){f32_after_pre_0}} & 12'd255)
	| ({(12){f64_after_pre_0}} & 12'd2047)
));

assign use_limitted_r_shift_num_dn_in = (exp_diff_dn_in_pre_1[11:0] <= 12'b111111001010) & exp_diff_dn_in_pre_1[12];
assign r_shift_num_dn_in_temp = 13'd1 - exp_diff_dn_in_pre_1[12:0];
assign r_shift_num_dn_in = use_limitted_r_shift_num_dn_in ? LIMITTED_R_SHIFT_NUM : r_shift_num_dn_in_temp[5:0];

assign use_limitted_r_shift_num_dn_in_m1 = (exp_diff_dn_in_pre_1_m1[11:0] <= 12'b111111001010) & exp_diff_dn_in_pre_1_m1[12];
assign r_shift_num_dn_in_temp_m1 = 13'd1 - exp_diff_dn_in_pre_1_m1[12:0];
assign r_shift_num_dn_in_m1 = use_limitted_r_shift_num_dn_in_m1 ? LIMITTED_R_SHIFT_NUM : r_shift_num_dn_in_temp_m1[5:0];

assign r_shift_num_pre_1 = opa_frac_lt_opb_frac ? r_shift_num_dn_in_m1 : r_shift_num_dn_in;

// What should we store in "res_exp_q" in PRE_0 ?
// FDIV
// dn in: exp_diff_dn_in_pre_0
// nm in: processed exp info
// FSQRT: res_exp_fsqrt
assign nxt_res_exp_pre_0 = is_fdiv_i ? (has_dn_in ? exp_diff_dn_in_pre_0 : {	
	opa_frac_lt_opb_frac ? res_exp_nm_in_fdiv_is_dn_m1 : res_exp_nm_in_fdiv_is_dn,
	// opa_frac_lt_opb_frac ? (res_exp_nm_in_fdiv_is_of_m1 | res_exp_nm_in_fdiv_is_dn_m1) : (res_exp_nm_in_fdiv_is_of | res_exp_nm_in_fdiv_is_dn),
	opa_frac_lt_opb_frac ? res_exp_nm_in_fdiv_is_of_m1 : res_exp_nm_in_fdiv_is_of,
	opa_frac_lt_opb_frac ? exp_diff_nm_in_m1[10:6] : exp_diff_nm_in[10:6],
	opa_frac_lt_opb_frac ? (res_exp_nm_in_fdiv_is_dn_m1 ? r_shift_num_nm_in_m1[5:0] : exp_diff_nm_in_m1[5:0]) : (res_exp_nm_in_fdiv_is_dn ? r_shift_num_nm_in[5:0] : exp_diff_nm_in[5:0])
}) : {2'b0, res_exp_mul_2_fsqrt[11:1]};

// What should we store in "res_exp_q" in PRE_1 ?
// FDIV: processed exp info
assign nxt_res_exp_pre_1 = {	
	opa_frac_lt_opb_frac ? res_exp_dn_in_fdiv_is_dn_m1 : res_exp_dn_in_fdiv_is_dn,
	// opa_frac_lt_opb_frac ? (res_exp_dn_in_fdiv_is_of_m1 | res_exp_dn_in_fdiv_is_dn_m1) : (res_exp_dn_in_fdiv_is_of | res_exp_dn_in_fdiv_is_dn),
	opa_frac_lt_opb_frac ? res_exp_dn_in_fdiv_is_of_m1 : res_exp_dn_in_fdiv_is_of,
	opa_frac_lt_opb_frac ? exp_diff_dn_in_pre_1_m1[10:6] : exp_diff_dn_in_pre_1[10:6],
	opa_frac_lt_opb_frac ? (res_exp_dn_in_fdiv_is_dn_m1 ? r_shift_num_dn_in_m1[5:0] : exp_diff_dn_in_pre_1_m1[5:0]) : (res_exp_dn_in_fdiv_is_dn ? r_shift_num_dn_in[5:0] : exp_diff_dn_in_pre_1[5:0])
};

// EXP calculation for FSQRT
// It might be a little bit difficult to understand the logic here.
// E: Real exponent of a number
// exp: The encoded value of E in a particular fp_format
// Take F64 as an example:
// x.E = 1023
// x.exp[10:0] = 1023 + 1023 = 11111111110
// sqrt_res.E = (1023 - 1) / 2 = 511
// sqrt_res.exp = 511 + 1023 = 10111111110
// Since x is a nm number -> opa_frac_l_shift_num[5:0] = 000000
// res_exp_fsqrt[11:0] = 
// 011111111110 + 
// 001111111111 (2'b0, 10'd1023) = 
// 101111111101
// 101111111101 >> 1 = 10111111110, correct !!!
// ================================================================================================================================================
// x.E = -1056
// x.exp[10:0] = 00000000000
// sqrt_res.E = -1056 / 2 = -528
// sqrt_res.exp = -528 + 1023 = 00111101111
// Since x is a dn number -> opa_frac_l_shift_num[5:0] = 100010
// res_exp_fsqrt[11:0] = 
// 000000000001 + 
// 001111011101 (2'b0, 1111, ~opa_frac_l_shift_num[5:0]) = 
// 001111011110
// 001111011110 >> 1 = 00111101111, correct !!!

// You can also try some other value for different fp_formats
// By using this design, now the cost of getting the unrounded "res_exp_fsqrt" is:
// 1) A 12-bit FA
// 2) A 6-bit 3-to-1 MUX
// What if you use a native method to calculate "res_exp_fsqrt" ?
// If we only consider nm number:
// x.E = x.exp - (fp_format_i[0] ? 15 : fp_format_i[1] ? 127 : 1023);
// sqrt.E = x.E / 2;
// sqrt.exp = sqrt.E + (fp_format_i[0] ? 15 : fp_format_i[1] ? 127 : 1023);
// I think the design used here should lead to better PPA.
assign res_exp_mul_2_fsqrt[11:0] = {1'b0, opa_exp[10:1], opa_exp[0] | opa_exp_is_zero} + {
	2'b0,
 	  ({(6){f16_pre_0}} & 6'b0)
	| ({(6){f32_pre_0}} & {3'b0, 2'b11, ~opa_frac_l_shift_num[4]})
	| ({(6){f64_pre_0}} & {4'b1111, ~opa_frac_l_shift_num[5:4]}),
	~opa_frac_l_shift_num[3:0]
};

assign res_exp_en = start_handshaked | (fsm_q[FSM_PRE_1_BIT] & is_fdiv_q);
assign res_exp_d  = 
  ({(13){fsm_q[FSM_PRE_0_BIT]}} & nxt_res_exp_pre_0)
| ({(13){fsm_q[FSM_PRE_1_BIT]}} & nxt_res_exp_pre_1);
always_ff @(posedge clk)
	if(res_exp_en)
		res_exp_q <= res_exp_d;



// ================================================================================================================================================
// Skipping the First iteration for FSQRT
// ================================================================================================================================================
assign exp_is_odd_fsqrt = fsm_q[FSM_PRE_0_BIT] ? ~opa_exp[0] : iter_num_q[0];
assign frac_fsqrt = fsm_q[FSM_PRE_0_BIT] ? opa_frac_unshifted[0 +: (F64_FRAC_W - 1)] : quot_root_iter_q[0 +: (F64_FRAC_W - 1)];
// Look at the REF paper for more details.
// even_exp, digit in (2 ^ -1) is 0: s[1] = -2, root = {0}.{1, 53'b0} , root_m1 = {0}.{01, 52'b0}
// even_exp, digit in (2 ^ -1) is 1: s[1] = -1, root = {0}.{11, 52'b0}, root_m1 = {0}.{10, 52'b0}
// odd_exp, digit in (2 ^ -1) is 0 : s[1] = -1, root = {0}.{11, 52'b0}, root_m1 = {0}.{10, 52'b0}
// odd_exp, digit in (2 ^ -1) is 1 : s[1] =  0, root = {1}.{00, 52'b0}, root_m1 = {0}.{11, 52'b0}
assign root_dig_n2_1st = ({exp_is_odd_fsqrt, frac_fsqrt[F64_FRAC_W - 2]} == 2'b00);
assign root_dig_n1_1st = ({exp_is_odd_fsqrt, frac_fsqrt[F64_FRAC_W - 2]} == 2'b01) | ({exp_is_odd_fsqrt, frac_fsqrt[F64_FRAC_W - 2]} == 2'b10);
assign root_dig_z0_1st = ({exp_is_odd_fsqrt, frac_fsqrt[F64_FRAC_W - 2]} == 2'b11);

// When (opa_is_power_of_2) and odd_exp: 
// f_r_s_before_iter_fsqrt = {1, 55'b0}
// f_r_c_before_iter_fsqrt = {0111, 52'b0}
// In the nxt cycle, we would have "nr_f_r != 0" and "nr_f_r[REM_W-1] == 1". This is what we need, to get the correct rounded result for sqrt(2)
// When (opa_is_power_of_2) and even_exp: 
// f_r_s_before_iter_fsqrt = {01, 54'b0}
// f_r_c_before_iter_fsqrt = {11, 54'b0}
// In the nxt cycle, we would have "nr_f_r == 0". This is what we need, to get the correct rounded result for sqrt(1)
// In conclusion, when (opa_is_power_of_2), the ITER step could be skipped, and we only need to use 1-bit reg to store "opa_is_power_of_2 & exp_is_odd", 
// instead of using 2-bit reg to store "{opa_is_power_of_2, exp_is_odd}"
assign root_before_iter = 
  ({(F64_FULL_ROOT_W){root_dig_n2_1st}} & {3'b010, {(F64_FULL_ROOT_W - 3){1'b0}}})
| ({(F64_FULL_ROOT_W){root_dig_n1_1st}} & {3'b011, {(F64_FULL_ROOT_W - 3){1'b0}}})
| ({(F64_FULL_ROOT_W){root_dig_z0_1st}} & {3'b100, {(F64_FULL_ROOT_W - 3){1'b0}}});
// In the following expression,
// when s[1] = -2, the MSB of root_m1 is not 1, which doesn't follow my assumption of root_m1. But you should easily find that in the later ITER stpes,
// the QDS "MUST" select "0/+1/+2" before the next "-1/-2" is selected. Therefore, root_m1 will not be used until the next "-1/-2" is selected.
assign root_m1_before_iter = 
  ({(F64_FULL_ROOT_W){root_dig_n2_1st}} & {3'b001, {(F64_FULL_ROOT_W - 3){1'b0}}})
| ({(F64_FULL_ROOT_W){root_dig_n1_1st}} & {3'b010, {(F64_FULL_ROOT_W - 3){1'b0}}})
| ({(F64_FULL_ROOT_W){root_dig_z0_1st}} & {3'b011, {(F64_FULL_ROOT_W - 3){1'b0}}});

assign f_r_s_before_iter_pre_fsqrt[FSQRT_F64_REM_W - 1:0] = {2'b11, exp_is_odd_fsqrt ? {1'b1, frac_fsqrt, 1'b0} : {1'b0, 1'b1, frac_fsqrt}};
assign f_r_s_before_iter_fsqrt[FSQRT_F64_REM_W - 1:0] = {f_r_s_before_iter_pre_fsqrt[(FSQRT_F64_REM_W - 1) - 2:0], 2'b0};
assign f_r_c_before_iter_fsqrt = 
  ({(FSQRT_F64_REM_W){root_dig_n2_1st}} & {2'b11  , {(FSQRT_F64_REM_W - 2){1'b0}}})
| ({(FSQRT_F64_REM_W){root_dig_n1_1st}} & {4'b0111, {(FSQRT_F64_REM_W - 4){1'b0}}})
| ({(FSQRT_F64_REM_W){root_dig_z0_1st}} & {			{(FSQRT_F64_REM_W - 0){1'b0}}});

// "f_r_c_before_iter_fsqrt" would only have 4-bit non-zero value, so a 4-bit FA is enough here
assign rem_msb_nxt_cycle_1st_srt_before_iter[7:0] = {f_r_s_before_iter_fsqrt[(FSQRT_F64_REM_W - 1) -: 4] + f_r_c_before_iter_fsqrt[(FSQRT_F64_REM_W - 1) -: 4], f_r_s_before_iter_fsqrt[(FSQRT_F64_REM_W - 1) - 4 -: 4]};

assign rem_msb_nxt_cycle_1st_srt_en = (start_handshaked & ~has_dn_in) | fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];
assign rem_msb_nxt_cycle_1st_srt_d  = 
  ({(7){fsm_q[FSM_PRE_0_BIT] | fsm_q[FSM_PRE_1_BIT]	}} & rem_msb_nxt_cycle_1st_srt_before_iter[7:1])
| ({(7){fsm_q[FSM_ITER_BIT]							}} & rem_msb_nxt_cycle_1st_srt_after_iter[6:0]);

assign a0_before_iter = root_before_iter[F64_FULL_ROOT_W - 1];
assign a2_before_iter = root_before_iter[F64_FULL_ROOT_W - 3];
assign a3_before_iter = root_before_iter[F64_FULL_ROOT_W - 4];
assign a4_before_iter = root_before_iter[F64_FULL_ROOT_W - 5];

fpsqrt_r4_qds_constants_generator u_fpsqrt_r4_qds_constants_generator_before_iter (
	.a0_i           (a0_before_iter),
	.a2_i           (a2_before_iter),
	.a3_i           (a3_before_iter),
	.a4_i           (a4_before_iter),
	.m_n1_o         (m_n1_nxt_cycle_1st_srt_before_iter),
	.m_z0_o         (m_z0_nxt_cycle_1st_srt_before_iter),
	.m_p1_o         (m_p1_nxt_cycle_1st_srt_before_iter),
	.m_p2_o         (m_p2_nxt_cycle_1st_srt_before_iter)
);

assign m_common_en = (start_handshaked & ~has_dn_in) | fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];

// [6:5] = 00 -> don't need to store it
assign m_n1_nxt_cycle_1st_srt_d = 
  ({(5){fsm_q[FSM_PRE_0_BIT] | fsm_q[FSM_PRE_1_BIT]	}} & m_n1_nxt_cycle_1st_srt_before_iter[4:0])
| ({(5){fsm_q[FSM_ITER_BIT]							}} & m_n1_nxt_cycle_1st_srt_after_iter[4:0]);

// [6:4] = 000 -> don't need to store it
assign m_z0_nxt_cycle_1st_srt_d = 
  ({(4){fsm_q[FSM_PRE_0_BIT] | fsm_q[FSM_PRE_1_BIT]	}} & m_z0_nxt_cycle_1st_srt_before_iter[3:0])
| ({(4){fsm_q[FSM_ITER_BIT]							}} & m_z0_nxt_cycle_1st_srt_after_iter[3:0]);

// [6:3] = 1111 -> don't need to store it
assign m_p1_nxt_cycle_1st_srt_d = 
  ({(3){fsm_q[FSM_PRE_0_BIT] | fsm_q[FSM_PRE_1_BIT]	}} & m_p1_nxt_cycle_1st_srt_before_iter[2:0])
| ({(3){fsm_q[FSM_ITER_BIT]							}} & m_p1_nxt_cycle_1st_srt_after_iter[2:0]);

// [6:5] = 11, [0] = 0 -> don't need to store it
assign m_p2_nxt_cycle_1st_srt_d = 
  ({(4){fsm_q[FSM_PRE_0_BIT] | fsm_q[FSM_PRE_1_BIT]	}} & m_p2_nxt_cycle_1st_srt_before_iter[4:1])
| ({(4){fsm_q[FSM_ITER_BIT]							}} & m_p2_nxt_cycle_1st_srt_after_iter[4:1]);

always_ff @(posedge clk) begin
	if(rem_msb_nxt_cycle_1st_srt_en)
		rem_msb_nxt_cycle_1st_srt_q <= rem_msb_nxt_cycle_1st_srt_d;
	if(m_common_en) begin
		m_n1_nxt_cycle_1st_srt_q <= m_n1_nxt_cycle_1st_srt_d;
		m_z0_nxt_cycle_1st_srt_q <= m_z0_nxt_cycle_1st_srt_d;
		m_p1_nxt_cycle_1st_srt_q <= m_p1_nxt_cycle_1st_srt_d;
		m_p2_nxt_cycle_1st_srt_q <= m_p2_nxt_cycle_1st_srt_d;
	end
end


// ================================================================================================================================================
// Normalization
// ================================================================================================================================================
assign opa_frac_unshifted = 
  ({(F64_FRAC_W){f16_pre_0}} & {1'b0, opa_i[0 +: (F16_FRAC_W - 1)], {(F64_FRAC_W - F16_FRAC_W){1'b0}}})
| ({(F64_FRAC_W){f32_pre_0}} & {1'b0, opa_i[0 +: (F32_FRAC_W - 1)], {(F64_FRAC_W - F32_FRAC_W){1'b0}}})
| ({(F64_FRAC_W){f64_pre_0}} & {1'b0, opa_i[0 +: (F64_FRAC_W - 1)], {(F64_FRAC_W - F64_FRAC_W){1'b0}}});
assign opb_frac_unshifted = 
  ({(F64_FRAC_W){f16_pre_0}} & {1'b0, opb_i[0 +: (F16_FRAC_W - 1)], {(F64_FRAC_W - F16_FRAC_W){1'b0}}})
| ({(F64_FRAC_W){f32_pre_0}} & {1'b0, opb_i[0 +: (F32_FRAC_W - 1)], {(F64_FRAC_W - F32_FRAC_W){1'b0}}})
| ({(F64_FRAC_W){f64_pre_0}} & {1'b0, opb_i[0 +: (F64_FRAC_W - 1)], {(F64_FRAC_W - F64_FRAC_W){1'b0}}});

// PRE_0: Normalize opa
// PRE_1: Check whether opa is "power of 2" after normalization, to make fsqrt faster
assign opa_frac_lzc_data_in = opa_frac_unshifted;
lzc #(
	.WIDTH(F64_FRAC_W),
	// 0: trailing zero.
	// 1: leading zero.
	.MODE(1'b1)
) u_lzc_opa (
	.in_i		(opa_frac_lzc_data_in),
	.cnt_o		(opa_frac_l_shift_num_temp),
	// The hidden bit of frac is not considered here
	.empty_o	(opa_frac_is_zero_pre_0)
);

// PRE_0: Normalize opb
// PRE_1: Check whether opb is "power of 2" after normalization, to make fdiv faster
assign opb_frac_lzc_data_in = opb_frac_unshifted;
lzc #(
	.WIDTH(F64_FRAC_W),
	// 0: trailing zero.
	// 1: leading zero.
	.MODE(1'b1)
) u_lzc_opb (
	.in_i		(opb_frac_lzc_data_in),
	.cnt_o		(opb_frac_l_shift_num_temp),
	// The hidden bit of frac is not considered here
	.empty_o	(opb_frac_is_zero_pre_0)
);
assign opa_frac_l_shift_num = {(6){opa_exp_is_zero}} & opa_frac_l_shift_num_temp;
assign opb_frac_l_shift_num = {(6){opb_exp_is_zero}} & opb_frac_l_shift_num_temp;


frac_lsh u_frac_lsh_opa (
	.lsh_i				(opa_frac_l_shift_num_temp),
	.frac_unshifted		(opa_frac_unshifted[0 +: (F64_FRAC_W - 1)]),
	.frac_shifted		(opa_frac_l_shifted)
);
frac_lsh u_frac_lsh_opb (
	.lsh_i				(opb_frac_l_shift_num_temp),
	.frac_unshifted		(opb_frac_unshifted[0 +: (F64_FRAC_W - 1)]),
	.frac_shifted		(opb_frac_l_shifted)
);

assign opa_frac_lt_opb_frac =
  (fsm_q[FSM_PRE_0_BIT] ? opa_frac_prescaled_pre_0[0 +: (F64_FRAC_W - 1)] : opa_frac_prescaled_pre_1[0 +: (F64_FRAC_W - 1)])
< (fsm_q[FSM_PRE_0_BIT] ? opb_frac_prescaled_pre_0[0 +: (F64_FRAC_W - 1)] : opb_frac_prescaled_pre_1[0 +: (F64_FRAC_W - 1)]);

// ================================================================================================================================================
// PRESCALING
// ================================================================================================================================================

assign opa_frac_prescaled_pre_0 = {1'b1, opa_frac_unshifted[0 +: (F64_FRAC_W - 1)]};
assign opb_frac_prescaled_pre_0 = {1'b1, opb_frac_unshifted[0 +: (F64_FRAC_W - 1)]};
// In PRE_1, quot_root_iter_q = opa_frac_l_shifted, quot_root_m1_iter_q = opb_frac_l_shifted
assign opa_frac_prescaled_pre_1 = {1'b1, quot_root_iter_q[0 +: (F64_FRAC_W - 1)]};
assign opb_frac_prescaled_pre_1 = {1'b1, quot_root_m1_iter_q[0 +: (F64_FRAC_W - 1)]};
assign opa_frac_prescaled = fsm_q[FSM_PRE_0_BIT] ? opa_frac_prescaled_pre_0 : opa_frac_prescaled_pre_1;
assign opb_frac_prescaled = fsm_q[FSM_PRE_0_BIT] ? opb_frac_prescaled_pre_0 : opb_frac_prescaled_pre_1;

assign scaling_factor_idx = opb_frac_prescaled[51 -: 3];

assign opa_frac_prescaled_rsh_0[55:0] = {opa_frac_prescaled, 3'b0};
assign opa_frac_prescaled_rsh_1[55:0] = {1'b0, opa_frac_prescaled, 2'b0};
assign opa_frac_prescaled_rsh_2[55:0] = {2'b0, opa_frac_prescaled, 1'b0};
assign opa_frac_prescaled_rsh_3[55:0] = {3'b0, opa_frac_prescaled};

assign opb_frac_prescaled_rsh_0[55:0] = {opb_frac_prescaled, 3'b0};
assign opb_frac_prescaled_rsh_1[55:0] = {1'b0, opb_frac_prescaled, 2'b0};
assign opb_frac_prescaled_rsh_2[55:0] = {2'b0, opb_frac_prescaled, 1'b0};
assign opb_frac_prescaled_rsh_3[55:0] = {3'b0, opb_frac_prescaled};

assign opa_frac_scaled_csa_in_0[55:0] = opa_frac_prescaled_rsh_0;
assign opa_frac_scaled_csa_in_1[55:0] = 
  ({(56){scaling_factor_idx == 3'd0}} & opa_frac_prescaled_rsh_1)
| ({(56){scaling_factor_idx == 3'd1}} & opa_frac_prescaled_rsh_2)
| ({(56){scaling_factor_idx == 3'd2}} & opa_frac_prescaled_rsh_1)
| ({(56){scaling_factor_idx == 3'd3}} & opa_frac_prescaled_rsh_1)
| ({(56){scaling_factor_idx == 3'd4}} & opa_frac_prescaled_rsh_2)
| ({(56){scaling_factor_idx == 3'd5}} & opa_frac_prescaled_rsh_2)
| ({(56){scaling_factor_idx == 3'd6}} & '0)
| ({(56){scaling_factor_idx == 3'd7}} & '0);
assign opa_frac_scaled_csa_in_2[55:0] = 
  ({(56){scaling_factor_idx == 3'd0}} & opa_frac_prescaled_rsh_1)
| ({(56){scaling_factor_idx == 3'd1}} & opa_frac_prescaled_rsh_1)
| ({(56){scaling_factor_idx == 3'd2}} & opa_frac_prescaled_rsh_3)
| ({(56){scaling_factor_idx == 3'd3}} & '0)
| ({(56){scaling_factor_idx == 3'd4}} & opa_frac_prescaled_rsh_3)
| ({(56){scaling_factor_idx == 3'd5}} & '0)
| ({(56){scaling_factor_idx == 3'd6}} & opa_frac_prescaled_rsh_3)
| ({(56){scaling_factor_idx == 3'd7}} & opa_frac_prescaled_rsh_3);

assign opb_frac_scaled_csa_in_0[55:0] = opb_frac_prescaled_rsh_0;
assign opb_frac_scaled_csa_in_1[55:0] = 
  ({(56){scaling_factor_idx == 3'd0}} & opb_frac_prescaled_rsh_1)
| ({(56){scaling_factor_idx == 3'd1}} & opb_frac_prescaled_rsh_2)
| ({(56){scaling_factor_idx == 3'd2}} & opb_frac_prescaled_rsh_1)
| ({(56){scaling_factor_idx == 3'd3}} & opb_frac_prescaled_rsh_1)
| ({(56){scaling_factor_idx == 3'd4}} & opb_frac_prescaled_rsh_2)
| ({(56){scaling_factor_idx == 3'd5}} & opb_frac_prescaled_rsh_2)
| ({(56){scaling_factor_idx == 3'd6}} & '0)
| ({(56){scaling_factor_idx == 3'd7}} & '0);
assign opb_frac_scaled_csa_in_2[55:0] = 
  ({(56){scaling_factor_idx == 3'd0}} & opb_frac_prescaled_rsh_1)
| ({(56){scaling_factor_idx == 3'd1}} & opb_frac_prescaled_rsh_1)
| ({(56){scaling_factor_idx == 3'd2}} & opb_frac_prescaled_rsh_3)
| ({(56){scaling_factor_idx == 3'd3}} & '0)
| ({(56){scaling_factor_idx == 3'd4}} & opb_frac_prescaled_rsh_3)
| ({(56){scaling_factor_idx == 3'd5}} & '0)
| ({(56){scaling_factor_idx == 3'd6}} & opb_frac_prescaled_rsh_3)
| ({(56){scaling_factor_idx == 3'd7}} & opb_frac_prescaled_rsh_3);


assign opa_frac_scaled_sum = opa_frac_scaled_csa_in_0 ^ opa_frac_scaled_csa_in_1 ^ opa_frac_scaled_csa_in_2;
assign opa_frac_scaled_carry = {
	  (opa_frac_scaled_csa_in_0[54:0] & opa_frac_scaled_csa_in_1[54:0])
	| (opa_frac_scaled_csa_in_0[54:0] & opa_frac_scaled_csa_in_2[54:0])
	| (opa_frac_scaled_csa_in_1[54:0] & opa_frac_scaled_csa_in_2[54:0]),
	1'b0
};
assign opa_frac_scaled[56:0] = {1'b0, opa_frac_scaled_sum[55:0]} + {1'b0, opa_frac_scaled_carry[55:0]};

assign opb_frac_scaled_sum = opb_frac_scaled_csa_in_0 ^ opb_frac_scaled_csa_in_1 ^ opb_frac_scaled_csa_in_2;
assign opb_frac_scaled_carry = {
	  (opb_frac_scaled_csa_in_0[54:0] & opb_frac_scaled_csa_in_1[54:0])
	| (opb_frac_scaled_csa_in_0[54:0] & opb_frac_scaled_csa_in_2[54:0])
	| (opb_frac_scaled_csa_in_1[54:0] & opb_frac_scaled_csa_in_2[54:0]),
	1'b0
};
assign opb_frac_scaled[56:0] = {1'b0, opb_frac_scaled_sum[55:0]} + {1'b0, opb_frac_scaled_carry[55:0]};

// Use the carry-save form of scaled dividend to get 1st quot_digit
assign rem_msb_1st_quot_opa_frac_ge_opb_frac_temp[5:0] = {2'b0, opa_frac_scaled_sum[55 -: 4]} + {2'b0, opa_frac_scaled_carry[55 -: 4]};
assign rem_msb_1st_quot_opa_frac_ge_opb_frac[4:0] = rem_msb_1st_quot_opa_frac_ge_opb_frac_temp[5:1];

assign rem_msb_1st_quot_opa_frac_lt_opb_frac_temp[5:0] = {1'b0, opa_frac_scaled_sum[55 -: 5]} + {1'b0, opa_frac_scaled_carry[55 -: 5]};
assign rem_msb_1st_quot_opa_frac_lt_opb_frac[4:0] = rem_msb_1st_quot_opa_frac_lt_opb_frac_temp[5:1];

// According to QDS, the 1st quot digit MUST be "+1" or "+2", and the sign of the current "nr_f_r" is 0 -> We only need to use 5-bit to for comparison.
assign quot_1st_is_p2_opa_frac_ge_opb_frac = (rem_msb_1st_quot_opa_frac_ge_opb_frac >= 5'd12);
assign quot_1st_is_p2_opa_frac_lt_opb_frac = (rem_msb_1st_quot_opa_frac_lt_opb_frac >= 5'd12);

assign quot_1st_is_p2 = opa_frac_lt_opb_frac ? quot_1st_is_p2_opa_frac_lt_opb_frac : quot_1st_is_p2_opa_frac_ge_opb_frac;


// Do "rem[0] = 4 * rem[-1] - q[0] * d"
// For c[N-1:0] = a[N-1:0] - b[N-1:0], if a/b is in the true form, then let sum[N:0] = {a[N-1:0], 1'b1} + {~b[N-1:0], 1'b1}, c[N-1:0] = sum[N:1]
// Some examples:
// a = +15 = 0_1111, b = +6 = 0_0110 ->
// {a, 1} = 0_11111, {~b, 1} = 1_10011
// 0_11111 + 1_10011 = 0_10010: (0_10010)[5:1] = 0_1001 = +9
// a = +13 = 0_1101, b = +9 = 0_1001 ->
// {a, 1} = 0_11011, {~b, 1} = 1_01101
// 0_11011 + 1_01101 = 0_01000: (0_01000)[5:1] = 0_0100 = +4
// So, we should initialize "sum/carry" using the following value.
assign f_r_s_before_iter_fdiv = {1'b0, opa_frac_lt_opb_frac ? {opa_frac_scaled[56:0], 1'b0} : {1'b0, opa_frac_scaled[56:0]}, 1'b1};

assign opb_frac_scaled_ext[GLOBAL_REM_W - 1:0] = {2'b0, opb_frac_scaled[56:0], 1'b0};
assign opb_frac_scaled_ext_mul_neg_1 = ~opb_frac_scaled_ext;
assign opb_frac_scaled_ext_mul_neg_2 = ~{opb_frac_scaled_ext[(GLOBAL_REM_W - 1) - 1:0], 1'b0};

assign f_r_c_before_iter_fdiv = quot_1st_is_p2 ? opb_frac_scaled_ext_mul_neg_2 : opb_frac_scaled_ext_mul_neg_1;

assign f_r_s_en = (start_handshaked & ~has_dn_in) | fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];
assign f_r_c_en = (start_handshaked & ~has_dn_in) | fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];



assign f_r_s_d = 
  ({(GLOBAL_REM_W){fsm_q[FSM_PRE_0_BIT]}} & (is_fdiv_i ? f_r_s_before_iter_fdiv : {{(GLOBAL_REM_W - FSQRT_F64_REM_W){1'b0}}, f_r_s_before_iter_fsqrt[0 +: FSQRT_F64_REM_W]}))
| ({(GLOBAL_REM_W){fsm_q[FSM_PRE_1_BIT]}} & (is_fdiv_q ? f_r_s_before_iter_fdiv : {{(GLOBAL_REM_W - FSQRT_F64_REM_W){1'b0}}, f_r_s_before_iter_fsqrt[0 +: FSQRT_F64_REM_W]}))
| ({(GLOBAL_REM_W){fsm_q[FSM_ITER_BIT]}} & (is_fdiv_q ? f_r_s_3rd_fdiv : {{(GLOBAL_REM_W - FSQRT_F64_REM_W){1'b0}}, f_r_s_2nd_fsqrt[0 +: FSQRT_F64_REM_W]}));

assign f_r_c_d = 
  ({(GLOBAL_REM_W){fsm_q[FSM_PRE_0_BIT]}} & (is_fdiv_i ? f_r_c_before_iter_fdiv : {{(GLOBAL_REM_W - FSQRT_F64_REM_W){1'b0}}, f_r_c_before_iter_fsqrt[0 +: FSQRT_F64_REM_W]}))
| ({(GLOBAL_REM_W){fsm_q[FSM_PRE_1_BIT]}} & (is_fdiv_q ? f_r_c_before_iter_fdiv : {{(GLOBAL_REM_W - FSQRT_F64_REM_W){1'b0}}, f_r_c_before_iter_fsqrt[0 +: FSQRT_F64_REM_W]}))
| ({(GLOBAL_REM_W){fsm_q[FSM_ITER_BIT]}} & (is_fdiv_q ? f_r_c_3rd_fdiv : {{(GLOBAL_REM_W - FSQRT_F64_REM_W){1'b0}}, f_r_c_2nd_fsqrt[0 +: FSQRT_F64_REM_W]}));


// For fdiv, when "opb_frac_is_zero_xxx = 1" , we need to remember "opa_frac_prescaled". Otherwise, we coult just set "quot = quot_m1 = 0"
assign quot_before_iter_opb_frac_is_zero_pre_0 = 
  ({(54){f16_pre_0}} & {{(54 - 10 - 2){1'b0}}, opa_frac_prescaled[51 -: 10], 2'b0})
| ({(54){f32_pre_0}} & {{(54 - 23 - 1){1'b0}}, opa_frac_prescaled[51 -: 23], 1'b0})
| ({(54){f64_pre_0}} & {{(54 - 52 - 2){1'b0}}, opa_frac_prescaled[51 -: 52], 2'b0});
assign quot_before_iter_opb_frac_is_zero_pre_1 = 
  ({(54){f16_after_pre_0}} & {{(54 - 10 - 2){1'b0}}, opa_frac_prescaled[51 -: 10], 2'b0})
| ({(54){f32_after_pre_0}} & {{(54 - 23 - 1){1'b0}}, opa_frac_prescaled[51 -: 23], 1'b0})
| ({(54){f64_after_pre_0}} & {{(54 - 52 - 2){1'b0}}, opa_frac_prescaled[51 -: 52], 2'b0});

assign quot_before_iter = 
  ({(54){fsm_q[FSM_PRE_0_BIT] & opb_frac_is_zero_pre_0}} & quot_before_iter_opb_frac_is_zero_pre_0)
| ({(54){fsm_q[FSM_PRE_1_BIT] & opb_frac_is_zero_pre_1}} & quot_before_iter_opb_frac_is_zero_pre_1);

// TODO: What would happen if we don't CLEAR "quot_m1" before iter starts ?
assign quot_m1_before_iter = '0;

assign quot_root_iter_en = (start_handshaked) | fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];
assign quot_root_m1_iter_en = (start_handshaked) | fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT] | (fsm_q[FSM_POST_0_BIT] & need_denormalization);

// f_r_s_q/f_r_c_q is in the critial path, to optimize timing, we should:
// Use quot_root_iter_q to store opa_frac_l_shifted
// Use quot_root_m1_iter_q to store opb_frac_l_shifted
// QUOT_ROOT_W = 54
assign quot_root_iter_d = 
  ({(QUOT_ROOT_W){fsm_q[FSM_PRE_0_BIT] &  has_dn_in	&  opa_is_dn}} & {{(QUOT_ROOT_W - (F64_FRAC_W - 1)){1'b0}}, opa_frac_l_shifted[0 +: (F64_FRAC_W - 1)]})
| ({(QUOT_ROOT_W){fsm_q[FSM_PRE_0_BIT] &  has_dn_in	& ~opa_is_dn}} & {{(QUOT_ROOT_W - (F64_FRAC_W - 1)){1'b0}}, opa_frac_unshifted[0 +: (F64_FRAC_W - 1)]})
| ({(QUOT_ROOT_W){fsm_q[FSM_PRE_0_BIT] & ~has_dn_in				}} & (is_fdiv_i ? quot_before_iter : root_before_iter[0 +: 54]))
| ({(QUOT_ROOT_W){fsm_q[FSM_PRE_1_BIT]							}} & (is_fdiv_q ? quot_before_iter : root_before_iter[0 +: 54]))
| ({(QUOT_ROOT_W){fsm_q[FSM_ITER_BIT]							}} & (is_fdiv_q ? quot_3rd[0 +: QUOT_ROOT_W] : root_2nd[0 +: 54]));
// When "need_denormalization = 1", use "quot_root_m1_iter_q" to store the rshifted QUOT we got in PRE_0
assign quot_root_m1_iter_d = 
  ({(QUOT_ROOT_W){fsm_q[FSM_PRE_0_BIT] &  has_dn_in	&  opb_is_dn}} & {{(QUOT_ROOT_W - (F64_FRAC_W - 1)){1'b0}}, opb_frac_l_shifted[0 +: (F64_FRAC_W - 1)]})
| ({(QUOT_ROOT_W){fsm_q[FSM_PRE_0_BIT] &  has_dn_in	& ~opb_is_dn}} & {{(QUOT_ROOT_W - (F64_FRAC_W - 1)){1'b0}}, opb_frac_unshifted[0 +: (F64_FRAC_W - 1)]})
| ({(QUOT_ROOT_W){fsm_q[FSM_PRE_0_BIT] & ~has_dn_in				}} & (is_fdiv_i ? quot_m1_before_iter : {1'b0, root_m1_before_iter[0 +: 53]}))
| ({(QUOT_ROOT_W){fsm_q[FSM_PRE_1_BIT]							}} & (is_fdiv_q ? quot_m1_before_iter : {1'b0, root_m1_before_iter[0 +: 53]}))
| ({(QUOT_ROOT_W){fsm_q[FSM_ITER_BIT]							}} & (is_fdiv_q ? quot_m1_3rd[0 +: QUOT_ROOT_W] : {1'b0, root_m1_2nd[0 +: 53]}))
| ({(QUOT_ROOT_W){fsm_q[FSM_POST_0_BIT]							}} & {rem_is_not_zero_post_0, correct_quot_frac_shifted[52:0]});

// How to use "frac_D_q"
// FDIV
// PRE_0/PRE_1: opb_frac_scaled
// POST_0: 54-bit sticky_without_rem
// FSQRT
// Use [12:0] to store "MASK"
assign frac_D_en =
  (start_handshaked & ~has_dn_in)
| fsm_q[FSM_PRE_1_BIT]
| (fsm_q[FSM_ITER_BIT] & ~is_fdiv_q)
| (fsm_q[FSM_POST_0_BIT] & need_denormalization);

assign nxt_frac_D_before_iter_fdiv = opb_frac_scaled;
assign nxt_frac_D_before_iter_fsqrt = {{(57 - 13){1'b0}}, 1'b1, 12'b0};
assign nxt_frac_D_iter = frac_D_q >> 1;
assign nxt_frac_D_post_0 = {frac_D_q[56:54], sticky_without_rem[53:0]};

assign frac_D_d = 
  ({(57){fsm_q[FSM_PRE_0_BIT]}} & (is_fdiv_i ? nxt_frac_D_before_iter_fdiv : nxt_frac_D_before_iter_fsqrt))
| ({(57){fsm_q[FSM_PRE_1_BIT]}} & (is_fdiv_q ? nxt_frac_D_before_iter_fdiv : nxt_frac_D_before_iter_fsqrt))
| ({(57){fsm_q[FSM_ITER_BIT] }} & nxt_frac_D_iter)
| ({(57){fsm_q[FSM_POST_0_BIT]}} & nxt_frac_D_post_0);


assign final_iter = (iter_num_q == '0);
assign iter_num_en = start_handshaked | fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];
assign iter_num_fdiv_pre_0 = f16_pre_0 ? 4'd1 : f32_pre_0 ? 4'd3 : 4'd8;
assign iter_num_fdiv_pre_1 = f16_after_pre_0 ? 4'd1 : f32_after_pre_0 ? 4'd3 : 4'd8;
assign iter_num_fsqrt_pre_0 = f16_pre_0 ? 4'd2 : f32_pre_0 ? 4'd5 : 4'd12;
assign iter_num_fsqrt_pre_1 = f16_after_pre_0 ? 4'd2 : f32_after_pre_0 ? 4'd5 : 4'd12;

assign iter_num_fdiv = fsm_q[FSM_PRE_0_BIT] ? iter_num_fdiv_pre_0 : iter_num_fdiv_pre_1;
assign iter_num_fsqrt = fsm_q[FSM_PRE_0_BIT] ? iter_num_fsqrt_pre_0 : iter_num_fsqrt_pre_1;

// TODO: Can we use this reg to store some special situations to save regs ??
// For FSQRT, when opa is denormal, use iter_num_q[0] to store "opa_frac_l_shift_num[0]", so we can know whether opa_exp is odd in PRE_1
assign iter_num_d  = 
  ({(4){fsm_q[FSM_PRE_0_BIT] &  has_dn_in}} & {iter_num_q[3:1], opa_frac_l_shift_num[0]})
| ({(4){fsm_q[FSM_PRE_0_BIT] & ~has_dn_in}} & (is_fdiv_i ? iter_num_fdiv_pre_0 : iter_num_fsqrt_pre_0))
| ({(4){fsm_q[FSM_PRE_1_BIT]}} & (is_fdiv_q ? iter_num_fdiv_pre_1 : iter_num_fsqrt_pre_1))
| ({(4){fsm_q[FSM_ITER_BIT]}} & (iter_num_q - 4'd1));

always_ff @(posedge clk) begin
	if(f_r_s_en)
		f_r_s_q <= f_r_s_d;
	if(f_r_c_en)
		f_r_c_q <= f_r_c_d;
	if(frac_D_en)
		frac_D_q <= frac_D_d;
	if(quot_root_iter_en)
		quot_root_iter_q <= quot_root_iter_d;
	if(quot_root_m1_iter_en)
		quot_root_m1_iter_q <= quot_root_m1_iter_d;
	if(iter_num_en)
		iter_num_q <= iter_num_d;
end

// ================================================================================================================================================
// ================================================================================================================================================
fpdiv_r64_block #(
	.QDS_ARCH	(FDIV_QDS_ARCH),
	.REM_W		(GLOBAL_REM_W)
) u_fpdiv_r64_block (
	.f_r_s_i			(f_r_s_q),
	.f_r_c_i			(f_r_c_q),
	.divisor_i			(frac_D_q),

	.quot_dig_p2_1st_o	(quot_dig_p2_1st),
	.quot_dig_p1_1st_o	(quot_dig_p1_1st),
	.quot_dig_z0_1st_o	(quot_dig_z0_1st),
	.quot_dig_n1_1st_o	(quot_dig_n1_1st),
	.quot_dig_n2_1st_o	(quot_dig_n2_1st),
	.quot_dig_p2_2nd_o	(quot_dig_p2_2nd),
	.quot_dig_p1_2nd_o	(quot_dig_p1_2nd),
	.quot_dig_z0_2nd_o	(quot_dig_z0_2nd),
	.quot_dig_n1_2nd_o	(quot_dig_n1_2nd),
	.quot_dig_n2_2nd_o	(quot_dig_n2_2nd),
	.quot_dig_p2_3rd_o	(quot_dig_p2_3rd),
	.quot_dig_p1_3rd_o	(quot_dig_p1_3rd),
	.quot_dig_z0_3rd_o	(quot_dig_z0_3rd),
	.quot_dig_n1_3rd_o	(quot_dig_n1_3rd),
	.quot_dig_n2_3rd_o	(quot_dig_n2_3rd),

	.f_r_s_1st_o		(f_r_s_1st_fdiv),
	.f_r_s_2nd_o		(f_r_s_2nd_fdiv),
	.f_r_s_3rd_o		(f_r_s_3rd_fdiv),
	.f_r_c_1st_o		(f_r_c_1st_fdiv),
	.f_r_c_2nd_o		(f_r_c_2nd_fdiv),
	.f_r_c_3rd_o		(f_r_c_3rd_fdiv)
);

fpsqrt_r16_block #(
	.REM_W			(FSQRT_F64_REM_W)
) u_fpsqrt_r16_block (
	.f_r_s_i						(f_r_s_q[0 +: FSQRT_F64_REM_W]),
	.f_r_c_i						(f_r_c_q[0 +: FSQRT_F64_REM_W]),
	.root_i							(quot_root_iter_q[0 +: 54]),
	.root_m1_i						(quot_root_m1_iter_q[0 +: 53]),
	.rem_msb_nxt_cycle_1st_srt_i	(rem_msb_nxt_cycle_1st_srt_q),
	.m_n1_last_cycle_i				(m_n1_nxt_cycle_1st_srt_q),
	.m_z0_last_cycle_i				(m_z0_nxt_cycle_1st_srt_q),
	.m_p1_last_cycle_i				(m_p1_nxt_cycle_1st_srt_q),
	.m_p2_last_cycle_i				(m_p2_nxt_cycle_1st_srt_q),
	.mask_i							(frac_D_q[12:0]),
	
	.root_1st_o						(root_1st),
	.root_m1_1st_o					(root_m1_1st),
	.root_2nd_o						(root_2nd),
	.root_m1_2nd_o					(root_m1_2nd),

	.f_r_s_1st_o					(f_r_s_1st_fsqrt),
	.f_r_c_1st_o					(f_r_c_1st_fsqrt),
	.f_r_s_2nd_o					(f_r_s_2nd_fsqrt),
	.f_r_c_2nd_o					(f_r_c_2nd_fsqrt),

	.rem_msb_nxt_cycle_1st_srt_o	(rem_msb_nxt_cycle_1st_srt_after_iter),
	.m_n1_nxt_cycle_1st_srt_o		(m_n1_nxt_cycle_1st_srt_after_iter),
	.m_z0_nxt_cycle_1st_srt_o		(m_z0_nxt_cycle_1st_srt_after_iter),
	.m_p1_nxt_cycle_1st_srt_o		(m_p1_nxt_cycle_1st_srt_after_iter),
	.m_p2_nxt_cycle_1st_srt_o		(m_p2_nxt_cycle_1st_srt_after_iter)
);


// ================================================================================================================================================
// On the Fly Conversion (OFC/OTFC) for FDIV
// ================================================================================================================================================
assign quot_1st = 
  ({(56){quot_dig_p2_1st}} & {quot_root_iter_q   [54 - 1:0], 2'b10})
| ({(56){quot_dig_p1_1st}} & {quot_root_iter_q   [54 - 1:0], 2'b01})
| ({(56){quot_dig_z0_1st}} & {quot_root_iter_q   [54 - 1:0], 2'b00})
| ({(56){quot_dig_n1_1st}} & {quot_root_m1_iter_q[54 - 1:0], 2'b11})
| ({(56){quot_dig_n2_1st}} & {quot_root_m1_iter_q[54 - 1:0], 2'b10});
assign quot_m1_1st = 
  ({(56){quot_dig_p2_1st}} & {quot_root_iter_q   [54 - 1:0], 2'b01})
| ({(56){quot_dig_p1_1st}} & {quot_root_iter_q   [54 - 1:0], 2'b00})
| ({(56){quot_dig_z0_1st}} & {quot_root_m1_iter_q[54 - 1:0], 2'b11})
| ({(56){quot_dig_n1_1st}} & {quot_root_m1_iter_q[54 - 1:0], 2'b10})
| ({(56){quot_dig_n2_1st}} & {quot_root_m1_iter_q[54 - 1:0], 2'b01});

assign quot_2nd = 
  ({(56){quot_dig_p2_2nd}} & {quot_1st   [(56 - 1) - 2:0], 2'b10})
| ({(56){quot_dig_p1_2nd}} & {quot_1st   [(56 - 1) - 2:0], 2'b01})
| ({(56){quot_dig_z0_2nd}} & {quot_1st   [(56 - 1) - 2:0], 2'b00})
| ({(56){quot_dig_n1_2nd}} & {quot_m1_1st[(56 - 1) - 2:0], 2'b11})
| ({(56){quot_dig_n2_2nd}} & {quot_m1_1st[(56 - 1) - 2:0], 2'b10});
assign quot_m1_2nd = 
  ({(56){quot_dig_p2_2nd}} & {quot_1st   [(56 - 1) - 2:0], 2'b01})
| ({(56){quot_dig_p1_2nd}} & {quot_1st   [(56 - 1) - 2:0], 2'b00})
| ({(56){quot_dig_z0_2nd}} & {quot_m1_1st[(56 - 1) - 2:0], 2'b11})
| ({(56){quot_dig_n1_2nd}} & {quot_m1_1st[(56 - 1) - 2:0], 2'b10})
| ({(56){quot_dig_n2_2nd}} & {quot_m1_1st[(56 - 1) - 2:0], 2'b01});

assign quot_3rd = 
  ({(56){quot_dig_p2_3rd}} & {quot_2nd   [(56 - 1) - 2:0], 2'b10})
| ({(56){quot_dig_p1_3rd}} & {quot_2nd   [(56 - 1) - 2:0], 2'b01})
| ({(56){quot_dig_z0_3rd}} & {quot_2nd   [(56 - 1) - 2:0], 2'b00})
| ({(56){quot_dig_n1_3rd}} & {quot_m1_2nd[(56 - 1) - 2:0], 2'b11})
| ({(56){quot_dig_n2_3rd}} & {quot_m1_2nd[(56 - 1) - 2:0], 2'b10});
assign quot_m1_3rd = 
  ({(56){quot_dig_p2_3rd}} & {quot_2nd   [(56 - 1) - 2:0], 2'b01})
| ({(56){quot_dig_p1_3rd}} & {quot_2nd   [(56 - 1) - 2:0], 2'b00})
| ({(56){quot_dig_z0_3rd}} & {quot_m1_2nd[(56 - 1) - 2:0], 2'b11})
| ({(56){quot_dig_n1_3rd}} & {quot_m1_2nd[(56 - 1) - 2:0], 2'b10})
| ({(56){quot_dig_n2_3rd}} & {quot_m1_2nd[(56 - 1) - 2:0], 2'b01});


// ================================================================================================================================================
// Post Process: Denormalization (Only for FDIV) & Rounding
// ================================================================================================================================================

assign nr_f_r = f_r_s_q + f_r_c_q;

// For c[N-1:0] = a[N-1:0] + b[N-1:0], if we want to know the value of "c == 0", the common method is:
// 1. Use a N-bit FA to get c
// 2. Calculate (c == 0)
// The total delay = delay(N-bit FA) + delay(N-bit NOT OR)
// A faster method is:
// a_b_xor[N-2:0] = a[N-1:1] ^ b[N-1:1]
// a_b_or[N-2:0] = a[N-2:0] | b[N-2:0]
// Then, (c == 0) <=> (a_b_xor == a_b_or)
// Some examples
// a[15:0] = 1111001111000000
// b[15:0] = (2 ^ 16) - a = 0000110001000000
// a_b_xor[14:0] = 111111111000000
// a_b_or[14:0] = 111111111000000
// ->
// We get (a_b_xor == a_b_or), and we also get ((a + b) == 0)

// a[11:0] = 000000001111
// b[11:0] = (2 ^ 12) - a = 111111110001
// a_b_xor[10:0] = 11111111111
// a_b_or[10:0] = 11111111111
// -> 
// We get (a_b_xor == a_b_or), and we also get ((a + b) == 0)

// a[15:0] = 0101111100001111
// b[15:0] = (2 ^ 16) - a + 0000000011111111 = 1010000111110000
// a_b_xor[14:0] = 111111101111111
// a_b_or[14:0] = 111111111111111
// -> 
// We get (a_b_xor != a_b_or), and we also get ((a + b) != 0)

// By using the above method, the total delay = delay(XOR) + delay(XOR) + delay(N-bit NOT OR)
// For f_r, the MSB is sign, so we only need to know the value of "(f_r_s_q[(GLOBAL_REM_W - 1)-1:0] + f_r_c_q[(GLOBAL_REM_W - 1)-1:0]) == 0"
assign f_r_xor = f_r_s_q[(GLOBAL_REM_W - 1) - 1:1] ^ f_r_c_q[(GLOBAL_REM_W - 1) - 1:1];
assign f_r_or  = f_r_s_q[(GLOBAL_REM_W - 1) - 2:0] | f_r_c_q[(GLOBAL_REM_W - 1) - 2:0];

// The algorithm we use is "Minimally Redundant Radix 4", and its redundnat factor is 2/3.
// So we must have "|rem| <= D * (2/3)" -> When (nr_f_r < 0), "nr_f_r + frac_D" MUST be NON_ZERO
assign rem_is_not_zero_post_0 =
  (is_fdiv_q ? ~opb_is_power_of_2_q : 1'b1)
& ((is_fdiv_q ? nr_f_r[GLOBAL_REM_W - 1] : nr_f_r[FSQRT_F64_REM_W - 1]) | ((f_r_xor[53:0] != f_r_or[53:0]) | (is_fdiv_q & (f_r_xor[57:54] != f_r_or[57:54]))));

// In PRE_1, quot_root_m1_iter_q[53] = rem_is_not_zero_post_0
assign rem_is_not_zero_post_1 = quot_root_m1_iter_q[53] | (frac_D_q[53:0] != '0);
// Now, we have already got 55/25/13-bit QUOT for f64/f32/f16
// ATTENTION: The MSB must be 1 because we have already do a 1-bit l_shift in the initialization step when (a_frac < b_frac)
// F64: 55 = 53 + 2
// F32: 25 = 24 + 1
// F16: 13 = 11 + 2
// Consider F64, in fact, we don't need QUOT[0] to calculate sticky_bit:
// QUOT[0] = 0: REM could be ZERO/NON_ZERO
// QUOT[0] = 1: REM must also be NON_ZERO
// The proof is very easy: QUOT[0] has the weight of "2 ^ -54". When QUOT[0] = 1, "exact division" is impossible, and QUOT[1] is the "guard_bit".
// So, we only need "REM (nr_f_r)" to calculate sticky_bit
// The similiar optimization could also be applied to f16
// For f32, the optimization is not needed because we perfectly get 25-bit QUOT[24:0], and QUOT[0] is the "guard_bit"
assign quot_unshifted    = {f64_after_pre_0, quot_root_iter_q[53:26], f32_after_pre_0 ? {1'b1, quot_root_iter_q[23:0]} : {quot_root_iter_q[25:13], f16_after_pre_0 | quot_root_iter_q[12], quot_root_iter_q[11:1]}};
assign quot_m1_unshifted = {f64_after_pre_0, quot_root_m1_iter_q[53:26], f32_after_pre_0 ? {1'b1, quot_root_m1_iter_q[23:0]} : {quot_root_m1_iter_q[25:13], f16_after_pre_0 | quot_root_m1_iter_q[12], quot_root_m1_iter_q[11:1]}};
assign r_shift_num_post_0 = res_exp_q[5:0];

assign quot_shifted    = {quot_unshifted   , 54'b0} >> r_shift_num_post_0;
assign quot_m1_shifted = {quot_m1_unshifted, 54'b0} >> r_shift_num_post_0;

assign select_quot_m1 = nr_f_r[GLOBAL_REM_W - 1] & ~opb_is_power_of_2_q;
assign select_root_m1 = nr_f_r[FSQRT_F64_REM_W - 1] & ~res_is_sqrt2_q;
// We at most need "(2 ^ -1) ~ (2 ^ -53)" for rounding when "need_denormalization = 1"
assign correct_quot_frac_shifted = select_quot_m1 ? quot_m1_shifted[54 +: 53] : quot_shifted[54 +: 53];
assign sticky_without_rem = select_quot_m1 ? quot_m1_shifted[0 +: 54] : quot_shifted[0 +: 54];

// F64: quot_unshifted[53:0] is "2 ^ 0 ~ 2 ^ -53", we only need to increase the "2 ^ -1 ~ 2 ^ -52" part of the QUOT/ -> A 53-bit incrementer is enough
// F32: quot_unshifted[24:0] is "2 ^ 0 ~ 2 ^ -24", we only need to increase the "2 ^ -1 ~ 2 ^ -23" part of the QUOT/ -> A 24-bit incrementer is enough
// F16: quot_unshifted[11:0] is "2 ^ 0 ~ 2 ^ -11", we only need to increase the "2 ^ -1 ~ 2 ^ -10" part of the QUOT/ -> A 11-bit incrementer is enough
assign quot_before_inc[51:0] = fsm_q[FSM_POST_0_BIT] ? {
	quot_unshifted[52:25],
	f32_after_pre_0 ? 1'b0 : quot_unshifted[24],
	quot_unshifted[23:12],
	f16_after_pre_0 ? 1'b0 : quot_unshifted[11],
	quot_unshifted[10:1]
} : {
	quot_root_m1_iter_q[52:25],
	f32_after_pre_0 ? 1'b0 : quot_root_m1_iter_q[24],
	quot_root_m1_iter_q[23:12],
	f16_after_pre_0 ? 1'b0 : quot_root_m1_iter_q[11],
	quot_root_m1_iter_q[10:1]
};
// This is only needed in POST_0
assign quot_m1_before_inc = {
	quot_m1_unshifted[52:25],
	f32_after_pre_0 ? 1'b0 : quot_m1_unshifted[24],
	quot_m1_unshifted[23:12],
	f16_after_pre_0 ? 1'b0 : quot_m1_unshifted[11],
	quot_m1_unshifted[10:1]
};

// root_before_inc[0] is "guard_bit", and it is not used in INC
assign root_before_inc[52:0] = res_is_sqrt2_q ? SQRT_2_WITH_ROUND_BIT[0 +: 53] : quot_root_iter_q[0 +: 53];

assign quot_root_before_inc[51:0] = is_fdiv_q ? quot_before_inc : root_before_inc[52:1];

assign inc_poisition_fsqrt = 
  ({(52){f16_after_pre_0}} & { 9'b0, 1'b1, 42'b0})
| ({(52){f32_after_pre_0}} & {22'b0, 1'b1, 29'b0})
| ({(52){f64_after_pre_0}} & {51'b0, 1'b1});
assign inc_poisition_fdiv = {51'b0, 1'b1};
assign inc_poisition = is_fdiv_q ? inc_poisition_fdiv : inc_poisition_fsqrt;

assign quot_root_inc_res[52:0] = {1'b0, quot_root_before_inc[51:0]} + {1'b0, inc_poisition[51:0]};

// In POST_0, for QUOT_M1, a CARRY into "2 ^ 0" is impossible -> we only need 52-bit to store info
assign quot_m1_inc_res[51:0] = (quot_unshifted[1] == quot_m1_unshifted[1]) ? quot_root_inc_res[51:0] : quot_before_inc[51:0];

assign root_m1_inc_res = (root_l == root_m1_l) ? quot_root_inc_res[52:0] : {1'b0, root_before_inc[52:1]};

assign root_l = f16_after_pre_0 ? root_before_inc[43] : f32_after_pre_0 ? root_before_inc[30] : root_before_inc[1];
assign root_g = f16_after_pre_0 ? root_before_inc[42] : f32_after_pre_0 ? root_before_inc[29] : root_before_inc[0];
assign root_s = rem_is_not_zero_post_0;
// For SQRT, there is no "Midpoint" result, which means, if guard_bit is 1, then sticky_bit MUST be 1 as well. By using this property,
// We could know that the effect of RNE is totally equal to RMM. So we can save several gates here.
assign root_need_rup = 
  ({rm_q == RM_RNE} &  root_g)
| ({rm_q == RM_RUP} & (root_g | root_s))
| ({rm_q == RM_RMM} &  root_g);
assign root_inexact = root_g | root_s;

assign root_m1_l = f16_after_pre_0 ? quot_root_m1_iter_q[43] : f32_after_pre_0 ? quot_root_m1_iter_q[30] : quot_root_m1_iter_q[1];
assign root_m1_g = f16_after_pre_0 ? quot_root_m1_iter_q[42] : f32_after_pre_0 ? quot_root_m1_iter_q[29] : quot_root_m1_iter_q[0];
assign root_m1_s = 1'b1;
assign root_m1_need_rup = 
  ({rm_q == RM_RNE} &  root_m1_g)
| ({rm_q == RM_RUP} & (root_m1_g | root_m1_s))
| ({rm_q == RM_RMM} &  root_m1_g);
assign root_m1_inexact = 1'b1;

assign root_rounded = root_need_rup ? quot_root_inc_res[52:0] : {1'b0, root_before_inc[52:1]};
assign root_m1_rounded = root_m1_need_rup ? root_m1_inc_res[52:0] : {1'b0, quot_root_m1_iter_q[52:1]};
assign inexact_fsqrt = select_root_m1 | root_inexact;

assign frac_rounded_post_0_fsqrt[51:0] = select_root_m1 ? root_m1_rounded[51:0] : root_rounded[51:0];
assign carry_after_round_fsqrt = select_root_m1 ? root_m1_rounded[52] : root_rounded[52];
assign exp_rounded_fsqrt = carry_after_round_fsqrt ? (res_exp_q[10:0] + 11'd1) : res_exp_q[10:0];

assign quot_l = fsm_q[FSM_POST_0_BIT] ? quot_unshifted[1] : quot_root_m1_iter_q[1];
assign quot_g = fsm_q[FSM_POST_0_BIT] ? quot_unshifted[0] : quot_root_m1_iter_q[0];
assign quot_s = fsm_q[FSM_POST_0_BIT] ? rem_is_not_zero_post_0 : rem_is_not_zero_post_1;
assign quot_need_rup = 
  ({rm_q == RM_RNE} & ((quot_g & quot_s) | (quot_l & quot_g)))
| ({rm_q == RM_RDN} & ((quot_g | quot_s) &  res_sign_q))
| ({rm_q == RM_RUP} & ((quot_g | quot_s) & ~res_sign_q))
| ({rm_q == RM_RMM} & quot_g);
assign quot_inexact = quot_g | quot_s;

assign quot_m1_l = quot_m1_unshifted[1];
assign quot_m1_g = quot_m1_unshifted[0];
// When we need to use "QUOT_M1", the sticky_bit must be 1
assign quot_m1_s = 1'b1;
assign quot_m1_need_rup = 
  ({rm_q == RM_RNE} & ((quot_m1_g & quot_m1_s) | (quot_m1_l & quot_m1_g)))
| ({rm_q == RM_RDN} & ((quot_m1_g | quot_m1_s) &  res_sign_q))
| ({rm_q == RM_RUP} & ((quot_m1_g | quot_m1_s) & ~res_sign_q))
| ({rm_q == RM_RMM} & quot_m1_g);
assign quot_m1_inexact = 1'b1;

assign quot_rounded = quot_need_rup ? quot_root_inc_res[52:0] : {1'b0, quot_before_inc[51:0]};
assign quot_m1_rounded = quot_m1_need_rup ? quot_m1_inc_res[51:0] : quot_m1_before_inc[51:0];
assign inexact_fdiv = fsm_q[FSM_POST_0_BIT] ? (select_quot_m1 | quot_inexact) : quot_inexact;

assign inexact = is_fdiv_q ? inexact_fdiv : inexact_fsqrt;

assign frac_rounded_post_0_fdiv = select_quot_m1 ? quot_m1_rounded[51:0] : quot_rounded[51:0];
// A CARRY into "2 ^ 0" could only happen in POST_1 (denormal situation)
assign carry_after_round_fdiv = 
  (f16_after_pre_0 & quot_rounded[10])
| (f32_after_pre_0 & quot_rounded[23])
| (f64_after_pre_0 & quot_rounded[52]);


assign frac_rounded_post_0 = is_fdiv_q ? frac_rounded_post_0_fdiv : frac_rounded_post_0_fsqrt;


// OVERFLOW could only happen for FDIV. For FSQRT, res_exp_q[11] MUST be 0
// In post_0, the result must be a NM/OF number, OF could only happen in post_0
// It's impossible to generate a OF result by rounding up (Easy to prove)
assign of = res_exp_q[11];
assign of_to_inf = 
  (rm_q == RM_RNE) 
| (rm_q == RM_RMM) 
| ((rm_q == RM_RUP) & ~res_sign_q) 
| ((rm_q == RM_RDN) &  res_sign_q);

assign exp_res_post_0_f16 = 
(of &  of_to_inf) ? {(5){1'b1}} : 
(of & ~of_to_inf) ? {{(4){1'b1}}, 1'b0} : 
(is_fdiv_q ? res_exp_q[4:0] : exp_rounded_fsqrt[4:0]);

assign exp_res_post_0_f32 = 
(of &  of_to_inf) ? {(8){1'b1}} : 
(of & ~of_to_inf) ? {{(7){1'b1}}, 1'b0} : 
(is_fdiv_q ? res_exp_q[7:0] : exp_rounded_fsqrt[7:0]);

assign exp_res_post_0_f64 = 
(of &  of_to_inf) ? {(11){1'b1}} : 
(of & ~of_to_inf) ? {{(10){1'b1}}, 1'b0} : 
(is_fdiv_q ? res_exp_q[10:0] : exp_rounded_fsqrt[10:0]);

assign frac_res_post_0_f16 = 
(of &  of_to_inf) ? 10'b0 : 
(of & ~of_to_inf) ? {(10){1'b1}} : 
(is_fdiv_q ? frac_rounded_post_0_fdiv[9:0] : frac_rounded_post_0_fsqrt[51 -: 10]);

assign frac_res_post_0_f32 = 
(of &  of_to_inf) ? 23'b0 : 
(of & ~of_to_inf) ? {(23){1'b1}} : 
(is_fdiv_q ? frac_rounded_post_0_fdiv[22:0] : frac_rounded_post_0_fsqrt[51 -: 23]);

assign frac_res_post_0_f64 = 
(of &  of_to_inf) ? 52'b0 : 
(of & ~of_to_inf) ? {(52){1'b1}} : 
(is_fdiv_q ? frac_rounded_post_0_fdiv[51:0] : frac_rounded_post_0_fsqrt[51 -: 52]);


assign final_res_post_0_f16 = {res_sign_q, exp_res_post_0_f16, frac_res_post_0_f16};
assign final_res_post_0_f32 = {res_sign_q, exp_res_post_0_f32, frac_res_post_0_f32};
assign final_res_post_0_f64 = {res_sign_q, exp_res_post_0_f64, frac_res_post_0_f64};

assign final_res_post_0 = {
	final_res_post_0_f64[63:32],
	  ({(16){f32_after_pre_0}} & final_res_post_0_f32[31:16])
	| ({(16){f64_after_pre_0}} & final_res_post_0_f64[31:16]),
	  ({(16){f16_after_pre_0}} & final_res_post_0_f16[15: 0])
	| ({(16){f32_after_pre_0}} & final_res_post_0_f32[15: 0])
	| ({(16){f64_after_pre_0}} & final_res_post_0_f64[15: 0])
};

// In POST_1, the result before rounding must be a denormal number or a special number
assign exp_res_post_1_f16 = 
(res_is_nan_q | res_is_inf_q) ? {(5){1'b1}} : 
res_is_exact_zero_q ? 5'b0 : 
{4'b0, carry_after_round_fdiv};

assign exp_res_post_1_f32 = 
(res_is_nan_q | res_is_inf_q) ? {(8){1'b1}} : 
res_is_exact_zero_q ? 8'b0 : 
{7'b0, carry_after_round_fdiv};

assign exp_res_post_1_f64 = 
(res_is_nan_q | res_is_inf_q) ? {(11){1'b1}} : 
res_is_exact_zero_q ? 11'b0 : 
{10'b0, carry_after_round_fdiv};

assign frac_res_post_1_f16 = 
res_is_nan_q ? {1'b1, 9'b0} : 
(res_is_inf_q | res_is_exact_zero_q) ? 10'b0 : 
quot_rounded[9:0];

assign frac_res_post_1_f32 = 
res_is_nan_q ? {1'b1, 22'b0} : 
(res_is_inf_q | res_is_exact_zero_q) ? 23'b0 : 
quot_rounded[22:0];

assign frac_res_post_1_f64 = 
res_is_nan_q ? {1'b1, 51'b0} : 
(res_is_inf_q | res_is_exact_zero_q) ? 52'b0 : 
quot_rounded[51:0];

assign final_res_post_1_f16 = {res_sign_q, exp_res_post_1_f16, frac_res_post_1_f16};
assign final_res_post_1_f32 = {res_sign_q, exp_res_post_1_f32, frac_res_post_1_f32};
assign final_res_post_1_f64 = {res_sign_q, exp_res_post_1_f64, frac_res_post_1_f64};

assign final_res_post_1 = {
	final_res_post_1_f64[63:32],
	  ({(16){f32_after_pre_0}} & final_res_post_1_f32[31:16])
	| ({(16){f64_after_pre_0}} & final_res_post_1_f64[31:16]),
	  ({(16){f16_after_pre_0}} & final_res_post_1_f16[15: 0])
	| ({(16){f32_after_pre_0}} & final_res_post_1_f32[15: 0])
	| ({(16){f64_after_pre_0}} & final_res_post_1_f64[15: 0])
};

assign fpdivsqrt_res_o = fsm_q[FSM_POST_0_BIT] ? final_res_post_0 : final_res_post_1;

assign fflags_invalid_operation = op_invalid_q;
assign fflags_div_by_zero = divided_by_zero_q;
// of could only happen in post_0
assign fflags_of = fsm_q[FSM_POST_0_BIT] & of;
// uf could only happen in post_1
assign fflags_uf = fsm_q[FSM_POST_1_BIT] & ~carry_after_round_fdiv & inexact & ~res_is_exact_zero_q & ~res_is_inf_q & ~res_is_nan_q;
assign fflags_inexact = ((fsm_q[FSM_POST_0_BIT] & of) | inexact) & ~res_is_inf_q & ~res_is_nan_q & ~res_is_exact_zero_q;

assign fflags_o = {
	fflags_invalid_operation,
	fflags_div_by_zero,
	fflags_of,
	fflags_uf,
	fflags_inexact
};






endmodule

