// ========================================================================================================
// File Name			: fadd16.sv
// Author				: HYF
// How to Contact		: hyf_sysu@qq.com
// Created Time    		: June 2nd 2024, 11:30:13
// Last Modified Time   : July 3rd 2024, 15:59:26
// ========================================================================================================
// Description	:
// A 2-cyc pipelined Floating Point Adder.
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

module fadd16 #(
	// Put some parameters here, which can be changed by other modules
	parameter UF_AFTER_ROUNDING = 1
)(	
	input  logic [16 - 1:0] 	opa_i,
    // [26]: sign
    // [25:21]: exp
    // [20:11]: frac
    // [11:0]: fma_vld_i ? frac : "Don't Care"
	input  logic [27 - 1:0] 	opb_i,
	input  logic [ 3 - 1:0] 	rm_i,
	input  logic            	s0_vld_i,
	input  logic            	fma_vld_i,
	// For FMA (a * b + c), opa_i = c, opb_i = a * b
	// 1. a or b is nan/inf
	// fma_mul_exp_gt_inf_i = 0
	// fma_mul_sticky_i = X
	// fma_inputs_nan_inf_i = 1
	// 2. "exp of a * b" is greater than {(11){1'b1}}
	// fma_mul_exp_gt_inf_i = 1
	// fma_mul_sticky_i = X
	// fma_inputs_nan_inf_i = 0
	// 3. a and b are normal numbers, "exp of a * b" is equal to {(11){1'b1}}
	// fma_mul_exp_gt_inf_i = 0
	// fma_mul_sticky_i = 0
	// fma_inputs_nan_inf_i = 0
	input  logic            	fma_mul_exp_gt_inf_i,
	input  logic            	fma_mul_sticky_i,
	input  logic            	fma_inputs_nan_inf_i,

	output logic [16 - 1:0] 	fadd_res_o,
	output logic [ 5 - 1:0] 	fadd_fflags_o,

	input  logic 			    clk,
	input  logic 			    rst_n
);

// ================================================================================================================================================
// (local) parameters begin

localparam F16_EXP_W = 5;
localparam F16_FRAC_W = 10;
// (11-bit) * (11-bit) = 22-bit -> There would be 21-bit frac for FMA at most
localparam F16_FRAC_FMA_W = 21;


localparam RM_RNE = 3'b000;
localparam RM_RTZ = 3'b001;
localparam RM_RDN = 3'b010;
localparam RM_RUP = 3'b011;
localparam RM_RMM = 3'b100;

// (local) parameters end
// ================================================================================================================================================

// ================================================================================================================================================
// signals begin

// Some abbreviations:
// sig = significand
// exp = exponent
// man = mantissa
// frac = fraction
// dn = denormal
// nm = normal
// lsh = left shift
// rsh = right shift

logic signa;
logic signb;
logic [5 - 1:0] expa;
logic [5 - 1:0] expb;
logic [21 - 1:0] fraca;
logic [21 - 1:0] fracb;
logic [22 - 1:0] siga;
logic [22 - 1:0] sigb;

logic do_sub;
logic do_add;

logic fracb_low_bits_zero;
logic fraca_zero;
logic fracb_zero;
logic fraca_eq_fracb_high_bits;
logic fraca_eq_fracb;

logic expa_all_1;
logic expb_all_1;
logic expa_zero;
logic expb_zero;
logic opa_zero;
logic opb_zero;
logic opa_inf;
logic opb_inf;
logic opa_qnan;
logic opa_snan;
logic opa_nan;
logic opb_qnan;
logic opb_snan;
logic opb_nan;

logic expa_ge_expb;
logic expb_gt_expa;
logic [5 - 1:0] expa_sub_expb;
logic expb_ge_expa;
logic expa_gt_expb;
logic [5 - 1:0] expb_sub_expa;
logic expa_eq_expb;
logic fracb_ge_fraca;
logic [10 - 1:0] fracb_sub_fraca;
logic opb_ge_opa;

logic sign_large;
logic [5 - 1:0] exp_large;
logic exact_zero_sign;
logic inf_sign;

logic res_exact_zero_or_inf_sign_s1_d;
logic res_exact_zero_or_inf_sign_s1_q;
logic res_non_special_sign_s1_d;
logic res_non_special_sign_s1_q;
logic res_nan_s1_d;
logic res_nan_s1_q;
logic invalid_operation_s1_d;
logic invalid_operation_s1_q;
logic res_exact_zero_s1_d;
logic res_exact_zero_s1_q;
logic opb_overflow_s1_d;
logic opb_overflow_s1_q;
logic res_inf_s1_d;
logic res_inf_s1_q;

logic sig_rsh1;
logic close_opa_rsh1;
logic close_opb_rsh1;
logic [23 - 1:0] close_siga_opa_larger;
logic [23 - 1:0] close_sigb_opa_larger;
logic [23 - 1:0] close_siga_opb_larger;
logic [23 - 1:0] close_sigb_opb_larger;
logic a_sub_b_cin;
logic [23 - 1:0] close_a_sub_b;
logic [23 - 1:0] close_b_sub_a;
logic [24 - 1:0] close_sum;
logic expa_sub_expb_eq_1;
logic expb_sub_expa_eq_1;
logic use_close_path;
logic use_far_path;
logic close_opa_larger;
logic close_opb_larger;

logic lza_limited_by_exp_opa_larger;
logic lza_limited_by_exp_opb_larger;
logic [5 - 1:0] lza_opa_larger;
logic [5 - 1:0] lza_opb_larger;
logic [14 - 1:0] overflow_l_mask_opa_larger;
logic [14 - 1:0] overflow_l_mask_opb_larger;
logic [13 - 1:0] overflow_g_mask_opa_larger;
logic [13 - 1:0] overflow_g_mask_opb_larger;
logic [13 - 1:0] normal_l_mask_opa_larger;
logic [13 - 1:0] normal_l_mask_opb_larger;
logic [12 - 1:0] normal_g_mask_opa_larger;
logic [12 - 1:0] normal_g_mask_opb_larger;
logic [12 - 1:0] overflow_s_mask_opa_larger;
logic [12 - 1:0] overflow_s_mask_opb_larger;
logic [11 - 1:0] normal_s_mask_opa_larger;
logic [11 - 1:0] normal_s_mask_opb_larger;

logic [5 - 1:0] close_lza;
logic [5 - 1:0] close_exp;
logic close_lza_limited_by_exp;

