// ========================================================================================================
// File Name			: fpsqrt_vector_r16.sv
// Author				: HYF
// How to Contact		: hyf_sysu@qq.com
// Created Time    		: 2022-02-01 19:52:28
// Last Modified Time   : 2022-02-08 09:27:25
// ========================================================================================================
// Description	:
// A high performance Vector Floating Point Square-Root module, based on Radix-16 SRT algorithm.
// It supports f16/f32/f64.
// ========================================================================================================
// ========================================================================================================
// Copyright (C) 2022, HYF. All Rights Reserved.
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

module fpsqrt_vector_r16 #(
	// Put some parameters here, which can be changed by other modules
	// TODO: Write recommended value here after merged_csa is finished
	parameter S0_CSA_SPECULATIVE = 1,
	parameter S0_CSA_MERGED = 1,	
	parameter S1_QDS_SPECULATIVE = 1,
	parameter S1_CSA_SPECULATIVE = 1,
	parameter S1_CSA_MERGED = 0
)(
	input  logic start_valid_i,
	output logic start_ready_o,
	input  logic flush_i,
	// 2'd0: f16
	// 2'd1: f16
	// 2'd2: f64
	input  logic [2-1:0] fp_format_i,
	input  logic [64-1:0] op_i,
	input  logic [3-1:0] rm_i,
	input  logic vector_mode_i,

	output logic finish_valid_o,
	input  logic finish_ready_i,
	output logic [64-1:0] fpsqrt_res_o,
	output logic [5-1:0] fflags_o,

	input  logic clk,
	input  logic rst_n
);

// ================================================================================================================================================
// (local) parameters begin

// F64: We would get 54-bit root -> We need 54 + 2 = 56-bit REM.
localparam F64_REM_W = 2 + 54;
// F32: We would get 26-bit root -> We need 26 + 2 = 28-bit REM.
localparam F32_REM_W = 2 + 26;
// F16: We would get 14-bit root -> We need 14 + 2 = 16-bit REM.
localparam F16_REM_W = 2 + 14;

// F64: The root could be 55-bit in the early stage, but finally the significant digits must be 54.
localparam F64_FULL_RT_W = F64_REM_W - 1;
// F32: The root could be 27-bit in the early stage, but finally the significant digits must be 26.
localparam F32_FULL_RT_W = F32_REM_W - 1;
// F16: The root could be 15-bit in the early stage, but finally the significant digits must be 14.
localparam F16_FULL_RT_W = F16_REM_W - 1;

// When we want to use the merged implementation for s0.csa, we should add 2-bit ZERO in REM between 2 F16 numbers as an interval.
localparam S0_CSA_IS_MERGED = (S0_CSA_SPECULATIVE == 0) & (S0_CSA_MERGED == 1);
localparam S1_CSA_IS_MERGED = (S1_CSA_SPECULATIVE == 0) & (S1_CSA_MERGED == 1);
localparam REM_W = S0_CSA_IS_MERGED ? ((2 + F16_REM_W) * 3 + F16_REM_W) : (4 * F16_REM_W);

localparam F64_FRAC_W = 52 + 1;
localparam F32_FRAC_W = 23 + 1;
localparam F16_FRAC_W = 10 + 1;

localparam F64_EXP_W = 11;
localparam F32_EXP_W = 8;
localparam F16_EXP_W = 5;

// f64: ceil((53 - 1) / 4) = 13
// f32: ceil((24 - 1) / 4) = 6
// f16: ceil((11 - 1) / 4) = 3
localparam F64_ITER_NUM = 13;
localparam F32_ITER_NUM = 6;
localparam F16_ITER_NUM = 3;
// 13 * 2 + 2 = 54
localparam F64_RT_W = 4 * F64_ITER_NUM + 2;
// 4 * 6 + 2 = 26
localparam F32_RT_W = 4 * F32_ITER_NUM + 2;
// 4 * 3 + 2 = 14
localparam F16_RT_W = 4 * F16_ITER_NUM + 2;

localparam ITER_NUM_W = 4;

localparam FSM_W = 4;
localparam FSM_PRE_0 	= (1 << 0);
localparam FSM_PRE_1 	= (1 << 1);
localparam FSM_ITER  	= (1 << 2);
localparam FSM_POST_0 	= (1 << 3);

localparam FSM_PRE_0_BIT 	= 0;
localparam FSM_PRE_1_BIT 	= 1;
localparam FSM_ITER_BIT 	= 2;
localparam FSM_POST_0_BIT 	= 3;

localparam RT_DIG_W = 5;

localparam RT_DIG_NEG_2_BIT = 4;
localparam RT_DIG_NEG_1_BIT = 3;
localparam RT_DIG_NEG_0_BIT = 2;
localparam RT_DIG_POS_1_BIT = 1;
localparam RT_DIG_POS_2_BIT = 0;

localparam RT_DIG_NEG_2 = (1 << 4);
localparam RT_DIG_NEG_1 = (1 << 3);
localparam RT_DIG_NEG_0 = (1 << 2);
localparam RT_DIG_POS_1 = (1 << 1);
localparam RT_DIG_POS_2 = (1 << 0);

// Used when we find that the op is the power of 2 and it has an odd_exp.
localparam [(F64_FRAC_W+1)-1:0] SQRT_2_WITH_ROUND_BIT = 54'b1_01101010000010011110011001100111111100111011110011001;

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
// rt = root
// f_r = frac_rem
// f_r_s = frac_rem_sum
// f_r_c = frac_rem_carry
// ext = extended
// nr = non_redundant

// *_0, the signals are used when:
// 1) op[63: 0] is f64
// 2) op[63:32] is f32
// 3) op[63:48] is f16

// *_1, the signals are used when:
// 1) op[31: 0] is f32
// 2) op[31:16] is f16

// *_2, the signals are used when:
// 1) op[47:32] is f16

// *_3, the signals are used when:
// 1) op[15: 0] is f16

// f64_0 = op[63: 0]
// f32_0 = op[63:32]
// f32_1 = op[31: 0]
// f16_0 = op[63:48]
// f16_1 = op[31:16]
// f16_2 = op[47:32]
// f16_3 = op[15: 0]

logic start_handshaked;
logic [FSM_W-1:0] fsm_d;
logic [FSM_W-1:0] fsm_q;

logic iter_num_en;
logic [4-1:0] iter_num_d;
logic [4-1:0] iter_num_q;
logic final_iter;

// ================================================================================================================================================
// common info
logic [3-1:0] fp_fmt_d;
logic [3-1:0] fp_fmt_q;
logic [3-1:0] rm_d;
logic [3-1:0] rm_q;
// v_mode = vector_mode
// s_mode = scalar_mode
logic v_mode_d;
logic v_mode_q;
// ================================================================================================================================================

logic out_sign_0_en;
logic out_sign_0_d;
logic out_sign_0_q;
logic out_sign_1_en;
logic out_sign_1_d;
logic out_sign_1_q;
logic out_sign_2_en;
logic out_sign_2_d;
logic out_sign_2_q;
logic out_sign_3_en;
logic out_sign_3_d;
logic out_sign_3_q;

logic out_exp_0_en;
logic [F64_EXP_W-1:0] out_exp_0_d;
logic [F64_EXP_W-1:0] out_exp_0_q;
logic out_exp_1_en;
logic [F32_EXP_W-1:0] out_exp_1_d;
logic [F32_EXP_W-1:0] out_exp_1_q;
logic out_exp_2_en;
logic [F16_EXP_W-1:0] out_exp_2_d;
logic [F16_EXP_W-1:0] out_exp_2_q;
logic out_exp_3_en;
logic [F16_EXP_W-1:0] out_exp_3_d;
logic [F16_EXP_W-1:0] out_exp_3_q;

logic [(F64_EXP_W+1)-1:0] out_exp_pre_0;
logic [(F32_EXP_W+1)-1:0] out_exp_pre_1;
logic [(F16_EXP_W+1)-1:0] out_exp_pre_2;
logic [(F16_EXP_W+1)-1:0] out_exp_pre_3;

logic op_sign_0;
logic op_sign_1;
logic op_sign_2;
logic op_sign_3;

logic [F64_EXP_W-1:0] op_exp_0;
logic [F32_EXP_W-1:0] op_exp_1;
logic [F16_EXP_W-1:0] op_exp_2;
logic [F16_EXP_W-1:0] op_exp_3;

logic op_exp_is_zero_0;
logic op_exp_is_zero_1;
logic op_exp_is_zero_2;
logic op_exp_is_zero_3;

logic op_exp_is_max_0;
logic op_exp_is_max_1;
logic op_exp_is_max_2;
logic op_exp_is_max_3;

logic op_is_zero_0;
logic op_is_zero_1;
logic op_is_zero_2;
logic op_is_zero_3;

logic op_is_inf_0;
logic op_is_inf_1;
logic op_is_inf_2;
logic op_is_inf_3;

logic op_is_qnan_0;
logic op_is_qnan_1;
logic op_is_qnan_2;
logic op_is_qnan_3;

logic op_is_snan_0;
logic op_is_snan_1;
logic op_is_snan_2;
logic op_is_snan_3;

logic op_is_nan_0;
logic op_is_nan_1;
logic op_is_nan_2;
logic op_is_nan_3;

logic res_is_nan_0_d;
logic res_is_nan_0_q;
logic res_is_nan_1_d;
logic res_is_nan_1_q;
logic res_is_nan_2_d;
logic res_is_nan_2_q;
logic res_is_nan_3_d;
logic res_is_nan_3_q;

logic res_is_inf_0_d;
logic res_is_inf_0_q;
logic res_is_inf_1_d;
logic res_is_inf_1_q;
logic res_is_inf_2_d;
logic res_is_inf_2_q;
logic res_is_inf_3_d;
logic res_is_inf_3_q;

logic res_is_exact_zero_0_d;
logic res_is_exact_zero_0_q;
logic res_is_exact_zero_1_d;
logic res_is_exact_zero_1_q;
logic res_is_exact_zero_2_d;
logic res_is_exact_zero_2_q;
logic res_is_exact_zero_3_d;
logic res_is_exact_zero_3_q;

logic op_invalid_0_d;
logic op_invalid_0_q;
logic op_invalid_1_d;
logic op_invalid_1_q;
logic op_invalid_2_d;
logic op_invalid_2_q;
logic op_invalid_3_d;
logic op_invalid_3_q;

// Only used for s_mode
logic res_is_sqrt_2_d;
logic res_is_sqrt_2_q;
logic early_finish;
logic need_2_cycles_init;

logic [$clog2(F64_FRAC_W)-1:0] op_l_shift_num_pre_0;
logic [$clog2(F32_FRAC_W)-1:0] op_l_shift_num_pre_1;
logic [$clog2(F16_FRAC_W)-1:0] op_l_shift_num_pre_2;
logic [$clog2(F16_FRAC_W)-1:0] op_l_shift_num_pre_3;

logic [$clog2(F64_FRAC_W)-1:0] op_l_shift_num_0;
logic [$clog2(F32_FRAC_W)-1:0] op_l_shift_num_1;
logic [$clog2(F16_FRAC_W)-1:0] op_l_shift_num_2;
logic [$clog2(F16_FRAC_W)-1:0] op_l_shift_num_3;

logic [F64_FRAC_W-1:0] op_frac_pre_shifted_0;
logic [F32_FRAC_W-1:0] op_frac_pre_shifted_1;
logic [F16_FRAC_W-1:0] op_frac_pre_shifted_2;
logic [F16_FRAC_W-1:0] op_frac_pre_shifted_3;

// For f64.frac, the Normalization operation is done in 2 cycles
logic [(F64_FRAC_W-1)-1:0] op_frac_l_shifted_s5_to_s2;
// For f32/f16.frac, the Normalization operation is done in 1 cycle
logic [(F32_FRAC_W-1)-1:0] op_frac_l_shifted_1;
logic [(F16_FRAC_W-1)-1:0] op_frac_l_shifted_2;
logic [(F16_FRAC_W-1)-1:0] op_frac_l_shifted_3;

logic [(F64_FRAC_W-1)-1:0] op_frac_l_shifted_0;

logic op_frac_is_zero_0;
logic op_frac_is_zero_1;
logic op_frac_is_zero_2;
logic op_frac_is_zero_3;

// For F64, it needs 13 cycles for iter, so we would get 13 * 4 + 2 = 54-bit root after iter is finished.
// At the beginning, rt could be {1}.{54'b0}, but finally it must become something like {0}.{1, 53'bx}
// So we only need to store the digits after the decimal point, and we must have rt[54] = ~rt[53]. So we would have:
// rt_full[54:0] = {~rt[53]}.{rt[53:0]}
// rt_m1_full[54:0] = {0}.{1, rt_m1[52:0]}

// This design would add "delay(INV_GATE)" to the critical path, it should be negligible.
// By doing this, we replace the 1-bit reg with a 1-bit INV_GATE, which should reduce some area (I have to admit that the area reduction is very small.)

// The similar method is applied to f32/f16
// f32: 26-bit rt, 25-bit rt_m1
// f16: 14-bit rt, 13-bit rt_m1

logic [3-1:0] rt_1st_0;
logic [3-1:0] rt_1st_1;
logic [3-1:0] rt_1st_2;
logic [3-1:0] rt_1st_3;
// MSB.idx is 55:
// rt_q[55: 2]: For f64_0
// rt_q[55:30]: For f32_0
// rt_q[55:42]: For f16_0
// MSB.idx is 41:
// rt_q[41:28]: For f16_2
// MSB.idx is 27:
// rt_q[27: 2]: For f32_1
// rt_q[27:14]: For f16_1
// MSB.idx is 13:
// rt_q[13: 0]: For f16_3
logic rt_en;
logic [56-1:0] rt_d;
logic [56-1:0] rt_q;

// MSB.idx is 52:
// rt_m1_q[52: 0]: For f64_0
// rt_m1_q[52:28]: For f32_0
// rt_m1_q[52:40]: For f16_0
// MSB.idx is 39:
// rt_m1_q[39:27]: For f16_2
// MSB.idx is 26:
// rt_m1_q[26: 2]: For f32_1
// rt_m1_q[26:14]: For f16_1
// MSB.idx is 13:
// rt_m1_q[13: 1]: For f16_3
logic rt_m1_en;
logic [53-1:0] rt_m1_d;
logic [53-1:0] rt_m1_q;

logic [56-1:0] rt_iter_init;
logic [53-1:0] rt_m1_iter_init;
logic [56-1:0] nxt_rt;
logic [53-1:0] nxt_rt_m1;

logic [F64_FULL_RT_W-1:0] rt_iter_init_0;
logic [F32_FULL_RT_W-1:0] rt_iter_init_1;
logic [F16_FULL_RT_W-1:0] rt_iter_init_2;
logic [F16_FULL_RT_W-1:0] rt_iter_init_3;

logic [F64_FULL_RT_W-1:0] rt_m1_iter_init_0;
logic [F32_FULL_RT_W-1:0] rt_m1_iter_init_1;
logic [F16_FULL_RT_W-1:0] rt_m1_iter_init_2;
logic [F16_FULL_RT_W-1:0] rt_m1_iter_init_3;

logic [F64_FULL_RT_W-1:0] nxt_rt_0 [2-1:0];
logic [F64_FULL_RT_W-1:0] nxt_rt_m1_0 [2-1:0];

logic [F32_FULL_RT_W-1:0] nxt_rt_1 [2-1:0];
logic [F32_FULL_RT_W-1:0] nxt_rt_m1_1 [2-1:0];

logic [F16_FULL_RT_W-1:0] nxt_rt_2 [2-1:0];
logic [F16_FULL_RT_W-1:0] nxt_rt_m1_2 [2-1:0];

logic [F16_FULL_RT_W-1:0] nxt_rt_3 [2-1:0];
logic [F16_FULL_RT_W-1:0] nxt_rt_m1_3 [2-1:0];

logic exp_is_odd_pre_0_0;
logic exp_is_odd_pre_0_1;
logic exp_is_odd_pre_0_2;
logic exp_is_odd_pre_0_3;

logic current_exp_is_odd_0;
logic current_exp_is_odd_1;
logic current_exp_is_odd_2;
logic current_exp_is_odd_3;

logic [(F64_FRAC_W-1)-1:0] current_frac_0;
logic [(F32_FRAC_W-1)-1:0] current_frac_1;
logic [(F16_FRAC_W-1)-1:0] current_frac_2;
logic [(F16_FRAC_W-1)-1:0] current_frac_3;

// This is a global mask...
logic mask_en;
logic [13-1:0] mask_d;
logic [13-1:0] mask_q;

logic [F64_REM_W-1:0] f_r_s_iter_init_pre_0;
logic [F32_REM_W-1:0] f_r_s_iter_init_pre_1;
logic [F16_REM_W-1:0] f_r_s_iter_init_pre_2;
logic [F16_REM_W-1:0] f_r_s_iter_init_pre_3;

logic [F64_REM_W-1:0] f_r_s_iter_init_0;
logic [F32_REM_W-1:0] f_r_s_iter_init_1;
logic [F16_REM_W-1:0] f_r_s_iter_init_2;
logic [F16_REM_W-1:0] f_r_s_iter_init_3;

logic [F64_REM_W-1:0] f_r_c_iter_init_0;
logic [F32_REM_W-1:0] f_r_c_iter_init_1;
logic [F16_REM_W-1:0] f_r_c_iter_init_2;
logic [F16_REM_W-1:0] f_r_c_iter_init_3;

logic f_r_s_en;
logic [REM_W-1:0] f_r_s_d;
logic [REM_W-1:0] f_r_s_q;
logic f_r_c_en;
logic [REM_W-1:0] f_r_c_d;
logic [REM_W-1:0] f_r_c_q;
logic [REM_W-1:0] f_r_s_iter_init;
logic [REM_W-1:0] f_r_c_iter_init;

