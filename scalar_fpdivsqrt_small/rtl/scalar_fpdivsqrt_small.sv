// ========================================================================================================
// File Name			: scalar_fpdivsqrt_small.sv
// Author				: HYF
// How to Contact		: hyf_sysu@qq.com
// Created Time    		: July 5th 2024, 16:39:25
// Last Modified Time   : July 19th 2024, 16:13:43
// ========================================================================================================
// Description	:
// A Scalar Floating Point Divider/Sqrt based on Minimally Redundant Radix-4 SRT Algorithm.
// FDIV and SQRT both use Radix-16.
// It supports f32/f64.
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

module scalar_fpdivsqrt_small #(
	// Put some parameters here, which can be changed by other modules
	parameter FDIV_QDS_ARCH 		= 2,
	parameter FDIV_SRT_2ND_SPEC 	= 1,
	parameter FSQRT_SRT_2ND_SPEC 	= 1,
	parameter UF_AFTER_ROUNDING 	= 1,
	parameter NAN_BOXING 			= 1
)(
	input  logic 			start_valid_i,
	output logic 			start_ready_o,
	input  logic 			flush_i,
	// [0]: f32
	// [1]: f64
	input  logic [ 2-1:0] 	fp_format_i,
	input  logic 			is_fdiv_i,
	// f32: src should be put in opa[31:0]/opb[31:0]
	// f64: src should be put in opa[63:0]/opb[63:0]
	// fsqrt: src should be put in opa, opb will be ignored
	input  logic [64-1:0] 	opa_i,
	input  logic [64-1:0] 	opb_i,
	input  logic [ 3-1:0] 	rm_i,

	output logic 			finish_valid_o,
	input  logic 			finish_ready_i,
	output logic [64-1:0] 	fdivsqrt_res_o,
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


// F64: it will generate 14 * 4 = 56-bit QUOT in total. But QUOT[55:54] MUST BE 2'b01 in the end -> We only need 54-bit to store quot.
localparam F64_QUOT_W = 54;
// F32: it will generate  7 * 4 = 28-bit QUOT in total. But QUOT[27:26] MUST BE 2'b01 in the end -> We only need 26-bit to store quot.
localparam F32_QUOT_W = 26;
// F16: it will generate  4 * 4 = 16-bit QUOT in total. But QUOT[15:14] MUST BE 2'b01 in the end -> We only need 14-bit to store quot.
localparam F16_QUOT_W = 14;

localparam QUOT_ROOT_W = 54;

// {-2, -1, 0, +1, +2}
localparam QUOT_ROOT_DIGIT_W = 5;

// frac_f64[52] <=> 2 ^  0
// frac_f64[51] <=> 2 ^ -1
// frac_f64[50] <=> 2 ^ -2
// ...
// frac_f64[ 1] <=> 2 ^ -52
// frac_f64[ 0] <=> 2 ^ -53
// The field of the "REM" used in iter is:
// 1: sign
// 1: fraca would do 1-bit lsh if (fraca_lt_fracb == 1)
// 2: rem[0] = dividend / 4, so we need to do 2-bit rsh before iter
// 1 + 53 + 3: after scaling operation, we would have 57-bit fraca/fracb
localparam FDIV_F64_REM_W = 1 + 1 + 2 + 1 + 53 + 3;
localparam FDIV_F32_REM_W = 1 + 1 + 2 + 1 + 24 + 3;
localparam FDIV_F16_REM_W = 1 + 1 + 2 + 1 + 11 + 3;

// FDIV_F64_REM_W >= FSQRT_F64_REM_W
localparam GLOBAL_REM_W = FDIV_F64_REM_W;

localparam FSM_W = 4;
localparam FSM_PRE_0 	= (1 << 0);
localparam FSM_PRE_1 	= (1 << 1);
localparam FSM_ITER  	= (1 << 2);
localparam FSM_POST 	= (1 << 3);

localparam FSM_PRE_0_BIT 	= 0;
localparam FSM_PRE_1_BIT	= 1;
localparam FSM_ITER_BIT 	= 2;
localparam FSM_POST_BIT 	= 3;

// Used when we find that the op is the power of 2 and it has an odd_exp.
localparam [54 - 1:0] SQRT_2_WITH_ROUND_BIT = 54'b1_01101010000010011110011001100111111100111011110011001;


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
// rsh = right shift
// lsh = left shift
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
logic res_sign_d;
logic res_sign_q;

logic f32_pre_0;
logic f64_pre_0;
logic f32_after_pre_0_d;
logic f32_after_pre_0_q;
logic f64_after_pre_0_d;
logic f64_after_pre_0_q;
logic rne_d;
logic rne_q;
logic rtz_d;
logic rtz_q;
logic rup_d;
logic rup_q;
logic rmm_d;
logic rmm_q;
logic rtz_temp;
logic rdn_temp;
logic rup_temp;


logic res_exp_en;
logic [13 - 1:0] res_exp_d;
logic [13 - 1:0] res_exp_q;
logic [13 - 1:0] nxt_res_exp_pre_0;
logic [13 - 1:0] nxt_res_exp_pre_1;
logic [13 - 1:0] exp_diff;
logic [13 - 1:0] exp_diff_m1;
logic [13 - 1:0] res_exp_fdiv_pre_0;
logic [13 - 1:0] res_exp_fdiv_pre_1;
logic [13 - 1:0] res_exp_dn_in_fsqrt_pre_0;
logic [12 - 1:0] res_exp_nm_in_fsqrt_pre_0;
logic [13 - 1:0] res_exp_fsqrt_pre_0;
logic [12 - 1:0] res_exp_fsqrt_pre_1;

logic res_exp_zero;
logic res_exp_dn;
logic res_exp_of;
logic [ 6 - 1:0] quot_bits_needed_res_exp_nm;
logic [13 - 1:0] quot_bits_needed_res_exp_dn_temp;
logic [ 6 - 1:0] quot_bits_needed_res_exp_dn;
logic [ 6 - 1:0] quot_bits_needed;
logic [ 6 - 1:0] quot_bits_calculated;
logic quot_bits_calculated_ge_quot_bits_needed;
logic [4 - 1:0] quot_discard_num_one_hot;
logic quot_discard_not_zero;
logic [4 - 1:0] quot_discard_num_post;
logic add_1_to_quot_msb;
logic add_1_to_quot_msb_post;

logic signa;
logic signb;
logic sign_fdiv;
logic sign_fsqrt;
logic [11 - 1:0] expa;
logic [11 - 1:0] expb;
logic [11 - 1:0] expa_adjusted;
logic [11 - 1:0] expb_adjusted;
logic [12 - 1:0] expa_plus_bias;
logic expa_zero;
logic expb_zero;
logic expa_all_1;
logic expb_all_1;
logic opa_zero;
logic opb_zero;

logic fraca_zero_pre_0;
logic fracb_zero_pre_0;
logic fraca_zero_pre_1;
logic fracb_zero_pre_1;

logic opa_inf;
logic opb_inf;
logic opa_qnan;
logic opb_qnan;
logic opa_qnan_nan_boxing;
logic opb_qnan_nan_boxing;
logic opa_snan;
logic opb_snan;
logic opa_nan;
logic opb_nan;
logic opa_dn;
logic opb_dn;

logic fraca_lt_fracb;
logic [F64_FRAC_W-1:0] fraca_unlsh;
logic [F64_FRAC_W-1:0] fracb_unlsh;
logic [$clog2(F64_FRAC_W)-1:0] fraca_lsh_num_temp;
logic [$clog2(F64_FRAC_W)-1:0] fracb_lsh_num_temp;

logic frac_lsh_num_en;
logic [$clog2(F64_FRAC_W)-1:0] fraca_lsh_num_d;
logic [$clog2(F64_FRAC_W)-1:0] fraca_lsh_num_q;
logic [$clog2(F64_FRAC_W)-1:0] fracb_lsh_num_d;
logic [$clog2(F64_FRAC_W)-1:0] fracb_lsh_num_q;

logic [(F64_FRAC_W-1)-1:0] fraca_lsh;
logic [(F64_FRAC_W-1)-1:0] fracb_lsh;
logic [3 - 1:0] scaling_factor_idx;

logic [F64_FRAC_W - 1:0] fraca_prescaled_pre_0;
logic [F64_FRAC_W - 1:0] fracb_prescaled_pre_0;
logic [F64_FRAC_W - 1:0] fraca_prescaled_pre_1;
logic [F64_FRAC_W - 1:0] fracb_prescaled_pre_1;
logic [F64_FRAC_W - 1:0] fraca_prescaled;
logic [F64_FRAC_W - 1:0] fracb_prescaled;

logic [55:0] fraca_prescaled_rsh_0;
logic [55:0] fraca_prescaled_rsh_1;
logic [55:0] fraca_prescaled_rsh_2;
logic [55:0] fraca_prescaled_rsh_3;
logic [55:0] fracb_prescaled_rsh_0;
logic [55:0] fracb_prescaled_rsh_1;
logic [55:0] fracb_prescaled_rsh_2;
logic [55:0] fracb_prescaled_rsh_3;

logic [55:0] fraca_scaled_csa_in_0;
logic [55:0] fraca_scaled_csa_in_1;
logic [55:0] fraca_scaled_csa_in_2;
logic [55:0] fracb_scaled_csa_in_0;
logic [55:0] fracb_scaled_csa_in_1;
logic [55:0] fracb_scaled_csa_in_2;

logic [55:0] fraca_scaled_sum;
logic [55:0] fraca_scaled_carry;
logic [55:0] fracb_scaled_sum;
logic [55:0] fracb_scaled_carry;
logic [56:0] fraca_scaled;
logic [56:0] fracb_scaled;

logic exp_odd_fsqrt;
logic [(F64_FRAC_W - 1) - 1:0] frac_fsqrt;
logic root_dig_n2_1st;
logic root_dig_n1_1st;
logic root_dig_z0_1st;

logic fsqrt_info_nxt_cycle_en;
logic [7 - 1:0] rem_msb_nxt_cycle_1st_srt_d;
logic [7 - 1:0] rem_msb_nxt_cycle_1st_srt_q;
logic [9 - 1:0] rem_msb_nxt_cycle_2nd_srt_d;
logic [9 - 1:0] rem_msb_nxt_cycle_2nd_srt_q;
logic [8 - 1:0] rem_msb_nxt_cycle_1st_srt_before_iter;
logic [7 - 1:0] rem_msb_nxt_cycle_1st_srt_after_iter;
logic [9 - 1:0] rem_msb_nxt_cycle_2nd_srt_before_iter;
logic [9 - 1:0] rem_msb_nxt_cycle_2nd_srt_after_iter;

logic a0_before_iter;
logic a2_before_iter;
logic a3_before_iter;
logic a4_before_iter;

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
logic [QUOT_ROOT_W - 1:0] quot_m1_before_iter_fracb_zero_pre_0;
logic [QUOT_ROOT_W - 1:0] quot_m1_before_iter_fracb_zero_pre_1;

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

logic [GLOBAL_REM_W - 1:0] f_r_s_1st_fdiv;
logic [GLOBAL_REM_W - 1:0] f_r_s_2nd_fdiv;
logic [GLOBAL_REM_W - 1:0] f_r_c_1st_fdiv;
logic [GLOBAL_REM_W - 1:0] f_r_c_2nd_fdiv;

logic [FSQRT_F64_REM_W - 1:0] f_r_s_1st_fsqrt;
logic [FSQRT_F64_REM_W - 1:0] f_r_c_1st_fsqrt;
logic [FSQRT_F64_REM_W - 1:0] f_r_s_2nd_fsqrt;
logic [FSQRT_F64_REM_W - 1:0] f_r_c_2nd_fsqrt;

logic [56 - 1:0] quot_1st;
logic [56 - 1:0] quot_2nd;
logic [56 - 1:0] quot_m1_1st;
logic [56 - 1:0] quot_m1_2nd;

logic [54 - 1:0] root_1st;
logic [53 - 1:0] root_m1_1st;
logic [54 - 1:0] root_2nd;
logic [53 - 1:0] root_m1_2nd;


// ================================================================================================================================================
// Some special cases

logic early_finish_fdiv_pre_0;
logic early_finish_fsqrt_pre_0;

logic early_finish_pre_0;
logic early_finish_pre_1;

logic invalid_operation_fdiv;
logic invalid_operation_fsqrt;
logic invalid_operation_d;
logic invalid_operation_q;

logic res_nan_fdiv;
logic res_inf_fdiv;
logic res_exact_zero_fdiv;

logic res_nan_fsqrt;
logic res_inf_fsqrt;
logic res_exact_zero_fsqrt;

logic res_sqrt2_pre_0;
logic res_sqrt2_pre_1;

logic res_nan_d;
logic res_nan_q;

logic res_inf_d;
logic res_inf_q;

logic res_exact_zero_d;
logic res_exact_zero_q;

logic opb_power_of_2_en;
logic opb_power_of_2_d;
logic opb_power_of_2_q;

logic res_sqrt2_en;
logic res_sqrt2_d;
logic res_sqrt2_q;

logic divided_by_zero_d;
logic divided_by_zero_q;

// ================================================================================================================================================

logic f_r_fdiv_en;
logic [GLOBAL_REM_W-1:0] f_r_s_fdiv_d;
logic [GLOBAL_REM_W-1:0] f_r_s_fdiv_q;
logic [GLOBAL_REM_W-1:0] f_r_c_fdiv_d;
logic [GLOBAL_REM_W-1:0] f_r_c_fdiv_q;

logic f_r_fsqrt_en;
logic [FSQRT_F64_REM_W-1:0] f_r_s_fsqrt_d;
logic [FSQRT_F64_REM_W-1:0] f_r_s_fsqrt_q;
logic [FSQRT_F64_REM_W-1:0] f_r_c_fsqrt_d;
logic [FSQRT_F64_REM_W-1:0] f_r_c_fsqrt_q;

// 57 = F64_FRAC_W + 4
logic frac_D_en;
logic [57 - 1:0] frac_D_d;
logic [57 - 1:0] frac_D_q;
logic [57 - 1:0] nxt_frac_D_before_iter_fdiv;
logic [57 - 1:0] nxt_frac_D_before_iter_fsqrt;
logic [57 - 1:0] nxt_frac_D_iter;

logic quot_root_iter_en;
logic [QUOT_ROOT_W - 1:0] quot_root_iter_d;
logic [QUOT_ROOT_W - 1:0] quot_root_iter_q;
logic quot_root_m1_iter_en;
logic [QUOT_ROOT_W - 1:0] quot_root_m1_iter_d;
logic [QUOT_ROOT_W - 1:0] quot_root_m1_iter_q;

logic [(QUOT_ROOT_W + 1) - 1:0] quot_rsh_0;
logic [(QUOT_ROOT_W + 1) - 1:0] quot_rsh_1;
logic [(QUOT_ROOT_W + 1) - 1:0] quot_rsh_2;
logic [(QUOT_ROOT_W + 1) - 1:0] quot_rsh_3;
logic [(QUOT_ROOT_W + 1) - 1:0] quot_m1_rsh_0;
logic [(QUOT_ROOT_W + 1) - 1:0] quot_m1_rsh_1;
logic [(QUOT_ROOT_W + 1) - 1:0] quot_m1_rsh_2;
logic [(QUOT_ROOT_W + 1) - 1:0] quot_m1_rsh_3;

logic iter_counter_en;
logic [6 - 1:0] iter_counter_d;
logic [6 - 1:0] iter_counter_q;
logic [6 - 1:0] iter_counter_start_value_fsqrt_pre_0;
logic [6 - 1:0] iter_counter_start_value_fsqrt_pre_1;
logic [6 - 1:0] iter_counter_nxt;
logic final_iter;

logic [GLOBAL_REM_W - 1:0] f_r_s_post;
logic [GLOBAL_REM_W - 1:0] f_r_c_post;
logic [GLOBAL_REM_W - 1:0] nr_f_r;
logic [(GLOBAL_REM_W - 2) - 1:0] f_r_xor;
logic [(GLOBAL_REM_W - 2) - 1:0] f_r_or;
logic rem_not_zero;

logic select_quot_m1;
logic select_root_m1;

logic [53 - 1:0] quot_before_inc;
logic [53 - 1:0] quot_m1_before_inc;
logic [53 - 1:0] quot_m1_inc_res;
logic [53 - 1:0] root_m1_inc_res;
logic [53 - 1:0] root_before_inc;
logic [53 - 1:0] root_m1_before_inc;
logic [52 - 1:0] quot_root_before_inc;
logic [52 - 1:0] inc_poisition_fsqrt;
logic [52 - 1:0] inc_poisition_fdiv;
logic [52 - 1:0] inc_poisition;
logic [53 - 1:0] quot_root_inc_res;

logic quot_before_round_all_1;
logic quot_m1_before_round_all_1;
logic carry_after_round_quot;
logic carry_after_round_quot_m1;
logic carry_after_round_fdiv;

logic root_before_round_all_1;
logic root_m1_before_round_all_1;
logic carry_after_round_root;
logic carry_after_round_root_m1;
logic carry_after_round_fsqrt;

logic sel_overflow_res;
logic sel_special_res;
logic [32 - 1:0] overflow_res_f32;
logic [64 - 1:0] overflow_res_f64;
logic [64 - 1:0] overflow_res;
logic [32 - 1:0] special_res_f32;
logic [64 - 1:0] special_res_f64;
logic [64 - 1:0] special_res;
logic [32 - 1:0] normal_res_f32;
logic [64 - 1:0] normal_res_f64;
logic [64 - 1:0] normal_res;

logic inexact;
logic inexact_fdiv;
logic inexact_fsqrt;

logic quot_l;
logic quot_g;
logic quot_s;
logic quot_m1_l;
logic quot_m1_g;
logic quot_m1_s;
logic quot_need_round_up;
logic quot_m1_need_round_up;
logic quot_inexact;
logic quot_m1_inexact;

logic quot_l_uf_check;
logic quot_g_uf_check;
logic quot_s_uf_check;
logic quot_uf_check_need_round_up;
logic quot_m1_l_uf_check;
logic quot_m1_g_uf_check;
logic quot_m1_s_uf_check;
logic quot_m1_uf_check_need_round_up;
logic quot_uf_check_before_round_all_1;
logic quot_m1_uf_check_before_round_all_1;
logic carry_after_round_quot_uf_check;
logic carry_after_round_quot_m1_uf_check;
logic carry_after_round_uf_check;

logic [53 - 1:0] quot_rounded;
logic [53 - 1:0] quot_m1_rounded;
logic [53 - 1:0] root_rounded;
logic [53 - 1:0] root_m1_rounded;

logic root_l;
logic root_g;
logic root_s;
logic root_need_round_up;
logic root_inexact;
logic root_m1_l;
logic root_m1_g;
logic root_m1_s;
logic root_m1_need_round_up;
logic root_m1_inexact;

logic [52 - 1:0] frac_rounded_fsqrt;
logic [52 - 1:0] frac_rounded_fdiv;
logic [52 - 1:0] frac_rounded;
logic [11 - 1:0] exp_rounded_fsqrt;
logic [11 - 1:0] exp_rounded_fdiv;
logic [11 - 1:0] exp_before_round_fdiv;
logic [11 - 1:0] exp_rounded;


logic fflags_invalid_operation;
logic fflags_divded_by_zero;
logic fflags_overflow;
logic fflags_underflow;
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
				early_finish_pre_0 ? FSM_POST :
				has_dn_in ? FSM_PRE_1 :
				FSM_ITER
			) : 
			FSM_PRE_0;
		FSM_PRE_1:
			fsm_d = early_finish_pre_1 ? FSM_POST : FSM_ITER;
		FSM_ITER:
			fsm_d = final_iter ? FSM_POST : FSM_ITER;
		FSM_POST:
			fsm_d = finish_ready_i ? FSM_PRE_0 : FSM_POST;
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
assign finish_valid_o = fsm_q[FSM_POST_BIT];

