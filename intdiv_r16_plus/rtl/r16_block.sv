// ========================================================================================================
// File Name			: r16_block.sv
// Author				: Yifei He
// How to Contact		: hyf_sysu@qq.com
// Created Time    		: 2022-01-24 21:57:45
// Last Modified Time 	: 2022-01-30 09:14:13
// ========================================================================================================
// Description	:
// Overlap 2 R4 blocks to form the R16 block.
// ========================================================================================================
// ========================================================================================================
// Copyright (C) 2022, Yifei He. All Rights Reserved.
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

module r16_block #(
	// Put some parameters here, which can be changed by other modules.
	parameter D_W = 32,
	parameter REM_W = 1 + D_W + 2 + 3,
	parameter QUO_DIG_W = 5
)(
	input  logic [REM_W-1:0] rem_s_i,
	input  logic [REM_W-1:0] rem_c_i,
	input  logic [D_W-2:0] D_i,
	input  logic [5-1:0] m_neg_1_i,
	input  logic [3-1:0] m_neg_0_i,
	input  logic [2-1:0] m_pos_1_i,
	input  logic [5-1:0] m_pos_2_i,
	input  logic m_neg_0_pos_1_lsb_i,
	input  logic [D_W-1:0] quo_iter_i,
	input  logic [D_W-1:0] quo_m1_iter_i,
	input  logic [QUO_DIG_W-1:0] prev_quo_dig_i,
	output logic [REM_W-1:0] nxt_rem_s_o [2-1:0],
	output logic [REM_W-1:0] nxt_rem_c_o [2-1:0],
	output logic [D_W-1:0] nxt_quo_iter_o [2-1:0],
	output logic [D_W-1:0] nxt_quo_m1_iter_o [2-1:0],
	output logic [QUO_DIG_W-1:0] nxt_quo_dig_o [2-1:0]
);

// ==================================================================================================================================================
// (local) params
// ==================================================================================================================================================

// ==================================================================================================================================================
// signals
// ==================================================================================================================================================

logic [(REM_W+4)-1:0] rem_s_mul_16 [2-1:0];
logic [(REM_W+4)-1:0] rem_c_mul_16 [2-1:0];
logic [REM_W-1:0] nxt_rem_s [2-1:0];
logic [REM_W-1:0] nxt_rem_c [2-1:0];
logic [REM_W-1:0] nxt_rem_s_spec_s1 [5-1:0];
logic [REM_W-1:0] nxt_rem_c_spec_s1 [5-1:0];

logic [7-1:0] m_neg_1;
logic [7-1:0] m_neg_0;
logic [7-1:0] m_pos_1;
logic [7-1:0] m_pos_2;

logic [QUO_DIG_W-1:0] nxt_quo_dig [2-1:0];
logic [D_W-1:0] nxt_quo_iter [2-1:0];
logic [D_W-1:0] nxt_quo_m1_iter [2-1:0];

logic [REM_W-1:0] D_ext;
logic [(REM_W+2)-1:0] D_mul_4;
logic [(REM_W+2)-1:0] D_mul_8;
logic [(REM_W+2)-1:0] D_mul_neg_4;
logic [(REM_W+2)-1:0] D_mul_neg_8;
logic [8-1:0] D_trunc_3_5_for_s0_qds;
logic [7-1:0] D_mul_4_trunc_2_5;
logic [7-1:0] D_mul_4_trunc_3_4;
logic [7-1:0] D_mul_8_trunc_2_5;
logic [7-1:0] D_mul_8_trunc_3_4;
logic [7-1:0] D_mul_neg_4_trunc_2_5;
logic [7-1:0] D_mul_neg_4_trunc_3_4;
logic [7-1:0] D_mul_neg_8_trunc_2_5;
logic [7-1:0] D_mul_neg_8_trunc_3_4;
logic [REM_W-1:0] D_to_csa [2-1:0];


