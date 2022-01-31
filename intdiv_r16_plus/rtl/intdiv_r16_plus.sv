// ========================================================================================================
// File Name			: intdiv_r16_plus.sv
// Author				: HYF
// How to Contact		: hyf_sysu@qq.com
// Created Time    		: 2022-01-26 09:23:42
// Last Modified Time   : 2022-01-31 09:31:03
// ========================================================================================================
// Description	:
// This is a High Performance Radix-16 SRT Integer Divider.
// Please look at reference paper to understand the alogorithm.
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

module intdiv_r16_plus #(
	// Put some parameters here, which can be changed by other modules
	// D_W = DATA_WIDTH
	// Only 32/64 has been tested yet..
	parameter D_W = 32
)(
	input  logic start_valid_i,
	output logic start_ready_o,
	input  logic flush_i,
	input  logic signed_op_i,
	input  logic [D_W-1:0] dividend_i,
	input  logic [D_W-1:0] divisor_i,

	output logic finish_valid_o,
	input  logic finish_ready_i,
	output logic [D_W-1:0] quotient_o,
	output logic [D_W-1:0] remainder_o,
	output logic divisor_is_zero_o,

	input  logic clk,
	input  logic rst_n
);

// ================================================================================================================================================
// (local) parameters begin

localparam FSM_W = 4;
localparam FSM_PRE_0 = (1 << 0);
localparam FSM_PRE_1 = (1 << 1);
localparam FSM_ITER  = (1 << 2);
localparam FSM_POST  = (1 << 3);
localparam FSM_PRE_0_BIT = 0;
localparam FSM_PRE_1_BIT = 1;
localparam FSM_ITER_BIT  = 2;
localparam FSM_POST_BIT  = 3;

// How many bits do we need to express the Leading Zero Count of the data ?
localparam LZC_W = (D_W == 64) ? 6 : 5;

// 1-bit in front of the MSB of rem -> Sign.
// 2-bit after the LSB of rem -> Used in Retiming Design.
// 3-bit after the LSB of rem -> Used for Align operation.
localparam REM_W = 1 + D_W + 2 + 3;

localparam QUO_DIG_W = 5;
localparam QUO_DIG_NEG_2 = (1 << 4);
localparam QUO_DIG_NEG_1 = (1 << 3);
localparam QUO_DIG_NEG_0 = (1 << 2);
localparam QUO_DIG_POS_1 = (1 << 1);
localparam QUO_DIG_POS_2 = (1 << 0);

localparam QUO_DIG_NEG_2_BIT = 4;
localparam QUO_DIG_NEG_1_BIT = 3;
localparam QUO_DIG_NEG_0_BIT = 2;
localparam QUO_DIG_POS_1_BIT = 1;
localparam QUO_DIG_POS_2_BIT = 0;

// (local) parameters end
// ================================================================================================================================================

// ================================================================================================================================================
// signals begin

// Some abbreviations:
// quo = quotient
// rem = remainder
// rem_s = rem_sum
// rem_c = rem_carry
// ext = extended
// N = dividend
// D = divisor
// nr = non_redundant

logic start_handshaked;
logic [FSM_W-1:0] fsm_d;
logic [FSM_W-1:0] fsm_q;
logic early_finish;

// In the design, when(D_W == 64), the MAX iter we need is 16, so a 4-bit reg is enough.
logic iter_num_en;
logic [4-1:0] iter_num_d;
logic [4-1:0] iter_num_q;
logic final_iter;

logic quo_sign_en;
logic quo_sign_d;
logic quo_sign_q;
logic rem_sign_en;
logic rem_sign_d;
logic rem_sign_q;

logic [D_W-1:0] negation_adder_in  [1:0];
logic [D_W-1:0] negation_adder_res [1:0];

logic N_sign;
logic D_sign;
logic [D_W-1:0] N_abs;
logic [D_W-1:0] D_abs;
logic [D_W-1:0] N_to_lzc;
logic [D_W-1:0] D_to_lzc;
// 1-extra bit to express whether N/D is ZERO
logic [(LZC_W+1)-1:0] N_lzc;
logic [(LZC_W+1)-1:0] D_lzc;
logic [(LZC_W+1)-1:0] lzc_diff;
logic [D_W-1:0] N_abs_l_shifted_s5_to_s2;
logic [D_W-1:0] D_abs_l_shifted_s5_to_s2;
logic [D_W-1:0] N_abs_l_shifted_s5_to_s2_pre_1;
logic [D_W-1:0] D_abs_l_shifted_s5_to_s2_pre_1;
logic [D_W-1:0] N_abs_l_shifted;
logic [D_W-1:0] D_abs_l_shifted;

logic [3-1:0] N_lzc_pre_1;
logic [(LZC_W+1)-1:0] D_lzc_pre_1;
logic [(LZC_W+1)-1:0] lzc_diff_pre_1;
logic [(LZC_W+1)-1:0] lzc_diff_pre_1_p1;
logic [(LZC_W+1)-1:0] correct_lzc_diff;

logic N_too_small;
logic D_is_zero;
logic D_is_one;
logic D_is_neg_power_of_2;

logic [D_W-1:0] N_abs_pre_1;
logic [LZC_W-1:0] N_abs_r_shift_num;
logic [(2 * D_W - 2)-1:0] N_abs_r_shifted_raw;
logic [D_W-1:0] N_abs_r_shifted_msbs;
logic [(D_W-2)-1:0] N_abs_r_shifted_lsbs;
logic [(D_W-1)-1:0] D_inversed_mask;

