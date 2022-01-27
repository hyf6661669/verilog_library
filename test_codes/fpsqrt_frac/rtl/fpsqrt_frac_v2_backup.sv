// ========================================================================================================
// File Name			: fpsqrt_frac_v2.sv
// Author				: HYF
// How to Contact		: hyf_sysu@qq.com
// Created Time    		: 2022-01-16 19:07:26
// Last Modified Time   : 2022-01-17 21:31:17
// ========================================================================================================
// Description	:
// Radix-64 SRT algorithm for the frac part of fpdiv.
// Add more speculation
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

module fpsqrt_frac_v2 #(
	// Put some parameters here, which can be changed by other modules
)(
	input  logic start_valid_i,
	output logic start_ready_o,
	input  logic flush_i,
	input  logic [53-1:0] op_i,
	input  logic is_odd_i,

	output logic finish_valid_o,
	input  logic finish_ready_i,
	output logic [54-1:0] fpsqrt_frac_o,

	input  logic clk,
	input  logic rst_n
);

// ================================================================================================================================================
// (local) parameters begin

localparam REM_W = 2 + 54;

localparam FP64_FRAC_W = 52 + 1;
localparam FP32_FRAC_W = 23 + 1;
localparam FP16_FRAC_W = 10 + 1;

localparam FP64_EXP_W = 11;
localparam FP32_EXP_W = 8;
localparam FP16_EXP_W = 5;

localparam FSM_W = 3;
localparam FSM_PRE_0 	= (1 << 0);
localparam FSM_ITER  	= (1 << 1);
localparam FSM_POST_0 	= (1 << 2);

localparam FSM_PRE_0_BIT 	= 0;
localparam FSM_ITER_BIT 	= 1;
localparam FSM_POST_0_BIT 	= 2;


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

logic rt_en;
logic [55-1:0] rt_d;
logic [55-1:0] rt_q;
logic rt_m1_en;
logic [55-1:0] rt_m1_d;
logic [55-1:0] rt_m1_q;
logic [55-1:0] nxt_rt [2-1:0];
logic [55-1:0] nxt_rt_m1 [2-1:0];
logic [5-1:0] nxt_rt_dig [2-1:0];
logic [3-1:0] rt_1th;
logic [55-1:0] rt_iter_init;
logic [55-1:0] rt_m1_iter_init;

logic mask_en;
logic [51-1:0] mask_d;
logic [51-1:0] mask_q;
logic [51-1:0] mask_csa_nxt_cycle;

logic [REM_W-1:0] mask_csa_ext [2-1:0];
logic [REM_W-1:0] mask_csa_neg_2 [2-1:0];
logic [REM_W-1:0] mask_csa_neg_1 [2-1:0];
logic [REM_W-1:0] mask_csa_pos_1 [2-1:0];
logic [REM_W-1:0] mask_csa_pos_2 [2-1:0];

logic [55-1:0] mask_rt_ext [2-1:0];
logic [55-1:0] mask_rt_neg_2 [2-1:0];
logic [55-1:0] mask_rt_neg_1 [2-1:0];
logic [55-1:0] mask_rt_neg_0 [2-1:0];
logic [55-1:0] mask_rt_pos_1 [2-1:0];
logic [55-1:0] mask_rt_pos_2 [2-1:0];
logic [55-1:0] mask_rt_m1_neg_2 [2-1:0];
logic [55-1:0] mask_rt_m1_neg_1 [2-1:0];
logic [55-1:0] mask_rt_m1_neg_0 [2-1:0];
logic [55-1:0] mask_rt_m1_pos_1 [2-1:0];
logic [55-1:0] mask_rt_m1_pos_2 [2-1:0];

logic [REM_W-1:0] f_r_s_iter_init_pre;
logic [REM_W-1:0] f_r_s_iter_init;
logic [REM_W-1:0] f_r_c_iter_init;
logic f_r_s_en;
logic [REM_W-1:0] f_r_s_d;
logic [REM_W-1:0] f_r_s_q;
logic f_r_c_en;
logic [REM_W-1:0] f_r_c_d;
logic [REM_W-1:0] f_r_c_q;
logic [REM_W-1:0] nxt_f_r_s [2-1:0];
logic [REM_W-1:0] nxt_f_r_c [2-1:0];
logic [REM_W-1:0] nxt_f_r_s_spec_s0 [5-1:0];
logic [REM_W-1:0] nxt_f_r_c_spec_s0 [5-1:0];
logic [REM_W-1:0] nxt_f_r_s_spec_s1 [5-1:0];
logic [REM_W-1:0] nxt_f_r_c_spec_s1 [5-1:0];

logic [REM_W-1:0] nr_f_r;

logic [REM_W-1:0] sqrt_csa_val_neg_2 [2-1:0];
logic [REM_W-1:0] sqrt_csa_val_neg_1 [2-1:0];
logic [REM_W-1:0] sqrt_csa_val_pos_1 [2-1:0];
logic [REM_W-1:0] sqrt_csa_val_pos_2 [2-1:0];

logic [8-1:0] adder_8b_for_s0_qds;
logic [8-1:0] adder_8b_for_s1_qds;

logic a0_iter_init;
logic a2_iter_init;
logic a3_iter_init;
logic a4_iter_init;

logic a0_spec_s0 [5-1:0];
logic a2_spec_s0 [5-1:0];
logic a3_spec_s0 [5-1:0];
logic a4_spec_s0 [5-1:0];

logic a0_spec_s1 [5-1:0];
logic a2_spec_s1 [5-1:0];
logic a3_spec_s1 [5-1:0];
logic a4_spec_s1 [5-1:0];

logic [7-1:0] m_neg_1 [2-1:0];
logic [7-1:0] m_neg_0 [2-1:0];
logic [7-1:0] m_pos_1 [2-1:0];
logic [7-1:0] m_pos_2 [2-1:0];

logic [7-1:0] m_neg_1_spec_s0 [5-1:0];
logic [7-1:0] m_neg_0_spec_s0 [5-1:0];
logic [7-1:0] m_pos_1_spec_s0 [5-1:0];
logic [7-1:0] m_pos_2_spec_s0 [5-1:0];

logic [7-1:0] m_neg_1_spec_s1 [5-1:0];
logic [7-1:0] m_neg_0_spec_s1 [5-1:0];
logic [7-1:0] m_pos_1_spec_s1 [5-1:0];
logic [7-1:0] m_pos_2_spec_s1 [5-1:0];

logic [7-1:0] m_neg_1_iter_init;
logic [7-1:0] m_neg_0_iter_init;
logic [7-1:0] m_pos_1_iter_init;
logic [7-1:0] m_pos_2_iter_init;

logic [7-1:0] m_neg_1_to_nxt_cycle;
logic [7-1:0] m_neg_0_to_nxt_cycle;
logic [7-1:0] m_pos_1_to_nxt_cycle;
logic [7-1:0] m_pos_2_to_nxt_cycle;

logic m_neg_1_for_nxt_cycle_s0_qds_en;
// [6:5] = 00, don't need to store it
logic [5-1:0] m_neg_1_for_nxt_cycle_s0_qds_d;
logic [5-1:0] m_neg_1_for_nxt_cycle_s0_qds_q;

