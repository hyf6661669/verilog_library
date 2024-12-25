// ========================================================================================================
// File Name			: fsqrt_srt_to_restoring.sv
// Author				: HYF
// How to Contact		: hyf_sysu@qq.com
// Created Time    		: July 24th 2024, 09:34:43
// Last Modified Time   : 
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

module fsqrt_srt_to_restoring #(
	// Put some parameters here, which can be changed by other modules.
    parameter REM_W = 2 + 54
)(
	input  logic [52 - 1:0]     frac_fsqrt_i,
    input  logic                exp_odd_i,
    input  logic                root_dig_n2_1st_i,
    input  logic                root_dig_n1_1st_i,
    input  logic                root_dig_z0_1st_i,
    input  logic [REM_W - 1:0]  f_r_s_before_iter_i,
    input  logic [REM_W - 1:0]  f_r_c_before_iter_i,
    input  logic                iter_start_i,
    input  logic                iter_vld_i,
    input  logic [ 6 - 1:0]     iter_counter_i,
    input  logic [54 - 1:0]     srt_root_2nd_i,
    input  logic [53 - 1:0]     srt_root_m1_2nd_i,
    input  logic [REM_W - 1:0]  srt_f_r_s_2nd_i,
    input  logic [REM_W - 1:0]  srt_f_r_c_2nd_i,

    input  logic                clk,
	input  logic                rst_n
);

// ================================================================================================================================================
// (local) parameters begin

localparam FSQRT_F64_REM_W = 2 + 54;
localparam F64_FULL_ROOT_W = 55;


// (local) parameters end
// ================================================================================================================================================

// ================================================================================================================================================
// signals begin


logic final_iter;
logic [F64_FULL_ROOT_W - 1:0] srt_root_ext;
logic [F64_FULL_ROOT_W - 1:0] srt_root_m1_ext;
logic [FSQRT_F64_REM_W - 1:0] srt_nr_f_r;

logic select_srt_root_m1;
logic [F64_FULL_ROOT_W - 1:0] srt_root_2nd_rsh;
logic [F64_FULL_ROOT_W - 1:0] srt_root_m1_2nd_rsh;

logic srt_root_dig_1st;
logic srt_root_dig_2nd;
logic srt_root_dig_3rd;
logic srt_root_dig_4th;

// In the final step, we need 54 * 2 + 2 = 110-bit rem
logic [110 - 1:0] rem_1st;
logic [110 - 1:0] rem_2nd;
logic [110 - 1:0] rem_3rd;
logic [110 - 1:0] rem_4th;
logic [ 54 - 1:0] root_1st;
logic [ 54 - 1:0] root_2nd;
logic [ 54 - 1:0] root_3rd;
logic [ 54 - 1:0] root_4th;

logic [110 - 1:0] rem_init;
logic [110 - 1:0] rem_before_iter_0;
logic [110 - 1:0] rem_before_iter;
logic [ 54 - 1:0] root_before_iter_0;
logic [ 54 - 1:0] root_before_iter;
logic [FSQRT_F64_REM_W - 1:0] nr_f_r_before_iter;
logic select_root_m1_before_iter;
logic [2 - 1:0] root_dig_before_iter;

logic root_en;
logic [54 - 1:0] root_d;
logic [54 - 1:0] root_q;

logic rem_en;
logic [110 - 1:0] rem_d;
logic [110 - 1:0] rem_q;

logic rem_final_check_en;
logic [108 - 1:0] rem_final_check_d;
logic [108 - 1:0] rem_final_check_q;

logic [55 - 1:0] rem_final;
logic [54 - 1:0] root_final;
logic [108 - 1:0] root_final_square;
logic restoring_correct;


// signals end
// ================================================================================================================================================

