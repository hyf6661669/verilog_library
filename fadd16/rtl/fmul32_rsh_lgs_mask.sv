// ========================================================================================================
// File Name			: fmul32_rsh_lgs_mask.sv
// Author				: HYF
// How to Contact		: hyf_sysu@qq.com
// Created Time    		: June 25th 2024, 16:55:49
// Last Modified Time   : 2024-06-27 @ 16:58:56
// ========================================================================================================
// Description	:
// Get mask to extract {L, G, S}/{L, G, S}_uf_check for rsh case
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

module fmul32_rsh_lgs_mask #(
	// Put some parameters here, which can be changed by other modules
)(
	input  logic [ 5 - 1:0] 	rsh_num_i,
	output logic [48 - 1:0] 	l_mask_o,
	output logic [48 - 1:0] 	g_mask_o,
	output logic [48 - 1:0] 	s_mask_o,
	output logic [48 - 1:0] 	l_mask_uf_check_o,
	output logic [48 - 1:0] 	g_mask_uf_check_o,
	output logic [48 - 1:0] 	s_mask_uf_check_o
);

// ================================================================================================================================================
// (local) parameters begin



// (local) parameters end
// ================================================================================================================================================

// ================================================================================================================================================
// signals begin

genvar i;
logic [64 - 1:0] l_mask;
logic [64 - 1:0] g_mask;
logic [64 - 1:0] s_mask_temp;
logic [64 - 1:0] s_mask;
logic [64 - 1:0] l_mask_uf_check;
logic [64 - 1:0] g_mask_uf_check;
logic [64 - 1:0] s_mask_uf_check;

// signals end
// ================================================================================================================================================

// F32, sig_mul is 48-bit
// rsh_num_i = 1 ~ 31
// rsh_num_i = 01, {L, G, S} = {sig_mul[24], sig_mul[23], sig_mul[22:0]}, {L, G, S}_uf_check = {sig_mul[23], sig_mul[22], sig_mul[21:0]}
// rsh_num_i = 02, {L, G, S} = {sig_mul[25], sig_mul[24], sig_mul[23:0]}, {L, G, S}_uf_check = {sig_mul[24], sig_mul[23], sig_mul[22:0]}
// rsh_num_i = 03, {L, G, S} = {sig_mul[26], sig_mul[25], sig_mul[24:0]}, {L, G, S}_uf_check = {sig_mul[25], sig_mul[24], sig_mul[23:0]}
// ...
// rsh_num_i = 24, {L, G, S} = {sig_mul[47], sig_mul[46], sig_mul[45:0]}, {L, G, S}_uf_check = {sig_mul[46], sig_mul[45], sig_mul[44:0]}
// rsh_num_i = 25, {L, G, S} = {0, sig_mul[47], sig_mul[46:0]}, {L, G, S}_uf_check = {sig_mul[47], sig_mul[46], sig_mul[45:0]}
// rsh_num_i = 26 ~ 31, {L, G, S} = {0, 0, sig_mul[47:0]}

assign l_mask = {40'b0, 1'b1, 23'b0} << rsh_num_i;
assign g_mask = l_mask >> 1;
assign s_mask_temp = g_mask >> 1;

assign l_mask_uf_check = l_mask >> 1;
assign g_mask_uf_check = g_mask >> 1;
assign s_mask_uf_check = s_mask >> 1;

// From MSB -> LSB, set all bits 1 after the fitst 1
generate
for(i = 63; i >= 1; i--) begin
    assign s_mask[i] = |s_mask_temp[63:i];
end
endgenerate
assign s_mask[0] = |s_mask_temp[63:0];

assign l_mask_o = l_mask[47:0];
assign g_mask_o = g_mask[47:0];
assign s_mask_o = s_mask[47:0];
assign l_mask_uf_check_o = l_mask_uf_check[47:0];
assign g_mask_uf_check_o = g_mask_uf_check[47:0];
assign s_mask_uf_check_o = s_mask_uf_check[47:0];

endmodule