logic m_neg_0_for_nxt_cycle_s0_qds_en;
// [6:4] = 000, don't need to store it
logic [4-1:0] m_neg_0_for_nxt_cycle_s0_qds_d;
logic [4-1:0] m_neg_0_for_nxt_cycle_s0_qds_q;

logic m_pos_1_for_nxt_cycle_s0_qds_en;
// [6:3] = 1111, don't need to store it
logic [3-1:0] m_pos_1_for_nxt_cycle_s0_qds_d;
logic [3-1:0] m_pos_1_for_nxt_cycle_s0_qds_q;

logic m_pos_2_for_nxt_cycle_s0_qds_en;
// [6:5] = 11, [0] = 0, don't need to store it
logic [4-1:0] m_pos_2_for_nxt_cycle_s0_qds_d;
logic [4-1:0] m_pos_2_for_nxt_cycle_s0_qds_q;

logic [8-1:0] adder_8b_iter_init;
logic [9-1:0] adder_9b_iter_init;
logic [9-1:0] adder_9b_for_nxt_cycle_s0_qds_spec [5-1:0];
logic [7-1:0] adder_7b_res_for_nxt_cycle_s0_qds;
logic [10-1:0] adder_10b_for_nxt_cycle_s1_qds_spec [5-1:0];
logic [9-1:0] adder_9b_res_for_nxt_cycle_s1_qds;

logic [9-1:0] adder_9b_for_s1_qds_spec [5-1:0];
logic [7-1:0] adder_7b_res_for_s1_qds;

logic nr_f_r_7b_for_nxt_cycle_s0_qds_en;
logic [7-1:0] nr_f_r_7b_for_nxt_cycle_s0_qds_d;
logic [7-1:0] nr_f_r_7b_for_nxt_cycle_s0_qds_q;
logic nr_f_r_9b_for_nxt_cycle_s1_qds_en;
logic [9-1:0] nr_f_r_9b_for_nxt_cycle_s1_qds_d;
logic [9-1:0] nr_f_r_9b_for_nxt_cycle_s1_qds_q;

logic [55-1:0] nxt_rt_spec_s0 [5-1:0];
logic [55-1:0] nxt_rt_spec_s1 [5-1:0];


// signals end
// ================================================================================================================================================

// ================================================================================================================================================
// FSM ctrl
// ================================================================================================================================================
always_comb begin
	unique case(fsm_q)
		FSM_PRE_0:
			fsm_d = start_valid_i ? FSM_ITER : FSM_PRE_0;
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

// even_exp, digit in (2 ^ -1) is 0: s[1] = -2, rt = {010, 52'b0}, rt_m1 = {001, 52'b0}
// even_exp, digit in (2 ^ -1) is 1: s[1] = -1, rt = {011, 52'b0}, rt_m1 = {010, 52'b0}
// odd_exp, digit in (2 ^ -1) is 0: s[1] = -1, rt = {011, 52'b0}, rt_m1 = {010, 52'b0}
// odd_exp, digit in (2 ^ -1) is 1: s[1] = 0, rt = {100, 52'b0}, rt_m1 = {011, 52'b0}

