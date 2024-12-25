// ========================================================================================================
// File Name			: fdiv_srt_to_restoring.sv
// Author				: HYF
// How to Contact		: hyf_sysu@qq.com
// Created Time    		: July 19th 2024, 19:00:40
// Last Modified Time   : July 23rd 2024, 15:11:50
// ========================================================================================================
// Description	:
// Convert SRT's result to restoring's result for faster formal proof
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

module fdiv_srt_to_restoring #(
	// Put some parameters here, which can be changed by other modules.
    parameter REM_W = 1 + 1 + 2 + 1 + 53 + 3
)(
	input  logic [53 - 1:0]     original_fraca_i,
	input  logic [53 - 1:0]     original_fracb_i,
    input  logic                fraca_lt_fracb_i,
    input  logic                iter_start_i,
    input  logic                iter_vld_i,
    input  logic                iter_end_i,
    input  logic [ 6 - 1:0]     iter_counter_i,
    input  logic [ 6 - 1:0]     quot_bits_calculated_i,
    input  logic [56 - 1:0]     srt_quot_2nd_i,
    input  logic [56 - 1:0]     srt_quot_m1_2nd_i,
    input  logic [REM_W - 1:0]  srt_f_r_s_2nd_i,
    input  logic [REM_W - 1:0]  srt_f_r_c_2nd_i,
    input  logic [ 4 - 1:0]     quot_discard_num_one_hot_i,


    input  logic                clk,
	input  logic                rst_n
);

// ================================================================================================================================================
// (local) parameters begin



// (local) parameters end
// ================================================================================================================================================

// ================================================================================================================================================
// signals begin

logic first_iter;

logic divisor_f64_en;
logic [53 - 1:0] divisor_f64_d;
logic [53 - 1:0] divisor_f64_q;
logic divisor_f32_en;
logic [24 - 1:0] divisor_f32_d;
logic [24 - 1:0] divisor_f32_q;

logic [REM_W - 1:0] srt_nr_f_r;
logic select_srt_quot_m1;
logic srt_quot_dig_1st;
logic srt_quot_dig_2nd;
logic srt_quot_dig_3rd;
logic srt_quot_dig_4th;
logic quot_en;
logic [56 - 1:0] quot_d;
logic [56 - 1:0] quot_q;
logic quot_final_en;
logic [55 - 1:0] quot_final_d;
logic [55 - 1:0] quot_final_q;

logic [54 - 1:0] rem_1st_f64;
logic [54 - 1:0] rem_2nd_f64;
logic [54 - 1:0] rem_3rd_f64;
logic [54 - 1:0] rem_4th_f64;
logic rem_f64_en;
logic [54 - 1:0] rem_f64_d;
logic [54 - 1:0] rem_f64_q;
logic rem_final_f64_en;
logic [54 - 1:0] rem_final_f64_d;
logic [54 - 1:0] rem_final_f64_q;

logic [25 - 1:0] rem_1st_f32;
logic [25 - 1:0] rem_2nd_f32;
logic [25 - 1:0] rem_3rd_f32;
logic [25 - 1:0] rem_4th_f32;
logic rem_f32_en;
logic [25 - 1:0] rem_f32_d;
logic [25 - 1:0] rem_f32_q;
logic rem_final_f32_en;
logic [25 - 1:0] rem_final_f32_d;
logic [25 - 1:0] rem_final_f32_q;

logic dividend_f64_en;
logic [54 - 1:0] dividend_f64_d;
logic [54 - 1:0] dividend_f64_q;
logic dividend_f32_en;
logic [25 - 1:0] dividend_f32_d;
logic [25 - 1:0] dividend_f32_q;

logic quot_bits_calculated_final_en;
logic [6 - 1:0] quot_bits_calculated_final_d;
logic [6 - 1:0] quot_bits_calculated_final_q;

logic [(54 + 53) - 1:0] dividend_ext_f64;
logic [(25 + 24) - 1:0] dividend_ext_f32;
logic [(54 + 53) - 1:0] quot_mul_divisor_f64;
logic [(25 + 24) - 1:0] quot_mul_divisor_f32;
logic [(54 + 53) - 1:0] quot_mul_divisor_plus_rem_f64;
logic [(25 + 24) - 1:0] quot_mul_divisor_plus_rem_f32;

// signals end
// ================================================================================================================================================

