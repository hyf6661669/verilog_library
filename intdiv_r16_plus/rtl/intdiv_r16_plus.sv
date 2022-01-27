// ========================================================================================================
// File Name			: intdiv_r16_plus.sv
// Author				: HYF
// How to Contact		: hyf_sysu@qq.com
// Created Time    		: 2022-01-26 09:23:42
// Last Modified Time   : 2022-01-27 21:26:43
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
localparam QUO_DIG_NEG_2 = (1 << 0);
localparam QUO_DIG_NEG_1 = (1 << 1);
localparam QUO_DIG_NEG_0 = (1 << 2);
localparam QUO_DIG_POS_1 = (1 << 3);
localparam QUO_DIG_POS_2 = (1 << 4);

localparam QUO_DIG_NEG_2_BIT = 0;
localparam QUO_DIG_NEG_1_BIT = 1;
localparam QUO_DIG_NEG_0_BIT = 2;
localparam QUO_DIG_POS_1_BIT = 3;
localparam QUO_DIG_POS_2_BIT = 4;

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

genvar i;

logic start_handshaked;
logic [FSM_W-1:0] fsm_d;
logic [FSM_W-1:0] fsm_q;

// In the design, when(D_W == 64), the MAX iter we need is 16, so a 4-bit reg is enough.
logic iter_num_en;
logic [4-1:0] iter_num_d;
logic [4-1:0] iter_num_q;
logic final_iter;

logic quo_sign_d;
logic quo_sign_q;
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

// To save 1 cycle for rem calculation, we use an extra data path, which is updated in parallel with the common data path.
logic r_aligned_rem_s_en;
logic [REM_W-1:0] r_aligned_rem_s_d;
logic [REM_W-1:0] r_aligned_rem_s_q;
logic r_aligned_rem_c_en;
logic [REM_W-1:0] r_aligned_rem_c_d;
logic [REM_W-1:0] r_aligned_rem_c_q;
logic rem_s_en;
logic [REM_W-1:0] rem_s_d;
logic [REM_W-1:0] rem_s_q;
logic rem_c_en;
logic [REM_W-1:0] rem_c_d;
logic [REM_W-1:0] rem_c_q;

// Since we only handle D >= 2'b10, the MAX r_shift_num for abs(N) is "D_W - 2"
logic N_r_shifted_lsbs_en;
logic [(D_W-2)-1:0] N_r_shifted_lsbs_d;
logic [(D_W-2)-1:0] N_r_shifted_lsbs_q;

// After normalization, the MSB of "normalized_D" must be 1 -> We don't need to store it
logic normalized_D_en;
// logic [(D_W-1)-1:0] normalized_D_d;
// logic [(D_W-1)-1:0] normalized_D_q;
logic [D_W-1:0] normalized_D_d;
logic [D_W-1:0] normalized_D_q;
logic D_abs_en;
logic [D_W-1:0] D_abs_d;
logic [D_W-1:0] D_abs_q;

logic [D_W-1:0] N_l_shifted_s5_to_s2;
logic [D_W-1:0] D_l_shifted_s5_to_s2;

logic D_trunc_3_5_for_nxt_cycle_en;
logic [8-1:0] D_trunc_3_5_for_nxt_cycle_d;
logic [8-1:0] D_trunc_3_5_for_nxt_cycle_q;
logic [8-1:0] nxt_D_trunc_3_5_for_nxt_cycle;

logic prev_quo_dig_en;
logic [QUO_DIG_W-1:0] prev_quo_dig_d;
logic [QUO_DIG_W-1:0] prev_quo_dig_q;
logic [QUO_DIG_W-1:0] quo_dig_1st;
logic [QUO_DIG_W-1:0] nxt_prev_quo_dig;

logic quo_iter_en;
logic [D_W-1:0] quo_iter_d;
logic [D_W-1:0] quo_iter_q;
logic quo_m1_iter_en;
logic [D_W-1:0] quo_m1_iter_d;
logic [D_W-1:0] quo_m1_iter_q;
logic [D_W-1:0] nxt_quo_iter [2-1:0];
logic [D_W-1:0] nxt_quo_m1_iter [2-1:0];

logic [7-1:0] m_neg_1_init;
logic [7-1:0] m_neg_0_init;
logic [7-1:0] m_pos_1_init;
logic [7-1:0] m_pos_2_init;

