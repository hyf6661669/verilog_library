// ========================================================================================================
// File Name			: fadd16_lza.sv
// Author				: HYF
// How to Contact		: hyf_sysu@qq.com
// Created Time    		: June 4th 2024, 16:18:14
// Last Modified Time   : July 17th 2024, 10:26:37
// ========================================================================================================
// Description	:
// 1. Get lshift num
// 2. Get mask to extract {L, G, S} for Overflow/Normal cases
// Read "Optimized Leading Zero Anticipators for Faster Fused Multiply-Adds" for more details.
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

module fadd16_lza #(
	// Put some parameters here, which can be changed by other modules
)(
	input  logic [21 - 1:0] 	frac_large_i,
	input  logic [21 - 1:0] 	frac_small_i,
	input  logic [ 5 - 1:0] 	exp_large_i,
    input  logic 			    small_rsh1_i,
    
    output logic 			    lza_limited_by_exp_o,
    output logic [ 5 - 1:0]     lza_o,
    output logic [14 - 1:0]     overflow_l_mask_o,
    output logic [13 - 1:0]     overflow_g_mask_o,
    output logic [12 - 1:0]     overflow_s_mask_o,
    output logic [13 - 1:0]     normal_l_mask_o,
    output logic [12 - 1:0]     normal_g_mask_o,    
    output logic [11 - 1:0]     normal_s_mask_o,
    output logic [13 - 1:0]     overflow_l_mask_uf_check_o,
    output logic [12 - 1:0]     overflow_g_mask_uf_check_o,
    output logic [11 - 1:0]     overflow_s_mask_uf_check_o,
    output logic [12 - 1:0]     normal_l_mask_uf_check_o,
    output logic [11 - 1:0]     normal_g_mask_uf_check_o,
    output logic [10 - 1:0]     normal_s_mask_uf_check_o
);

// ================================================================================================================================================
// (local) parameters begin



// (local) parameters end
// ================================================================================================================================================

// ================================================================================================================================================
// signals begin

genvar i;
logic [32 - 1:0] op_large;
logic [32 - 1:0] op_small_rsh0;
logic [32 - 1:0] op_small_rsh1;
logic [32 - 1:0] p_rsh0;
logic [32 - 1:0] k_rsh0;
logic [32 - 1:0] p_rsh1;
logic [32 - 1:0] k_rsh1;
logic [32 - 1:0] lzc_in_rsh0;
logic [32 - 1:0] lzc_in_rsh1;
logic [32 - 1:0] lzc_in_temp;
logic [32 - 1:0] lzc_in;

logic [32 - 1:0] exp_limit;
logic [32 - 1:0] exp_limit_mask;

logic [32 - 1:0] lzc_in_lg_mask;
logic [32 - 1:0] lg_mask;

logic [32 - 1:0] lzc_in_s_mask;
logic [32 - 1:0] s_mask;

logic [32 - 1:0] overflow_l_mask;
logic [32 - 1:0] overflow_g_mask;
logic [32 - 1:0] overflow_s_mask;
logic [32 - 1:0] normal_l_mask;
logic [32 - 1:0] normal_g_mask;
logic [32 - 1:0] normal_s_mask;
logic [32 - 1:0] overflow_l_mask_uf_check;
logic [32 - 1:0] overflow_g_mask_uf_check;
logic [32 - 1:0] overflow_s_mask_uf_check;
logic [32 - 1:0] normal_l_mask_uf_check;
logic [32 - 1:0] normal_g_mask_uf_check;
logic [32 - 1:0] normal_s_mask_uf_check;


// signals end
// ================================================================================================================================================

// We can always assume the hidden bit is 1 when we are doing LZA -> If op is a denormal number, the output of the lza module would be limited by exp, so the frac value is of no use.
assign op_large = {1'b1, frac_large_i[20:0], 10'b0};
assign op_small_rsh0 = ~{1'b1, frac_small_i[20:0], 10'b0};
assign op_small_rsh1 = ~{2'b01, frac_small_i[20:0], 9'b0};

// P: propgate carry
// K: kill carry
assign p_rsh0[30:0] = op_large[31:1] ^ op_small_rsh0[31:1];
assign k_rsh0[30:0] = ~op_large[30:0] & ~op_small_rsh0[30:0];

assign p_rsh1[30:0] = op_large[31:1] ^ op_small_rsh1[31:1];
assign k_rsh1[30:0] = ~op_large[30:0] & ~op_small_rsh1[30:0];