logic [REM_W-1:0] nxt_f_r_s;
logic [REM_W-1:0] nxt_f_r_c;

logic nr_f_r_7b_for_nxt_cycle_s0_qds_0_en;
logic [7-1:0] nr_f_r_7b_for_nxt_cycle_s0_qds_0_d;
logic [7-1:0] nr_f_r_7b_for_nxt_cycle_s0_qds_0_q;
logic nr_f_r_9b_for_nxt_cycle_s1_qds_0_en;
logic [9-1:0] nr_f_r_9b_for_nxt_cycle_s1_qds_0_d;
logic [9-1:0] nr_f_r_9b_for_nxt_cycle_s1_qds_0_q;

logic nr_f_r_7b_for_nxt_cycle_s0_qds_1_en;
logic [7-1:0] nr_f_r_7b_for_nxt_cycle_s0_qds_1_d;
logic [7-1:0] nr_f_r_7b_for_nxt_cycle_s0_qds_1_q;
logic nr_f_r_9b_for_nxt_cycle_s1_qds_1_en;
logic [9-1:0] nr_f_r_9b_for_nxt_cycle_s1_qds_1_d;
logic [9-1:0] nr_f_r_9b_for_nxt_cycle_s1_qds_1_q;

logic nr_f_r_7b_for_nxt_cycle_s0_qds_2_en;
logic [7-1:0] nr_f_r_7b_for_nxt_cycle_s0_qds_2_d;
logic [7-1:0] nr_f_r_7b_for_nxt_cycle_s0_qds_2_q;
logic nr_f_r_9b_for_nxt_cycle_s1_qds_2_en;
logic [9-1:0] nr_f_r_9b_for_nxt_cycle_s1_qds_2_d;
logic [9-1:0] nr_f_r_9b_for_nxt_cycle_s1_qds_2_q;

logic nr_f_r_7b_for_nxt_cycle_s0_qds_3_en;
logic [7-1:0] nr_f_r_7b_for_nxt_cycle_s0_qds_3_d;
logic [7-1:0] nr_f_r_7b_for_nxt_cycle_s0_qds_3_q;
logic nr_f_r_9b_for_nxt_cycle_s1_qds_3_en;
logic [9-1:0] nr_f_r_9b_for_nxt_cycle_s1_qds_3_d;
logic [9-1:0] nr_f_r_9b_for_nxt_cycle_s1_qds_3_q;

logic [8-1:0] adder_8b_iter_init_0;
logic [8-1:0] adder_8b_iter_init_1;
logic [8-1:0] adder_8b_iter_init_2;
logic [8-1:0] adder_8b_iter_init_3;

logic [9-1:0] adder_9b_iter_init_0;
logic [9-1:0] adder_9b_iter_init_1;
logic [9-1:0] adder_9b_iter_init_2;
logic [9-1:0] adder_9b_iter_init_3;

logic a0_iter_init_0;
logic a0_iter_init_1;
logic a0_iter_init_2;
logic a0_iter_init_3;

logic a2_iter_init_0;
logic a2_iter_init_1;
logic a2_iter_init_2;
logic a2_iter_init_3;

logic a3_iter_init_0;
logic a3_iter_init_1;
logic a3_iter_init_2;
logic a3_iter_init_3;

logic a4_iter_init_0;
logic a4_iter_init_1;
logic a4_iter_init_2;
logic a4_iter_init_3;

logic [7-1:0] m_neg_1_iter_init_0;
logic [7-1:0] m_neg_1_iter_init_1;
logic [7-1:0] m_neg_1_iter_init_2;
logic [7-1:0] m_neg_1_iter_init_3;

logic [7-1:0] m_neg_0_iter_init_0;
logic [7-1:0] m_neg_0_iter_init_1;
logic [7-1:0] m_neg_0_iter_init_2;
logic [7-1:0] m_neg_0_iter_init_3;

logic [7-1:0] m_pos_1_iter_init_0;
logic [7-1:0] m_pos_1_iter_init_1;
logic [7-1:0] m_pos_1_iter_init_2;
logic [7-1:0] m_pos_1_iter_init_3;

logic [7-1:0] m_pos_2_iter_init_0;
logic [7-1:0] m_pos_2_iter_init_1;
logic [7-1:0] m_pos_2_iter_init_2;
logic [7-1:0] m_pos_2_iter_init_3;

logic [7-1:0] adder_7b_res_for_nxt_cycle_s0_qds_0;
logic [7-1:0] adder_7b_res_for_nxt_cycle_s0_qds_1;
logic [7-1:0] adder_7b_res_for_nxt_cycle_s0_qds_2;
logic [7-1:0] adder_7b_res_for_nxt_cycle_s0_qds_3;

logic [9-1:0] adder_9b_res_for_nxt_cycle_s1_qds_0;
logic [9-1:0] adder_9b_res_for_nxt_cycle_s1_qds_1;
logic [9-1:0] adder_9b_res_for_nxt_cycle_s1_qds_2;
logic [9-1:0] adder_9b_res_for_nxt_cycle_s1_qds_3;

// [6:5] = 00 -> A 5-bit reg is enough
logic m_neg_1_for_nxt_cycle_s0_qds_0_en;
logic [5-1:0] m_neg_1_for_nxt_cycle_s0_qds_0_d;
logic [5-1:0] m_neg_1_for_nxt_cycle_s0_qds_0_q;

logic m_neg_1_for_nxt_cycle_s0_qds_1_en;
logic [5-1:0] m_neg_1_for_nxt_cycle_s0_qds_1_d;
logic [5-1:0] m_neg_1_for_nxt_cycle_s0_qds_1_q;

logic m_neg_1_for_nxt_cycle_s0_qds_2_en;
logic [5-1:0] m_neg_1_for_nxt_cycle_s0_qds_2_d;
logic [5-1:0] m_neg_1_for_nxt_cycle_s0_qds_2_q;

logic m_neg_1_for_nxt_cycle_s0_qds_3_en;
logic [5-1:0] m_neg_1_for_nxt_cycle_s0_qds_3_d;
logic [5-1:0] m_neg_1_for_nxt_cycle_s0_qds_3_q;

// [6:4] = 000 -> A 4-bit reg is enough
logic m_neg_0_for_nxt_cycle_s0_qds_0_en;
logic [4-1:0] m_neg_0_for_nxt_cycle_s0_qds_0_d;
logic [4-1:0] m_neg_0_for_nxt_cycle_s0_qds_0_q;

logic m_neg_0_for_nxt_cycle_s0_qds_1_en;
logic [4-1:0] m_neg_0_for_nxt_cycle_s0_qds_1_d;
logic [4-1:0] m_neg_0_for_nxt_cycle_s0_qds_1_q;

logic m_neg_0_for_nxt_cycle_s0_qds_2_en;
logic [4-1:0] m_neg_0_for_nxt_cycle_s0_qds_2_d;
logic [4-1:0] m_neg_0_for_nxt_cycle_s0_qds_2_q;

logic m_neg_0_for_nxt_cycle_s0_qds_3_en;
logic [4-1:0] m_neg_0_for_nxt_cycle_s0_qds_3_d;
logic [4-1:0] m_neg_0_for_nxt_cycle_s0_qds_3_q;

// [6:3] = 1111 -> A 3-bit reg is enough
logic m_pos_1_for_nxt_cycle_s0_qds_0_en;
logic [3-1:0] m_pos_1_for_nxt_cycle_s0_qds_0_d;
logic [3-1:0] m_pos_1_for_nxt_cycle_s0_qds_0_q;

logic m_pos_1_for_nxt_cycle_s0_qds_1_en;
logic [3-1:0] m_pos_1_for_nxt_cycle_s0_qds_1_d;
logic [3-1:0] m_pos_1_for_nxt_cycle_s0_qds_1_q;

logic m_pos_1_for_nxt_cycle_s0_qds_2_en;
logic [3-1:0] m_pos_1_for_nxt_cycle_s0_qds_2_d;
logic [3-1:0] m_pos_1_for_nxt_cycle_s0_qds_2_q;

logic m_pos_1_for_nxt_cycle_s0_qds_3_en;
logic [3-1:0] m_pos_1_for_nxt_cycle_s0_qds_3_d;
logic [3-1:0] m_pos_1_for_nxt_cycle_s0_qds_3_q;

// [6:5] = 11, [0] = 0 -> A 4-bit reg is enough
logic m_pos_2_for_nxt_cycle_s0_qds_0_en;
logic [4-1:0] m_pos_2_for_nxt_cycle_s0_qds_0_d;
logic [4-1:0] m_pos_2_for_nxt_cycle_s0_qds_0_q;

logic m_pos_2_for_nxt_cycle_s0_qds_1_en;
logic [4-1:0] m_pos_2_for_nxt_cycle_s0_qds_1_d;
logic [4-1:0] m_pos_2_for_nxt_cycle_s0_qds_1_q;

logic m_pos_2_for_nxt_cycle_s0_qds_2_en;
logic [4-1:0] m_pos_2_for_nxt_cycle_s0_qds_2_d;
logic [4-1:0] m_pos_2_for_nxt_cycle_s0_qds_2_q;

logic m_pos_2_for_nxt_cycle_s0_qds_3_en;
logic [4-1:0] m_pos_2_for_nxt_cycle_s0_qds_3_d;
logic [4-1:0] m_pos_2_for_nxt_cycle_s0_qds_3_q;

logic [7-1:0] m_neg_1_to_nxt_cycle_0;
logic [7-1:0] m_neg_1_to_nxt_cycle_1;
logic [7-1:0] m_neg_1_to_nxt_cycle_2;
logic [7-1:0] m_neg_1_to_nxt_cycle_3;

logic [7-1:0] m_neg_0_to_nxt_cycle_0;
logic [7-1:0] m_neg_0_to_nxt_cycle_1;
logic [7-1:0] m_neg_0_to_nxt_cycle_2;
logic [7-1:0] m_neg_0_to_nxt_cycle_3;

logic [7-1:0] m_pos_1_to_nxt_cycle_0;
logic [7-1:0] m_pos_1_to_nxt_cycle_1;
logic [7-1:0] m_pos_1_to_nxt_cycle_2;
logic [7-1:0] m_pos_1_to_nxt_cycle_3;

logic [7-1:0] m_pos_2_to_nxt_cycle_0;
logic [7-1:0] m_pos_2_to_nxt_cycle_1;
logic [7-1:0] m_pos_2_to_nxt_cycle_2;
logic [7-1:0] m_pos_2_to_nxt_cycle_3;

logic [REM_W-1:0] nr_f_r_merged;
logic [(((F16_REM_W + 1) * 3) + F16_REM_W)-1:0] nr_f_r;
logic [(((F16_REM_W + 1) * 3) + F16_REM_W)-1:0] nr_f_r_adder_in [2-1:0];

// 64 - 2 = 62
// 70 - 2 = 68
logic [(REM_W-2)-1:0] f_r_xor;
logic [(REM_W-2)-1:0] f_r_or;

logic rem_is_not_zero_0;
logic rem_is_not_zero_1;
logic rem_is_not_zero_2;
logic rem_is_not_zero_3;

logic select_rt_m1_0;
logic select_rt_m1_1;
logic select_rt_m1_2;
logic select_rt_m1_3;

logic f64_res_is_sqrt_2;
logic f32_res_is_sqrt_2;
logic f16_res_is_sqrt_2;
logic [56-1:0] rt_for_inc;
logic [F64_FRAC_W-1:0] rt_before_round;
logic [F64_FRAC_W-1:0] rt_m1_before_round;
logic [(F64_FRAC_W-1)-1:0] rt_pre_inc;
logic [(F64_FRAC_W-1)-1:0] rt_inc_lane;

logic [(F64_FRAC_W-1)-1:0] rt_m1_pre_inc_0;
logic [(F32_FRAC_W-1)-1:0] rt_m1_pre_inc_1;
logic [(F16_FRAC_W-1)-1:0] rt_m1_pre_inc_2;
logic [(F16_FRAC_W-1)-1:0] rt_m1_pre_inc_3;

logic [F64_FRAC_W-1:0] rt_inc_res;
logic [F64_FRAC_W-1:0] rt_inc_res_0;
logic [F32_FRAC_W-1:0] rt_inc_res_1;
logic [F16_FRAC_W-1:0] rt_inc_res_2;
logic [F16_FRAC_W-1:0] rt_inc_res_3;

logic [F64_FRAC_W-1:0] rt_m1_inc_res_0;
logic [F32_FRAC_W-1:0] rt_m1_inc_res_1;
logic [F16_FRAC_W-1:0] rt_m1_inc_res_2;
logic [F16_FRAC_W-1:0] rt_m1_inc_res_3;

logic guard_bit_rt_0;
logic guard_bit_rt_1;
logic guard_bit_rt_2;
logic guard_bit_rt_3;

logic round_bit_rt_0;
logic round_bit_rt_1;
logic round_bit_rt_2;
logic round_bit_rt_3;

logic sticky_bit_rt_0;
logic sticky_bit_rt_1;
logic sticky_bit_rt_2;
logic sticky_bit_rt_3;

logic rt_need_rup_0;
logic rt_need_rup_1;
logic rt_need_rup_2;
logic rt_need_rup_3;

logic inexact_rt_0;
logic inexact_rt_1;
logic inexact_rt_2;
logic inexact_rt_3;

logic inexact_0;
logic inexact_1;
logic inexact_2;
logic inexact_3;

logic guard_bit_rt_m1_0;
logic guard_bit_rt_m1_1;
logic guard_bit_rt_m1_2;
logic guard_bit_rt_m1_3;

logic round_bit_rt_m1_0;
logic round_bit_rt_m1_1;
logic round_bit_rt_m1_2;
logic round_bit_rt_m1_3;

logic rt_m1_need_rup_0;
logic rt_m1_need_rup_1;
logic rt_m1_need_rup_2;
logic rt_m1_need_rup_3;

logic [F64_FRAC_W-1:0] rt_rounded_0;
logic [F32_FRAC_W-1:0] rt_rounded_1;
logic [F16_FRAC_W-1:0] rt_rounded_2;
logic [F16_FRAC_W-1:0] rt_rounded_3;

logic [F64_FRAC_W-1:0] rt_m1_rounded_0;
logic [F32_FRAC_W-1:0] rt_m1_rounded_1;
logic [F16_FRAC_W-1:0] rt_m1_rounded_2;
logic [F16_FRAC_W-1:0] rt_m1_rounded_3;

logic carry_after_round_0;
logic carry_after_round_1;
logic carry_after_round_2;
logic carry_after_round_3;

logic [F64_FRAC_W-1:0] frac_rounded_0;
logic [F32_FRAC_W-1:0] frac_rounded_1;
logic [F16_FRAC_W-1:0] frac_rounded_2;
logic [F16_FRAC_W-1:0] frac_rounded_3;

logic [F64_EXP_W-1:0] exp_rounded_0;
logic [F32_EXP_W-1:0] exp_rounded_1;
logic [F16_EXP_W-1:0] exp_rounded_2;
logic [F16_EXP_W-1:0] exp_rounded_3;

logic [(F16_EXP_W + F16_FRAC_W)-1:0] f16_res_0;
logic [(F16_EXP_W + F16_FRAC_W)-1:0] f16_res_1;
logic [(F16_EXP_W + F16_FRAC_W)-1:0] f16_res_2;
logic [(F16_EXP_W + F16_FRAC_W)-1:0] f16_res_3;

logic [(F32_EXP_W + F32_FRAC_W)-1:0] f32_res_0;
logic [(F32_EXP_W + F32_FRAC_W)-1:0] f32_res_1;

logic [(F64_EXP_W + F64_FRAC_W)-1:0] f64_res_0;

logic [F16_EXP_W-1:0] f16_exp_res_0;
logic [F16_EXP_W-1:0] f16_exp_res_1;
logic [F16_EXP_W-1:0] f16_exp_res_2;
logic [F16_EXP_W-1:0] f16_exp_res_3;

logic [F32_EXP_W-1:0] f32_exp_res_0;
logic [F32_EXP_W-1:0] f32_exp_res_1;

logic [F64_EXP_W-1:0] f64_exp_res_0;

logic [(F16_FRAC_W-1)-1:0] f16_frac_res_0;
logic [(F16_FRAC_W-1)-1:0] f16_frac_res_1;
logic [(F16_FRAC_W-1)-1:0] f16_frac_res_2;
logic [(F16_FRAC_W-1)-1:0] f16_frac_res_3;

logic [(F32_FRAC_W-1)-1:0] f32_frac_res_0;
logic [(F32_FRAC_W-1)-1:0] f32_frac_res_1;

logic [(F64_FRAC_W-1)-1:0] f64_frac_res_0;

logic fflags_invalid_operation_0;
logic fflags_invalid_operation_1;
logic fflags_invalid_operation_2;
logic fflags_invalid_operation_3;

logic f16_fflags_invalid_operation;
logic f32_fflags_invalid_operation;
logic f64_fflags_invalid_operation;

logic fflags_div_by_zero_0;
logic fflags_div_by_zero_1;
logic fflags_div_by_zero_2;
logic fflags_div_by_zero_3;

logic f16_fflags_div_by_zero;
logic f32_fflags_div_by_zero;
logic f64_fflags_div_by_zero;

logic fflags_overflow_0;
logic fflags_overflow_1;
logic fflags_overflow_2;
logic fflags_overflow_3;

logic f16_fflags_overflow;
logic f32_fflags_overflow;
logic f64_fflags_overflow;

logic fflags_underflow_0;
logic fflags_underflow_1;
logic fflags_underflow_2;
logic fflags_underflow_3;

logic f16_fflags_underflow;
logic f32_fflags_underflow;
logic f64_fflags_underflow;

logic fflags_inexact_0;
logic fflags_inexact_1;
logic fflags_inexact_2;
logic fflags_inexact_3;