logic [14 - 1:0] close_overflow_l_mask;
logic [13 - 1:0] close_overflow_g_mask;
logic [12 - 1:0] close_overflow_s_mask;
logic [13 - 1:0] close_normal_l_mask;
logic [12 - 1:0] close_normal_g_mask;
logic [11 - 1:0] close_normal_s_mask;
logic [13 - 1:0] overflow_l_mask_uf_check_opa_larger;
logic [12 - 1:0] overflow_g_mask_uf_check_opa_larger;
logic [11 - 1:0] overflow_s_mask_uf_check_opa_larger;
logic [12 - 1:0] normal_l_mask_uf_check_opa_larger;
logic [11 - 1:0] normal_g_mask_uf_check_opa_larger;
logic [10 - 1:0] normal_s_mask_uf_check_opa_larger;
logic [13 - 1:0] overflow_l_mask_uf_check_opb_larger;
logic [12 - 1:0] overflow_g_mask_uf_check_opb_larger;
logic [11 - 1:0] overflow_s_mask_uf_check_opb_larger;
logic [12 - 1:0] normal_l_mask_uf_check_opb_larger;
logic [11 - 1:0] normal_g_mask_uf_check_opb_larger;
logic [10 - 1:0] normal_s_mask_uf_check_opb_larger;
logic [13 - 1:0] close_overflow_l_mask_uf_check;
logic [12 - 1:0] close_overflow_g_mask_uf_check;
logic [11 - 1:0] close_overflow_s_mask_uf_check;
logic [12 - 1:0] close_normal_l_mask_uf_check;
logic [11 - 1:0] close_normal_g_mask_uf_check;
logic [10 - 1:0] close_normal_s_mask_uf_check;

logic close_overflow_l;
logic close_overflow_g;
logic close_overflow_s;
logic close_normal_l;
logic close_normal_g;
logic close_normal_s;
logic close_overflow_l_uf_check;
logic close_overflow_g_uf_check;
logic close_overflow_s_uf_check;
logic close_normal_l_uf_check;
logic close_normal_g_uf_check;
logic close_normal_s_uf_check;

logic [24 - 1:0] close_sum_lsh_l0;
logic [24 - 1:0] close_sum_lsh_l1;
logic [24 - 1:0] close_sum_lsh_l2;
logic [24 - 1:0] close_sum_lsh_l3;
logic [24 - 1:0] close_sum_lsh_l4;
logic [12 - 1:0] close_sum_unrounded;

logic [5 - 1:0] a_rsh_num;
logic cout_lsb_of_expb_sub_expa;
logic [24 - 1:0] siga_rsh_in;
logic [24 - 1:0] siga_rsh_l0;
logic [24 - 1:0] siga_rsh_l1;
logic [24 - 1:0] siga_rsh_l2;
logic [24 - 1:0] siga_rsh_l3;
logic [24 - 1:0] siga_rsh_l4;
logic [23 - 1:0] siga_rsh_l5;

logic [5 - 1:0] b_rsh_num;
logic cout_lsb_of_expa_sub_expb;
logic [24 - 1:0] sigb_rsh_in;
logic [24 - 1:0] sigb_rsh_l0;
logic [24 - 1:0] sigb_rsh_l1;
logic [24 - 1:0] sigb_rsh_l2;
logic [24 - 1:0] sigb_rsh_l3;
logic [24 - 1:0] sigb_rsh_l4;
logic [23 - 1:0] sigb_rsh_l5;

logic [23 - 1:0] sig_small_rsh_l6;
logic [23 - 1:0] sig_small_rsh_l7;
logic [4:4] rsh_num;
logic [23 - 1:0] far_sig_small;
logic [22 - 1:0] sig_large;
logic [23 - 1:0] far_sig_large;
logic [22 - 1:0] lost_bits_mask_opa_larger;
logic [22 - 1:0] lost_bits_mask_opb_larger;
logic a_rsh_lost_bits_non_zero;
logic b_rsh_lost_bits_non_zero;
logic rsh_lost_bits_non_zero;

logic far_cin;
logic [23 - 1:0] far_sum;
logic [12 - 1:0] far_sum_unrounded;
logic [5 - 1:0] far_exp;

logic [11 - 1:0] far_sum_low_bits_sum;
logic [11 - 1:0] far_sum_low_bits_carry;
logic [10 - 1:0] far_sum_low_bits_xor;
logic [10 - 1:0] far_sum_low_bits_or;
logic far_overflow_l;
logic far_overflow_g;
logic far_overflow_s;
logic far_normal_l;
logic far_normal_g;
logic far_normal_s;
logic far_overflow_l_uf_check;
logic far_overflow_g_uf_check;
logic far_overflow_s_uf_check;
logic far_normal_l_uf_check;
logic far_normal_g_uf_check;
logic far_normal_s_uf_check;

logic rne;
logic rtz_temp;
logic rdn_temp;
logic rup_temp;
logic rmm;
logic rtz;
logic rup;

logic far_overflow;
logic far_l;
logic far_g;
logic far_s;
logic far_inexact;
logic far_round_up;
logic far_l_uf_check;
logic far_g_uf_check;
logic far_s_uf_check;
logic far_round_up_uf_check;

logic close_overflow;
logic close_l;
logic close_g;
logic close_s;
logic close_inexact;
logic close_round_up;
logic close_l_uf_check;
logic close_g_uf_check;
logic close_s_uf_check;
logic close_round_up_uf_check;

logic sum_overflow_before_rounding_s1_d;
logic sum_overflow_before_rounding_s1_q;
logic [11 - 1:0] sig_sum_unrounded_s1_d;
logic [11 - 1:0] sig_sum_unrounded_s1_q;
logic round_up_s1_d;
logic round_up_s1_q;
logic round_up_uf_check_s1_d;
logic round_up_uf_check_s1_q;
logic l_uf_check_s1_d;
logic l_uf_check_s1_q;
logic [5 - 1:0] exp_s1_d;
logic [5 - 1:0] exp_s1_q;
logic inexact_s1_d;
logic inexact_s1_q;
logic fma_vld_s1_d;
logic fma_vld_s1_q;
logic rtz_s1_d;
logic rtz_s1_q;

