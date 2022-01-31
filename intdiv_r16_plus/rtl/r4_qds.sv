// ========================================================================================================
// File Name			: r4_qds.sv
// Author				: Yifei He
// How to Contact		: hyf_sysu@qq.com
// Created Time    		: 2022-01-28 10:09:49
// Last Modified Time 	: 2022-01-30 10:19:19
// ========================================================================================================
// Description	:
// Please Look at the reference for more details.
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

module r4_qds #(
	// Put some parameters here, which can be changed by other modules.
	parameter SPEC = 0
)(
	input  logic [8-1:0] rem_s_trunc_3_5_i,
	input  logic [8-1:0] rem_c_trunc_3_5_i,
	input  logic [7-1:0] m_neg_1_i,
	input  logic [7-1:0] m_neg_0_i,
	input  logic [7-1:0] m_pos_1_i,
	input  logic [7-1:0] m_pos_2_i,
	input  logic [8-1:0] D_trunc_3_5_i,
	input  logic [7-1:0] D_mul_4_trunc_2_5_i,
	input  logic [7-1:0] D_mul_4_trunc_3_4_i,
	input  logic [7-1:0] D_mul_8_trunc_2_5_i,
	input  logic [7-1:0] D_mul_8_trunc_3_4_i,
	input  logic [7-1:0] D_mul_neg_4_trunc_2_5_i,
	input  logic [7-1:0] D_mul_neg_4_trunc_3_4_i,
	input  logic [7-1:0] D_mul_neg_8_trunc_2_5_i,
	input  logic [7-1:0] D_mul_neg_8_trunc_3_4_i,
	input  logic [5-1:0] prev_quo_dig_i,
	output logic [5-1:0] quo_dig_o
);

// ==================================================================================================================================================
// (local) params
// ==================================================================================================================================================

// ==================================================================================================================================================
// signals
// ==================================================================================================================================================

logic [7-1:0] rem_s_trunc_2_5;
logic [7-1:0] rem_s_trunc_3_4;
logic [7-1:0] rem_c_trunc_2_5;
logic [7-1:0] rem_c_trunc_3_4;

logic [7-1:0] D_trunc_2_5;
logic [7-1:0] D_trunc_3_4;
logic [4-1:0] qds_sign;
logic [6-1:0] unused_bit [4-1:0];
logic [4-1:0] qds_sign_spec [5-1:0];
logic [6-1:0] unused_bit_prev_q_neg_2 [4-1:0];
logic [6-1:0] unused_bit_prev_q_neg_1 [4-1:0];
logic [6-1:0] unused_bit_prev_q_neg_0 [4-1:0];
logic [6-1:0] unused_bit_prev_q_pos_1 [4-1:0];
logic [6-1:0] unused_bit_prev_q_pos_2 [4-1:0];

// ==================================================================================================================================================
// main codes
// ==================================================================================================================================================
assign rem_s_trunc_2_5 = rem_s_trunc_3_5_i[0 +: 7];
assign rem_s_trunc_3_4 = rem_s_trunc_3_5_i[1 +: 7];
assign rem_c_trunc_2_5 = rem_c_trunc_3_5_i[0 +: 7];
assign rem_c_trunc_3_4 = rem_c_trunc_3_5_i[1 +: 7];

assign D_trunc_2_5 = D_trunc_3_5_i[0 +: 7];
assign D_trunc_3_4 = D_trunc_3_5_i[1 +: 7];

generate
if(SPEC == 0) begin

	assign {qds_sign[3], unused_bit[3]} = rem_s_trunc_2_5 + rem_c_trunc_2_5 + D_trunc_2_5 + m_pos_2_i;
	assign {qds_sign[2], unused_bit[2]} = rem_s_trunc_3_4 + rem_c_trunc_3_4 + D_trunc_3_4 + m_pos_1_i;
	assign {qds_sign[1], unused_bit[1]} = rem_s_trunc_3_4 + rem_c_trunc_3_4 + D_trunc_3_4 + m_neg_0_i;
	assign {qds_sign[0], unused_bit[0]} = rem_s_trunc_2_5 + rem_c_trunc_2_5 + D_trunc_2_5 + m_neg_1_i;

