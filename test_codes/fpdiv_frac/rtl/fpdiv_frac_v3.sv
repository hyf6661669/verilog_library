// ========================================================================================================
// File Name			: fpdiv_frac_v3.sv
// Author				: HYF
// How to Contact		: hyf_sysu@qq.com
// Created Time    		: 2021-12-30 21:11:16
// Last Modified Time   : 2022-01-02 11:13:22
// ========================================================================================================
// Description	:
// Radix-64 SRT algorithm for the frac part of fpdiv.
// Here we use a faster implementation with larger area.
// rem[i+3][(REM_W-1)-2 -: 9] is calculated and stored in non_redundant form, so the generation of q[i+1]/q[i+2]
// should be faster.
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

module fpdiv_frac_v3 #(
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
	output logic [55-1:0] fpdiv_frac_o,

	input  logic clk,
	input  logic rst_n
);

// ================================================================================================================================================
// (local) parameters begin

// SPECULATIVE_MSB_W = "number of srt iteration per cycles" * 2 = 3 * 2 = 6
localparam SPECULATIVE_MSB_W = 6;

// 
localparam REM_W = 3 + 53 + 3 + 1;

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

logic [5-1:0] frac_rem_for_int_quo;
logic int_quo_is_pos_2;
logic [REM_W-1:0] scaled_D_extended;
logic [REM_W-1:0] scaled_D_mul_neg_2;
logic [REM_W-1:0] scaled_D_mul_neg_1;

logic [(REM_W+1)-1:0] frac_rem_sum_iter_init_pre;
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

logic nr_rem_6b_for_iter_en;
logic [6-1:0] nr_rem_6b_for_iter_d;
logic [6-1:0] nr_rem_6b_for_iter_q;
logic nr_rem_7b_for_iter_en;
logic [7-1:0] nr_rem_7b_for_iter_d;
logic [7-1:0] nr_rem_7b_for_iter_q;

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

// logic [REM_W-1:0] test_nxt_frac_rem_sum_spec_s0   [5-1:0];
// logic [REM_W-1:0] test_nxt_frac_rem_carry_spec_s0 [5-1:0];
// logic [REM_W-1:0] test_nxt_frac_rem_sum_s0;
// logic [REM_W-1:0] test_nxt_frac_rem_carry_s0;

logic divisor_en;
logic [58-1:0] divisor_d;
logic [58-1:0] divisor_q;
logic [REM_W-1:0] divisor_extended;
logic [REM_W-1:0] divisor_mul_neg_2;
logic [REM_W-1:0] divisor_mul_neg_1;
logic [REM_W-1:0] divisor_mul_pos_1;
logic [REM_W-1:0] divisor_mul_pos_2;

logic quo_iter_en;
logic [56-1:0] pos_quo_iter_d;
logic [56-1:0] pos_quo_iter_q;
logic [56-1:0] neg_quo_iter_d;
logic [56-1:0] neg_quo_iter_q;

// [4]: -2
// [3]: -1
// [2]: -0
// [1]: +1
// [0]: +2
logic [5-1:0] quo_dig [3-1:0];
logic [56-1:0] nxt_pos_quo [3-1:0];
logic [56-1:0] nxt_neg_quo [3-1:0];

logic [7-1:0] adder_7b_s0;
logic [7-1:0] adder_7b_s0_spec [5-1:0];

logic [7-1:0] adder_7b_s1;
logic [7-1:0] adder_7b_s1_spec [5-1:0];

logic [7-1:0] adder_7b_s2;
logic [7-1:0] adder_7b_s2_spec [5-1:0];

logic [7-1:0] nxt_nr_rem_6b_for_iter;
logic [7-1:0] nxt_nr_rem_6b_for_iter_spec [5-1:0];
logic [8-1:0] nxt_nr_rem_7b_for_iter;
logic [8-1:0] nxt_nr_rem_7b_for_iter_spec [5-1:0];


logic [REM_W-1:0] nr_frac_rem;
logic [REM_W-1:0] nr_frac_rem_plus_d;
logic [56-1:0] nr_quo;
logic [56-1:0] nr_quo_m1;
logic [55-1:0] final_quo;

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



