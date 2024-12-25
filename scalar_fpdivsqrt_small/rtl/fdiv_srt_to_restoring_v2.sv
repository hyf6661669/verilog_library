// ========================================================================================================
// File Name            : fdiv_srt_to_restoring_v2.sv
// Author                : HYF
// How to Contact        : hyf_sysu@qq.com
// Created Time            : August 5th 2024, 11:16:32
// Last Modified Time   : August 9th 2024, 10:16:26
// ========================================================================================================
// Description    :
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

module fdiv_srt_to_restoring_v2 #(
    // Put some parameters here, which can be changed by other modules.
    parameter REM_W = 1 + 1 + 2 + 1 + 53 + 3
)(
    input  logic [57 - 1:0]     scaled_dividend_i,
    input  logic [57 - 1:0]     scaled_divisor_i,
    input  logic                dividend_lt_divisor_i,
    input  logic                iter_start_i,
    input  logic                iter_vld_i,
    input  logic                iter_end_i,
    input  logic [ 6 - 1:0]     iter_counter_i,
    input  logic [ 6 - 1:0]     quot_bits_calculated_i,
    input  logic [56 - 1:0]     srt_quot_1st_i,
    input  logic [56 - 1:0]     srt_quot_m1_1st_i,
    input  logic [56 - 1:0]     srt_quot_2nd_i,
    input  logic [56 - 1:0]     srt_quot_m1_2nd_i,
    input  logic [REM_W - 1:0]  srt_f_r_s_1st_i,
    input  logic [REM_W - 1:0]  srt_f_r_c_1st_i,
    input  logic [REM_W - 1:0]  srt_f_r_s_2nd_i,
    input  logic [REM_W - 1:0]  srt_f_r_c_2nd_i,
    input  logic [ 4 - 1:0]     quot_discard_num_one_hot_i,

    input  logic                clk,
    input  logic                rst_n
);

// ================================================================================================================================================
// (local) parameters begin

// 61
localparam FDIV_F64_REM_W = 1 + 1 + 2 + 1 + 53 + 3;
// 32
localparam FDIV_F32_REM_W = 1 + 1 + 2 + 1 + 24 + 3;
// 19
localparam FDIV_F16_REM_W = 1 + 1 + 2 + 1 + 11 + 3;


// (local) parameters end
// ================================================================================================================================================

// ================================================================================================================================================
// signals begin

logic first_iter;

logic divisor_f64_en;
logic [57 - 1:0] divisor_f64_d;
logic [57 - 1:0] divisor_f64_q;
logic divisor_f32_en;
logic [28 - 1:0] divisor_f32_d;
logic [28 - 1:0] divisor_f32_q;

logic dividend_f64_en;
logic [58 - 1:0] dividend_f64_d;
logic [58 - 1:0] dividend_f64_q;
logic dividend_f32_en;
logic [29 - 1:0] dividend_f32_d;
logic [29 - 1:0] dividend_f32_q;

logic [REM_W - 1:0] srt_nr_f_r_1st;
logic [REM_W - 1:0] srt_nr_f_r_2nd;
logic select_srt_quot_m1_1st;
logic select_srt_quot_m1_2nd;
logic srt_quot_dig_1st;
logic srt_quot_dig_2nd;
logic srt_quot_dig_3rd;
logic srt_quot_dig_4th;
logic quot_en;
logic [56 - 1:0] quot_d;
logic [56 - 1:0] quot_q;
logic [56 - 1:0] quot_after_discard;

logic [FDIV_F64_REM_W - 1:0] divisor_ext_f64;
logic [FDIV_F64_REM_W - 1:0] rem_1st_f64;
logic [FDIV_F64_REM_W - 1:0] rem_2nd_f64;

logic rem_final_f64_en;
logic [58 - 1:0] rem_final_f64_d;
logic [58 - 1:0] rem_final_f64_q;
logic rem_final_f32_en;
logic [29 - 1:0] rem_final_f32_d;
logic [29 - 1:0] rem_final_f32_q;

logic quot_bits_calculated_final_en;
logic [6 - 1:0] quot_bits_calculated_final_d;
logic [6 - 1:0] quot_bits_calculated_final_q;
logic quot_discard_num_one_hot_en;
logic [4 - 1:0] quot_discard_num_one_hot_d;
logic [4 - 1:0] quot_discard_num_one_hot_q;

logic [(54 + 58) - 1:0] dividend_ext_f64;
logic [(26 + 29) - 1:0] dividend_ext_f32;
logic [(55 + 57) - 1:0] quot_mul_divisor_f64;
logic [(27 + 28) - 1:0] quot_mul_divisor_f32;
logic [(55 + 57) - 1:0] quot_mul_divisor_plus_rem_f64;
logic [(27 + 28) - 1:0] quot_mul_divisor_plus_rem_f32;

// signals end
// ================================================================================================================================================