assign first_iter = (iter_counter_i == '0);

assign divisor_f64_en = iter_start_i;
assign divisor_f64_d = original_fracb_i;
assign divisor_f32_en = divisor_f64_en;
assign divisor_f32_d = original_fracb_i[52 -: 24];

assign srt_nr_f_r = srt_f_r_s_2nd_i + srt_f_r_c_2nd_i;
assign select_srt_quot_m1 = srt_nr_f_r[REM_W - 1];
assign {
    srt_quot_dig_1st,
    srt_quot_dig_2nd,
    srt_quot_dig_3rd,
    srt_quot_dig_4th
} = select_srt_quot_m1 ? {srt_quot_m1_2nd_i[3], srt_quot_m1_2nd_i[2], srt_quot_m1_2nd_i[1], srt_quot_m1_2nd_i[0]} : {srt_quot_2nd_i[3], srt_quot_2nd_i[2], srt_quot_2nd_i[1], srt_quot_2nd_i[0]};

assign quot_en = iter_start_i | iter_vld_i;
assign quot_d = iter_start_i ? '0 : {quot_q[51:0], srt_quot_dig_1st, srt_quot_dig_2nd, srt_quot_dig_3rd, srt_quot_dig_4th};

assign rem_1st_f64 = srt_quot_dig_1st ? ({rem_f64_q[52:0], 1'b0} - {1'b0, divisor_f64_q[52:0]}) : {rem_f64_q[52:0], 1'b0};
// In the 1st iter, we could only get 3-bit quot_dig -> We should skip the 1st restoring step.
assign rem_2nd_f64 = srt_quot_dig_2nd ? ((first_iter ? rem_f64_q[53:0] : {rem_1st_f64[52:0], 1'b0}) - {1'b0, divisor_f64_q[52:0]}) : (first_iter ? rem_f64_q[53:0] : {rem_1st_f64[52:0], 1'b0});
assign rem_3rd_f64 = srt_quot_dig_3rd ? ({rem_2nd_f64[52:0], 1'b0} - {1'b0, divisor_f64_q[52:0]}) : {rem_2nd_f64[52:0], 1'b0};
assign rem_4th_f64 = srt_quot_dig_4th ? ({rem_3rd_f64[52:0], 1'b0} - {1'b0, divisor_f64_q[52:0]}) : {rem_3rd_f64[52:0], 1'b0};

assign rem_f64_en = iter_start_i | iter_vld_i;
assign rem_f64_d[53:0] = iter_start_i ? (fraca_lt_fracb_i ? {original_fraca_i[52:0], 1'b0} : {1'b0, original_fraca_i[52:0]}) : rem_4th_f64;

assign dividend_f64_en = iter_start_i;
assign dividend_f64_d = fraca_lt_fracb_i ? {original_fraca_i[52:0], 1'b0} : {1'b0, original_fraca_i[52:0]};

assign dividend_f32_en = iter_start_i;
assign dividend_f32_d = fraca_lt_fracb_i ? {original_fraca_i[52 -: 24], 1'b0} : {1'b0, original_fraca_i[52 -: 24]};

assign rem_1st_f32 = srt_quot_dig_1st ? ({rem_f32_q[23:0], 1'b0} - {1'b0, divisor_f32_q[23:0]}) : {rem_f32_q[23:0], 1'b0};
// In the 1st iter, we could only get 3-bit quot_dig -> We should skip the 1st restoring step.
assign rem_2nd_f32 = srt_quot_dig_2nd ? ((first_iter ? rem_f32_q[24:0] : {rem_1st_f32[23:0], 1'b0}) - {1'b0, divisor_f32_q[23:0]}) : (first_iter ? rem_f32_q[24:0] : {rem_1st_f32[23:0], 1'b0});
assign rem_3rd_f32 = srt_quot_dig_3rd ? ({rem_2nd_f32[23:0], 1'b0} - {1'b0, divisor_f32_q[23:0]}) : {rem_2nd_f32[23:0], 1'b0};
assign rem_4th_f32 = srt_quot_dig_4th ? ({rem_3rd_f32[23:0], 1'b0} - {1'b0, divisor_f32_q[23:0]}) : {rem_3rd_f32[23:0], 1'b0};

assign rem_f32_en = rem_f64_en;
assign rem_f32_d[24:0] = iter_start_i ? (fraca_lt_fracb_i ? {original_fraca_i[52 -: 24], 1'b0} : {1'b0, original_fraca_i[52 -: 24]}) : rem_4th_f32;

assign rem_final_f64_en = iter_end_i;
assign rem_final_f64_d = 
  ({(54){quot_discard_num_one_hot_i[0]}} & rem_4th_f64)
| ({(54){quot_discard_num_one_hot_i[1]}} & rem_3rd_f64)
| ({(54){quot_discard_num_one_hot_i[2]}} & rem_2nd_f64)
| ({(54){quot_discard_num_one_hot_i[3]}} & (first_iter ? rem_f64_q : rem_1st_f64));

assign rem_final_f32_en = rem_final_f64_en;
assign rem_final_f32_d = 
  ({(25){quot_discard_num_one_hot_i[0]}} & rem_4th_f32)
| ({(25){quot_discard_num_one_hot_i[1]}} & rem_3rd_f32)
| ({(25){quot_discard_num_one_hot_i[2]}} & rem_2nd_f32)
| ({(25){quot_discard_num_one_hot_i[3]}} & (first_iter ? rem_f32_q : rem_1st_f32));

assign quot_final_en = iter_end_i;
assign quot_final_d = 
  ({(55){quot_discard_num_one_hot_i[0]}} & ({quot_q[50:0], srt_quot_dig_1st, srt_quot_dig_2nd, srt_quot_dig_3rd, srt_quot_dig_4th} >> (first_iter ? 1 : 0)))
| ({(55){quot_discard_num_one_hot_i[1]}} & ({quot_q[50:0], srt_quot_dig_1st, srt_quot_dig_2nd, srt_quot_dig_3rd, srt_quot_dig_4th} >> (first_iter ? 2 : 1)))
| ({(55){quot_discard_num_one_hot_i[2]}} & ({quot_q[50:0], srt_quot_dig_1st, srt_quot_dig_2nd, srt_quot_dig_3rd, srt_quot_dig_4th} >> (first_iter ? 3 : 2)))
| ({(55){quot_discard_num_one_hot_i[3]}} & ({quot_q[50:0], srt_quot_dig_1st, srt_quot_dig_2nd, srt_quot_dig_3rd, srt_quot_dig_4th} >> (first_iter ? 4 : 3)));

assign quot_bits_calculated_final_en = iter_end_i;
assign quot_bits_calculated_final_d = quot_bits_calculated_i - (quot_discard_num_one_hot_i[1] ? 6'd1 : quot_discard_num_one_hot_i[2] ? 6'd2 : quot_discard_num_one_hot_i[3] ? 6'd3 : 6'd0);

// After iter, we check whether "rem and quot" are correct
assign dividend_ext_f64 = {53'b0, dividend_f64_q} << ((quot_bits_calculated_final_q == '0) ? '0 : (quot_bits_calculated_final_q - 6'd1));
assign dividend_ext_f32 = {24'b0, dividend_f32_q} << ((quot_bits_calculated_final_q == '0) ? '0 : (quot_bits_calculated_final_q - 6'd1));

assign quot_mul_divisor_f64 = quot_final_q[53:0] * divisor_f64_q;
assign quot_mul_divisor_f32 = quot_final_q[24:0] * divisor_f32_q;

assign quot_mul_divisor_plus_rem_f64 = quot_mul_divisor_f64 + {53'b0, rem_final_f64_q};
assign quot_mul_divisor_plus_rem_f32 = quot_mul_divisor_f32 + {24'b0, rem_final_f32_q};

always_ff @(posedge clk) begin
	if(divisor_f64_en)
		divisor_f64_q <= divisor_f64_d;
	if(divisor_f32_en)
		divisor_f32_q <= divisor_f32_d;
	if(quot_en)
		quot_q <= quot_d;
	if(rem_f64_en)
		rem_f64_q <= rem_f64_d;
	if(rem_f32_en)
		rem_f32_q <= rem_f32_d;
	if(quot_final_en)
		quot_final_q <= quot_final_d;
	if(rem_final_f64_en)
		rem_final_f64_q <= rem_final_f64_d;
	if(rem_final_f32_en)
		rem_final_f32_q <= rem_final_f32_d;
	
    if(quot_bits_calculated_final_en)
		quot_bits_calculated_final_q <= quot_bits_calculated_final_d;
	
    if(dividend_f64_en)
		dividend_f64_q <= dividend_f64_d;
    if(dividend_f32_en)
		dividend_f32_q <= dividend_f32_d;
end


endmodule