end else begin
	
	assign {qds_sign_spec[4][3], unused_bit_prev_q_neg_2[3]} = rem_s_trunc_2_5 + rem_c_trunc_2_5 + D_mul_8_trunc_2_5_i + m_pos_2_i;
	assign {qds_sign_spec[4][2], unused_bit_prev_q_neg_2[2]} = rem_s_trunc_3_4 + rem_c_trunc_3_4 + D_mul_8_trunc_3_4_i + m_pos_1_i;
	assign {qds_sign_spec[4][1], unused_bit_prev_q_neg_2[1]} = rem_s_trunc_3_4 + rem_c_trunc_3_4 + D_mul_8_trunc_3_4_i + m_neg_0_i;
	assign {qds_sign_spec[4][0], unused_bit_prev_q_neg_2[0]} = rem_s_trunc_2_5 + rem_c_trunc_2_5 + D_mul_8_trunc_2_5_i + m_neg_1_i;

	assign {qds_sign_spec[3][3], unused_bit_prev_q_neg_1[3]} = rem_s_trunc_2_5 + rem_c_trunc_2_5 + D_mul_4_trunc_2_5_i + m_pos_2_i;
	assign {qds_sign_spec[3][2], unused_bit_prev_q_neg_1[2]} = rem_s_trunc_3_4 + rem_c_trunc_3_4 + D_mul_4_trunc_3_4_i + m_pos_1_i;
	assign {qds_sign_spec[3][1], unused_bit_prev_q_neg_1[1]} = rem_s_trunc_3_4 + rem_c_trunc_3_4 + D_mul_4_trunc_3_4_i + m_neg_0_i;
	assign {qds_sign_spec[3][0], unused_bit_prev_q_neg_1[0]} = rem_s_trunc_2_5 + rem_c_trunc_2_5 + D_mul_4_trunc_2_5_i + m_neg_1_i;

	assign {qds_sign_spec[2][3], unused_bit_prev_q_neg_0[3]} = rem_s_trunc_2_5 + rem_c_trunc_2_5 + m_pos_2_i;
	assign {qds_sign_spec[2][2], unused_bit_prev_q_neg_0[2]} = rem_s_trunc_3_4 + rem_c_trunc_3_4 + m_pos_1_i;
	assign {qds_sign_spec[2][1], unused_bit_prev_q_neg_0[1]} = rem_s_trunc_3_4 + rem_c_trunc_3_4 + m_neg_0_i;
	assign {qds_sign_spec[2][0], unused_bit_prev_q_neg_0[0]} = rem_s_trunc_2_5 + rem_c_trunc_2_5 + m_neg_1_i;

	assign {qds_sign_spec[1][3], unused_bit_prev_q_pos_1[3]} = rem_s_trunc_2_5 + rem_c_trunc_2_5 + D_mul_neg_4_trunc_2_5_i + m_pos_2_i;
	assign {qds_sign_spec[1][2], unused_bit_prev_q_pos_1[2]} = rem_s_trunc_3_4 + rem_c_trunc_3_4 + D_mul_neg_4_trunc_3_4_i + m_pos_1_i;
	assign {qds_sign_spec[1][1], unused_bit_prev_q_pos_1[1]} = rem_s_trunc_3_4 + rem_c_trunc_3_4 + D_mul_neg_4_trunc_3_4_i + m_neg_0_i;
	assign {qds_sign_spec[1][0], unused_bit_prev_q_pos_1[0]} = rem_s_trunc_2_5 + rem_c_trunc_2_5 + D_mul_neg_4_trunc_2_5_i + m_neg_1_i;

	assign {qds_sign_spec[0][3], unused_bit_prev_q_pos_2[3]} = rem_s_trunc_2_5 + rem_c_trunc_2_5 + D_mul_neg_8_trunc_2_5_i + m_pos_2_i;
	assign {qds_sign_spec[0][2], unused_bit_prev_q_pos_2[2]} = rem_s_trunc_3_4 + rem_c_trunc_3_4 + D_mul_neg_8_trunc_3_4_i + m_pos_1_i;
	assign {qds_sign_spec[0][1], unused_bit_prev_q_pos_2[1]} = rem_s_trunc_3_4 + rem_c_trunc_3_4 + D_mul_neg_8_trunc_3_4_i + m_neg_0_i;
	assign {qds_sign_spec[0][0], unused_bit_prev_q_pos_2[0]} = rem_s_trunc_2_5 + rem_c_trunc_2_5 + D_mul_neg_8_trunc_2_5_i + m_neg_1_i;

	// When we get the above signals, the "prev_quo_dig_i" must be ready.
	assign qds_sign = 
	  ({(4){prev_quo_dig_i[4]}} & qds_sign_spec[4])
	| ({(4){prev_quo_dig_i[3]}} & qds_sign_spec[3])
	| ({(4){prev_quo_dig_i[2]}} & qds_sign_spec[2])
	| ({(4){prev_quo_dig_i[1]}} & qds_sign_spec[1])
	| ({(4){prev_quo_dig_i[0]}} & qds_sign_spec[0]);
	
end
endgenerate

assign quo_dig_o[4] = (qds_sign[1:0] == 2'b11);
assign quo_dig_o[3] = (qds_sign[1:0] == 2'b10);
assign quo_dig_o[2] = (qds_sign[2:1] == 2'b10);
assign quo_dig_o[1] = (qds_sign[3:2] == 2'b10);
assign quo_dig_o[0] = (qds_sign[3:2] == 2'b00);


endmodule