// {m_neg_1[6], m_neg_1[0}} = 00 -> A 5-bit reg is enough
logic [5-1:0] m_neg_1_d;
logic [5-1:0] m_neg_1_q;
// In common cases, {m_neg_0[6:4], m_neg_0[0}} = 0000 -> A 3-bit reg is enough
logic [3-1:0] m_neg_0_d;
logic [3-1:0] m_neg_0_q;
// In common cases, {m_pos_1[6:4], m_pos_1[0}} = 1110 -> A 3-bit reg is enough
logic [3-1:0] m_pos_1_d;
logic [3-1:0] m_pos_1_q;
// {m_pos_2[6], m_pos_2[0}} = 10 -> A 5-bit reg is enough
logic [5-1:0] m_pos_2_d;
logic [5-1:0] m_pos_2_q;
logic special_D_d;
logic special_D_q;


// signals end
// ================================================================================================================================================

assign start_handshaked = start_valid_i & start_ready_o;
assign start_ready_o = fsm_q[FSM_PRE_0_BIT];
assign finsih_valid_o = fsm_q[FSM_POST_BIT];
// ================================================================================================================================================
// FSM Ctrl Logic
// ================================================================================================================================================
always_comb begin
	unique case(fsm_q)
		FSM_PRE_0:
			fsm_d = 
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
assign negation_adder_in[0] = fsm_q[FSM_PRE_0_BIT] ? dividend_i : quo_iter_q;
assign negation_adder_in[1] = fsm_q[FSM_PRE_0_BIT] ? divisor_i  : quo_m1_iter_q;
assign negation_adder_res[0] = -negation_adder_in[0];
assign negation_adder_res[1] = -negation_adder_in[1];

// ================================================================================================================================================
// pre_0
// ================================================================================================================================================
assign N_sign = signed_op_i & dividend_i[D_W-1];
assign D_sign = signed_op_i & divisor_i[D_W-1];
assign N_abs = N_sign ? negation_adder_res[0] : dividend_i;
assign D_abs = D_sign ? negation_adder_res[1] : divisor_i;

