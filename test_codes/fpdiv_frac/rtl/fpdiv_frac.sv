// ========================================================================================================
// File Name			: fpdiv_frac.sv
// Author				: HYF
// How to Contact		: hyf_sysu@qq.com
// Created Time    		: 2021-12-29 16:42:38
// Last Modified Time   : 2021-12-30 20:23:54
// ========================================================================================================
// Description	:
// Radix-64 SRT algorithm for the frac part of fpdiv.
// ========================================================================================================
// ========================================================================================================
// Copyright (C) 2021, HYF. All Rights Reserved.
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

module fpdiv_frac #(
	// Put some parameters here, which can be changed by other modules
)(
	input  logic start_valid_i,
	output logic start_ready_o,
	input  logic flush_i,
	// 2'd0: fp16
	// 2'd1: fp16
	// 2'd2: fp64
	input  logic [2-1:0] fp_format_i,
	input  logic [53-1:0] a_frac_i,
	input  logic [53-1:0] b_frac_i,

	output logic finish_valid_o,
	input  logic finish_ready_i,
	output logic [54-1:0] fpdiv_frac_o,

	input  logic clk,
	input  logic rst_n
);

// ================================================================================================================================================
// (local) parameters begin

// SPECULATIVE_MSB_W = "number of srt iteration per cycles" * 2 = 3 * 2 = 6
localparam SPECULATIVE_MSB_W = 6;

// 
localparam REM_W = 3 + 53 + 3 + 2;

localparam FP64_FRAC_W = 52 + 1;
localparam FP32_FRAC_W = 23 + 1;
localparam FP16_FRAC_W = 10 + 1;

localparam FP64_EXP_W = 11;
localparam FP32_EXP_W = 8;
localparam FP16_EXP_W = 5;

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

// If r_shift_num of quo is larger than this value, then the whole quo would be sticky_bit
localparam R_SHIFT_NUM_LIMIT = 6'd55;

localparam RM_RNE = 3'b000;
localparam RM_RTZ = 3'b001;
localparam RM_RDN = 3'b010;
localparam RM_RUP = 3'b011;
localparam RM_RMM = 3'b100;

// (local) parameters end
// ================================================================================================================================================

// ================================================================================================================================================
// signals begin

genvar i;

logic start_handshaked;
logic [FSM_W-1:0] fsm_d;
logic [FSM_W-1:0] fsm_q;

logic iter_num_en;
logic [4-1:0] iter_num_d;
logic [4-1:0] iter_num_q;
logic final_iter;

logic fp_format_en;
logic [2-1:0] fp_format_d;
logic [2-1:0] fp_format_q;

logic [ 3-1:0] scaled_factor_selector;
logic [ 5-1:0] scaled_factor;
logic [53-1:0] prescaled_X;
logic [53-1:0] prescaled_D;
logic [58-1:0] scaled_X;
logic [58-1:0] scaled_D;
logic scaled_X_lt_scaled_D;

logic [REM_W-1:0] frac_rem_sum_iter_init;
logic [REM_W-1:0] frac_rem_carry_iter_init;
logic frac_rem_sum_en;
logic [REM_W-1:0] frac_rem_sum_d;
logic [REM_W-1:0] frac_rem_sum_q;
logic frac_rem_carry_en;
logic [REM_W-1:0] frac_rem_carry_d;
logic [REM_W-1:0] frac_rem_carry_q;

logic [REM_W-1:0] nxt_frac_rem_sum   [3-1:0];
logic [REM_W-1:0] nxt_frac_rem_carry [3-1:0];
// [4]: q[i] = -2
// [3]: q[i] = -1
// [2]: q[i] = -0
// [1]: q[i] = +1
// [0]: q[i] = +2
logic [REM_W-1:0] nxt_frac_rem_sum_spec_s0   [5-1:0];
logic [REM_W-1:0] nxt_frac_rem_sum_spec_s1   [5-1:0];
logic [REM_W-1:0] nxt_frac_rem_sum_spec_s2   [5-1:0];
logic [REM_W-1:0] nxt_frac_rem_carry_spec_s0 [5-1:0];
logic [REM_W-1:0] nxt_frac_rem_carry_spec_s1 [5-1:0];
logic [REM_W-1:0] nxt_frac_rem_carry_spec_s2 [5-1:0];

logic divisor_en;
logic [58-1:0] divisor_d;
logic [58-1:0] divisor_q;
logic [REM_W-1:0] divisor_extended;
logic [REM_W-1:0] divisor_mul_neg_2;
logic [REM_W-1:0] divisor_mul_neg_1;
logic [REM_W-1:0] divisor_mul_pos_1;
logic [REM_W-1:0] divisor_mul_pos_2;