assign f32_pre_0 = fp_format_i[0];
assign f64_pre_0 = fp_format_i[1];

// ================================================================================================================================================
// SRC unpacking
// ================================================================================================================================================

assign signa = f32_pre_0 ? opa_i[31] : opa_i[63];
assign signb = f32_pre_0 ? opb_i[31] : opb_i[63];

assign expa = f32_pre_0 ? {3'b0, opa_i[30:23]} : opa_i[62:52];
assign expb = f32_pre_0 ? {3'b0, opb_i[30:23]} : opb_i[62:52];
assign expa_zero = (expa == '0);
assign expb_zero = (expb == '0);
assign expa_adjusted = f32_pre_0 ? {3'b0, opa_i[30:24], opa_i[23] | expa_zero} : {opa_i[62:53], opa_i[52] | expa_zero};
assign expb_adjusted = f32_pre_0 ? {3'b0, opb_i[30:24], opb_i[23] | expb_zero} : {opb_i[62:53], opb_i[52] | expb_zero};
assign expa_plus_bias = {1'b0, expa_adjusted[10:0]} + (f32_pre_0 ? 12'd127 : 12'd1023);
assign expa_all_1 = (expa == (f32_pre_0 ? {3'b0, {(8){1'b1}}} : {(11){1'b1}}));
assign expb_all_1 = (expb == (f32_pre_0 ? {3'b0, {(8){1'b1}}} : {(11){1'b1}}));

assign opa_zero = expa_zero & fraca_zero_pre_0 & ~opa_qnan_nan_boxing;
assign opb_zero = expb_zero & fracb_zero_pre_0 & ~opb_qnan_nan_boxing;
assign opa_dn = expa_zero & ~fraca_zero_pre_0;
assign opb_dn = expb_zero & ~fracb_zero_pre_0;
assign has_dn_in = opa_dn | (opb_dn & is_fdiv_i);

assign opa_qnan_nan_boxing = (NAN_BOXING == 1) & f32_pre_0 & (opa_i[63:32] != {(32){1'b1}});
assign opb_qnan_nan_boxing = (NAN_BOXING == 1) & f32_pre_0 & (opb_i[63:32] != {(32){1'b1}});
assign opa_qnan = (expa_all_1 & (f32_pre_0 ? opa_i[22] : opa_i[51])) | opa_qnan_nan_boxing;
assign opb_qnan = (expb_all_1 & (f32_pre_0 ? opb_i[22] : opb_i[51])) | opb_qnan_nan_boxing;
assign opa_snan = expa_all_1 & ~fraca_zero_pre_0 & (f32_pre_0 ? ~opa_i[22] : ~opa_i[51]) & ~opa_qnan_nan_boxing;
assign opb_snan = expb_all_1 & ~fracb_zero_pre_0 & (f32_pre_0 ? ~opb_i[22] : ~opb_i[51]) & ~opb_qnan_nan_boxing;
assign opa_nan = (opa_qnan | opa_snan);
assign opb_nan = (opb_qnan | opb_snan);

assign opa_inf = expa_all_1 & fraca_zero_pre_0 & ~opa_qnan_nan_boxing;
assign opb_inf = expb_all_1 & fracb_zero_pre_0 & ~opb_qnan_nan_boxing;

assign invalid_operation_fdiv = ((opa_inf & opb_inf) | (opa_zero & opb_zero) | opa_snan | opb_snan);
assign invalid_operation_fsqrt = (signa & ~opa_zero & ~opa_qnan) | opa_snan;

assign res_nan_fdiv = opa_nan | opb_nan | invalid_operation_fdiv;
assign res_inf_fdiv = (opa_inf & ~opb_nan & ~opb_inf) | (~opa_zero & ~opa_nan & opb_zero);
assign res_exact_zero_fdiv = (opa_zero & ~opb_nan & ~opb_zero) | (~opa_inf & ~opa_nan & opb_inf);

assign res_nan_fsqrt = opa_nan | invalid_operation_fsqrt;
assign res_inf_fsqrt = opa_inf & ~signa;
assign res_exact_zero_fsqrt = opa_zero;

// In PRE_1, opa and opb have already been 2 nm numbers
assign fraca_zero_pre_1 = (quot_root_iter_q[0 +: (F64_FRAC_W - 1)] == '0);
assign fracb_zero_pre_1 = (quot_root_m1_iter_q[0 +: (F64_FRAC_W - 1)] == '0);

// {opa_dn, res_sqrt2_pre_0} can't be 2'b11 in PRE_0
assign res_sqrt2_pre_0 = fraca_zero_pre_0 & ~expa[0];
assign res_sqrt2_pre_1 = fraca_zero_pre_1 & iter_counter_q[0];

assign early_finish_fdiv_pre_0 =  
  res_nan_fdiv
| res_inf_fdiv
| res_exact_zero_fdiv;

assign early_finish_fsqrt_pre_0 = 
  res_nan_fsqrt
| res_inf_fsqrt
| res_exact_zero_fsqrt
| (fraca_zero_pre_0 & ~expa_zero);

assign early_finish_pre_0 =
  ( is_fdiv_i & early_finish_fdiv_pre_0)
| (~is_fdiv_i & early_finish_fsqrt_pre_0);

// Only fsqrt could lead to "early_finish" in pre_1
assign early_finish_pre_1 = ~is_fdiv_q & fraca_zero_pre_1;

// When result is not nan, and dividend is not inf, "dividend / 0" should lead to "DIVDED_BY_ZERO" exception.
// When "divided_by_zero_d = 1", "res_inf_fdiv" is also 1, so it will also lead to "early_finish"
assign divided_by_zero_d = ~res_nan_fdiv & ~opa_inf & opb_zero & is_fdiv_i;

assign sign_fdiv = signa ^ signb;
assign sign_fsqrt = signa;

assign rne_d = (rm_i == RM_RNE);
assign rtz_temp = (rm_i == RM_RTZ);
assign rdn_temp = (rm_i == RM_RDN);
assign rup_temp = (rm_i == RM_RUP);
assign rmm_d = (rm_i == RM_RMM);

assign rtz_d = 
  ( res_sign_d & rup_temp)
| (~res_sign_d & rdn_temp)
| rtz_temp;
assign rup_d = 
  ( res_sign_d & rdn_temp)
| (~res_sign_d & rup_temp);

assign res_sign_d = (is_fdiv_i & sign_fdiv) | (~is_fdiv_i & sign_fsqrt);
assign f32_after_pre_0_d = f32_pre_0;
assign f64_after_pre_0_d = f64_pre_0;

assign res_nan_d = (res_nan_fdiv & is_fdiv_i) | (res_nan_fsqrt & ~is_fdiv_i);
assign res_inf_d = (res_inf_fdiv & is_fdiv_i) | (res_inf_fsqrt & ~is_fdiv_i);
assign res_exact_zero_d = (res_exact_zero_fdiv & is_fdiv_i) | (res_exact_zero_fsqrt & ~is_fdiv_i);
assign invalid_operation_d = (invalid_operation_fdiv & is_fdiv_i) | (invalid_operation_fsqrt & ~is_fdiv_i);
assign is_fdiv_d = is_fdiv_i;

assign opb_power_of_2_en = (is_fdiv_i & start_handshaked) | (is_fdiv_q & fsm_q[FSM_PRE_1_BIT]) | (is_fdiv_q & fsm_q[FSM_ITER_BIT]);
// FDIV: When (opb_power_of_2_q & res_exp_dn), we just use SRT to get final result -> Here we clear "opb_power_of_2_q"
assign opb_power_of_2_d = 
  ({(1){fsm_q[FSM_PRE_0_BIT]}} & fracb_zero_pre_0)
| ({(1){fsm_q[FSM_PRE_1_BIT]}} & fracb_zero_pre_1)
| ({(1){fsm_q[FSM_ITER_BIT ]}} & (res_exp_dn ? '0 : opb_power_of_2_q));

assign res_sqrt2_en = (~is_fdiv_i & start_handshaked) | (~is_fdiv_q & fsm_q[FSM_PRE_1_BIT]);
assign res_sqrt2_d = fsm_q[FSM_PRE_0_BIT] ? res_sqrt2_pre_0 : res_sqrt2_pre_1;

always_ff @(posedge clk) begin
	if(start_handshaked) begin		
		is_fdiv_q <= is_fdiv_d;
		res_sign_q <= res_sign_d;
		f32_after_pre_0_q <= f32_after_pre_0_d;
		f64_after_pre_0_q <= f64_after_pre_0_d;

		rne_q <= rne_d;
		rtz_q <= rtz_d;
		rup_q <= rup_d;
		rmm_q <= rmm_d;		

		res_nan_q <= res_nan_d;
		res_inf_q <= res_inf_d;
		res_exact_zero_q <= res_exact_zero_d;
		invalid_operation_q <= invalid_operation_d;
		divided_by_zero_q <= divided_by_zero_d;
	end

	if(opb_power_of_2_en)
		opb_power_of_2_q <= opb_power_of_2_d;
	
	if(res_sqrt2_en)
		res_sqrt2_q <= res_sqrt2_d;
end

// ================================================================================================================================================
// EXP logic for FDIV
// ================================================================================================================================================
assign exp_diff = {1'b0, expa_plus_bias} - {2'b0, expb_adjusted};
assign exp_diff_m1 = exp_diff - 13'd1;

assign res_exp_fdiv_pre_0 = has_dn_in ? exp_diff : (fraca_lt_fracb ? exp_diff_m1 : exp_diff);
assign res_exp_fdiv_pre_1 = res_exp_q[12:0] - {7'b0, fraca_lsh_num_q[5:0]} + {7'b0, fracb_lsh_num_q[5:0]} - {12'b0, fraca_lt_fracb};


// ================================================================================================================================================
// EXP logic for FSQRT
// ================================================================================================================================================
// It might be a little bit difficult to understand the logic here.
// E: Real exponent of a number
// exp: The encoded value of E in a particular fp_format
// Take F64 as an example:
// x.E = 1023
// x.exp[10:0] = 1023 + 1023 = 11111111110
// sqrt_res.E = (1023 - 1) / 2 = 511
// sqrt_res.exp = 511 + 1023 = 10111111110
// Since x is a nm number -> fraca_lsh_num[5:0] = 000000
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
// Since x is a dn number -> fraca_lsh_num[5:0] = 100010
// res_exp_fsqrt[11:0] = 
// 000000000001 + 
// 001111011101 (2'b0, 1111, ~fraca_lsh_num[5:0]) = 
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

// Keep original "expa" when "dn_in"
assign res_exp_dn_in_fsqrt_pre_0[12:0] = {2'b0, expa_adjusted[10:0]};
assign res_exp_nm_in_fsqrt_pre_0[11:0] = {1'b0, expa_adjusted[10:0]} + {
	2'b0,
	f32_pre_0 ? {3'b0, 2'b11, 1'b1} : {4'b1111, 2'b11},
	4'b1111
};
assign res_exp_fsqrt_pre_0[12:0] = opa_dn ? res_exp_dn_in_fsqrt_pre_0[12:0] : {2'b0, res_exp_nm_in_fsqrt_pre_0[11:1]};

assign res_exp_fsqrt_pre_1[11:0] = {1'b0, res_exp_q[10:0]} + {
	2'b0,
	f32_pre_0 ? {3'b0, 2'b11, ~fraca_lsh_num_q[4]} : {4'b1111, ~fraca_lsh_num_q[5:4]},
	~fraca_lsh_num_q[3:0]
};


// What should we store in "res_exp_q" in PRE_0 ?
// FDIV: res_exp_fdiv_pre_0
// FSQRT: res_exp_fsqrt_pre_0
// What should we store in "res_exp_q" in PRE_1 ?
// FDIV: res_exp_fdiv_pre_1
// FSQRT: res_exp_fsqrt_pre_1

assign nxt_res_exp_pre_0 = is_fdiv_i ? res_exp_fdiv_pre_0 : res_exp_fsqrt_pre_0;

assign nxt_res_exp_pre_1 = is_fdiv_q ? res_exp_fdiv_pre_1 : {2'b0, res_exp_fsqrt_pre_1[11:1]};

assign res_exp_en = start_handshaked | fsm_q[FSM_PRE_1_BIT];
assign res_exp_d  = 
  ({(13){fsm_q[FSM_PRE_0_BIT]}} & nxt_res_exp_pre_0)
| ({(13){fsm_q[FSM_PRE_1_BIT]}} & nxt_res_exp_pre_1);
always_ff @(posedge clk)
	if(res_exp_en)
		res_exp_q <= res_exp_d;

// ================================================================================================================================================
// Skipping the First iteration for FSQRT
// ================================================================================================================================================

assign exp_odd_fsqrt = fsm_q[FSM_PRE_0_BIT] ? ~expa[0] : iter_counter_q[0];
assign frac_fsqrt = fsm_q[FSM_PRE_0_BIT] ? fraca_unlsh[0 +: (F64_FRAC_W - 1)] : quot_root_iter_q[0 +: (F64_FRAC_W - 1)];
// Look at the REF paper for more details.
// even_exp, digit in (2 ^ -1) is 0: s[1] = -2, root = {0}.{1, 53'b0} , root_m1 = {0}.{01, 52'b0}
// even_exp, digit in (2 ^ -1) is 1: s[1] = -1, root = {0}.{11, 52'b0}, root_m1 = {0}.{10, 52'b0}
// odd_exp, digit in (2 ^ -1) is 0 : s[1] = -1, root = {0}.{11, 52'b0}, root_m1 = {0}.{10, 52'b0}
// odd_exp, digit in (2 ^ -1) is 1 : s[1] =  0, root = {1}.{00, 52'b0}, root_m1 = {0}.{11, 52'b0}
assign root_dig_n2_1st = ({exp_odd_fsqrt, frac_fsqrt[F64_FRAC_W - 2]} == 2'b00);
assign root_dig_n1_1st = ({exp_odd_fsqrt, frac_fsqrt[F64_FRAC_W - 2]} == 2'b01) | ({exp_odd_fsqrt, frac_fsqrt[F64_FRAC_W - 2]} == 2'b10);
assign root_dig_z0_1st = ({exp_odd_fsqrt, frac_fsqrt[F64_FRAC_W - 2]} == 2'b11);

// When (opa_power_of_2) and odd_exp: 
// f_r_s_before_iter_fsqrt = {1, 55'b0}
// f_r_c_before_iter_fsqrt = {0111, 52'b0}
// In the nxt cycle, we would have "nr_f_r != 0" and "nr_f_r[REM_W-1] == 1". This is what we need, to get the correct rounded result for sqrt(2)
// When (opa_power_of_2) and even_exp: 
// f_r_s_before_iter_fsqrt = {01, 54'b0}
// f_r_c_before_iter_fsqrt = {11, 54'b0}
// In the nxt cycle, we would have "nr_f_r == 0". This is what we need, to get the correct rounded result for sqrt(1)
// In conclusion, when (opa_power_of_2), the ITER step could be skipped, and we only need to use 1-bit reg to store "opa_power_of_2 & exp_odd_fsqrt", 
// instead of using 2-bit reg to store "{opa_power_of_2, exp_odd_fsqrt}"
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

assign f_r_s_before_iter_pre_fsqrt[FSQRT_F64_REM_W - 1:0] = {2'b11, exp_odd_fsqrt ? {1'b1, frac_fsqrt, 1'b0} : {1'b0, 1'b1, frac_fsqrt}};
assign f_r_s_before_iter_fsqrt[FSQRT_F64_REM_W - 1:0] = {f_r_s_before_iter_pre_fsqrt[(FSQRT_F64_REM_W - 1) - 2:0], 2'b0};
assign f_r_c_before_iter_fsqrt = 
  ({(FSQRT_F64_REM_W){root_dig_n2_1st}} & {2'b11  , {(FSQRT_F64_REM_W - 2){1'b0}}})
| ({(FSQRT_F64_REM_W){root_dig_n1_1st}} & {4'b0111, {(FSQRT_F64_REM_W - 4){1'b0}}})
| ({(FSQRT_F64_REM_W){root_dig_z0_1st}} & {			{(FSQRT_F64_REM_W - 0){1'b0}}});

// "f_r_c_before_iter_fsqrt" would only have 4-bit non-zero value, so a 4-bit FA is enough here
assign rem_msb_nxt_cycle_1st_srt_before_iter[7:0] = {f_r_s_before_iter_fsqrt[(FSQRT_F64_REM_W - 1) -: 4] + f_r_c_before_iter_fsqrt[(FSQRT_F64_REM_W - 1) -: 4], f_r_s_before_iter_fsqrt[(FSQRT_F64_REM_W - 1) - 4 -: 4]};
// "f_r_c_before_iter_fsqrt * 4" would only have 2-bit non-zero value, so a 2-bit FA is enough here
assign rem_msb_nxt_cycle_2nd_srt_before_iter[8:0] = {f_r_s_before_iter_fsqrt[(FSQRT_F64_REM_W - 1) - 2 -: 2] + f_r_c_before_iter_fsqrt[(FSQRT_F64_REM_W - 1) - 2 -: 2], f_r_s_before_iter_fsqrt[(FSQRT_F64_REM_W - 1) - 2 - 2 -: 7]};

assign fsqrt_info_nxt_cycle_en = (start_handshaked & ~has_dn_in & ~is_fdiv_i) | (fsm_q[FSM_PRE_1_BIT] & ~is_fdiv_q) | (fsm_q[FSM_ITER_BIT] & ~is_fdiv_q);

assign rem_msb_nxt_cycle_1st_srt_d = 
  ({(7){fsm_q[FSM_PRE_0_BIT] | fsm_q[FSM_PRE_1_BIT]	}} & rem_msb_nxt_cycle_1st_srt_before_iter[7:1])
| ({(7){fsm_q[FSM_ITER_BIT]							}} & rem_msb_nxt_cycle_1st_srt_after_iter[6:0]);

assign rem_msb_nxt_cycle_2nd_srt_d = 
  ({(9){fsm_q[FSM_PRE_0_BIT] | fsm_q[FSM_PRE_1_BIT]	}} & rem_msb_nxt_cycle_2nd_srt_before_iter[8:0])
| ({(9){fsm_q[FSM_ITER_BIT]							}} & rem_msb_nxt_cycle_2nd_srt_after_iter[8:0]);

assign a0_before_iter = root_before_iter[F64_FULL_ROOT_W - 1];
assign a2_before_iter = root_before_iter[F64_FULL_ROOT_W - 3];
assign a3_before_iter = root_before_iter[F64_FULL_ROOT_W - 4];
assign a4_before_iter = root_before_iter[F64_FULL_ROOT_W - 5];

fsqrt_r4_qds_constants_generator u_fsqrt_r4_qds_constants_generator_before_iter (
	.a0_i           (a0_before_iter),
	.a2_i           (a2_before_iter),
	.a3_i           (a3_before_iter),
	.a4_i           (a4_before_iter),
	.m_n1_o         (m_n1_nxt_cycle_1st_srt_before_iter),
	.m_z0_o         (m_z0_nxt_cycle_1st_srt_before_iter),
	.m_p1_o         (m_p1_nxt_cycle_1st_srt_before_iter),
	.m_p2_o         (m_p2_nxt_cycle_1st_srt_before_iter)
);

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
	if(fsqrt_info_nxt_cycle_en) begin
		rem_msb_nxt_cycle_1st_srt_q <= rem_msb_nxt_cycle_1st_srt_d;
		rem_msb_nxt_cycle_2nd_srt_q <= rem_msb_nxt_cycle_2nd_srt_d;

		m_n1_nxt_cycle_1st_srt_q <= m_n1_nxt_cycle_1st_srt_d;
		m_z0_nxt_cycle_1st_srt_q <= m_z0_nxt_cycle_1st_srt_d;
		m_p1_nxt_cycle_1st_srt_q <= m_p1_nxt_cycle_1st_srt_d;
		m_p2_nxt_cycle_1st_srt_q <= m_p2_nxt_cycle_1st_srt_d;
	end
end

// ================================================================================================================================================
// Normalization
// ================================================================================================================================================
assign fraca_unlsh = f32_pre_0 ? {1'b0, opa_i[0 +: (F32_FRAC_W - 1)], {(F64_FRAC_W - F32_FRAC_W){1'b0}}} : {1'b0, opa_i[0 +: (F64_FRAC_W - 1)], {(F64_FRAC_W - F64_FRAC_W){1'b0}}};
assign fracb_unlsh = f32_pre_0 ? {1'b0, opb_i[0 +: (F32_FRAC_W - 1)], {(F64_FRAC_W - F32_FRAC_W){1'b0}}} : {1'b0, opb_i[0 +: (F64_FRAC_W - 1)], {(F64_FRAC_W - F64_FRAC_W){1'b0}}};

lzc #(
	.WIDTH(F64_FRAC_W),
	// 0: trailing zero.
	// 1: leading zero.
	.MODE(1'b1)
) u_lzc_fraca (
	.in_i		(fraca_unlsh),
	.cnt_o		(fraca_lsh_num_temp),
	// The hidden bit of frac is not considered here
	.empty_o	(fraca_zero_pre_0)
);

lzc #(
	.WIDTH(F64_FRAC_W),
	// 0: trailing zero.
	// 1: leading zero.
	.MODE(1'b1)
) u_lzc_fracb (
	.in_i		(fracb_unlsh),
	.cnt_o		(fracb_lsh_num_temp),
	// The hidden bit of frac is not considered here
	.empty_o	(fracb_zero_pre_0)
);


frac_lsh u_lsh_fraca (
	.lsh_i				(fraca_lsh_num_temp),
	.frac_unshifted		(fraca_unlsh[0 +: (F64_FRAC_W - 1)]),
	.frac_shifted		(fraca_lsh)
);
frac_lsh u_lsh_fracb (
	.lsh_i				(fracb_lsh_num_temp),
	.frac_unshifted		(fracb_unlsh[0 +: (F64_FRAC_W - 1)]),
	.frac_shifted		(fracb_lsh)
);

assign fraca_lt_fracb =
  (fsm_q[FSM_PRE_0_BIT] ? fraca_prescaled_pre_0[0 +: (F64_FRAC_W - 1)] : fraca_prescaled_pre_1[0 +: (F64_FRAC_W - 1)])
< (fsm_q[FSM_PRE_0_BIT] ? fracb_prescaled_pre_0[0 +: (F64_FRAC_W - 1)] : fracb_prescaled_pre_1[0 +: (F64_FRAC_W - 1)]);

assign frac_lsh_num_en = start_handshaked & has_dn_in;
assign fraca_lsh_num_d = {(6){expa_zero}} & fraca_lsh_num_temp;
assign fracb_lsh_num_d = {(6){expb_zero}} & fracb_lsh_num_temp;

always_ff @(posedge clk) begin
	if(frac_lsh_num_en) begin
		fraca_lsh_num_q <= fraca_lsh_num_d;
		fracb_lsh_num_q <= fracb_lsh_num_d;
	end
end

// ================================================================================================================================================
// PRESCALING
// ================================================================================================================================================

assign fraca_prescaled_pre_0 = {1'b1, fraca_unlsh[0 +: (F64_FRAC_W - 1)]};
assign fracb_prescaled_pre_0 = {1'b1, fracb_unlsh[0 +: (F64_FRAC_W - 1)]};
// In PRE_1, quot_root_iter_q = fraca_lsh, quot_root_m1_iter_q = fracb_lsh
assign fraca_prescaled_pre_1 = {1'b1, quot_root_iter_q[0 +: (F64_FRAC_W - 1)]};
assign fracb_prescaled_pre_1 = {1'b1, quot_root_m1_iter_q[0 +: (F64_FRAC_W - 1)]};
assign fraca_prescaled = fsm_q[FSM_PRE_0_BIT] ? fraca_prescaled_pre_0 : fraca_prescaled_pre_1;
assign fracb_prescaled = fsm_q[FSM_PRE_0_BIT] ? fracb_prescaled_pre_0 : fracb_prescaled_pre_1;

assign scaling_factor_idx = fracb_prescaled[51 -: 3];

assign fraca_prescaled_rsh_0[55:0] = {fraca_prescaled, 3'b0};
assign fraca_prescaled_rsh_1[55:0] = {1'b0, fraca_prescaled, 2'b0};
assign fraca_prescaled_rsh_2[55:0] = {2'b0, fraca_prescaled, 1'b0};
assign fraca_prescaled_rsh_3[55:0] = {3'b0, fraca_prescaled};

assign fracb_prescaled_rsh_0[55:0] = {fracb_prescaled, 3'b0};
assign fracb_prescaled_rsh_1[55:0] = {1'b0, fracb_prescaled, 2'b0};
assign fracb_prescaled_rsh_2[55:0] = {2'b0, fracb_prescaled, 1'b0};
assign fracb_prescaled_rsh_3[55:0] = {3'b0, fracb_prescaled};

assign fraca_scaled_csa_in_0[55:0] = fraca_prescaled_rsh_0;
// assign fraca_scaled_csa_in_1[55:0] = 
//   ({(56){scaling_factor_idx == 3'd0}} & fraca_prescaled_rsh_1)
// | ({(56){scaling_factor_idx == 3'd1}} & fraca_prescaled_rsh_2)
// | ({(56){scaling_factor_idx == 3'd2}} & fraca_prescaled_rsh_1)
// | ({(56){scaling_factor_idx == 3'd3}} & fraca_prescaled_rsh_1)
// | ({(56){scaling_factor_idx == 3'd4}} & fraca_prescaled_rsh_2)
// | ({(56){scaling_factor_idx == 3'd5}} & fraca_prescaled_rsh_2)
// | ({(56){scaling_factor_idx == 3'd6}} & '0)
// | ({(56){scaling_factor_idx == 3'd7}} & '0);
// assign fraca_scaled_csa_in_2[55:0] = 
//   ({(56){scaling_factor_idx == 3'd0}} & fraca_prescaled_rsh_1)
// | ({(56){scaling_factor_idx == 3'd1}} & fraca_prescaled_rsh_1)
// | ({(56){scaling_factor_idx == 3'd2}} & fraca_prescaled_rsh_3)
// | ({(56){scaling_factor_idx == 3'd3}} & '0)
// | ({(56){scaling_factor_idx == 3'd4}} & fraca_prescaled_rsh_3)
// | ({(56){scaling_factor_idx == 3'd5}} & '0)
// | ({(56){scaling_factor_idx == 3'd6}} & fraca_prescaled_rsh_3)
// | ({(56){scaling_factor_idx == 3'd7}} & fraca_prescaled_rsh_3);

assign fraca_scaled_csa_in_1[55:0] = 
  ({(56){~scaling_factor_idx[2] & (scaling_factor_idx[1] | ~scaling_factor_idx[0])}} & fraca_prescaled_rsh_1)
| ({(56){~scaling_factor_idx[1] & (scaling_factor_idx[2] |  scaling_factor_idx[0])}} & fraca_prescaled_rsh_2);
assign fraca_scaled_csa_in_2[55:0] = 
  ({(56){~scaling_factor_idx[2] & ~scaling_factor_idx[1]}} & fraca_prescaled_rsh_1)
| ({(56){((scaling_factor_idx[2] | scaling_factor_idx[1]) & ~scaling_factor_idx[0]) | (scaling_factor_idx[2] & scaling_factor_idx[1])}} & fraca_prescaled_rsh_3);

assign fracb_scaled_csa_in_0[55:0] = fracb_prescaled_rsh_0;
// assign fracb_scaled_csa_in_1[55:0] = 
//   ({(56){scaling_factor_idx == 3'd0}} & fracb_prescaled_rsh_1)
// | ({(56){scaling_factor_idx == 3'd1}} & fracb_prescaled_rsh_2)
// | ({(56){scaling_factor_idx == 3'd2}} & fracb_prescaled_rsh_1)
// | ({(56){scaling_factor_idx == 3'd3}} & fracb_prescaled_rsh_1)
// | ({(56){scaling_factor_idx == 3'd4}} & fracb_prescaled_rsh_2)
// | ({(56){scaling_factor_idx == 3'd5}} & fracb_prescaled_rsh_2)
// | ({(56){scaling_factor_idx == 3'd6}} & '0)
// | ({(56){scaling_factor_idx == 3'd7}} & '0);
// assign fracb_scaled_csa_in_2[55:0] = 
//   ({(56){scaling_factor_idx == 3'd0}} & fracb_prescaled_rsh_1)
// | ({(56){scaling_factor_idx == 3'd1}} & fracb_prescaled_rsh_1)
// | ({(56){scaling_factor_idx == 3'd2}} & fracb_prescaled_rsh_3)
// | ({(56){scaling_factor_idx == 3'd3}} & '0)
// | ({(56){scaling_factor_idx == 3'd4}} & fracb_prescaled_rsh_3)
// | ({(56){scaling_factor_idx == 3'd5}} & '0)
// | ({(56){scaling_factor_idx == 3'd6}} & fracb_prescaled_rsh_3)
// | ({(56){scaling_factor_idx == 3'd7}} & fracb_prescaled_rsh_3);

assign fracb_scaled_csa_in_1[55:0] = 
  ({(56){~scaling_factor_idx[2] & (scaling_factor_idx[1] | ~scaling_factor_idx[0])}} & fracb_prescaled_rsh_1)
| ({(56){~scaling_factor_idx[1] & (scaling_factor_idx[2] |  scaling_factor_idx[0])}} & fracb_prescaled_rsh_2);
assign fracb_scaled_csa_in_2[55:0] = 
  ({(56){~scaling_factor_idx[2] & ~scaling_factor_idx[1]}} & fracb_prescaled_rsh_1)
| ({(56){((scaling_factor_idx[2] | scaling_factor_idx[1]) & ~scaling_factor_idx[0]) | (scaling_factor_idx[2] & scaling_factor_idx[1])}} & fracb_prescaled_rsh_3);


assign fraca_scaled_sum = fraca_scaled_csa_in_0 ^ fraca_scaled_csa_in_1 ^ fraca_scaled_csa_in_2;
assign fraca_scaled_carry = {
	  (fraca_scaled_csa_in_0[54:0] & fraca_scaled_csa_in_1[54:0])
	| (fraca_scaled_csa_in_0[54:0] & fraca_scaled_csa_in_2[54:0])
	| (fraca_scaled_csa_in_1[54:0] & fraca_scaled_csa_in_2[54:0]),
	1'b0
};
assign fraca_scaled[56:0] = {1'b0, fraca_scaled_sum[55:0]} + {1'b0, fraca_scaled_carry[55:0]};

assign fracb_scaled_sum = fracb_scaled_csa_in_0 ^ fracb_scaled_csa_in_1 ^ fracb_scaled_csa_in_2;
assign fracb_scaled_carry = {
	  (fracb_scaled_csa_in_0[54:0] & fracb_scaled_csa_in_1[54:0])
	| (fracb_scaled_csa_in_0[54:0] & fracb_scaled_csa_in_2[54:0])
	| (fracb_scaled_csa_in_1[54:0] & fracb_scaled_csa_in_2[54:0]),
	1'b0
};
assign fracb_scaled[56:0] = {1'b0, fracb_scaled_sum[55:0]} + {1'b0, fracb_scaled_carry[55:0]};

// rem[0] = dividend / 4
assign f_r_s_before_iter_fdiv = {1'b0, 2'b0, fraca_lt_fracb ? {fraca_scaled[56:0], 1'b0} : {1'b0, fraca_scaled[56:0]}};
assign f_r_c_before_iter_fdiv = '0;

assign f_r_fdiv_en = (start_handshaked & ~has_dn_in & is_fdiv_i) | (is_fdiv_q & (fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT]));
assign f_r_fsqrt_en = (start_handshaked & ~opa_dn & ~is_fdiv_i) | (~is_fdiv_q & (fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT]));

assign f_r_s_fdiv_d = 
  ({(GLOBAL_REM_W){fsm_q[FSM_PRE_0_BIT]}} & f_r_s_before_iter_fdiv)
| ({(GLOBAL_REM_W){fsm_q[FSM_PRE_1_BIT]}} & f_r_s_before_iter_fdiv)
| ({(GLOBAL_REM_W){fsm_q[FSM_ITER_BIT ]}} & f_r_s_2nd_fdiv);

assign f_r_c_fdiv_d = 
  ({(GLOBAL_REM_W){fsm_q[FSM_PRE_0_BIT]}} & f_r_c_before_iter_fdiv)
| ({(GLOBAL_REM_W){fsm_q[FSM_PRE_1_BIT]}} & f_r_c_before_iter_fdiv)
| ({(GLOBAL_REM_W){fsm_q[FSM_ITER_BIT ]}} & f_r_c_2nd_fdiv);

assign f_r_s_fsqrt_d = 
  ({(FSQRT_F64_REM_W){fsm_q[FSM_PRE_0_BIT]}} & f_r_s_before_iter_fsqrt)
| ({(FSQRT_F64_REM_W){fsm_q[FSM_PRE_1_BIT]}} & f_r_s_before_iter_fsqrt)
| ({(FSQRT_F64_REM_W){fsm_q[FSM_ITER_BIT ]}} & f_r_s_2nd_fsqrt);

assign f_r_c_fsqrt_d = 
  ({(FSQRT_F64_REM_W){fsm_q[FSM_PRE_0_BIT]}} & f_r_c_before_iter_fsqrt)
| ({(FSQRT_F64_REM_W){fsm_q[FSM_PRE_1_BIT]}} & f_r_c_before_iter_fsqrt)
| ({(FSQRT_F64_REM_W){fsm_q[FSM_ITER_BIT ]}} & f_r_c_2nd_fsqrt);

// FDIV: When "fracb_zero_pre_0/fracb_zero_pre_1 = 1" , we need to remember "fraca_prescaled".
assign quot_m1_before_iter_fracb_zero_pre_0 = f32_pre_0 ? {{(54 - 23 - 1){1'b0}}, fraca_prescaled[51 -: 23], 1'b0} : {{(54 - 52 - 1){1'b0}}, fraca_prescaled[51 -: 52], 1'b0};
assign quot_m1_before_iter_fracb_zero_pre_1 = f32_after_pre_0_q ? {{(54 - 23 - 1){1'b0}}, fraca_prescaled[51 -: 23], 1'b0} : {{(54 - 52 - 1){1'b0}}, fraca_prescaled[51 -: 52], 1'b0};

assign quot_before_iter = '0;

assign quot_m1_before_iter =
  ({(QUOT_ROOT_W){fsm_q[FSM_PRE_0_BIT]}} & quot_m1_before_iter_fracb_zero_pre_0)
| ({(QUOT_ROOT_W){fsm_q[FSM_PRE_1_BIT]}} & quot_m1_before_iter_fracb_zero_pre_1);

assign quot_root_iter_en = start_handshaked | fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];
// FDIV: When (opb_power_of_2_q & ~res_exp_dn), "quot_root_m1_iter_q" has already remembered "fraca_prescaled", don't change it.
assign quot_root_m1_iter_en = start_handshaked | fsm_q[FSM_PRE_1_BIT] | (fsm_q[FSM_ITER_BIT] & (is_fdiv_q ? ~(opb_power_of_2_q & ~res_exp_dn) : 1'b1));

// f_r_s_q/f_r_c_q is in the critial path, to optimize timing, we should:
// Use quot_root_iter_q to store "fraca_lsh"
// Use quot_root_m1_iter_q to store "fracb_lsh"
// QUOT_ROOT_W = 54
assign quot_root_iter_d = 
  ({(QUOT_ROOT_W){fsm_q[FSM_PRE_0_BIT] &  has_dn_in	&  opa_dn}} & {{(QUOT_ROOT_W - (F64_FRAC_W - 1)){1'b0}}, fraca_lsh[0 +: (F64_FRAC_W - 1)]})
| ({(QUOT_ROOT_W){fsm_q[FSM_PRE_0_BIT] &  has_dn_in	& ~opa_dn}} & {{(QUOT_ROOT_W - (F64_FRAC_W - 1)){1'b0}}, fraca_unlsh[0 +: (F64_FRAC_W - 1)]})
| ({(QUOT_ROOT_W){fsm_q[FSM_PRE_0_BIT] & ~has_dn_in				}} & (is_fdiv_i ? quot_before_iter : root_before_iter[0 +: 54]))
| ({(QUOT_ROOT_W){fsm_q[FSM_PRE_1_BIT]							}} & (is_fdiv_q ? quot_before_iter : root_before_iter[0 +: 54]))
| ({(QUOT_ROOT_W){fsm_q[FSM_ITER_BIT]							}} & (is_fdiv_q ? quot_2nd[0 +: QUOT_ROOT_W] : root_2nd[0 +: 54]));

assign quot_root_m1_iter_d = 
  ({(QUOT_ROOT_W){fsm_q[FSM_PRE_0_BIT] &  has_dn_in	&  opb_dn}} & {{(QUOT_ROOT_W - (F64_FRAC_W - 1)){1'b0}}, fracb_lsh[0 +: (F64_FRAC_W - 1)]})
| ({(QUOT_ROOT_W){fsm_q[FSM_PRE_0_BIT] &  has_dn_in	& ~opb_dn}} & {{(QUOT_ROOT_W - (F64_FRAC_W - 1)){1'b0}}, fracb_unlsh[0 +: (F64_FRAC_W - 1)]})
| ({(QUOT_ROOT_W){fsm_q[FSM_PRE_0_BIT] & ~has_dn_in				}} & (is_fdiv_i ? quot_m1_before_iter : {1'b0, root_m1_before_iter[0 +: 53]}))
| ({(QUOT_ROOT_W){fsm_q[FSM_PRE_1_BIT]							}} & (is_fdiv_q ? quot_m1_before_iter : {1'b0, root_m1_before_iter[0 +: 53]}))
| ({(QUOT_ROOT_W){fsm_q[FSM_ITER_BIT]							}} & (is_fdiv_q ? quot_m1_2nd[0 +: QUOT_ROOT_W] : {1'b0, root_m1_2nd[0 +: 53]}));

// How to use "frac_D_q"
// FDIV
// PRE_0/PRE_1: fracb_scaled
// FSQRT
// Use [12:0] to store "MASK"
assign frac_D_en =
  (start_handshaked & ~has_dn_in)
| fsm_q[FSM_PRE_1_BIT]
| (fsm_q[FSM_ITER_BIT] & ~is_fdiv_q);

assign nxt_frac_D_before_iter_fdiv = fracb_scaled;
assign nxt_frac_D_before_iter_fsqrt = {{(57 - 13){1'b0}}, 1'b1, 12'b0};
assign nxt_frac_D_iter = frac_D_q >> 1;

assign frac_D_d = 
  ({(57){fsm_q[FSM_PRE_0_BIT]}} & (is_fdiv_i ? nxt_frac_D_before_iter_fdiv : nxt_frac_D_before_iter_fsqrt))
| ({(57){fsm_q[FSM_PRE_1_BIT]}} & (is_fdiv_q ? nxt_frac_D_before_iter_fdiv : nxt_frac_D_before_iter_fsqrt))
| ({(57){fsm_q[FSM_ITER_BIT] }} & nxt_frac_D_iter);

always_ff @(posedge clk) begin
	if(f_r_fdiv_en) begin
		f_r_s_fdiv_q <= f_r_s_fdiv_d;
		f_r_c_fdiv_q <= f_r_c_fdiv_d;
	end

	if(f_r_fsqrt_en) begin
		f_r_s_fsqrt_q <= f_r_s_fsqrt_d;
		f_r_c_fsqrt_q <= f_r_c_fsqrt_d;
	end
	
	if(frac_D_en)
		frac_D_q <= frac_D_d;
	
	if(quot_root_iter_en)
		quot_root_iter_q <= quot_root_iter_d;
	if(quot_root_m1_iter_en)
		quot_root_m1_iter_q <= quot_root_m1_iter_d;
end


// FDIV
// F64
// nm_res, quot_needed = 54, iter_num_needed = 14, discard_bit = 14 * 4 - 1 - quot_needed = 1
// dn_res, exp_diff =   0, quot_needed = 53, iter_num_needed = 14, discard_bit = 14 * 4 - 1 - quot_needed = 2. In this case, actually we need extra 1-bit quot as "g_uf_check" to generate "UF"
// When (exp_diff <= -1), it must lead to "UF = 1", so we never need extra 1-bit quot anymore
// dn_res, exp_diff = - 1, quot_needed = 52, iter_num_needed = 14, discard_bit = 14 * 4 - 1 - quot_needed = 3
// dn_res, exp_diff = - 2, quot_needed = 51, iter_num_needed = 13, discard_bit = 13 * 4 - 1 - quot_needed = 0
// dn_res, exp_diff = - 3, quot_needed = 50, iter_num_needed = 13, discard_bit = 13 * 4 - 1 - quot_needed = 1
// dn_res, exp_diff = - 4, quot_needed = 49, iter_num_needed = 13, discard_bit = 13 * 4 - 1 - quot_needed = 2
// dn_res, exp_diff = - 5, quot_needed = 48, iter_num_needed = 13, discard_bit = 13 * 4 - 1 - quot_needed = 3
// dn_res, exp_diff = - 6, quot_needed = 47, iter_num_needed = 12, discard_bit = 12 * 4 - 1 - quot_needed = 0
// dn_res, exp_diff = - 7, quot_needed = 46, iter_num_needed = 12, discard_bit = 12 * 4 - 1 - quot_needed = 1
// dn_res, exp_diff = - 8, quot_needed = 45, iter_num_needed = 12, discard_bit = 12 * 4 - 1 - quot_needed = 2
// dn_res, exp_diff = - 9, quot_needed = 44, iter_num_needed = 12, discard_bit = 12 * 4 - 1 - quot_needed = 3
// dn_res, exp_diff = -10, quot_needed = 43, iter_num_needed = 11, discard_bit = 11 * 4 - 1 - quot_needed = 0
// dn_res, exp_diff = -11, quot_needed = 42, iter_num_needed = 11, discard_bit = 11 * 4 - 1 - quot_needed = 1
// dn_res, exp_diff = -12, quot_needed = 41, iter_num_needed = 11, discard_bit = 11 * 4 - 1 - quot_needed = 2
// dn_res, exp_diff = -13, quot_needed = 40, iter_num_needed = 11, discard_bit = 11 * 4 - 1 - quot_needed = 3
// dn_res, exp_diff = -14, quot_needed = 39, iter_num_needed = 10, discard_bit = 10 * 4 - 1 - quot_needed = 0
// dn_res, exp_diff = -15, quot_needed = 38, iter_num_needed = 10, discard_bit = 10 * 4 - 1 - quot_needed = 1
// dn_res, exp_diff = -16, quot_needed = 37, iter_num_needed = 10, discard_bit = 10 * 4 - 1 - quot_needed = 2
// dn_res, exp_diff = -17, quot_needed = 36, iter_num_needed = 10, discard_bit = 10 * 4 - 1 - quot_needed = 3
// dn_res, exp_diff = -18, quot_needed = 35, iter_num_needed =  9, discard_bit =  9 * 4 - 1 - quot_needed = 0
// dn_res, exp_diff = -19, quot_needed = 34, iter_num_needed =  9, discard_bit =  9 * 4 - 1 - quot_needed = 1
// dn_res, exp_diff = -20, quot_needed = 33, iter_num_needed =  9, discard_bit =  9 * 4 - 1 - quot_needed = 2
// dn_res, exp_diff = -21, quot_needed = 32, iter_num_needed =  9, discard_bit =  9 * 4 - 1 - quot_needed = 3
// dn_res, exp_diff = -22, quot_needed = 31, iter_num_needed =  8, discard_bit =  8 * 4 - 1 - quot_needed = 0
// dn_res, exp_diff = -23, quot_needed = 30, iter_num_needed =  8, discard_bit =  8 * 4 - 1 - quot_needed = 1
// dn_res, exp_diff = -24, quot_needed = 29, iter_num_needed =  8, discard_bit =  8 * 4 - 1 - quot_needed = 2
// dn_res, exp_diff = -25, quot_needed = 28, iter_num_needed =  8, discard_bit =  8 * 4 - 1 - quot_needed = 3
// dn_res, exp_diff = -26, quot_needed = 27, iter_num_needed =  7, discard_bit =  7 * 4 - 1 - quot_needed = 0
// dn_res, exp_diff = -27, quot_needed = 26, iter_num_needed =  7, discard_bit =  7 * 4 - 1 - quot_needed = 1
// dn_res, exp_diff = -28, quot_needed = 25, iter_num_needed =  7, discard_bit =  7 * 4 - 1 - quot_needed = 2
// dn_res, exp_diff = -29, quot_needed = 24, iter_num_needed =  7, discard_bit =  7 * 4 - 1 - quot_needed = 3
// dn_res, exp_diff = -30, quot_needed = 23, iter_num_needed =  6, discard_bit =  6 * 4 - 1 - quot_needed = 0
// dn_res, exp_diff = -31, quot_needed = 22, iter_num_needed =  6, discard_bit =  6 * 4 - 1 - quot_needed = 1
// dn_res, exp_diff = -32, quot_needed = 21, iter_num_needed =  6, discard_bit =  6 * 4 - 1 - quot_needed = 2
// dn_res, exp_diff = -33, quot_needed = 20, iter_num_needed =  6, discard_bit =  6 * 4 - 1 - quot_needed = 3
// dn_res, exp_diff = -34, quot_needed = 19, iter_num_needed =  5, discard_bit =  5 * 4 - 1 - quot_needed = 0
// dn_res, exp_diff = -35, quot_needed = 18, iter_num_needed =  5, discard_bit =  5 * 4 - 1 - quot_needed = 1
// dn_res, exp_diff = -36, quot_needed = 17, iter_num_needed =  5, discard_bit =  5 * 4 - 1 - quot_needed = 2
// dn_res, exp_diff = -37, quot_needed = 16, iter_num_needed =  5, discard_bit =  5 * 4 - 1 - quot_needed = 3
// dn_res, exp_diff = -38, quot_needed = 15, iter_num_needed =  4, discard_bit =  4 * 4 - 1 - quot_needed = 0
// dn_res, exp_diff = -39, quot_needed = 14, iter_num_needed =  4, discard_bit =  4 * 4 - 1 - quot_needed = 1
// dn_res, exp_diff = -40, quot_needed = 13, iter_num_needed =  4, discard_bit =  4 * 4 - 1 - quot_needed = 2
// dn_res, exp_diff = -41, quot_needed = 12, iter_num_needed =  4, discard_bit =  4 * 4 - 1 - quot_needed = 3
// dn_res, exp_diff = -42, quot_needed = 11, iter_num_needed =  3, discard_bit =  3 * 4 - 1 - quot_needed = 0
// dn_res, exp_diff = -43, quot_needed = 10, iter_num_needed =  3, discard_bit =  3 * 4 - 1 - quot_needed = 1
// dn_res, exp_diff = -44, quot_needed =  9, iter_num_needed =  3, discard_bit =  3 * 4 - 1 - quot_needed = 2
// dn_res, exp_diff = -45, quot_needed =  8, iter_num_needed =  3, discard_bit =  3 * 4 - 1 - quot_needed = 3
// dn_res, exp_diff = -46, quot_needed =  7, iter_num_needed =  2, discard_bit =  2 * 4 - 1 - quot_needed = 0
// dn_res, exp_diff = -47, quot_needed =  6, iter_num_needed =  2, discard_bit =  2 * 4 - 1 - quot_needed = 1
// dn_res, exp_diff = -48, quot_needed =  5, iter_num_needed =  2, discard_bit =  2 * 4 - 1 - quot_needed = 2
// dn_res, exp_diff = -49, quot_needed =  4, iter_num_needed =  2, discard_bit =  2 * 4 - 1 - quot_needed = 3
// dn_res, exp_diff = -50, quot_needed =  3, iter_num_needed =  1, discard_bit =  1 * 4 - 1 - quot_needed = 0
// dn_res, exp_diff = -51, quot_needed =  2, iter_num_needed =  1, discard_bit =  1 * 4 - 1 - quot_needed = 1
// dn_res, exp_diff = -52, quot_needed =  1, iter_num_needed =  1, discard_bit =  1 * 4 - 1 - quot_needed = 2
// dn_res, exp_diff = -53, quot_needed =  0, iter_num_needed =  1, discard_bit =  1 * 4 - 1 - quot_needed = 3
// dn_res, exp_diff <= -54, quot_needed =  0, iter_num_needed =  1, discard_bit =  1 * 4 - 1 - quot_needed = 3

// F32
// nm_res, quot_needed = 25, iter_num_needed = 7, discard_bit = 7 * 4 - 1 - quot_needed = 2
// dn_res, exp_diff =   0, quot_needed = 24, iter_num_needed = 7, discard_bit = 7 * 4 - 1 - quot_needed = 3. In this case, actually we need extra 1-bit quot as "g_uf_check" to generate "UF"
// When (exp_diff <= -1), it must lead to "UF = 1", so we never need extra 1-bit quot anymore
// dn_res, exp_diff = - 1, quot_needed = 23, iter_num_needed = 6, discard_bit = 6 * 4 - 1 - quot_needed = 0
// dn_res, exp_diff = - 2, quot_needed = 22, iter_num_needed = 6, discard_bit = 6 * 4 - 1 - quot_needed = 1
// dn_res, exp_diff = - 3, quot_needed = 21, iter_num_needed = 6, discard_bit = 6 * 4 - 1 - quot_needed = 2
// dn_res, exp_diff = - 4, quot_needed = 20, iter_num_needed = 6, discard_bit = 6 * 4 - 1 - quot_needed = 3
// dn_res, exp_diff = - 5, quot_needed = 19, iter_num_needed = 5, discard_bit = 5 * 4 - 1 - quot_needed = 0
// dn_res, exp_diff = - 6, quot_needed = 18, iter_num_needed = 5, discard_bit = 5 * 4 - 1 - quot_needed = 1
// dn_res, exp_diff = - 7, quot_needed = 17, iter_num_needed = 5, discard_bit = 5 * 4 - 1 - quot_needed = 2
// dn_res, exp_diff = - 8, quot_needed = 16, iter_num_needed = 5, discard_bit = 5 * 4 - 1 - quot_needed = 3
// dn_res, exp_diff = - 9, quot_needed = 15, iter_num_needed = 4, discard_bit = 4 * 4 - 1 - quot_needed = 0
// dn_res, exp_diff = -10, quot_needed = 14, iter_num_needed = 4, discard_bit = 4 * 4 - 1 - quot_needed = 1
// dn_res, exp_diff = -11, quot_needed = 13, iter_num_needed = 4, discard_bit = 4 * 4 - 1 - quot_needed = 2
// dn_res, exp_diff = -12, quot_needed = 12, iter_num_needed = 4, discard_bit = 4 * 4 - 1 - quot_needed = 3
// dn_res, exp_diff = -13, quot_needed = 11, iter_num_needed = 3, discard_bit = 3 * 4 - 1 - quot_needed = 0
// dn_res, exp_diff = -14, quot_needed = 10, iter_num_needed = 3, discard_bit = 3 * 4 - 1 - quot_needed = 1
// dn_res, exp_diff = -15, quot_needed =  9, iter_num_needed = 3, discard_bit = 3 * 4 - 1 - quot_needed = 2
// dn_res, exp_diff = -16, quot_needed =  8, iter_num_needed = 3, discard_bit = 3 * 4 - 1 - quot_needed = 3
// dn_res, exp_diff = -17, quot_needed =  7, iter_num_needed = 2, discard_bit = 2 * 4 - 1 - quot_needed = 0
// dn_res, exp_diff = -18, quot_needed =  6, iter_num_needed = 2, discard_bit = 2 * 4 - 1 - quot_needed = 1
// dn_res, exp_diff = -19, quot_needed =  5, iter_num_needed = 2, discard_bit = 2 * 4 - 1 - quot_needed = 2
// dn_res, exp_diff = -20, quot_needed =  4, iter_num_needed = 2, discard_bit = 2 * 4 - 1 - quot_needed = 3
// dn_res, exp_diff = -21, quot_needed =  3, iter_num_needed = 1, discard_bit = 1 * 4 - 1 - quot_needed = 0
// dn_res, exp_diff = -22, quot_needed =  2, iter_num_needed = 1, discard_bit = 1 * 4 - 1 - quot_needed = 1
// dn_res, exp_diff = -23, quot_needed =  1, iter_num_needed = 1, discard_bit = 1 * 4 - 1 - quot_needed = 2
// dn_res, exp_diff = -24, quot_needed =  0, iter_num_needed = 1, discard_bit = 1 * 4 - 1 - quot_needed = 3
// dn_res, exp_diff <= -25, quot_needed =  0, iter_num_needed = 1, discard_bit = 1 * 4 - 1 - quot_needed = 3

assign iter_counter_en = start_handshaked | fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];
assign iter_counter_start_value_fsqrt_pre_0 = f32_pre_0 ? 6'd5 : 6'd12;
assign iter_counter_start_value_fsqrt_pre_1 = f32_after_pre_0_q ? 6'd5 : 6'd12;

// F64: When "iter_counter_q >= 52", we need to add a "1" before MSB of final quot.
assign add_1_to_quot_msb = (iter_counter_q == 6'd52);

// For FSQRT, when opa is denormal, use iter_counter_q[0] to store "fraca_lsh_num_d[0]", so we can know whether expa is odd in PRE_1
assign iter_counter_d = 
  ({(6){fsm_q[FSM_PRE_0_BIT] &  has_dn_in	}} & {{(6 - 1){1'b0}}, fraca_lsh_num_d[0]})
| ({(6){fsm_q[FSM_PRE_0_BIT] & ~has_dn_in	}} & (is_fdiv_i ? '0 : iter_counter_start_value_fsqrt_pre_0))
| ({(6){fsm_q[FSM_PRE_1_BIT]				}} & (is_fdiv_q ? '0 : iter_counter_start_value_fsqrt_pre_1))
| ({(6){fsm_q[FSM_ITER_BIT]					}} & (final_iter ? {add_1_to_quot_msb, res_exp_of, quot_discard_num_one_hot[3:0]} : iter_counter_nxt));

// FDIV: iter_counter_nxt = iter_counter_q + 4
// FSQRT: iter_counter_nxt = iter_counter_q - 1
assign iter_counter_nxt = iter_counter_q + (is_fdiv_q ? 6'd4 : {(6){1'b1}});

assign res_exp_zero = (res_exp_q[11:0] == '0);
assign res_exp_dn = res_exp_q[12] | res_exp_zero;
assign res_exp_of = ~res_exp_q[12] & (res_exp_q[11:0] >= (f32_after_pre_0_q ? 12'd255 : 12'd2047));

assign quot_bits_needed_res_exp_nm = f32_after_pre_0_q ? 6'd25 : 6'd54;

assign quot_bits_needed_res_exp_dn_temp[12:0] = (f32_after_pre_0_q ? 13'd24 : 13'd53) + res_exp_q[12:0];
assign quot_bits_needed_res_exp_dn[5:0] = quot_bits_needed_res_exp_dn_temp[12] ? '0 : quot_bits_needed_res_exp_dn_temp[5:0];

assign quot_bits_needed = res_exp_dn ? quot_bits_needed_res_exp_dn : quot_bits_needed_res_exp_nm;

// After this iter, how many quot_bits could we get?
// 3 = 4 - 1
assign quot_bits_calculated = iter_counter_q + 6'd3;

// assign quot_bits_calculated_sub_quot_bits_needed[6:0] = {1'b0, quot_bits_calculated[5:0]} + ~{1'b0, quot_bits_needed[5:0]} + 7'd1;
// assign quot_bits_calculated_ge_quot_bits_needed = ~quot_bits_calculated_sub_quot_bits_needed[6];
assign quot_bits_calculated_ge_quot_bits_needed = (quot_bits_calculated[5:0] >= quot_bits_needed[5:0]);

// quot_bits_needed[1:0] = 
// 2'b00: quot_discard_num = 3
// 2'b01: quot_discard_num = 2
// 2'b10: quot_discard_num = 1
// 2'b11: quot_discard_num = 0
assign quot_discard_num_one_hot[3:0] = 
  ({(4){(quot_bits_needed[1:0] == 2'b11) |  (opb_power_of_2_q & ~res_exp_dn)}} & 4'b0001)
| ({(4){(quot_bits_needed[1:0] == 2'b10) & ~(opb_power_of_2_q & ~res_exp_dn)}} & 4'b0010)
| ({(4){(quot_bits_needed[1:0] == 2'b01) & ~(opb_power_of_2_q & ~res_exp_dn)}} & 4'b0100)
| ({(4){(quot_bits_needed[1:0] == 2'b00) & ~(opb_power_of_2_q & ~res_exp_dn)}} & 4'b1000);

// When (final_iter == 1), use "iter_counter_q" to store the number of "quot_bits" that we should discard before rounding.
// assign quot_discard_num_one_hot[3:0] = 
//   ({(4){(quot_bits_calculated_sub_quot_bits_needed[1:0] == 2'd0) |  (opb_power_of_2_q & ~res_exp_dn)}} & 4'b0001)
// | ({(4){(quot_bits_calculated_sub_quot_bits_needed[1:0] == 2'd1) & ~(opb_power_of_2_q & ~res_exp_dn)}} & 4'b0010)
// | ({(4){(quot_bits_calculated_sub_quot_bits_needed[1:0] == 2'd2) & ~(opb_power_of_2_q & ~res_exp_dn)}} & 4'b0100)
// | ({(4){(quot_bits_calculated_sub_quot_bits_needed[1:0] == 2'd3) & ~(opb_power_of_2_q & ~res_exp_dn)}} & 4'b1000);

// FDIV: When (opb_power_of_2_q & res_exp_dn), we just use SRT to get final result.
assign final_iter = is_fdiv_q ? (quot_bits_calculated_ge_quot_bits_needed | res_exp_of | (opb_power_of_2_q & ~res_exp_dn)) : (iter_counter_q == '0);

always_ff @(posedge clk) begin
	if(iter_counter_en)
		iter_counter_q <= iter_counter_d;
end

// ================================================================================================================================================

// ================================================================================================================================================

fdiv_r16_block #(
	.QDS_ARCH			(FDIV_QDS_ARCH),
	.SRT_2ND_SPEC		(FDIV_SRT_2ND_SPEC),
	.REM_W				(GLOBAL_REM_W)
) u_fdiv_r16_block (
	.f_r_s_i			(f_r_s_fdiv_q),
	.f_r_c_i			(f_r_c_fdiv_q),
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

	.f_r_s_1st_o		(f_r_s_1st_fdiv),
	.f_r_s_2nd_o		(f_r_s_2nd_fdiv),
	.f_r_c_1st_o		(f_r_c_1st_fdiv),
	.f_r_c_2nd_o		(f_r_c_2nd_fdiv)
);

fsqrt_r16_block #(
	.SRT_2ND_SPEC	(FSQRT_SRT_2ND_SPEC),
	.REM_W			(FSQRT_F64_REM_W)
) u_fsqrt_r16_block (
	.f_r_s_i						(f_r_s_fsqrt_q),
	.f_r_c_i						(f_r_c_fsqrt_q),
	.root_i							(quot_root_iter_q[0 +: 54]),
	.root_m1_i						(quot_root_m1_iter_q[0 +: 53]),
	.rem_msb_nxt_cycle_1st_srt_i	(rem_msb_nxt_cycle_1st_srt_q),
	.rem_msb_nxt_cycle_2nd_srt_i	(rem_msb_nxt_cycle_2nd_srt_q),
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
	.rem_msb_nxt_cycle_2nd_srt_o	(rem_msb_nxt_cycle_2nd_srt_after_iter),
	.m_n1_nxt_cycle_1st_srt_o		(m_n1_nxt_cycle_1st_srt_after_iter),
	.m_z0_nxt_cycle_1st_srt_o		(m_z0_nxt_cycle_1st_srt_after_iter),
	.m_p1_nxt_cycle_1st_srt_o		(m_p1_nxt_cycle_1st_srt_after_iter),
	.m_p2_nxt_cycle_1st_srt_o		(m_p2_nxt_cycle_1st_srt_after_iter)
);

// Only for formal prrof
fdiv_srt_to_restoring #(
	.REM_W(GLOBAL_REM_W)
) u_fdiv_srt_to_restoring (
	.original_fraca_i			(fraca_prescaled),
	.original_fracb_i			(fracb_prescaled),
    .fraca_lt_fracb_i			(fraca_lt_fracb),
    .iter_start_i				((start_handshaked & ~has_dn_in) | fsm_q[FSM_PRE_1_BIT]),
    .iter_vld_i					(fsm_q[FSM_ITER_BIT]),
    .iter_end_i					(final_iter),
    .iter_counter_i				(iter_counter_q),
    .quot_bits_calculated_i		(quot_bits_calculated),
    .srt_quot_2nd_i				(quot_2nd),
    .srt_quot_m1_2nd_i			(quot_m1_2nd),
    .srt_f_r_s_2nd_i			(f_r_s_2nd_fdiv),
    .srt_f_r_c_2nd_i			(f_r_c_2nd_fdiv),
    .quot_discard_num_one_hot_i	(quot_discard_num_one_hot),

    .clk						(clk),
	.rst_n						(rst_n)
);
fdiv_srt_to_restoring_v2 #(
	.REM_W(GLOBAL_REM_W)
) u_fdiv_srt_to_restoring_v2 (
	.scaled_dividend_i			(fraca_scaled),
	.scaled_divisor_i			(fracb_scaled),
    .dividend_lt_divisor_i		(fraca_lt_fracb),
    .iter_start_i				((start_handshaked & ~has_dn_in) | fsm_q[FSM_PRE_1_BIT]),
    .iter_vld_i					(fsm_q[FSM_ITER_BIT]),
    .iter_end_i					(final_iter),
    .iter_counter_i				(iter_counter_q),
    .quot_bits_calculated_i		(quot_bits_calculated),
    .srt_quot_1st_i				(quot_1st),
    .srt_quot_m1_1st_i			(quot_m1_1st),
    .srt_quot_2nd_i				(quot_2nd),
    .srt_quot_m1_2nd_i			(quot_m1_2nd),
    .srt_f_r_s_1st_i			(f_r_s_1st_fdiv),
    .srt_f_r_c_1st_i			(f_r_c_1st_fdiv),
    .srt_f_r_s_2nd_i			(f_r_s_2nd_fdiv),
    .srt_f_r_c_2nd_i			(f_r_c_2nd_fdiv),
    .quot_discard_num_one_hot_i	(quot_discard_num_one_hot),

    .clk						(clk),
	.rst_n						(rst_n)
);

fsqrt_srt_to_restoring u_fsqrt_srt_to_restoring (
	.frac_fsqrt_i				(frac_fsqrt),
    .exp_odd_i					(exp_odd_fsqrt),
    .root_dig_n2_1st_i			(root_dig_n2_1st),
    .root_dig_n1_1st_i			(root_dig_n1_1st),
    .root_dig_z0_1st_i			(root_dig_z0_1st),
    .f_r_s_before_iter_i		(f_r_s_before_iter_fsqrt),
    .f_r_c_before_iter_i		(f_r_c_before_iter_fsqrt),
    .iter_start_i				((start_handshaked & ~has_dn_in) | fsm_q[FSM_PRE_1_BIT]),
    .iter_vld_i					(fsm_q[FSM_ITER_BIT]),
    .iter_counter_i				(iter_counter_q),
    .srt_root_2nd_i				(root_2nd),
    .srt_root_m1_2nd_i			(root_m1_2nd),
    .srt_f_r_s_2nd_i			(f_r_s_2nd_fsqrt),
    .srt_f_r_c_2nd_i			(f_r_c_2nd_fsqrt),

    .clk						(clk),
	.rst_n						(rst_n)
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


// ================================================================================================================================================
// Post Process: Denormalization (Only for FDIV) & Rounding
// ================================================================================================================================================

assign f_r_s_post[GLOBAL_REM_W - 1:0] = is_fdiv_q ? f_r_s_fdiv_q : {{(GLOBAL_REM_W - FSQRT_F64_REM_W){1'b0}}, f_r_s_fsqrt_q};
assign f_r_c_post[GLOBAL_REM_W - 1:0] = is_fdiv_q ? f_r_c_fdiv_q : {{(GLOBAL_REM_W - FSQRT_F64_REM_W){1'b0}}, f_r_c_fsqrt_q};

assign nr_f_r = f_r_s_post + f_r_c_post;

assign f_r_xor = f_r_s_post[(GLOBAL_REM_W - 1) - 1:1] ^ f_r_c_post[(GLOBAL_REM_W - 1) - 1:1];
assign f_r_or  = f_r_s_post[(GLOBAL_REM_W - 1) - 2:0] | f_r_c_post[(GLOBAL_REM_W - 1) - 2:0];

assign quot_discard_not_zero = 
  (quot_discard_num_post[1] & quot_root_iter_q[0])
| (quot_discard_num_post[2] & (quot_root_iter_q[0] | quot_root_iter_q[1]))
| (quot_discard_num_post[3] & (quot_root_iter_q[0] | quot_root_iter_q[1] | quot_root_iter_q[2]));
// The algorithm we use is "Minimally Redundant Radix 4", and its redundnat factor is 2/3.
// So we must have "|rem| <= D * (2/3)" -> When (nr_f_r < 0), "nr_f_r + frac_D" MUST be NON_ZERO
assign rem_not_zero =
  (is_fdiv_q ? ~opb_power_of_2_q : 1'b1)
& ((is_fdiv_q ? (nr_f_r[GLOBAL_REM_W - 1] | quot_discard_not_zero) : nr_f_r[FSQRT_F64_REM_W - 1]) | ((f_r_xor[53:0] != f_r_or[53:0]) | (is_fdiv_q & (f_r_xor[58:54] != f_r_or[58:54]))));

assign select_quot_m1 = nr_f_r[GLOBAL_REM_W - 1] | opb_power_of_2_q;
assign select_root_m1 = nr_f_r[FSQRT_F64_REM_W - 1] & ~res_sqrt2_q;

assign add_1_to_quot_msb_post = iter_counter_q[5];
assign quot_discard_num_post = iter_counter_q[3:0];
assign quot_rsh_0 = {add_1_to_quot_msb_post, quot_root_iter_q};
assign quot_rsh_1 = {add_1_to_quot_msb_post, quot_root_iter_q} >> 1;
assign quot_rsh_2 = {add_1_to_quot_msb_post, quot_root_iter_q} >> 2;
assign quot_rsh_3 = {add_1_to_quot_msb_post, quot_root_iter_q} >> 3;
assign quot_m1_rsh_0 = {add_1_to_quot_msb_post, quot_root_m1_iter_q};
assign quot_m1_rsh_1 = {add_1_to_quot_msb_post, quot_root_m1_iter_q} >> 1;
assign quot_m1_rsh_2 = {add_1_to_quot_msb_post, quot_root_m1_iter_q} >> 2;
assign quot_m1_rsh_3 = {add_1_to_quot_msb_post, quot_root_m1_iter_q} >> 3;

assign quot_before_inc[52:0] = 
  ({(53){quot_discard_num_post[0]}} & quot_rsh_0[52:0])
| ({(53){quot_discard_num_post[1]}} & quot_rsh_1[52:0])
| ({(53){quot_discard_num_post[2]}} & quot_rsh_2[52:0])
| ({(53){quot_discard_num_post[3]}} & quot_rsh_3[52:0]);
assign quot_m1_before_inc[52:0] = 
  ({(53){quot_discard_num_post[0]}} & quot_m1_rsh_0[52:0])
| ({(53){quot_discard_num_post[1]}} & quot_m1_rsh_1[52:0])
| ({(53){quot_discard_num_post[2]}} & quot_m1_rsh_2[52:0])
| ({(53){quot_discard_num_post[3]}} & quot_m1_rsh_3[52:0]);
assign quot_before_round_all_1 = f32_after_pre_0_q ? (quot_before_inc[1 +: 23] == {(23){1'b1}}) : (quot_before_inc[1 +: 52] == {(52){1'b1}});
assign quot_m1_before_round_all_1 = f32_after_pre_0_q ? (quot_m1_before_inc[1 +: 23] == {(23){1'b1}}) : (quot_m1_before_inc[1 +: 52] == {(52){1'b1}});


assign root_before_inc[52:0] = res_sqrt2_q ? SQRT_2_WITH_ROUND_BIT[0 +: 53] : quot_root_iter_q[0 +: 53];
assign root_m1_before_inc[52:0] = quot_root_m1_iter_q[52:0];
assign root_before_round_all_1 = f32_after_pre_0_q ? (root_before_inc[52 -: 23] == {(23){1'b1}}) : (root_before_inc[52 -: 52] == {(52){1'b1}});
assign root_m1_before_round_all_1 = f32_after_pre_0_q ? (root_m1_before_inc[52 -: 23] == {(23){1'b1}}) : (root_m1_before_inc[52 -: 52] == {(52){1'b1}});

// quot_before_inc[0]/root_before_inc[0] is "guard_bit", and it is not used in INC
assign quot_root_before_inc[51:0] = is_fdiv_q ? quot_before_inc[52:1] : root_before_inc[52:1];

assign inc_poisition_fsqrt = f32_after_pre_0_q ? {22'b0, 1'b1, 29'b0} : {51'b0, 1'b1};
assign inc_poisition_fdiv = {51'b0, 1'b1};
assign inc_poisition = is_fdiv_q ? inc_poisition_fdiv : inc_poisition_fsqrt;

assign quot_root_inc_res[52:0] = {1'b0, quot_root_before_inc[51:0]} + {1'b0, inc_poisition[51:0]};

assign quot_m1_inc_res[52:0] = (quot_before_inc[1] == quot_m1_before_inc[1]) ? quot_root_inc_res[52:0] : {1'b0, quot_before_inc[52:1]};

assign root_m1_inc_res = (root_l == root_m1_l) ? quot_root_inc_res[52:0] : {1'b0, root_before_inc[52:1]};

assign root_l = f32_after_pre_0_q ? root_before_inc[30] : root_before_inc[1];
assign root_g = f32_after_pre_0_q ? root_before_inc[29] : root_before_inc[0];
assign root_s = rem_not_zero;
// For FSQRT, there is no "Midpoint" result, which means, if guard_bit is 1, then sticky_bit MUST be 1 as well. By using this property,
// We could know that the effect of RNE is totally equal to RMM. So we can save several gates here.
assign root_need_round_up = 
  (rne_q &  root_g)
| (rup_q & (root_g | root_s))
| (rmm_q &  root_g);
assign root_inexact = root_g | root_s;

assign root_m1_l = f32_after_pre_0_q ? quot_root_m1_iter_q[30] : quot_root_m1_iter_q[1];
assign root_m1_g = f32_after_pre_0_q ? quot_root_m1_iter_q[29] : quot_root_m1_iter_q[0];
assign root_m1_s = 1'b1;
assign root_m1_need_round_up = 
  (rne_q &  root_m1_g)
| (rup_q & (root_m1_g | root_m1_s))
| (rmm_q &  root_m1_g);
assign root_m1_inexact = 1'b1;

assign root_rounded = root_need_round_up ? quot_root_inc_res[52:0] : {1'b0, root_before_inc[52:1]};
assign root_m1_rounded = root_m1_need_round_up ? root_m1_inc_res[52:0] : {1'b0, quot_root_m1_iter_q[52:1]};
assign inexact_fsqrt = select_root_m1 | root_inexact;


assign frac_rounded_fsqrt[51:0] = select_root_m1 ? root_m1_rounded[51:0] : root_rounded[51:0];

assign carry_after_round_root = root_need_round_up & root_before_round_all_1;
assign carry_after_round_root_m1 = root_m1_need_round_up & root_m1_before_round_all_1;
assign carry_after_round_fsqrt = select_root_m1 ? carry_after_round_root_m1 : carry_after_round_root;
assign exp_rounded_fsqrt = carry_after_round_fsqrt ? (res_exp_q[10:0] + 11'd1) : res_exp_q[10:0];

assign quot_l = quot_before_inc[1];
assign quot_g = quot_before_inc[0];
assign quot_s = rem_not_zero;
assign quot_need_round_up = 
  (rne_q & ((quot_g & quot_s) | (quot_l & quot_g)))
| (rup_q & (quot_g | quot_s))
| (rmm_q & quot_g);
assign quot_inexact = quot_g | quot_s;

assign quot_m1_l = quot_m1_before_inc[1];
assign quot_m1_g = quot_m1_before_inc[0];
// When we need to use "QUOT_M1", the sticky_bit must be 1
assign quot_m1_s = 1'b1 & ~opb_power_of_2_q;
assign quot_m1_need_round_up = 
  (rne_q & ((quot_m1_g & quot_m1_s) | (quot_m1_l & quot_m1_g)))
| (rup_q & (quot_m1_g | quot_m1_s))
| (rmm_q & quot_m1_g);
assign quot_m1_inexact = 1'b1;

assign quot_rounded[52:0] = quot_need_round_up ? quot_root_inc_res[52:0] : {1'b0, quot_before_inc[52:1]};
assign quot_m1_rounded[52:0] = quot_m1_need_round_up ? quot_m1_inc_res[52:0] : {1'b0, quot_m1_before_inc[52:1]};
assign inexact_fdiv = (select_quot_m1 | quot_inexact) & ~opb_power_of_2_q;

assign inexact = is_fdiv_q ? inexact_fdiv : inexact_fsqrt;

assign frac_rounded_fdiv = select_quot_m1 ? quot_m1_rounded[51:0] : quot_rounded[51:0];

assign carry_after_round_quot = quot_need_round_up & quot_before_round_all_1;
assign carry_after_round_quot_m1 = quot_m1_need_round_up & quot_m1_before_round_all_1;
assign carry_after_round_fdiv = select_quot_m1 ? carry_after_round_quot_m1 : carry_after_round_quot;

assign exp_before_round_fdiv[10:0] = res_exp_q[12] ? '0 : res_exp_q[10:0];
assign exp_rounded_fdiv = carry_after_round_fdiv ? (exp_before_round_fdiv[10:0] + 11'd1) : exp_before_round_fdiv[10:0];

assign frac_rounded = is_fdiv_q ? frac_rounded_fdiv : frac_rounded_fsqrt;
assign exp_rounded = is_fdiv_q ? exp_rounded_fdiv : exp_rounded_fsqrt;

assign sel_overflow_res = is_fdiv_q & iter_counter_q[4];
assign overflow_res_f32 = {
	res_sign_q,
	{(7){1'b1}}, ~rtz_q,
	{(23){rtz_q}}
};
assign overflow_res_f64 = {
	res_sign_q,
	{(10){1'b1}}, ~rtz_q,
	{(52){rtz_q}}
};
assign overflow_res = f32_after_pre_0_q ? {{(32){1'b1}}, overflow_res_f32} : overflow_res_f64;

assign sel_special_res = res_nan_q | res_inf_q | res_exact_zero_q;
assign special_res_f32 = 
  ({(32){res_nan_q			}} & {1'b0, 		{(8){1'b1}}, 1'b1, 22'b0})
| ({(32){res_inf_q			}} & {res_sign_q,	{(8){1'b1}}, 1'b0, 22'b0})
| ({(32){res_exact_zero_q	}} & {res_sign_q, 	{(8){1'b0}}, 1'b0, 22'b0});
assign special_res_f64 = 
  ({(64){res_nan_q			}} & {1'b0, 		{(11){1'b1}}, 1'b1, 51'b0})
| ({(64){res_inf_q			}} & {res_sign_q,	{(11){1'b1}}, 1'b0, 51'b0})
| ({(64){res_exact_zero_q	}} & {res_sign_q, 	{(11){1'b0}}, 1'b0, 51'b0});
assign special_res = f32_after_pre_0_q ? {{(32){1'b1}}, special_res_f32} : special_res_f64;

assign normal_res_f32 = {res_sign_q, exp_rounded[7:0], is_fdiv_q ? frac_rounded_fdiv[0 +: 23] : frac_rounded_fsqrt[51 -: 23]};
assign normal_res_f64 = {res_sign_q, exp_rounded[10:0], is_fdiv_q ? frac_rounded_fdiv[0 +: 52] : frac_rounded_fsqrt[51 -: 52]};
assign normal_res = f32_after_pre_0_q ? {{(32){1'b1}}, normal_res_f32} : normal_res_f64;

assign fdivsqrt_res_o = sel_special_res ? special_res : sel_overflow_res ? overflow_res : normal_res;


assign fflags_invalid_operation = invalid_operation_q;
assign fflags_divded_by_zero = divided_by_zero_q;
assign fflags_overflow = sel_overflow_res & ~sel_special_res;


// FOR "UF_AFTER_ROUNDING"
// When (res_exp_q <= -1), we must have "fflags_underflow = 1"
// F64:
// When (res_exp_zero == 1), we have got 55-bit QUOT = {1'b1, quot_root_iter_q[53:0]}, QUOT_M1 = {1'b1, quot_root_m1_iter_q[53:0]}
// F32:
// When (res_exp_zero == 1), we have got 27-bit QUOT = {1'b1, quot_root_iter_q[25:0]}, QUOT_M1 = {1'b1, quot_root_m1_iter_q[25:0]} 
assign quot_l_uf_check = f32_after_pre_0_q ? quot_root_iter_q[3] : quot_root_iter_q[2];
assign quot_g_uf_check = f32_after_pre_0_q ? quot_root_iter_q[2] : quot_root_iter_q[1];
assign quot_s_uf_check = rem_not_zero;
assign quot_uf_check_need_round_up = 
  (rne_q & ((quot_g_uf_check & quot_s_uf_check) | (quot_l_uf_check & quot_g_uf_check)))
| (rup_q & (quot_g_uf_check | quot_s_uf_check))
| (rmm_q & quot_g_uf_check);

assign quot_m1_l_uf_check = f32_after_pre_0_q ? quot_root_m1_iter_q[3] : quot_root_m1_iter_q[2];
assign quot_m1_g_uf_check = f32_after_pre_0_q ? quot_root_m1_iter_q[2] : quot_root_m1_iter_q[1];
assign quot_m1_s_uf_check = 1'b1;
assign quot_m1_uf_check_need_round_up = 
  (rne_q & ((quot_m1_g_uf_check & quot_m1_s_uf_check) | (quot_m1_l_uf_check & quot_m1_g_uf_check)))
| (rup_q & (quot_m1_g_uf_check | quot_m1_s_uf_check))
| (rmm_q & quot_m1_g_uf_check);

assign quot_uf_check_before_round_all_1 = f32_after_pre_0_q ? (quot_root_iter_q[25:3] == {(23){1'b1}}) : (quot_root_iter_q[53:2] == {(52){1'b1}});
assign quot_m1_uf_check_before_round_all_1 = f32_after_pre_0_q ? (quot_root_m1_iter_q[25:3] == {(23){1'b1}}) : (quot_root_m1_iter_q[53:2] == {(52){1'b1}});

assign carry_after_round_quot_uf_check = quot_uf_check_need_round_up & quot_uf_check_before_round_all_1;
assign carry_after_round_quot_m1_uf_check = quot_m1_uf_check_need_round_up & quot_m1_uf_check_before_round_all_1;
assign carry_after_round_uf_check = select_quot_m1 ? carry_after_round_quot_m1_uf_check : carry_after_round_quot_uf_check;


assign fflags_underflow = 
  is_fdiv_q
& (res_exp_zero | res_exp_dn)
& inexact
& ~sel_overflow_res
& ~sel_special_res
& ((UF_AFTER_ROUNDING == '0) ? 1'b1 : ~(res_exp_zero & carry_after_round_uf_check));

// assign fflags_underflow = 
//   is_fdiv_q
// & (res_exp_zero | res_exp_dn)
// & inexact
// & ~sel_overflow_res
// & ~sel_special_res;

assign fflags_inexact = (inexact | sel_overflow_res) & ~sel_special_res;

assign fflags_o = {
	fflags_invalid_operation,
	fflags_divded_by_zero,
	fflags_overflow,
	fflags_underflow,
	fflags_inexact
};


endmodule

