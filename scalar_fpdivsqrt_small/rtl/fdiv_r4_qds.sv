// ========================================================================================================
// File Name			: fdiv_r4_qds.sv
// Author				: HYF
// How to Contact		: hyf_sysu@qq.com
// Created Time    		: July 5th 2024, 16:39:24
// Last Modified Time   : July 16th 2024, 09:56:40
// ========================================================================================================
// Description	:
// Modified based on the Table 2 (a) in "Low Latency Floating-Point Division and Square Root Unit"
// In the original implementation, there is a "+1" operation applied to the rem.
// Here we coud just apply the "-1" operation to the parameters.
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

module fdiv_r4_qds #(
	// Put some parameters here, which can be changed by other modules.

	// You should try which config could lead to best PPA.
	// 0: Native expression
	// 1: Comparator based
	// 2: Adder based
	parameter QDS_ARCH = 2
)(
	input  logic [6 - 1:0] rem_i,
	output logic [5 - 1:0] quo_dig_o
);

// ================================================================================================================================================
// (local) parameters begin

localparam [6-1:0] M_POS_2 = 6'd12;
localparam [6-1:0] M_POS_1 = 6'd3;
// -4 = 11_1100
// -13 = 11_0011
localparam [6-1:0] M_NEG_0 = -(6'd4);
localparam [6-1:0] M_NEG_1 = -(6'd13);

localparam [6-1:0] M_POS_2_NEGATED = -(6'd12);
localparam [6-1:0] M_POS_1_NEGATED = -(6'd3);
localparam [6-1:0] M_NEG_0_NEGATED = 6'd4;
localparam [6-1:0] M_NEG_1_NEGATED = 6'd13;

// (local) parameters end
// ================================================================================================================================================

// ================================================================================================================================================
// signals begin

logic [4-1:0] qds_sign;
logic [5-1:0] unused_bit [4-1:0];
logic rem_ge_m_pos_2;
logic rem_ge_m_pos_1;
logic rem_ge_m_neg_0;
logic rem_ge_m_neg_1;

// signals end
// ================================================================================================================================================

// The SEL logic is:
// rem >= m[+2]			: quo = +2
// m[+1] <= rem < m[+2]	: quo = +1
// m[-0] <= rem < m[+1]	: quo = -0
// m[-1] <= rem < m[-0]	: quo = -1
// rem < m[-1]			: quo = -2

generate
if(QDS_ARCH == 0) begin

	// Native implementation, hope EDA could optimize it well...
	assign quo_dig_o[4] = ($signed(rem_i) <= -14);
	assign quo_dig_o[3] = ($signed(rem_i) >= -13) & ($signed(rem_i) <= -5);
	assign quo_dig_o[2] = ($signed(rem_i) >=  -4) & ($signed(rem_i) <=  2);
	assign quo_dig_o[1] = ($signed(rem_i) >=   3) & ($signed(rem_i) <= 11);
	assign quo_dig_o[0] = ($signed(rem_i) >=  12);

end else if(QDS_ARCH == 1) begin

	assign rem_ge_m_pos_2 = ($signed(rem_i) >= $signed(M_POS_2));
	assign rem_ge_m_pos_1 = ($signed(rem_i) >= $signed(M_POS_1));
	assign rem_ge_m_neg_0 = ($signed(rem_i) >= $signed(M_NEG_0));
	assign rem_ge_m_neg_1 = ($signed(rem_i) >= $signed(M_NEG_1));

	assign quo_dig_o[4] = ~rem_ge_m_neg_1;
	assign quo_dig_o[3] =  rem_ge_m_neg_1 & ~rem_ge_m_neg_0;
	assign quo_dig_o[2] =  rem_ge_m_neg_0 & ~rem_ge_m_pos_1;
	assign quo_dig_o[1] =  rem_ge_m_pos_1 & ~rem_ge_m_pos_2;
	assign quo_dig_o[0] =  rem_ge_m_pos_2;

end else begin

	assign {qds_sign[3], unused_bit[3]} = rem_i + M_POS_2_NEGATED;
	assign {qds_sign[2], unused_bit[2]} = rem_i + M_POS_1_NEGATED;
	assign {qds_sign[1], unused_bit[1]} = rem_i + M_NEG_0_NEGATED;
	assign {qds_sign[0], unused_bit[0]} = rem_i + M_NEG_1_NEGATED;

	// assign quo_dig_o[4] = (qds_sign[0]   == 1'b1);
	assign quo_dig_o[4] = (qds_sign[1:0] == 2'b11);
	assign quo_dig_o[3] = (qds_sign[1:0] == 2'b10);
	assign quo_dig_o[2] = (qds_sign[2:1] == 2'b10);
	assign quo_dig_o[1] = (qds_sign[3:2] == 2'b10);
	// assign quo_dig_o[0] = (qds_sign[3]   == 1'b0);
	assign quo_dig_o[0] = (qds_sign[3:2] == 2'b00);
	
end
endgenerate



endmodule