logic [10 - 1:0] sig_sum_rounded_s1;
logic frac_unrounded_all_1_s1;
logic sum_overflow_after_rounding_s1;
logic denormal_before_rounding_s1;
logic [5 - 1:0] exp_adjusted_s1;
logic [5 - 1:0] exp_plus_1_s1;
logic [5 - 1:0] exp_plus_2_s1;
logic exp_max_s1;
logic exp_max_m1_s1;
logic exp_inf_s1;
logic sel_overflow_res_s1;
logic sel_special_res_s1;
logic [ 5 - 1:0] normal_exp_s1;
logic [16 - 1:0] normal_res_s1;
logic [16 - 1:0] overflow_res_s1;
logic [16 - 1:0] special_res_s1;

logic underflow_s1;
logic overflow_s1;
logic inexact_s1;


// signals end
// ================================================================================================================================================


assign signa = opa_i[15];
assign signb = opb_i[26];
assign expa = opa_i[14:10];
assign expb = opb_i[25:21];
assign fraca[20:0] = {opa_i[9:0], 11'b0};
assign fracb[20:0] = {opb_i[20:11], fma_vld_i ? opb_i[10:0] : 11'b0};
assign siga = {~expa_zero, fraca};
assign sigb = {~expb_zero, fracb};

assign do_sub = signa ^ signb;
assign do_add = ~do_sub;

assign fracb_low_bits_zero = fma_vld_i ? ((fracb[10:0] == '0) & ~fma_mul_sticky_i) : 1'b1;
assign fraca_zero = (fraca[20:11] == '0);
assign fracb_zero = (fracb[20:11] == '0) & fracb_low_bits_zero;
assign fraca_eq_fracb_high_bits = (fraca[20:11] == fracb[20:11]);
assign fraca_eq_fracb = fraca_eq_fracb_high_bits & fracb_low_bits_zero;

assign expa_all_1 =  (&expa);
assign expb_all_1 =  (&expb);
assign expa_zero  = ~(|expa);
assign expb_zero  = ~(|expb);

assign opa_zero = expa_zero & fraca_zero;
assign opb_zero = expb_zero & fracb_zero;

assign opa_inf = expa_all_1 & fraca_zero;
// For fma, if a/b is neither inf/nan, then "a * b" should not be regarded as inf, even if the exp of mul is all 1
assign opb_inf = (fma_vld_i & ~fma_inputs_nan_inf_i) ? 1'b0 : (expb_all_1 & (fracb[20:11] == '0));

assign opa_qnan = expa_all_1 &  fraca[20];
assign opa_snan = expa_all_1 & ~fraca[20] & (fraca[19:11] != '0);
assign opa_nan = opa_qnan | opa_snan;

// For fma, if a/b is neither inf/nan, then "a * b" should not be regarded as nan, even if the exp of mul is all 1
// For fma, when "a * b" is a nan result, we would set "fracb[10:0] = 0" in fmul, so we only need to check fracb[20:11]
assign opb_qnan = (fma_vld_i & ~fma_inputs_nan_inf_i) ? 1'b0 : (expb_all_1 &  fracb[20]);
assign opb_snan = (fma_vld_i & ~fma_inputs_nan_inf_i) ? 1'b0 : (expb_all_1 & ~fracb[20] & (fracb[19:11] != '0));
assign opb_nan = opb_qnan | opb_snan;

assign {expa_ge_expb, expa_sub_expb[4:0]} = {1'b0, expa[4:0]} + {1'b0, ~expb[4:0]} + {5'b0, 1'b1};
assign expb_gt_expa = ~expa_ge_expb;

assign {expb_ge_expa, expb_sub_expa[4:0]} = {1'b0, expb[4:0]} + {1'b0, ~expa[4:0]} + {5'b0, 1'b1};
assign expa_gt_expb = ~expb_ge_expa;

assign expa_eq_expb = (expa == expb);

// For fma, when ({fracb[10:0], fma_mul_sticky_i} != 0), we would also get "fracb_ge_fraca" by using the folloing expression
assign {fracb_ge_fraca, fracb_sub_fraca[9:0]} = {1'b0, fracb[20:11]} + {1'b0, ~fraca[20:11]} + {10'b0, 1'b1};
assign opb_ge_opa = expb_gt_expa | (expa_eq_expb & fracb_ge_fraca);

assign sign_large = (opb_ge_opa | (fma_vld_i & fma_mul_exp_gt_inf_i)) ? signb : signa;
assign exp_large = expb_gt_expa ? expb : expa;

// IEEE 754:
// When the sum of two operands with opposite signs (or the difference of two operands with like signs) is
// exactly zero, the sign of that sum (or difference) shall be +0 under all rounding-direction attributes except
// roundTowardNegative; under that attribute, the sign of an exact zero sum (or difference) shall be -0.
// However, under all rounding-direction attributes, when x is zero, x+x and x-(-x) have the sign of x.

// When (a*b)+c is exactly zero, the sign of fusedMultiplyAdd(a, b, c) shall be determined by the rules
// above for a sum of operands. When the exact result of (a*b)+c is non-zero yet the result of
// fusedMultiplyAdd is zero because of rounding, the zero result takes the sign of the exact result. 

// 1. |opa| = |opb|, and opa != opb : Only "opa - opb" could lead to "exact_zero result". So we would have "signa = ~signb, (signa | signb) = 1" -> Only "rtz = 1" could lead to "exact_zero_sign = 1"
// 2. opa = opb = +0/-0 : result is exact_zero, and "signa & signb = signa | signb = signa" -> We correctly retain the sign of opa
assign exact_zero_sign = 
  (~rdn_temp & (signa & signb))
| ( rdn_temp & (signa | signb));

// 1. opa or opb is inf: Use the sign of inf number
// 2. opa and opb is neither inf, but we get a inf result
// 2.1 For fadd, it means we are "do_add" and "signa = signb"
// 2.2 For fma, it means 1) We are "do_add" and "signa = signb" 2) We are "do_sub", |opb| is greater than MAX, and it finally leads to "|res| > MAX"
assign inf_sign = (opa_inf | opb_inf) ? ((opa_inf & signa) | (opb_inf & signb)) : signb;
// {res_inf_s1_d, res_exact_zero_s1_d} can't be 2'b11
assign res_exact_zero_or_inf_sign_s1_d = res_exact_zero_s1_d ? exact_zero_sign : inf_sign;

assign res_non_special_sign_s1_d = sign_large;

assign res_nan_s1_d = 
  opa_nan
| opb_nan
| (opa_inf & opb_inf & do_sub);

assign invalid_operation_s1_d = 
  opa_snan
| opb_snan
| (opa_inf & opb_inf & do_sub);

assign res_exact_zero_s1_d = 
  ~opa_nan
& ~opb_nan
& ~opa_inf
& ~opb_inf
& ~(fma_vld_i & fma_mul_exp_gt_inf_i)
& (	  (expa_eq_expb & fraca_eq_fracb & do_sub)
	| (opa_zero & opb_zero)
);

assign opb_overflow_s1_d = fma_vld_i & fma_mul_exp_gt_inf_i;
assign res_inf_s1_d = 	  ((opa_inf & ~opb_nan) | (opb_inf & ~opa_nan))
						& ~(opa_inf & opb_inf & do_sub);

always_ff @(posedge clk) begin
	if(s0_vld_i) begin
		res_nan_s1_q <= res_nan_s1_d;
		res_exact_zero_s1_q <= res_exact_zero_s1_d;
		res_inf_s1_q <= res_inf_s1_d;
		opb_overflow_s1_q <= opb_overflow_s1_d;
		invalid_operation_s1_q <= invalid_operation_s1_d;

		res_non_special_sign_s1_q <= res_non_special_sign_s1_d;
		res_exact_zero_or_inf_sign_s1_q <= res_exact_zero_or_inf_sign_s1_d;
	end
end

// ================================================================================================================================================
// Close path
// ================================================================================================================================================

// If opa/opb is a denormal number and we are using close_path, the denormal number doesn't need rsh
assign close_opa_rsh1 = (expa[0] ^ expb[0]) & ~expa_zero;
assign close_opb_rsh1 = (expa[0] ^ expb[0]) & ~expb_zero;

assign close_siga_opa_larger = {siga[21:0], 1'b0};
assign close_sigb_opa_larger = close_opb_rsh1 ? {1'b0, sigb[21:0]} : {sigb[21:0], 1'b0};
assign close_siga_opb_larger = close_opa_rsh1 ? {1'b0, siga[21:0]} : {siga[21:0], 1'b0};
assign close_sigb_opb_larger = {sigb[21:0], 1'b0};

assign a_sub_b_cin = ~(fma_vld_i & fma_mul_sticky_i);
assign close_a_sub_b = close_siga_opa_larger + ~close_sigb_opa_larger + {22'b0, a_sub_b_cin};
assign close_b_sub_a = close_sigb_opb_larger + ~close_siga_opb_larger + {22'b0, 1'b1};
// For close_path, we always "Let" the frac at least lsh 1-bit, so we would have "lza = lzc" or "lza = lzc + 1".
// Finally, the lsh result of close_path have 2 cases: 1) Overflow. 2) Normal. And these 2 cases can be handled in the same way as far_path.
assign close_sum[23:0] = {1'b0, close_opa_larger ? close_a_sub_b : close_b_sub_a};


// How to check "{1'b0, a[N:0]} = {1'b0, b[N:0]} + 1" ?
// We have:
// a - b - 1 = a + ~b + 1 - 1 = a + ~b = 0
// If "x + y = 0", then:
// (x[N:1] ^ y[N:1]) = (x[N - 1:0] | y[N - 1:0]) -> (x[N:1] ^ y[N:1]) ^ (x[N - 1:0] | y[N - 1:0]) = {(N){1'b0}}
// So,
// ~((x[N:1] ^ y[N:1]) ^ (x[N - 1:0] | y[N - 1:0])) = {(N){1'b1}}
// Since
// ~(x ^ y) = ~x ^ y = x ^ ~y
// So we get:
// (x[N - 1:0] | y[N - 1:0]) ^ ~(x[N:1] ^ y[N:1]) = (x[N - 1:0] | y[N - 1:0]) ^ (x[N:1] ^ ~y[N:1]) = {(N){1'b1}}
// Let "x = {1'b0, a[N:0]}, y = ~{1'b0, b[N:0]}",
// (a[N:0] | ~b[N:0]) ^ ({1'b0, a[N:1]} ^ {1'b0, b[N:1]}) = {(N){1'b1}}
// Finally, when "{1'b0, a[N:0]} = {1'b0, b[N:0]} + 1", we have:
// &((a[N:0] | ~b[N:0]) ^ ({1'b0, a[N:1]} ^ {1'b0, b[N:1]})) = 1

// ATTENTION: The above prof has problem.
// When "a = b = 0", we would also get "&((a[N:0] | ~b[N:0]) ^ ({1'b0, a[N:0]} ^ {1'b0, b[N:0]})) = 1"
// To avoid this special case, add 1'b0 in LSB
assign expa_sub_expb_eq_1 = &(({expa[4:0] | ~expb[4:0], 1'b0}) ^ ({1'b0, expa[4:0]} ^ {1'b0, expb[4:0]}));
assign expb_sub_expa_eq_1 = &(({expb[4:0] | ~expa[4:0], 1'b0}) ^ ({1'b0, expb[4:0]} ^ {1'b0, expa[4:0]}));

assign use_close_path = do_sub & (expa_eq_expb | expa_sub_expb_eq_1 | expb_sub_expa_eq_1);
assign use_far_path = ~use_close_path;

assign close_opa_larger = (expa_eq_expb & ~fracb_ge_fraca) | expa_sub_expb_eq_1;
assign close_opb_larger = (expa_eq_expb &  fracb_ge_fraca) | expb_sub_expa_eq_1;

fadd16_lza u_lza_opa_larger (
	.frac_large_i				(fraca),
	.frac_small_i				(fracb),
	.exp_large_i				(expa),
    .small_rsh1_i				(expa[0] ^ expb[0]),
    .lza_limited_by_exp_o		(lza_limited_by_exp_opa_larger),
    .lza_o						(lza_opa_larger),
    .overflow_l_mask_o			(overflow_l_mask_opa_larger),
    .overflow_g_mask_o			(overflow_g_mask_opa_larger),
	.overflow_s_mask_o			(overflow_s_mask_opa_larger),
    .normal_l_mask_o			(normal_l_mask_opa_larger),
    .normal_g_mask_o			(normal_g_mask_opa_larger),    
    .normal_s_mask_o			(normal_s_mask_opa_larger),
	.overflow_l_mask_uf_check_o	(overflow_l_mask_uf_check_opa_larger),
	.overflow_g_mask_uf_check_o	(overflow_g_mask_uf_check_opa_larger),
	.overflow_s_mask_uf_check_o	(overflow_s_mask_uf_check_opa_larger),
    .normal_l_mask_uf_check_o	(normal_l_mask_uf_check_opa_larger),
    .normal_g_mask_uf_check_o	(normal_g_mask_uf_check_opa_larger),
    .normal_s_mask_uf_check_o	(normal_s_mask_uf_check_opa_larger)
);
   
fadd16_lza u_lza_opb_larger (
	.frac_large_i				(fracb),
	.frac_small_i				(fraca),
	.exp_large_i				(expb),
    .small_rsh1_i				(expa[0] ^ expb[0]),
    .lza_limited_by_exp_o		(lza_limited_by_exp_opb_larger),
    .lza_o						(lza_opb_larger),
    .overflow_l_mask_o			(overflow_l_mask_opb_larger),
    .overflow_g_mask_o			(overflow_g_mask_opb_larger),
	.overflow_s_mask_o			(overflow_s_mask_opb_larger),
    .normal_l_mask_o			(normal_l_mask_opb_larger),
    .normal_g_mask_o			(normal_g_mask_opb_larger),    
    .normal_s_mask_o			(normal_s_mask_opb_larger),
	.overflow_l_mask_uf_check_o	(overflow_l_mask_uf_check_opb_larger),
	.overflow_g_mask_uf_check_o	(overflow_g_mask_uf_check_opb_larger),
	.overflow_s_mask_uf_check_o	(overflow_s_mask_uf_check_opb_larger),
    .normal_l_mask_uf_check_o	(normal_l_mask_uf_check_opb_larger),
    .normal_g_mask_uf_check_o	(normal_g_mask_uf_check_opb_larger),
    .normal_s_mask_uf_check_o	(normal_s_mask_uf_check_opb_larger)
);

assign close_lza = close_opa_larger ? lza_opa_larger : lza_opb_larger;
assign close_lza_limited_by_exp = close_opa_larger ? lza_limited_by_exp_opa_larger : lza_limited_by_exp_opb_larger;
assign close_exp[4:0] = close_lza_limited_by_exp ? '0 : (exp_large[4:0] - close_lza[4:0]);

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

assign close_overflow_l_mask = close_opa_larger ? overflow_l_mask_opa_larger : overflow_l_mask_opb_larger;
assign close_overflow_g_mask = close_opa_larger ? overflow_g_mask_opa_larger : overflow_g_mask_opb_larger;
assign close_overflow_s_mask = close_opa_larger ? overflow_s_mask_opa_larger : overflow_s_mask_opb_larger;
assign close_normal_l_mask = close_opa_larger ? normal_l_mask_opa_larger : normal_l_mask_opb_larger;
assign close_normal_g_mask = close_opa_larger ? normal_g_mask_opa_larger : normal_g_mask_opb_larger;
assign close_normal_s_mask = close_opa_larger ? normal_s_mask_opa_larger : normal_s_mask_opb_larger;
assign close_overflow_l_mask_uf_check = close_opa_larger ? overflow_l_mask_uf_check_opa_larger : overflow_l_mask_uf_check_opb_larger;
assign close_overflow_g_mask_uf_check = close_opa_larger ? overflow_g_mask_uf_check_opa_larger : overflow_g_mask_uf_check_opb_larger;
assign close_overflow_s_mask_uf_check = close_opa_larger ? overflow_s_mask_uf_check_opa_larger : overflow_s_mask_uf_check_opb_larger;
assign close_normal_l_mask_uf_check = close_opa_larger ? normal_l_mask_uf_check_opa_larger : normal_l_mask_uf_check_opb_larger;
assign close_normal_g_mask_uf_check = close_opa_larger ? normal_g_mask_uf_check_opa_larger : normal_g_mask_uf_check_opb_larger;
assign close_normal_s_mask_uf_check = close_opa_larger ? normal_s_mask_uf_check_opa_larger : normal_s_mask_uf_check_opb_larger;

// Start lsh from MSB of "lza"
assign close_sum_lsh_l0 = close_lza[4] ? {close_sum[7:0], 16'b0} : close_sum[23:0];
assign close_sum_lsh_l1 = close_lza[3] ? {close_sum_lsh_l0[15:0], 8'b0} : close_sum_lsh_l0[23:0];
assign close_sum_lsh_l2 = close_lza[2] ? {close_sum_lsh_l1[19:0], 4'b0} : close_sum_lsh_l1[23:0];
assign close_sum_lsh_l3 = close_lza[1] ? {close_sum_lsh_l2[21:0], 2'b0} : close_sum_lsh_l2[23:0];
assign close_sum_lsh_l4 = close_lza[0] ? {close_sum_lsh_l3[22:0], 1'b0} : close_sum_lsh_l3[23:0];

assign close_overflow_l = |(close_overflow_l_mask[13:0] & close_sum[13:0]);
assign close_overflow_g = close_overflow_l_uf_check;
assign close_overflow_s = close_overflow_g_uf_check | close_overflow_s_uf_check;

assign close_overflow_l_uf_check = close_normal_l;
assign close_overflow_g_uf_check = close_normal_g;
assign close_overflow_s_uf_check = close_normal_s;

assign close_normal_l = |(close_normal_l_mask[12:0] & close_sum[12:0]);
assign close_normal_g = close_normal_l_uf_check;
assign close_normal_s = close_normal_g_uf_check | close_normal_s_uf_check;

assign close_normal_l_uf_check = |(close_normal_l_mask_uf_check[11:0] & close_sum[11:0]);
assign close_normal_g_uf_check = |(close_normal_g_mask_uf_check[10:0] & close_sum[10:0]);
// When "fma_mul_sticky_i = 1", opb must be a denormal number. So, in close_path, we won't do any lsh, so "fma_mul_sticky_i" will still be sticky_bit
assign close_normal_s_uf_check = |(close_normal_s_mask_uf_check[09:0] & close_sum[09:0]) | (fma_vld_i & fma_mul_sticky_i);

// If we don't use "MASK" to extract {L, G}, is the timing acceptable ?
// assign close_overflow_l = close_sum_lsh_l4[13];
// assign close_overflow_g = close_sum_lsh_l4[12];
// assign close_normal_l = close_sum_lsh_l4[12];
// assign close_normal_g = close_sum_lsh_l4[11];
// assign close_overflow_l_uf_check = close_sum_lsh_l4[12];
// assign close_overflow_g_uf_check = close_sum_lsh_l4[11];
// assign close_normal_l_uf_check = close_sum_lsh_l4[11];
// assign close_normal_g_uf_check = close_sum_lsh_l4[10];

assign close_sum_unrounded[11:0] = close_sum_lsh_l4[23:12];

// ================================================================================================================================================
// Far path
// ================================================================================================================================================
// opa <= opb
assign a_rsh_num[0] = expa[0] ^ expb[0];
// expb[1:0] - expa[1:0] = expb[1:0] + ~expa[1:0] + 2'b01, the carry into [1] is:
// (expb[0] & 1) | (expb[0] & ~expa[0]) | (~expa[0] & 1) = expb[0] | (expb[0] & ~expa[0]) | ~expa[0] = expb[0] | ~expa[0]
assign cout_lsb_of_expb_sub_expa = expb[0] | ~expa[0];
assign a_rsh_num[1] = expb[1] ^ ~expa[1] ^ cout_lsb_of_expb_sub_expa;
assign a_rsh_num[3:2] = expb_sub_expa[3:2];
assign a_rsh_num[4] = expb_sub_expa[4];

// Since we don't consider whether opa is a denormal number when we are doing "expb_sub_expa", we would rsh 1 more bit when opa is a denormal number but opb is a normal number
// When "do_add", we should rsh sig_large and sig_small 1 bit, so far_sum would only have 2 cases: 1) Overflow. 2) Normal
// As a result, we could do 2 more bit in rsh process. Here we add 2'b0 after LSB
assign siga_rsh_in[23:0] = {siga[21:0], 2'b0};
// The order or rsh should be:
// rsh_num[0], rsh_num[1], do_sub/do_add, rsh_num[2], rsh_num[3], "adjustment for denormal number", expa_ge_expb, rsh_num[4]
assign siga_rsh_l0 = a_rsh_num[0] ? {1'b0, siga_rsh_in[23:1]} : {siga_rsh_in[23:0]};
assign siga_rsh_l1 = a_rsh_num[1] ? {2'b0, siga_rsh_l0[23:2]} : {siga_rsh_l0[23:0]};
assign siga_rsh_l2 = do_sub ? {~siga_rsh_l1[23:0]} : {1'b0, siga_rsh_l1[23:1]};
assign siga_rsh_l3 = a_rsh_num[2] ? {{(4){do_sub}}, siga_rsh_l2[23:4]} : {siga_rsh_l2[23:0]};
assign siga_rsh_l4 = a_rsh_num[3] ? {{(8){do_sub}}, siga_rsh_l3[23:8]} : {siga_rsh_l3[23:0]};
assign siga_rsh_l5[22:0] = (expa_zero & ~expb_zero) ? {siga_rsh_l4[22:0]} : {siga_rsh_l4[23:1]};

// opb < opa
assign b_rsh_num[0] = expa[0] ^ expb[0];
// expa[1:0] - expb[1:0] = expa[1:0] + ~expb[1:0] + 2'b01, the carry into [1] is:
// (expa[0] & 1) | (expa[0] & ~expb[0]) | (~expb[0] & 1) = expa[0] | (expa[0] & ~expb[0]) | ~expb[0] = expa[0] | ~expb[0]
assign cout_lsb_of_expa_sub_expb = expa[0] | ~expb[0];
assign b_rsh_num[1] = expa[1] ^ ~expb[1] ^ cout_lsb_of_expa_sub_expb;
assign b_rsh_num[3:2] = expa_sub_expb[3:2];
assign b_rsh_num[4] = expa_sub_expb[4];

assign sigb_rsh_in[23:0] = {sigb[21:0], 2'b0};
assign sigb_rsh_l0 = b_rsh_num[0] ? {1'b0, sigb_rsh_in[23:1]} : {sigb_rsh_in[23:0]};
assign sigb_rsh_l1 = b_rsh_num[1] ? {2'b0, sigb_rsh_l0[23:2]} : {sigb_rsh_l0[23:0]};
assign sigb_rsh_l2 = do_sub ? {~sigb_rsh_l1[23:0]} : {1'b0, sigb_rsh_l1[23:1]};
assign sigb_rsh_l3 = b_rsh_num[2] ? {{(4){do_sub}}, sigb_rsh_l2[23:4]} : {sigb_rsh_l2[23:0]};
assign sigb_rsh_l4 = b_rsh_num[3] ? {{(8){do_sub}}, sigb_rsh_l3[23:8]} : {sigb_rsh_l3[23:0]};
assign sigb_rsh_l5[22:0] = (expb_zero & ~expa_zero) ? {sigb_rsh_l4[22:0]} : {sigb_rsh_l4[23:1]};

assign sig_small_rsh_l6 = expa_ge_expb ? sigb_rsh_l5 : siga_rsh_l5;
assign rsh_num[4] = expa_ge_expb ? b_rsh_num[4] : a_rsh_num[4];
assign sig_small_rsh_l7 = rsh_num[4] ? {{(16){do_sub}}, sig_small_rsh_l6[22:16]} : {sig_small_rsh_l6[22:0]};

assign far_sig_small = sig_small_rsh_l7;
assign sig_large = expa_ge_expb ? siga : sigb;
assign far_sig_large = do_add ? {1'b0, sig_large[21:0]} : {sig_large[21:0], 1'b0};

fadd16_rsh_lost_bits_mask u_rsh_lost_bits_mask_opa_larger (
	.exp_diff_i			(expa_sub_expb),
	.exp_zero_i			(expb_zero),
	.do_sub_i			(do_sub),
    .lost_bits_mask_o	(lost_bits_mask_opa_larger)
);
fadd16_rsh_lost_bits_mask u_rsh_lost_bits_mask_opb_larger (
	.exp_diff_i			(expb_sub_expa),
	.exp_zero_i			(expa_zero),
	.do_sub_i			(do_sub),
    .lost_bits_mask_o	(lost_bits_mask_opb_larger)
);
assign a_rsh_lost_bits_non_zero = |(lost_bits_mask_opb_larger & siga);
assign b_rsh_lost_bits_non_zero = |(lost_bits_mask_opa_larger & sigb) | (fma_vld_i & fma_mul_sticky_i);
assign rsh_lost_bits_non_zero = expa_ge_expb ? b_rsh_lost_bits_non_zero : a_rsh_lost_bits_non_zero;

// Use "far_cin" to do 2-1 MUX
// far_sum_cin_0 = far_sig_large + far_sig_small
// far_sum_cin_1 = far_sig_large + far_sig_small + 1
// assign far_sum = far_cin ? far_sum_cin_1 : far_sum_cin_0;
assign far_cin = do_sub & ~rsh_lost_bits_non_zero;
assign far_sum[22:0] = far_sig_large + far_sig_small + {22'b0, far_cin};

assign far_sum_unrounded[11:0] = far_sum[22:11];
assign far_exp[4:0] = exp_large[4:0] - {4'b0, do_sub};

// In far_path,
// overflow: far_sum[22] = 1, {L, G, S} = {far_sum[12], far_sum[11], far_sum[10:0]}, {L_uf_check, G_uf_check, S_uf_check} = {far_sum[11], far_sum[10], far_sum[9:0]}
// normal: far_sum[22:21] = 01, {L, G, S} = {far_sum[11], far_sum[10], far_sum[9:0]}, {L_uf_check, G_uf_check, S_uf_check} = {far_sum[10], far_sum[9], far_sum[8:0]}
// So we need to check whether "far_sig_large[10:0] + far_sig_small[10:0] + {10'b0, far_cin} == 0"
// For "a[N - 1:0] + b[N - 1:0]"
// sum[N - 1:0] = a[N - 1:0] ^ b[N - 1:0]
// carry[N - 1:0] = {a[N - 2:0] & b[N - 2:0], 1'b0}
// Let "a = far_sig_large", "b = far_sig_small"
assign far_sum_low_bits_sum[10:0] = far_sig_large[10:0] ^ far_sig_small[10:0];
assign far_sum_low_bits_carry[10:0] = {far_sig_large[9:0] & far_sig_small[9:0], far_cin};
assign far_sum_low_bits_xor[9:0] = far_sum_low_bits_sum[10:1] ^ far_sum_low_bits_carry[10:1];
assign far_sum_low_bits_or [9:0] = far_sum_low_bits_sum[9:0] | far_sum_low_bits_carry[9:0];
// When "fma_mul_sticky_i = 1", opb must be a denormal number, we must do rsh for opb in far_path, so "fma_mul_sticky_i" will still be sticky_bit
assign far_overflow_s = (far_sum_low_bits_xor[9:0] != far_sum_low_bits_or[9:0]) | (&(far_sum_low_bits_sum[10:0] ^ far_sum_low_bits_carry[10:0])) | rsh_lost_bits_non_zero;
assign far_normal_s = (far_sum_low_bits_xor[8:0] != far_sum_low_bits_or[8:0]) | (&(far_sum_low_bits_sum[9:0] ^ far_sum_low_bits_carry[9:0])) | rsh_lost_bits_non_zero;
assign far_overflow_s_uf_check = far_normal_s;
assign far_normal_s_uf_check = (far_sum_low_bits_xor[7:0] != far_sum_low_bits_or[7:0]) | (&(far_sum_low_bits_sum[8:0] ^ far_sum_low_bits_carry[8:0])) | rsh_lost_bits_non_zero;
assign far_overflow_l = far_sum[12];
assign far_overflow_g = far_sum[11];
assign far_normal_l = far_sum[11];
assign far_normal_g = far_sum[10];
assign far_overflow_l_uf_check = far_sum[11];
assign far_overflow_g_uf_check = far_sum[10];
assign far_normal_l_uf_check = far_sum[10];
assign far_normal_g_uf_check = far_sum[09];

assign rne = (rm_i == RM_RNE);
assign rtz_temp = (rm_i == RM_RTZ);
assign rdn_temp = (rm_i == RM_RDN);
assign rup_temp = (rm_i == RM_RUP);
assign rmm = (rm_i == RM_RMM);

assign rtz = 
  ( sign_large & rup_temp)
| (~sign_large & rdn_temp)
| rtz_temp;
assign rup = 
  ( sign_large & rdn_temp)
| (~sign_large & rup_temp);

// For f16, the data width is small, we should be able to do the folloing operation in s0.
assign far_overflow = far_sum_unrounded[11];
assign far_l = far_overflow ? far_overflow_l : far_normal_l;
assign far_g = far_overflow ? far_overflow_g : far_normal_g;
assign far_s = far_overflow ? far_overflow_s : far_normal_s;
assign far_inexact = far_g | far_s;
assign far_round_up = 
  (rne & (far_g & (far_l | far_s)))
| (rup & (far_g | far_s))
| (rmm & (far_g));

assign far_l_uf_check = far_overflow ? far_overflow_l_uf_check : far_normal_l_uf_check;
assign far_g_uf_check = far_overflow ? far_overflow_g_uf_check : far_normal_g_uf_check;
assign far_s_uf_check = far_overflow ? far_overflow_s_uf_check : far_normal_s_uf_check;
assign far_round_up_uf_check = 
  (rne & (far_g_uf_check & (far_l_uf_check | far_s_uf_check)))
| (rup & (far_g_uf_check | far_s_uf_check))
| (rmm & (far_g_uf_check));

assign close_overflow = close_sum_unrounded[11];
assign close_l = close_overflow ? close_overflow_l : close_normal_l;
assign close_g = close_overflow ? close_overflow_g : close_normal_g;
assign close_s = close_overflow ? close_overflow_s : close_normal_s;
assign close_inexact = close_g | close_s;
assign close_round_up = 
  (rne & (close_g & (close_l | close_s)))
| (rup & (close_g | close_s))
| (rmm & (close_g));

assign close_l_uf_check = close_overflow ? close_overflow_l_uf_check : close_normal_l_uf_check;
assign close_g_uf_check = close_overflow ? close_overflow_g_uf_check : close_normal_g_uf_check;
assign close_s_uf_check = close_overflow ? close_overflow_s_uf_check : close_normal_s_uf_check;
assign close_round_up_uf_check = 
  (rne & (close_g_uf_check & (close_l_uf_check | close_s_uf_check)))
| (rup & (close_g_uf_check | close_s_uf_check))
| (rmm & (close_g_uf_check));

assign sum_overflow_before_rounding_s1_d = use_close_path ? close_overflow : far_overflow;
assign sig_sum_unrounded_s1_d[10:0] = use_close_path ? (close_overflow ? close_sum_unrounded[11:1] : close_sum_unrounded[10:0]) : (far_overflow ? far_sum_unrounded[11:1] : far_sum_unrounded[10:0]);
assign round_up_s1_d = use_close_path ? close_round_up : far_round_up;
assign round_up_uf_check_s1_d = use_close_path ? close_round_up_uf_check : far_round_up_uf_check;
assign l_uf_check_s1_d = use_close_path ? close_l_uf_check : far_l_uf_check;
assign exp_s1_d = use_close_path ? close_exp : far_exp;
assign inexact_s1_d = use_close_path ? close_inexact : far_inexact;
assign fma_vld_s1_d = fma_vld_i;
assign rtz_s1_d = rtz;

always_ff @(posedge clk) begin
	if(s0_vld_i) begin
		sum_overflow_before_rounding_s1_q <= sum_overflow_before_rounding_s1_d;
		sig_sum_unrounded_s1_q <= sig_sum_unrounded_s1_d;
		round_up_s1_q <= round_up_s1_d;
		round_up_uf_check_s1_q <= round_up_uf_check_s1_d;
		l_uf_check_s1_q <= l_uf_check_s1_d;
		exp_s1_q <= exp_s1_d;
		inexact_s1_q <= inexact_s1_d;
		fma_vld_s1_q <= fma_vld_s1_d;
		rtz_s1_q <= rtz_s1_d;
	end
end

// ================================================================================================================================================

assign sig_sum_rounded_s1[9:0] = sig_sum_unrounded_s1_q[9:0] + {9'b0, round_up_s1_q};
assign frac_unrounded_all_1_s1 = (&sig_sum_unrounded_s1_q[9:0]);
assign sum_overflow_after_rounding_s1 = frac_unrounded_all_1_s1 & round_up_s1_q;
// The digit in "2 ^ 0" is 0
assign denormal_before_rounding_s1 = ~sig_sum_unrounded_s1_q[10];
// For a denormal exp, if "sig_sum_unrounded_s1_q >= 1.0", we should set exp 1.
assign exp_adjusted_s1 = {exp_s1_q[4:1], ((exp_s1_q == '0) & sig_sum_unrounded_s1_q[10]) | exp_s1_q[0]};

assign exp_plus_2_s1[4:1] = exp_adjusted_s1[4:1] + 4'd1;
assign exp_plus_2_s1[0:0] = exp_adjusted_s1[0];
assign exp_plus_1_s1[4:0] = exp_adjusted_s1[0] ? {exp_plus_2_s1[4:1], 1'b0} : {exp_adjusted_s1[4:1], 1'b1};

assign exp_max_s1 = (exp_s1_q == {{(4){1'b1}}, 1'b0});
assign exp_max_m1_s1 = (exp_s1_q == {{(3){1'b1}}, 1'b0, 1'b1});
assign exp_inf_s1 = (exp_s1_q == {(5){1'b1}});

assign sel_overflow_res_s1 = 
  opb_overflow_s1_q
| ((sum_overflow_before_rounding_s1_q | sum_overflow_after_rounding_s1) & exp_max_s1)
| (sum_overflow_before_rounding_s1_q & sum_overflow_after_rounding_s1 & exp_max_m1_s1)
| (fma_vld_s1_q & exp_inf_s1);

assign normal_exp_s1 = {
	  ({(4){{sum_overflow_before_rounding_s1_q, sum_overflow_after_rounding_s1} == 2'b00}} & exp_adjusted_s1[4:1])
	| ({(4){{sum_overflow_before_rounding_s1_q, sum_overflow_after_rounding_s1} == 2'b01}} & exp_plus_1_s1[4:1])
	| ({(4){{sum_overflow_before_rounding_s1_q, sum_overflow_after_rounding_s1} == 2'b10}} & exp_plus_1_s1[4:1])
	| ({(4){{sum_overflow_before_rounding_s1_q, sum_overflow_after_rounding_s1} == 2'b11}} & exp_plus_2_s1[4:1]),
	  ({(1){{sum_overflow_before_rounding_s1_q, sum_overflow_after_rounding_s1} == 2'b00}} & exp_adjusted_s1[0])
	| ({(1){{sum_overflow_before_rounding_s1_q, sum_overflow_after_rounding_s1} == 2'b01}} & exp_plus_1_s1[0])
	| ({(1){{sum_overflow_before_rounding_s1_q, sum_overflow_after_rounding_s1} == 2'b10}} & exp_plus_1_s1[0])
	| ({(1){{sum_overflow_before_rounding_s1_q, sum_overflow_after_rounding_s1} == 2'b11}} & exp_plus_2_s1[0])
};

assign normal_res_s1 = {
	res_non_special_sign_s1_q,
	normal_exp_s1,
	sig_sum_rounded_s1[9:0]
};

assign overflow_res_s1 = {
	res_exact_zero_or_inf_sign_s1_q,
	{(4){1'b1}}, ~rtz_s1_q,
	{(10){rtz_s1_q}}
};

// Only generate default NaN
assign special_res_s1 = 
  ({(16){res_nan_s1_q}} & {1'b0, {(5){1'b1}}, 1'b1, 9'b0})
| ({(16){res_inf_s1_q}} & {res_exact_zero_or_inf_sign_s1_q, {(5){1'b1}}, 10'b0})
| ({(16){res_exact_zero_s1_q}} & {res_exact_zero_or_inf_sign_s1_q, 15'b0});

assign sel_special_res_s1 = res_nan_s1_q | res_inf_s1_q | res_exact_zero_s1_q;

assign fadd_res_o = 
sel_special_res_s1 ? special_res_s1 :
sel_overflow_res_s1 ? overflow_res_s1 :
normal_res_s1;

// "UF = 1" could only happen in fma
assign underflow_s1 =
  denormal_before_rounding_s1
& ((UF_AFTER_ROUNDING == '0) ? 1'b1 : ~(frac_unrounded_all_1_s1 & l_uf_check_s1_q & round_up_uf_check_s1_q))
& ~(res_nan_s1_q | res_inf_s1_q)
& ~opb_overflow_s1_q
& inexact_s1;


assign overflow_s1 = sel_overflow_res_s1 & ~(res_nan_s1_q | res_inf_s1_q);

assign inexact_s1 = (inexact_s1_q | sel_overflow_res_s1) & ~(res_nan_s1_q | res_inf_s1_q);

assign fadd_fflags_o = {
	invalid_operation_s1_q,
	1'b0,
	overflow_s1,
	underflow_s1,
	inexact_s1
};

endmodule