// [0]: s[1] = -2
// [1]: s[1] = -1
// [2]: s[1] =  0
assign rt_1th[0] = ({is_odd_i, op_i[51]} == 2'b00);
assign rt_1th[1] = ({is_odd_i, op_i[51]} == 2'b01) | ({is_odd_i, op_i[51]} == 2'b10);
assign rt_1th[2] = ({is_odd_i, op_i[51]} == 2'b11);

assign rt_iter_init = 
  ({(55){rt_1th[0]}} & {3'b010, 52'b0})
| ({(55){rt_1th[1]}} & {3'b011, 52'b0})
| ({(55){rt_1th[2]}} & {3'b100, 52'b0});
assign rt_m1_iter_init = 
  ({(55){rt_1th[0]}} & {3'b001, 52'b0})
| ({(55){rt_1th[1]}} & {3'b010, 52'b0})
| ({(55){rt_1th[2]}} & {3'b011, 52'b0});

assign f_r_s_iter_init_pre = {2'b11, is_odd_i ? {op_i[52:0], 1'b0} : {1'b0, op_i[52:0]}};
assign f_r_s_iter_init = {f_r_s_iter_init_pre[(REM_W-1)-2:0], 2'b0};
assign f_r_c_iter_init = 
  ({(56){rt_1th[0]}} & {2'b11,   {(REM_W - 2){1'b0}}})
| ({(56){rt_1th[1]}} & {4'b0111, {(REM_W - 4){1'b0}}})
| ({(56){rt_1th[2]}} & {(REM_W){1'b0}});

assign rt_en = start_handshaked | fsm_q[FSM_ITER_BIT];
assign rt_d  = fsm_q[FSM_PRE_0_BIT] ? rt_iter_init : nxt_rt[1];

assign rt_m1_en = start_handshaked | fsm_q[FSM_ITER_BIT];
assign rt_m1_d  = fsm_q[FSM_PRE_0_BIT] ? rt_m1_iter_init : nxt_rt_m1[1];

assign mask_en = start_handshaked | fsm_q[FSM_ITER_BIT];
// 先用51-bit的mask, 后面再考虑省寄存器的问题
assign mask_d  = fsm_q[FSM_PRE_0_BIT] ? {1'b1, 50'b0} : mask_csa_nxt_cycle;
assign mask_csa_nxt_cycle = mask_q >> 4;

assign f_r_s_en = start_handshaked | fsm_q[FSM_ITER_BIT];
assign f_r_s_d  = fsm_q[FSM_PRE_0_BIT] ? f_r_s_iter_init : nxt_f_r_s[1];

assign f_r_c_en = start_handshaked | fsm_q[FSM_ITER_BIT];
assign f_r_c_d  = fsm_q[FSM_PRE_0_BIT] ? f_r_c_iter_init : nxt_f_r_c[1];

assign iter_num_en = start_handshaked | fsm_q[FSM_ITER_BIT];
assign iter_num_d  = fsm_q[FSM_PRE_0_BIT] ? 4'd12 : (iter_num_q - 4'd1);

// "f_r_c_iter_init" would only have 4-bit non-zero value, so a 4-bit FA is enough here
// assign adder_8b_iter_init = f_r_s_iter_init[(REM_W-1) -: 8] + f_r_c_iter_init[(REM_W-1) -: 8];
assign adder_8b_iter_init = {f_r_s_iter_init[(REM_W-1) -: 4] + f_r_c_iter_init[(REM_W-1) -: 4], f_r_s_iter_init[(REM_W-1)-4 -: 4]};
assign nr_f_r_7b_for_nxt_cycle_s0_qds_en = start_handshaked | fsm_q[FSM_ITER_BIT];
assign nr_f_r_7b_for_nxt_cycle_s0_qds_d  = fsm_q[FSM_PRE_0_BIT] ? adder_8b_iter_init[7:1] : adder_7b_res_for_nxt_cycle_s0_qds;

// "f_r_c_iter_init * 4" would only have 2-bit non-zero value, so a 2-bit FA is enough here
// assign adder_9b_iter_init = f_r_s_iter_init[(REM_W-1)-2 -: 9] + f_r_c_iter_init[(REM_W-1)-2 -: 9];
assign adder_9b_iter_init = {f_r_s_iter_init[(REM_W-1)-2 -: 2] + f_r_c_iter_init[(REM_W-1)-2 -: 2], f_r_s_iter_init[(REM_W-1)-2-2 -: 7]};
assign nr_f_r_9b_for_nxt_cycle_s1_qds_en = start_handshaked | fsm_q[FSM_ITER_BIT];
assign nr_f_r_9b_for_nxt_cycle_s1_qds_d  = fsm_q[FSM_PRE_0_BIT] ? adder_9b_iter_init : adder_9b_res_for_nxt_cycle_s1_qds;


assign a0_iter_init = rt_iter_init[54];
assign a2_iter_init = rt_iter_init[52];
assign a3_iter_init = rt_iter_init[51];
assign a4_iter_init = rt_iter_init[50];
r4_qds_constants_generator 
u_r4_qds_constants_generator_iter_init (
	.a0_i(a0_iter_init),
	.a2_i(a2_iter_init),
	.a3_i(a3_iter_init),
	.a4_i(a4_iter_init),
	.m_neg_1_o(m_neg_1_iter_init),
	.m_neg_0_o(m_neg_0_iter_init),
	.m_pos_1_o(m_pos_1_iter_init),
	.m_pos_2_o(m_pos_2_iter_init)
);

assign m_neg_1_for_nxt_cycle_s0_qds_en = start_handshaked | fsm_q[FSM_ITER_BIT];
// [6:5] = 00, don't need to store it
assign m_neg_1_for_nxt_cycle_s0_qds_d  = fsm_q[FSM_PRE_0_BIT] ? m_neg_1_iter_init[4:0] : m_neg_1_to_nxt_cycle[4:0];

assign m_neg_0_for_nxt_cycle_s0_qds_en = start_handshaked | fsm_q[FSM_ITER_BIT];
// [6:4] = 000, don't need to store it
assign m_neg_0_for_nxt_cycle_s0_qds_d  = fsm_q[FSM_PRE_0_BIT] ? m_neg_0_iter_init[3:0] : m_neg_0_to_nxt_cycle[3:0];

assign m_pos_1_for_nxt_cycle_s0_qds_en = start_handshaked | fsm_q[FSM_ITER_BIT];
// [6:3] = 1111, don't need to store it
assign m_pos_1_for_nxt_cycle_s0_qds_d  = fsm_q[FSM_PRE_0_BIT] ? m_pos_1_iter_init[2:0] : m_pos_1_to_nxt_cycle[2:0];

assign m_pos_2_for_nxt_cycle_s0_qds_en = start_handshaked | fsm_q[FSM_ITER_BIT];
// [6:5] = 11, [0] = 0, don't need to store it
assign m_pos_2_for_nxt_cycle_s0_qds_d  = fsm_q[FSM_PRE_0_BIT] ? m_pos_2_iter_init[4:1] : m_pos_2_to_nxt_cycle[4:1];

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

	if(nr_f_r_7b_for_nxt_cycle_s0_qds_en)
		nr_f_r_7b_for_nxt_cycle_s0_qds_q <= nr_f_r_7b_for_nxt_cycle_s0_qds_d;
	if(nr_f_r_9b_for_nxt_cycle_s1_qds_en)
		nr_f_r_9b_for_nxt_cycle_s1_qds_q <= nr_f_r_9b_for_nxt_cycle_s1_qds_d;

	if(m_neg_1_for_nxt_cycle_s0_qds_en)
		m_neg_1_for_nxt_cycle_s0_qds_q <= m_neg_1_for_nxt_cycle_s0_qds_d;
	if(m_neg_0_for_nxt_cycle_s0_qds_en)
		m_neg_0_for_nxt_cycle_s0_qds_q <= m_neg_0_for_nxt_cycle_s0_qds_d;
	if(m_pos_1_for_nxt_cycle_s0_qds_en)
		m_pos_1_for_nxt_cycle_s0_qds_q <= m_pos_1_for_nxt_cycle_s0_qds_d;
	if(m_pos_2_for_nxt_cycle_s0_qds_en)
		m_pos_2_for_nxt_cycle_s0_qds_q <= m_pos_2_for_nxt_cycle_s0_qds_d;
end

assign final_iter = (iter_num_q == 4'd0);

// ================================================================================================================================================
// ITER
// ================================================================================================================================================

assign m_neg_1[0] = {2'b0, m_neg_1_for_nxt_cycle_s0_qds_q};
assign m_neg_0[0] = {3'b0, m_neg_0_for_nxt_cycle_s0_qds_q};
assign m_pos_1[0] = {4'b1111, m_pos_1_for_nxt_cycle_s0_qds_q};
assign m_pos_2[0] = {2'b11, m_pos_2_for_nxt_cycle_s0_qds_q, 1'b0};

assign nxt_rt_spec_s0[4] = rt_m1_q | mask_rt_neg_2[0];
assign nxt_rt_spec_s0[3] = rt_m1_q | mask_rt_neg_1[0];
assign nxt_rt_spec_s0[2] = rt_q;
assign nxt_rt_spec_s0[1] = rt_q    | mask_rt_pos_1[0];
assign nxt_rt_spec_s0[0] = rt_q    | mask_rt_pos_2[0];

assign a0_spec_s0[4] = nxt_rt_spec_s0[4][54];
assign a2_spec_s0[4] = nxt_rt_spec_s0[4][52];
assign a3_spec_s0[4] = nxt_rt_spec_s0[4][51];
assign a4_spec_s0[4] = nxt_rt_spec_s0[4][50];

assign a0_spec_s0[3] = nxt_rt_spec_s0[3][54];
assign a2_spec_s0[3] = nxt_rt_spec_s0[3][52];
assign a3_spec_s0[3] = nxt_rt_spec_s0[3][51];
assign a4_spec_s0[3] = nxt_rt_spec_s0[3][50];

assign a0_spec_s0[2] = nxt_rt_spec_s0[2][54];
assign a2_spec_s0[2] = nxt_rt_spec_s0[2][52];
assign a3_spec_s0[2] = nxt_rt_spec_s0[2][51];
assign a4_spec_s0[2] = nxt_rt_spec_s0[2][50];

assign a0_spec_s0[1] = nxt_rt_spec_s0[1][54];
assign a2_spec_s0[1] = nxt_rt_spec_s0[1][52];
assign a3_spec_s0[1] = nxt_rt_spec_s0[1][51];
assign a4_spec_s0[1] = nxt_rt_spec_s0[1][50];

assign a0_spec_s0[0] = nxt_rt_spec_s0[0][54];
assign a2_spec_s0[0] = nxt_rt_spec_s0[0][52];
assign a3_spec_s0[0] = nxt_rt_spec_s0[0][51];
assign a4_spec_s0[0] = nxt_rt_spec_s0[0][50];

r4_qds_constants_generator 
u_r4_qds_constants_generator_spec_s0_neg_2 (
	.a0_i(a0_spec_s0[4]),
	.a2_i(a2_spec_s0[4]),
	.a3_i(a3_spec_s0[4]),
	.a4_i(a4_spec_s0[4]),
	.m_neg_1_o(m_neg_1_spec_s0[4]),
	.m_neg_0_o(m_neg_0_spec_s0[4]),
	.m_pos_1_o(m_pos_1_spec_s0[4]),
	.m_pos_2_o(m_pos_2_spec_s0[4])
);

r4_qds_constants_generator 
u_r4_qds_constants_generator_spec_s0_neg_1 (
	.a0_i(a0_spec_s0[3]),
	.a2_i(a2_spec_s0[3]),
	.a3_i(a3_spec_s0[3]),
	.a4_i(a4_spec_s0[3]),
	.m_neg_1_o(m_neg_1_spec_s0[3]),
	.m_neg_0_o(m_neg_0_spec_s0[3]),
	.m_pos_1_o(m_pos_1_spec_s0[3]),
	.m_pos_2_o(m_pos_2_spec_s0[3])
);

r4_qds_constants_generator 
u_r4_qds_constants_generator_spec_s0_neg_0 (
	.a0_i(a0_spec_s0[2]),
	.a2_i(a2_spec_s0[2]),
	.a3_i(a3_spec_s0[2]),
	.a4_i(a4_spec_s0[2]),
	.m_neg_1_o(m_neg_1_spec_s0[2]),
	.m_neg_0_o(m_neg_0_spec_s0[2]),
	.m_pos_1_o(m_pos_1_spec_s0[2]),
	.m_pos_2_o(m_pos_2_spec_s0[2])
);

r4_qds_constants_generator 
u_r4_qds_constants_generator_spec_s0_pos_1 (
	.a0_i(a0_spec_s0[1]),
	.a2_i(a2_spec_s0[1]),
	.a3_i(a3_spec_s0[1]),
	.a4_i(a4_spec_s0[1]),
	.m_neg_1_o(m_neg_1_spec_s0[1]),
	.m_neg_0_o(m_neg_0_spec_s0[1]),
	.m_pos_1_o(m_pos_1_spec_s0[1]),
	.m_pos_2_o(m_pos_2_spec_s0[1])
);

r4_qds_constants_generator 
u_r4_qds_constants_generator_spec_s0_pos_2 (
	.a0_i(a0_spec_s0[0]),
	.a2_i(a2_spec_s0[0]),
	.a3_i(a3_spec_s0[0]),
	.a4_i(a4_spec_s0[0]),
	.m_neg_1_o(m_neg_1_spec_s0[0]),
	.m_neg_0_o(m_neg_0_spec_s0[0]),
	.m_pos_1_o(m_pos_1_spec_s0[0]),
	.m_pos_2_o(m_pos_2_spec_s0[0])
);

assign adder_8b_for_s0_qds = f_r_s_q[(REM_W-1) -: 8] + f_r_c_q[(REM_W-1) -: 8];
r4_qds
u_r4_qds_s0 (
	// .rem_i(adder_8b_for_s0_qds[7:1]),
	.rem_i(nr_f_r_7b_for_nxt_cycle_s0_qds_q),
	.m_neg_1_i(m_neg_1[0]),
	.m_neg_0_i(m_neg_0[0]),
	.m_pos_1_i(m_pos_1[0]),
	.m_pos_2_i(m_pos_2[0]),
	.rt_dig_o(nxt_rt_dig[0])
);

assign mask_csa_ext[0] = {5'b0, mask_q[50:0]};
assign mask_csa_neg_2[0] = (mask_csa_ext[0] << 2) | (mask_csa_ext[0] << 3);
assign mask_csa_neg_1[0] = mask_csa_ext[0] | (mask_csa_ext[0] << 1) | (mask_csa_ext[0] << 2);
assign mask_csa_pos_1[0] = mask_csa_ext[0];
assign mask_csa_pos_2[0] = mask_csa_ext[0] << 2;

assign sqrt_csa_val_neg_2[0] = ({1'b0, rt_m1_q} << 2) | mask_csa_neg_2[0];
assign sqrt_csa_val_neg_1[0] = ({1'b0, rt_m1_q} << 1) | mask_csa_neg_1[0];
assign sqrt_csa_val_pos_1[0] = ~(({1'b0, rt_q} << 1) | mask_csa_pos_1[0]);
assign sqrt_csa_val_pos_2[0] = ~(({1'b0, rt_q} << 2) | mask_csa_pos_2[0]);
// Here we assume nxt_rt_dig[0] = -2
assign nxt_f_r_s_spec_s0[4] = 
  {f_r_s_q[(REM_W-1)-2:0], 2'b0}
^ {f_r_c_q[(REM_W-1)-2:0], 2'b0}
^ sqrt_csa_val_neg_2[0];
assign nxt_f_r_c_spec_s0[4] = {
	  ({f_r_s_q[(REM_W-1)-3:0], 2'b0} & {f_r_c_q[(REM_W-1)-3:0], 2'b0})
	| ({f_r_s_q[(REM_W-1)-3:0], 2'b0} & sqrt_csa_val_neg_2[0][(REM_W-1)-1:0])
	| ({f_r_c_q[(REM_W-1)-3:0], 2'b0} & sqrt_csa_val_neg_2[0][(REM_W-1)-1:0]),
	1'b0
};

// Here we assume nxt_rt_dig[0] = -1
assign nxt_f_r_s_spec_s0[3] = 
  {f_r_s_q[(REM_W-1)-2:0], 2'b0}
^ {f_r_c_q[(REM_W-1)-2:0], 2'b0}
^ sqrt_csa_val_neg_1[0];
assign nxt_f_r_c_spec_s0[3] = {
	  ({f_r_s_q[(REM_W-1)-3:0], 2'b0} & {f_r_c_q[(REM_W-1)-3:0], 2'b0})
	| ({f_r_s_q[(REM_W-1)-3:0], 2'b0} & sqrt_csa_val_neg_1[0][(REM_W-1)-1:0])
	| ({f_r_c_q[(REM_W-1)-3:0], 2'b0} & sqrt_csa_val_neg_1[0][(REM_W-1)-1:0]),
	1'b0
};

// Here we assume nxt_rt_dig[0] = 0
assign nxt_f_r_s_spec_s0[2] = {f_r_s_q[(REM_W-1)-2:0], 2'b0};
assign nxt_f_r_c_spec_s0[2] = {f_r_c_q[(REM_W-1)-2:0], 2'b0};

// Here we assume nxt_rt_dig[0] = +1
assign nxt_f_r_s_spec_s0[1] = 
  {f_r_s_q[(REM_W-1)-2:0], 2'b0}
^ {f_r_c_q[(REM_W-1)-2:0], 2'b0}
^ sqrt_csa_val_pos_1[0];
assign nxt_f_r_c_spec_s0[1] = {
	  ({f_r_s_q[(REM_W-1)-3:0], 2'b0} & {f_r_c_q[(REM_W-1)-3:0], 2'b0})
	| ({f_r_s_q[(REM_W-1)-3:0], 2'b0} & sqrt_csa_val_pos_1[0][(REM_W-1)-1:0])
	| ({f_r_c_q[(REM_W-1)-3:0], 2'b0} & sqrt_csa_val_pos_1[0][(REM_W-1)-1:0]),
	1'b1
};

// Here we assume nxt_rt_dig[0] = +2
assign nxt_f_r_s_spec_s0[0] = 
  {f_r_s_q[(REM_W-1)-2:0], 2'b0}
^ {f_r_c_q[(REM_W-1)-2:0], 2'b0}
^ sqrt_csa_val_pos_2[0];
assign nxt_f_r_c_spec_s0[0] = {
	  ({f_r_s_q[(REM_W-1)-3:0], 2'b0} & {f_r_c_q[(REM_W-1)-3:0], 2'b0})
	| ({f_r_s_q[(REM_W-1)-3:0], 2'b0} & sqrt_csa_val_pos_2[0][(REM_W-1)-1:0])
	| ({f_r_c_q[(REM_W-1)-3:0], 2'b0} & sqrt_csa_val_pos_2[0][(REM_W-1)-1:0]),
	1'b1
};

// Get the non-redundant form, for stage[1].qds
assign adder_9b_for_s1_qds_spec[4] = nr_f_r_9b_for_nxt_cycle_s1_qds_q + sqrt_csa_val_neg_2[0][(REM_W-1) -: 9];

assign adder_9b_for_s1_qds_spec[3] = nr_f_r_9b_for_nxt_cycle_s1_qds_q + sqrt_csa_val_neg_1[0][(REM_W-1) -: 9];

assign adder_9b_for_s1_qds_spec[2] = nr_f_r_9b_for_nxt_cycle_s1_qds_q;

assign adder_9b_for_s1_qds_spec[1] = nr_f_r_9b_for_nxt_cycle_s1_qds_q + sqrt_csa_val_pos_1[0][(REM_W-1) -: 9];

assign adder_9b_for_s1_qds_spec[0] = nr_f_r_9b_for_nxt_cycle_s1_qds_q + sqrt_csa_val_pos_2[0][(REM_W-1) -: 9];

assign adder_7b_res_for_s1_qds = 
  ({(7){nxt_rt_dig[0][4]}} & adder_9b_for_s1_qds_spec[4][8:2])
| ({(7){nxt_rt_dig[0][3]}} & adder_9b_for_s1_qds_spec[3][8:2])
| ({(7){nxt_rt_dig[0][2]}} & adder_9b_for_s1_qds_spec[2][8:2])
| ({(7){nxt_rt_dig[0][1]}} & adder_9b_for_s1_qds_spec[1][8:2])
| ({(7){nxt_rt_dig[0][0]}} & adder_9b_for_s1_qds_spec[0][8:2]);


assign nxt_f_r_s[0] = 
  ({(REM_W){nxt_rt_dig[0][4]}} & nxt_f_r_s_spec_s0[4])
| ({(REM_W){nxt_rt_dig[0][3]}} & nxt_f_r_s_spec_s0[3])
| ({(REM_W){nxt_rt_dig[0][2]}} & nxt_f_r_s_spec_s0[2])
| ({(REM_W){nxt_rt_dig[0][1]}} & nxt_f_r_s_spec_s0[1])
| ({(REM_W){nxt_rt_dig[0][0]}} & nxt_f_r_s_spec_s0[0]);
assign nxt_f_r_c[0] = 
  ({(REM_W){nxt_rt_dig[0][4]}} & nxt_f_r_c_spec_s0[4])
| ({(REM_W){nxt_rt_dig[0][3]}} & nxt_f_r_c_spec_s0[3])
| ({(REM_W){nxt_rt_dig[0][2]}} & nxt_f_r_c_spec_s0[2])
| ({(REM_W){nxt_rt_dig[0][1]}} & nxt_f_r_c_spec_s0[1])
| ({(REM_W){nxt_rt_dig[0][0]}} & nxt_f_r_c_spec_s0[0]);

assign mask_rt_ext[0] = mask_csa_ext[0][54:0];

assign mask_rt_neg_2[0] = mask_rt_ext[0] << 1;
assign mask_rt_neg_1[0] = mask_rt_ext[0] | (mask_rt_ext[0] << 1);
assign mask_rt_neg_0[0] = '0;
assign mask_rt_pos_1[0] = mask_rt_ext[0];
assign mask_rt_pos_2[0] = mask_rt_ext[0] << 1;

assign mask_rt_m1_neg_2[0] = mask_rt_ext[0];
assign mask_rt_m1_neg_1[0] = mask_rt_ext[0] << 1;
assign mask_rt_m1_neg_0[0] = mask_rt_ext[0] | (mask_rt_ext[0] << 1);
assign mask_rt_m1_pos_1[0] = '0;
assign mask_rt_m1_pos_2[0] = mask_rt_ext[0];

assign nxt_rt[0] = 
  ({(55){nxt_rt_dig[0][4]}} & (rt_m1_q | mask_rt_neg_2[0]))
| ({(55){nxt_rt_dig[0][3]}} & (rt_m1_q | mask_rt_neg_1[0]))
| ({(55){nxt_rt_dig[0][2]}} & rt_q)
| ({(55){nxt_rt_dig[0][1]}} & (rt_q    | mask_rt_pos_1[0]))
| ({(55){nxt_rt_dig[0][0]}} & (rt_q    | mask_rt_pos_2[0]));
assign nxt_rt_m1[0] = 
  ({(55){nxt_rt_dig[0][4]}} & (rt_m1_q | mask_rt_m1_neg_2[0]))
| ({(55){nxt_rt_dig[0][3]}} & (rt_m1_q | mask_rt_m1_neg_1[0]))
| ({(55){nxt_rt_dig[0][2]}} & (rt_m1_q | mask_rt_m1_neg_0[0]))
| ({(55){nxt_rt_dig[0][1]}} & rt_q)
| ({(55){nxt_rt_dig[0][0]}} & (rt_q    | mask_rt_m1_pos_2[0]));

assign m_neg_1[1] = 
  ({(7){nxt_rt_dig[0][4]}} & m_neg_1_spec_s0[4])
| ({(7){nxt_rt_dig[0][3]}} & m_neg_1_spec_s0[3])
| ({(7){nxt_rt_dig[0][2]}} & m_neg_1_spec_s0[2])
| ({(7){nxt_rt_dig[0][1]}} & m_neg_1_spec_s0[1])
| ({(7){nxt_rt_dig[0][0]}} & m_neg_1_spec_s0[0]);
assign m_neg_0[1] = 
  ({(7){nxt_rt_dig[0][4]}} & m_neg_0_spec_s0[4])
| ({(7){nxt_rt_dig[0][3]}} & m_neg_0_spec_s0[3])
| ({(7){nxt_rt_dig[0][2]}} & m_neg_0_spec_s0[2])
| ({(7){nxt_rt_dig[0][1]}} & m_neg_0_spec_s0[1])
| ({(7){nxt_rt_dig[0][0]}} & m_neg_0_spec_s0[0]);
assign m_pos_1[1] = 
  ({(7){nxt_rt_dig[0][4]}} & m_pos_1_spec_s0[4])
| ({(7){nxt_rt_dig[0][3]}} & m_pos_1_spec_s0[3])
| ({(7){nxt_rt_dig[0][2]}} & m_pos_1_spec_s0[2])
| ({(7){nxt_rt_dig[0][1]}} & m_pos_1_spec_s0[1])
| ({(7){nxt_rt_dig[0][0]}} & m_pos_1_spec_s0[0]);
assign m_pos_2[1] = 
  ({(7){nxt_rt_dig[0][4]}} & m_pos_2_spec_s0[4])
| ({(7){nxt_rt_dig[0][3]}} & m_pos_2_spec_s0[3])
| ({(7){nxt_rt_dig[0][2]}} & m_pos_2_spec_s0[2])
| ({(7){nxt_rt_dig[0][1]}} & m_pos_2_spec_s0[1])
| ({(7){nxt_rt_dig[0][0]}} & m_pos_2_spec_s0[0]);

assign adder_8b_for_s1_qds = nxt_f_r_s[0][(REM_W-1) -: 8] + nxt_f_r_c[0][(REM_W-1) -: 8];
r4_qds
u_r4_qds_s1 (
	// .rem_i(adder_8b_for_s1_qds[7:1]),
	.rem_i(adder_7b_res_for_s1_qds),
	.m_neg_1_i(m_neg_1[1]),
	.m_neg_0_i(m_neg_0[1]),
	.m_pos_1_i(m_pos_1[1]),
	.m_pos_2_i(m_pos_2[1]),
	.rt_dig_o(nxt_rt_dig[1])
);

// Get the non-redundant form, for stage[0].qds in the nxt cycle
assign adder_9b_for_nxt_cycle_s0_qds_spec[4] = 
  nxt_f_r_s[0][(REM_W-1)-2 -: 9]
+ nxt_f_r_c[0][(REM_W-1)-2 -: 9]
+ sqrt_csa_val_neg_2[1][(REM_W-1) -: 9];

assign adder_9b_for_nxt_cycle_s0_qds_spec[3] = 
  nxt_f_r_s[0][(REM_W-1)-2 -: 9]
+ nxt_f_r_c[0][(REM_W-1)-2 -: 9]
+ sqrt_csa_val_neg_1[1][(REM_W-1) -: 9];

assign adder_9b_for_nxt_cycle_s0_qds_spec[2] = 
  nxt_f_r_s[0][(REM_W-1)-2 -: 9]
+ nxt_f_r_c[0][(REM_W-1)-2 -: 9];

assign adder_9b_for_nxt_cycle_s0_qds_spec[1] = 
  nxt_f_r_s[0][(REM_W-1)-2 -: 9]
+ nxt_f_r_c[0][(REM_W-1)-2 -: 9]
+ sqrt_csa_val_pos_1[1][(REM_W-1) -: 9];

assign adder_9b_for_nxt_cycle_s0_qds_spec[0] = 
  nxt_f_r_s[0][(REM_W-1)-2 -: 9]
+ nxt_f_r_c[0][(REM_W-1)-2 -: 9]
+ sqrt_csa_val_pos_2[1][(REM_W-1) -: 9];

assign adder_7b_res_for_nxt_cycle_s0_qds = 
  ({(7){nxt_rt_dig[1][4]}} & adder_9b_for_nxt_cycle_s0_qds_spec[4][8:2])
| ({(7){nxt_rt_dig[1][3]}} & adder_9b_for_nxt_cycle_s0_qds_spec[3][8:2])
| ({(7){nxt_rt_dig[1][2]}} & adder_9b_for_nxt_cycle_s0_qds_spec[2][8:2])
| ({(7){nxt_rt_dig[1][1]}} & adder_9b_for_nxt_cycle_s0_qds_spec[1][8:2])
| ({(7){nxt_rt_dig[1][0]}} & adder_9b_for_nxt_cycle_s0_qds_spec[0][8:2]);

// Get the non-redundant form, for stage[1].qds in the nxt cycle
assign adder_10b_for_nxt_cycle_s1_qds_spec[4] = 
  nxt_f_r_s[0][(REM_W-1)-2-2 -: 10]
+ nxt_f_r_c[0][(REM_W-1)-2-2 -: 10]
+ sqrt_csa_val_neg_2[1][(REM_W-1)-2 -: 10];

assign adder_10b_for_nxt_cycle_s1_qds_spec[3] = 
  nxt_f_r_s[0][(REM_W-1)-2-2 -: 10]
+ nxt_f_r_c[0][(REM_W-1)-2-2 -: 10]
+ sqrt_csa_val_neg_1[1][(REM_W-1)-2 -: 10];

assign adder_10b_for_nxt_cycle_s1_qds_spec[2] = 
  nxt_f_r_s[0][(REM_W-1)-2-2 -: 10]
+ nxt_f_r_c[0][(REM_W-1)-2-2 -: 10];

assign adder_10b_for_nxt_cycle_s1_qds_spec[1] = 
  nxt_f_r_s[0][(REM_W-1)-2-2 -: 10]
+ nxt_f_r_c[0][(REM_W-1)-2-2 -: 10]
+ sqrt_csa_val_pos_1[1][(REM_W-1)-2 -: 10];

assign adder_10b_for_nxt_cycle_s1_qds_spec[0] = 
  nxt_f_r_s[0][(REM_W-1)-2-2 -: 10]
+ nxt_f_r_c[0][(REM_W-1)-2-2 -: 10]
+ sqrt_csa_val_pos_2[1][(REM_W-1)-2 -: 10];

assign adder_9b_res_for_nxt_cycle_s1_qds = 
  ({(9){nxt_rt_dig[1][4]}} & adder_10b_for_nxt_cycle_s1_qds_spec[4][9:1])
| ({(9){nxt_rt_dig[1][3]}} & adder_10b_for_nxt_cycle_s1_qds_spec[3][9:1])
| ({(9){nxt_rt_dig[1][2]}} & adder_10b_for_nxt_cycle_s1_qds_spec[2][9:1])
| ({(9){nxt_rt_dig[1][1]}} & adder_10b_for_nxt_cycle_s1_qds_spec[1][9:1])
| ({(9){nxt_rt_dig[1][0]}} & adder_10b_for_nxt_cycle_s1_qds_spec[0][9:1]);


assign nxt_rt_spec_s1[4] = nxt_rt_m1[0] | mask_rt_neg_2[1];
assign nxt_rt_spec_s1[3] = nxt_rt_m1[0] | mask_rt_neg_1[1];
assign nxt_rt_spec_s1[2] = nxt_rt[0];
assign nxt_rt_spec_s1[1] = nxt_rt[0]    | mask_rt_pos_1[1];
assign nxt_rt_spec_s1[0] = nxt_rt[0]    | mask_rt_pos_2[1];

assign a0_spec_s1[4] = nxt_rt_spec_s1[4][54];
assign a2_spec_s1[4] = nxt_rt_spec_s1[4][52];
assign a3_spec_s1[4] = nxt_rt_spec_s1[4][51];
assign a4_spec_s1[4] = nxt_rt_spec_s1[4][50];

assign a0_spec_s1[3] = nxt_rt_spec_s1[3][54];
assign a2_spec_s1[3] = nxt_rt_spec_s1[3][52];
assign a3_spec_s1[3] = nxt_rt_spec_s1[3][51];
assign a4_spec_s1[3] = nxt_rt_spec_s1[3][50];

assign a0_spec_s1[2] = nxt_rt_spec_s1[2][54];
assign a2_spec_s1[2] = nxt_rt_spec_s1[2][52];
assign a3_spec_s1[2] = nxt_rt_spec_s1[2][51];
assign a4_spec_s1[2] = nxt_rt_spec_s1[2][50];

assign a0_spec_s1[1] = nxt_rt_spec_s1[1][54];
assign a2_spec_s1[1] = nxt_rt_spec_s1[1][52];
assign a3_spec_s1[1] = nxt_rt_spec_s1[1][51];
assign a4_spec_s1[1] = nxt_rt_spec_s1[1][50];

assign a0_spec_s1[0] = nxt_rt_spec_s1[0][54];
assign a2_spec_s1[0] = nxt_rt_spec_s1[0][52];
assign a3_spec_s1[0] = nxt_rt_spec_s1[0][51];
assign a4_spec_s1[0] = nxt_rt_spec_s1[0][50];

r4_qds_constants_generator 
u_r4_qds_constants_generator_spec_s1_neg_2 (
	.a0_i(a0_spec_s1[4]),
	.a2_i(a2_spec_s1[4]),
	.a3_i(a3_spec_s1[4]),
	.a4_i(a4_spec_s1[4]),
	.m_neg_1_o(m_neg_1_spec_s1[4]),
	.m_neg_0_o(m_neg_0_spec_s1[4]),
	.m_pos_1_o(m_pos_1_spec_s1[4]),
	.m_pos_2_o(m_pos_2_spec_s1[4])
);

r4_qds_constants_generator 
u_r4_qds_constants_generator_spec_s1_neg_1 (
	.a0_i(a0_spec_s1[3]),
	.a2_i(a2_spec_s1[3]),
	.a3_i(a3_spec_s1[3]),
	.a4_i(a4_spec_s1[3]),
	.m_neg_1_o(m_neg_1_spec_s1[3]),
	.m_neg_0_o(m_neg_0_spec_s1[3]),
	.m_pos_1_o(m_pos_1_spec_s1[3]),
	.m_pos_2_o(m_pos_2_spec_s1[3])
);

r4_qds_constants_generator 
u_r4_qds_constants_generator_spec_s1_neg_0 (
	.a0_i(a0_spec_s1[2]),
	.a2_i(a2_spec_s1[2]),
	.a3_i(a3_spec_s1[2]),
	.a4_i(a4_spec_s1[2]),
	.m_neg_1_o(m_neg_1_spec_s1[2]),
	.m_neg_0_o(m_neg_0_spec_s1[2]),
	.m_pos_1_o(m_pos_1_spec_s1[2]),
	.m_pos_2_o(m_pos_2_spec_s1[2])
);

r4_qds_constants_generator 
u_r4_qds_constants_generator_spec_s1_pos_1 (
	.a0_i(a0_spec_s1[1]),
	.a2_i(a2_spec_s1[1]),
	.a3_i(a3_spec_s1[1]),
	.a4_i(a4_spec_s1[1]),
	.m_neg_1_o(m_neg_1_spec_s1[1]),
	.m_neg_0_o(m_neg_0_spec_s1[1]),
	.m_pos_1_o(m_pos_1_spec_s1[1]),
	.m_pos_2_o(m_pos_2_spec_s1[1])
);

r4_qds_constants_generator 
u_r4_qds_constants_generator_spec_s1_pos_2 (
	.a0_i(a0_spec_s1[0]),
	.a2_i(a2_spec_s1[0]),
	.a3_i(a3_spec_s1[0]),
	.a4_i(a4_spec_s1[0]),
	.m_neg_1_o(m_neg_1_spec_s1[0]),
	.m_neg_0_o(m_neg_0_spec_s1[0]),
	.m_pos_1_o(m_pos_1_spec_s1[0]),
	.m_pos_2_o(m_pos_2_spec_s1[0])
);

assign m_neg_1_to_nxt_cycle = 
  ({(7){nxt_rt_dig[1][4]}} & m_neg_1_spec_s1[4])
| ({(7){nxt_rt_dig[1][3]}} & m_neg_1_spec_s1[3])
| ({(7){nxt_rt_dig[1][2]}} & m_neg_1_spec_s1[2])
| ({(7){nxt_rt_dig[1][1]}} & m_neg_1_spec_s1[1])
| ({(7){nxt_rt_dig[1][0]}} & m_neg_1_spec_s1[0]);
assign m_neg_0_to_nxt_cycle = 
  ({(7){nxt_rt_dig[1][4]}} & m_neg_0_spec_s1[4])
| ({(7){nxt_rt_dig[1][3]}} & m_neg_0_spec_s1[3])
| ({(7){nxt_rt_dig[1][2]}} & m_neg_0_spec_s1[2])
| ({(7){nxt_rt_dig[1][1]}} & m_neg_0_spec_s1[1])
| ({(7){nxt_rt_dig[1][0]}} & m_neg_0_spec_s1[0]);
assign m_pos_1_to_nxt_cycle = 
  ({(7){nxt_rt_dig[1][4]}} & m_pos_1_spec_s1[4])
| ({(7){nxt_rt_dig[1][3]}} & m_pos_1_spec_s1[3])
| ({(7){nxt_rt_dig[1][2]}} & m_pos_1_spec_s1[2])
| ({(7){nxt_rt_dig[1][1]}} & m_pos_1_spec_s1[1])
| ({(7){nxt_rt_dig[1][0]}} & m_pos_1_spec_s1[0]);
assign m_pos_2_to_nxt_cycle = 
  ({(7){nxt_rt_dig[1][4]}} & m_pos_2_spec_s1[4])
| ({(7){nxt_rt_dig[1][3]}} & m_pos_2_spec_s1[3])
| ({(7){nxt_rt_dig[1][2]}} & m_pos_2_spec_s1[2])
| ({(7){nxt_rt_dig[1][1]}} & m_pos_2_spec_s1[1])
| ({(7){nxt_rt_dig[1][0]}} & m_pos_2_spec_s1[0]);

assign mask_csa_ext[1] = mask_csa_ext[0] >> 2;
assign mask_csa_neg_2[1] = (mask_csa_ext[1] << 2) | (mask_csa_ext[1] << 3);
assign mask_csa_neg_1[1] = mask_csa_ext[1] | (mask_csa_ext[1] << 1) | (mask_csa_ext[1] << 2);
assign mask_csa_pos_1[1] = mask_csa_ext[1];
assign mask_csa_pos_2[1] = mask_csa_ext[1] << 2;

assign sqrt_csa_val_neg_2[1] = ({1'b0, nxt_rt_m1[0]} << 2) | mask_csa_neg_2[1];
assign sqrt_csa_val_neg_1[1] = ({1'b0, nxt_rt_m1[0]} << 1) | mask_csa_neg_1[1];
assign sqrt_csa_val_pos_1[1] = ~(({1'b0, nxt_rt[0]} << 1) | mask_csa_pos_1[1]);
assign sqrt_csa_val_pos_2[1] = ~(({1'b0, nxt_rt[0]} << 2) | mask_csa_pos_2[1]);
// Here we assume nxt_rt_dig[1] = -2
assign nxt_f_r_s_spec_s1[4] = 
  {nxt_f_r_s[0][(REM_W-1)-2:0], 2'b0}
^ {nxt_f_r_c[0][(REM_W-1)-2:0], 2'b0}
^ sqrt_csa_val_neg_2[1];
assign nxt_f_r_c_spec_s1[4] = {
	  ({nxt_f_r_s[0][(REM_W-1)-3:0], 2'b0} & {nxt_f_r_c[0][(REM_W-1)-3:0], 2'b0})
	| ({nxt_f_r_s[0][(REM_W-1)-3:0], 2'b0} & sqrt_csa_val_neg_2[1][(REM_W-1)-1:0])
	| ({nxt_f_r_c[0][(REM_W-1)-3:0], 2'b0} & sqrt_csa_val_neg_2[1][(REM_W-1)-1:0]),
	1'b0
};

// Here we assume nxt_rt_dig[1] = -1
assign nxt_f_r_s_spec_s1[3] = 
  {nxt_f_r_s[0][(REM_W-1)-2:0], 2'b0}
^ {nxt_f_r_c[0][(REM_W-1)-2:0], 2'b0}
^ sqrt_csa_val_neg_1[1];
assign nxt_f_r_c_spec_s1[3] = {
	  ({nxt_f_r_s[0][(REM_W-1)-3:0], 2'b0} & {nxt_f_r_c[0][(REM_W-1)-3:0], 2'b0})
	| ({nxt_f_r_s[0][(REM_W-1)-3:0], 2'b0} & sqrt_csa_val_neg_1[1][(REM_W-1)-1:0])
	| ({nxt_f_r_c[0][(REM_W-1)-3:0], 2'b0} & sqrt_csa_val_neg_1[1][(REM_W-1)-1:0]),
	1'b0
};

// Here we assume nxt_rt_dig[1] = 0
assign nxt_f_r_s_spec_s1[2] = {nxt_f_r_s[0][(REM_W-1)-2:0], 2'b0};
assign nxt_f_r_c_spec_s1[2] = {nxt_f_r_c[0][(REM_W-1)-2:0], 2'b0};

// Here we assume nxt_rt_dig[1] = +1
assign nxt_f_r_s_spec_s1[1] = 
  {nxt_f_r_s[0][(REM_W-1)-2:0], 2'b0}
^ {nxt_f_r_c[0][(REM_W-1)-2:0], 2'b0}
^ sqrt_csa_val_pos_1[1];
assign nxt_f_r_c_spec_s1[1] = {
	  ({nxt_f_r_s[0][(REM_W-1)-3:0], 2'b0} & {nxt_f_r_c[0][(REM_W-1)-3:0], 2'b0})
	| ({nxt_f_r_s[0][(REM_W-1)-3:0], 2'b0} & sqrt_csa_val_pos_1[1][(REM_W-1)-1:0])
	| ({nxt_f_r_c[0][(REM_W-1)-3:0], 2'b0} & sqrt_csa_val_pos_1[1][(REM_W-1)-1:0]),
	1'b1
};

// Here we assume nxt_rt_dig[1] = +2
assign nxt_f_r_s_spec_s1[0] = 
  {nxt_f_r_s[0][(REM_W-1)-2:0], 2'b0}
^ {nxt_f_r_c[0][(REM_W-1)-2:0], 2'b0}
^ sqrt_csa_val_pos_2[1];
assign nxt_f_r_c_spec_s1[0] = {
	  ({nxt_f_r_s[0][(REM_W-1)-3:0], 2'b0} & {nxt_f_r_c[0][(REM_W-1)-3:0], 2'b0})
	| ({nxt_f_r_s[0][(REM_W-1)-3:0], 2'b0} & sqrt_csa_val_pos_2[1][(REM_W-1)-1:0])
	| ({nxt_f_r_c[0][(REM_W-1)-3:0], 2'b0} & sqrt_csa_val_pos_2[1][(REM_W-1)-1:0]),
	1'b1
};

assign nxt_f_r_s[1] = 
  ({(REM_W){nxt_rt_dig[1][4]}} & nxt_f_r_s_spec_s1[4])
| ({(REM_W){nxt_rt_dig[1][3]}} & nxt_f_r_s_spec_s1[3])
| ({(REM_W){nxt_rt_dig[1][2]}} & nxt_f_r_s_spec_s1[2])
| ({(REM_W){nxt_rt_dig[1][1]}} & nxt_f_r_s_spec_s1[1])
| ({(REM_W){nxt_rt_dig[1][0]}} & nxt_f_r_s_spec_s1[0]);
assign nxt_f_r_c[1] = 
  ({(REM_W){nxt_rt_dig[1][4]}} & nxt_f_r_c_spec_s1[4])
| ({(REM_W){nxt_rt_dig[1][3]}} & nxt_f_r_c_spec_s1[3])
| ({(REM_W){nxt_rt_dig[1][2]}} & nxt_f_r_c_spec_s1[2])
| ({(REM_W){nxt_rt_dig[1][1]}} & nxt_f_r_c_spec_s1[1])
| ({(REM_W){nxt_rt_dig[1][0]}} & nxt_f_r_c_spec_s1[0]);

assign mask_rt_ext[1] = mask_rt_ext[0] >> 2;

assign mask_rt_neg_2[1] = mask_rt_ext[1] << 1;
assign mask_rt_neg_1[1] = mask_rt_ext[1] | (mask_rt_ext[1] << 1);
assign mask_rt_neg_0[1] = '0;
assign mask_rt_pos_1[1] = mask_rt_ext[1];
assign mask_rt_pos_2[1] = mask_rt_ext[1] << 1;

assign mask_rt_m1_neg_2[1] = mask_rt_ext[1];
assign mask_rt_m1_neg_1[1] = mask_rt_ext[1] << 1;
assign mask_rt_m1_neg_0[1] = mask_rt_ext[1] | (mask_rt_ext[1] << 1);
assign mask_rt_m1_pos_1[1] = '0;
assign mask_rt_m1_pos_2[1] = mask_rt_ext[1];

assign nxt_rt[1] = 
  ({(55){nxt_rt_dig[1][4]}} & (nxt_rt_m1[0] | mask_rt_neg_2[1]))
| ({(55){nxt_rt_dig[1][3]}} & (nxt_rt_m1[0] | mask_rt_neg_1[1]))
| ({(55){nxt_rt_dig[1][2]}} & nxt_rt[0])
| ({(55){nxt_rt_dig[1][1]}} & (nxt_rt[0]    | mask_rt_pos_1[1]))
| ({(55){nxt_rt_dig[1][0]}} & (nxt_rt[0]    | mask_rt_pos_2[1]));
assign nxt_rt_m1[1] = 
  ({(55){nxt_rt_dig[1][4]}} & (nxt_rt_m1[0] | mask_rt_m1_neg_2[1]))
| ({(55){nxt_rt_dig[1][3]}} & (nxt_rt_m1[0] | mask_rt_m1_neg_1[1]))
| ({(55){nxt_rt_dig[1][2]}} & (nxt_rt_m1[0] | mask_rt_m1_neg_0[1]))
| ({(55){nxt_rt_dig[1][1]}} & nxt_rt[0])
| ({(55){nxt_rt_dig[1][0]}} & (nxt_rt[0]    | mask_rt_m1_pos_2[1]));


// ================================================================================================================================================
// Test signals
// ================================================================================================================================================
// logic [REM_W-1:0] nxt_f_r [2-1:0];
// assign nxt_f_r[0] = nxt_f_r_s[0] + nxt_f_r_c[0];
// assign nxt_f_r[1] = nxt_f_r_s[1] + nxt_f_r_c[1];


// ================================================================================================================================================
// Post
// ================================================================================================================================================

assign nr_f_r = f_r_s_q + f_r_c_q;
assign fpsqrt_frac_o = nr_f_r[REM_W-1] ? rt_m1_q[53:0] : rt_q[53:0];

endmodule

