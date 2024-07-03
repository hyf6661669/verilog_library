// ========================================================================================================
// File Name			: fmul_simulation.sv
// Author				: HYF
// How to Contact		: hyf_sysu@qq.com
// Created Time    		: June 26th 2024, 10:35:29
// Last Modified Time   : 2024-07-01 @ 10:34:46
// ========================================================================================================
// Description	:
// Functional model of fmul, it can: 
// 1) Generate a special intermediate result of Fused-Multiply-Add (FMA) operation. And the result will be sent to fadd to get the final result of FMA.
// 2) Generate the result of Floating Point Multiply operation.
// Only used for simulation.
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

module fmul_simulation #(
	// Put some parameters here, which can be changed by other modules
    parameter UF_AFTER_ROUNDING = 1
)(
	input  logic [ 64 - 1:0] 	opa_i,
	input  logic [ 64 - 1:0] 	opb_i,
	input  logic [  3 - 1:0] 	format_i,
	input  logic [  3 - 1:0] 	rm_i,
	output logic     	        fma_mul_exp_gt_inf_o,
	output logic     	        fma_mul_sticky_o,
	output logic     	        fma_inputs_nan_inf_o,
	output logic [117 - 1:0]    fma_intermediate_res_o,
	output logic [ 64 - 1:0]    fmul_res_o,
	output logic [  5 - 1:0]    fmul_fflags_o
);

// ================================================================================================================================================
// (local) parameters begin

localparam F16_EXP_W = 5;
localparam F16_FRAC_W = 10;
// (11-bit) * (11-bit) = 22-bit -> There would be 21-bit frac for FMA at most
localparam F16_FRAC_FMA_W = 21;

localparam F32_EXP_W = 8;
localparam F32_FRAC_W = 23;
// (24-bit) * (24-bit) = 48-bit -> There would be 47-bit frac for FMA at most
localparam F32_FRAC_FMA_W = 47;

localparam F64_EXP_W = 11;
localparam F64_FRAC_W = 52;
// (53-bit) * (53-bit) = 106-bit -> There would be 105-bit frac for FMA at most
localparam F64_FRAC_FMA_W = 105;


localparam RM_RNE = 3'b000;
localparam RM_RTZ = 3'b001;
localparam RM_RDN = 3'b010;
localparam RM_RUP = 3'b011;
localparam RM_RMM = 3'b100;

// (local) parameters end
// ================================================================================================================================================

// ================================================================================================================================================
// signals begin

logic rne;
logic rtz_temp;
logic rdn_temp;
logic rup_temp;
logic rmm;
logic rtz;
logic rup;

logic is_f16;
logic is_f32;
logic is_f64;
logic signa;
logic signb;
logic sign_mul;

logic [11 - 1:0] expa;
logic [11 - 1:0] expb;
logic [11 - 1:0] expa_adj;
logic [11 - 1:0] expb_adj;
logic expa_all_1;
logic expb_all_1;
logic expa_zero;
logic expb_zero;

logic [52 - 1:0] fraca;
logic [52 - 1:0] fracb;
logic [53 - 1:0] siga;
logic [53 - 1:0] sigb;

logic opa_zero;
logic opb_zero;
logic opa_qnan;
logic opb_qnan;
logic opa_snan;
logic opb_snan;
logic opa_inf;
logic opb_inf;

logic [12 - 1:0] expa_unbiased;
logic [12 - 1:0] expb_unbiased;

logic [13 - 1:0] exp_no_lsh;
logic [13 - 1:0] exp_no_lsh_m1;
logic [13 - 1:0] exp_lsh;
logic exp_no_lsh_zero;
logic exp_no_lsh_neg;
logic exp_lsh_zero;
logic exp_lsh_neg;
logic exp_lsh_pos;
logic do_rsh;

logic [13 - 1:0] rsh_num_temp;
logic set_rsh_num_max_f16;
logic set_rsh_num_max_f32;
logic set_rsh_num_max_f64;
logic [4 - 1:0] rsh_num_f16;
logic [5 - 1:0] rsh_num_f32;
logic [6 - 1:0] rsh_num_f64;
logic [6 - 1:0] rsh_num;
logic [14 - 1:0] s_mask_f16;
logic [30 - 1:0] s_mask_f32;
logic [62 - 1:0] s_mask_f64;
logic fma_mul_sticky_f16;
logic fma_mul_sticky_f32;
logic fma_mul_sticky_f64;

logic [6 - 1:0] lzc_fraca_temp;
logic [6 - 1:0] lzc_fracb_temp;
logic [6 - 1:0] lzc_fraca;
logic [6 - 1:0] lzc_fracb;
logic [6 - 1:0] lzc_frac;
logic [6 - 1:0] lzc_frac_m1;
logic [6 - 1:0] lsh_num;

logic [12 - 1:0] exp_mul;
logic [12 - 1:0] exp_mul_p1;
logic exp_mul_overflow;
logic exp_mul_inf;
logic exp_mul_max;
logic exp_mul_zero;

logic [106 - 1:0] sig_mul;
logic [ 22 - 1:0] sig_mul_f16;
logic [ 48 - 1:0] sig_mul_f32;
logic [107 - 1:0] sig_mul_rsh;
logic [106 - 1:0] sig_mul_lsh;

logic rsh_overflow;
logic lsh_overflow;
logic lsh_denormal_to_normal;
logic sel_overflow_exp;
logic [11 - 1:0] exp_fma;

logic [ 21 - 1:0] frac_fma_f16;
logic [ 47 - 1:0] frac_fma_f32;
logic [105 - 1:0] frac_fma_f64;

logic res_snan;
logic res_qnan;
logic res_zero;
logic res_inf;
logic sel_special;

logic sign_special;
logic [  5 - 1:0] exp_special_f16;
logic [  8 - 1:0] exp_special_f32;
logic [ 11 - 1:0] exp_special_f64;
logic [ 21 - 1:0] frac_special_f16;
logic [ 47 - 1:0] frac_special_f32;
logic [105 - 1:0] frac_special_f64;

logic [ 27 - 1:0] fma_intermediate_res_f16;
logic [ 56 - 1:0] fma_intermediate_res_f32;
logic [117 - 1:0] fma_intermediate_res_f64;


logic [22 - 1:0] rsh_l_mask_f16;
logic [22 - 1:0] rsh_g_mask_f16;
logic [22 - 1:0] rsh_s_mask_f16;
logic [22 - 1:0] rsh_l_mask_uf_check_f16;
logic [22 - 1:0] rsh_g_mask_uf_check_f16;
logic [22 - 1:0] rsh_s_mask_uf_check_f16;