// Width for rem_r_aligned: 1 + D_W + 2
// To save 1 cycle for rem calculation, we use an extra data path, which is updated in parallel with the common data path.
logic rem_r_aligned_s_en;
logic [(D_W+3)-1:0] rem_r_aligned_s_d;
logic [(D_W+3)-1:0] rem_r_aligned_s_q;
logic rem_r_aligned_c_en;
logic [(D_W+3)-1:0] rem_r_aligned_c_d;
logic [(D_W+3)-1:0] rem_r_aligned_c_q;
logic [(D_W+3)-1:0] rem_r_aligned_s_iter_init;
logic [(D_W+3)-1:0] rem_r_aligned_s_iter_init_normal;
logic [(D_W+3)-1:0] nxt_rem_r_aligned_s [2-1:0];
logic [(D_W+3)-1:0] nxt_rem_r_aligned_c [2-1:0];
logic [(D_W+3)-1:0] D_abs_ext;
logic [(D_W+3)-1:0] D_abs_to_csa [2-1:0];

// Since we only use ITER step for "D >= 2'b10", the MAX r_shift_num for abs(N) is "D_W - 2".
logic N_r_shifted_lsbs_en;
logic [(D_W-2)-1:0] N_r_shifted_lsbs_d;
logic [(D_W-2)-1:0] N_r_shifted_lsbs_q;
logic [(D_W-2)-1:0] N_r_shifted_lsbs_iter_init;

logic rem_s_en;
logic [REM_W-1:0] rem_s_d;
logic [REM_W-1:0] rem_s_q;
logic rem_c_en;
logic [REM_W-1:0] rem_c_d;
logic [REM_W-1:0] rem_c_q;
logic [REM_W-1:0] rem_s_iter_init;
logic [REM_W-1:0] nxt_rem_s [2-1:0];
logic [REM_W-1:0] nxt_rem_c [2-1:0];

// After normalization, the MSB of "normalized_D" must be 1 -> We don't need to store it
logic normalized_D_en;
logic [(D_W-1)-1:0] normalized_D_d;
logic [(D_W-1)-1:0] normalized_D_q;
logic D_abs_en;
logic [D_W-1:0] D_abs_d;
logic [D_W-1:0] D_abs_q;

logic D_is_zero_en;
logic D_is_zero_d;
logic D_is_zero_q;
logic D_is_special_en;
logic D_is_special_d;
logic D_is_special_q;

logic prev_quo_dig_en;
logic [QUO_DIG_W-1:0] prev_quo_dig_d;
logic [QUO_DIG_W-1:0] prev_quo_dig_q;
logic [QUO_DIG_W-1:0] quo_dig_1st;
logic [QUO_DIG_W-1:0] nxt_quo_dig [2-1:0];

logic quo_iter_en;
logic [D_W-1:0] quo_iter_d;
logic [D_W-1:0] quo_iter_q;
logic quo_m1_iter_en;
logic [D_W-1:0] quo_m1_iter_d;
logic [D_W-1:0] quo_m1_iter_q;
logic [D_W-1:0] nxt_quo_iter [2-1:0];
logic [D_W-1:0] nxt_quo_m1_iter [2-1:0];
logic [D_W-1:0] quo_iter_init;

logic [7-1:0] m_neg_1_init;
logic [7-1:0] m_neg_0_init;
logic [7-1:0] m_pos_1_init;
logic [7-1:0] m_pos_2_init;

logic [5-1:0] m_pos_1_for_1st_quo;
logic [5-1:0] m_pos_2_for_1st_quo;
logic [5-1:0] rem_trunc_1_4_for_1st_quo;

// {m_neg_1[6], m_neg_1[0}} = 00 -> A 5-bit reg is enough
logic m_neg_1_en;
logic [5-1:0] m_neg_1_d;
logic [5-1:0] m_neg_1_q;
// In common cases, {m_neg_0[6:4], m_neg_0[0}} = 0000 -> A 3-bit reg is enough
logic m_neg_0_en;
logic [3-1:0] m_neg_0_d;
logic [3-1:0] m_neg_0_q;
// In common cases, {m_pos_1[6:3], m_pos_1[0}} = 11110 -> A 2-bit reg is enough
logic m_pos_1_en;
logic [2-1:0] m_pos_1_d;
logic [2-1:0] m_pos_1_q;
// {m_pos_2[6], m_pos_2[0}} = 10 -> A 5-bit reg is enough
logic m_pos_2_en;
logic [5-1:0] m_pos_2_d;
logic [5-1:0] m_pos_2_q;
logic m_neg_0_pos_1_lsb_en;
logic m_neg_0_pos_1_lsb_d;
logic m_neg_0_pos_1_lsb_q;

logic [(D_W+3)-1:0] nr_rem_r_aligned;
logic [(D_W+3)-1:0] nr_rem_r_aligned_plus_D;
logic [(D_W+1)-1:0] rem_r_aligned_xor;
logic [(D_W+1)-1:0] rem_r_aligned_or;
logic nr_rem_r_aligned_is_not_zero;
logic select_quo_m1;
logic [D_W-1:0] quo_sign_adjusted;
logic [D_W-1:0] quo_m1_sign_adjusted;

// signals end
// ================================================================================================================================================

