// ========================================================================================================
// File Name			: fmul16_rsh_lgs_mask.sv
// Author				: HYF
// How to Contact		: hyf_sysu@qq.com
// Created Time    		: June 25th 2024, 14:51:50
// Last Modified Time   : 2024-06-27 @ 16:58:59
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

module fmul16_rsh_lgs_mask #(
	// Put some parameters here, which can be changed by other modules
)(
	input  logic [ 4 - 1:0] 	rsh_num_i,
	output logic [22 - 1:0] 	l_mask_o,
	output logic [22 - 1:0] 	g_mask_o,
	output logic [22 - 1:0] 	s_mask_o,
	output logic [22 - 1:0] 	l_mask_uf_check_o,
	output logic [22 - 1:0] 	g_mask_uf_check_o,
	output logic [22 - 1:0] 	s_mask_uf_check_o
);

// ================================================================================================================================================
// (local) parameters begin



// (local) parameters end
// ================================================================================================================================================

// ================================================================================================================================================
// signals begin

genvar i;
logic [32 - 1:0] l_mask;
logic [32 - 1:0] g_mask;
logic [32 - 1:0] s_mask_temp;
logic [32 - 1:0] s_mask;
logic [32 - 1:0] l_mask_uf_check;
logic [32 - 1:0] g_mask_uf_check;
logic [32 - 1:0] s_mask_uf_check;

// signals end
// ================================================================================================================================================

// F16, sig_mul is 22-bit
// rsh_num_i = 1 ~ 15
// rsh_num_i = 01, {L, G, S} = {sig_mul[11], sig_mul[10], sig_mul[09:0]}, {L, G, S}_uf_check = {sig_mul[10], sig_mul[09], sig_mul[08:0]}
// rsh_num_i = 02, {L, G, S} = {sig_mul[12], sig_mul[11], sig_mul[10:0]}, {L, G, S}_uf_check = {sig_mul[11], sig_mul[10], sig_mul[09:0]}
// rsh_num_i = 03, {L, G, S} = {sig_mul[13], sig_mul[12], sig_mul[11:0]}, {L, G, S}_uf_check = {sig_mul[12], sig_mul[11], sig_mul[10:0]}
// ...
// rsh_num_i = 11, {L, G, S} = {sig_mul[21], sig_mul[20], sig_mul[19:0]}, {L, G, S}_uf_check = {sig_mul[20], sig_mul[19], sig_mul[18:0]}
// rsh_num_i = 12, {L, G, S} = {0, sig_mul[21], sig_mul[20:0]}, {L, G, S}_uf_check = {sig_mul[21], sig_mul[20], sig_mul[19:0]}
// rsh_num_i = 13 ~ 15, {L, G, S} = {0, 0, sig_mul[21:0]}

assign l_mask = {21'b0, 1'b1, 10'b0} << rsh_num_i;
assign g_mask = l_mask >> 1;
assign s_mask_temp = g_mask >> 1;

assign l_mask_uf_check = l_mask >> 1;
assign g_mask_uf_check = g_mask >> 1;
assign s_mask_uf_check = s_mask >> 1;

// From MSB -> LSB, set all bits 1 after the fitst 1
generate
for(i = 31; i >= 1; i--) begin
    assign s_mask[i] = |s_mask_temp[31:i];
end
endgenerate
assign s_mask[0] = |s_mask_temp[31:0];

assign l_mask_o = l_mask[21:0];
assign g_mask_o = g_mask[21:0];
assign s_mask_o = s_mask[21:0];
assign l_mask_uf_check_o = l_mask_uf_check[21:0];
assign g_mask_uf_check_o = g_mask_uf_check[21:0];
assign s_mask_uf_check_o = s_mask_uf_check[21:0];

endmodule