logic [48 - 1:0] rsh_l_mask_f32;
logic [48 - 1:0] rsh_g_mask_f32;
logic [48 - 1:0] rsh_s_mask_f32;
logic [48 - 1:0] rsh_l_mask_uf_check_f32;
logic [48 - 1:0] rsh_g_mask_uf_check_f32;
logic [48 - 1:0] rsh_s_mask_uf_check_f32;

logic [106 - 1:0] rsh_l_mask_f64;
logic [106 - 1:0] rsh_g_mask_f64;
logic [106 - 1:0] rsh_s_mask_f64;
logic [106 - 1:0] rsh_l_mask_uf_check_f64;
logic [106 - 1:0] rsh_g_mask_uf_check_f64;
logic [106 - 1:0] rsh_s_mask_uf_check_f64;

logic rsh_l_f16;
logic rsh_g_f16;
logic rsh_s_f16;
logic rsh_l_uf_check_f16;
logic rsh_g_uf_check_f16;
logic rsh_s_uf_check_f16;

logic rsh_l_f32;
logic rsh_g_f32;
logic rsh_s_f32;
logic rsh_l_uf_check_f32;
logic rsh_g_uf_check_f32;
logic rsh_s_uf_check_f32;

logic rsh_l_f64;
logic rsh_g_f64;
logic rsh_s_f64;
logic rsh_l_uf_check_f64;
logic rsh_g_uf_check_f64;
logic rsh_s_uf_check_f64;

logic rsh_l;
logic rsh_g;
logic rsh_s;
logic rsh_l_uf_check;
logic rsh_g_uf_check;
logic rsh_s_uf_check;

logic [11 - 1:0] lsh_overflow_mask_f16;
logic [11 - 1:0] lsh_overflow_l_mask_f16;
logic [11 - 1:0] lsh_overflow_g_mask_f16;
logic [10 - 1:0] lsh_overflow_s_mask_f16;
logic [11 - 1:0] lsh_overflow_l_mask_uf_check_f16;
logic [10 - 1:0] lsh_overflow_g_mask_uf_check_f16;
logic [09 - 1:0] lsh_overflow_s_mask_uf_check_f16;
logic [11 - 1:0] lsh_normal_l_mask_f16;
logic [10 - 1:0] lsh_normal_g_mask_f16;
logic [09 - 1:0] lsh_normal_s_mask_f16;
logic [10 - 1:0] lsh_normal_l_mask_uf_check_f16;
logic [09 - 1:0] lsh_normal_g_mask_uf_check_f16;
logic [08 - 1:0] lsh_normal_s_mask_uf_check_f16;

logic [24 - 1:0] lsh_overflow_mask_f32;
logic [24 - 1:0] lsh_overflow_l_mask_f32;
logic [24 - 1:0] lsh_overflow_g_mask_f32;
logic [23 - 1:0] lsh_overflow_s_mask_f32;
logic [24 - 1:0] lsh_overflow_l_mask_uf_check_f32;
logic [23 - 1:0] lsh_overflow_g_mask_uf_check_f32;
logic [22 - 1:0] lsh_overflow_s_mask_uf_check_f32;
logic [24 - 1:0] lsh_normal_l_mask_f32;
logic [23 - 1:0] lsh_normal_g_mask_f32;
logic [22 - 1:0] lsh_normal_s_mask_f32;
logic [23 - 1:0] lsh_normal_l_mask_uf_check_f32;
logic [22 - 1:0] lsh_normal_g_mask_uf_check_f32;
logic [21 - 1:0] lsh_normal_s_mask_uf_check_f32;

logic [53 - 1:0] lsh_overflow_mask_f64;
logic [53 - 1:0] lsh_overflow_l_mask_f64;
logic [53 - 1:0] lsh_overflow_g_mask_f64;
logic [52 - 1:0] lsh_overflow_s_mask_f64;
logic [53 - 1:0] lsh_overflow_l_mask_uf_check_f64;
logic [52 - 1:0] lsh_overflow_g_mask_uf_check_f64;
logic [51 - 1:0] lsh_overflow_s_mask_uf_check_f64;
logic [53 - 1:0] lsh_normal_l_mask_f64;
logic [52 - 1:0] lsh_normal_g_mask_f64;
logic [51 - 1:0] lsh_normal_s_mask_f64;
logic [52 - 1:0] lsh_normal_l_mask_uf_check_f64;
logic [51 - 1:0] lsh_normal_g_mask_uf_check_f64;
logic [50 - 1:0] lsh_normal_s_mask_uf_check_f64;

logic lsh_overflow_f16;
logic lsh_overflow_l_f16;
logic lsh_overflow_g_f16;
logic lsh_overflow_s_f16;
logic lsh_overflow_l_uf_check_f16;
logic lsh_overflow_g_uf_check_f16;
logic lsh_overflow_s_uf_check_f16;
logic lsh_normal_l_f16;
logic lsh_normal_g_f16;
logic lsh_normal_s_f16;
logic lsh_normal_l_uf_check_f16;
logic lsh_normal_g_uf_check_f16;
logic lsh_normal_s_uf_check_f16;
logic lsh_l_f16;
logic lsh_g_f16;
logic lsh_s_f16;
logic lsh_l_uf_check_f16;
logic lsh_g_uf_check_f16;
logic lsh_s_uf_check_f16;

logic lsh_overflow_f32;
logic lsh_overflow_l_f32;
logic lsh_overflow_g_f32;
logic lsh_overflow_s_f32;
logic lsh_overflow_l_uf_check_f32;
logic lsh_overflow_g_uf_check_f32;
logic lsh_overflow_s_uf_check_f32;
logic lsh_normal_l_f32;
logic lsh_normal_g_f32;
logic lsh_normal_s_f32;
logic lsh_normal_l_uf_check_f32;
logic lsh_normal_g_uf_check_f32;
logic lsh_normal_s_uf_check_f32;
logic lsh_l_f32;
logic lsh_g_f32;
logic lsh_s_f32;
logic lsh_l_uf_check_f32;
logic lsh_g_uf_check_f32;
logic lsh_s_uf_check_f32;

logic lsh_overflow_f64;
logic lsh_overflow_l_f64;
logic lsh_overflow_g_f64;
logic lsh_overflow_s_f64;
logic lsh_overflow_l_uf_check_f64;
logic lsh_overflow_g_uf_check_f64;
logic lsh_overflow_s_uf_check_f64;
logic lsh_normal_l_f64;
logic lsh_normal_g_f64;
logic lsh_normal_s_f64;
logic lsh_normal_l_uf_check_f64;
logic lsh_normal_g_uf_check_f64;
logic lsh_normal_s_uf_check_f64;
logic lsh_l_f64;
logic lsh_g_f64;
logic lsh_s_f64;
logic lsh_l_uf_check_f64;
logic lsh_g_uf_check_f64;
logic lsh_s_uf_check_f64;

logic lsh_l;
logic lsh_g;
logic lsh_s;
logic lsh_l_uf_check;
logic lsh_g_uf_check;
logic lsh_s_uf_check;