logic quo_iter_en;
logic [54-1:0] pos_quo_iter_d;
logic [54-1:0] pos_quo_iter_q;
logic [54-1:0] neg_quo_iter_d;
logic [54-1:0] neg_quo_iter_q;

// [4]: -2
// [3]: -1
// [2]: -0
// [1]: +1
// [0]: +2
logic [5-1:0] quo_dig [3-1:0];
logic [54-1:0] nxt_pos_quo [3-1:0];
logic [54-1:0] nxt_neg_quo [3-1:0];

logic [6-1:0] adder_6b;
logic [9-1:0] adder_9b_sepc [5-1:0];
logic [4-1:0] adder_9b_carry_sepc [5-1:0];
logic [9-1:0] adder_9b;
logic [9-1:0] adder_9b_carry;
logic [7-1:0] adder_7b_spec [5-1:0];
logic [7-1:0] adder_7b;

logic [REM_W-1:0] nr_frac_rem;
logic [REM_W-1:0] nr_frac_rem_plus_d;
logic [54-1:0] nr_quo;
logic [54-1:0] nr_quo_m1;
logic [54-1:0] final_quo;

// signals end
// ================================================================================================================================================

// ================================================================================================================================================
// FSM ctrl
// ================================================================================================================================================
always_comb begin
	unique case(fsm_q)
		FSM_PRE_0:
			fsm_d = start_valid_i ? FSM_PRE_1 : FSM_PRE_0;
		FSM_PRE_1:
			fsm_d = FSM_ITER;
		FSM_ITER:
			fsm_d = final_iter ? FSM_POST_0 : FSM_ITER;
		FSM_POST_0:
			fsm_d = FSM_POST_1;
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
assign finish_valid_o = fsm_q[FSM_POST_1_BIT];

// ================================================================================================================================================
// Pre
// ================================================================================================================================================

