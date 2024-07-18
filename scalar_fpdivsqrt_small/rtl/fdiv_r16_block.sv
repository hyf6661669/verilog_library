// ========================================================================================================
// File Name			: fdiv_r16_block.sv
// Author				: HYF
// How to Contact		: hyf_sysu@qq.com
// Created Time    		: July 5th 2024, 16:39:24
// Last Modified Time   : July 13th 2024, 18:17:57
// ========================================================================================================
// Description	:
// Please look at the reference paper for its original architecture.
// To improve timing and area, here we only use Radix-16 (Performance is reduced).
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

module fdiv_r16_block #(
	// Put some parameters here, which can be changed by other modules.

	// You should try which config could lead to best PPA.
	// 0: Native expression
	// 1: Comparator based
	// 2: Adder based
	parameter QDS_ARCH = 2,
	parameter SRT_2ND_SPEC = 1,
	parameter REM_W = 1 + 1 + 2 + 1 + 53 + 3
)(
	input  logic [REM_W - 1:0] f_r_s_i,
	input  logic [REM_W - 1:0] f_r_c_i,
	// 57 = 1 + 52 + 4
	input  logic [57 - 1:0] divisor_i,
	
	output logic quot_dig_p2_1st_o,
	output logic quot_dig_p1_1st_o,
	output logic quot_dig_z0_1st_o,
	output logic quot_dig_n1_1st_o,
	output logic quot_dig_n2_1st_o,

	output logic quot_dig_p2_2nd_o,
	output logic quot_dig_p1_2nd_o,
	output logic quot_dig_z0_2nd_o,
	output logic quot_dig_n1_2nd_o,
	output logic quot_dig_n2_2nd_o,

	output logic [REM_W - 1:0] f_r_s_1st_o,
	output logic [REM_W - 1:0] f_r_s_2nd_o,

	output logic [REM_W - 1:0] f_r_c_1st_o,
	output logic [REM_W - 1:0] f_r_c_2nd_o

);

// ================================================================================================================================================
// (local) parameters begin



// (local) parameters end
// ================================================================================================================================================

// ================================================================================================================================================
// signals begin

logic [REM_W-1:0] divisor_ext;
logic [REM_W-1:0] divisor_mul_neg_2;
logic [REM_W-1:0] divisor_mul_neg_1;
logic [REM_W-1:0] divisor_mul_pos_1;
logic [REM_W-1:0] divisor_mul_pos_2;

logic quot_dig_p2_1st;
logic quot_dig_p2_2nd;

logic quot_dig_p1_1st;
logic quot_dig_p1_2nd;

logic quot_dig_z0_1st;
logic quot_dig_z0_2nd;

logic quot_dig_n1_1st;
logic quot_dig_n1_2nd;

logic quot_dig_n2_1st;
logic quot_dig_n2_2nd;

// f_r = frac_rem
// f_r_s = frac_rem_sum
// f_r_c = frac_rem_carry
logic [REM_W-1:0] f_r_s_1st;
logic [REM_W-1:0] f_r_s_2nd;
logic [REM_W-1:0] f_r_c_1st;
logic [REM_W-1:0] f_r_c_2nd;


// Speculativly do csa for next srt operation
logic [REM_W-1:0] f_r_s_quot_dig_p2_1st;
logic [REM_W-1:0] f_r_s_quot_dig_p2_2nd;
logic [REM_W-1:0] f_r_c_quot_dig_p2_1st;
logic [REM_W-1:0] f_r_c_quot_dig_p2_2nd;

logic [REM_W-1:0] f_r_s_quot_dig_p1_1st;
logic [REM_W-1:0] f_r_s_quot_dig_p1_2nd;
logic [REM_W-1:0] f_r_c_quot_dig_p1_1st;
logic [REM_W-1:0] f_r_c_quot_dig_p1_2nd;

logic [REM_W-1:0] f_r_s_quot_dig_z0_1st;
logic [REM_W-1:0] f_r_s_quot_dig_z0_2nd;
logic [REM_W-1:0] f_r_c_quot_dig_z0_1st;
logic [REM_W-1:0] f_r_c_quot_dig_z0_2nd;

logic [REM_W-1:0] f_r_s_quot_dig_n1_1st;
logic [REM_W-1:0] f_r_s_quot_dig_n1_2nd;
logic [REM_W-1:0] f_r_c_quot_dig_n1_1st;
logic [REM_W-1:0] f_r_c_quot_dig_n1_2nd;