assign start_handshaked = start_valid_i & start_ready_o;
assign start_ready_o = fsm_q[FSM_PRE_0_BIT];
assign finish_valid_o = fsm_q[FSM_POST_BIT];
// ================================================================================================================================================
// FSM Ctrl Logic
// ================================================================================================================================================
always_comb begin
	unique case(fsm_q)
		FSM_PRE_0:
			fsm_d = start_valid_i ? FSM_PRE_1 : FSM_PRE_0;
		FSM_PRE_1:
			fsm_d = early_finish ? FSM_POST : FSM_ITER;
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

// The only regs that need rst_n.
always_ff @(posedge clk or negedge rst_n) begin
	if(~rst_n)
		fsm_q <= FSM_PRE_0;
	else
		fsm_q <= fsm_d;
end

// ================================================================================================================================================
// The negation_adders are used in pre_0 and post_0
// ================================================================================================================================================
assign negation_adder_in [0] = fsm_q[FSM_PRE_0_BIT] ? dividend_i : quo_iter_q;
assign negation_adder_in [1] = fsm_q[FSM_PRE_0_BIT] ? divisor_i  : quo_m1_iter_q;
assign negation_adder_res[0] = -negation_adder_in[0];
assign negation_adder_res[1] = -negation_adder_in[1];

// ================================================================================================================================================
// pre_0
// ================================================================================================================================================
assign N_sign = signed_op_i & dividend_i[D_W-1];
assign D_sign = signed_op_i & divisor_i[D_W-1];
assign N_abs = N_sign ? negation_adder_res[0] : dividend_i;
assign D_abs = D_sign ? negation_adder_res[1] : divisor_i;