// For close_path, we always "Let" the frac at least lsh 1-bit, so we would have "lza = lzc" or "lza = lzc + 1".
// Finally, the lsh result of close_path have 2 cases: 1) Overflow. 2) Normal. And these 2 cases can be handled in the same way as far_path.
// For example: 
// opa = 1.1 * (2 ^ 1)
// opb = 1.0 * (2 ^ 0)
// opa - opb = (1.1 - 0.1) * (2 ^ 1) = (11.0 - 1.0) * (2 ^ 0) = 10.0 * (2 ^ 0) = 1.0 * (2 ^ 1) -> Overflow case

// opa = 1.1 * (2 ^ 1)
// opb = 1.11 * (2 ^ 0)
// opa - opb = (1.1 - 0.111) * (2 ^ 1) = (11.0 - 1.11) * (2 ^ 0) = 1.01 * (2 ^ 0) -> Normal case
assign lzc_in_rsh0[30:0] = ~(p_rsh0[30:0] ^ k_rsh0[30:0]);
assign lzc_in_rsh0[31] = 1'b0;
assign lzc_in_rsh1[30:0] = ~(p_rsh1[30:0] ^ k_rsh1[30:0]);
assign lzc_in_rsh1[31] = 1'b0;

assign lzc_in_temp = small_rsh1_i ? lzc_in_rsh1 : lzc_in_rsh0;

// We can at most lsh "exp_large - 1" in close_path
generate
for(i = 2; i < 32; i++) begin
    assign exp_limit[32 - i] = (exp_large_i[4:0] == i[4:0]);
end
endgenerate
assign exp_limit[31] = (exp_large_i == 5'd0) | (exp_large_i == 5'd1);
assign exp_limit[00] = 1'b1;
// From MSB -> LSB, set all bits 1 after the fitst 1
generate
for(i = 31; i >= 1; i--) begin
    assign exp_limit_mask[i] = |exp_limit[31:i];
end
endgenerate
assign exp_limit_mask[0] = |exp_limit[31:0];

assign lzc_in = lzc_in_temp | exp_limit;
lzc #(
	.WIDTH(32),
	// 0: trailing zero.
	// 1: leading zero.
	.MODE(1'b1)
) u_lzc (
	.in_i		(lzc_in),
	.cnt_o		(lza_o),
	.empty_o	()
);
// Check whether lza is determined by "exp_large"
assign lza_limited_by_exp_o = ({1'b0, exp_limit_mask[31:1]} == (lzc_in_temp | {1'b0, exp_limit_mask[31:1]}));

// Overflow
// lzc_in = {1, 31'bx}, lza_o = 0, for unrounded frac in close_sum[23:0], {L, G, S} = {[13], [12], [11:0]}, {L_uf_check, G_uf_check, S_uf_check} = {[12], [11], [10:0]} -> This is impossible in Overflow case
// lzc_in = {1'b0, 1, 30'bx}, lza_o = 1, for unrounded frac in close_sum[23:0], {L, G, S} = {[12], [11], [10:0]}, {L_uf_check, G_uf_check, S_uf_check} = {[11], [10], [9:0]}
// lzc_in = {2'b0, 1, 29'bx}, lza_o = 2, for unrounded frac in close_sum[23:0], {L, G, S} = {[11], [10], [09:0]}, {L_uf_check, G_uf_check, S_uf_check} = {[10], [9], [8:0]}
// ...
// lzc_in = {11'b0, 1, 20'bx}, lza_o = 11, for unrounded frac in close_sum[23:0], {L, G, S} = {[2], [1], [0:0]}, {L_uf_check, G_uf_check, S_uf_check} = {[1], [0], 0}
// lzc_in = {12'b0, 1, 19'bx}, lza_o = 12, for unrounded frac in close_sum[23:0], {L, G, S} = {[1], [0], 0}, {L_uf_check, G_uf_check, S_uf_check} = {[0], 0, 0}
// lzc_in = {13'b0, 1, 18'bx}, lza_o = 13, for unrounded frac in close_sum[23:0], {L, G, S} = {[0], 0, 0}, {L_uf_check, G_uf_check, S_uf_check} = {0, 0, 0}
// lza_o >= 14, for unrounded frac in close_sum[23:0], {L, G, S} = {0, 0, 0}, {L_uf_check, G_uf_check, S_uf_check} = {0, 0, 0}