logic f16_fflags_inexact;
logic f32_fflags_inexact;
logic f64_fflags_inexact;

// signals end
// ================================================================================================================================================

// ================================================================================================================================================
// FSM ctrl
// ================================================================================================================================================
always_comb begin
	unique case(fsm_q)
		FSM_PRE_0:
			fsm_d = start_valid_i ? (early_finish ? FSM_POST_0 : (need_2_cycles_init ? FSM_PRE_1 : FSM_ITER)) : FSM_PRE_0;
		FSM_PRE_1:
			fsm_d = FSM_ITER;
		FSM_ITER:
			fsm_d = final_iter ? FSM_POST_0 : FSM_ITER;
		FSM_POST_0:
			fsm_d = finish_ready_i ? FSM_PRE_0 : FSM_POST_0;
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
assign finish_valid_o = fsm_q[FSM_POST_0_BIT];

// ================================================================================================================================================
// Pre
// ================================================================================================================================================

assign op_sign_0 = op_i[63];
assign op_sign_1 = op_i[31];
assign op_sign_2 = op_i[47];
assign op_sign_3 = op_i[15];

assign op_exp_0 = 
  ({(F64_EXP_W){fp_format_i == 2'd0}} & {{(F64_EXP_W - F16_EXP_W){1'b0}}, op_i[62 -: F16_EXP_W]})
| ({(F64_EXP_W){fp_format_i == 2'd1}} & {{(F64_EXP_W - F32_EXP_W){1'b0}}, op_i[62 -: F32_EXP_W]})
| ({(F64_EXP_W){fp_format_i == 2'd2}} & {{(F64_EXP_W - F64_EXP_W){1'b0}}, op_i[62 -: F64_EXP_W]});
assign op_exp_1 = 
  ({(F32_EXP_W){fp_format_i == 2'd0}} & {{(F32_EXP_W - F16_EXP_W){1'b0}}, op_i[30 -: F16_EXP_W]})
| ({(F32_EXP_W){fp_format_i == 2'd1}} & {{(F32_EXP_W - F32_EXP_W){1'b0}}, op_i[30 -: F32_EXP_W]});
assign op_exp_2 = op_i[46 -: F16_EXP_W];
assign op_exp_3 = op_i[14 -: F16_EXP_W];