// Here we only use the inversed value to make LZC faster, which will lead to wrong result if the operand is a negative power of 2.
// Don't worry, we will make correction in pre_1.
// If "N = -1 = {(D_W){1'b1}}, then we will have "~N = 0", which will lead to "N_lzc = {(LZC_W + 1){1'b1}}".
// So it is hard to tell the difference between "N = -1" and "N = 0" by only using "N_lzc".
// To avoid that, we just make "N_to_lzc[0] = 1" when "N < 0", so we can get the correct "lzc" for "N = -1"
// The same operation should also be applied to D
assign N_to_lzc = N_sign ? {~dividend_i[D_W-1:1], 1'b1} : dividend_i;
assign D_to_lzc = D_sign ? {~divisor_i [D_W-1:1], 1'b1} : divisor_i;
lzc #(
	.WIDTH(D_W),
	// 0: trailing zero.
	// 1: leading zero.
	.MODE(1'b1)
) u_lzc_for_N (
	.in_i(N_to_lzc),
	.cnt_o(N_lzc[LZC_W-1:0]),
	.empty_o(N_lzc[LZC_W])
);
lzc #(
	.WIDTH(D_W),
	// 0: trailing zero.
	// 1: leading zero.
	.MODE(1'b1)
) u_lzc_for_D (
	.in_i(D_to_lzc),
	.cnt_o(D_lzc[LZC_W-1:0]),
	.empty_o(D_lzc[LZC_W])
);
// ATTENTION: We will fix the value in pre_1.
assign lzc_diff[LZC_W:0] = {1'b0, D_lzc[LZC_W-1:0]} - {1'b0, N_lzc[LZC_W-1:0]};

// When(D_W == 64), a 6-stage barrel shifter is needed, and we only do stage[5:2] in pre_0
assign N_abs_l_shifted_s5_to_s2[D_W-1:0] = N_abs << {(D_W == 64) ? N_lzc[5] : 1'b0, N_lzc[4:2], 2'b00};
assign D_abs_l_shifted_s5_to_s2[D_W-1:0] = D_abs << {(D_W == 64) ? D_lzc[5] : 1'b0, D_lzc[4:2], 2'b00};

// ================================================================================================================================================
// pre_1
// ================================================================================================================================================

// N_lzc_pre_1 = {N_lzc[LZC_W], N_lzc[1:0]}
assign N_lzc_pre_1 = rem_s_q[16 -: 3];
assign D_lzc_pre_1 = rem_s_q[7 +: (LZC_W+1)];
assign lzc_diff_pre_1 = rem_s_q[0 +: (LZC_W+1)];

assign N_abs_l_shifted_s5_to_s2_pre_1 = quo_iter_q;
assign D_abs_l_shifted_s5_to_s2_pre_1 = {D_is_special_q, normalized_D_q};
// Do the remaining stage[1:0] l_shift for N/D in pre_1
// Attention: N_abs_l_shifted/D_abs_l_shifted[MSB] could possibly be 0 !!!
assign N_abs_l_shifted = N_abs_l_shifted_s5_to_s2_pre_1 << N_lzc_pre_1[1:0];
assign D_abs_l_shifted = D_abs_l_shifted_s5_to_s2_pre_1 << D_lzc_pre_1[1:0];

// "lzc_diff_pre_1" is not "correct_lzc_diff" when (Either N or D is a negative power of 2).
// Since we would regard "D < 0, and D is the power of 2" as a special case, here we only need to detect whether (N is a negative power of 2), in order to
// get "correct_lzc_diff".
assign lzc_diff_pre_1_p1[LZC_W:0] = lzc_diff_pre_1 + {{(LZC_W){1'b0}}, 1'b1};
assign correct_lzc_diff[LZC_W:0] = N_abs_l_shifted[D_W-1] ? lzc_diff_pre_1 : lzc_diff_pre_1_p1;

// ================================================================================================================================================
// Handling special cases
// ================================================================================================================================================
// 1. D is special.
// 1) D_is_zero:
// QUO = {(D_W){1'b1}}, REM = N
// 2) D_is_one:
// QUO = N, REM = 0
// 3) D_is_neg_power_of_2:
// QUO = N_r_shifted, REM = {1'b0, N[D_W-2:0] & D_inversed_mask[D_W-2:0]}
// Consider I32, N = 00001111000011111110101010100111, D = -(2 ^ 17) = 11111111111111100000000000000000
// abs(correct_QUO) = N / (2 ^ 17) = 00000000000000000000011110000111, REM = 00000000000000011110101010100111
// abs(D) = 00000000000000100000000000000000, ~D[D_W-1:0] = 00000000000000011111111111111111, we would have:
// D_lzc = lzc(~D[D_W-1:0]) = 15
// Now to get the correct QUO, we should do:
// QUO = N >> (D_W - D_lzc)
// D_W - D_lzc = ~D_lzc + 1
// QUO = N >> (D_W - D_lzc) = (N >> ~D_lzc) >> 1
// REM = {1'b0, N[D_W-2:0] & D_inversed_mask[D_W-2:0]}

// 2. D is not special, but N is too small. That means we must have "abs(N) < abs(D)":
// QUO = 0, REM = N;
assign N_too_small = correct_lzc_diff[LZC_W];
// {D_is_zero, D_is_one, D_is_neg_power_of_2} must be one-hot
assign D_is_zero = D_lzc_pre_1[LZC_W];
// If(correct_lzc_diff == (D_W - 1)), it means abs(D) = 1, and we can directly get "QUO = N, REM = 0"
assign D_is_one = ~D_lzc_pre_1[LZC_W] & (D_lzc_pre_1[LZC_W-1:0] == {(LZC_W){1'b1}}) & D_abs_q[0];
// Attention: This signal doesn't include "D = -1" 
assign D_is_neg_power_of_2 = ~D_lzc_pre_1[LZC_W] & ~D_abs_l_shifted[D_W-1];
assign early_finish = N_too_small | D_is_zero | D_is_one | D_is_neg_power_of_2;

// ================================================================================================================================================
// r_shifter to make the MSB of N/D in the same position
// ================================================================================================================================================
// To make this r_shifter faster, try to not use "correct_lzc_diff" (Because its delay is "(6/7-bit FA) + (2-to-1 MUX)")
assign N_abs_pre_1 = quo_m1_iter_q;
// When we need to use the value of lsbs of "N_abs_r_shifted", the MAX_r_shift_num is "D_W - 2"
// So a (D_W + D_W - 2)-bit" shifter is enough.
assign N_abs_r_shift_num = D_is_neg_power_of_2 ? ~D_lzc_pre_1[LZC_W-1:0] : (lzc_diff_pre_1[LZC_W] ? '0 : lzc_diff_pre_1[LZC_W-1:0]);
assign N_abs_r_shifted_raw = {N_abs_pre_1, {(D_W - 2){1'b0}}} >> N_abs_r_shift_num;

// Only consider when (N is not too small), 
// If((~N_abs_l_shifted[D_W-1] & lzc_diff_pre_1[LZC_W]) == 1), it means we must have "lzc_diff_pre_1 == -1" and "correct_lzc_diff = 0"
// Therefore, the MSB of "N_abs" and "D_abs" are in the same position. So actually we don't need to do any r_shift for N_abs -> This has already been done when we 
// choose the value of "N_abs_r_shift_num"
assign N_abs_r_shifted_msbs = (D_is_neg_power_of_2 | (~N_abs_l_shifted[D_W-1] & ~lzc_diff_pre_1[LZC_W])) ? 
{1'b0, N_abs_r_shifted_raw[D_W-1 +: (D_W-1)]} : N_abs_r_shifted_raw[D_W-2 +: D_W];

// When(N_is_neg_power_of_2), the "LSBs" must be ALL_ZERO -> The 1-bit r_shift is not needed.
// When(D_is_neg_power_of_2), the "LSBs" is not used -> The 1-bit r_shift is not needed.
assign N_abs_r_shifted_lsbs = N_abs_r_shifted_raw[0 +: D_W-2];

// iter_num = ceil((lzc_diff + 2) / 4);
// Take "D_W = 32" as an example, lzc_diff = 
//  0 -> iter_num = 1, r_shift_num_for_align = 2;
//  1 -> iter_num = 1, r_shift_num_for_align = 1;
//  2 -> iter_num = 1, r_shift_num_for_align = 0;
//  3 -> iter_num = 2, r_shift_num_for_align = 3;
//  4 -> iter_num = 2, r_shift_num_for_align = 2;
//  5 -> iter_num = 2, r_shift_num_for_align = 1;
//  6 -> iter_num = 2, r_shift_num_for_align = 0;
// ...
// 28 -> iter_num = 8, r_shift_num_for_align = 2;
// 29 -> iter_num = 8, r_shift_num_for_align = 1;
// 30 -> iter_num = 8, r_shift_num_for_align = 0;
// 31 -> This is regarded as a special case.
// Here we use "correct_lzc_diff[1:0]" to express "r_shift_num_for_align"
assign rem_s_iter_init = {
	1'b0,
	2'b0,
	  ({(D_W + 3){correct_lzc_diff[1:0] == 2'b00}} & {2'b0, {1'b1, N_abs_l_shifted[D_W-2:0]}, 1'b0})
	| ({(D_W + 3){correct_lzc_diff[1:0] == 2'b01}} & {1'b0, {1'b1, N_abs_l_shifted[D_W-2:0]}, 2'b0})
	| ({(D_W + 3){correct_lzc_diff[1:0] == 2'b10}} & {      {1'b1, N_abs_l_shifted[D_W-2:0]}, 3'b0})
	| ({(D_W + 3){correct_lzc_diff[1:0] == 2'b11}} & {3'b0, {1'b1, N_abs_l_shifted[D_W-2:0]}      })
};

assign rem_r_aligned_s_iter_init_normal = {
	1'b0,
	2'b0,
	  ({(D_W){correct_lzc_diff[1:0] == 2'b00}} & {2'b0, N_abs_r_shifted_msbs[D_W-1:2]})
	| ({(D_W){correct_lzc_diff[1:0] == 2'b01}} & {1'b0, N_abs_r_shifted_msbs[D_W-1:1]})
	| ({(D_W){correct_lzc_diff[1:0] == 2'b10}} & {      N_abs_r_shifted_msbs[D_W-1:0]})
	| ({(D_W){correct_lzc_diff[1:0] == 2'b11}} & {3'b0, N_abs_r_shifted_msbs[D_W-1:3]})
};

assign D_inversed_mask = {D_is_zero_q, N_r_shifted_lsbs_q};
assign rem_r_aligned_s_iter_init = 
(D_is_zero | N_too_small) ? {1'b0, N_abs_pre_1, 2'b0} : 
D_is_neg_power_of_2 ? {1'b0, 1'b0, N_abs_pre_1[D_W-2:0] & D_inversed_mask, 2'b0} : 
D_is_one ? '0 : 
rem_r_aligned_s_iter_init_normal;

assign N_r_shifted_lsbs_iter_init =
  ({(D_W - 2){correct_lzc_diff[1:0] == 2'b00}} & {N_abs_r_shifted_msbs[1:0], N_abs_r_shifted_lsbs[(D_W-2)-1:2]})
| ({(D_W - 2){correct_lzc_diff[1:0] == 2'b01}} & {N_abs_r_shifted_msbs[0:0], N_abs_r_shifted_lsbs[(D_W-2)-1:1]})
| ({(D_W - 2){correct_lzc_diff[1:0] == 2'b10}} & {                           N_abs_r_shifted_lsbs[(D_W-2)-1:0]})
| ({(D_W - 2){correct_lzc_diff[1:0] == 2'b11}} & {N_abs_r_shifted_msbs[2:0], N_abs_r_shifted_lsbs[(D_W-2)-1:3]});


assign quo_iter_init = D_is_zero ? {(D_W){1'b1}} : (
	  ({(D_W){D_is_one}} & N_abs_pre_1)
	| ({(D_W){D_is_neg_power_of_2}} & N_abs_r_shifted_msbs)
);

r4_qds_constants_generator
u_r4_qds_constants_generator (
	.D_msbs_i(D_abs_l_shifted[D_W-2 -: 3]),
	.m_neg_1_o(m_neg_1_init),
	.m_neg_0_o(m_neg_0_init),
	.m_pos_1_o(m_pos_1_init),
	.m_pos_2_o(m_pos_2_init)
);
// At present, REM must be positive, so we only need to compare it with m[+1]/m[+2] -> A (3 or 4-bit) comparator is needed.
// For rem_s_iter_init, the decimal point is between [REM_W-1] and [REM_W-2], and we should use 
// "(4 * rem_s_iter_init)_trunc_1_4" to choose the 1st quo.
assign rem_trunc_1_4_for_1st_quo = {1'b0, rem_s_iter_init[REM_W-4 -: 4]};
// For m[+1], the decimal point is between [4], [3]
// 000: m[+1] = +4 = 0_0100
// 001: m[+1] = +4 = 0_0100
// 010: m[+1] = +4 = 0_0100
// 011: m[+1] = +4 = 0_0100
// 100: m[+1] = +6 = 0_0110
// 101: m[+1] = +6 = 0_0110
// 110: m[+1] = +6 = 0_0110
// 111: m[+1] = +8 = 0_1000
// For m[+1], a 3-bit comparator is enough
assign m_pos_1_for_1st_quo = 
  ({(5){D_abs_l_shifted[D_W-2 -: 3] == 3'd0}} & 5'b0_0100)
| ({(5){D_abs_l_shifted[D_W-2 -: 3] == 3'd1}} & 5'b0_0100)
| ({(5){D_abs_l_shifted[D_W-2 -: 3] == 3'd2}} & 5'b0_0100)
| ({(5){D_abs_l_shifted[D_W-2 -: 3] == 3'd3}} & 5'b0_0100)
| ({(5){D_abs_l_shifted[D_W-2 -: 3] == 3'd4}} & 5'b0_0110)
| ({(5){D_abs_l_shifted[D_W-2 -: 3] == 3'd5}} & 5'b0_0110)
| ({(5){D_abs_l_shifted[D_W-2 -: 3] == 3'd6}} & 5'b0_0110)
| ({(5){D_abs_l_shifted[D_W-2 -: 3] == 3'd7}} & 5'b0_1000);
// ATTENTION: The m[+2] used here is different with m[+2] used in "r4_qds_constants_generator", when (normalized_D[D_W-2 -: 3] == 3'd2)
// Since using m[+2] = 16, when (normalized_D[D_W-2 -: 3] == 3'd2), will not lead to any mistakes, we could reduce the width of the comparator by 1.
// For m[+2], the decimal point is between [5], [4]
// 000: m[+2] = +12 = 0_1100
// 001: m[+2] = +14 = 0_1110
// 010: m[+2] = +16 = 1_0000
// 011: m[+2] = +16 = 1_0000
// 100: m[+2] = +18 = 1_0010
// 101: m[+2] = +20 = 1_0100
// 110: m[+2] = +22 = 1_0110
// 111: m[+2] = +22 = 1_0110
// For m[+2], a 4-bit comparator is enough
assign m_pos_2_for_1st_quo = 
  ({(5){D_abs_l_shifted[D_W-2 -: 3] == 3'd0}} & 5'b0_1100)
| ({(5){D_abs_l_shifted[D_W-2 -: 3] == 3'd1}} & 5'b0_1110)
| ({(5){D_abs_l_shifted[D_W-2 -: 3] == 3'd2}} & 5'b1_0000)
| ({(5){D_abs_l_shifted[D_W-2 -: 3] == 3'd3}} & 5'b1_0000)
| ({(5){D_abs_l_shifted[D_W-2 -: 3] == 3'd4}} & 5'b1_0010)
| ({(5){D_abs_l_shifted[D_W-2 -: 3] == 3'd5}} & 5'b1_0100)
| ({(5){D_abs_l_shifted[D_W-2 -: 3] == 3'd6}} & 5'b1_0110)
| ({(5){D_abs_l_shifted[D_W-2 -: 3] == 3'd7}} & 5'b1_0110);

assign quo_dig_1st = {
	1'b0,
	1'b0,
	~(rem_trunc_1_4_for_1st_quo >= m_pos_1_for_1st_quo) & ~(rem_trunc_1_4_for_1st_quo >= m_pos_2_for_1st_quo),
	 (rem_trunc_1_4_for_1st_quo >= m_pos_1_for_1st_quo) & ~(rem_trunc_1_4_for_1st_quo >= m_pos_2_for_1st_quo),
	rem_trunc_1_4_for_1st_quo >= m_pos_2_for_1st_quo
};

// ================================================================================================================================================
// If we find "D_is_zero", we should force "quo_sign = 0" -> Beacuse it is supposed to output {(D_W){1'b1}} in this situation.
assign quo_sign_en = start_handshaked | (fsm_q[FSM_PRE_1_BIT] & D_is_zero);
assign quo_sign_d  = fsm_q[FSM_PRE_0_BIT] ? (N_sign ^ D_sign) : '0;

assign rem_sign_en = start_handshaked;
assign rem_sign_d  = N_sign;

// D_W = 64: {N_lzc[6], N_lzc[1:0], D_lzc[6:0], lzc_diff[6:0]}
// D_W = 32: {N_lzc[5], N_lzc[1:0], 1'b0, D_lzc[5:0], 1'b0, lzc_diff[5:0]}
// In conclusion, rem_s_q[0 +: 17] is used to store LZC_INFO got in pre_0.
assign rem_s_en = start_handshaked | fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];
assign rem_s_d  = 
fsm_q[FSM_PRE_0_BIT] ? {
	rem_s_q[REM_W-1 -: 17], 
	N_lzc[LZC_W],
	N_lzc[1:0],
	(D_W == 64) ? D_lzc[6] : 1'b0,
	D_lzc[5:0],
	(D_W == 64) ? lzc_diff[6] : 1'b0,
	lzc_diff[5:0]
} : 
fsm_q[FSM_PRE_1_BIT] ? rem_s_iter_init : 
nxt_rem_s[1];

assign rem_c_en = fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];
assign rem_c_d  = fsm_q[FSM_PRE_1_BIT] ? '0 : nxt_rem_c[1];

assign rem_r_aligned_s_en = fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];
assign rem_r_aligned_s_d  = fsm_q[FSM_PRE_1_BIT] ? rem_r_aligned_s_iter_init : nxt_rem_r_aligned_s[1];

assign rem_r_aligned_c_en = fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];
assign rem_r_aligned_c_d  = fsm_q[FSM_PRE_1_BIT] ? '0 : nxt_rem_r_aligned_c[1];

assign N_r_shifted_lsbs_en = start_handshaked | fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];
// pre_0: ~D[D_W-3:0], this will be used as a "MASK" when(D is a negative power of 2)
assign N_r_shifted_lsbs_d = 
fsm_q[FSM_PRE_0_BIT] ? ~divisor_i[D_W-3:0] : 
fsm_q[FSM_PRE_1_BIT] ? N_r_shifted_lsbs_iter_init : 
N_r_shifted_lsbs_q << 4;


assign iter_num_en = fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];
assign iter_num_d  = fsm_q[FSM_PRE_1_BIT] ? (
	(D_W == 64) ? (correct_lzc_diff[5:2] + {{(3){1'b0}}, &correct_lzc_diff[1:0]}) : 
	{1'b0, correct_lzc_diff[4:2] + {{(2){1'b0}}, &correct_lzc_diff[1:0]}}
) : (iter_num_q - 4'd1);

assign final_iter = (iter_num_q == 4'd0);


assign normalized_D_en = start_handshaked | fsm_q[FSM_PRE_1_BIT];
assign normalized_D_d  = fsm_q[FSM_PRE_0_BIT] ? D_abs_l_shifted_s5_to_s2[D_W-2:0] : D_abs_l_shifted;

assign D_abs_en = start_handshaked;
assign D_abs_d  = D_abs;

assign D_is_zero_en = start_handshaked | fsm_q[FSM_PRE_1_BIT];
assign D_is_zero_d  = fsm_q[FSM_PRE_0_BIT] ? ~divisor_i[D_W-2] : D_is_zero;

assign D_is_special_en = start_handshaked | fsm_q[FSM_PRE_1_BIT];
assign D_is_special_d  = fsm_q[FSM_PRE_0_BIT] ? D_abs_l_shifted_s5_to_s2[D_W-1] : (D_is_one | D_is_neg_power_of_2);


assign prev_quo_dig_en = fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];
assign prev_quo_dig_d  = fsm_q[FSM_PRE_1_BIT] ? quo_dig_1st : nxt_quo_dig[1];

assign quo_iter_en = start_handshaked | fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];
assign quo_iter_d = 
fsm_q[FSM_PRE_0_BIT] ? N_abs_l_shifted_s5_to_s2 : 
fsm_q[FSM_PRE_1_BIT] ? quo_iter_init : 
nxt_quo_iter[1];

// According to the property of the SRT algorithm, the first "NON_ZERO quo_dig" must be "+1/+2", it cannot be "-1/-2"
// So "quo_m1" is not useful until we get the first "NON_ZERO quo_dig".
// Therefore, we don't have to do any initialization operation for quo_m1 before the iter starts.
assign quo_m1_iter_en = start_handshaked | fsm_q[FSM_ITER_BIT];
assign quo_m1_iter_d = fsm_q[FSM_PRE_0_BIT] ? N_abs : nxt_quo_m1_iter[1];

assign m_neg_0_pos_1_lsb_en = fsm_q[FSM_PRE_1_BIT];
assign m_neg_0_pos_1_lsb_d  = (D_abs_l_shifted[D_W-2 -: 3] == 3'b000) | (D_abs_l_shifted[D_W-2 -: 3] == 3'b100);

assign m_neg_1_en = fsm_q[FSM_PRE_1_BIT];
assign m_neg_1_d  = m_neg_1_init[5:1];

assign m_neg_0_en = fsm_q[FSM_PRE_1_BIT];
assign m_neg_0_d  = m_neg_0_init[3:1];

assign m_pos_1_en = fsm_q[FSM_PRE_1_BIT];
assign m_pos_1_d  = m_pos_1_init[2:1];

assign m_pos_2_en = fsm_q[FSM_PRE_1_BIT];
assign m_pos_2_d  = m_pos_2_init[5:1];


always_ff @(posedge clk) begin
	if(quo_sign_en)
		quo_sign_q <= quo_sign_d;
	if(rem_sign_en)
		rem_sign_q <= rem_sign_d;

	if(rem_s_en)
		rem_s_q <= rem_s_d;
	if(rem_c_en)
		rem_c_q <= rem_c_d;
	if(rem_r_aligned_s_en)
		rem_r_aligned_s_q <= rem_r_aligned_s_d;
	if(rem_r_aligned_c_en)
		rem_r_aligned_c_q <= rem_r_aligned_c_d;
	if(N_r_shifted_lsbs_en)
		N_r_shifted_lsbs_q <= N_r_shifted_lsbs_d;

	if(iter_num_en)
		iter_num_q <= iter_num_d;

	if(normalized_D_en)
		normalized_D_q <= normalized_D_d;
	if(D_abs_en)
		D_abs_q <= D_abs_d;
	if(D_is_zero_en)
		D_is_zero_q <= D_is_zero_d;
	if(D_is_special_en)
		D_is_special_q <= D_is_special_d;

	if(prev_quo_dig_en)
		prev_quo_dig_q <= prev_quo_dig_d;
	if(quo_iter_en)
		quo_iter_q <= quo_iter_d;
	if(quo_m1_iter_en)
		quo_m1_iter_q <= quo_m1_iter_d;

	if(m_neg_0_pos_1_lsb_en)
		m_neg_0_pos_1_lsb_q <= m_neg_0_pos_1_lsb_d;
	if(m_neg_1_en)
		m_neg_1_q <= m_neg_1_d;
	if(m_neg_0_en)
		m_neg_0_q <= m_neg_0_d;
	if(m_pos_1_en)
		m_pos_1_q <= m_pos_1_d;
	if(m_pos_2_en)
		m_pos_2_q <= m_pos_2_d;
end


// ================================================================================================================================================
// SRT ITER
// ================================================================================================================================================

r16_block #(
	.D_W(D_W),
	.REM_W(REM_W),
	.QUO_DIG_W(QUO_DIG_W)
) u_r16_block (
	.rem_s_i(rem_s_q),
	.rem_c_i(rem_c_q),
	.D_i(normalized_D_q[(D_W-1)-1:0]),
	.m_neg_1_i(m_neg_1_q),
	.m_neg_0_i(m_neg_0_q),
	.m_pos_1_i(m_pos_1_q),
	.m_pos_2_i(m_pos_2_q),
	.m_neg_0_pos_1_lsb_i(m_neg_0_pos_1_lsb_q),
	.quo_iter_i(quo_iter_q),
	.quo_m1_iter_i(quo_m1_iter_q),
	.prev_quo_dig_i(prev_quo_dig_q),
	.nxt_rem_s_o(nxt_rem_s),
	.nxt_rem_c_o(nxt_rem_c),
	.nxt_quo_iter_o(nxt_quo_iter),
	.nxt_quo_m1_iter_o(nxt_quo_m1_iter),
	.nxt_quo_dig_o(nxt_quo_dig)
);


assign D_abs_ext = {1'b0, D_abs_q, 2'b0};
assign D_abs_to_csa[0] = 
  ({(D_W + 3){prev_quo_dig_q[4]}} & {D_abs_ext[D_W+1:0], 1'b0})
| ({(D_W + 3){prev_quo_dig_q[3]}} & D_abs_ext)
| ({(D_W + 3){prev_quo_dig_q[1]}} & ~D_abs_ext)
| ({(D_W + 3){prev_quo_dig_q[0]}} & ~{D_abs_ext[D_W+1:0], 1'b0});

assign nxt_rem_r_aligned_s[0] = 
  {rem_r_aligned_s_q[D_W:0], N_r_shifted_lsbs_q[D_W-3 -: 2]}
^ {rem_r_aligned_c_q[D_W:0], 2'b00}
^ D_abs_to_csa[0];
assign nxt_rem_r_aligned_c[0] = {
	  ({rem_r_aligned_s_q[D_W-1:0], N_r_shifted_lsbs_q[D_W-3 -: 2]} & {rem_r_aligned_c_q[D_W-1:0], 2'b00})
	| ({rem_r_aligned_s_q[D_W-1:0], N_r_shifted_lsbs_q[D_W-3 -: 2]} & D_abs_to_csa[0][D_W+1:0])
	| ({rem_r_aligned_c_q[D_W-1:0], 2'b00} 							& D_abs_to_csa[0][D_W+1:0]),
	prev_quo_dig_q[0] | prev_quo_dig_q[1]
};

assign D_abs_to_csa[1] = 
  ({(D_W + 3){nxt_quo_dig[0][4]}} & {D_abs_ext[D_W+1:0], 1'b0})
| ({(D_W + 3){nxt_quo_dig[0][3]}} & D_abs_ext)
| ({(D_W + 3){nxt_quo_dig[0][1]}} & ~D_abs_ext)
| ({(D_W + 3){nxt_quo_dig[0][0]}} & ~{D_abs_ext[D_W+1:0], 1'b0});

assign nxt_rem_r_aligned_s[1] = 
  {nxt_rem_r_aligned_s[0][D_W:0], N_r_shifted_lsbs_q[D_W-3-2 -: 2]}
^ {nxt_rem_r_aligned_c[0][D_W:0], 2'b00}
^ D_abs_to_csa[1];
assign nxt_rem_r_aligned_c[1] = {
	  ({nxt_rem_r_aligned_s[0][D_W-1:0], N_r_shifted_lsbs_q[D_W-3-2 -: 2]} & {nxt_rem_r_aligned_c[0][D_W-1:0], 2'b00})
	| ({nxt_rem_r_aligned_s[0][D_W-1:0], N_r_shifted_lsbs_q[D_W-3-2 -: 2]} & D_abs_to_csa[1][D_W+1:0])
	| ({nxt_rem_r_aligned_c[0][D_W-1:0], 2'b00} 						   & D_abs_to_csa[1][D_W+1:0]),
	nxt_quo_dig[0][0] | nxt_quo_dig[0][1]
};

// ================================================================================================================================================
// Post
// ================================================================================================================================================

assign nr_rem_r_aligned = 
  ({(D_W + 3){rem_sign_q}} ^ rem_r_aligned_s_q)
+ ({(D_W + 3){rem_sign_q}} ^ rem_r_aligned_c_q)
+ {{(D_W + 1){1'b0}}, rem_sign_q, 1'b0};

assign nr_rem_r_aligned_plus_D = 
  ({(D_W + 3){rem_sign_q}} ^ rem_r_aligned_s_q)
+ ({(D_W + 3){rem_sign_q}} ^ rem_r_aligned_c_q)
+ ({(D_W + 3){rem_sign_q}} ^ D_abs_ext)
+ {{(D_W + 1){1'b0}}, rem_sign_q, rem_sign_q};

assign rem_r_aligned_xor = rem_r_aligned_s_q[(D_W+2)-1:1] ^ rem_r_aligned_c_q[(D_W+2)-1:1];
assign rem_r_aligned_or  = rem_r_aligned_s_q[(D_W+2)-2:0] | rem_r_aligned_c_q[(D_W+2)-2:0];
assign nr_rem_r_aligned_is_not_zero = (rem_r_aligned_xor != rem_r_aligned_or);

// If (rem >= 0):
// select_quo_m1 = 0 <-> "rem_pre" belongs to [ 0, +D), rem = (rem_pre + 0)
// select_quo_m1 = 1 <-> "rem_pre" belongs to (-D,  0), rem = (rem_pre + D)
// If (rem <= 0):
// select_quo_m1 = 0 <-> "rem_pre" belongs to (-D,  0], rem = (rem_pre - 0)
// select_quo_m1 = 1 <-> "rem_pre" belongs to ( 0, +D), rem = (rem_pre - D)
assign select_quo_m1 = ~D_is_zero_q & ~D_is_special_q & (
	rem_sign_q ? (~nr_rem_r_aligned[D_W+2] & nr_rem_r_aligned_is_not_zero) : nr_rem_r_aligned[D_W+2]
);

assign quo_sign_adjusted = quo_sign_q ? negation_adder_res[0] : quo_iter_q;

assign quo_m1_sign_adjusted = quo_sign_q ? negation_adder_res[1] : quo_m1_iter_q;

assign quotient_o = select_quo_m1 ? quo_m1_sign_adjusted : quo_sign_adjusted;

assign remainder_o = select_quo_m1 ? nr_rem_r_aligned_plus_D[2 +: D_W] : nr_rem_r_aligned[2 +: D_W];

assign divisor_is_zero_o = D_is_zero_q;

endmodule