logic l_for_round;
logic g_for_round;
logic s_for_round;
logic l_for_uf_check;
logic g_for_uf_check;
logic s_for_uf_check;

logic round_up;
logic round_up_uf_check;

logic [52 - 1:0] frac_unrounded_fmul;
logic [52 - 1:0] round_up_poisition;
logic [52 - 1:0] frac_rounded_fmul;
logic frac_unrounded_all_1_fmul;
logic sel_exp_p1_fmul;
logic sel_overflow_res_fmul;

logic [11 - 1:0] exp_fmul;
logic [11 - 1:0] exp_fmul_before_rounding;

logic [16 - 1:0] overflow_res_fmul_f16;
logic [32 - 1:0] overflow_res_fmul_f32;
logic [64 - 1:0] overflow_res_fmul_f64;
logic [16 - 1:0] special_res_fmul_f16;
logic [32 - 1:0] special_res_fmul_f32;
logic [64 - 1:0] special_res_fmul_f64;
logic [16 - 1:0] fmul_res_f16;
logic [32 - 1:0] fmul_res_f32;
logic [64 - 1:0] fmul_res_f64;

logic [5 - 1:0] exp_special_fmul_f16;
logic [10 - 1:0] frac_special_fmul_f16;
logic [8 - 1:0] exp_special_fmul_f32;
logic [23 - 1:0] frac_special_fmul_f32;
logic [11 - 1:0] exp_special_fmul_f64;
logic [52 - 1:0] frac_special_fmul_f64;

logic invalid_operation_fmul;
logic overflow_fmul;
logic underflow_fmul;
logic inexact_fmul;

// signals end
// ================================================================================================================================================

assign is_f16 = format_i[0];
assign is_f32 = format_i[1];
assign is_f64 = format_i[2];

assign signa = is_f16 ? opa_i[15] : is_f32 ? opa_i[31] : opa_i[63];
assign signb = is_f16 ? opb_i[15] : is_f32 ? opb_i[31] : opb_i[63];

assign sign_mul = signa ^ signb;

assign expa = is_f16 ? {6'b0, opa_i[14:10]} : is_f32 ? {3'b0, opa_i[30:23]} : opa_i[62:52];
assign expb = is_f16 ? {6'b0, opb_i[14:10]} : is_f32 ? {3'b0, opb_i[30:23]} : opb_i[62:52];

assign expa_all_1 = is_f16 ? (&expa[4:0]) : is_f32 ? (&expa[7:0]) : (&expa[10:0]);
assign expb_all_1 = is_f16 ? (&expb[4:0]) : is_f32 ? (&expb[7:0]) : (&expb[10:0]);
assign expa_zero  = ~(|expa);
assign expb_zero  = ~(|expb);

assign expa_adj = {expa[10:1], expa[0] | expa_zero};
assign expb_adj = {expb[10:1], expb[0] | expb_zero};

assign fraca[51:0] = is_f16 ? {opa_i[9:0], 42'b0} : is_f32 ? {opa_i[22:0], 29'b0} : opa_i[51:0];
assign fracb[51:0] = is_f16 ? {opb_i[9:0], 42'b0} : is_f32 ? {opb_i[22:0], 29'b0} : opb_i[51:0];

assign siga[52:0] = {~expa_zero, fraca};
assign sigb[52:0] = {~expb_zero, fracb};