assign final_iter = (iter_counter_i == '0);

assign srt_root_ext = {~srt_root_2nd_i[F64_FULL_ROOT_W - 2], srt_root_2nd_i[F64_FULL_ROOT_W - 2:0]};
assign srt_root_m1_ext = {1'b0, 1'b1, srt_root_m1_2nd_i[F64_FULL_ROOT_W - 3:0]};
assign srt_nr_f_r = srt_f_r_s_2nd_i + srt_f_r_c_2nd_i;
assign select_srt_root_m1 = srt_nr_f_r[FSQRT_F64_REM_W - 1];

assign srt_root_2nd_rsh = srt_root_ext >> (iter_counter_i * 4);
assign srt_root_m1_2nd_rsh = srt_root_m1_ext >> (iter_counter_i * 4);

assign {
    srt_root_dig_1st,
    srt_root_dig_2nd,
    srt_root_dig_3rd,
    srt_root_dig_4th
} = select_srt_root_m1 ? srt_root_m1_2nd_rsh[3:0] : srt_root_2nd_rsh[3:0];

assign rem_1st = {rem_q[107:52] - {1'b0, srt_root_dig_1st ? root_q[52:0] : 53'b0, 1'b0, srt_root_dig_1st}, rem_q[51:0], 2'b0};
assign root_1st = {root_q[52:0], srt_root_dig_1st};

assign rem_2nd = {rem_1st[107:52] - {1'b0, srt_root_dig_2nd ? root_1st[52:0] : 53'b0, 1'b0, srt_root_dig_2nd}, rem_1st[51:0], 2'b0};
assign root_2nd = {root_1st[52:0], srt_root_dig_2nd};

assign rem_3rd = {rem_2nd[107:52] - {1'b0, srt_root_dig_3rd ? root_2nd[52:0] : 53'b0, 1'b0, srt_root_dig_3rd}, rem_2nd[51:0], 2'b0};
assign root_3rd = {root_2nd[52:0], srt_root_dig_3rd};

assign rem_4th = {rem_3rd[107:52] - {1'b0, srt_root_dig_4th ? root_3rd[52:0] : 53'b0, 1'b0, srt_root_dig_4th}, rem_3rd[51:0], 2'b0};
assign root_4th = {root_3rd[52:0], srt_root_dig_4th};


assign rem_init = {56'b0, exp_odd_i ? {1'b1, frac_fsqrt_i[51:0], 1'b0} : {1'b0, 1'b1, frac_fsqrt_i[51:0]}};

assign nr_f_r_before_iter = f_r_s_before_iter_i + f_r_c_before_iter_i;
assign select_root_m1_before_iter = nr_f_r_before_iter[FSQRT_F64_REM_W - 1];
// We could get 2-bit root_dig before iter
// If(root_dig_z0_1st_i), root_dig_before_iter must be 2'b11, and final root is {1.1, 52'bx}
// If(root_dig_n2_1st_i), root_dig_before_iter must be 2'b10, and final root is {1.0, 52'bx}
assign root_dig_before_iter = 
  ({(2){root_dig_z0_1st_i}} & 2'b11)
| ({(2){root_dig_n2_1st_i}} & 2'b10)
| ({(2){root_dig_n1_1st_i}} & (select_root_m1_before_iter ? 2'b10 : 2'b11));

// root_dig_before_iter[1] must be 1
assign rem_before_iter_0 = {rem_init[107:52] - {1'b0, 53'b0, 1'b0, 1'b1}, rem_init[51:0], 2'b0};
assign root_before_iter_0 = {53'b0, 1'b1};
assign rem_before_iter = {rem_before_iter_0[107:52] - {1'b0, root_dig_before_iter[0] ? root_before_iter_0[52:0] : 53'b0, 1'b0, root_dig_before_iter[0]}, rem_before_iter_0[51:0], 2'b0};
assign root_before_iter = {root_before_iter_0[52:0], root_dig_before_iter[0]};

assign root_en = iter_start_i | iter_vld_i;
assign root_d = iter_start_i ? root_before_iter : root_4th;

assign rem_en = iter_start_i | iter_vld_i;
assign rem_d = iter_start_i ? rem_before_iter : rem_4th;

assign rem_final_check_en = iter_start_i;
assign rem_final_check_d = {rem_init[53:0], 54'b0};

always_ff @(posedge clk) begin
	if(root_en)
        root_q <= root_d;
	if(rem_en)
        rem_q <= rem_d;
	if(rem_final_check_en)
        rem_final_check_q <= rem_final_check_d;
		
end

assign rem_final[54:0] = rem_4th[108:54];
assign root_final[53:0] = root_4th;
assign root_final_square[107:0] = root_final[53:0] * root_final[53:0];
// When (final_iter), restoring_correct should be 1
assign restoring_correct = ((root_final_square + {53'b0, rem_final}) == rem_final_check_q);



endmodule