// The 1st quo must be "+1/+2", we should choose it in the initialization step, so the latency could be reduced by 1.
// According to the QDS, we only need to do 5-bit CMP
assign frac_rem_sum_iter_init_pre = {2'b0, scaled_X_lt_scaled_D ? {scaled_X, 1'b0} : {1'b0, scaled_X}};
assign frac_rem_for_int_quo = frac_rem_sum_iter_init_pre[(REM_W+1-1)-2-1 -: 5];
assign int_quo_is_pos_2 = (frac_rem_for_int_quo >= 5'd12);

assign scaled_D_extended = {1'b0, scaled_D, 1'b0};
assign scaled_D_mul_neg_2 = ~{scaled_D_extended[(REM_W-1)-1:0], 1'b0};
assign scaled_D_mul_neg_1 = ~scaled_D_extended;

// For c[N-1:0] = a[N-1:0] - b[N-1:0], if a/b is in the true form, then let sum[N:0] = {a[N-1:0], 1'b1} + {~b[N-1:0], 1'b1}, c[N-1:0] = sum[N:1]
// Some examples:
// a = +15 = 0_1111, b = +6 = 0_0110 ->
// {a, 1} = 0_11111, {~b, 1} = 1_10011
// 0_11111 + 1_10011 = 0_10010: (0_10010)[5:1] = 0_1001 = +9
// a = +13 = 0_1101, b = +9 = 0_1001 ->
// {a, 1} = 0_11011, {~b, 1} = 1_01101
// 0_11011 + 1_01101 = 0_01000: (0_01000)[5:1] = 0_0100 = +4
// According to the QDS, the 1st quo_dig must be "+1", so we need to do "a_frac_i - b_frac_i".
// As a result, we should initialize "sum/carry" using the following value.
assign frac_rem_sum_iter_init = {frac_rem_sum_iter_init_pre[(REM_W+1-1)-2:0], 1'b1};
assign frac_rem_carry_iter_init = int_quo_is_pos_2 ? scaled_D_mul_neg_2[(REM_W-1):0] : scaled_D_mul_neg_1[(REM_W-1):0];


assign frac_rem_sum_en = fsm_q[FSM_PRE_0_BIT] | fsm_q[FSM_ITER_BIT];
assign frac_rem_sum_d  = fsm_q[FSM_PRE_0_BIT] ? frac_rem_sum_iter_init : nxt_frac_rem_sum[2];

assign frac_rem_carry_en = fsm_q[FSM_PRE_0_BIT] | fsm_q[FSM_ITER_BIT];
assign frac_rem_carry_d  = fsm_q[FSM_PRE_0_BIT] ? frac_rem_carry_iter_init : nxt_frac_rem_carry[2];

assign nr_rem_6b_for_iter_en = fsm_q[FSM_PRE_0_BIT] | fsm_q[FSM_ITER_BIT];
assign nr_rem_6b_for_iter_d  = 
fsm_q[FSM_PRE_0_BIT] ? (frac_rem_sum_iter_init[((REM_W-1)-2) -: 6] + frac_rem_carry_iter_init[((REM_W-1)-2) -: 6]) : 
nxt_nr_rem_6b_for_iter[6:1];

assign nr_rem_7b_for_iter_en = fsm_q[FSM_PRE_0_BIT] | fsm_q[FSM_ITER_BIT];
assign nr_rem_7b_for_iter_d  = 
fsm_q[FSM_PRE_0_BIT] ? (frac_rem_sum_iter_init[((REM_W-1)-2-2) -: 7] + frac_rem_carry_iter_init[((REM_W-1)-2-2) -: 7]) : 
nxt_nr_rem_7b_for_iter[7:1];

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
	if(nr_rem_6b_for_iter_en)
		nr_rem_6b_for_iter_q <= nr_rem_6b_for_iter_d;
	if(nr_rem_7b_for_iter_en)
		nr_rem_7b_for_iter_q <= nr_rem_7b_for_iter_d;

	if(iter_num_en)
		iter_num_q <= iter_num_d;
end

// ================================================================================================================================================
// SRT
// ================================================================================================================================================

assign quo_iter_en = fsm_q[FSM_PRE_0_BIT] | fsm_q[FSM_ITER_BIT];
assign pos_quo_iter_d = fsm_q[FSM_PRE_0_BIT] ? {54'b0, int_quo_is_pos_2, ~int_quo_is_pos_2} : nxt_pos_quo[2];
assign neg_quo_iter_d = fsm_q[FSM_PRE_0_BIT] ? '0 : nxt_neg_quo[2];
always_ff @(posedge clk) begin
	if(quo_iter_en) begin
		pos_quo_iter_q <= pos_quo_iter_d;
		neg_quo_iter_q <= neg_quo_iter_d;
	end
end

assign divisor_extended = {1'b0, divisor_q, 1'b0};
assign divisor_mul_neg_2 = ~{divisor_extended[(REM_W-1)-1:0], 1'b0};
assign divisor_mul_neg_1 = ~divisor_extended;
assign divisor_mul_pos_1 = divisor_extended;
assign divisor_mul_pos_2 = {divisor_extended[(REM_W-1)-1:0], 1'b0};

// stage[0]
// assign test_nxt_frac_rem_sum_spec_s0[4][(REM_W-1) -: 2] = 
//   frac_rem_sum_q  [(REM_W-1)-2 -: 2]
// ^ frac_rem_carry_q[(REM_W-1)-2 -: 2]
// ^ divisor_mul_pos_2[(REM_W-1) -: 2];
// assign test_nxt_frac_rem_sum_spec_s0[4][(REM_W-1)-2 -: 9] = {nr_rem_6b_for_iter_q, nr_rem_7b_for_iter_q[2:0]};
// assign test_nxt_frac_rem_sum_spec_s0[4][(REM_W-1)-2-9:0] = 
//   {frac_rem_sum_q  [(REM_W-1)-2-2-9:0], 2'b0}
// ^ {frac_rem_carry_q[(REM_W-1)-2-2-9:0], 2'b0}
// ^ divisor_mul_pos_2[(REM_W-1)-2-9:0];

// assign test_nxt_frac_rem_carry_spec_s0[4][(REM_W-1) -: 2] = {
// 	  ({frac_rem_sum_q  [(REM_W-1)-3 -: 1], nr_rem_6b_for_iter_q[5]} & {frac_rem_carry_q[(REM_W-1)-3 -: 1], 1'b0})
// 	| ({frac_rem_sum_q  [(REM_W-1)-3 -: 1], nr_rem_6b_for_iter_q[5]} & divisor_mul_pos_2[(REM_W-1)-1 -: 2])
// 	| ({frac_rem_carry_q[(REM_W-1)-3 -: 1], 1'b0} & divisor_mul_pos_2[(REM_W-1)-1 -: 2])
// };
// assign test_nxt_frac_rem_carry_spec_s0[4][(REM_W-1)-2 -: 9] = divisor_mul_pos_2[(REM_W-1)-1-2 -: 9];
// assign test_nxt_frac_rem_carry_spec_s0[4][(REM_W-1)-2-9:0] = {
// 	  ({frac_rem_sum_q  [(REM_W-1)-3-2-9:0], 2'b0} & {frac_rem_carry_q[(REM_W-1)-3-2-9:0], 2'b0})
// 	| ({frac_rem_sum_q  [(REM_W-1)-3-2-9:0], 2'b0} & divisor_mul_pos_2[(REM_W-1)-1-2-9:0])
// 	| ({frac_rem_carry_q[(REM_W-1)-3-2-9:0], 2'b0} & divisor_mul_pos_2[(REM_W-1)-1-2-9:0]), 
// 	1'b0
// };


// assign test_nxt_frac_rem_sum_spec_s0[3][(REM_W-1) -: 2] = 
//   frac_rem_sum_q  [(REM_W-1)-2 -: 2]
// ^ frac_rem_carry_q[(REM_W-1)-2 -: 2]
// ^ divisor_mul_pos_1[(REM_W-1) -: 2];
// assign test_nxt_frac_rem_sum_spec_s0[3][(REM_W-1)-2 -: 9] = {nr_rem_6b_for_iter_q, nr_rem_7b_for_iter_q[2:0]};
// assign test_nxt_frac_rem_sum_spec_s0[3][(REM_W-1)-2-9:0] = 
//   {frac_rem_sum_q  [(REM_W-1)-2-2-9:0], 2'b0}
// ^ {frac_rem_carry_q[(REM_W-1)-2-2-9:0], 2'b0}
// ^ divisor_mul_pos_1[(REM_W-1)-2-9:0];

// assign test_nxt_frac_rem_carry_spec_s0[3][(REM_W-1) -: 2] = {
// 	  ({frac_rem_sum_q  [(REM_W-1)-3 -: 1], nr_rem_6b_for_iter_q[5]} & {frac_rem_carry_q[(REM_W-1)-3 -: 1], 1'b0})
// 	| ({frac_rem_sum_q  [(REM_W-1)-3 -: 1], nr_rem_6b_for_iter_q[5]} & divisor_mul_pos_1[(REM_W-1)-1 -: 2])
// 	| ({frac_rem_carry_q[(REM_W-1)-3 -: 1], 1'b0} & divisor_mul_pos_1[(REM_W-1)-1 -: 2])
// };
// assign test_nxt_frac_rem_carry_spec_s0[3][(REM_W-1)-2 -: 9] = divisor_mul_pos_1[(REM_W-1)-1-2 -: 9];
// assign test_nxt_frac_rem_carry_spec_s0[3][(REM_W-1)-2-9:0] = {
// 	  ({frac_rem_sum_q  [(REM_W-1)-3-2-9:0], 2'b0} & {frac_rem_carry_q[(REM_W-1)-3-2-9:0], 2'b0})
// 	| ({frac_rem_sum_q  [(REM_W-1)-3-2-9:0], 2'b0} & divisor_mul_pos_1[(REM_W-1)-1-2-9:0])
// 	| ({frac_rem_carry_q[(REM_W-1)-3-2-9:0], 2'b0} & divisor_mul_pos_1[(REM_W-1)-1-2-9:0]), 
// 	1'b0
// };


// assign test_nxt_frac_rem_sum_spec_s0[2] = {
// 	frac_rem_sum_q[(REM_W-1)-2 -: 2], 
// 	nr_rem_6b_for_iter_q, nr_rem_7b_for_iter_q[2:0], 
// 	frac_rem_sum_q[(REM_W-1)-2-2-9:0],
// 	2'b0
// };

// assign test_nxt_frac_rem_carry_spec_s0[2] = {
// 	frac_rem_carry_q[(REM_W-1)-2 -: 2], 
// 	9'b0,
// 	frac_rem_carry_q[(REM_W-1)-2-2-9:0],
// 	2'b0
// };


// assign test_nxt_frac_rem_sum_spec_s0[1][(REM_W-1) -: 2] = 
//   frac_rem_sum_q  [(REM_W-1)-2 -: 2]
// ^ frac_rem_carry_q[(REM_W-1)-2 -: 2]
// ^ divisor_mul_neg_1[(REM_W-1) -: 2];
// assign test_nxt_frac_rem_sum_spec_s0[1][(REM_W-1)-2 -: 9] = {nr_rem_6b_for_iter_q, nr_rem_7b_for_iter_q[2:0]};
// assign test_nxt_frac_rem_sum_spec_s0[1][(REM_W-1)-2-9:0] = 
//   {frac_rem_sum_q  [(REM_W-1)-2-2-9:0], 2'b0}
// ^ {frac_rem_carry_q[(REM_W-1)-2-2-9:0], 2'b0}
// ^ divisor_mul_neg_1[(REM_W-1)-2-9:0];

// assign test_nxt_frac_rem_carry_spec_s0[1][(REM_W-1) -: 2] = {
// 	  ({frac_rem_sum_q  [(REM_W-1)-3 -: 1], nr_rem_6b_for_iter_q[5]} & {frac_rem_carry_q[(REM_W-1)-3 -: 1], 1'b0})
// 	| ({frac_rem_sum_q  [(REM_W-1)-3 -: 1], nr_rem_6b_for_iter_q[5]} & divisor_mul_neg_1[(REM_W-1)-1 -: 2])
// 	| ({frac_rem_carry_q[(REM_W-1)-3 -: 1], 1'b0} & divisor_mul_neg_1[(REM_W-1)-1 -: 2])
// };
// assign test_nxt_frac_rem_carry_spec_s0[1][(REM_W-1)-2 -: 9] = divisor_mul_neg_1[(REM_W-1)-1-2 -: 9];
// assign test_nxt_frac_rem_carry_spec_s0[1][(REM_W-1)-2-9:0] = {
// 	  ({frac_rem_sum_q  [(REM_W-1)-3-2-9:0], 2'b0} & {frac_rem_carry_q[(REM_W-1)-3-2-9:0], 2'b0})
// 	| ({frac_rem_sum_q  [(REM_W-1)-3-2-9:0], 2'b0} & divisor_mul_neg_1[(REM_W-1)-1-2-9:0])
// 	| ({frac_rem_carry_q[(REM_W-1)-3-2-9:0], 2'b0} & divisor_mul_neg_1[(REM_W-1)-1-2-9:0]), 
// 	1'b1
// };


// assign test_nxt_frac_rem_sum_spec_s0[0][(REM_W-1) -: 2] = 
//   frac_rem_sum_q  [(REM_W-1)-2 -: 2]
// ^ frac_rem_carry_q[(REM_W-1)-2 -: 2]
// ^ divisor_mul_neg_2[(REM_W-1) -: 2];
// assign test_nxt_frac_rem_sum_spec_s0[0][(REM_W-1)-2 -: 9] = {nr_rem_6b_for_iter_q, nr_rem_7b_for_iter_q[2:0]};
// assign test_nxt_frac_rem_sum_spec_s0[0][(REM_W-1)-2-9:0] = 
//   {frac_rem_sum_q  [(REM_W-1)-2-2-9:0], 2'b0}
// ^ {frac_rem_carry_q[(REM_W-1)-2-2-9:0], 2'b0}
// ^ divisor_mul_neg_2[(REM_W-1)-2-9:0];

// assign test_nxt_frac_rem_carry_spec_s0[0][(REM_W-1) -: 2] = {
// 	  ({frac_rem_sum_q  [(REM_W-1)-3 -: 1], nr_rem_6b_for_iter_q[5]} & {frac_rem_carry_q[(REM_W-1)-3 -: 1], 1'b0})
// 	| ({frac_rem_sum_q  [(REM_W-1)-3 -: 1], nr_rem_6b_for_iter_q[5]} & divisor_mul_neg_2[(REM_W-1)-1 -: 2])
// 	| ({frac_rem_carry_q[(REM_W-1)-3 -: 1], 1'b0} & divisor_mul_neg_2[(REM_W-1)-1 -: 2])
// };
// assign test_nxt_frac_rem_carry_spec_s0[0][(REM_W-1)-2 -: 9] = divisor_mul_neg_2[(REM_W-1)-1-2 -: 9];
// assign test_nxt_frac_rem_carry_spec_s0[0][(REM_W-1)-2-9:0] = {
// 	  ({frac_rem_sum_q  [(REM_W-1)-3-2-9:0], 2'b0} & {frac_rem_carry_q[(REM_W-1)-3-2-9:0], 2'b0})
// 	| ({frac_rem_sum_q  [(REM_W-1)-3-2-9:0], 2'b0} & divisor_mul_neg_2[(REM_W-1)-1-2-9:0])
// 	| ({frac_rem_carry_q[(REM_W-1)-3-2-9:0], 2'b0} & divisor_mul_neg_2[(REM_W-1)-1-2-9:0]), 
// 	1'b1
// };


// Original csa
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
r4_qds_v2 #(
	.QDS_ARCH(1)
) u_r4_qds_s0 (
	.rem_i(nr_rem_6b_for_iter_q),
	.quo_dig_o(quo_dig[0])
);
assign nxt_pos_quo[0] = {pos_quo_iter_q[53:0], quo_dig[0][0], quo_dig[0][1]};
assign nxt_neg_quo[0] = {neg_quo_iter_q[53:0], quo_dig[0][4], quo_dig[0][3]};

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


assign adder_7b_s0_spec[4] = nr_rem_7b_for_iter_q + divisor_mul_pos_2[(REM_W-1-2) -: 7];
assign adder_7b_s0_spec[3] = nr_rem_7b_for_iter_q + divisor_mul_pos_1[(REM_W-1-2) -: 7];
assign adder_7b_s0_spec[2] = nr_rem_7b_for_iter_q;
assign adder_7b_s0_spec[1] = nr_rem_7b_for_iter_q + divisor_mul_neg_1[(REM_W-1-2) -: 7];
assign adder_7b_s0_spec[0] = nr_rem_7b_for_iter_q + divisor_mul_neg_2[(REM_W-1-2) -: 7];

assign adder_7b_s0 = 
  ({(7){quo_dig[0][4]}} & adder_7b_s0_spec[4])
| ({(7){quo_dig[0][3]}} & adder_7b_s0_spec[3])
| ({(7){quo_dig[0][2]}} & adder_7b_s0_spec[2])
| ({(7){quo_dig[0][1]}} & adder_7b_s0_spec[1])
| ({(7){quo_dig[0][0]}} & adder_7b_s0_spec[0]);

assign adder_7b_s1_spec[4] = nxt_frac_rem_sum_spec_s0[4][(REM_W-1-4) -: 7] + nxt_frac_rem_carry_spec_s0[4][(REM_W-1-4) -: 7];
assign adder_7b_s1_spec[3] = nxt_frac_rem_sum_spec_s0[3][(REM_W-1-4) -: 7] + nxt_frac_rem_carry_spec_s0[3][(REM_W-1-4) -: 7];
assign adder_7b_s1_spec[2] = nxt_frac_rem_sum_spec_s0[2][(REM_W-1-4) -: 7] + nxt_frac_rem_carry_spec_s0[2][(REM_W-1-4) -: 7];
assign adder_7b_s1_spec[1] = nxt_frac_rem_sum_spec_s0[1][(REM_W-1-4) -: 7] + nxt_frac_rem_carry_spec_s0[1][(REM_W-1-4) -: 7];
assign adder_7b_s1_spec[0] = nxt_frac_rem_sum_spec_s0[0][(REM_W-1-4) -: 7] + nxt_frac_rem_carry_spec_s0[0][(REM_W-1-4) -: 7];

assign adder_7b_s1 = 
  ({(7){quo_dig[0][4]}} & adder_7b_s1_spec[4])
| ({(7){quo_dig[0][3]}} & adder_7b_s1_spec[3])
| ({(7){quo_dig[0][2]}} & adder_7b_s1_spec[2])
| ({(7){quo_dig[0][1]}} & adder_7b_s1_spec[1])
| ({(7){quo_dig[0][0]}} & adder_7b_s1_spec[0]);

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
// r4_qds_v2 #(
// 	.QDS_ARCH(1)
// ) u_r4_qds_s1 (
// 	.rem_i(adder_7b_s0[6:1]),
// 	.quo_dig_o(quo_dig[1])
// );

r4_qds_v2_with_speculation #(
	.QDS_ARCH(2)
) u_r4_qds_s1 (
	.rem_i(nr_rem_7b_for_iter_q),
	.divisor_mul_pos_2_i(divisor_mul_pos_2[(REM_W-1-2) -: 7]),
	.divisor_mul_pos_1_i(divisor_mul_pos_1[(REM_W-1-2) -: 7]),
	.divisor_mul_neg_1_i(divisor_mul_neg_1[(REM_W-1-2) -: 7]),
	.divisor_mul_neg_2_i(divisor_mul_neg_2[(REM_W-1-2) -: 7]),
	.prev_quo_dig_i(quo_dig[0]),
	.quo_dig_o(quo_dig[1])
);

assign nxt_pos_quo[1] = {nxt_pos_quo[0][53:0], quo_dig[1][0], quo_dig[1][1]};
assign nxt_neg_quo[1] = {nxt_neg_quo[0][53:0], quo_dig[1][4], quo_dig[1][3]};

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

assign adder_7b_s2_spec[4] = adder_7b_s1[6:0] + divisor_mul_pos_2[(REM_W-1-2) -: 7];
assign adder_7b_s2_spec[3] = adder_7b_s1[6:0] + divisor_mul_pos_1[(REM_W-1-2) -: 7];
assign adder_7b_s2_spec[2] = adder_7b_s1[6:0];
assign adder_7b_s2_spec[1] = adder_7b_s1[6:0] + divisor_mul_neg_1[(REM_W-1-2) -: 7];
assign adder_7b_s2_spec[0] = adder_7b_s1[6:0] + divisor_mul_neg_2[(REM_W-1-2) -: 7];

assign adder_7b_s2 = 
  ({(7){quo_dig[1][4]}} & adder_7b_s2_spec[4])
| ({(7){quo_dig[1][3]}} & adder_7b_s2_spec[3])
| ({(7){quo_dig[1][2]}} & adder_7b_s2_spec[2])
| ({(7){quo_dig[1][1]}} & adder_7b_s2_spec[1])
| ({(7){quo_dig[1][0]}} & adder_7b_s2_spec[0]);


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
// Get the non_redundant form
assign nxt_nr_rem_6b_for_iter_spec[4] = 
  nxt_frac_rem_sum  [1][((REM_W-1)-2-2) -: 7]
+ nxt_frac_rem_carry[1][((REM_W-1)-2-2) -: 7]
+ divisor_mul_pos_2    [((REM_W-1)-2) -: 7];
assign nxt_nr_rem_7b_for_iter_spec[4] = 
  nxt_frac_rem_sum  [1][((REM_W-1)-2-2-2) -: 8]
+ nxt_frac_rem_carry[1][((REM_W-1)-2-2-2) -: 8]
+ divisor_mul_pos_2    [((REM_W-1)-2-2) -: 8];


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
// Get the non_redundant form
assign nxt_nr_rem_6b_for_iter_spec[3] = 
  nxt_frac_rem_sum  [1][((REM_W-1)-2-2) -: 7]
+ nxt_frac_rem_carry[1][((REM_W-1)-2-2) -: 7]
+ divisor_mul_pos_1    [((REM_W-1)-2) -: 7];
assign nxt_nr_rem_7b_for_iter_spec[3] = 
  nxt_frac_rem_sum  [1][((REM_W-1)-2-2-2) -: 8]
+ nxt_frac_rem_carry[1][((REM_W-1)-2-2-2) -: 8]
+ divisor_mul_pos_1    [((REM_W-1)-2-2) -: 8];


assign nxt_frac_rem_sum_spec_s2[2]   = {nxt_frac_rem_sum  [1][(REM_W-1)-2:0], 2'b0};
assign nxt_frac_rem_carry_spec_s2[2] = {nxt_frac_rem_carry[1][(REM_W-1)-2:0], 2'b0};
// Get the non_redundant form
assign nxt_nr_rem_6b_for_iter_spec[2] = 
  nxt_frac_rem_sum  [1][((REM_W-1)-2-2) -: 7]
+ nxt_frac_rem_carry[1][((REM_W-1)-2-2) -: 7];
assign nxt_nr_rem_7b_for_iter_spec[2] = 
  nxt_frac_rem_sum  [1][((REM_W-1)-2-2-2) -: 8]
+ nxt_frac_rem_carry[1][((REM_W-1)-2-2-2) -: 8];

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
// Get the non_redundant form
assign nxt_nr_rem_6b_for_iter_spec[1] = 
  nxt_frac_rem_sum  [1][((REM_W-1)-2-2) -: 7]
+ nxt_frac_rem_carry[1][((REM_W-1)-2-2) -: 7]
+ divisor_mul_neg_1    [((REM_W-1)-2) -: 7];
assign nxt_nr_rem_7b_for_iter_spec[1] = 
  nxt_frac_rem_sum  [1][((REM_W-1)-2-2-2) -: 8]
+ nxt_frac_rem_carry[1][((REM_W-1)-2-2-2) -: 8]
+ divisor_mul_neg_1    [((REM_W-1)-2-2) -: 8];


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
// Get the non_redundant form
assign nxt_nr_rem_6b_for_iter_spec[0] = 
  nxt_frac_rem_sum  [1][((REM_W-1)-2-2) -: 7]
+ nxt_frac_rem_carry[1][((REM_W-1)-2-2) -: 7]
+ divisor_mul_neg_2    [((REM_W-1)-2) -: 7];
assign nxt_nr_rem_7b_for_iter_spec[0] = 
  nxt_frac_rem_sum  [1][((REM_W-1)-2-2-2) -: 8]
+ nxt_frac_rem_carry[1][((REM_W-1)-2-2-2) -: 8]
+ divisor_mul_neg_2    [((REM_W-1)-2-2) -: 8];

// QDS
r4_qds_v2 #(
	.QDS_ARCH(1)
) u_r4_qds_s2 (
	.rem_i(adder_7b_s2[6:1]),
	.quo_dig_o(quo_dig[2])
);
assign nxt_pos_quo[2] = {nxt_pos_quo[1][53:0], quo_dig[2][0], quo_dig[2][1]};
assign nxt_neg_quo[2] = {nxt_neg_quo[1][53:0], quo_dig[2][4], quo_dig[2][3]};

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

assign nxt_nr_rem_6b_for_iter = 
  ({(7){quo_dig[2][4]}} & nxt_nr_rem_6b_for_iter_spec[4])
| ({(7){quo_dig[2][3]}} & nxt_nr_rem_6b_for_iter_spec[3])
| ({(7){quo_dig[2][2]}} & nxt_nr_rem_6b_for_iter_spec[2])
| ({(7){quo_dig[2][1]}} & nxt_nr_rem_6b_for_iter_spec[1])
| ({(7){quo_dig[2][0]}} & nxt_nr_rem_6b_for_iter_spec[0]);
assign nxt_nr_rem_7b_for_iter = 
  ({(8){quo_dig[2][4]}} & nxt_nr_rem_7b_for_iter_spec[4])
| ({(8){quo_dig[2][3]}} & nxt_nr_rem_7b_for_iter_spec[3])
| ({(8){quo_dig[2][2]}} & nxt_nr_rem_7b_for_iter_spec[2])
| ({(8){quo_dig[2][1]}} & nxt_nr_rem_7b_for_iter_spec[1])
| ({(8){quo_dig[2][0]}} & nxt_nr_rem_7b_for_iter_spec[0]);

// ================================================================================================================================================
// test signals
// ================================================================================================================================================
logic [REM_W-1:0] nxt_frac_rem [3-1:0];
// logic [REM_W-1:0] test_nxt_frac_rem_s0;
assign nxt_frac_rem[0] = nxt_frac_rem_sum[0] + nxt_frac_rem_carry[0];
assign nxt_frac_rem[1] = nxt_frac_rem_sum[1] + nxt_frac_rem_carry[1];
assign nxt_frac_rem[2] = nxt_frac_rem_sum[2] + nxt_frac_rem_carry[2];

// assign test_nxt_frac_rem_s0 = test_nxt_frac_rem_sum_s0 + test_nxt_frac_rem_carry_s0;

// assign test_nxt_frac_rem_sum_s0 = 
//   ({(REM_W){quo_dig[0][4]}} & test_nxt_frac_rem_sum_spec_s0[4])
// | ({(REM_W){quo_dig[0][3]}} & test_nxt_frac_rem_sum_spec_s0[3])
// | ({(REM_W){quo_dig[0][2]}} & test_nxt_frac_rem_sum_spec_s0[2])
// | ({(REM_W){quo_dig[0][1]}} & test_nxt_frac_rem_sum_spec_s0[1])
// | ({(REM_W){quo_dig[0][0]}} & test_nxt_frac_rem_sum_spec_s0[0]);
// assign test_nxt_frac_rem_carry_s0 = 
//   ({(REM_W){quo_dig[0][4]}} & test_nxt_frac_rem_carry_spec_s0[4])
// | ({(REM_W){quo_dig[0][3]}} & test_nxt_frac_rem_carry_spec_s0[3])
// | ({(REM_W){quo_dig[0][2]}} & test_nxt_frac_rem_carry_spec_s0[2])
// | ({(REM_W){quo_dig[0][1]}} & test_nxt_frac_rem_carry_spec_s0[1])
// | ({(REM_W){quo_dig[0][0]}} & test_nxt_frac_rem_carry_spec_s0[0]);


// ================================================================================================================================================
// Post
// ================================================================================================================================================


assign nr_frac_rem = frac_rem_sum_q + frac_rem_carry_q;

assign nr_frac_rem_plus_d = frac_rem_sum_q + frac_rem_carry_q + divisor_extended;

assign nr_quo    = pos_quo_iter_q - neg_quo_iter_q;
assign nr_quo_m1 = pos_quo_iter_q - neg_quo_iter_q - 56'd1;

assign final_quo = nr_frac_rem[REM_W-1] ? nr_quo_m1[54:0] : nr_quo[54:0];
assign fpdiv_frac_o = final_quo;

endmodule