assign opa_zero = expa_zero & (fraca == '0);
assign opb_zero = expb_zero & (fracb == '0);
assign opa_qnan = expa_all_1 & fraca[51];
assign opb_qnan = expb_all_1 & fracb[51];
assign opa_snan = expa_all_1 & ~fraca[51] & (fraca[50:0] != '0);
assign opb_snan = expb_all_1 & ~fracb[51] & (fracb[50:0] != '0);
assign opa_inf = expa_all_1 & (fraca == '0);
assign opb_inf = expb_all_1 & (fracb == '0);

assign expa_unbiased[11:0] = {1'b0, expa_adj[10:0]} - (is_f16 ? 12'd15 : is_f32 ? 12'd127 : 12'd1023);
assign expb_unbiased[11:0] = {1'b0, expb_adj[10:0]} - (is_f16 ? 12'd15 : is_f32 ? 12'd127 : 12'd1023);

// When opa/opb is neither denormal, "expa + expb" could be "exp_mul"
assign exp_no_lsh[12:0] = {2'b0, expa_adj[10:0]} + {expb_unbiased[11], expb_unbiased[11:0]};
assign exp_no_lsh_m1 = exp_no_lsh - 13'd1;
// When opa/opa is denormal, "expa + expb - lzc" could be "exp_res"
assign exp_lsh[12:0] = exp_no_lsh[12:0] - {7'b0, lzc_frac[5:0]};

assign exp_no_lsh_zero = (exp_no_lsh == '0);
assign exp_no_lsh_neg = exp_no_lsh[12];
assign exp_lsh_zero = (exp_lsh == '0);
assign exp_lsh_neg = exp_lsh[12];
assign exp_lsh_pos = ~exp_lsh_zero & ~exp_lsh_neg;

assign do_rsh = exp_no_lsh_zero | exp_no_lsh_neg;
// When "exp_no_lsh <= 0", rsh_num_temp = 1 - exp_no_lsh. rsh_num_temp is a unsigned number
assign rsh_num_temp[12:0] = 13'd1 - exp_no_lsh[12:0];

// F16: When "rsh_num_temp >= (13 = 11 + 2)", the whole  22-bit product will become sticky -> We let "max_rsh_num = {(4){1'b1}} = 15"
// F32: When "rsh_num_temp >= (26 = 24 + 2)", the whole  48-bit product will become sticky -> We let "max_rsh_num = {(5){1'b1}} = 31"
// F64: When "rsh_num_temp >= (55 = 53 + 2)", the whole 106-bit product will become sticky -> We let "max_rsh_num = {(6){1'b1}} = 63"
assign set_rsh_num_max_f16 = |rsh_num_temp[12:4];
assign set_rsh_num_max_f32 = |rsh_num_temp[12:5];
assign set_rsh_num_max_f64 = |rsh_num_temp[12:6];

// F16: When "rsh_num_temp >= (13 = 11 + 2)", the whole  22-bit product will become sticky -> We let "max_rsh_num >= ({{(3){1'b1}}, 1'b0} = 14)"
// F32: When "rsh_num_temp >= (26 = 24 + 2)", the whole  48-bit product will become sticky -> We let "max_rsh_num >= ({{(3){1'b1}}, 2'b0} = 28)"
// F64: When "rsh_num_temp >= (55 = 53 + 2)", the whole 106-bit product will become sticky -> We let "max_rsh_num >= ({{(3){1'b1}}, 3'b0} = 56)"
assign rsh_num_f16[3:0] = {{(3){set_rsh_num_max_f16}} | rsh_num_temp[3:1], rsh_num_temp[0]};
assign rsh_num_f32[4:0] = {{(3){set_rsh_num_max_f32}} | rsh_num_temp[4:2], rsh_num_temp[1:0]};
assign rsh_num_f64[5:0] = {{(3){set_rsh_num_max_f64}} | rsh_num_temp[5:3], rsh_num_temp[2:0]};
// assign rsh_num_f16[3:0] = {(4){set_rsh_num_max_f16}} | rsh_num_temp[3:0];
// assign rsh_num_f32[4:0] = {(5){set_rsh_num_max_f32}} | rsh_num_temp[4:0];
// assign rsh_num_f64[5:0] = {(6){set_rsh_num_max_f64}} | rsh_num_temp[5:0];
assign rsh_num = 
  ({(6){is_f16}} & {2'b0, rsh_num_f16[3:0]})
| ({(6){is_f32}} & {1'b0, rsh_num_f32[4:0]})
| ({(6){is_f64}} & {rsh_num_f64[5:0]});

fma16_rsh_lost_bits_mask u_fma16_rsh_lost_bits_mask (
	.rsh_num_i  (rsh_num_f16),
	.s_mask_o   (s_mask_f16)
);
fma32_rsh_lost_bits_mask u_fma32_rsh_lost_bits_mask (
	.rsh_num_i  (rsh_num_f32),
	.s_mask_o   (s_mask_f32)
);
fma64_rsh_lost_bits_mask u_fma64_rsh_lost_bits_mask (
	.rsh_num_i  (rsh_num_f64),
	.s_mask_o   (s_mask_f64)
);
fmul16_rsh_lgs_mask u_fmul16_rsh_lgs_mask (
	.rsh_num_i                  (rsh_num_f16),
	.l_mask_o                   (rsh_l_mask_f16),
	.g_mask_o                   (rsh_g_mask_f16),
	.s_mask_o                   (rsh_s_mask_f16),
	.l_mask_uf_check_o          (rsh_l_mask_uf_check_f16),
	.g_mask_uf_check_o          (rsh_g_mask_uf_check_f16),
	.s_mask_uf_check_o          (rsh_s_mask_uf_check_f16)
);
fmul32_rsh_lgs_mask u_fmul32_rsh_lgs_mask (
	.rsh_num_i                  (rsh_num_f32),
	.l_mask_o                   (rsh_l_mask_f32),
	.g_mask_o                   (rsh_g_mask_f32),
	.s_mask_o                   (rsh_s_mask_f32),
	.l_mask_uf_check_o          (rsh_l_mask_uf_check_f32),
	.g_mask_uf_check_o          (rsh_g_mask_uf_check_f32),
	.s_mask_uf_check_o          (rsh_s_mask_uf_check_f32)
);
fmul64_rsh_lgs_mask u_fmul64_rsh_lgs_mask (
	.rsh_num_i                  (rsh_num_f64),
	.l_mask_o                   (rsh_l_mask_f64),
	.g_mask_o                   (rsh_g_mask_f64),
	.s_mask_o                   (rsh_s_mask_f64),
	.l_mask_uf_check_o          (rsh_l_mask_uf_check_f64),
	.g_mask_uf_check_o          (rsh_g_mask_uf_check_f64),
	.s_mask_uf_check_o          (rsh_s_mask_uf_check_f64)
);
// F16: sig_mul[105:84]
// F32: sig_mul[105:58]
// F64: sig_mul[105: 0]
assign fma_mul_sticky_f16 = |(s_mask_f16[13:0] & sig_mul[84 +: 14]);
assign fma_mul_sticky_f32 = |(s_mask_f32[29:0] & sig_mul[58 +: 30]);
assign fma_mul_sticky_f64 = |(s_mask_f64[61:0] & sig_mul[ 0 +: 62]);

// {L, G, S}_uf_check = {L, G, S} >> 1

assign rsh_l_f16 = |(rsh_l_mask_f16[21:0] & sig_mul_f16[21:0]);
assign rsh_g_f16 = rsh_l_uf_check_f16;
assign rsh_s_f16 = rsh_g_uf_check_f16 | rsh_s_uf_check_f16;
 
assign rsh_l_uf_check_f16 = |(rsh_l_mask_uf_check_f16[21:0] & sig_mul_f16[21:0]);
assign rsh_g_uf_check_f16 = |(rsh_g_mask_uf_check_f16[21:0] & sig_mul_f16[21:0]);
assign rsh_s_uf_check_f16 = |(rsh_s_mask_uf_check_f16[21:0] & sig_mul_f16[21:0]);

assign rsh_l_f32 = |(rsh_l_mask_f32[47:0] & sig_mul_f32[47:0]);
assign rsh_g_f32 = rsh_l_uf_check_f32;
assign rsh_s_f32 = rsh_g_uf_check_f32 | rsh_s_uf_check_f32;

assign rsh_l_uf_check_f32 = |(rsh_l_mask_uf_check_f32[47:0] & sig_mul_f32[47:0]);
assign rsh_g_uf_check_f32 = |(rsh_g_mask_uf_check_f32[47:0] & sig_mul_f32[47:0]);
assign rsh_s_uf_check_f32 = |(rsh_s_mask_uf_check_f32[47:0] & sig_mul_f32[47:0]);

assign rsh_l_f64 = |(rsh_l_mask_f64[105:0] & sig_mul[105:0]);
assign rsh_g_f64 = rsh_l_uf_check_f64;
assign rsh_s_f64 = rsh_g_uf_check_f64 | rsh_s_uf_check_f64;

assign rsh_l_uf_check_f64 = |(rsh_l_mask_uf_check_f64[105:0] & sig_mul[105:0]);
assign rsh_g_uf_check_f64 = |(rsh_g_mask_uf_check_f64[105:0] & sig_mul[105:0]);
assign rsh_s_uf_check_f64 = |(rsh_s_mask_uf_check_f64[105:0] & sig_mul[105:0]);

assign rsh_l = is_f16 ? rsh_l_f16 : is_f32 ? rsh_l_f32 : rsh_l_f64;
assign rsh_g = is_f16 ? rsh_g_f16 : is_f32 ? rsh_g_f32 : rsh_g_f64;
assign rsh_s = is_f16 ? rsh_s_f16 : is_f32 ? rsh_s_f32 : rsh_s_f64;

assign rsh_l_uf_check = is_f16 ? rsh_l_uf_check_f16 : is_f32 ? rsh_l_uf_check_f32 : rsh_l_uf_check_f64;
assign rsh_g_uf_check = is_f16 ? rsh_g_uf_check_f16 : is_f32 ? rsh_g_uf_check_f32 : rsh_g_uf_check_f64;
assign rsh_s_uf_check = is_f16 ? rsh_s_uf_check_f16 : is_f32 ? rsh_s_uf_check_f32 : rsh_s_uf_check_f64;

lzc #(
	.WIDTH(52 + 1),
	// 0: trailing zero.
	// 1: leading zero.
	.MODE(1'b1)
) u_lzc_fraca (
	.in_i		({1'b0, fraca}),
	.cnt_o		(lzc_fraca_temp),
	.empty_o	()
);
lzc #(
	.WIDTH(52 + 1),
	// 0: trailing zero.
	// 1: leading zero.
	.MODE(1'b1)
) u_lzc_fracb (
	.in_i		({1'b0, fracb}),
	.cnt_o		(lzc_fracb_temp),
	.empty_o	()
);
assign lzc_fraca = expa_zero ? lzc_fraca_temp : '0;
assign lzc_fracb = expb_zero ? lzc_fracb_temp : '0;
// When opa and opb are both denormal numbers, we will not do lsh, so lzc is useless and we only need "|" here, instead of "+"
assign lzc_frac = lzc_fraca | lzc_fracb;
assign lzc_frac_m1 = lzc_frac - 6'd1;

assign lsh_num = 
  ({(6){exp_lsh_pos }} & lzc_frac)
| ({(6){exp_lsh_zero}} & lzc_frac_m1)
| ({(6){exp_lsh_neg }} & exp_no_lsh_m1[5:0]);


fmul16_lsh_overflow_lgs_mask u_fmul16_lsh_overflow_lgs_mask (
	.lsh_num_i                          (lsh_num[3:0]),
	.overflow_mask_o                    (lsh_overflow_mask_f16),
	.overflow_l_mask_o                  (lsh_overflow_l_mask_f16),
	.overflow_g_mask_o                  (lsh_overflow_g_mask_f16),
	.overflow_s_mask_o                  (lsh_overflow_s_mask_f16),
    .overflow_l_mask_uf_check_o         (lsh_overflow_l_mask_uf_check_f16),
	.overflow_g_mask_uf_check_o         (lsh_overflow_g_mask_uf_check_f16),
	.overflow_s_mask_uf_check_o         (lsh_overflow_s_mask_uf_check_f16),
	.normal_l_mask_o                    (lsh_normal_l_mask_f16),
	.normal_g_mask_o                    (lsh_normal_g_mask_f16),
	.normal_s_mask_o                    (lsh_normal_s_mask_f16),
	.normal_l_mask_uf_check_o           (lsh_normal_l_mask_uf_check_f16),
	.normal_g_mask_uf_check_o           (lsh_normal_g_mask_uf_check_f16),
	.normal_s_mask_uf_check_o           (lsh_normal_s_mask_uf_check_f16)
);
fmul32_lsh_overflow_lgs_mask u_fmul32_lsh_overflow_lgs_mask (
	.lsh_num_i                          (lsh_num[4:0]),
	.overflow_mask_o                    (lsh_overflow_mask_f32),
	.overflow_l_mask_o                  (lsh_overflow_l_mask_f32),
	.overflow_g_mask_o                  (lsh_overflow_g_mask_f32),
	.overflow_s_mask_o                  (lsh_overflow_s_mask_f32),
    .overflow_l_mask_uf_check_o         (lsh_overflow_l_mask_uf_check_f32),
	.overflow_g_mask_uf_check_o         (lsh_overflow_g_mask_uf_check_f32),
	.overflow_s_mask_uf_check_o         (lsh_overflow_s_mask_uf_check_f32),
	.normal_l_mask_o                    (lsh_normal_l_mask_f32),
	.normal_g_mask_o                    (lsh_normal_g_mask_f32),
	.normal_s_mask_o                    (lsh_normal_s_mask_f32),
	.normal_l_mask_uf_check_o           (lsh_normal_l_mask_uf_check_f32),
	.normal_g_mask_uf_check_o           (lsh_normal_g_mask_uf_check_f32),
	.normal_s_mask_uf_check_o           (lsh_normal_s_mask_uf_check_f32)
);
fmul64_lsh_overflow_lgs_mask u_fmul64_lsh_overflow_lgs_mask (
	.lsh_num_i                          (lsh_num[5:0]),
	.overflow_mask_o                    (lsh_overflow_mask_f64),
	.overflow_l_mask_o                  (lsh_overflow_l_mask_f64),
	.overflow_g_mask_o                  (lsh_overflow_g_mask_f64),
	.overflow_s_mask_o                  (lsh_overflow_s_mask_f64),
    .overflow_l_mask_uf_check_o         (lsh_overflow_l_mask_uf_check_f64),
	.overflow_g_mask_uf_check_o         (lsh_overflow_g_mask_uf_check_f64),
	.overflow_s_mask_uf_check_o         (lsh_overflow_s_mask_uf_check_f64),
	.normal_l_mask_o                    (lsh_normal_l_mask_f64),
	.normal_g_mask_o                    (lsh_normal_g_mask_f64),
	.normal_s_mask_o                    (lsh_normal_s_mask_f64),
	.normal_l_mask_uf_check_o           (lsh_normal_l_mask_uf_check_f64),
	.normal_g_mask_uf_check_o           (lsh_normal_g_mask_uf_check_f64),
	.normal_s_mask_uf_check_o           (lsh_normal_s_mask_uf_check_f64)
);

// {L, G, S}_overflow_uf_check = {L, G, S}_normal = {L, G, S}_overflow >> 1, {L, G, S}_normal_uf_check = {L, G, S}_normal >> 1 = {L, G, S}_overflow >> 2
// S_normal_uf_check
// G_normal_uf_check
// L_normal_uf_check
// S_normal = S_normal_uf_check | G_normal_uf_check
// G_normal = L_normal_uf_check
// L_normal
// S_overflow_uf_check = S_normal
// G_overflow_uf_check = G_normal
// L_overflow_uf_check = L_normal
// S_overflow = S_normal | G_normal
// G_overflow = L_normal
// L_overflow

// We only need {L_overflow, L_normal, L_normal_uf_check, G_normal_uf_check, S_normal_uf_check}

assign lsh_overflow_f16 = |(lsh_overflow_mask_f16[10:0] & sig_mul_f16[21:11]);

assign lsh_overflow_l_f16 = |(lsh_overflow_l_mask_f16[10:0] & sig_mul_f16[11:01]);
assign lsh_overflow_g_f16 = lsh_normal_l_f16;
assign lsh_overflow_s_f16 = lsh_normal_s_f16 | lsh_normal_g_f16;

assign lsh_overflow_l_uf_check_f16 = lsh_normal_l_f16;
assign lsh_overflow_g_uf_check_f16 = lsh_normal_g_f16;
assign lsh_overflow_s_uf_check_f16 = lsh_normal_s_f16;

assign lsh_normal_l_f16 = |(lsh_normal_l_mask_f16[10:0] & sig_mul_f16[10:00]);
assign lsh_normal_g_f16 = lsh_normal_l_uf_check_f16;
assign lsh_normal_s_f16 = lsh_normal_s_uf_check_f16 | lsh_normal_g_uf_check_f16;

assign lsh_normal_l_uf_check_f16 = |(lsh_normal_l_mask_uf_check_f16[09:0] & sig_mul_f16[09:00]);
assign lsh_normal_g_uf_check_f16 = |(lsh_normal_g_mask_uf_check_f16[08:0] & sig_mul_f16[08:00]);
assign lsh_normal_s_uf_check_f16 = |(lsh_normal_s_mask_uf_check_f16[07:0] & sig_mul_f16[07:00]);

assign lsh_l_f16 = lsh_overflow_f16 ? lsh_overflow_l_f16 : lsh_normal_l_f16;
assign lsh_g_f16 = lsh_overflow_f16 ? lsh_overflow_g_f16 : lsh_normal_g_f16;
assign lsh_s_f16 = lsh_overflow_f16 ? lsh_overflow_s_f16 : lsh_normal_s_f16;

assign lsh_l_uf_check_f16 = lsh_overflow_f16 ? lsh_overflow_l_uf_check_f16 : lsh_normal_l_uf_check_f16;
assign lsh_g_uf_check_f16 = lsh_overflow_f16 ? lsh_overflow_g_uf_check_f16 : lsh_normal_g_uf_check_f16;
assign lsh_s_uf_check_f16 = lsh_overflow_f16 ? lsh_overflow_s_uf_check_f16 : lsh_normal_s_uf_check_f16;

assign lsh_overflow_f32 = |(lsh_overflow_mask_f32[23:0] & sig_mul_f32[47:24]);

assign lsh_overflow_l_f32 = |(lsh_overflow_l_mask_f32[23:0] & sig_mul_f32[24:01]);
assign lsh_overflow_g_f32 = lsh_normal_l_f32;
assign lsh_overflow_s_f32 = lsh_normal_s_f32 | lsh_normal_g_f32;

assign lsh_overflow_l_uf_check_f32 = lsh_normal_l_f32;
assign lsh_overflow_g_uf_check_f32 = lsh_normal_g_f32;
assign lsh_overflow_s_uf_check_f32 = lsh_normal_s_f32;

assign lsh_normal_l_f32 = |(lsh_normal_l_mask_f32[23:0] & sig_mul_f32[23:00]);
assign lsh_normal_g_f32 = lsh_normal_l_uf_check_f32;
assign lsh_normal_s_f32 = lsh_normal_s_uf_check_f32 | lsh_normal_g_uf_check_f32;

assign lsh_normal_l_uf_check_f32 = |(lsh_normal_l_mask_uf_check_f32[22:0] & sig_mul_f32[22:00]);
assign lsh_normal_g_uf_check_f32 = |(lsh_normal_g_mask_uf_check_f32[21:0] & sig_mul_f32[21:00]);
assign lsh_normal_s_uf_check_f32 = |(lsh_normal_s_mask_uf_check_f32[20:0] & sig_mul_f32[20:00]);

assign lsh_l_f32 = lsh_overflow_f32 ? lsh_overflow_l_f32 : lsh_normal_l_f32;
assign lsh_g_f32 = lsh_overflow_f32 ? lsh_overflow_g_f32 : lsh_normal_g_f32;
assign lsh_s_f32 = lsh_overflow_f32 ? lsh_overflow_s_f32 : lsh_normal_s_f32;

assign lsh_l_uf_check_f32 = lsh_overflow_f32 ? lsh_overflow_l_uf_check_f32 : lsh_normal_l_uf_check_f32;
assign lsh_g_uf_check_f32 = lsh_overflow_f32 ? lsh_overflow_g_uf_check_f32 : lsh_normal_g_uf_check_f32;
assign lsh_s_uf_check_f32 = lsh_overflow_f32 ? lsh_overflow_s_uf_check_f32 : lsh_normal_s_uf_check_f32;

assign lsh_overflow_f64 = |(lsh_overflow_mask_f64[52:0] & sig_mul[105:53]);

assign lsh_overflow_l_f64 = |(lsh_overflow_l_mask_f64[52:0] & sig_mul[53:01]);
assign lsh_overflow_g_f64 = lsh_normal_l_f64;
assign lsh_overflow_s_f64 = lsh_normal_s_f64 | lsh_normal_g_f64;

assign lsh_overflow_l_uf_check_f64 = lsh_normal_l_f64;
assign lsh_overflow_g_uf_check_f64 = lsh_normal_g_f64;
assign lsh_overflow_s_uf_check_f64 = lsh_normal_s_f64;

assign lsh_normal_l_f64 = |(lsh_normal_l_mask_f64[52:0] & sig_mul[52:00]);
assign lsh_normal_g_f64 = lsh_normal_l_uf_check_f64;
assign lsh_normal_s_f64 = lsh_normal_s_uf_check_f64 | lsh_normal_g_uf_check_f64;

assign lsh_normal_l_uf_check_f64 = |(lsh_normal_l_mask_uf_check_f64[51:0] & sig_mul[51:00]);
assign lsh_normal_g_uf_check_f64 = |(lsh_normal_g_mask_uf_check_f64[50:0] & sig_mul[50:00]);
assign lsh_normal_s_uf_check_f64 = |(lsh_normal_s_mask_uf_check_f64[49:0] & sig_mul[49:00]);

assign lsh_l_f64 = lsh_overflow_f64 ? lsh_overflow_l_f64 : lsh_normal_l_f64;
assign lsh_g_f64 = lsh_overflow_f64 ? lsh_overflow_g_f64 : lsh_normal_g_f64;
assign lsh_s_f64 = lsh_overflow_f64 ? lsh_overflow_s_f64 : lsh_normal_s_f64;

assign lsh_l_uf_check_f64 = lsh_overflow_f64 ? lsh_overflow_l_uf_check_f64 : lsh_normal_l_uf_check_f64;
assign lsh_g_uf_check_f64 = lsh_overflow_f64 ? lsh_overflow_g_uf_check_f64 : lsh_normal_g_uf_check_f64;
assign lsh_s_uf_check_f64 = lsh_overflow_f64 ? lsh_overflow_s_uf_check_f64 : lsh_normal_s_uf_check_f64;

assign lsh_l = is_f16 ? lsh_l_f16 : is_f32 ? lsh_l_f32 : lsh_l_f64;
assign lsh_g = is_f16 ? lsh_g_f16 : is_f32 ? lsh_g_f32 : lsh_g_f64;
assign lsh_s = is_f16 ? lsh_s_f16 : is_f32 ? lsh_s_f32 : lsh_s_f64;

assign lsh_l_uf_check = is_f16 ? lsh_l_uf_check_f16 : is_f32 ? lsh_l_uf_check_f32 : lsh_l_uf_check_f64;
assign lsh_g_uf_check = is_f16 ? lsh_g_uf_check_f16 : is_f32 ? lsh_g_uf_check_f32 : lsh_g_uf_check_f64;
assign lsh_s_uf_check = is_f16 ? lsh_s_uf_check_f16 : is_f32 ? lsh_s_uf_check_f32 : lsh_s_uf_check_f64;

assign exp_mul = (do_rsh | exp_lsh_neg) ? '0 : exp_lsh[11:0];
assign exp_mul_p1 = exp_mul + 12'd1;
assign exp_mul_overflow = is_f16 ? exp_mul[5] : is_f32 ? exp_mul[8] : exp_mul[11];
assign exp_mul_inf = (exp_mul[11:0] == (is_f16 ? {7'b0, {(5){1'b1}}} : is_f32 ? {4'b0, {(8){1'b1}}} : {1'b0, {(11){1'b1}}}));
assign exp_mul_max = (exp_mul[11:0] == (is_f16 ? {7'b0, {(4){1'b1}}, 1'b0} : is_f32 ? {4'b0, {(7){1'b1}}, 1'b0} : {1'b0, {(10){1'b1}}, 1'b0}));
assign exp_mul_zero = ~(|exp_mul);

assign sig_mul[105:0] = siga * sigb;
assign sig_mul_f16[21:0] = sig_mul[105 -: 22];
assign sig_mul_f32[47:0] = sig_mul[105 -: 48];

// When "do_rsh", we should do 1-bit rsh at least
assign sig_mul_rsh[106:0] = {sig_mul[105:0], 1'b0} >> rsh_num;
assign sig_mul_lsh[105:0] = sig_mul << lsh_num;

// Since "rsh_num_temp = 1 - exp_no_lsh", if (rsh_num >= 2), even "sig_mul >= 10.0", we still get a denormal res
assign rsh_overflow = sig_mul[105] & (rsh_num == 6'd1);
// assign lsh_overflow = sig_mul_lsh[105];
assign lsh_overflow = is_f16 ? lsh_overflow_f16 : is_f32 ? lsh_overflow_f32 : lsh_overflow_f64;

assign l_for_round = do_rsh ? rsh_l : lsh_l;
assign g_for_round = do_rsh ? rsh_g : lsh_g;
assign s_for_round = do_rsh ? rsh_s : lsh_s;

assign l_for_uf_check = do_rsh ? rsh_l_uf_check : lsh_l_uf_check;
assign g_for_uf_check = do_rsh ? rsh_g_uf_check : lsh_g_uf_check;
assign s_for_uf_check = do_rsh ? rsh_s_uf_check : lsh_s_uf_check;

assign rne = (rm_i == RM_RNE);
assign rtz_temp = (rm_i == RM_RTZ);
assign rdn_temp = (rm_i == RM_RDN);
assign rup_temp = (rm_i == RM_RUP);
assign rmm = (rm_i == RM_RMM);

assign rtz = 
  ( sign_mul & rup_temp)
| (~sign_mul & rdn_temp)
| rtz_temp;
assign rup = 
  ( sign_mul & rdn_temp)
| (~sign_mul & rup_temp);

assign round_up = 
  (rne & (g_for_round & (l_for_round | s_for_round)))
| (rup & (g_for_round | s_for_round))
| (rmm & (g_for_round));

assign round_up_uf_check = 
  (rne & (g_for_uf_check & (l_for_uf_check | s_for_uf_check)))
| (rup & (g_for_uf_check | s_for_uf_check))
| (rmm & (g_for_uf_check));

// 1. do_rsh: the decimal point is between "sig_mul_rsh[105] and sig_mul_rsh[104]"
// 2. ~do_rsh &  lsh_overflow: the decimal point is between "sig_mul_lsh[105] and sig_mul_lsh[104]"
// 3. ~do_rsh & ~lsh_overflow: the decimal point is between "sig_mul_lsh[104] and sig_mul_lsh[103]"
assign frac_fma_f16 = 
  ({(21){ do_rsh}} & sig_mul_rsh[104 -: 21])
| ({(21){~do_rsh &  lsh_overflow}} & sig_mul_lsh[104 -: 21])
| ({(21){~do_rsh & ~lsh_overflow}} & {sig_mul_lsh[103 -: 20], 1'b0});
assign frac_fma_f32 = 
  ({(47){ do_rsh}} & sig_mul_rsh[104 -: 47])
| ({(47){~do_rsh &  lsh_overflow}} & sig_mul_lsh[104 -: 47])
| ({(47){~do_rsh & ~lsh_overflow}} & {sig_mul_lsh[103 -: 46], 1'b0});
assign frac_fma_f64 = 
  ({(105){ do_rsh}} & sig_mul_rsh[104 -: 105])
| ({(105){~do_rsh &  lsh_overflow}} & sig_mul_lsh[104 -: 105])
| ({(105){~do_rsh & ~lsh_overflow}} & {sig_mul_lsh[103 -: 104], 1'b0});

assign frac_unrounded_fmul = frac_fma_f64[104 -: 52];
assign frac_unrounded_all_1_fmul = is_f16 ? (&frac_unrounded_fmul[51 -: 10]) : is_f32 ? (&frac_unrounded_fmul[51 -: 23]) : (&frac_unrounded_fmul);

// F16: frac_unrounded_fmul[104:95]
// F32: frac_unrounded_fmul[104:82]
// F64: frac_unrounded_fmul[104:53]
assign round_up_poisition = 
  ({(52){is_f16}} & {{( 9){1'b0}}, round_up, {(52 - 10){1'b0}}})
| ({(52){is_f32}} & {{(22){1'b0}}, round_up, {(52 - 23){1'b0}}})
| ({(52){is_f64}} & {{(51){1'b0}}, round_up, {(52 - 52){1'b0}}});
assign frac_rounded_fmul = frac_unrounded_fmul + round_up_poisition;
assign sel_exp_p1_fmul = sel_overflow_exp | (round_up & frac_unrounded_all_1_fmul);
assign sel_overflow_res_fmul = (exp_mul_overflow | exp_mul_inf | (exp_mul_max & ((~do_rsh & sig_mul[105]) | (round_up & frac_unrounded_all_1_fmul))));

assign lsh_denormal_to_normal = sig_mul_lsh[104] & exp_lsh_zero;
assign sel_overflow_exp = do_rsh ? rsh_overflow : (lsh_overflow | lsh_denormal_to_normal);
assign exp_fma[10:0] = sel_overflow_exp ? exp_mul_p1[10:0] : exp_mul[10:0];
assign exp_fmul[10:0] = sel_exp_p1_fmul ? exp_mul_p1[10:0] : exp_mul[10:0];
assign exp_fmul_before_rounding[10:0] = exp_fma;

assign overflow_res_fmul_f16 = {
    sign_mul,
    {(4){1'b1}}, ~rtz,
    {(10){rtz}}
};
assign overflow_res_fmul_f32 = {
    sign_mul,
    {(7){1'b1}}, ~rtz,
    {(23){rtz}}
};
assign overflow_res_fmul_f64 = {
    sign_mul,
    {(10){1'b1}}, ~rtz,
    {(52){rtz}}
};

assign exp_special_fmul_f16 = exp_special_f16;
assign frac_special_fmul_f16 = (res_snan | res_qnan) ? {1'b1, {(10 - 1){1'b0}}} : '0;
assign exp_special_fmul_f32 = exp_special_f32;
assign frac_special_fmul_f32 = (res_snan | res_qnan) ? {1'b1, {(23 - 1){1'b0}}} : '0;
assign exp_special_fmul_f64 = exp_special_f64;
assign frac_special_fmul_f64 = (res_snan | res_qnan) ? {1'b1, {(52 - 1){1'b0}}} : '0;
assign special_res_fmul_f16 = {
    sign_special,
    exp_special_fmul_f16,
    frac_special_fmul_f16
};
assign special_res_fmul_f32 = {
    sign_special,
    exp_special_fmul_f32,
    frac_special_fmul_f32
};
assign special_res_fmul_f64 = {
    sign_special,
    exp_special_fmul_f64,
    frac_special_fmul_f64
};

assign fmul_res_f16 = 
sel_special ? special_res_fmul_f16 :
sel_overflow_res_fmul ? overflow_res_fmul_f16 : {
    sign_mul,
    exp_fmul[0 +: 5],
    frac_rounded_fmul[51 -: 10]
};
assign fmul_res_f32 = 
sel_special ? special_res_fmul_f32 :
sel_overflow_res_fmul ? overflow_res_fmul_f32 : {
    sign_mul,
    exp_fmul[0 +: 8],
    frac_rounded_fmul[51 -: 23]
};
assign fmul_res_f64 = 
sel_special ? special_res_fmul_f64 :
sel_overflow_res_fmul ? overflow_res_fmul_f64 : {
    sign_mul,
    exp_fmul[0 +: 11],
    frac_rounded_fmul[51 -: 52]
};

assign fmul_res_o = 
  ({(64){is_f16}} & {{(64 - 16){1'b0}}, fmul_res_f16})
| ({(64){is_f32}} & {{(64 - 32){1'b0}}, fmul_res_f32})
| ({(64){is_f64}} & {{(64 - 64){1'b0}}, fmul_res_f64});


assign invalid_operation_fmul = opa_snan | opb_snan | (opa_zero & opb_inf) | (opb_zero & opa_inf);
assign overflow_fmul = ~sel_special & sel_overflow_res_fmul;

assign underflow_fmul =
  ~sel_special
& inexact_fmul
& (exp_fmul_before_rounding == '0) & ~exp_mul_overflow & ~exp_mul_inf
& ((UF_AFTER_ROUNDING == '0) ? 1'b1 : ~(frac_unrounded_all_1_fmul & l_for_uf_check & round_up_uf_check));

assign inexact_fmul = ~sel_special & (sel_overflow_res_fmul | g_for_round | s_for_round);
assign fmul_fflags_o = {
    invalid_operation_fmul,
    1'b0,
    overflow_fmul,
    underflow_fmul,
    inexact_fmul
};

// When inputs have snan, or we meet "Inf * Zero", send a special "snan" to fadd, so it can generate a "invalid operation" fflag.
assign res_snan = opa_snan | opb_snan | (opa_zero & opb_inf) | (opb_zero & opa_inf);
assign res_qnan = (opa_qnan & ~opb_snan) | (~opa_snan & opb_qnan);
assign res_zero = (opa_zero & ~expb_all_1) | (opb_zero & ~expa_all_1);
assign res_inf = (opa_inf & ~opb_qnan & ~opb_snan & ~opb_zero) | (opb_inf & ~opa_qnan & ~opa_snan & ~opa_zero);

assign sel_special = 
  res_snan
| res_qnan
| res_zero
| res_inf;

assign sign_special = (res_snan | res_qnan) ? 1'b0 : sign_mul;
assign exp_special_f16 = (res_snan | res_qnan | res_inf) ? {(5){1'b1}} : '0;
assign frac_special_f16 = res_snan ? {{(10 - 1){1'b0}}, 1'b1, {(21 - 10){1'b0}}} : res_qnan ? {1'b1, {(10 - 1){1'b0}}, {(21 - 10){1'b0}}} : '0;
assign exp_special_f32 = (res_snan | res_qnan | res_inf) ? {(8){1'b1}} : '0;
assign frac_special_f32 = res_snan ? {{(23 - 1){1'b0}}, 1'b1, {(47 - 23){1'b0}}} : res_qnan ? {1'b1, {(23 - 1){1'b0}}, {(47 - 23){1'b0}}} : '0;
assign exp_special_f64 = (res_snan | res_qnan | res_inf) ? {(11){1'b1}} : '0;
assign frac_special_f64 = res_snan ? {{(52 - 1){1'b0}}, 1'b1, {(105 - 52){1'b0}}} : res_qnan ? {1'b1, {(52 - 1){1'b0}}, {(105 - 52){1'b0}}} : '0;

assign fma_intermediate_res_f16 = sel_special ? {sign_special, exp_special_f16, frac_special_f16} : {sign_mul, exp_fma[ 4:0], frac_fma_f16};
assign fma_intermediate_res_f32 = sel_special ? {sign_special, exp_special_f32, frac_special_f32} : {sign_mul, exp_fma[ 7:0], frac_fma_f32};
assign fma_intermediate_res_f64 = sel_special ? {sign_special, exp_special_f64, frac_special_f64} : {sign_mul, exp_fma[10:0], frac_fma_f64};
assign fma_intermediate_res_o = 
  ({(117){is_f16}} & {{(117 -  27){1'b0}}, fma_intermediate_res_f16})
| ({(117){is_f32}} & {{(117 -  56){1'b0}}, fma_intermediate_res_f32})
| ({(117){is_f64}} & {{(117 - 117){1'b0}}, fma_intermediate_res_f64});

assign fma_mul_sticky_o = do_rsh & (is_f16 ? fma_mul_sticky_f16 : is_f32 ? fma_mul_sticky_f32 : fma_mul_sticky_f64);
assign fma_inputs_nan_inf_o = expa_all_1 | expb_all_1;
// 
assign fma_mul_exp_gt_inf_o = ~fma_inputs_nan_inf_o & (exp_mul_overflow | (~do_rsh & sig_mul[105] & exp_mul_inf));

endmodule