// Here we only the inverted value to make LZC faster, and we will make correction in pre_1.
// If "N = -1 = {(D_W){1'b1}}, then we will have "~N = 0", which will lead to "N_lzc[LZC_W] = 1". It would be complicated to tell the difference
// between "N = -1" and "N = 0", under this situation. To aviod that, we just make "N_to_lzc[0] = 1" when "N < 0", so we can get the correct "lzc" for "N = -1"
// The same operation should be applied to D
assign N_to_lzc = N_sign ? {~dividend_i[D_W-1:1], 1'b1} : dividend_i;
assign D_to_lzc = D_sign ? {~divisor_i[D_W-1:1], 1'b1}  : divisor_i;
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
// Since we will regard "D < 0, and D is the power of 2" as a special case.
// We only need to worry about the correctness of "lzc_diff" when (N < 0, and N is the power of 2)
// In the above situation, correct_N_lzc = N_lzc - 1 -> correct_lzc_diff = lzc_diff + 1
// In normal situation, if(lzc_diff < 0), then we would think that we can skip the iter (Because we must have: QUO = 0, REM = N, in this situation).
// If(lzc_diff == -1), then correct_lzc_diff = 0. So the QUO could be 1 or 0, but since the iter is skipped, we could only get "QUO = 0 and REM = N".
// Fortunately, this will not lead to mistake, because N.MSB and D.MSB are in the same position so we must have abs(N) < abs(D)
// Take D_W = 32 as an example.
// N = -(2 ^ 15) = 11111111111111111000000000000000 -> N_lzc = 17
// abs(N) = 00000000000000001000000000000000 -> correct_N_lzc = 16
// D = 00000000000000001000000000000001, D_lzc = 16
// lzc_diff = 16 - 17 = -1, correct_lzc_diff = 16 - 16 = 0
// By using the value of "lzc_diff", the iter will be skipped, and finally, we would get abs(QUO) = 0, abs(REM) = abs(N) = 00000000000000001000000000000000
// This is correct...
assign lzc_diff[LZC_W:0] = {1'b0, D_lzc[LZC_W-1:0]} - {1'b0, N_lzc[LZC_W-1:0]};

// When(D_W == 64), a 6-stage barrel shifter is needed, and we only do stage[5:2] in pre_0
generate
if(D_W == 64) begin: g_l_shifter_64
	assign N_l_shifted_s5_to_s2[D_W-1:0] = N_abs << {N_lzc[5:2], 2'b00};
	assign D_l_shifted_s5_to_s2[D_W-1:0] = D_abs << {D_lzc[5:2], 2'b00};
end else begin: g_l_shifter_32
	assign N_l_shifted_s5_to_s2[D_W-1:0] = N_abs << {N_lzc[4:2], 2'b00};
	assign D_l_shifted_s5_to_s2[D_W-1:0] = D_abs << {D_lzc[4:2], 2'b00};
end
endgenerate


assign D_trunc_3_5_for_nxt_cycle_en = start_handshaked | fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];
// pre_0
// D_W = 64: {lzc_diff[0], D_lzc[6:0]}
// D_W = 32: {lzc_diff[0], 1'b0, D_lzc[5:0]}
assign D_trunc_3_5_for_nxt_cycle_d = 
fsm_q[FSM_PRE_0_BIT] ? {lzc_diff[0], (D_W == 64) ? D_lzc[6] : 1'b0, D_lzc[5:0]} : 
fsm_q[FSM_PRE_1_BIT] ? 
nxt_D_trunc_3_5_for_nxt_cycle;


assign iter_num_en = start_handshaked | fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];
// pre_0: lzc_diff[4:1]
assign iter_num_d

assign prev_quo_dig_en = start_handshaked | fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];
// pre_0
// D_W = 64: {N_lzc[6], N_lzc[1:0], lzc_diff[6:5]}
// D_W = 32: {N_lzc[5], N_lzc[1:0], 0, lzc_diff[5]}
assign prev_quo_dig_d = 
fsm_q[FSM_PRE_0_BIT] ? {(D_W == 64) ? N_lzc[6] : N_lzc[5], N_lzc[1:0], (D_W == 64) ? lzc_diff[6] : 1'b0, lzc_diff[5]} : 
fsm_q[FSM_PRE_1_BIT] ? quo_dig_1st : 
nxt_prev_quo_dig;

assign normalized_D_en = start_handshaked | fsm_q[FSM_PRE_1_BIT];
assign normalized_D_d = fsm_q[FSM_PRE_0_BIT] ? D_l_shifted_s5_to_s2 : D_l_shifted;


assign nxt_normalized_D_pre_0 = ;
assign 


assign quo_iter_en = start_handshaked | fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];
assign quo_iter_d = 
fsm_q[FSM_PRE_0_BIT] ? N_l_shifted_s5_to_s2 : 
fsm_q[FSM_PRE_1_BIT] ? N_l_shifted_s5_to_s2 : 




assign quo_m1_iter_en = start_handshaked | fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];
assign quo_m1_iter_d = 
fsm_q[FSM_PRE_0_BIT] ? N_abs : 
fsm_q[FSM_PRE_1_BIT] ? '0 : 
nxt_quo_m1[1];


assign nxt_quo_pre_0    = ;
assign nxt_quo_m1_pre_0 = N_abs;

generate
if(D_W == 64) begin: g_lzc_info_in_pre_1_64
	assign lzc_diff_pre_1 = {prev_quo_dig_q[1:0], iter_num_d_q[3:0], D_trunc_3_5_for_nxt_cycle_q[7]};
end else begin: g_lzc_info_in_pre_1_32
	assign lzc_diff_pre_1 = {prev_quo_dig_q[0], iter_num_d_q[3:0], D_trunc_3_5_for_nxt_cycle_q[7]};
end
endgenerate
// N_lzc_pre_1 = {N_lzc[LZC_W], N_lzc[1:0]}
assign N_lzc_pre_1 = prev_quo_dig_q[4:2];
assign D_lzc_pre_1 = D_trunc_3_5_for_nxt_cycle_q[LZC_W:0];

// TODO
// Consider I32, "N = 0" is a special case:
// N_lzc = 1_111111, 
// {N_too_small, D_is_zero} can't be 2'b11.
assign N_too_small = (D_W == 64) ? prev_quo_dig_q[1] : prev_quo_dig_q[0];
assign D_is_zero = D_lzc_pre_1[LZC_W];
// If(correct_lzc_diff == (D_W - 1)), it means abs(D) = 1, and we can directly get "QUO = N, REM = 0"
assign D_is_one = ~D_lzc_pre_1[LZC_W] & (D_lzc_pre_1[LZC_W-1:0] == {(LZC_W){1'b1}});
// This signal doesn't take "D = -1" into cosideration.
assign D_is_neg_power_of_2 = 


assign N_abs_r_shift_num = 






always_ff @(posedge clk) begin
	if(D_trunc_3_5_for_nxt_cycle_en)
		D_trunc_3_5_for_nxt_cycle_q <= D_trunc_3_5_for_nxt_cycle_d;
end




endmodule