assign op_exp_is_zero_0 = (op_exp_0 == '0);
assign op_exp_is_zero_1 = (op_exp_1 == '0);
assign op_exp_is_zero_2 = (op_exp_2 == '0);
assign op_exp_is_zero_3 = (op_exp_3 == '0);

assign op_exp_is_max_0 = (op_exp_0 == ((fp_format_i == 2'd0) ? 11'd31 : (fp_format_i == 2'd1) ? 11'd255 : 11'd2047));
assign op_exp_is_max_1 = (op_exp_1 == ((fp_format_i == 2'd0) ? 8'd31 : 8'd255));
assign op_exp_is_max_2 = (op_exp_2 == 5'd31);
assign op_exp_is_max_3 = (op_exp_3 == 5'd31);

assign op_is_zero_0 = op_exp_is_zero_0 & op_frac_is_zero_0;
assign op_is_zero_1 = op_exp_is_zero_1 & op_frac_is_zero_1;
assign op_is_zero_2 = op_exp_is_zero_2 & op_frac_is_zero_2;
assign op_is_zero_3 = op_exp_is_zero_3 & op_frac_is_zero_3;

assign op_is_inf_0 = op_exp_is_max_0 & op_frac_is_zero_0;
assign op_is_inf_1 = op_exp_is_max_1 & op_frac_is_zero_1;
assign op_is_inf_2 = op_exp_is_max_2 & op_frac_is_zero_2;
assign op_is_inf_3 = op_exp_is_max_3 & op_frac_is_zero_3;

assign op_is_qnan_0 = op_exp_is_max_0 & ((fp_format_i == 2'd0) ? op_i[57] : (fp_format_i == 2'd1) ? op_i[54] : op_i[51]);
assign op_is_qnan_1 = op_exp_is_max_1 & ((fp_format_i == 2'd0) ? op_i[25] : op_i[22]);
assign op_is_qnan_2 = op_exp_is_max_2 & op_i[41];
assign op_is_qnan_3 = op_exp_is_max_3 & op_i[ 9];

assign op_is_snan_0 = op_exp_is_max_0 & ~op_frac_is_zero_0 & ((fp_format_i == 2'd0) ? ~op_i[57] : (fp_format_i == 2'd1) ? ~op_i[54] : ~op_i[51]);
assign op_is_snan_1 = op_exp_is_max_1 & ~op_frac_is_zero_1 & ((fp_format_i == 2'd0) ? ~op_i[25] : ~op_i[22]);
assign op_is_snan_2 = op_exp_is_max_2 & ~op_frac_is_zero_2 & ~op_i[41];
assign op_is_snan_3 = op_exp_is_max_3 & ~op_frac_is_zero_3 & ~op_i[ 9];

assign op_is_nan_0 = (op_is_qnan_0 | op_is_snan_0);
assign op_is_nan_1 = (op_is_qnan_1 | op_is_snan_1);
assign op_is_nan_2 = (op_is_qnan_2 | op_is_snan_2);
assign op_is_nan_3 = (op_is_qnan_3 | op_is_snan_3);

assign op_invalid_0_d = (op_sign_0 & ~op_is_zero_0) | op_is_snan_0;
assign op_invalid_1_d = (op_sign_1 & ~op_is_zero_1) | op_is_snan_1;
assign op_invalid_2_d = (op_sign_2 & ~op_is_zero_2) | op_is_snan_2;
assign op_invalid_3_d = (op_sign_3 & ~op_is_zero_3) | op_is_snan_3;

assign res_is_nan_0_d = op_is_nan_0 | op_invalid_0_d;
assign res_is_nan_1_d = op_is_nan_1 | op_invalid_1_d;
assign res_is_nan_2_d = op_is_nan_2 | op_invalid_2_d;
assign res_is_nan_3_d = op_is_nan_3 | op_invalid_3_d;

assign res_is_inf_0_d = op_is_inf_0;
assign res_is_inf_1_d = op_is_inf_1;
assign res_is_inf_2_d = op_is_inf_2;
assign res_is_inf_3_d = op_is_inf_3;

assign res_is_exact_zero_0_d = op_is_zero_0;
assign res_is_exact_zero_1_d = op_is_zero_1;
assign res_is_exact_zero_2_d = op_is_zero_2;
assign res_is_exact_zero_3_d = op_is_zero_3;

assign out_sign_0_d = res_is_nan_0_d ? 1'b0 : op_sign_0;
assign out_sign_1_d = res_is_nan_1_d ? 1'b0 : op_sign_1;
assign out_sign_2_d = res_is_nan_2_d ? 1'b0 : op_sign_2;
assign out_sign_3_d = res_is_nan_3_d ? 1'b0 : op_sign_3;

assign out_exp_0_d = out_exp_pre_0[F64_EXP_W:1];
assign out_exp_1_d = out_exp_pre_1[F32_EXP_W:1];
assign out_exp_2_d = out_exp_pre_2[F16_EXP_W:1];
assign out_exp_3_d = out_exp_pre_3[F16_EXP_W:1];
// Convert it to one-hot.
assign fp_fmt_d = {fp_format_i == 2'd2, fp_format_i == 2'd1, fp_format_i == 2'd0};
assign rm_d = rm_i;
assign v_mode_d = vector_mode_i;
// This is only used in s_mode
assign res_is_sqrt_2_d = ~vector_mode_i & (
	  ({(1){fp_format_i == 2'd0}} & op_frac_is_zero_3 & ~op_exp_3[0])
	| ({(1){fp_format_i == 2'd1}} & op_frac_is_zero_1 & ~op_exp_1[0])
	| ({(1){fp_format_i == 2'd2}} & op_frac_is_zero_0 & ~op_exp_0[0])
);

always_ff @(posedge clk) begin
	if(start_handshaked) begin
		fp_fmt_q <= fp_fmt_d;
		rm_q <= rm_d;
		v_mode_q <= v_mode_d;
		res_is_sqrt_2_q <= res_is_sqrt_2_d;

		op_invalid_0_q <= op_invalid_0_d;
		op_invalid_1_q <= op_invalid_1_d;
		op_invalid_2_q <= op_invalid_2_d;
		op_invalid_3_q <= op_invalid_3_d;

		res_is_nan_0_q <= res_is_nan_0_d;
		res_is_nan_1_q <= res_is_nan_1_d;
		res_is_nan_2_q <= res_is_nan_2_d;
		res_is_nan_3_q <= res_is_nan_3_d;

		res_is_inf_0_q <= res_is_inf_0_d;
		res_is_inf_1_q <= res_is_inf_1_d;
		res_is_inf_2_q <= res_is_inf_2_d;
		res_is_inf_3_q <= res_is_inf_3_d;

		res_is_exact_zero_0_q <= res_is_exact_zero_0_d;
		res_is_exact_zero_1_q <= res_is_exact_zero_1_d;
		res_is_exact_zero_2_q <= res_is_exact_zero_2_d;
		res_is_exact_zero_3_q <= res_is_exact_zero_3_d;

		out_sign_0_q <= out_sign_0_d;
		out_sign_1_q <= out_sign_1_d;
		out_sign_2_q <= out_sign_2_d;
		out_sign_3_q <= out_sign_3_d;

		out_exp_0_q <= out_exp_0_d;
		out_exp_1_q <= out_exp_1_d;
		out_exp_2_q <= out_exp_2_d;
		out_exp_3_q <= out_exp_3_d;
	end
end

// ATTENTION: When(f64), "vector_mode_i" is ignored because we only have to deal with 1 input operand.
assign early_finish = 
(fp_format_i == 2'd2) ? (res_is_nan_0_d | res_is_inf_0_d | res_is_exact_zero_0_d | op_frac_is_zero_0) : 
(~vector_mode_i & (
	(fp_format_i == 2'd0) ? (res_is_nan_3_d | res_is_inf_3_d | res_is_exact_zero_3_d | op_frac_is_zero_3) : 
	(res_is_nan_1_d | res_is_inf_1_d | res_is_exact_zero_1_d | op_frac_is_zero_1)
));

// v_mode: Always use 2 cycles for init operation.
// s_mode: Use 2 cycles for init operation when the input operand is a denormal number.
assign need_2_cycles_init = 
(fp_format_i == 2'd2) ? op_exp_is_zero_0 : 
(vector_mode_i | ((fp_format_i == 2'd0) ? op_exp_is_zero_3 : op_exp_is_zero_1));

// ================================================================================================================================================
// LZC and Normalization
// ================================================================================================================================================
// Make the MSB of frac of different formats aligned.
assign op_frac_pre_shifted_0 = 
  ({(F64_FRAC_W){fp_format_i == 2'd0}} & {1'b0, op_i[48 +: (F16_FRAC_W - 1)], {(F64_FRAC_W - F16_FRAC_W){1'b0}}})
| ({(F64_FRAC_W){fp_format_i == 2'd1}} & {1'b0, op_i[32 +: (F32_FRAC_W - 1)], {(F64_FRAC_W - F32_FRAC_W){1'b0}}})
| ({(F64_FRAC_W){fp_format_i == 2'd2}} & {1'b0, op_i[ 0 +: (F64_FRAC_W - 1)], {(F64_FRAC_W - F64_FRAC_W){1'b0}}});
lzc #(
	.WIDTH(F64_FRAC_W),
	// 0: trailing zero.
	// 1: leading zero.
	.MODE(1'b1)
) u_lzc_0 (
	.in_i(op_frac_pre_shifted_0),
	.cnt_o(op_l_shift_num_pre_0),
	// The hiddend bit of frac is not considered here
	.empty_o(op_frac_is_zero_0)
);
assign op_l_shift_num_0 = {($clog2(F64_FRAC_W)){op_exp_is_zero_0}} & op_l_shift_num_pre_0;
// Do stage[5:2] l_shift in pre_0, because in the common CLZ logic, delay(MSB) should be smaller than delay(LSB).
assign op_frac_l_shifted_s5_to_s2 = op_frac_pre_shifted_0[0 +: (F64_FRAC_W - 1)] << {op_l_shift_num_0[5:2], 2'b0};
// Do stage[1:0] l_shift in pre_1
assign op_frac_l_shifted_0 = rt_m1_q[0 +: (F64_FRAC_W - 1)] << iter_num_q[1:0];

assign op_frac_pre_shifted_1 = 
  ({(F32_FRAC_W){fp_format_i == 2'd0}} & {1'b0, op_i[16 +: (F16_FRAC_W - 1)], {(F32_FRAC_W - F16_FRAC_W){1'b0}}})
| ({(F32_FRAC_W){fp_format_i == 2'd1}} & {1'b0, op_i[ 0 +: (F32_FRAC_W - 1)], {(F32_FRAC_W - F32_FRAC_W){1'b0}}});
lzc #(
	.WIDTH(F32_FRAC_W),
	// 0: trailing zero.
	// 1: leading zero.
	.MODE(1'b1)
) u_lzc_1 (
	.in_i(op_frac_pre_shifted_1),
	.cnt_o(op_l_shift_num_pre_1),
	// The hiddend bit of frac is not considered here
	.empty_o(op_frac_is_zero_1)
);
assign op_l_shift_num_1 = {($clog2(F32_FRAC_W)){op_exp_is_zero_1}} & op_l_shift_num_pre_1;
// For f32/f16, it should be able to finish "CLZ + l_shift" in 1 cycle.
assign op_frac_l_shifted_1 = op_frac_pre_shifted_1[0 +: (F32_FRAC_W - 1)] << op_l_shift_num_1;

assign op_frac_pre_shifted_2 = {1'b0, op_i[32 +: (F16_FRAC_W - 1)]};
lzc #(
	.WIDTH(F16_FRAC_W),
	// 0: trailing zero.
	// 1: leading zero.
	.MODE(1'b1)
) u_lzc_2 (
	.in_i(op_frac_pre_shifted_2),
	.cnt_o(op_l_shift_num_pre_2),
	// The hiddend bit of frac is not considered here
	.empty_o(op_frac_is_zero_2)
);
assign op_l_shift_num_2 = {($clog2(F16_FRAC_W)){op_exp_is_zero_2}} & op_l_shift_num_pre_2;
assign op_frac_l_shifted_2 = op_frac_pre_shifted_2[0 +: (F16_FRAC_W - 1)] << op_l_shift_num_2;

assign op_frac_pre_shifted_3 = {1'b0, op_i[0 +: (F16_FRAC_W - 1)]};
lzc #(
	.WIDTH(F16_FRAC_W),
	// 0: trailing zero.
	// 1: leading zero.
	.MODE(1'b1)
) u_lzc_3 (
	.in_i(op_frac_pre_shifted_3),
	.cnt_o(op_l_shift_num_pre_3),
	// The hiddend bit of frac is not considered here
	.empty_o(op_frac_is_zero_3)
);
assign op_l_shift_num_3 = {($clog2(F16_FRAC_W)){op_exp_is_zero_3}} & op_l_shift_num_pre_3;
assign op_frac_l_shifted_3 = op_frac_pre_shifted_3[0 +: (F16_FRAC_W - 1)] << op_l_shift_num_3;

// ================================================================================================================================================

// It might be a little bit difficult to understand the logic here.
// E: Real exponent of a number
// exp: The encoding value of E in a particular fp_format
// Take F64 as an example:
// x.E = 1023
// x.exp[10:0] = 1023 + 1023 = 11111111110
// sqrt_res.E = (1023 - 1) / 2 = 511
// sqrt_res.exp = 511 + 1023 = 10111111110
// Since x is a normal number -> op_l_shift_num[5:0] = 000000
// out_exp_pre[11:0] = 
// 011111111110 + 
// 001111111111 = 
// 101111111101
// 101111111101 >> 1 = 10111111110, correct !!!
// ================================================================================================================================================
// x.E = -1056
// x.exp[10:0] = 00000000000
// sqrt_res.E = -1056 / 2 = -528
// sqrt_res.exp = -528 + 1023 = 00111101111
// Since x is a denormal number -> op_l_shift_num[5:0] = 100010
// out_exp_pre[11:0] = 
// 000000000001 + 
// 001111011101 = 
// 001111011110
// 001111011110 >> 1 = 00111101111, correct !!!

// You can also try some other value for different fp_fmts
// By using this design, now the cost of getting the unrounded "out_exp" is:
// 1) A 12-bit FA
// 2) A 6-bit 3-to-1 MUX
// What if you use a native method to calculate "out_exp" ?
// If we only consider normal number:
// x.E = x.exp - ((fp_format_i == 2'd0) ? 15 : (fp_format_i == 2'd1) ? 127 : 1023);
// sqrt.E = x.E / 2;
// sqrt.exp = sqrt.E + ((fp_format_i == 2'd0) ? 15 : (fp_format_i == 2'd1) ? 127 : 1023);
// I think the design used here should lead to better PPA.
assign out_exp_pre_0 = {1'b0, op_exp_0[10:1], op_exp_0[0] | op_exp_is_zero_0} + {
	2'b0,
 	  ({(6){fp_format_i == 2'd0}} & 6'b0)
	| ({(6){fp_format_i == 2'd1}} & {3'b0, 2'b11, ~op_l_shift_num_0[4]})
	| ({(6){fp_format_i == 2'd2}} & {4'b1111, ~op_l_shift_num_0[5:4]}),
	~op_l_shift_num_0[3:0]
};
assign out_exp_pre_1 = {1'b0, op_exp_1[7:1], op_exp_1[0] | op_exp_is_zero_1} + {
	2'b0,
	  ({(3){fp_format_i == 2'd0}} & 3'b0)
	| ({(3){fp_format_i == 2'd1}} & {2'b11, ~op_l_shift_num_1[4]}),
	~op_l_shift_num_1[3:0]
};

assign out_exp_pre_2 = {1'b0, op_exp_2[4:1], op_exp_2[0] | op_exp_is_zero_2} + {2'b0, ~op_l_shift_num_2[3:0]};
assign out_exp_pre_3 = {1'b0, op_exp_3[4:1], op_exp_3[0] | op_exp_is_zero_3} + {2'b0, ~op_l_shift_num_3[3:0]};

// ================================================================================================================================================
// Get the 1st root digit
// ================================================================================================================================================
// For f64, we will not enter PRE_1 if input is a normal number.
assign exp_is_odd_pre_0_0 = op_exp_is_zero_0 ? op_l_shift_num_0[0] : ~op_exp_0[0];
assign current_exp_is_odd_0 = fsm_q[FSM_PRE_0_BIT] ? exp_is_odd_pre_0_0 : mask_q[0];
assign current_frac_0 = fsm_q[FSM_PRE_0_BIT] ? op_frac_pre_shifted_0[0 +: (F64_FRAC_W - 1)] : op_frac_l_shifted_0[0 +: (F64_FRAC_W - 1)];
// Look at the paper for more details.
// even_exp, digit in (2 ^ -1) is 0: s[1] = -2, rt = {0}.{1, 53'b0} , rt_m1 = {0}.{01, 52'b0}
// even_exp, digit in (2 ^ -1) is 1: s[1] = -1, rt = {0}.{11, 52'b0}, rt_m1 = {0}.{10, 52'b0}
// odd_exp, digit in (2 ^ -1) is 0 : s[1] = -1, rt = {0}.{11, 52'b0}, rt_m1 = {0}.{10, 52'b0}
// odd_exp, digit in (2 ^ -1) is 1 : s[1] =  0, rt = {1}.{00, 52'b0}, rt_m1 = {0}.{11, 52'b0}
// [0]: s[1] = -2
// [1]: s[1] = -1
// [2]: s[1] =  0
assign rt_1st_0[0] = ({current_exp_is_odd_0, current_frac_0[F64_FRAC_W-2]} == 2'b00);
assign rt_1st_0[1] = ({current_exp_is_odd_0, current_frac_0[F64_FRAC_W-2]} == 2'b01) | ({current_exp_is_odd_0, current_frac_0[F64_FRAC_W-2]} == 2'b10);
assign rt_1st_0[2] = ({current_exp_is_odd_0, current_frac_0[F64_FRAC_W-2]} == 2'b11);

// When (op_is_power_of_2) and odd_exp: 
// f_r_s_iter_init = {1, 55'b0}
// f_r_c_iter_init = {0111, 52'b0}
// In the nxt cycle, we would have "nr_f_r != 0" and "nr_f_r[REM_W-1] == 1". This is what we need, to get the correct rounded result for sqrt(2)
// When (op_is_power_of_2) and even_exp: 
// f_r_s_iter_init = {01, 54'b0}
// f_r_c_iter_init = {11, 54'b0}
// In the nxt cycle, we would have "nr_f_r == 0". This is what we need, to get the correct rounded result for sqrt(1)
// In conclusion, when (op_is_power_of_2), the ITER step could be skipped, and we only need to use 1-bit reg to store "op_is_power_of_2 & exp_is_odd", 
// instead of using 2-bit reg to store "{op_is_power_of_2, exp_is_odd}"
assign rt_iter_init_0 = 
  ({(F64_FULL_RT_W){rt_1st_0[0]}} & {3'b010, {(F64_FULL_RT_W - 3){1'b0}}})
| ({(F64_FULL_RT_W){rt_1st_0[1]}} & {3'b011, {(F64_FULL_RT_W - 3){1'b0}}})
| ({(F64_FULL_RT_W){rt_1st_0[2]}} & {3'b100, {(F64_FULL_RT_W - 3){1'b0}}});
// When s[1] = -2, the MSB of rt_m1 is not 1, which doesn't follow my assumption of rt_m1. But you should easily find that in the later iter process,
// the QDS "MUST" select "0/+1/+2" before the next "-1/-2" is selected. Therefore, rt_m1 will not be used until the next "-1/-2" is selected.
assign rt_m1_iter_init_0 = 
  ({(F64_FULL_RT_W){rt_1st_0[0]}} & {3'b001, {(F64_FULL_RT_W - 3){1'b0}}})
| ({(F64_FULL_RT_W){rt_1st_0[1]}} & {3'b010, {(F64_FULL_RT_W - 3){1'b0}}})
| ({(F64_FULL_RT_W){rt_1st_0[2]}} & {3'b011, {(F64_FULL_RT_W - 3){1'b0}}});

assign f_r_s_iter_init_pre_0 = {2'b11, current_exp_is_odd_0 ? {1'b1, current_frac_0, 1'b0} : {1'b0, 1'b1, current_frac_0}};
assign f_r_s_iter_init_0 = {f_r_s_iter_init_pre_0[(F64_REM_W-1)-2:0], 2'b0};
assign f_r_c_iter_init_0 = 
  ({(F64_REM_W){rt_1st_0[0]}} & {2'b11,   {(F64_REM_W - 2){1'b0}}})
| ({(F64_REM_W){rt_1st_0[1]}} & {4'b0111, {(F64_REM_W - 4){1'b0}}})
| ({(F64_REM_W){rt_1st_0[2]}} & {(F64_REM_W){1'b0}});


// This would be used for f32 in s_mode, so it might be needed in pre_0 if the input f32.op is a normal number.
assign exp_is_odd_pre_0_1 = op_exp_is_zero_1 ? op_l_shift_num_1[0] : ~op_exp_1[0];
assign current_exp_is_odd_1 = fsm_q[FSM_PRE_0_BIT] ? exp_is_odd_pre_0_1 : mask_q[1];
assign current_frac_1 = fsm_q[FSM_PRE_0_BIT] ? op_frac_pre_shifted_1[0 +: (F32_FRAC_W - 1)] : rt_q[0 +: (F32_FRAC_W - 1)];

assign rt_1st_1[0] = ({current_exp_is_odd_1, current_frac_1[F32_FRAC_W-2]} == 2'b00);
assign rt_1st_1[1] = ({current_exp_is_odd_1, current_frac_1[F32_FRAC_W-2]} == 2'b01) | ({current_exp_is_odd_1, current_frac_1[F32_FRAC_W-2]} == 2'b10);
assign rt_1st_1[2] = ({current_exp_is_odd_1, current_frac_1[F32_FRAC_W-2]} == 2'b11);

assign rt_iter_init_1 = 
  ({(F32_FULL_RT_W){rt_1st_1[0]}} & {3'b010, {(F32_FULL_RT_W - 3){1'b0}}})
| ({(F32_FULL_RT_W){rt_1st_1[1]}} & {3'b011, {(F32_FULL_RT_W - 3){1'b0}}})
| ({(F32_FULL_RT_W){rt_1st_1[2]}} & {3'b100, {(F32_FULL_RT_W - 3){1'b0}}});
assign rt_m1_iter_init_1 = 
  ({(F32_FULL_RT_W){rt_1st_1[0]}} & {3'b001, {(F32_FULL_RT_W - 3){1'b0}}})
| ({(F32_FULL_RT_W){rt_1st_1[1]}} & {3'b010, {(F32_FULL_RT_W - 3){1'b0}}})
| ({(F32_FULL_RT_W){rt_1st_1[2]}} & {3'b011, {(F32_FULL_RT_W - 3){1'b0}}});

assign f_r_s_iter_init_pre_1 = {2'b11, current_exp_is_odd_1 ? {1'b1, current_frac_1, 2'b0} : {1'b0, 1'b1, current_frac_1, 1'b0}};
assign f_r_s_iter_init_1 = {f_r_s_iter_init_pre_1[(F32_REM_W-1)-2:0], 2'b0};
assign f_r_c_iter_init_1 = 
  ({(F32_REM_W){rt_1st_1[0]}} & {2'b11,   {(F32_REM_W - 2){1'b0}}})
| ({(F32_REM_W){rt_1st_1[1]}} & {4'b0111, {(F32_REM_W - 4){1'b0}}})
| ({(F32_REM_W){rt_1st_1[2]}} & {(F32_REM_W){1'b0}});

// This would be only used for f16 in v_mode, so the init step is only done in pre_1.
assign exp_is_odd_pre_0_2 = op_exp_is_zero_2 ? op_l_shift_num_2[0] : ~op_exp_2[0];
// To get rid of "X" in the simulation, we just add a MUX here. But actually the MUX is not needed.
// How to eliminate "X" without this MUX ?
// Method: Run a signle "vector sqrt" at the beginning, so the regs used here must contain something and won't generate any "X".
// But it might be unacceptable for verfication engineer...
// assign current_exp_is_odd_2 = mask_q[2];
// assign current_frac_2 = rt_q[23 +: (F16_FRAC_W - 1)];
assign current_exp_is_odd_2 = fsm_q[FSM_PRE_0_BIT] ? exp_is_odd_pre_0_2 : mask_q[2];
assign current_frac_2 = fsm_q[FSM_PRE_0_BIT] ? op_frac_pre_shifted_2[0 +: (F16_FRAC_W - 1)] : rt_q[23 +: (F16_FRAC_W - 1)];

assign rt_1st_2[0] = ({current_exp_is_odd_2, current_frac_2[F16_FRAC_W-2]} == 2'b00);
assign rt_1st_2[1] = ({current_exp_is_odd_2, current_frac_2[F16_FRAC_W-2]} == 2'b01) | ({current_exp_is_odd_2, current_frac_2[F16_FRAC_W-2]} == 2'b10);
assign rt_1st_2[2] = ({current_exp_is_odd_2, current_frac_2[F16_FRAC_W-2]} == 2'b11);

assign rt_iter_init_2 = 
  ({(F16_FULL_RT_W){rt_1st_2[0]}} & {3'b010, {(F16_FULL_RT_W - 3){1'b0}}})
| ({(F16_FULL_RT_W){rt_1st_2[1]}} & {3'b011, {(F16_FULL_RT_W - 3){1'b0}}})
| ({(F16_FULL_RT_W){rt_1st_2[2]}} & {3'b100, {(F16_FULL_RT_W - 3){1'b0}}});
assign rt_m1_iter_init_2 = 
  ({(F16_FULL_RT_W){rt_1st_2[0]}} & {3'b001, {(F16_FULL_RT_W - 3){1'b0}}})
| ({(F16_FULL_RT_W){rt_1st_2[1]}} & {3'b010, {(F16_FULL_RT_W - 3){1'b0}}})
| ({(F16_FULL_RT_W){rt_1st_2[2]}} & {3'b011, {(F16_FULL_RT_W - 3){1'b0}}});

assign f_r_s_iter_init_pre_2 = {2'b11, current_exp_is_odd_2 ? {1'b1, current_frac_2, 3'b0} : {1'b0, 1'b1, current_frac_2, 2'b0}};
assign f_r_s_iter_init_2 = {f_r_s_iter_init_pre_2[(F16_REM_W-1)-2:0], 2'b0};
assign f_r_c_iter_init_2 = 
  ({(F16_REM_W){rt_1st_2[0]}} & {2'b11,   {(F16_REM_W - 2){1'b0}}})
| ({(F16_REM_W){rt_1st_2[1]}} & {4'b0111, {(F16_REM_W - 4){1'b0}}})
| ({(F16_REM_W){rt_1st_2[2]}} & {(F16_REM_W){1'b0}});

// This would be used for f16 in s_mode, so it might be needed in pre_0 if the input f32.op is a normal number.
assign exp_is_odd_pre_0_3 = op_exp_is_zero_3 ? op_l_shift_num_3[0] : ~op_exp_3[0];
assign current_exp_is_odd_3 = fsm_q[FSM_PRE_0_BIT] ? exp_is_odd_pre_0_3 : mask_q[3];
assign current_frac_3 = fsm_q[FSM_PRE_0_BIT] ? op_frac_pre_shifted_3[0 +: (F16_FRAC_W - 1)] : rt_q[33 +: (F16_FRAC_W - 1)];

assign rt_1st_3[0] = ({current_exp_is_odd_3, current_frac_3[F16_FRAC_W-2]} == 2'b00);
assign rt_1st_3[1] = ({current_exp_is_odd_3, current_frac_3[F16_FRAC_W-2]} == 2'b01) | ({current_exp_is_odd_3, current_frac_3[F16_FRAC_W-2]} == 2'b10);
assign rt_1st_3[2] = ({current_exp_is_odd_3, current_frac_3[F16_FRAC_W-2]} == 2'b11);

assign rt_iter_init_3 = 
  ({(F16_FULL_RT_W){rt_1st_3[0]}} & {3'b010, {(F16_FULL_RT_W - 3){1'b0}}})
| ({(F16_FULL_RT_W){rt_1st_3[1]}} & {3'b011, {(F16_FULL_RT_W - 3){1'b0}}})
| ({(F16_FULL_RT_W){rt_1st_3[2]}} & {3'b100, {(F16_FULL_RT_W - 3){1'b0}}});
assign rt_m1_iter_init_3 = 
  ({(F16_FULL_RT_W){rt_1st_3[0]}} & {3'b001, {(F16_FULL_RT_W - 3){1'b0}}})
| ({(F16_FULL_RT_W){rt_1st_3[1]}} & {3'b010, {(F16_FULL_RT_W - 3){1'b0}}})
| ({(F16_FULL_RT_W){rt_1st_3[2]}} & {3'b011, {(F16_FULL_RT_W - 3){1'b0}}});

assign f_r_s_iter_init_pre_3 = {2'b11, current_exp_is_odd_3 ? {1'b1, current_frac_3, 3'b0} : {1'b0, 1'b1, current_frac_3, 2'b0}};
assign f_r_s_iter_init_3 = {f_r_s_iter_init_pre_3[(F16_REM_W-1)-2:0], 2'b0};
assign f_r_c_iter_init_3 = 
  ({(F16_REM_W){rt_1st_3[0]}} & {2'b11,   {(F16_REM_W - 2){1'b0}}})
| ({(F16_REM_W){rt_1st_3[1]}} & {4'b0111, {(F16_REM_W - 4){1'b0}}})
| ({(F16_REM_W){rt_1st_3[2]}} & {(F16_REM_W){1'b0}});
// ================================================================================================================================================

// MSB.idx is 55:
// rt_q[55: 2]: For f64_0
// rt_q[55:30]: For f32_0
// rt_q[55:42]: For f16_0
// MSB.idx is 41:
// rt_q[41:28]: For f16_2
// MSB.idx is 27:
// rt_q[27: 2]: For f32_1
// rt_q[27:14]: For f16_1
// MSB.idx is 13:
// rt_q[13: 0]: For f16_3

// MSB.idx is 52:
// rt_m1_q[52: 0]: For f64_0
// rt_m1_q[52:28]: For f32_0
// rt_m1_q[52:40]: For f16_0
// MSB.idx is 39:
// rt_m1_q[39:27]: For f16_2
// MSB.idx is 26:
// rt_m1_q[26: 2]: For f32_1
// rt_m1_q[26:14]: For f16_1
// MSB.idx is 13:
// rt_m1_q[13: 1]: For f16_3

// When we need to use 2 cycles for init:
// rt_q[ 0 +: 23]: store op_frac_l_shifted_1
// rt_q[23 +: 10]: store op_frac_l_shifted_2
// rt_q[33 +: 10]: store op_frac_l_shifted_3
// Make sure the lower parts of the rt_q is 0 when they are used for other fp_fmts.
assign rt_iter_init = {
	rt_iter_init_0[F64_FULL_RT_W-2 -: 2],
	12'b0,
	{(2){fsm_q[FSM_PRE_0_BIT] ? (fp_format_i == 2'd0) : fp_fmt_q[0]}} & rt_iter_init_2[F16_FULL_RT_W-2 -: 2],
	12'b0,
	{(2){fsm_q[FSM_PRE_0_BIT] ? ((fp_format_i == 2'd0) | (fp_format_i == 2'd1)) : (fp_fmt_q[0] | fp_fmt_q[1])}} & rt_iter_init_1[F32_FULL_RT_W-2 -: 2],
	12'b0,
	{(2){fsm_q[FSM_PRE_0_BIT] ? (fp_format_i == 2'd0) : fp_fmt_q[0]}} & rt_iter_init_3[F16_FULL_RT_W-2 -: 2],
	12'b0
};

assign rt_d = 
fsm_q[FSM_PRE_0_BIT] ? (need_2_cycles_init ? {
	rt_q[55:43],
	op_frac_l_shifted_3[0 +: (F16_FRAC_W - 1)],
	op_frac_l_shifted_2[0 +: (F16_FRAC_W - 1)],
	op_frac_l_shifted_1[0 +: (F32_FRAC_W - 1)]
} : rt_iter_init) : 
fsm_q[FSM_PRE_1_BIT] ? rt_iter_init : 
nxt_rt;
assign rt_en = start_handshaked | fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];


// Use rt_m1_q to store the unfinished op_frac_l_shifted_0, when we need to use 2 cycles for init.
// Make sure the lower parts of the rt_m1_q is 0 when they are used for other fp_fmts.
assign rt_m1_iter_init = {
	rt_m1_iter_init_0[F64_FULL_RT_W-3],
	12'b0,
	{(1){fsm_q[FSM_PRE_0_BIT] ? (fp_format_i == 2'd0) : fp_fmt_q[0]}} & rt_m1_iter_init_2[F16_FULL_RT_W-3],
	12'b0,
	{(1){fsm_q[FSM_PRE_0_BIT] ? ((fp_format_i == 2'd0) | (fp_format_i == 2'd1)) : (fp_fmt_q[0] | fp_fmt_q[1])}} & rt_m1_iter_init_1[F32_FULL_RT_W-3],
	12'b0,
	{(1){fsm_q[FSM_PRE_0_BIT] ? (fp_format_i == 2'd0) : fp_fmt_q[0]}} & rt_m1_iter_init_3[F16_FULL_RT_W-3],
	12'b0,
	1'b0
};

assign rt_m1_d  = 
fsm_q[FSM_PRE_0_BIT] ? (need_2_cycles_init ? {rt_m1_q[52], op_frac_l_shifted_s5_to_s2} : rt_m1_iter_init) : 
fsm_q[FSM_PRE_1_BIT] ? rt_m1_iter_init : 
nxt_rt_m1;
assign rt_m1_en = start_handshaked | fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];

assign mask_en = start_handshaked | fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];
// mask_q[3:0] is used to store whether the real exp of operands are odd
assign mask_d  = 
fsm_q[FSM_PRE_0_BIT] ? (need_2_cycles_init ? {
	mask_q[12:4],
	exp_is_odd_pre_0_3,
	exp_is_odd_pre_0_2,
	exp_is_odd_pre_0_1,
	exp_is_odd_pre_0_0
} : {1'b1, 12'b0}) : 
fsm_q[FSM_PRE_1_BIT] ? {1'b1, 12'b0} : 
(mask_q >> 1);

// For MERGED REM, the width is 70, the meaning of different positions:
// [69:54]
// f16: f16_0.rem[15: 0]
// f32: f32_0.rem[27:12]
// f64: f64_0.rem[55:40]
// [53:52]
// f16: 2'b0
// f32: f32_0.rem[11:10]
// f64: f64_0.rem[39:38]
// [51:36]
// f16: f16_2.rem[15: 0]
// f32: f32_0.rem[ 9: 0], 6'b0
// f64: f64_0.rem[37:22]
// [35:34]
// f16: 2'b0
// f32: 2'b0
// f64: f64_0.rem[21:20]
// [33:18]
// f16: f16_1.rem[15: 0]
// f32: f32_1.rem[27:12]
// f64: f64_0.rem[19: 4]
// [17:16]
// f16: 2'b0
// f32: f32_1.rem[11:10]
// f64: f64_0.rem[ 3: 2]
// [15: 0]
// f16: f16_3.rem[15: 0]
// f32: f32_1.rem[ 9: 0], 6'b0
// f64: f64_0.rem[ 1: 0], 14'b0

// For NOT_MERGED REM, the width is 64, the meaning of different positions:
// [63:48]
// f16: f16_0.rem[15: 0]
// f32: f32_0.rem[27:12]
// f64: f64_0.rem[55:40]
// [47:32]
// f16: f16_2.rem[15: 0]
// f32: f32_0.rem[11: 0], 4'b0
// f64: f64_0.rem[39:24]
// [31:16]
// f16: f16_1.rem[15: 0]
// f32: f32_1.rem[27:12]
// f64: f64_0.rem[23: 8]
// [15: 0]
// f16: f16_3.rem[15: 0]
// f32: f32_1.rem[11: 0], 4'b0
// f64: f64_0.rem[ 7: 0], 8'b0

generate
if(S0_CSA_IS_MERGED == 1) begin: g_merged_rem_init

	assign f_r_s_iter_init[69:54] = f_r_s_iter_init_0[55:40];

	// When(f16), f_r_s_iter_init_0[39:38] must be 2'b00 -> So we don't need a MUX logic here
	assign f_r_s_iter_init[53:52] = f_r_s_iter_init_0[39:38];

	// When(f32), f_r_s_iter_init_0[27:22] must be 6'b0 -> So we don't need a MUX logic here
	// assign f_r_s_iter_init[51:36] = fp_fmt_q[0] ? f_r_s_iter_init_2[15:0] : {
	// 	f_r_s_iter_init_0[37:28],
	// 	(fsm_q[FSM_PRE_0_BIT] | fp_fmt_q[2]) ? f_r_s_iter_init_0[27:22] : 6'b0
	// };
	assign f_r_s_iter_init[51:36] = (fsm_q[FSM_PRE_1_BIT] & fp_fmt_q[0]) ? f_r_s_iter_init_2[15:0] : f_r_s_iter_init_0[37:22];

	// When(f32/f16), f_r_s_iter_init_0[21:20] must be 2'b0 -> So we don't need a MUX logic here
	assign f_r_s_iter_init[35:34] = f_r_s_iter_init_0[21:20];

	assign f_r_s_iter_init[33:18] = 
	  ({(16){(fsm_q[FSM_PRE_0_BIT] & (fp_format_i == 2'd2)) | (fsm_q[FSM_PRE_1_BIT] &  fp_fmt_q[2])}} & f_r_s_iter_init_0[19: 4])
	| ({(16){(fsm_q[FSM_PRE_0_BIT] & (fp_format_i != 2'd2)) | (fsm_q[FSM_PRE_1_BIT] & ~fp_fmt_q[2])}} & f_r_s_iter_init_1[27:12]);

	// When(f16), f_r_s_iter_init_1[11:10] must be 2'b0 -> So we don't need a MUX logic here
	assign f_r_s_iter_init[17:16] = 
	  ({(16){(fsm_q[FSM_PRE_0_BIT] & (fp_format_i == 2'd2)) | (fsm_q[FSM_PRE_1_BIT] &  fp_fmt_q[2])}} & f_r_s_iter_init_0[ 3: 2])
	| ({(16){(fsm_q[FSM_PRE_0_BIT] & (fp_format_i != 2'd2)) | (fsm_q[FSM_PRE_1_BIT] & ~fp_fmt_q[2])}} & f_r_s_iter_init_1[11:10]);

	assign f_r_s_iter_init[15: 0] = 
	  ({(16){(fsm_q[FSM_PRE_0_BIT] & (fp_format_i == 2'd0)) | (fsm_q[FSM_PRE_1_BIT] & fp_fmt_q[0])}} & f_r_s_iter_init_3[15:0])
	| ({(16){(fsm_q[FSM_PRE_0_BIT] & (fp_format_i == 2'd1)) | (fsm_q[FSM_PRE_1_BIT] & fp_fmt_q[1])}} & {f_r_s_iter_init_1[9:0], 6'b0})
	| ({(16){(fsm_q[FSM_PRE_0_BIT] & (fp_format_i == 2'd2)) | (fsm_q[FSM_PRE_1_BIT] & fp_fmt_q[2])}} & {f_r_s_iter_init_0[1:0], 14'b0});


	// Actually, most parts of carry is ZERO.
	assign f_r_c_iter_init[69:54] = f_r_c_iter_init_0[55:40];

	assign f_r_c_iter_init[53:52] = f_r_c_iter_init_0[39:38];

	assign f_r_c_iter_init[51:36] = (fsm_q[FSM_PRE_1_BIT] & fp_fmt_q[0]) ? f_r_c_iter_init_2[15:0] : f_r_c_iter_init_0[37:22];

	assign f_r_c_iter_init[35:34] = f_r_c_iter_init_0[21:20];

	assign f_r_c_iter_init[33:18] = 
	  ({(16){(fsm_q[FSM_PRE_0_BIT] & (fp_format_i == 2'd2)) | (fsm_q[FSM_PRE_1_BIT] &  fp_fmt_q[2])}} & f_r_c_iter_init_0[19: 4])
	| ({(16){(fsm_q[FSM_PRE_0_BIT] & (fp_format_i != 2'd2)) | (fsm_q[FSM_PRE_1_BIT] & ~fp_fmt_q[2])}} & f_r_c_iter_init_1[27:12]);

	assign f_r_c_iter_init[17:16] = 
	  ({(16){(fsm_q[FSM_PRE_0_BIT] & (fp_format_i == 2'd2)) | (fsm_q[FSM_PRE_1_BIT] &  fp_fmt_q[2])}} & f_r_c_iter_init_0[ 3: 2])
	| ({(16){(fsm_q[FSM_PRE_0_BIT] & (fp_format_i != 2'd2)) | (fsm_q[FSM_PRE_1_BIT] & ~fp_fmt_q[2])}} & f_r_c_iter_init_1[11:10]);
	
	assign f_r_c_iter_init[15: 0] = 
	  ({(16){(fsm_q[FSM_PRE_0_BIT] & (fp_format_i == 2'd0)) | (fsm_q[FSM_PRE_1_BIT] & fp_fmt_q[0])}} & f_r_c_iter_init_3[15:0])
	| ({(16){(fsm_q[FSM_PRE_0_BIT] & (fp_format_i == 2'd1)) | (fsm_q[FSM_PRE_1_BIT] & fp_fmt_q[1])}} & {f_r_c_iter_init_1[9:0], 6'b0})
	| ({(16){(fsm_q[FSM_PRE_0_BIT] & (fp_format_i == 2'd2)) | (fsm_q[FSM_PRE_1_BIT] & fp_fmt_q[2])}} & {f_r_c_iter_init_0[1:0], 14'b0});
	
end else begin: g_n_merged_rem_init

	assign f_r_s_iter_init[63:48] = f_r_s_iter_init_0[55:40];

	// When(f32), f_r_s_iter_init_0[27:24] must be 4'b0 -> So we don't need a MUX logic here
	assign f_r_s_iter_init[47:32] = (fsm_q[FSM_PRE_1_BIT] & fp_fmt_q[0]) ? f_r_s_iter_init_2[15:0] : f_r_s_iter_init_0[39:24];

	assign f_r_s_iter_init[31:16] = 
	  ({(16){(fsm_q[FSM_PRE_0_BIT] & (fp_format_i == 2'd2)) | (fsm_q[FSM_PRE_1_BIT] &  fp_fmt_q[2])}} & f_r_s_iter_init_0[23: 8])
	| ({(16){(fsm_q[FSM_PRE_0_BIT] & (fp_format_i != 2'd2)) | (fsm_q[FSM_PRE_1_BIT] & ~fp_fmt_q[2])}} & f_r_s_iter_init_1[27:12]);

	assign f_r_s_iter_init[15: 0] = 
	  ({(16){(fsm_q[FSM_PRE_0_BIT] & (fp_format_i == 2'd0)) | (fsm_q[FSM_PRE_1_BIT] &  fp_fmt_q[0])}} & f_r_s_iter_init_3[15:0])
	| ({(16){(fsm_q[FSM_PRE_0_BIT] & (fp_format_i == 2'd1)) | (fsm_q[FSM_PRE_1_BIT] &  fp_fmt_q[1])}} & {f_r_s_iter_init_1[11:0], 4'b0})
	| ({(16){(fsm_q[FSM_PRE_0_BIT] & (fp_format_i == 2'd2)) | (fsm_q[FSM_PRE_1_BIT] &  fp_fmt_q[2])}} & {f_r_s_iter_init_0[7:0], 8'b0});


	// Actually, most parts of carry is ZERO.
	assign f_r_c_iter_init[63:48] = f_r_c_iter_init_0[55:40];

	assign f_r_c_iter_init[47:32] = (fsm_q[FSM_PRE_1_BIT] & fp_fmt_q[0]) ? f_r_c_iter_init_2[15:0] : f_r_c_iter_init_0[39:24];

	assign f_r_c_iter_init[31:16] = 
	  ({(16){(fsm_q[FSM_PRE_0_BIT] & (fp_format_i == 2'd2)) | (fsm_q[FSM_PRE_1_BIT] &  fp_fmt_q[2])}} & f_r_c_iter_init_0[23: 8])
	| ({(16){(fsm_q[FSM_PRE_0_BIT] & (fp_format_i != 2'd2)) | (fsm_q[FSM_PRE_1_BIT] & ~fp_fmt_q[2])}} & f_r_c_iter_init_1[27:12]);

	assign f_r_c_iter_init[15: 0] = 
	  ({(16){(fsm_q[FSM_PRE_0_BIT] & (fp_format_i == 2'd0)) | (fsm_q[FSM_PRE_1_BIT] &  fp_fmt_q[0])}} & f_r_c_iter_init_3[15:0])
	| ({(16){(fsm_q[FSM_PRE_0_BIT] & (fp_format_i == 2'd1)) | (fsm_q[FSM_PRE_1_BIT] &  fp_fmt_q[1])}} & {f_r_c_iter_init_1[11:0], 4'b0})
	| ({(16){(fsm_q[FSM_PRE_0_BIT] & (fp_format_i == 2'd2)) | (fsm_q[FSM_PRE_1_BIT] &  fp_fmt_q[2])}} & {f_r_c_iter_init_0[7:0], 8'b0});

end
endgenerate

assign f_r_s_en = start_handshaked | fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];
assign f_r_s_d  = (fsm_q[FSM_PRE_0_BIT] | fsm_q[FSM_PRE_1_BIT]) ? f_r_s_iter_init : nxt_f_r_s;

assign f_r_c_en = start_handshaked | fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];
assign f_r_c_d  = (fsm_q[FSM_PRE_0_BIT] | fsm_q[FSM_PRE_1_BIT]) ? f_r_c_iter_init : nxt_f_r_c;

assign iter_num_en = start_handshaked | fsm_q[FSM_PRE_1_BIT] | (fsm_q[FSM_ITER_BIT] & ~final_iter);
// Use this reg to store "op_l_shift_num_0[1:0]" -> Because we can't finish l_shift operation in 1 cycle.
assign iter_num_d  = 
fsm_q[FSM_PRE_0_BIT] ? (need_2_cycles_init ? {iter_num_q[3:2], op_l_shift_num_0[1:0]} : {
	  ({(4){fp_format_i == 2'd0}} & 4'd2)
	| ({(4){fp_format_i == 2'd1}} & 4'd5)
	| ({(4){fp_format_i == 2'd2}} & 4'd12)
}) : 
fsm_q[FSM_PRE_1_BIT] ? (
	  ({(4){fp_fmt_q[0]}} & 4'd2)
	| ({(4){fp_fmt_q[1]}} & 4'd5)
	| ({(4){fp_fmt_q[2]}} & 4'd12)
) : 
(iter_num_q - 4'd1);
assign final_iter = (iter_num_q == 4'd0);


// "f_r_c_iter_init_n" would only have 4-bit non-zero value, so a 4-bit FA is enough here
assign adder_8b_iter_init_0 = {f_r_s_iter_init_0[(F64_REM_W-1) -: 4] + f_r_c_iter_init_0[(F64_REM_W-1) -: 4], f_r_s_iter_init_0[(F64_REM_W-1)-4 -: 4]};
assign nr_f_r_7b_for_nxt_cycle_s0_qds_0_en = start_handshaked | fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];
assign nr_f_r_7b_for_nxt_cycle_s0_qds_0_d  = (fsm_q[FSM_PRE_0_BIT] | fsm_q[FSM_PRE_1_BIT]) ? adder_8b_iter_init_0[7:1] : adder_7b_res_for_nxt_cycle_s0_qds_0;

assign adder_8b_iter_init_1 = {f_r_s_iter_init_1[(F32_REM_W-1) -: 4] + f_r_c_iter_init_1[(F32_REM_W-1) -: 4], f_r_s_iter_init_1[(F32_REM_W-1)-4 -: 4]};
assign nr_f_r_7b_for_nxt_cycle_s0_qds_1_en = start_handshaked | fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];
assign nr_f_r_7b_for_nxt_cycle_s0_qds_1_d  = (fsm_q[FSM_PRE_0_BIT] | fsm_q[FSM_PRE_1_BIT]) ? adder_8b_iter_init_1[7:1] : adder_7b_res_for_nxt_cycle_s0_qds_1;

assign adder_8b_iter_init_2 = {f_r_s_iter_init_2[(F16_REM_W-1) -: 4] + f_r_c_iter_init_2[(F16_REM_W-1) -: 4], f_r_s_iter_init_2[(F16_REM_W-1)-4 -: 4]};
assign nr_f_r_7b_for_nxt_cycle_s0_qds_2_en = start_handshaked | fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];
assign nr_f_r_7b_for_nxt_cycle_s0_qds_2_d  = (fsm_q[FSM_PRE_0_BIT] | fsm_q[FSM_PRE_1_BIT]) ? adder_8b_iter_init_2[7:1] : adder_7b_res_for_nxt_cycle_s0_qds_2;

assign adder_8b_iter_init_3 = {f_r_s_iter_init_3[(F16_REM_W-1) -: 4] + f_r_c_iter_init_3[(F16_REM_W-1) -: 4], f_r_s_iter_init_3[(F16_REM_W-1)-4 -: 4]};
assign nr_f_r_7b_for_nxt_cycle_s0_qds_3_en = start_handshaked | fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];
assign nr_f_r_7b_for_nxt_cycle_s0_qds_3_d  = (fsm_q[FSM_PRE_0_BIT] | fsm_q[FSM_PRE_1_BIT]) ? adder_8b_iter_init_3[7:1] : adder_7b_res_for_nxt_cycle_s0_qds_3;


// "f_r_c_iter_init_n * 4" would only have 2-bit non-zero value, so a 2-bit FA is enough here
assign adder_9b_iter_init_0 = {f_r_s_iter_init_0[(F64_REM_W-1)-2 -: 2] + f_r_c_iter_init_0[(F64_REM_W-1)-2 -: 2], f_r_s_iter_init_0[(F64_REM_W-1)-2-2 -: 7]};
assign nr_f_r_9b_for_nxt_cycle_s1_qds_0_en = start_handshaked | fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];
assign nr_f_r_9b_for_nxt_cycle_s1_qds_0_d  = (fsm_q[FSM_PRE_0_BIT] | fsm_q[FSM_PRE_1_BIT]) ? adder_9b_iter_init_0 : adder_9b_res_for_nxt_cycle_s1_qds_0;

assign adder_9b_iter_init_1 = {f_r_s_iter_init_1[(F32_REM_W-1)-2 -: 2] + f_r_c_iter_init_1[(F32_REM_W-1)-2 -: 2], f_r_s_iter_init_1[(F32_REM_W-1)-2-2 -: 7]};
assign nr_f_r_9b_for_nxt_cycle_s1_qds_1_en = start_handshaked | fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];
assign nr_f_r_9b_for_nxt_cycle_s1_qds_1_d  = (fsm_q[FSM_PRE_0_BIT] | fsm_q[FSM_PRE_1_BIT]) ? adder_9b_iter_init_1 : adder_9b_res_for_nxt_cycle_s1_qds_1;

assign adder_9b_iter_init_2 = {f_r_s_iter_init_2[(F16_REM_W-1)-2 -: 2] + f_r_c_iter_init_2[(F16_REM_W-1)-2 -: 2], f_r_s_iter_init_2[(F16_REM_W-1)-2-2 -: 7]};
assign nr_f_r_9b_for_nxt_cycle_s1_qds_2_en = start_handshaked | fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];
assign nr_f_r_9b_for_nxt_cycle_s1_qds_2_d  = (fsm_q[FSM_PRE_0_BIT] | fsm_q[FSM_PRE_1_BIT]) ? adder_9b_iter_init_2 : adder_9b_res_for_nxt_cycle_s1_qds_2;

assign adder_9b_iter_init_3 = {f_r_s_iter_init_3[(F16_REM_W-1)-2 -: 2] + f_r_c_iter_init_3[(F16_REM_W-1)-2 -: 2], f_r_s_iter_init_3[(F16_REM_W-1)-2-2 -: 7]};
assign nr_f_r_9b_for_nxt_cycle_s1_qds_3_en = start_handshaked | fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];
assign nr_f_r_9b_for_nxt_cycle_s1_qds_3_d  = (fsm_q[FSM_PRE_0_BIT] | fsm_q[FSM_PRE_1_BIT]) ? adder_9b_iter_init_3 : adder_9b_res_for_nxt_cycle_s1_qds_3;


assign a0_iter_init_0 = rt_iter_init_0[F64_FULL_RT_W-1];
assign a2_iter_init_0 = rt_iter_init_0[F64_FULL_RT_W-3];
assign a3_iter_init_0 = rt_iter_init_0[F64_FULL_RT_W-4];
assign a4_iter_init_0 = rt_iter_init_0[F64_FULL_RT_W-5];
r4_qds_cg
u_r4_qds_cg_iter_init_0 (
	.a0_i(a0_iter_init_0),
	.a2_i(a2_iter_init_0),
	.a3_i(a3_iter_init_0),
	.a4_i(a4_iter_init_0),
	.m_neg_1_o(m_neg_1_iter_init_0),
	.m_neg_0_o(m_neg_0_iter_init_0),
	.m_pos_1_o(m_pos_1_iter_init_0),
	.m_pos_2_o(m_pos_2_iter_init_0)
);

assign a0_iter_init_1 = rt_iter_init_1[F32_FULL_RT_W-1];
assign a2_iter_init_1 = rt_iter_init_1[F32_FULL_RT_W-3];
assign a3_iter_init_1 = rt_iter_init_1[F32_FULL_RT_W-4];
assign a4_iter_init_1 = rt_iter_init_1[F32_FULL_RT_W-5];
r4_qds_cg
u_r4_qds_cg_iter_init_1 (
	.a0_i(a0_iter_init_1),
	.a2_i(a2_iter_init_1),
	.a3_i(a3_iter_init_1),
	.a4_i(a4_iter_init_1),
	.m_neg_1_o(m_neg_1_iter_init_1),
	.m_neg_0_o(m_neg_0_iter_init_1),
	.m_pos_1_o(m_pos_1_iter_init_1),
	.m_pos_2_o(m_pos_2_iter_init_1)
);

assign a0_iter_init_2 = rt_iter_init_2[F16_FULL_RT_W-1];
assign a2_iter_init_2 = rt_iter_init_2[F16_FULL_RT_W-3];
assign a3_iter_init_2 = rt_iter_init_2[F16_FULL_RT_W-4];
assign a4_iter_init_2 = rt_iter_init_2[F16_FULL_RT_W-5];
r4_qds_cg
u_r4_qds_cg_iter_init_2 (
	.a0_i(a0_iter_init_2),
	.a2_i(a2_iter_init_2),
	.a3_i(a3_iter_init_2),
	.a4_i(a4_iter_init_2),
	.m_neg_1_o(m_neg_1_iter_init_2),
	.m_neg_0_o(m_neg_0_iter_init_2),
	.m_pos_1_o(m_pos_1_iter_init_2),
	.m_pos_2_o(m_pos_2_iter_init_2)
);

assign a0_iter_init_3 = rt_iter_init_3[F16_FULL_RT_W-1];
assign a2_iter_init_3 = rt_iter_init_3[F16_FULL_RT_W-3];
assign a3_iter_init_3 = rt_iter_init_3[F16_FULL_RT_W-4];
assign a4_iter_init_3 = rt_iter_init_3[F16_FULL_RT_W-5];
r4_qds_cg
u_r4_qds_cg_iter_init_3 (
	.a0_i(a0_iter_init_3),
	.a2_i(a2_iter_init_3),
	.a3_i(a3_iter_init_3),
	.a4_i(a4_iter_init_3),
	.m_neg_1_o(m_neg_1_iter_init_3),
	.m_neg_0_o(m_neg_0_iter_init_3),
	.m_pos_1_o(m_pos_1_iter_init_3),
	.m_pos_2_o(m_pos_2_iter_init_3)
);


// [6:5] = 00, don't need to store it
assign m_neg_1_for_nxt_cycle_s0_qds_0_en = start_handshaked | fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];
assign m_neg_1_for_nxt_cycle_s0_qds_0_d  = (fsm_q[FSM_PRE_0_BIT] | fsm_q[FSM_PRE_1_BIT]) ? m_neg_1_iter_init_0[4:0] : m_neg_1_to_nxt_cycle_0[4:0];

assign m_neg_1_for_nxt_cycle_s0_qds_1_en = start_handshaked | fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];
assign m_neg_1_for_nxt_cycle_s0_qds_1_d  = (fsm_q[FSM_PRE_0_BIT] | fsm_q[FSM_PRE_1_BIT]) ? m_neg_1_iter_init_1[4:0] : m_neg_1_to_nxt_cycle_1[4:0];

assign m_neg_1_for_nxt_cycle_s0_qds_2_en = start_handshaked | fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];
assign m_neg_1_for_nxt_cycle_s0_qds_2_d  = (fsm_q[FSM_PRE_0_BIT] | fsm_q[FSM_PRE_1_BIT]) ? m_neg_1_iter_init_2[4:0] : m_neg_1_to_nxt_cycle_2[4:0];

assign m_neg_1_for_nxt_cycle_s0_qds_3_en = start_handshaked | fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];
assign m_neg_1_for_nxt_cycle_s0_qds_3_d  = (fsm_q[FSM_PRE_0_BIT] | fsm_q[FSM_PRE_1_BIT]) ? m_neg_1_iter_init_3[4:0] : m_neg_1_to_nxt_cycle_3[4:0];


// [6:4] = 000, don't need to store it
assign m_neg_0_for_nxt_cycle_s0_qds_0_en = start_handshaked | fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];
assign m_neg_0_for_nxt_cycle_s0_qds_0_d  = (fsm_q[FSM_PRE_0_BIT] | fsm_q[FSM_PRE_1_BIT]) ? m_neg_0_iter_init_0[3:0] : m_neg_0_to_nxt_cycle_0[3:0];

assign m_neg_0_for_nxt_cycle_s0_qds_1_en = start_handshaked | fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];
assign m_neg_0_for_nxt_cycle_s0_qds_1_d  = (fsm_q[FSM_PRE_0_BIT] | fsm_q[FSM_PRE_1_BIT]) ? m_neg_0_iter_init_1[3:0] : m_neg_0_to_nxt_cycle_1[3:0];

assign m_neg_0_for_nxt_cycle_s0_qds_2_en = start_handshaked | fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];
assign m_neg_0_for_nxt_cycle_s0_qds_2_d  = (fsm_q[FSM_PRE_0_BIT] | fsm_q[FSM_PRE_1_BIT]) ? m_neg_0_iter_init_2[3:0] : m_neg_0_to_nxt_cycle_2[3:0];

assign m_neg_0_for_nxt_cycle_s0_qds_3_en = start_handshaked | fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];
assign m_neg_0_for_nxt_cycle_s0_qds_3_d  = (fsm_q[FSM_PRE_0_BIT] | fsm_q[FSM_PRE_1_BIT]) ? m_neg_0_iter_init_3[3:0] : m_neg_0_to_nxt_cycle_3[3:0];


// [6:3] = 1111, don't need to store it
assign m_pos_1_for_nxt_cycle_s0_qds_0_en = start_handshaked | fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];
assign m_pos_1_for_nxt_cycle_s0_qds_0_d  = (fsm_q[FSM_PRE_0_BIT] | fsm_q[FSM_PRE_1_BIT]) ? m_pos_1_iter_init_0[2:0] : m_pos_1_to_nxt_cycle_0[2:0];

assign m_pos_1_for_nxt_cycle_s0_qds_1_en = start_handshaked | fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];
assign m_pos_1_for_nxt_cycle_s0_qds_1_d  = (fsm_q[FSM_PRE_0_BIT] | fsm_q[FSM_PRE_1_BIT]) ? m_pos_1_iter_init_1[2:0] : m_pos_1_to_nxt_cycle_1[2:0];

assign m_pos_1_for_nxt_cycle_s0_qds_2_en = start_handshaked | fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];
assign m_pos_1_for_nxt_cycle_s0_qds_2_d  = (fsm_q[FSM_PRE_0_BIT] | fsm_q[FSM_PRE_1_BIT]) ? m_pos_1_iter_init_2[2:0] : m_pos_1_to_nxt_cycle_2[2:0];

assign m_pos_1_for_nxt_cycle_s0_qds_3_en = start_handshaked | fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];
assign m_pos_1_for_nxt_cycle_s0_qds_3_d  = (fsm_q[FSM_PRE_0_BIT] | fsm_q[FSM_PRE_1_BIT]) ? m_pos_1_iter_init_3[2:0] : m_pos_1_to_nxt_cycle_3[2:0];


// [6:5] = 11, [0] = 0, don't need to store it
assign m_pos_2_for_nxt_cycle_s0_qds_0_en = start_handshaked | fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];
assign m_pos_2_for_nxt_cycle_s0_qds_0_d  = (fsm_q[FSM_PRE_0_BIT] | fsm_q[FSM_PRE_1_BIT]) ? m_pos_2_iter_init_0[4:1] : m_pos_2_to_nxt_cycle_0[4:1];

assign m_pos_2_for_nxt_cycle_s0_qds_1_en = start_handshaked | fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];
assign m_pos_2_for_nxt_cycle_s0_qds_1_d  = (fsm_q[FSM_PRE_0_BIT] | fsm_q[FSM_PRE_1_BIT]) ? m_pos_2_iter_init_1[4:1] : m_pos_2_to_nxt_cycle_1[4:1];

assign m_pos_2_for_nxt_cycle_s0_qds_2_en = start_handshaked | fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];
assign m_pos_2_for_nxt_cycle_s0_qds_2_d  = (fsm_q[FSM_PRE_0_BIT] | fsm_q[FSM_PRE_1_BIT]) ? m_pos_2_iter_init_2[4:1] : m_pos_2_to_nxt_cycle_2[4:1];

assign m_pos_2_for_nxt_cycle_s0_qds_3_en = start_handshaked | fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];
assign m_pos_2_for_nxt_cycle_s0_qds_3_d  = (fsm_q[FSM_PRE_0_BIT] | fsm_q[FSM_PRE_1_BIT]) ? m_pos_2_iter_init_3[4:1] : m_pos_2_to_nxt_cycle_3[4:1];

always_ff @(posedge clk) begin
	if(rt_en)
		rt_q <= rt_d;
	if(rt_m1_en)
		rt_m1_q <= rt_m1_d;
	if(mask_en)
		mask_q <= mask_d;
	if(f_r_s_en)
		f_r_s_q <= f_r_s_d;
	if(f_r_c_en)
		f_r_c_q <= f_r_c_d;
	if(iter_num_en)
		iter_num_q <= iter_num_d;



	if(nr_f_r_7b_for_nxt_cycle_s0_qds_0_en)
		nr_f_r_7b_for_nxt_cycle_s0_qds_0_q <= nr_f_r_7b_for_nxt_cycle_s0_qds_0_d;
	if(nr_f_r_7b_for_nxt_cycle_s0_qds_1_en)
		nr_f_r_7b_for_nxt_cycle_s0_qds_1_q <= nr_f_r_7b_for_nxt_cycle_s0_qds_1_d;
	if(nr_f_r_7b_for_nxt_cycle_s0_qds_2_en)
		nr_f_r_7b_for_nxt_cycle_s0_qds_2_q <= nr_f_r_7b_for_nxt_cycle_s0_qds_2_d;
	if(nr_f_r_7b_for_nxt_cycle_s0_qds_3_en)
		nr_f_r_7b_for_nxt_cycle_s0_qds_3_q <= nr_f_r_7b_for_nxt_cycle_s0_qds_3_d;

	if(nr_f_r_9b_for_nxt_cycle_s1_qds_0_en)
		nr_f_r_9b_for_nxt_cycle_s1_qds_0_q <= nr_f_r_9b_for_nxt_cycle_s1_qds_0_d;
	if(nr_f_r_9b_for_nxt_cycle_s1_qds_1_en)
		nr_f_r_9b_for_nxt_cycle_s1_qds_1_q <= nr_f_r_9b_for_nxt_cycle_s1_qds_1_d;
	if(nr_f_r_9b_for_nxt_cycle_s1_qds_2_en)
		nr_f_r_9b_for_nxt_cycle_s1_qds_2_q <= nr_f_r_9b_for_nxt_cycle_s1_qds_2_d;
	if(nr_f_r_9b_for_nxt_cycle_s1_qds_3_en)
		nr_f_r_9b_for_nxt_cycle_s1_qds_3_q <= nr_f_r_9b_for_nxt_cycle_s1_qds_3_d;



	if(m_neg_1_for_nxt_cycle_s0_qds_0_en)
		m_neg_1_for_nxt_cycle_s0_qds_0_q <= m_neg_1_for_nxt_cycle_s0_qds_0_d;
	if(m_neg_1_for_nxt_cycle_s0_qds_1_en)
		m_neg_1_for_nxt_cycle_s0_qds_1_q <= m_neg_1_for_nxt_cycle_s0_qds_1_d;
	if(m_neg_1_for_nxt_cycle_s0_qds_2_en)
		m_neg_1_for_nxt_cycle_s0_qds_2_q <= m_neg_1_for_nxt_cycle_s0_qds_2_d;
	if(m_neg_1_for_nxt_cycle_s0_qds_3_en)
		m_neg_1_for_nxt_cycle_s0_qds_3_q <= m_neg_1_for_nxt_cycle_s0_qds_3_d;

	if(m_neg_0_for_nxt_cycle_s0_qds_0_en)
		m_neg_0_for_nxt_cycle_s0_qds_0_q <= m_neg_0_for_nxt_cycle_s0_qds_0_d;
	if(m_neg_0_for_nxt_cycle_s0_qds_1_en)
		m_neg_0_for_nxt_cycle_s0_qds_1_q <= m_neg_0_for_nxt_cycle_s0_qds_1_d;
	if(m_neg_0_for_nxt_cycle_s0_qds_2_en)
		m_neg_0_for_nxt_cycle_s0_qds_2_q <= m_neg_0_for_nxt_cycle_s0_qds_2_d;
	if(m_neg_0_for_nxt_cycle_s0_qds_3_en)
		m_neg_0_for_nxt_cycle_s0_qds_3_q <= m_neg_0_for_nxt_cycle_s0_qds_3_d;

	if(m_pos_1_for_nxt_cycle_s0_qds_0_en)
		m_pos_1_for_nxt_cycle_s0_qds_0_q <= m_pos_1_for_nxt_cycle_s0_qds_0_d;
	if(m_pos_1_for_nxt_cycle_s0_qds_1_en)
		m_pos_1_for_nxt_cycle_s0_qds_1_q <= m_pos_1_for_nxt_cycle_s0_qds_1_d;
	if(m_pos_1_for_nxt_cycle_s0_qds_2_en)
		m_pos_1_for_nxt_cycle_s0_qds_2_q <= m_pos_1_for_nxt_cycle_s0_qds_2_d;
	if(m_pos_1_for_nxt_cycle_s0_qds_3_en)
		m_pos_1_for_nxt_cycle_s0_qds_3_q <= m_pos_1_for_nxt_cycle_s0_qds_3_d;

	if(m_pos_2_for_nxt_cycle_s0_qds_0_en)
		m_pos_2_for_nxt_cycle_s0_qds_0_q <= m_pos_2_for_nxt_cycle_s0_qds_0_d;
	if(m_pos_2_for_nxt_cycle_s0_qds_1_en)
		m_pos_2_for_nxt_cycle_s0_qds_1_q <= m_pos_2_for_nxt_cycle_s0_qds_1_d;
	if(m_pos_2_for_nxt_cycle_s0_qds_2_en)
		m_pos_2_for_nxt_cycle_s0_qds_2_q <= m_pos_2_for_nxt_cycle_s0_qds_2_d;
	if(m_pos_2_for_nxt_cycle_s0_qds_3_en)
		m_pos_2_for_nxt_cycle_s0_qds_3_q <= m_pos_2_for_nxt_cycle_s0_qds_3_d;
end

// ================================================================================================================================================
// ITER
// ================================================================================================================================================
fpsqrt_r16_block #(
	// Put some parameters here, which can be changed by other modules
	.S0_CSA_SPECULATIVE(S0_CSA_SPECULATIVE),
	.S0_CSA_MERGED(S0_CSA_MERGED),	
	.S1_QDS_SPECULATIVE(S1_QDS_SPECULATIVE),
	.S1_CSA_SPECULATIVE(S1_CSA_SPECULATIVE),
	.S1_CSA_MERGED(S1_CSA_MERGED),
	.REM_W(REM_W),
	.RT_DIG_W(RT_DIG_W)
) u_fpsqrt_r16_block (
	.fp_fmt_i(fp_fmt_q),
	.f_r_s_i(f_r_s_q),
	.f_r_c_i(f_r_c_q),
	.rt_i(rt_q),
	.rt_m1_i(rt_m1_q),
	.mask_i(mask_q),

	.nr_f_r_7b_for_nxt_cycle_s0_qds_0_i(nr_f_r_7b_for_nxt_cycle_s0_qds_0_q),
	.nr_f_r_7b_for_nxt_cycle_s0_qds_1_i(nr_f_r_7b_for_nxt_cycle_s0_qds_1_q),
	.nr_f_r_7b_for_nxt_cycle_s0_qds_2_i(nr_f_r_7b_for_nxt_cycle_s0_qds_2_q),
	.nr_f_r_7b_for_nxt_cycle_s0_qds_3_i(nr_f_r_7b_for_nxt_cycle_s0_qds_3_q),

	.nr_f_r_9b_for_nxt_cycle_s1_qds_0_i(nr_f_r_9b_for_nxt_cycle_s1_qds_0_q),
	.nr_f_r_9b_for_nxt_cycle_s1_qds_1_i(nr_f_r_9b_for_nxt_cycle_s1_qds_1_q),
	.nr_f_r_9b_for_nxt_cycle_s1_qds_2_i(nr_f_r_9b_for_nxt_cycle_s1_qds_2_q),
	.nr_f_r_9b_for_nxt_cycle_s1_qds_3_i(nr_f_r_9b_for_nxt_cycle_s1_qds_3_q),

	.m_neg_1_for_nxt_cycle_s0_qds_0_i(m_neg_1_for_nxt_cycle_s0_qds_0_q),
	.m_neg_1_for_nxt_cycle_s0_qds_1_i(m_neg_1_for_nxt_cycle_s0_qds_1_q),
	.m_neg_1_for_nxt_cycle_s0_qds_2_i(m_neg_1_for_nxt_cycle_s0_qds_2_q),
	.m_neg_1_for_nxt_cycle_s0_qds_3_i(m_neg_1_for_nxt_cycle_s0_qds_3_q),

	.m_neg_0_for_nxt_cycle_s0_qds_0_i(m_neg_0_for_nxt_cycle_s0_qds_0_q),
	.m_neg_0_for_nxt_cycle_s0_qds_1_i(m_neg_0_for_nxt_cycle_s0_qds_1_q),
	.m_neg_0_for_nxt_cycle_s0_qds_2_i(m_neg_0_for_nxt_cycle_s0_qds_2_q),
	.m_neg_0_for_nxt_cycle_s0_qds_3_i(m_neg_0_for_nxt_cycle_s0_qds_3_q),

	.m_pos_1_for_nxt_cycle_s0_qds_0_i(m_pos_1_for_nxt_cycle_s0_qds_0_q),
	.m_pos_1_for_nxt_cycle_s0_qds_1_i(m_pos_1_for_nxt_cycle_s0_qds_1_q),
	.m_pos_1_for_nxt_cycle_s0_qds_2_i(m_pos_1_for_nxt_cycle_s0_qds_2_q),
	.m_pos_1_for_nxt_cycle_s0_qds_3_i(m_pos_1_for_nxt_cycle_s0_qds_3_q),

	.m_pos_2_for_nxt_cycle_s0_qds_0_i(m_pos_2_for_nxt_cycle_s0_qds_0_q),
	.m_pos_2_for_nxt_cycle_s0_qds_1_i(m_pos_2_for_nxt_cycle_s0_qds_1_q),
	.m_pos_2_for_nxt_cycle_s0_qds_2_i(m_pos_2_for_nxt_cycle_s0_qds_2_q),
	.m_pos_2_for_nxt_cycle_s0_qds_3_i(m_pos_2_for_nxt_cycle_s0_qds_3_q),

	.nxt_rt_o(nxt_rt),
	.nxt_rt_m1_o(nxt_rt_m1),
	
	.nxt_f_r_s_o(nxt_f_r_s),
	.nxt_f_r_c_o(nxt_f_r_c),

	.adder_7b_res_for_nxt_cycle_s0_qds_0_o(adder_7b_res_for_nxt_cycle_s0_qds_0),
	.adder_7b_res_for_nxt_cycle_s0_qds_1_o(adder_7b_res_for_nxt_cycle_s0_qds_1),
	.adder_7b_res_for_nxt_cycle_s0_qds_2_o(adder_7b_res_for_nxt_cycle_s0_qds_2),
	.adder_7b_res_for_nxt_cycle_s0_qds_3_o(adder_7b_res_for_nxt_cycle_s0_qds_3),

	.adder_9b_res_for_nxt_cycle_s1_qds_0_o(adder_9b_res_for_nxt_cycle_s1_qds_0),
	.adder_9b_res_for_nxt_cycle_s1_qds_1_o(adder_9b_res_for_nxt_cycle_s1_qds_1),
	.adder_9b_res_for_nxt_cycle_s1_qds_2_o(adder_9b_res_for_nxt_cycle_s1_qds_2),
	.adder_9b_res_for_nxt_cycle_s1_qds_3_o(adder_9b_res_for_nxt_cycle_s1_qds_3),

	.m_neg_1_to_nxt_cycle_0_o(m_neg_1_to_nxt_cycle_0),
	.m_neg_1_to_nxt_cycle_1_o(m_neg_1_to_nxt_cycle_1),
	.m_neg_1_to_nxt_cycle_2_o(m_neg_1_to_nxt_cycle_2),
	.m_neg_1_to_nxt_cycle_3_o(m_neg_1_to_nxt_cycle_3),

	.m_neg_0_to_nxt_cycle_0_o(m_neg_0_to_nxt_cycle_0),
	.m_neg_0_to_nxt_cycle_1_o(m_neg_0_to_nxt_cycle_1),
	.m_neg_0_to_nxt_cycle_2_o(m_neg_0_to_nxt_cycle_2),
	.m_neg_0_to_nxt_cycle_3_o(m_neg_0_to_nxt_cycle_3),

	.m_pos_1_to_nxt_cycle_0_o(m_pos_1_to_nxt_cycle_0),
	.m_pos_1_to_nxt_cycle_1_o(m_pos_1_to_nxt_cycle_1),
	.m_pos_1_to_nxt_cycle_2_o(m_pos_1_to_nxt_cycle_2),
	.m_pos_1_to_nxt_cycle_3_o(m_pos_1_to_nxt_cycle_3),

	.m_pos_2_to_nxt_cycle_0_o(m_pos_2_to_nxt_cycle_0),
	.m_pos_2_to_nxt_cycle_1_o(m_pos_2_to_nxt_cycle_1),
	.m_pos_2_to_nxt_cycle_2_o(m_pos_2_to_nxt_cycle_2),
	.m_pos_2_to_nxt_cycle_3_o(m_pos_2_to_nxt_cycle_3)
);


// ================================================================================================================================================
// Post
// ================================================================================================================================================
// [66:51]: f_r_s[63:48]
// [50:50]: Set to 0 when(f16), used as a separation
// [49:34]: f_r_s[47:32]
// [33:33]: Set to 0 when(f32/f16), used as a separation
// [32:17]: f_r_s[31:16]
// [16:16]: Set to 0 when(f16), used as a separation
// [15: 0]: f_r_s[15: 0]

// The algorithm we use is "Minimally Redundant Radix 4", and its redundnat factor is 2/3.
// So we must have "|rem| <= D * (2/3)" -> when (nr_f_r < 0), the "positive rem" must be NON_ZERO
// Which means we don't have to calculate "nr_f_r_plus_d"
assign nr_f_r_adder_in[0] = {
	f_r_s_q[63:48],
	~fp_fmt_q[0],
	f_r_s_q[47:32],
	fp_fmt_q[2],
	f_r_s_q[31:16],
	~fp_fmt_q[0],
	f_r_s_q[15: 0]
};
assign nr_f_r_adder_in[1] = {
	f_r_c_q[63:48],
	1'b0,
	f_r_c_q[47:32],
	1'b0,
	f_r_c_q[31:16],
	1'b0,
	f_r_c_q[15: 0]
};
assign nr_f_r = nr_f_r_adder_in[0] + nr_f_r_adder_in[1];

assign nr_f_r_merged = f_r_s_q + f_r_c_q;

// For MERGED REM, the width is 70, the meaning of different positions:
// [69:54]
// f16: f16_0.rem[15: 0]
// f32: f32_0.rem[27:12]
// f64: f64_0.rem[55:40]
// [53:52]
// f16: 2'b0
// f32: f32_0.rem[11:10]
// f64: f64_0.rem[39:38]
// [51:36]
// f16: f16_2.rem[15: 0]
// f32: f32_0.rem[ 9: 0], 6'b0
// f64: f64_0.rem[37:22]
// [35:34]
// f16: 2'b0
// f32: 2'b0
// f64: f64_0.rem[21:20]
// [33:18]
// f16: f16_1.rem[15: 0]
// f32: f32_1.rem[27:12]
// f64: f64_0.rem[19: 4]
// [17:16]
// f16: 2'b0
// f32: f32_1.rem[11:10]
// f64: f64_0.rem[ 3: 2]
// [15: 0]
// f16: f16_3.rem[15: 0]
// f32: f32_1.rem[ 9: 0], 6'b0
// f64: f64_0.rem[ 1: 0], 14'b0

// For xor/or[67:0], the fields that are used to tell whether "nr_f_r == 0" for different fp_fmts:
// f16
// [67:54]: f16_0
// [53:50]: Not used when(f16)
// [49:36]: f16_2
// [35:32]: Not used when(f16)
// [31:18]: f16_1
// [17:14]: Not used when(f16)
// [13: 0]: f16_3
// f32
// [67:42]: f32_0
// [41:32]: Not used when(f32)
// [31: 6]: f32_1
// [ 5: 0]: Not used when(f32)
// f64
// [67:14]: f64_0
// [13: 0]: Not used when(f64)

// For NOT_MERGED REM, the width is 64, the meaning of different positions:
// [63:48]
// f16: f16_0.rem[15: 0]
// f32: f32_0.rem[27:12]
// f64: f64_0.rem[55:40]
// [47:32]
// f16: f16_2.rem[15: 0]
// f32: f32_0.rem[11: 0], 4'b0
// f64: f64_0.rem[39:24]
// [31:16]
// f16: f16_1.rem[15: 0]
// f32: f32_1.rem[27:12]
// f64: f64_0.rem[23: 8]
// [15: 0]
// f16: f16_3.rem[15: 0]
// f32: f32_1.rem[11: 0], 4'b0
// f64: f64_0.rem[ 7: 0], 8'b0

// For xor/or[61:0], the fields that are used to tell whether "nr_f_r == 0" for different fp_fmts:
// f16
// [61:48]: f16_0
// [47:46]: Not used when(f16)
// [45:32]: f16_2
// [31:30]: Not used when(f16)
// [29:16]: f16_1
// [15:14]: Not used when(f16)
// [13: 0]: f16_3
// f32
// [61:36]: f32_0
// [35:30]: Not used when(f32)
// [29: 4]: f32_1
// [ 3: 0]: Not used when(f32)
// f16
// [61: 8]: f64_0
// [ 7: 0]: Not used when(f64)
assign f_r_xor = f_r_s_q[(REM_W-1)-1:1] ^ f_r_c_q[(REM_W-1)-1:1];
assign f_r_or  = f_r_s_q[(REM_W-1)-2:0] | f_r_c_q[(REM_W-1)-2:0];

generate
if(S0_CSA_IS_MERGED == 1) begin

	// I hope the EDA could extract the common part of "!=" calculation and do some area reduction work...
	assign rem_is_not_zero_0 = nr_f_r_merged[69] | (
		  (f_r_xor[67:54] != f_r_or[67:54])
		| (fp_fmt_q[1] & (f_r_xor[53:42] != f_r_or[53:42]))
		| (fp_fmt_q[2] & (f_r_xor[41:14] != f_r_or[41:14]))
	);
	assign rem_is_not_zero_1 = nr_f_r_merged[33] | (
		  (f_r_xor[31:18] != f_r_or[31:18])
		| (fp_fmt_q[1] & (f_r_xor[17:6] != f_r_or[17:6]))
	);
	assign rem_is_not_zero_2 = nr_f_r_merged[51] | (f_r_xor[49:36] != f_r_or[49:36]);
	assign rem_is_not_zero_3 = nr_f_r_merged[15] | (f_r_xor[13: 0] != f_r_or[13: 0]);

	// *_2 is only used in vector_mode, so it has nothing to do with "res_is_sqrt_2"
	assign select_rt_m1_0 = nr_f_r_merged[69] & ~res_is_sqrt_2_q;
	assign select_rt_m1_1 = nr_f_r_merged[33] & ~res_is_sqrt_2_q;
	assign select_rt_m1_2 = nr_f_r_merged[51];
	assign select_rt_m1_3 = nr_f_r_merged[15] & ~res_is_sqrt_2_q;

end else begin

	// I hope the EDA could extract the common part of "!=" calculation and do some area reduction work...
	assign rem_is_not_zero_0 = nr_f_r[66] | (
		  (f_r_xor[61:48] != f_r_or[61:48])
		| (fp_fmt_q[1] & (f_r_xor[47:36] != f_r_or[47:36]))
		| (fp_fmt_q[2] & (f_r_xor[35: 8] != f_r_or[35: 8]))
	);
	assign rem_is_not_zero_1 = nr_f_r[32] | (
		  (f_r_xor[29:16] != f_r_or[29:16])
		| (fp_fmt_q[1] & (f_r_xor[15:4] != f_r_or[15:4]))
	);
	assign rem_is_not_zero_2 = nr_f_r[49] | (f_r_xor[45:32] != f_r_or[45:32]);
	assign rem_is_not_zero_3 = nr_f_r[15] | (f_r_xor[13: 0] != f_r_or[13: 0]);

	// *_2 is only used in vector_mode, so it has nothing to do with "res_is_sqrt_2"
	assign select_rt_m1_0 = nr_f_r[66] & ~res_is_sqrt_2_q;
	assign select_rt_m1_1 = nr_f_r[32] & ~res_is_sqrt_2_q;
	assign select_rt_m1_2 = nr_f_r[49];
	assign select_rt_m1_3 = nr_f_r[15] & ~res_is_sqrt_2_q;

end
endgenerate



assign f64_res_is_sqrt_2 = res_is_sqrt_2_q & fp_fmt_q[2];
assign f32_res_is_sqrt_2 = res_is_sqrt_2_q & fp_fmt_q[1];
assign f16_res_is_sqrt_2 = res_is_sqrt_2_q & fp_fmt_q[0];

assign rt_for_inc = res_is_sqrt_2_q ? (
	  ({(56){f64_res_is_sqrt_2}} & {SQRT_2_WITH_ROUND_BIT, rt_q[1:0]})
	| ({(56){f32_res_is_sqrt_2}} & {rt_q[55:28], SQRT_2_WITH_ROUND_BIT[53 -: 25], rt_q[2:0]})
	| ({(56){f16_res_is_sqrt_2}} & {rt_q[55:14], SQRT_2_WITH_ROUND_BIT[53 -: 12], rt_q[1:0]})
) : rt_q;


// f64
// [51:0] = rt_q[54:3]
// f32
// [51:29] = rt_q[54:32]: used for f32_0
// [28:25] = rt_q[31:28]: f32_0.round_bit + 2 unnecessary bits, they won't influence the correctness of the rounding -> Don't use MUX here
// [   24] = 0: Make sure the carry of f32_1 will not influence f32_0
// [23: 1] = rt_q[26: 4], used for f32_1
// [    0] = rt_q[    3]: f32_1.round_bit, they won't influence the correctness of the rounding -> Don't use MUX here
// f16
// [51:42] = rt_q[54:45]: used for f16_0
// [41:39] = rt_q[44:42]: f16_0.round_bit + 2 unnecessary bits, they won't influence the correctness of the rounding -> Don't use MUX here
// [   38] = 0: Make sure the carry of f16_2 will not influence f16_0
// [37:28] = rt_q[40:31]: used for f16_2
// [27:25] = rt_q[30:28]: f16_2.round_bit + 2 unnecessary bits, they won't influence the correctness of the rounding -> Don't use MUX here
// [   24] = 0: Make sure the carry of f16_1 will not influence f16_2
// [23:14] = rt_q[26:17]: used for f16_1
// [13:11] = rt_q[16:14]: f16_1.round_bit + 2 unnecessary bits, they won't influence the correctness of the rounding -> Don't use MUX here
// [   10] = 0: Make sure the carry of f16_3 will not influence f16_1
// [ 9: 0] = rt_q[12: 3]: used for f16_3
assign rt_pre_inc = {
	rt_for_inc[54:42],
	fp_fmt_q[0] ? 1'b0 : rt_for_inc[41],
	rt_for_inc[40:28],
	(fp_fmt_q[0] | fp_fmt_q[1]) ? 1'b0 : rt_for_inc[27],
	rt_for_inc[26:14],
	fp_fmt_q[0] ? 1'b0 : rt_for_inc[13],
	rt_for_inc[12:3]
};

assign rt_inc_lane = 
  ({(52){fp_fmt_q[0]}} & {
	9'b0, 1'b1,
	4'b0,
	9'b0, 1'b1,
	4'b0,
	9'b0, 1'b1,
	4'b0,
	9'b0, 1'b1
})
| ({(52){fp_fmt_q[1]}} & {
	22'b0, 1'b1,
	5'b0,
	22'b0, 1'b1,
	1'b0
})
| ({(52){fp_fmt_q[2]}} & {51'b0, 1'b1});

assign rt_inc_res = {1'b0, rt_pre_inc} + {1'b0, rt_inc_lane};

assign rt_m1_pre_inc_0 = rt_m1_q[52:1];
assign rt_m1_pre_inc_1 = rt_m1_q[26:4];
assign rt_m1_pre_inc_2 = rt_m1_q[39:30];
assign rt_m1_pre_inc_3 = rt_m1_q[13:4];


assign guard_bit_rt_0 = 
  ({(1){fp_fmt_q[0]}} & rt_q[45])
| ({(1){fp_fmt_q[1]}} & rt_q[32])
| ({(1){fp_fmt_q[2]}} & rt_q[3]);

assign guard_bit_rt_1 = 
  ({(1){fp_fmt_q[0]}} & rt_q[17])
| ({(1){fp_fmt_q[1]}} & rt_q[4]);

assign guard_bit_rt_2 = rt_q[31];
assign guard_bit_rt_3 = rt_q[3];


assign guard_bit_rt_m1_0 = 
  ({(1){fp_fmt_q[0]}} & rt_m1_q[43])
| ({(1){fp_fmt_q[1]}} & rt_m1_q[30])
| ({(1){fp_fmt_q[2]}} & rt_m1_q[1]);

assign guard_bit_rt_m1_1 = 
  ({(1){fp_fmt_q[0]}} & rt_m1_q[17])
| ({(1){fp_fmt_q[1]}} & rt_m1_q[4]);

assign guard_bit_rt_m1_2 = rt_m1_q[30];
assign guard_bit_rt_m1_3 = rt_m1_q[4];


assign rt_m1_inc_res_0 = (guard_bit_rt_0 == guard_bit_rt_m1_0) ? rt_inc_res        : {1'b0, rt_pre_inc};
assign rt_m1_inc_res_1 = (guard_bit_rt_1 == guard_bit_rt_m1_1) ? rt_inc_res[24: 1] : {1'b0, rt_pre_inc[23: 1]};
assign rt_m1_inc_res_2 = (guard_bit_rt_2 == guard_bit_rt_m1_2) ? rt_inc_res[38:28] : {1'b0, rt_pre_inc[37:28]};
assign rt_m1_inc_res_3 = (guard_bit_rt_3 == guard_bit_rt_m1_3) ? rt_inc_res[10: 0] : {1'b0, rt_pre_inc[ 9: 0]};


assign round_bit_rt_0 = 
  ({(1){fp_fmt_q[0]}} & rt_for_inc[44])
| ({(1){fp_fmt_q[1]}} & rt_for_inc[31])
| ({(1){fp_fmt_q[2]}} & rt_for_inc[2]);

assign round_bit_rt_1 = 
  ({(1){fp_fmt_q[0]}} & rt_for_inc[16])
| ({(1){fp_fmt_q[1]}} & rt_for_inc[3]);

assign round_bit_rt_2 = rt_for_inc[30];
assign round_bit_rt_3 = rt_for_inc[2];

assign sticky_bit_rt_0 = rem_is_not_zero_0;
assign sticky_bit_rt_1 = rem_is_not_zero_1;
assign sticky_bit_rt_2 = rem_is_not_zero_2;
assign sticky_bit_rt_3 = rem_is_not_zero_3;

assign inexact_rt_0 = round_bit_rt_0 | sticky_bit_rt_0;
assign inexact_rt_1 = round_bit_rt_1 | sticky_bit_rt_1;
assign inexact_rt_2 = round_bit_rt_2 | sticky_bit_rt_2;
assign inexact_rt_3 = round_bit_rt_3 | sticky_bit_rt_3;

assign inexact_0 = inexact_rt_0 | select_rt_m1_0;
assign inexact_1 = inexact_rt_1 | select_rt_m1_1;
assign inexact_2 = inexact_rt_2 | select_rt_m1_2;
assign inexact_3 = inexact_rt_3 | select_rt_m1_3;


assign rt_need_rup_0 = 
  ({rm_q == RM_RNE} &  round_bit_rt_0)
| ({rm_q == RM_RUP} & (round_bit_rt_0 | sticky_bit_rt_0))
| ({rm_q == RM_RMM} &  round_bit_rt_0);

assign rt_need_rup_1 = 
  ({rm_q == RM_RNE} &  round_bit_rt_1)
| ({rm_q == RM_RUP} & (round_bit_rt_1 | sticky_bit_rt_1))
| ({rm_q == RM_RMM} &  round_bit_rt_1);

assign rt_need_rup_2 = 
  ({rm_q == RM_RNE} &  round_bit_rt_2)
| ({rm_q == RM_RUP} & (round_bit_rt_2 | sticky_bit_rt_2))
| ({rm_q == RM_RMM} &  round_bit_rt_2);

assign rt_need_rup_3 = 
  ({rm_q == RM_RNE} &  round_bit_rt_3)
| ({rm_q == RM_RUP} & (round_bit_rt_3 | sticky_bit_rt_3))
| ({rm_q == RM_RMM} &  round_bit_rt_3);


assign round_bit_rt_m1_0 = 
  ({(1){fp_fmt_q[0]}} & rt_m1_q[42])
| ({(1){fp_fmt_q[1]}} & rt_m1_q[29])
| ({(1){fp_fmt_q[2]}} & rt_m1_q[0]);

assign round_bit_rt_m1_1 = 
  ({(1){fp_fmt_q[0]}} & rt_m1_q[16])
| ({(1){fp_fmt_q[1]}} & rt_m1_q[3]);

assign round_bit_rt_m1_2 = rt_m1_q[29];
assign round_bit_rt_m1_3 = rt_m1_q[3];


assign rt_m1_need_rup_0 = (rm_q == RM_RUP) | (((rm_q == RM_RNE) | (rm_q == RM_RMM)) & round_bit_rt_m1_0);
assign rt_m1_need_rup_1 = (rm_q == RM_RUP) | (((rm_q == RM_RNE) | (rm_q == RM_RMM)) & round_bit_rt_m1_1);
assign rt_m1_need_rup_2 = (rm_q == RM_RUP) | (((rm_q == RM_RNE) | (rm_q == RM_RMM)) & round_bit_rt_m1_2);
assign rt_m1_need_rup_3 = (rm_q == RM_RUP) | (((rm_q == RM_RNE) | (rm_q == RM_RMM)) & round_bit_rt_m1_3);


assign rt_rounded_0 = rt_need_rup_0 ? rt_inc_res        : {1'b0, rt_pre_inc};
assign rt_rounded_1 = rt_need_rup_1 ? rt_inc_res[24: 1] : {1'b0, rt_pre_inc[23: 1]};
assign rt_rounded_2 = rt_need_rup_2 ? rt_inc_res[38:28] : {1'b0, rt_pre_inc[37:28]};
assign rt_rounded_3 = rt_need_rup_3 ? rt_inc_res[10: 0] : {1'b0, rt_pre_inc[ 9: 0]};


assign rt_m1_rounded_0 = rt_m1_need_rup_0 ? rt_m1_inc_res_0 : {1'b0, rt_m1_pre_inc_0};
assign rt_m1_rounded_1 = rt_m1_need_rup_1 ? rt_m1_inc_res_1 : {1'b0, rt_m1_pre_inc_1};
assign rt_m1_rounded_2 = rt_m1_need_rup_2 ? rt_m1_inc_res_2 : {1'b0, rt_m1_pre_inc_2};
assign rt_m1_rounded_3 = rt_m1_need_rup_3 ? rt_m1_inc_res_3 : {1'b0, rt_m1_pre_inc_3};


assign frac_rounded_0 = select_rt_m1_0 ? rt_m1_rounded_0 : rt_rounded_0;
assign frac_rounded_1 = select_rt_m1_1 ? rt_m1_rounded_1 : rt_rounded_1;
assign frac_rounded_2 = select_rt_m1_2 ? rt_m1_rounded_2 : rt_rounded_2;
assign frac_rounded_3 = select_rt_m1_3 ? rt_m1_rounded_3 : rt_rounded_3;


assign carry_after_round_0 = frac_rounded_0[52];
assign carry_after_round_1 = frac_rounded_1[23];
assign carry_after_round_2 = frac_rounded_2[10];
assign carry_after_round_3 = frac_rounded_3[10];


assign exp_rounded_0 = carry_after_round_0 ? (out_exp_0_q + 11'd1) : out_exp_0_q;
assign exp_rounded_1 = carry_after_round_1 ? (out_exp_1_q +  8'd1) : out_exp_1_q;
assign exp_rounded_2 = carry_after_round_2 ? (out_exp_2_q +  5'd1) : out_exp_2_q;
assign exp_rounded_3 = carry_after_round_3 ? (out_exp_3_q +  5'd1) : out_exp_3_q;


assign f16_exp_res_0 = 
(res_is_nan_0_q | res_is_inf_0_q) ? {(5){1'b1}} : 
res_is_exact_zero_0_q ? 5'b0 : 
exp_rounded_0[4:0];

assign f16_exp_res_1 = 
(res_is_nan_1_q | res_is_inf_1_q) ? {(5){1'b1}} : 
res_is_exact_zero_1_q ? 5'b0 : 
exp_rounded_1[4:0];

assign f16_exp_res_2 = 
(res_is_nan_2_q | res_is_inf_2_q) ? {(5){1'b1}} : 
res_is_exact_zero_2_q ? 5'b0 : 
exp_rounded_2;

assign f16_exp_res_3 = 
(res_is_nan_3_q | res_is_inf_3_q) ? {(5){1'b1}} : 
res_is_exact_zero_3_q ? 5'b0 : 
exp_rounded_3;

assign f32_exp_res_0 = 
(res_is_nan_0_q | res_is_inf_0_q) ? {(8){1'b1}} : 
res_is_exact_zero_0_q ? 8'b0 : 
exp_rounded_0[7:0];

assign f32_exp_res_1 = 
(res_is_nan_1_q | res_is_inf_1_q) ? {(8){1'b1}} : 
res_is_exact_zero_1_q ? 8'b0 : 
exp_rounded_1;

assign f64_exp_res_0 = 
(res_is_nan_0_q | res_is_inf_0_q) ? {(11){1'b1}} : 
res_is_exact_zero_0_q ? 11'b0 : 
exp_rounded_0;

assign f16_frac_res_0 = 
res_is_nan_0_q ? {1'b1, 9'b0} : 
(res_is_inf_0_q | res_is_exact_zero_0_q) ? 10'b0 : 
frac_rounded_0[51 -: 10];

assign f16_frac_res_1 = 
res_is_nan_1_q ? {1'b1, 9'b0} : 
(res_is_inf_1_q | res_is_exact_zero_1_q) ? 10'b0 : 
frac_rounded_1[22 -: 10];

assign f16_frac_res_2 = 
res_is_nan_2_q ? {1'b1, 9'b0} : 
(res_is_inf_2_q | res_is_exact_zero_2_q) ? 10'b0 : 
frac_rounded_2[0 +: 10];

assign f16_frac_res_3 = 
res_is_nan_3_q ? {1'b1, 9'b0} : 
(res_is_inf_3_q | res_is_exact_zero_3_q) ? 10'b0 : 
frac_rounded_3[0 +: 10];

assign f32_frac_res_0 = 
res_is_nan_0_q ? {1'b1, 22'b0} : 
(res_is_inf_0_q | res_is_exact_zero_0_q) ? 23'b0 : 
frac_rounded_0[51 -: 23];

assign f32_frac_res_1 = 
res_is_nan_1_q ? {1'b1, 22'b0} : 
(res_is_inf_1_q | res_is_exact_zero_1_q) ? 23'b0 : 
frac_rounded_1[0 +: 23];

assign f64_frac_res_0 = 
res_is_nan_0_q ? {1'b1, 51'b0} : 
(res_is_inf_0_q | res_is_exact_zero_0_q) ? 52'b0 : 
frac_rounded_0[0 +: 52];

assign f16_res_0 = {out_sign_0_q, f16_exp_res_0, f16_frac_res_0};
assign f16_res_1 = {out_sign_1_q, f16_exp_res_1, f16_frac_res_1};
assign f16_res_2 = {out_sign_2_q, f16_exp_res_2, f16_frac_res_2};
assign f16_res_3 = {out_sign_3_q, f16_exp_res_3, f16_frac_res_3};

assign f32_res_0 = {out_sign_0_q, f32_exp_res_0, f32_frac_res_0};
assign f32_res_1 = {out_sign_1_q, f32_exp_res_1, f32_frac_res_1};

assign f64_res_0 = {out_sign_0_q, f64_exp_res_0, f64_frac_res_0};

assign fpsqrt_res_o = 
  ({(64){fp_fmt_q[0]}} & {f16_res_0, f16_res_2, f16_res_1, f16_res_3})
| ({(64){fp_fmt_q[1]}} & {f32_res_0, f32_res_1})
| ({(64){fp_fmt_q[2]}} & f64_res_0);


assign fflags_invalid_operation_0 = op_invalid_0_q;
assign fflags_div_by_zero_0 = '0;
assign fflags_overflow_0 = '0;
assign fflags_underflow_0 = '0;
assign fflags_inexact_0 = inexact_0 & ~res_is_nan_0_q & ~res_is_exact_zero_0_q;

assign fflags_invalid_operation_1 = op_invalid_1_q;
assign fflags_div_by_zero_1 = '0;
assign fflags_overflow_1 = '0;
assign fflags_underflow_1 = '0;
assign fflags_inexact_1 = inexact_1 & ~res_is_nan_1_q & ~res_is_exact_zero_1_q;

assign fflags_invalid_operation_2 = op_invalid_2_q;
assign fflags_div_by_zero_2 = '0;
assign fflags_overflow_2 = '0;
assign fflags_underflow_2 = '0;
assign fflags_inexact_2 = inexact_2 & ~res_is_nan_2_q & ~res_is_exact_zero_2_q;

assign fflags_invalid_operation_3 = op_invalid_3_q;
assign fflags_div_by_zero_3 = '0;
assign fflags_overflow_3 = '0;
assign fflags_underflow_3 = '0;
assign fflags_inexact_3 = inexact_3 & ~res_is_nan_3_q & ~res_is_exact_zero_3_q;


assign f16_fflags_invalid_operation = fflags_invalid_operation_3 | (
	v_mode_q ? (
	  fflags_invalid_operation_0
	| fflags_invalid_operation_1
	| fflags_invalid_operation_2
	) : 1'b0
);
assign f32_fflags_invalid_operation = fflags_invalid_operation_1 | (v_mode_q ? fflags_invalid_operation_0 : 1'b0);
assign f64_fflags_invalid_operation = fflags_invalid_operation_0;


assign f16_fflags_div_by_zero = fflags_div_by_zero_3 | (
	v_mode_q ? (
	  fflags_div_by_zero_0
	| fflags_div_by_zero_1
	| fflags_div_by_zero_2
	) : 1'b0
);
assign f32_fflags_div_by_zero = fflags_div_by_zero_1 | (v_mode_q ? fflags_div_by_zero_0 : 1'b0);
assign f64_fflags_div_by_zero = fflags_div_by_zero_0;


assign f16_fflags_overflow = fflags_overflow_3 | (
	v_mode_q ? (
	  fflags_overflow_0
	| fflags_overflow_1
	| fflags_overflow_2
	) : 1'b0
);
assign f32_fflags_overflow = fflags_overflow_1 | (v_mode_q ? fflags_overflow_0 : 1'b0);
assign f64_fflags_overflow = fflags_overflow_0;


assign f16_fflags_underflow = fflags_underflow_3 | (
	v_mode_q ? (
	  fflags_underflow_0
	| fflags_underflow_1
	| fflags_underflow_2
	) : 1'b0
);
assign f32_fflags_underflow = fflags_underflow_1 | (v_mode_q ? fflags_underflow_0 : 1'b0);
assign f64_fflags_underflow = fflags_underflow_0;

assign f16_fflags_inexact = fflags_inexact_3 | (
	v_mode_q ? (
	  fflags_inexact_0
	| fflags_inexact_1
	| fflags_inexact_2
	) : 1'b0
);
assign f32_fflags_inexact = fflags_inexact_1 | (v_mode_q ? fflags_inexact_0 : 1'b0);
assign f64_fflags_inexact = fflags_inexact_0;


assign fflags_o = {
	  ({(1){fp_fmt_q[0]}} & f16_fflags_invalid_operation)
	| ({(1){fp_fmt_q[1]}} & f32_fflags_invalid_operation)
	| ({(1){fp_fmt_q[2]}} & f64_fflags_invalid_operation),
	  ({(1){fp_fmt_q[0]}} & f16_fflags_div_by_zero)
	| ({(1){fp_fmt_q[1]}} & f32_fflags_div_by_zero)
	| ({(1){fp_fmt_q[2]}} & f64_fflags_div_by_zero),
	  ({(1){fp_fmt_q[0]}} & f16_fflags_overflow)
	| ({(1){fp_fmt_q[1]}} & f32_fflags_overflow)
	| ({(1){fp_fmt_q[2]}} & f64_fflags_overflow),
	  ({(1){fp_fmt_q[0]}} & f16_fflags_underflow)
	| ({(1){fp_fmt_q[1]}} & f32_fflags_underflow)
	| ({(1){fp_fmt_q[2]}} & f64_fflags_underflow),
	  ({(1){fp_fmt_q[0]}} & f16_fflags_inexact)
	| ({(1){fp_fmt_q[1]}} & f32_fflags_inexact)
	| ({(1){fp_fmt_q[2]}} & f64_fflags_inexact)
};



endmodule