assign scaled_factor_selector = (fp_format_i == 2'd0) ? b_frac_i[9 -: 3] : (fp_format_i == 2'd1) ? b_frac_i[22 -: 3] : b_frac_i[51 -: 3];
assign scaled_factor = 
  ({(5){scaled_factor_selector == 3'd0}} & 5'b10000)
| ({(5){scaled_factor_selector == 3'd1}} & 5'b01110)
| ({(5){scaled_factor_selector == 3'd2}} & 5'b01101)
| ({(5){scaled_factor_selector == 3'd3}} & 5'b01100)
| ({(5){scaled_factor_selector == 3'd4}} & 5'b01011)
| ({(5){scaled_factor_selector == 3'd5}} & 5'b01010)
| ({(5){scaled_factor_selector == 3'd6}} & 5'b01001)
| ({(5){scaled_factor_selector == 3'd7}} & 5'b01001);

assign prescaled_X[52:0] = 
  ({(53){fp_format_i == 2'd0}} & {a_frac_i[0 +: 11], {(53 - 11){1'b0}}})
| ({(53){fp_format_i == 2'd1}} & {a_frac_i[0 +: 24], {(53 - 24){1'b0}}})
| ({(53){fp_format_i == 2'd2}} & {a_frac_i[0 +: 53], {(53 - 53){1'b0}}});
assign prescaled_D[52:0] = 
  ({(53){fp_format_i == 2'd0}} & {b_frac_i[0 +: 11], {(53 - 11){1'b0}}})
| ({(53){fp_format_i == 2'd1}} & {b_frac_i[0 +: 24], {(53 - 24){1'b0}}})
| ({(53){fp_format_i == 2'd2}} & {b_frac_i[0 +: 53], {(53 - 53){1'b0}}});

assign scaled_X[57:0] = prescaled_X * scaled_factor;
assign scaled_D[57:0] = prescaled_D * scaled_factor;
assign scaled_X_lt_scaled_D = scaled_X < scaled_D;

assign divisor_en = fsm_q[FSM_PRE_0_BIT];
assign divisor_d  = scaled_D;
always_ff @(posedge clk)
	if(divisor_en)
		divisor_q <= divisor_d;


assign fp_format_en = start_handshaked;
assign fp_format_d  = fp_format_i;
always_ff @(posedge clk)
	if(fp_format_en)
		fp_format_q <= fp_format_d;


assign frac_rem_sum_iter_init   = {2'b0, scaled_X_lt_scaled_D ? {scaled_X, 1'b0} : {1'b0, scaled_X}};
assign frac_rem_carry_iter_init = '0;

assign frac_rem_sum_en = fsm_q[FSM_PRE_0_BIT] | fsm_q[FSM_ITER_BIT];
assign frac_rem_sum_d  = fsm_q[FSM_PRE_0_BIT] ? frac_rem_sum_iter_init : nxt_frac_rem_sum[2];

assign frac_rem_carry_en = fsm_q[FSM_PRE_0_BIT] | fsm_q[FSM_ITER_BIT];
assign frac_rem_carry_d  = fsm_q[FSM_PRE_0_BIT] ? frac_rem_carry_iter_init : nxt_frac_rem_carry[2];

assign final_iter = (iter_num_q == 4'd0);
assign iter_num_en = fsm_q[FSM_PRE_0_BIT] | fsm_q[FSM_ITER_BIT];
// fp64: 9
// fp32: 4
// fp16: 2
assign iter_num_d  = fsm_q[FSM_PRE_0_BIT] ? ((fp_format_i == 2'd0) ? 4'd1 : (fp_format_i == 2'd1) ? 4'd3 : 4'd8) : (iter_num_q - 4'd1);
always_ff @(posedge clk) begin
	if(frac_rem_sum_en)
		frac_rem_sum_q <= frac_rem_sum_d;
	if(frac_rem_carry_en)
		frac_rem_carry_q <= frac_rem_carry_d;
	if(iter_num_en)
		iter_num_q <= iter_num_d;
end

// ================================================================================================================================================
// SRT
// ================================================================================================================================================

assign quo_iter_en = fsm_q[FSM_PRE_0_BIT] | fsm_q[FSM_ITER_BIT];
assign pos_quo_iter_d = fsm_q[FSM_PRE_0_BIT] ? '0 : nxt_pos_quo[2];
assign neg_quo_iter_d = fsm_q[FSM_PRE_0_BIT] ? '0 : nxt_neg_quo[2];
always_ff @(posedge clk) begin
	if(quo_iter_en) begin
		pos_quo_iter_q <= pos_quo_iter_d;
		neg_quo_iter_q <= neg_quo_iter_d;
	end
end

assign divisor_extended = {1'b0, divisor_q, 2'b0};
assign divisor_mul_neg_2 = ~{divisor_extended[(REM_W-1)-1:0], 1'b0};
assign divisor_mul_neg_1 = ~divisor_extended;
assign divisor_mul_pos_1 = divisor_extended;
assign divisor_mul_pos_2 = {divisor_extended[(REM_W-1)-1:0], 1'b0};

// stage[0]
assign nxt_frac_rem_sum_spec_s0[4] = 
  {frac_rem_sum_q  [(REM_W-1)-2:0], 2'b0}
^ {frac_rem_carry_q[(REM_W-1)-2:0], 2'b0}
^ divisor_mul_pos_2;
assign nxt_frac_rem_carry_spec_s0[4] = {
	  ({frac_rem_sum_q  [(REM_W-1)-3:0], 2'b0} & {frac_rem_carry_q[(REM_W-1)-3:0], 2'b0})
	| ({frac_rem_sum_q  [(REM_W-1)-3:0], 2'b0} & divisor_mul_pos_2[(REM_W-1)-1:0])
	| ({frac_rem_carry_q[(REM_W-1)-3:0], 2'b0} & divisor_mul_pos_2[(REM_W-1)-1:0]),
	1'b0
};

assign nxt_frac_rem_sum_spec_s0[3] = 
  {frac_rem_sum_q  [(REM_W-1)-2:0], 2'b0}
^ {frac_rem_carry_q[(REM_W-1)-2:0], 2'b0}
^ divisor_mul_pos_1;
assign nxt_frac_rem_carry_spec_s0[3] = {
	  ({frac_rem_sum_q  [(REM_W-1)-3:0], 2'b0} & {frac_rem_carry_q[(REM_W-1)-3:0], 2'b0})
	| ({frac_rem_sum_q  [(REM_W-1)-3:0], 2'b0} & divisor_mul_pos_1[(REM_W-1)-1:0])
	| ({frac_rem_carry_q[(REM_W-1)-3:0], 2'b0} & divisor_mul_pos_1[(REM_W-1)-1:0]),
	1'b0
};

assign nxt_frac_rem_sum_spec_s0[2]   = {frac_rem_sum_q  [(REM_W-1)-2:0], 2'b0};
assign nxt_frac_rem_carry_spec_s0[2] = {frac_rem_carry_q[(REM_W-1)-2:0], 2'b0};

assign nxt_frac_rem_sum_spec_s0[1] = 
  {frac_rem_sum_q  [(REM_W-1)-2:0], 2'b0}
^ {frac_rem_carry_q[(REM_W-1)-2:0], 2'b0}
^ divisor_mul_neg_1;
assign nxt_frac_rem_carry_spec_s0[1] = {
	  ({frac_rem_sum_q  [(REM_W-1)-3:0], 2'b0} & {frac_rem_carry_q[(REM_W-1)-3:0], 2'b0})
	| ({frac_rem_sum_q  [(REM_W-1)-3:0], 2'b0} & divisor_mul_neg_1[(REM_W-1)-1:0])
	| ({frac_rem_carry_q[(REM_W-1)-3:0], 2'b0} & divisor_mul_neg_1[(REM_W-1)-1:0]),
	1'b1
};

assign nxt_frac_rem_sum_spec_s0[0] = 
  {frac_rem_sum_q  [(REM_W-1)-2:0], 2'b0}
^ {frac_rem_carry_q[(REM_W-1)-2:0], 2'b0}
^ divisor_mul_neg_2;
assign nxt_frac_rem_carry_spec_s0[0] = {
	  ({frac_rem_sum_q  [(REM_W-1)-3:0], 2'b0} & {frac_rem_carry_q[(REM_W-1)-3:0], 2'b0})
	| ({frac_rem_sum_q  [(REM_W-1)-3:0], 2'b0} & divisor_mul_neg_2[(REM_W-1)-1:0])
	| ({frac_rem_carry_q[(REM_W-1)-3:0], 2'b0} & divisor_mul_neg_2[(REM_W-1)-1:0]),
	1'b1
};

// QDS
// assign adder_6b = frac_rem_sum_q[(REM_W-1-2) -: 6] + frac_rem_carry_q[(REM_W-1-2) -: 6];
assign adder_6b = frac_rem_sum_q[(REM_W-1-2) -: 6] + frac_rem_carry_q[(REM_W-1-2) -: 6] + 6'd1;
r4_qds_v0
u_r4_qds_s0 (
	.rem_i(adder_6b),
	.quo_dig_o(quo_dig[0])
);
assign nxt_pos_quo[0] = {pos_quo_iter_q[51:0], quo_dig[0][0], quo_dig[0][1]};
assign nxt_neg_quo[0] = {neg_quo_iter_q[51:0], quo_dig[0][4], quo_dig[0][3]};

assign nxt_frac_rem_sum[0] = 
  ({(REM_W){quo_dig[0][4]}} & nxt_frac_rem_sum_spec_s0[4])
| ({(REM_W){quo_dig[0][3]}} & nxt_frac_rem_sum_spec_s0[3])
| ({(REM_W){quo_dig[0][2]}} & nxt_frac_rem_sum_spec_s0[2])
| ({(REM_W){quo_dig[0][1]}} & nxt_frac_rem_sum_spec_s0[1])
| ({(REM_W){quo_dig[0][0]}} & nxt_frac_rem_sum_spec_s0[0]);
assign nxt_frac_rem_carry[0] = 
  ({(REM_W){quo_dig[0][4]}} & nxt_frac_rem_carry_spec_s0[4])
| ({(REM_W){quo_dig[0][3]}} & nxt_frac_rem_carry_spec_s0[3])
| ({(REM_W){quo_dig[0][2]}} & nxt_frac_rem_carry_spec_s0[2])
| ({(REM_W){quo_dig[0][1]}} & nxt_frac_rem_carry_spec_s0[1])
| ({(REM_W){quo_dig[0][0]}} & nxt_frac_rem_carry_spec_s0[0]);

// assign adder_9b_sepc[4] = nxt_frac_rem_sum_spec_s0[4][(REM_W-1-2) -: 9] + nxt_frac_rem_carry_spec_s0[4][(REM_W-1-2) -: 9];
// assign adder_9b_sepc[3] = nxt_frac_rem_sum_spec_s0[3][(REM_W-1-2) -: 9] + nxt_frac_rem_carry_spec_s0[3][(REM_W-1-2) -: 9];
// assign adder_9b_sepc[2] = nxt_frac_rem_sum_spec_s0[2][(REM_W-1-2) -: 9] + nxt_frac_rem_carry_spec_s0[2][(REM_W-1-2) -: 9];
// assign adder_9b_sepc[1] = nxt_frac_rem_sum_spec_s0[1][(REM_W-1-2) -: 9] + nxt_frac_rem_carry_spec_s0[1][(REM_W-1-2) -: 9];
// assign adder_9b_sepc[0] = nxt_frac_rem_sum_spec_s0[0][(REM_W-1-2) -: 9] + nxt_frac_rem_carry_spec_s0[0][(REM_W-1-2) -: 9];

// assign adder_9b_carry_sepc[4] = {1'b0, nxt_frac_rem_sum_spec_s0[4][(REM_W-1-2-6) -: 3]} + {1'b0, nxt_frac_rem_carry_spec_s0[4][(REM_W-1-2-6) -: 3]};
// assign adder_9b_carry_sepc[3] = {1'b0, nxt_frac_rem_sum_spec_s0[3][(REM_W-1-2-6) -: 3]} + {1'b0, nxt_frac_rem_carry_spec_s0[3][(REM_W-1-2-6) -: 3]};
// assign adder_9b_carry_sepc[2] = {1'b0, nxt_frac_rem_sum_spec_s0[2][(REM_W-1-2-6) -: 3]} + {1'b0, nxt_frac_rem_carry_spec_s0[2][(REM_W-1-2-6) -: 3]};
// assign adder_9b_carry_sepc[1] = {1'b0, nxt_frac_rem_sum_spec_s0[1][(REM_W-1-2-6) -: 3]} + {1'b0, nxt_frac_rem_carry_spec_s0[1][(REM_W-1-2-6) -: 3]};
// assign adder_9b_carry_sepc[0] = {1'b0, nxt_frac_rem_sum_spec_s0[0][(REM_W-1-2-6) -: 3]} + {1'b0, nxt_frac_rem_carry_spec_s0[0][(REM_W-1-2-6) -: 3]};

assign adder_9b_sepc[4] = nxt_frac_rem_sum_spec_s0[4][(REM_W-1-2) -: 9] + nxt_frac_rem_carry_spec_s0[4][(REM_W-1-2) -: 9] + 9'd1;
assign adder_9b_sepc[3] = nxt_frac_rem_sum_spec_s0[3][(REM_W-1-2) -: 9] + nxt_frac_rem_carry_spec_s0[3][(REM_W-1-2) -: 9] + 9'd1;
assign adder_9b_sepc[2] = nxt_frac_rem_sum_spec_s0[2][(REM_W-1-2) -: 9] + nxt_frac_rem_carry_spec_s0[2][(REM_W-1-2) -: 9] + 9'd1;
assign adder_9b_sepc[1] = nxt_frac_rem_sum_spec_s0[1][(REM_W-1-2) -: 9] + nxt_frac_rem_carry_spec_s0[1][(REM_W-1-2) -: 9] + 9'd1;
assign adder_9b_sepc[0] = nxt_frac_rem_sum_spec_s0[0][(REM_W-1-2) -: 9] + nxt_frac_rem_carry_spec_s0[0][(REM_W-1-2) -: 9] + 9'd1;

assign adder_9b_carry_sepc[4] = {1'b0, nxt_frac_rem_sum_spec_s0[4][(REM_W-1-2-6) -: 3]} + {1'b0, nxt_frac_rem_carry_spec_s0[4][(REM_W-1-2-6) -: 3]} + 4'd1;
assign adder_9b_carry_sepc[3] = {1'b0, nxt_frac_rem_sum_spec_s0[3][(REM_W-1-2-6) -: 3]} + {1'b0, nxt_frac_rem_carry_spec_s0[3][(REM_W-1-2-6) -: 3]} + 4'd1;
assign adder_9b_carry_sepc[2] = {1'b0, nxt_frac_rem_sum_spec_s0[2][(REM_W-1-2-6) -: 3]} + {1'b0, nxt_frac_rem_carry_spec_s0[2][(REM_W-1-2-6) -: 3]} + 4'd1;
assign adder_9b_carry_sepc[1] = {1'b0, nxt_frac_rem_sum_spec_s0[1][(REM_W-1-2-6) -: 3]} + {1'b0, nxt_frac_rem_carry_spec_s0[1][(REM_W-1-2-6) -: 3]} + 4'd1;
assign adder_9b_carry_sepc[0] = {1'b0, nxt_frac_rem_sum_spec_s0[0][(REM_W-1-2-6) -: 3]} + {1'b0, nxt_frac_rem_carry_spec_s0[0][(REM_W-1-2-6) -: 3]} + 4'd1;

assign adder_9b = 
  ({(9){quo_dig[0][4]}} & adder_9b_sepc[4])
| ({(9){quo_dig[0][3]}} & adder_9b_sepc[3])
| ({(9){quo_dig[0][2]}} & adder_9b_sepc[2])
| ({(9){quo_dig[0][1]}} & adder_9b_sepc[1])
| ({(9){quo_dig[0][0]}} & adder_9b_sepc[0]);
assign adder_9b_carry = 
  ({(1){quo_dig[0][4]}} & adder_9b_carry_sepc[4][3])
| ({(1){quo_dig[0][3]}} & adder_9b_carry_sepc[3][3])
| ({(1){quo_dig[0][2]}} & adder_9b_carry_sepc[2][3])
| ({(1){quo_dig[0][1]}} & adder_9b_carry_sepc[1][3])
| ({(1){quo_dig[0][0]}} & adder_9b_carry_sepc[0][3]);


// stage[1]
assign nxt_frac_rem_sum_spec_s1[4] = 
  {nxt_frac_rem_sum  [0][(REM_W-1)-2:0], 2'b0}
^ {nxt_frac_rem_carry[0][(REM_W-1)-2:0], 2'b0}
^ divisor_mul_pos_2;
assign nxt_frac_rem_carry_spec_s1[4] = {
	  ({nxt_frac_rem_sum  [0][(REM_W-1)-3:0], 2'b0} & {nxt_frac_rem_carry[0][(REM_W-1)-3:0], 2'b0})
	| ({nxt_frac_rem_sum  [0][(REM_W-1)-3:0], 2'b0} & divisor_mul_pos_2[(REM_W-1)-1:0])
	| ({nxt_frac_rem_carry[0][(REM_W-1)-3:0], 2'b0} & divisor_mul_pos_2[(REM_W-1)-1:0]),
	1'b0
};

assign nxt_frac_rem_sum_spec_s1[3] = 
  {nxt_frac_rem_sum  [0][(REM_W-1)-2:0], 2'b0}
^ {nxt_frac_rem_carry[0][(REM_W-1)-2:0], 2'b0}
^ divisor_mul_pos_1;
assign nxt_frac_rem_carry_spec_s1[3] = {
	  ({nxt_frac_rem_sum  [0][(REM_W-1)-3:0], 2'b0} & {nxt_frac_rem_carry[0][(REM_W-1)-3:0], 2'b0})
	| ({nxt_frac_rem_sum  [0][(REM_W-1)-3:0], 2'b0} & divisor_mul_pos_1[(REM_W-1)-1:0])
	| ({nxt_frac_rem_carry[0][(REM_W-1)-3:0], 2'b0} & divisor_mul_pos_1[(REM_W-1)-1:0]),
	1'b0
};

assign nxt_frac_rem_sum_spec_s1[2]   = {nxt_frac_rem_sum  [0][(REM_W-1)-2:0], 2'b0};
assign nxt_frac_rem_carry_spec_s1[2] = {nxt_frac_rem_carry[0][(REM_W-1)-2:0], 2'b0};

assign nxt_frac_rem_sum_spec_s1[1] = 
  {nxt_frac_rem_sum  [0][(REM_W-1)-2:0], 2'b0}
^ {nxt_frac_rem_carry[0][(REM_W-1)-2:0], 2'b0}
^ divisor_mul_neg_1;
assign nxt_frac_rem_carry_spec_s1[1] = {
	  ({nxt_frac_rem_sum  [0][(REM_W-1)-3:0], 2'b0} & {nxt_frac_rem_carry[0][(REM_W-1)-3:0], 2'b0})
	| ({nxt_frac_rem_sum  [0][(REM_W-1)-3:0], 2'b0} & divisor_mul_neg_1[(REM_W-1)-1:0])
	| ({nxt_frac_rem_carry[0][(REM_W-1)-3:0], 2'b0} & divisor_mul_neg_1[(REM_W-1)-1:0]),
	1'b1
};

assign nxt_frac_rem_sum_spec_s1[0] = 
  {nxt_frac_rem_sum  [0][(REM_W-1)-2:0], 2'b0}
^ {nxt_frac_rem_carry[0][(REM_W-1)-2:0], 2'b0}
^ divisor_mul_neg_2;
assign nxt_frac_rem_carry_spec_s1[0] = {
	  ({nxt_frac_rem_sum  [0][(REM_W-1)-3:0], 2'b0} & {nxt_frac_rem_carry[0][(REM_W-1)-3:0], 2'b0})
	| ({nxt_frac_rem_sum  [0][(REM_W-1)-3:0], 2'b0} & divisor_mul_neg_2[(REM_W-1)-1:0])
	| ({nxt_frac_rem_carry[0][(REM_W-1)-3:0], 2'b0} & divisor_mul_neg_2[(REM_W-1)-1:0]),
	1'b1
};

// QDS
r4_qds_v1
u_r4_qds_s1 (
	.rem_i(adder_9b[8:3]),
	.carry_i(adder_9b_carry),
	.quo_dig_o(quo_dig[1])
);
assign nxt_pos_quo[1] = {nxt_pos_quo[0][51:0], quo_dig[1][0], quo_dig[1][1]};
assign nxt_neg_quo[1] = {nxt_neg_quo[0][51:0], quo_dig[1][4], quo_dig[1][3]};

assign nxt_frac_rem_sum[1] = 
  ({(REM_W){quo_dig[1][4]}} & nxt_frac_rem_sum_spec_s1[4])
| ({(REM_W){quo_dig[1][3]}} & nxt_frac_rem_sum_spec_s1[3])
| ({(REM_W){quo_dig[1][2]}} & nxt_frac_rem_sum_spec_s1[2])
| ({(REM_W){quo_dig[1][1]}} & nxt_frac_rem_sum_spec_s1[1])
| ({(REM_W){quo_dig[1][0]}} & nxt_frac_rem_sum_spec_s1[0]);
assign nxt_frac_rem_carry[1] = 
  ({(REM_W){quo_dig[1][4]}} & nxt_frac_rem_carry_spec_s1[4])
| ({(REM_W){quo_dig[1][3]}} & nxt_frac_rem_carry_spec_s1[3])
| ({(REM_W){quo_dig[1][2]}} & nxt_frac_rem_carry_spec_s1[2])
| ({(REM_W){quo_dig[1][1]}} & nxt_frac_rem_carry_spec_s1[1])
| ({(REM_W){quo_dig[1][0]}} & nxt_frac_rem_carry_spec_s1[0]);

// assign adder_7b_spec[4] = adder_9b[6:0] + divisor_mul_pos_2[(REM_W-1-2) -: 7];
// assign adder_7b_spec[3] = adder_9b[6:0] + divisor_mul_pos_1[(REM_W-1-2) -: 7];
// assign adder_7b_spec[2] = adder_9b[6:0];
// assign adder_7b_spec[1] = adder_9b[6:0] + divisor_mul_neg_1[(REM_W-1-2) -: 7];
// assign adder_7b_spec[0] = adder_9b[6:0] + divisor_mul_neg_2[(REM_W-1-2) -: 7];

assign adder_7b_spec[4] = adder_9b[6:0] + divisor_mul_pos_2[(REM_W-1-2) -: 7] + 7'd1;
assign adder_7b_spec[3] = adder_9b[6:0] + divisor_mul_pos_1[(REM_W-1-2) -: 7] + 7'd1;
assign adder_7b_spec[2] = adder_9b[6:0] + 7'd1;
assign adder_7b_spec[1] = adder_9b[6:0] + divisor_mul_neg_1[(REM_W-1-2) -: 7] + 7'd1;
assign adder_7b_spec[0] = adder_9b[6:0] + divisor_mul_neg_2[(REM_W-1-2) -: 7] + 7'd1;

assign adder_7b = 
  ({(7){quo_dig[1][4]}} & adder_7b_spec[4])
| ({(7){quo_dig[1][3]}} & adder_7b_spec[3])
| ({(7){quo_dig[1][2]}} & adder_7b_spec[2])
| ({(7){quo_dig[1][1]}} & adder_7b_spec[1])
| ({(7){quo_dig[1][0]}} & adder_7b_spec[0]);


// stage[2]
assign nxt_frac_rem_sum_spec_s2[4] = 
  {nxt_frac_rem_sum  [1][(REM_W-1)-2:0], 2'b0}
^ {nxt_frac_rem_carry[1][(REM_W-1)-2:0], 2'b0}
^ divisor_mul_pos_2;
assign nxt_frac_rem_carry_spec_s2[4] = {
	  ({nxt_frac_rem_sum  [1][(REM_W-1)-3:0], 2'b0} & {nxt_frac_rem_carry[1][(REM_W-1)-3:0], 2'b0})
	| ({nxt_frac_rem_sum  [1][(REM_W-1)-3:0], 2'b0} & divisor_mul_pos_2[(REM_W-1)-1:0])
	| ({nxt_frac_rem_carry[1][(REM_W-1)-3:0], 2'b0} & divisor_mul_pos_2[(REM_W-1)-1:0]),
	1'b0
};

assign nxt_frac_rem_sum_spec_s2[3] = 
  {nxt_frac_rem_sum  [1][(REM_W-1)-2:0], 2'b0}
^ {nxt_frac_rem_carry[1][(REM_W-1)-2:0], 2'b0}
^ divisor_mul_pos_1;
assign nxt_frac_rem_carry_spec_s2[3] = {
	  ({nxt_frac_rem_sum  [1][(REM_W-1)-3:0], 2'b0} & {nxt_frac_rem_carry[1][(REM_W-1)-3:0], 2'b0})
	| ({nxt_frac_rem_sum  [1][(REM_W-1)-3:0], 2'b0} & divisor_mul_pos_1[(REM_W-1)-1:0])
	| ({nxt_frac_rem_carry[1][(REM_W-1)-3:0], 2'b0} & divisor_mul_pos_1[(REM_W-1)-1:0]),
	1'b0
};

assign nxt_frac_rem_sum_spec_s2[2]   = {nxt_frac_rem_sum  [1][(REM_W-1)-2:0], 2'b0};
assign nxt_frac_rem_carry_spec_s2[2] = {nxt_frac_rem_carry[1][(REM_W-1)-2:0], 2'b0};

assign nxt_frac_rem_sum_spec_s2[1] = 
  {nxt_frac_rem_sum  [1][(REM_W-1)-2:0], 2'b0}
^ {nxt_frac_rem_carry[1][(REM_W-1)-2:0], 2'b0}
^ divisor_mul_neg_1;
assign nxt_frac_rem_carry_spec_s2[1] = {
	  ({nxt_frac_rem_sum  [1][(REM_W-1)-3:0], 2'b0} & {nxt_frac_rem_carry[1][(REM_W-1)-3:0], 2'b0})
	| ({nxt_frac_rem_sum  [1][(REM_W-1)-3:0], 2'b0} & divisor_mul_neg_1[(REM_W-1)-1:0])
	| ({nxt_frac_rem_carry[1][(REM_W-1)-3:0], 2'b0} & divisor_mul_neg_1[(REM_W-1)-1:0]),
	1'b1
};

assign nxt_frac_rem_sum_spec_s2[0] = 
  {nxt_frac_rem_sum  [1][(REM_W-1)-2:0], 2'b0}
^ {nxt_frac_rem_carry[1][(REM_W-1)-2:0], 2'b0}
^ divisor_mul_neg_2;
assign nxt_frac_rem_carry_spec_s2[0] = {
	  ({nxt_frac_rem_sum  [1][(REM_W-1)-3:0], 2'b0} & {nxt_frac_rem_carry[1][(REM_W-1)-3:0], 2'b0})
	| ({nxt_frac_rem_sum  [1][(REM_W-1)-3:0], 2'b0} & divisor_mul_neg_2[(REM_W-1)-1:0])
	| ({nxt_frac_rem_carry[1][(REM_W-1)-3:0], 2'b0} & divisor_mul_neg_2[(REM_W-1)-1:0]),
	1'b1
};

// QDS
r4_qds_v0
u_r4_qds_s2 (
	.rem_i(adder_7b[6:1]),
	.quo_dig_o(quo_dig[2])
);
assign nxt_pos_quo[2] = {nxt_pos_quo[1][51:0], quo_dig[2][0], quo_dig[2][1]};
assign nxt_neg_quo[2] = {nxt_neg_quo[1][51:0], quo_dig[2][4], quo_dig[2][3]};

assign nxt_frac_rem_sum[2] = 
  ({(REM_W){quo_dig[2][4]}} & nxt_frac_rem_sum_spec_s2[4])
| ({(REM_W){quo_dig[2][3]}} & nxt_frac_rem_sum_spec_s2[3])
| ({(REM_W){quo_dig[2][2]}} & nxt_frac_rem_sum_spec_s2[2])
| ({(REM_W){quo_dig[2][1]}} & nxt_frac_rem_sum_spec_s2[1])
| ({(REM_W){quo_dig[2][0]}} & nxt_frac_rem_sum_spec_s2[0]);
assign nxt_frac_rem_carry[2] = 
  ({(REM_W){quo_dig[2][4]}} & nxt_frac_rem_carry_spec_s2[4])
| ({(REM_W){quo_dig[2][3]}} & nxt_frac_rem_carry_spec_s2[3])
| ({(REM_W){quo_dig[2][2]}} & nxt_frac_rem_carry_spec_s2[2])
| ({(REM_W){quo_dig[2][1]}} & nxt_frac_rem_carry_spec_s2[1])
| ({(REM_W){quo_dig[2][0]}} & nxt_frac_rem_carry_spec_s2[0]);

// ================================================================================================================================================
// test signals
// ================================================================================================================================================
logic [REM_W-1:0] nxt_frac_rem [3-1:0];
assign nxt_frac_rem[0] = nxt_frac_rem_sum[0] + nxt_frac_rem_carry[0];
assign nxt_frac_rem[1] = nxt_frac_rem_sum[1] + nxt_frac_rem_carry[1];
assign nxt_frac_rem[2] = nxt_frac_rem_sum[2] + nxt_frac_rem_carry[2];

// ================================================================================================================================================
// Post
// ================================================================================================================================================


assign nr_frac_rem = frac_rem_sum_q + frac_rem_carry_q;

assign nr_frac_rem_plus_d = frac_rem_sum_q + frac_rem_carry_q + divisor_extended;

assign nr_quo    = pos_quo_iter_q - neg_quo_iter_q;
assign nr_quo_m1 = pos_quo_iter_q - neg_quo_iter_q - 54'd1;

assign final_quo = nr_frac_rem[REM_W-1] ? nr_quo_m1 : nr_quo;
assign fpdiv_frac_o = final_quo;

endmodule