// Normal
// lzc_in = {1, 31'bx}, lza_o = 0, for unrounded frac in close_sum[23:0], {L, G, S} = {[12], [11], [10:0]}, {L_uf_check, G_uf_check, S_uf_check} = {[11], [10], [9:0]}
// lzc_in = {1'b0, 1, 30'bx}, lza_o = 1, for unrounded frac in close_sum[23:0], {L, G, S} = {[11], [10], [9:0]}, {L_uf_check, G_uf_check, S_uf_check} = {[10], [9], [8:0]}
// lzc_in = {2'b0, 1, 29'bx}, lza_o = 2, for unrounded frac in close_sum[23:0], {L, G, S} = {[10], [09], [8:0]}, {L_uf_check, G_uf_check, S_uf_check} = {[9], [8], [7:0]}
// ...
// lzc_in = {10'b0, 1, 21'bx}, lza_o = 10, for unrounded frac in close_sum[23:0], {L, G, S} = {[2], [1], [0:0]}, {L_uf_check, G_uf_check, S_uf_check} = {[1], [0], 0}
// lzc_in = {11'b0, 1, 20'bx}, lza_o = 11, for unrounded frac in close_sum[23:0], {L, G, S} = {[1], [0], 0}, {L_uf_check, G_uf_check, S_uf_check} = {[0], 0, 0}
// lzc_in = {12'b0, 1, 19'bx}, lza_o = 12, for unrounded frac in close_sum[23:0], {L, G, S} = {[0], 0, 0}, {L_uf_check, G_uf_check, S_uf_check} = {0, 0, 0}
// lza_o >= 13, for unrounded frac in close_sum[23:0], {L, G, S} = {0, 0, 0}, {L_uf_check, G_uf_check, S_uf_check} = {0, 0, 0}


// From MSB -> LSB, set all bits 0 after the fitst 1
generate
for(i = 30; i >= 1; i--) begin
    assign lzc_in_lg_mask[i] = lzc_in[i] & ~(|lzc_in[31:i + 1]);
end
endgenerate
assign lzc_in_lg_mask[00] = lzc_in[0] & ~(|lzc_in[31:1]);
assign lzc_in_lg_mask[31] = lzc_in[31];
// F16_FRAC_W = 10
assign lg_mask = lzc_in_lg_mask >> 10;

assign overflow_l_mask = lg_mask[31 - 10 -: 14];
assign overflow_g_mask = overflow_l_mask >> 1;
assign normal_l_mask = overflow_g_mask;
assign normal_g_mask = normal_l_mask >> 1;
assign overflow_l_mask_uf_check = overflow_g_mask;
assign overflow_g_mask_uf_check = overflow_l_mask_uf_check >> 1;
assign normal_l_mask_uf_check = normal_g_mask;
assign normal_g_mask_uf_check = normal_l_mask_uf_check >> 1;

// From MSB -> LSB, set all bits 1 after the fitst 1
generate
for(i = 31; i >= 1; i--) begin
    assign lzc_in_s_mask[i] = |lzc_in[31:i];
end
endgenerate
assign lzc_in_s_mask[0] = |lzc_in[31:0];
// 12 = F16_FRAC_W + 2
assign s_mask = lzc_in_s_mask >> 12;

assign overflow_s_mask = s_mask[31 - 12 -: 12];
assign normal_s_mask = overflow_s_mask >> 1;
assign overflow_s_mask_uf_check = normal_s_mask;
assign normal_s_mask_uf_check = normal_s_mask >> 1;

assign overflow_l_mask_o[13:0] = overflow_l_mask[13:0];
assign overflow_g_mask_o[12:0] = overflow_g_mask[12:0];
assign overflow_s_mask_o[11:0] = overflow_s_mask[11:0];
assign normal_l_mask_o[12:0] = normal_l_mask[12:0];
assign normal_g_mask_o[11:0] = normal_g_mask[11:0];
assign normal_s_mask_o[10:0] = normal_s_mask[10:0];

assign overflow_l_mask_uf_check_o = overflow_l_mask_uf_check[12:0];
assign overflow_g_mask_uf_check_o = overflow_g_mask_uf_check[11:0];
assign overflow_s_mask_uf_check_o = overflow_s_mask_uf_check[10:0];
assign normal_l_mask_uf_check_o = normal_l_mask_uf_check[11:0];
assign normal_g_mask_uf_check_o = normal_g_mask_uf_check[10:0];
assign normal_s_mask_uf_check_o = normal_s_mask_uf_check[09:0];

endmodule