logic [REM_W-1:0] f_r_s_quot_dig_n2_1st;
logic [REM_W-1:0] f_r_s_quot_dig_n2_2nd;
logic [REM_W-1:0] f_r_c_quot_dig_n2_1st;
logic [REM_W-1:0] f_r_c_quot_dig_n2_2nd;

logic [5:0] rem_msb_1st;
logic [5:0] rem_msb_2nd;

logic [6:0] rem_msb_quot_dig_p2_2nd;
logic [6:0] rem_msb_quot_dig_p1_2nd;
logic [6:0] rem_msb_quot_dig_z0_2nd;
logic [6:0] rem_msb_quot_dig_n1_2nd;
logic [6:0] rem_msb_quot_dig_n2_2nd;

logic quot_dig_n2_quot_dig_p2_2nd;
logic quot_dig_n2_quot_dig_p1_2nd;
logic quot_dig_n2_quot_dig_z0_2nd;
logic quot_dig_n2_quot_dig_n1_2nd;
logic quot_dig_n2_quot_dig_n2_2nd;

logic quot_dig_n1_quot_dig_p2_2nd;
logic quot_dig_n1_quot_dig_p1_2nd;
logic quot_dig_n1_quot_dig_z0_2nd;
logic quot_dig_n1_quot_dig_n1_2nd;
logic quot_dig_n1_quot_dig_n2_2nd;

logic quot_dig_z0_quot_dig_p2_2nd;
logic quot_dig_z0_quot_dig_p1_2nd;
logic quot_dig_z0_quot_dig_z0_2nd;
logic quot_dig_z0_quot_dig_n1_2nd;
logic quot_dig_z0_quot_dig_n2_2nd;

logic quot_dig_p1_quot_dig_p2_2nd;
logic quot_dig_p1_quot_dig_p1_2nd;
logic quot_dig_p1_quot_dig_z0_2nd;
logic quot_dig_p1_quot_dig_n1_2nd;
logic quot_dig_p1_quot_dig_n2_2nd;

logic quot_dig_p2_quot_dig_p2_2nd;
logic quot_dig_p2_quot_dig_p1_2nd;
logic quot_dig_p2_quot_dig_z0_2nd;
logic quot_dig_p2_quot_dig_n1_2nd;
logic quot_dig_p2_quot_dig_n2_2nd;


// signals end
// ================================================================================================================================================