assign first_iter = (iter_counter_i == '0);

assign divisor_f64_en = iter_start_i;
assign divisor_f64_d = scaled_divisor_i;
assign divisor_f32_en = divisor_f64_en;
assign divisor_f32_d = scaled_divisor_i[56 -: 28];

// F64: srt_nr_f_r_xxx[60] is sign (0, because in restoring algorithm, rem must be POSITIVE), srt_nr_f_r_xxx[1:0] = '0
// F32: srt_nr_f_r_xxx[60] is sign (0, because in restoring algorithm, rem must be POSITIVE), srt_nr_f_r_xxx[30:0] = '0
assign srt_nr_f_r_1st = srt_f_r_s_1st_i + srt_f_r_c_1st_i;
assign srt_nr_f_r_2nd = srt_f_r_s_2nd_i + srt_f_r_c_2nd_i;

assign select_srt_quot_m1_1st = srt_nr_f_r_1st[REM_W - 1];
assign select_srt_quot_m1_2nd = srt_nr_f_r_2nd[REM_W - 1];

assign {srt_quot_dig_1st, srt_quot_dig_2nd} = select_srt_quot_m1_1st ? srt_quot_m1_1st_i[1:0] : srt_quot_1st_i[1:0];
assign {srt_quot_dig_3rd, srt_quot_dig_4th} = select_srt_quot_m1_2nd ? srt_quot_m1_2nd_i[1:0] : srt_quot_2nd_i[1:0];


assign quot_en = iter_start_i | iter_vld_i;
assign quot_d = iter_start_i ? '0 : {quot_q[51:0], srt_quot_dig_1st, srt_quot_dig_2nd, srt_quot_dig_3rd, srt_quot_dig_4th};

assign dividend_f64_en = iter_start_i;
assign dividend_f64_d = dividend_lt_divisor_i ? {scaled_dividend_i, 1'b0} : {1'b0, scaled_dividend_i};
assign dividend_f32_en = iter_start_i;
assign dividend_f32_d = dividend_lt_divisor_i ? {scaled_dividend_i[56 -: 28], 1'b0} : {1'b0, scaled_dividend_i[56 -: 28]};

assign divisor_ext_f64 = {1'b0, 1'b0, divisor_f64_q, 2'b0};
assign rem_1st_f64 = select_srt_quot_m1_1st ? (srt_nr_f_r_1st + divisor_ext_f64) : srt_nr_f_r_1st;
assign rem_2nd_f64 = select_srt_quot_m1_2nd ? (srt_nr_f_r_2nd + divisor_ext_f64) : srt_nr_f_r_2nd;

assign rem_final_f64_en = iter_end_i;
assign rem_final_f64_d = rem_2nd_f64[59:2];
assign rem_final_f32_en = rem_final_f64_en;
assign rem_final_f32_d = rem_2nd_f64[59:31];

assign quot_bits_calculated_final_en = iter_end_i;
assign quot_bits_calculated_final_d = quot_bits_calculated_i;
assign quot_discard_num_one_hot_en = quot_bits_calculated_final_en;
assign quot_discard_num_one_hot_d = quot_discard_num_one_hot_i;

assign quot_after_discard = quot_q >> (quot_discard_num_one_hot_q[1] ? 1 : quot_discard_num_one_hot_q[2] ? 2 : quot_discard_num_one_hot_q[3] ? 3 : 0);

// We can't recover the right REM after discard...
// So we could only check the correctness of QUOT and REM before discard
// We would at most get "14 * 4 - 1 = 55 bits" quot for F64 -> 54 = 55 - 1
assign dividend_ext_f64 = {54'b0, dividend_f64_q} << ((quot_bits_calculated_final_q == '0) ? '0 : (quot_bits_calculated_final_q - 6'd1));
// We would at most get " 7 * 4 - 1 = 27 bits" quot for F64 -> 26 = 27 - 1
assign dividend_ext_f32 = {26'b0, dividend_f32_q} << ((quot_bits_calculated_final_q == '0) ? '0 : (quot_bits_calculated_final_q - 6'd1));

assign quot_mul_divisor_f64 = quot_q[54:0] * divisor_f64_q[56:0];
assign quot_mul_divisor_f32 = quot_q[26:0] * divisor_f32_q[27:0];

// If (quot_mul_divisor_plus_rem_f64 == dividend_ext_f64)/(quot_mul_divisor_plus_rem_f32 == dividend_ext_f32)
// The "srt to restoring helper code" is correct
assign quot_mul_divisor_plus_rem_f64 = quot_mul_divisor_f64 + {{(55 + 57 - 58){1'b0}}, rem_final_f64_q};
assign quot_mul_divisor_plus_rem_f32 = quot_mul_divisor_f32 + {{(27 + 28 - 29){1'b0}}, rem_final_f32_q};

always_ff @(posedge clk) begin
    if(divisor_f64_en)
        divisor_f64_q <= divisor_f64_d;
    if(divisor_f32_en)
        divisor_f32_q <= divisor_f32_d;
    if(dividend_f64_en)
        dividend_f64_q <= dividend_f64_d;
    if(dividend_f32_en)
        dividend_f32_q <= dividend_f32_d;
    
    if(quot_en)
        quot_q <= quot_d;
    if(rem_final_f64_en)
        rem_final_f64_q <= rem_final_f64_d;
    if(rem_final_f32_en)
        rem_final_f32_q <= rem_final_f32_d;
    
    if(quot_bits_calculated_final_en)
        quot_bits_calculated_final_q <= quot_bits_calculated_final_d;
    if(quot_discard_num_one_hot_en)
        quot_discard_num_one_hot_q <= quot_discard_num_one_hot_d;
    
    
end


endmodule
