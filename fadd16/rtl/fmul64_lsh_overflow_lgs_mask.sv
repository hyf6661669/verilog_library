// ========================================================================================================
// File Name			: fmul64_lsh_overflow_lgs_mask.sv
// Author				: HYF
// How to Contact		: hyf_sysu@qq.com
// Created Time    		: June 26th 2024, 10:09:42
// Last Modified Time   : 2024-06-28 @ 14:32:58
// ========================================================================================================
// Description	:
// Get mask to extract {overflow, L, G, S} for lsh case
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

module fmul64_lsh_overflow_lgs_mask #(
	// Put some parameters here, which can be changed by other modules
)(
	input  logic [ 6 - 1:0] 	lsh_num_i,
	output logic [53 - 1:0] 	overflow_mask_o,
	output logic [53 - 1:0] 	overflow_l_mask_o,
	output logic [53 - 1:0] 	overflow_g_mask_o,
	output logic [52 - 1:0] 	overflow_s_mask_o,
	output logic [53 - 1:0] 	overflow_l_mask_uf_check_o,
	output logic [52 - 1:0] 	overflow_g_mask_uf_check_o,
	output logic [51 - 1:0] 	overflow_s_mask_uf_check_o,
	output logic [53 - 1:0] 	normal_l_mask_o,
	output logic [52 - 1:0] 	normal_g_mask_o,
	output logic [51 - 1:0] 	normal_s_mask_o,
	output logic [52 - 1:0] 	normal_l_mask_uf_check_o,
	output logic [51 - 1:0] 	normal_g_mask_uf_check_o,
	output logic [50 - 1:0] 	normal_s_mask_uf_check_o
);

// ================================================================================================================================================
// (local) parameters begin



// (local) parameters end
// ================================================================================================================================================

// ================================================================================================================================================
// signals begin

genvar i;
logic [106 - 1:0] overflow_mask;

logic [106 - 1:0] overflow_l_mask;
logic [106 - 1:0] overflow_g_mask;
logic [106 - 1:0] overflow_s_mask_temp;
logic [106 - 1:0] overflow_s_mask;

logic [106 - 1:0] overflow_l_mask_uf_check;
logic [106 - 1:0] overflow_g_mask_uf_check;
logic [106 - 1:0] overflow_s_mask_uf_check;

logic [106 - 1:0] normal_l_mask;
logic [106 - 1:0] normal_g_mask;
logic [106 - 1:0] normal_s_mask;

logic [106 - 1:0] normal_l_mask_uf_check;
logic [106 - 1:0] normal_g_mask_uf_check;
logic [106 - 1:0] normal_s_mask_uf_check;



// signals end
// ================================================================================================================================================

// F64, sig_mul is 106-bit
// lsh_num_i = 0 ~ 52
// lsh_num_i = 00, overflow = sig_mul[105], {L, G, S}_overflow = {sig_mul[53], sig_mul[52], sig_mul[51:0]}, {L, G, S}_normal = {sig_mul[52], sig_mul[51], sig_mul[50:0]}
// lsh_num_i = 01, overflow = sig_mul[104], {L, G, S}_overflow = {sig_mul[52], sig_mul[51], sig_mul[50:0]}, {L, G, S}_normal = {sig_mul[51], sig_mul[50], sig_mul[49:0]}
// lsh_num_i = 02, overflow = sig_mul[103], {L, G, S}_overflow = {sig_mul[51], sig_mul[50], sig_mul[49:0]}, {L, G, S}_normal = {sig_mul[50], sig_mul[49], sig_mul[48:0]}
// ...
// lsh_num_i = 51, overflow = sig_mul[54], {L, G, S}_overflow = {sig_mul[02], sig_mul[01], sig_mul[00:0]}, {L, G, S}_normal = {sig_mul[01], sig_mul[00], 0}
// lsh_num_i = 52, overflow = sig_mul[53], {L, G, S}_overflow = {sig_mul[01], sig_mul[00], 0}, {L, G, S}_normal = {sig_mul[00], 0, 0}
assign overflow_mask = {1'b1, 105'b0} >> lsh_num_i;
assign overflow_l_mask = overflow_mask >> 52;
assign overflow_g_mask = overflow_l_mask >> 1;
assign overflow_s_mask_temp = overflow_g_mask >> 1;
assign normal_l_mask = overflow_g_mask;
assign normal_g_mask = normal_l_mask >> 1;

// From MSB -> LSB, set all bits 1 after the fitst 1
generate
for(i = 105; i >= 1; i--) begin
    assign overflow_s_mask[i] = |overflow_s_mask_temp[105:i];
end
endgenerate
assign overflow_s_mask[0] = |overflow_s_mask_temp[105:0];
assign normal_s_mask = overflow_s_mask >> 1;

assign overflow_l_mask_uf_check = overflow_l_mask >> 1;
assign overflow_g_mask_uf_check = overflow_g_mask >> 1;
assign overflow_s_mask_uf_check = overflow_s_mask >> 1;

assign normal_l_mask_uf_check = normal_l_mask >> 1;
assign normal_g_mask_uf_check = normal_g_mask >> 1;
assign normal_s_mask_uf_check = normal_s_mask >> 1;

assign overflow_mask_o = overflow_mask[105 -: 53];

assign overflow_l_mask_o = overflow_l_mask[53:1];
assign overflow_g_mask_o = overflow_g_mask[52:0];
assign overflow_s_mask_o = overflow_s_mask[51:0];

assign overflow_l_mask_uf_check_o = overflow_l_mask_uf_check[52:0];
assign overflow_g_mask_uf_check_o = overflow_g_mask_uf_check[51:0];
assign overflow_s_mask_uf_check_o = overflow_s_mask_uf_check[50:0];

assign normal_l_mask_o = normal_l_mask[52:0];
assign normal_g_mask_o = normal_g_mask[51:0];
assign normal_s_mask_o = normal_s_mask[50:0];

assign normal_l_mask_uf_check_o = normal_l_mask_uf_check[51:0];
assign normal_g_mask_uf_check_o = normal_g_mask_uf_check[50:0];
assign normal_s_mask_uf_check_o = normal_s_mask_uf_check[49:0];

endmodule