// ==================================================================================================================================================
// main codes
// ==================================================================================================================================================

// The decimal point is between [REM_W-1] and [REM_W-2]
assign rem_s_mul_16[0] = {rem_s_i, 4'b0};
assign rem_c_mul_16[0] = {rem_c_i, 4'b0};

// ================================================================================================================================================
// Get the QDS constants
// ================================================================================================================================================
assign m_neg_1 = {1'b0, m_neg_1_i, 1'b0};
assign m_neg_0 = {3'b0, m_neg_0_i, m_neg_0_pos_1_lsb_i};
assign m_pos_1 = {4'b1111, m_pos_1_i, m_neg_0_pos_1_lsb_i};
assign m_pos_2 = {1'b1, m_pos_2_i, 1'b0};
// ================================================================================================================================================
// Calculate "-4 * q * D" for QDS
// ================================================================================================================================================
assign D_ext = {1'b0, 1'b1, D_i, 5'b0};
assign D_mul_4 = {D_ext, 2'b0};
assign D_mul_8 = {D_ext[REM_W-2:0], 3'b0};
assign D_mul_neg_4 = ~D_mul_4;
assign D_mul_neg_8 = ~D_mul_8;

assign D_mul_4_trunc_2_5 = D_mul_4[REM_W+0 -: 7];
assign D_mul_4_trunc_3_4 = D_mul_4[REM_W+1 -: 7];
assign D_mul_8_trunc_2_5 = D_mul_8[REM_W+0 -: 7];
assign D_mul_8_trunc_3_4 = D_mul_8[REM_W+1 -: 7];
assign D_mul_neg_4_trunc_2_5 = D_mul_neg_4[REM_W+0 -: 7];
assign D_mul_neg_4_trunc_3_4 = D_mul_neg_4[REM_W+1 -: 7];
assign D_mul_neg_8_trunc_2_5 = D_mul_neg_8[REM_W+0 -: 7];
assign D_mul_neg_8_trunc_3_4 = D_mul_neg_8[REM_W+1 -: 7];
// ================================================================================================================================================
// stage[0].qds + stage[0].csa
// ================================================================================================================================================
assign D_to_csa[0] = 
  ({(REM_W){prev_quo_dig_i[4]}} & {D_ext[(REM_W-1)-1:0], 1'b0})
| ({(REM_W){prev_quo_dig_i[3]}} & D_ext)
| ({(REM_W){prev_quo_dig_i[1]}} & ~D_ext)
| ({(REM_W){prev_quo_dig_i[0]}} & ~{D_ext[(REM_W-1)-1:0], 1'b0});

assign nxt_rem_s[0] = 
  {rem_s_i[(REM_W-1)-2:0], 2'b0}
^ {rem_c_i[(REM_W-1)-2:0], 2'b0}
^ D_to_csa[0];
assign nxt_rem_c[0] = {
	  ({rem_s_i[(REM_W-1)-3:0], 2'b0} & {rem_c_i[(REM_W-1)-3:0], 2'b0})
	| ({rem_s_i[(REM_W-1)-3:0], 2'b0} & D_to_csa[0][(REM_W-1)-1:0])
	| ({rem_c_i[(REM_W-1)-3:0], 2'b0} & D_to_csa[0][(REM_W-1)-1:0]),
	prev_quo_dig_i[1] | prev_quo_dig_i[0]
};

assign D_trunc_3_5_for_s0_qds = 
  ({(8){prev_quo_dig_i[4]}} & D_mul_8[REM_W+1 -: 8])
| ({(8){prev_quo_dig_i[3]}} & D_mul_4[REM_W+1 -: 8])
| ({(8){prev_quo_dig_i[1]}} & D_mul_neg_4[REM_W+1 -: 8])
| ({(8){prev_quo_dig_i[0]}} & D_mul_neg_8[REM_W+1 -: 8]);

r4_qds #(
	.SPEC(0)
) u_r4_qds_s0 (
	.rem_s_trunc_3_5_i(rem_s_mul_16[0][REM_W+1 -: 8]),
	.rem_c_trunc_3_5_i(rem_c_mul_16[0][REM_W+1 -: 8]),
	.m_neg_1_i(m_neg_1),
	.m_neg_0_i(m_neg_0),
	.m_pos_1_i(m_pos_1),
	.m_pos_2_i(m_pos_2),
	.D_trunc_3_5_i(D_trunc_3_5_for_s0_qds),
	// Not used
	.D_mul_4_trunc_2_5_i('0),
	.D_mul_4_trunc_3_4_i('0),
	.D_mul_8_trunc_2_5_i('0),
	.D_mul_8_trunc_3_4_i('0),
	.D_mul_neg_4_trunc_2_5_i('0),
	.D_mul_neg_4_trunc_3_4_i('0),
	.D_mul_neg_8_trunc_2_5_i('0),
	.D_mul_neg_8_trunc_3_4_i('0),
	.prev_quo_dig_i('0),
	.quo_dig_o(nxt_quo_dig[0])
);

// ================================================================================================================================================
// stage[0].OFC
// ================================================================================================================================================
assign nxt_quo_iter[0] = 
  ({(D_W){prev_quo_dig_i[0]}} & {quo_iter_i   [(D_W-1)-2:0], 2'b10})
| ({(D_W){prev_quo_dig_i[1]}} & {quo_iter_i   [(D_W-1)-2:0], 2'b01})
| ({(D_W){prev_quo_dig_i[2]}} & {quo_iter_i   [(D_W-1)-2:0], 2'b00})
| ({(D_W){prev_quo_dig_i[3]}} & {quo_m1_iter_i[(D_W-1)-2:0], 2'b11})
| ({(D_W){prev_quo_dig_i[4]}} & {quo_m1_iter_i[(D_W-1)-2:0], 2'b10});
assign nxt_quo_m1_iter[0] = 
  ({(D_W){prev_quo_dig_i[0]}} & {quo_iter_i   [(D_W-1)-2:0], 2'b01})
| ({(D_W){prev_quo_dig_i[1]}} & {quo_iter_i   [(D_W-1)-2:0], 2'b00})
| ({(D_W){prev_quo_dig_i[2]}} & {quo_m1_iter_i[(D_W-1)-2:0], 2'b11})
| ({(D_W){prev_quo_dig_i[3]}} & {quo_m1_iter_i[(D_W-1)-2:0], 2'b10})
| ({(D_W){prev_quo_dig_i[4]}} & {quo_m1_iter_i[(D_W-1)-2:0], 2'b01});

// ================================================================================================================================================
// stage[1].qds + stage[1].csa
// ================================================================================================================================================

// The decimal point is between [REM_W-1] and [REM_W-2]
assign rem_s_mul_16[1] = {nxt_rem_s[0], 4'b0};
assign rem_c_mul_16[1] = {nxt_rem_c[0], 4'b0};

r4_qds #(
	.SPEC(1)
) u_r4_qds_s1 (
	.rem_s_trunc_3_5_i(rem_s_mul_16[1][REM_W+1 -: 8]),
	.rem_c_trunc_3_5_i(rem_c_mul_16[1][REM_W+1 -: 8]),
	.m_neg_1_i(m_neg_1),
	.m_neg_0_i(m_neg_0),
	.m_pos_1_i(m_pos_1),
	.m_pos_2_i(m_pos_2),
	// Not used
	.D_trunc_3_5_i('0),
	.D_mul_4_trunc_2_5_i(D_mul_4_trunc_2_5),
	.D_mul_4_trunc_3_4_i(D_mul_4_trunc_3_4),
	.D_mul_8_trunc_2_5_i(D_mul_8_trunc_2_5),
	.D_mul_8_trunc_3_4_i(D_mul_8_trunc_3_4),
	.D_mul_neg_4_trunc_2_5_i(D_mul_neg_4_trunc_2_5),
	.D_mul_neg_4_trunc_3_4_i(D_mul_neg_4_trunc_3_4),
	.D_mul_neg_8_trunc_2_5_i(D_mul_neg_8_trunc_2_5),
	.D_mul_neg_8_trunc_3_4_i(D_mul_neg_8_trunc_3_4),
	.prev_quo_dig_i(nxt_quo_dig[0]),
	.quo_dig_o(nxt_quo_dig[1])
);

assign D_to_csa[1] = 
  ({(REM_W){nxt_quo_dig[0][4]}} & {D_ext[(REM_W-1)-1:0], 1'b0})
| ({(REM_W){nxt_quo_dig[0][3]}} & D_ext)
| ({(REM_W){nxt_quo_dig[0][1]}} & ~D_ext)
| ({(REM_W){nxt_quo_dig[0][0]}} & ~{D_ext[(REM_W-1)-1:0], 1'b0});

assign nxt_rem_s[1] = 
  {nxt_rem_s[0][(REM_W-1)-2:0], 2'b0}
^ {nxt_rem_c[0][(REM_W-1)-2:0], 2'b0}
^ D_to_csa[1];
assign nxt_rem_c[1] = {
	  ({nxt_rem_s[0][(REM_W-1)-3:0], 2'b0} & {nxt_rem_c[0][(REM_W-1)-3:0], 2'b0})
	| ({nxt_rem_s[0][(REM_W-1)-3:0], 2'b0} & D_to_csa[1][(REM_W-1)-1:0])
	| ({nxt_rem_c[0][(REM_W-1)-3:0], 2'b0} & D_to_csa[1][(REM_W-1)-1:0]),
	nxt_quo_dig[0][1] | nxt_quo_dig[0][0]
};

// ================================================================================================================================================
// stage[1].OFC
// ================================================================================================================================================
assign nxt_quo_iter[1] = 
  ({(D_W){nxt_quo_dig[0][0]}} & {nxt_quo_iter[0]   [(D_W-1)-2:0], 2'b10})
| ({(D_W){nxt_quo_dig[0][1]}} & {nxt_quo_iter[0]   [(D_W-1)-2:0], 2'b01})
| ({(D_W){nxt_quo_dig[0][2]}} & {nxt_quo_iter[0]   [(D_W-1)-2:0], 2'b00})
| ({(D_W){nxt_quo_dig[0][3]}} & {nxt_quo_m1_iter[0][(D_W-1)-2:0], 2'b11})
| ({(D_W){nxt_quo_dig[0][4]}} & {nxt_quo_m1_iter[0][(D_W-1)-2:0], 2'b10});
assign nxt_quo_m1_iter[1] = 
  ({(D_W){nxt_quo_dig[0][0]}} & {nxt_quo_iter[0]   [(D_W-1)-2:0], 2'b01})
| ({(D_W){nxt_quo_dig[0][1]}} & {nxt_quo_iter[0]   [(D_W-1)-2:0], 2'b00})
| ({(D_W){nxt_quo_dig[0][2]}} & {nxt_quo_m1_iter[0][(D_W-1)-2:0], 2'b11})
| ({(D_W){nxt_quo_dig[0][3]}} & {nxt_quo_m1_iter[0][(D_W-1)-2:0], 2'b10})
| ({(D_W){nxt_quo_dig[0][4]}} & {nxt_quo_m1_iter[0][(D_W-1)-2:0], 2'b01});

assign nxt_rem_s_o = nxt_rem_s;
assign nxt_rem_c_o = nxt_rem_c;
assign nxt_quo_iter_o = nxt_quo_iter;
assign nxt_quo_m1_iter_o = nxt_quo_m1_iter;
assign nxt_quo_dig_o = nxt_quo_dig;

endmodule