assign divisor_ext = {1'b0, 1'b0, divisor_i, 2'b0};
assign divisor_mul_neg_2 = ~{divisor_ext[(REM_W-1)-1:0], 1'b0};
assign divisor_mul_neg_1 = ~divisor_ext;
assign divisor_mul_pos_1 = divisor_ext;
assign divisor_mul_pos_2 = {divisor_ext[(REM_W-1)-1:0], 1'b0};

// ================================================================================================================================================
// 1st srt
// ================================================================================================================================================

assign f_r_s_quot_dig_n2_1st = 
  {f_r_s_i[(REM_W-1)-2:0], 2'b0}
^ {f_r_c_i[(REM_W-1)-2:0], 2'b0}
^ divisor_mul_pos_2;
assign f_r_c_quot_dig_n2_1st = {
	  ({f_r_s_i[(REM_W-1)-3:0], 2'b0} & {f_r_c_i[(REM_W-1)-3:0], 2'b0})
	| ({f_r_s_i[(REM_W-1)-3:0], 2'b0} & divisor_mul_pos_2[(REM_W-1)-1:0])
	| ({f_r_c_i[(REM_W-1)-3:0], 2'b0} & divisor_mul_pos_2[(REM_W-1)-1:0]),
	1'b0
};


assign f_r_s_quot_dig_n1_1st = 
  {f_r_s_i[(REM_W-1)-2:0], 2'b0}
^ {f_r_c_i[(REM_W-1)-2:0], 2'b0}
^ divisor_mul_pos_1;
assign f_r_c_quot_dig_n1_1st = {
	  ({f_r_s_i[(REM_W-1)-3:0], 2'b0} & {f_r_c_i[(REM_W-1)-3:0], 2'b0})
	| ({f_r_s_i[(REM_W-1)-3:0], 2'b0} & divisor_mul_pos_1[(REM_W-1)-1:0])
	| ({f_r_c_i[(REM_W-1)-3:0], 2'b0} & divisor_mul_pos_1[(REM_W-1)-1:0]),
	1'b0
};


assign f_r_s_quot_dig_z0_1st = {f_r_s_i[(REM_W-1)-2:0], 2'b0};
assign f_r_c_quot_dig_z0_1st = {f_r_c_i[(REM_W-1)-2:0], 2'b0};


assign f_r_s_quot_dig_p1_1st = 
  {f_r_s_i[(REM_W-1)-2:0], 2'b0}
^ {f_r_c_i[(REM_W-1)-2:0], 2'b0}
^ divisor_mul_neg_1;
assign f_r_c_quot_dig_p1_1st = {
	  ({f_r_s_i[(REM_W-1)-3:0], 2'b0} & {f_r_c_i[(REM_W-1)-3:0], 2'b0})
	| ({f_r_s_i[(REM_W-1)-3:0], 2'b0} & divisor_mul_neg_1[(REM_W-1)-1:0])
	| ({f_r_c_i[(REM_W-1)-3:0], 2'b0} & divisor_mul_neg_1[(REM_W-1)-1:0]),
	1'b1
};


assign f_r_s_quot_dig_p2_1st = 
  {f_r_s_i[(REM_W-1)-2:0], 2'b0}
^ {f_r_c_i[(REM_W-1)-2:0], 2'b0}
^ divisor_mul_neg_2;
assign f_r_c_quot_dig_p2_1st = {
	  ({f_r_s_i[(REM_W-1)-3:0], 2'b0} & {f_r_c_i[(REM_W-1)-3:0], 2'b0})
	| ({f_r_s_i[(REM_W-1)-3:0], 2'b0} & divisor_mul_neg_2[(REM_W-1)-1:0])
	| ({f_r_c_i[(REM_W-1)-3:0], 2'b0} & divisor_mul_neg_2[(REM_W-1)-1:0]),
	1'b1
};

assign rem_msb_quot_dig_n2_2nd[6:0] = f_r_s_i[(REM_W - 1) - 2 - 2 -: 7] + f_r_c_i[(REM_W - 1) - 2 - 2 -: 7] + divisor_mul_pos_2[(REM_W - 1) - 2 -: 7];
assign rem_msb_quot_dig_n1_2nd[6:0] = f_r_s_i[(REM_W - 1) - 2 - 2 -: 7] + f_r_c_i[(REM_W - 1) - 2 - 2 -: 7] + divisor_mul_pos_1[(REM_W - 1) - 2 -: 7];
assign rem_msb_quot_dig_z0_2nd[6:0] = f_r_s_i[(REM_W - 1) - 2 - 2 -: 7] + f_r_c_i[(REM_W - 1) - 2 - 2 -: 7];
assign rem_msb_quot_dig_p1_2nd[6:0] = f_r_s_i[(REM_W - 1) - 2 - 2 -: 7] + f_r_c_i[(REM_W - 1) - 2 - 2 -: 7] + divisor_mul_neg_1[(REM_W - 1) - 2 -: 7];
assign rem_msb_quot_dig_p2_2nd[6:0] = f_r_s_i[(REM_W - 1) - 2 - 2 -: 7] + f_r_c_i[(REM_W - 1) - 2 - 2 -: 7] + divisor_mul_neg_2[(REM_W - 1) - 2 -: 7];


assign rem_msb_1st[5:0] = f_r_s_i[(REM_W - 1) - 2 -: 6] + f_r_c_i[(REM_W - 1) - 2 -: 6];
fdiv_r4_qds #(
	.QDS_ARCH(QDS_ARCH)
) u_fdiv_r4_qds_1st (
	.rem_i		(rem_msb_1st),
	.quo_dig_o	(
		{
			quot_dig_n2_1st,
			quot_dig_n1_1st,
			quot_dig_z0_1st,
			quot_dig_p1_1st,
			quot_dig_p2_1st
		}
	)
);

assign f_r_s_1st = 
  ({(REM_W){quot_dig_p2_1st}} & f_r_s_quot_dig_p2_1st)
| ({(REM_W){quot_dig_p1_1st}} & f_r_s_quot_dig_p1_1st)
| ({(REM_W){quot_dig_z0_1st}} & f_r_s_quot_dig_z0_1st)
| ({(REM_W){quot_dig_n1_1st}} & f_r_s_quot_dig_n1_1st)
| ({(REM_W){quot_dig_n2_1st}} & f_r_s_quot_dig_n2_1st);
assign f_r_c_1st = 
  ({(REM_W){quot_dig_p2_1st}} & f_r_c_quot_dig_p2_1st)
| ({(REM_W){quot_dig_p1_1st}} & f_r_c_quot_dig_p1_1st)
| ({(REM_W){quot_dig_z0_1st}} & f_r_c_quot_dig_z0_1st)
| ({(REM_W){quot_dig_n1_1st}} & f_r_c_quot_dig_n1_1st)
| ({(REM_W){quot_dig_n2_1st}} & f_r_c_quot_dig_n2_1st);


// ================================================================================================================================================
// 2ND srt
// ================================================================================================================================================

assign f_r_s_quot_dig_n2_2nd = 
  {f_r_s_1st[(REM_W-1)-2:0], 2'b0}
^ {f_r_c_1st[(REM_W-1)-2:0], 2'b0}
^ divisor_mul_pos_2;
assign f_r_c_quot_dig_n2_2nd = {
	  ({f_r_s_1st[(REM_W-1)-3:0], 2'b0} & {f_r_c_1st[(REM_W-1)-3:0], 2'b0})
	| ({f_r_s_1st[(REM_W-1)-3:0], 2'b0} & divisor_mul_pos_2[(REM_W-1)-1:0])
	| ({f_r_c_1st[(REM_W-1)-3:0], 2'b0} & divisor_mul_pos_2[(REM_W-1)-1:0]),
	1'b0
};


assign f_r_s_quot_dig_n1_2nd = 
  {f_r_s_1st[(REM_W-1)-2:0], 2'b0}
^ {f_r_c_1st[(REM_W-1)-2:0], 2'b0}
^ divisor_mul_pos_1;
assign f_r_c_quot_dig_n1_2nd = {
	  ({f_r_s_1st[(REM_W-1)-3:0], 2'b0} & {f_r_c_1st[(REM_W-1)-3:0], 2'b0})
	| ({f_r_s_1st[(REM_W-1)-3:0], 2'b0} & divisor_mul_pos_1[(REM_W-1)-1:0])
	| ({f_r_c_1st[(REM_W-1)-3:0], 2'b0} & divisor_mul_pos_1[(REM_W-1)-1:0]),
	1'b0
};


assign f_r_s_quot_dig_z0_2nd = {f_r_s_1st[(REM_W-1)-2:0], 2'b0};
assign f_r_c_quot_dig_z0_2nd = {f_r_c_1st[(REM_W-1)-2:0], 2'b0};


assign f_r_s_quot_dig_p1_2nd = 
  {f_r_s_1st[(REM_W-1)-2:0], 2'b0}
^ {f_r_c_1st[(REM_W-1)-2:0], 2'b0}
^ divisor_mul_neg_1;
assign f_r_c_quot_dig_p1_2nd = {
	  ({f_r_s_1st[(REM_W-1)-3:0], 2'b0} & {f_r_c_1st[(REM_W-1)-3:0], 2'b0})
	| ({f_r_s_1st[(REM_W-1)-3:0], 2'b0} & divisor_mul_neg_1[(REM_W-1)-1:0])
	| ({f_r_c_1st[(REM_W-1)-3:0], 2'b0} & divisor_mul_neg_1[(REM_W-1)-1:0]),
	1'b1
};


assign f_r_s_quot_dig_p2_2nd = 
  {f_r_s_1st[(REM_W-1)-2:0], 2'b0}
^ {f_r_c_1st[(REM_W-1)-2:0], 2'b0}
^ divisor_mul_neg_2;
assign f_r_c_quot_dig_p2_2nd = {
	  ({f_r_s_1st[(REM_W-1)-3:0], 2'b0} & {f_r_c_1st[(REM_W-1)-3:0], 2'b0})
	| ({f_r_s_1st[(REM_W-1)-3:0], 2'b0} & divisor_mul_neg_2[(REM_W-1)-1:0])
	| ({f_r_c_1st[(REM_W-1)-3:0], 2'b0} & divisor_mul_neg_2[(REM_W-1)-1:0]),
	1'b1
};

generate
if(SRT_2ND_SPEC == 1) begin
// Speculative do 5 QDS for 2nd SRD to improve timing

fdiv_r4_qds #(
	.QDS_ARCH(QDS_ARCH)
) u_fdiv_r4_qds_quot_dig_p2_2nd (
	.rem_i		(rem_msb_quot_dig_p2_2nd[6:1]),
	.quo_dig_o	(
		{
			quot_dig_n2_quot_dig_p2_2nd,
			quot_dig_n1_quot_dig_p2_2nd,
			quot_dig_z0_quot_dig_p2_2nd,
			quot_dig_p1_quot_dig_p2_2nd,
			quot_dig_p2_quot_dig_p2_2nd
		}
	)
);

fdiv_r4_qds #(
	.QDS_ARCH(QDS_ARCH)
) u_fdiv_r4_qds_quot_dig_p1_2nd (
	.rem_i		(rem_msb_quot_dig_p1_2nd[6:1]),
	.quo_dig_o	(
		{
			quot_dig_n2_quot_dig_p1_2nd,
			quot_dig_n1_quot_dig_p1_2nd,
			quot_dig_z0_quot_dig_p1_2nd,
			quot_dig_p1_quot_dig_p1_2nd,
			quot_dig_p2_quot_dig_p1_2nd
		}
	)
);

fdiv_r4_qds #(
	.QDS_ARCH(QDS_ARCH)
) u_fdiv_r4_qds_quot_dig_z0_2nd (
	.rem_i		(rem_msb_quot_dig_z0_2nd[6:1]),
	.quo_dig_o	(
		{
			quot_dig_n2_quot_dig_z0_2nd,
			quot_dig_n1_quot_dig_z0_2nd,
			quot_dig_z0_quot_dig_z0_2nd,
			quot_dig_p1_quot_dig_z0_2nd,
			quot_dig_p2_quot_dig_z0_2nd
		}
	)
);

fdiv_r4_qds #(
	.QDS_ARCH(QDS_ARCH)
) u_fdiv_r4_qds_quot_dig_n1_2nd (
	.rem_i		(rem_msb_quot_dig_n1_2nd[6:1]),
	.quo_dig_o	(
		{
			quot_dig_n2_quot_dig_n1_2nd,
			quot_dig_n1_quot_dig_n1_2nd,
			quot_dig_z0_quot_dig_n1_2nd,
			quot_dig_p1_quot_dig_n1_2nd,
			quot_dig_p2_quot_dig_n1_2nd
		}
	)
);

fdiv_r4_qds #(
	.QDS_ARCH(QDS_ARCH)
) u_fdiv_r4_qds_quot_dig_n2_2nd (
	.rem_i		(rem_msb_quot_dig_n2_2nd[6:1]),
	.quo_dig_o	(
		{
			quot_dig_n2_quot_dig_n2_2nd,
			quot_dig_n1_quot_dig_n2_2nd,
			quot_dig_z0_quot_dig_n2_2nd,
			quot_dig_p1_quot_dig_n2_2nd,
			quot_dig_p2_quot_dig_n2_2nd
		}
	)
);

assign quot_dig_n2_2nd = 
  (quot_dig_n2_quot_dig_p2_2nd & quot_dig_p2_1st)
| (quot_dig_n2_quot_dig_p1_2nd & quot_dig_p1_1st)
| (quot_dig_n2_quot_dig_z0_2nd & quot_dig_z0_1st)
| (quot_dig_n2_quot_dig_n1_2nd & quot_dig_n1_1st)
| (quot_dig_n2_quot_dig_n2_2nd & quot_dig_n2_1st);

assign quot_dig_n1_2nd = 
  (quot_dig_n1_quot_dig_p2_2nd & quot_dig_p2_1st)
| (quot_dig_n1_quot_dig_p1_2nd & quot_dig_p1_1st)
| (quot_dig_n1_quot_dig_z0_2nd & quot_dig_z0_1st)
| (quot_dig_n1_quot_dig_n1_2nd & quot_dig_n1_1st)
| (quot_dig_n1_quot_dig_n2_2nd & quot_dig_n2_1st);

assign quot_dig_z0_2nd = 
  (quot_dig_z0_quot_dig_p2_2nd & quot_dig_p2_1st)
| (quot_dig_z0_quot_dig_p1_2nd & quot_dig_p1_1st)
| (quot_dig_z0_quot_dig_z0_2nd & quot_dig_z0_1st)
| (quot_dig_z0_quot_dig_n1_2nd & quot_dig_n1_1st)
| (quot_dig_z0_quot_dig_n2_2nd & quot_dig_n2_1st);

assign quot_dig_p1_2nd = 
  (quot_dig_p1_quot_dig_p2_2nd & quot_dig_p2_1st)
| (quot_dig_p1_quot_dig_p1_2nd & quot_dig_p1_1st)
| (quot_dig_p1_quot_dig_z0_2nd & quot_dig_z0_1st)
| (quot_dig_p1_quot_dig_n1_2nd & quot_dig_n1_1st)
| (quot_dig_p1_quot_dig_n2_2nd & quot_dig_n2_1st);

assign quot_dig_p2_2nd = 
  (quot_dig_p2_quot_dig_p2_2nd & quot_dig_p2_1st)
| (quot_dig_p2_quot_dig_p1_2nd & quot_dig_p1_1st)
| (quot_dig_p2_quot_dig_z0_2nd & quot_dig_z0_1st)
| (quot_dig_p2_quot_dig_n1_2nd & quot_dig_n1_1st)
| (quot_dig_p2_quot_dig_n2_2nd & quot_dig_n2_1st);

end else begin

// No speculation in 2nd SRT if timing is good enough
assign rem_msb_2nd[5:0] = 
  ({(6){quot_dig_p2_1st}} & rem_msb_quot_dig_p2_2nd[6:1])
| ({(6){quot_dig_p1_1st}} & rem_msb_quot_dig_p1_2nd[6:1])
| ({(6){quot_dig_z0_1st}} & rem_msb_quot_dig_z0_2nd[6:1])
| ({(6){quot_dig_n1_1st}} & rem_msb_quot_dig_n1_2nd[6:1])
| ({(6){quot_dig_n2_1st}} & rem_msb_quot_dig_n2_2nd[6:1]);
fdiv_r4_qds #(
	.QDS_ARCH(QDS_ARCH)
) u_fdiv_r4_qds_2nd (
	.rem_i		(rem_msb_2nd),
	.quo_dig_o	(
		{
			quot_dig_n2_2nd,
			quot_dig_n1_2nd,
			quot_dig_z0_2nd,
			quot_dig_p1_2nd,
			quot_dig_p2_2nd
		}
	)
);

end

endgenerate


assign f_r_s_2nd = 
  ({(REM_W){quot_dig_n2_2nd}} & f_r_s_quot_dig_n2_2nd)
| ({(REM_W){quot_dig_n1_2nd}} & f_r_s_quot_dig_n1_2nd)
| ({(REM_W){quot_dig_z0_2nd}} & f_r_s_quot_dig_z0_2nd)
| ({(REM_W){quot_dig_p1_2nd}} & f_r_s_quot_dig_p1_2nd)
| ({(REM_W){quot_dig_p2_2nd}} & f_r_s_quot_dig_p2_2nd);
assign f_r_c_2nd = 
  ({(REM_W){quot_dig_n2_2nd}} & f_r_c_quot_dig_n2_2nd)
| ({(REM_W){quot_dig_n1_2nd}} & f_r_c_quot_dig_n1_2nd)
| ({(REM_W){quot_dig_z0_2nd}} & f_r_c_quot_dig_z0_2nd)
| ({(REM_W){quot_dig_p1_2nd}} & f_r_c_quot_dig_p1_2nd)
| ({(REM_W){quot_dig_p2_2nd}} & f_r_c_quot_dig_p2_2nd);



assign f_r_s_1st_o = f_r_s_1st;
assign f_r_s_2nd_o = f_r_s_2nd;
assign f_r_c_1st_o = f_r_c_1st;
assign f_r_c_2nd_o = f_r_c_2nd;

assign quot_dig_p2_1st_o = quot_dig_p2_1st;
assign quot_dig_p1_1st_o = quot_dig_p1_1st;
assign quot_dig_z0_1st_o = quot_dig_z0_1st;
assign quot_dig_n1_1st_o = quot_dig_n1_1st;
assign quot_dig_n2_1st_o = quot_dig_n2_1st;

assign quot_dig_p2_2nd_o = quot_dig_p2_2nd;
assign quot_dig_p1_2nd_o = quot_dig_p1_2nd;
assign quot_dig_z0_2nd_o = quot_dig_z0_2nd;
assign quot_dig_n1_2nd_o = quot_dig_n1_2nd;
assign quot_dig_n2_2nd_o = quot_dig_n2_2nd;



endmodule
