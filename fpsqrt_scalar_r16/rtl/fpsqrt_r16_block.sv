// ========================================================================================================
// File Name			: fpsqrt_r16_block.sv
// Author				: HYF
// How to Contact		: hyf_sysu@qq.com
// Created Time    		: 2022-02-01 18:39:18
// Last Modified Time   : 2022-02-08 15:05:37
// ========================================================================================================
// Description	:
// Radix-16 SRT algorithm for the frac part of fpsqrt.
// Here I add more speculation to reduce the delay.
// ========================================================================================================
// ========================================================================================================
// Copyright (C) 2022, HYF. All Rights Reserved.
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

module fpsqrt_r16_block #(
	// Put some parameters here, which can be changed by other modules
	parameter S0_CSA_SPECULATIVE = 0,
	parameter S1_QDS_SPECULATIVE = 0,
	parameter S1_CSA_SPECULATIVE = 1,
	// Don't change the following value
	parameter REM_W = 2 + 54,
	parameter RT_DIG_W = 5
)(
	input  logic [REM_W-1:0] f_r_s_i,
	input  logic [REM_W-1:0] f_r_c_i,
	input  logic [54-1:0] rt_i,
	input  logic [53-1:0] rt_m1_i,
	input  logic [7-1:0] nr_f_r_7b_for_nxt_cycle_s0_qds_i,
	input  logic [9-1:0] nr_f_r_9b_for_nxt_cycle_s1_qds_i,
	input  logic [5-1:0] m_neg_1_for_nxt_cycle_s0_qds_i,
	input  logic [4-1:0] m_neg_0_for_nxt_cycle_s0_qds_i,
	input  logic [3-1:0] m_pos_1_for_nxt_cycle_s0_qds_i,
	input  logic [4-1:0] m_pos_2_for_nxt_cycle_s0_qds_i,
	input  logic [13-1:0] mask_i,
	
	output logic [54-1:0] nxt_rt_o,
	output logic [53-1:0] nxt_rt_m1_o,
	output logic [REM_W-1:0] nxt_f_r_s_o [2-1:0],
	output logic [REM_W-1:0] nxt_f_r_c_o [2-1:0],
	output logic [7-1:0] adder_7b_res_for_nxt_cycle_s0_qds_o,
	output logic [9-1:0] adder_9b_res_for_nxt_cycle_s1_qds_o,
	output logic [7-1:0] m_neg_1_to_nxt_cycle_o,
	output logic [7-1:0] m_neg_0_to_nxt_cycle_o,
	output logic [7-1:0] m_pos_1_to_nxt_cycle_o,
	output logic [7-1:0] m_pos_2_to_nxt_cycle_o
);

// ================================================================================================================================================
// (local) parameters begin

// F64: We would get 54-bit root -> We need 54 + 2 = 56-bit REM.
localparam F64_REM_W = 2 + 54;
// F32: We would get 26-bit root -> We need 26 + 2 = 28-bit REM.
localparam F32_REM_W = 2 + 26;
// F16: We would get 14-bit root -> We need 14 + 2 = 16-bit REM.
localparam F16_REM_W = 2 + 14;

// F64: The root could be 55-bit in the early stage, but finally the significant digits must be 54.
localparam F64_FULL_RT_W = F64_REM_W - 1;
// F32: The root could be 27-bit in the early stage, but finally the significant digits must be 26.
localparam F32_FULL_RT_W = F32_REM_W - 1;
// F16: The root could be 15-bit in the early stage, but finally the significant digits must be 14.
localparam F16_FULL_RT_W = F16_REM_W - 1;

// (local) parameters end
// ================================================================================================================================================

// ================================================================================================================================================
// signals begin

logic [F64_FULL_RT_W-1:0] rt;
logic [F64_FULL_RT_W-1:0] rt_m1;
logic [F64_FULL_RT_W-1:0] nxt_rt_spec_s0 [5-1:0];
logic [F64_FULL_RT_W-1:0] nxt_rt_spec_s1 [5-1:0];
logic [F64_FULL_RT_W-1:0] nxt_rt [2-1:0];
logic [F64_FULL_RT_W-1:0] nxt_rt_m1 [2-1:0];
logic [RT_DIG_W-1:0] nxt_rt_dig [2-1:0];

logic [REM_W-1:0] mask_csa_ext [2-1:0];
logic [REM_W-1:0] mask_csa_neg_2 [2-1:0];
logic [REM_W-1:0] mask_csa_neg_1 [2-1:0];
logic [REM_W-1:0] mask_csa_pos_1 [2-1:0];
logic [REM_W-1:0] mask_csa_pos_2 [2-1:0];

logic [F64_FULL_RT_W-1:0] mask_rt_ext [2-1:0];
logic [F64_FULL_RT_W-1:0] mask_rt_neg_2 [2-1:0];
logic [F64_FULL_RT_W-1:0] mask_rt_neg_1 [2-1:0];
logic [F64_FULL_RT_W-1:0] mask_rt_neg_0 [2-1:0];
logic [F64_FULL_RT_W-1:0] mask_rt_pos_1 [2-1:0];
logic [F64_FULL_RT_W-1:0] mask_rt_pos_2 [2-1:0];
logic [F64_FULL_RT_W-1:0] mask_rt_m1_neg_2 [2-1:0];
logic [F64_FULL_RT_W-1:0] mask_rt_m1_neg_1 [2-1:0];
logic [F64_FULL_RT_W-1:0] mask_rt_m1_neg_0 [2-1:0];
logic [F64_FULL_RT_W-1:0] mask_rt_m1_pos_1 [2-1:0];
logic [F64_FULL_RT_W-1:0] mask_rt_m1_pos_2 [2-1:0];

logic [REM_W-1:0] nxt_f_r_s [2-1:0];
logic [REM_W-1:0] nxt_f_r_c [2-1:0];
logic [REM_W-1:0] nxt_f_r_s_spec_s0 [5-1:0];
logic [REM_W-1:0] nxt_f_r_c_spec_s0 [5-1:0];
logic [REM_W-1:0] nxt_f_r_s_spec_s1 [5-1:0];
logic [REM_W-1:0] nxt_f_r_c_spec_s1 [5-1:0];

logic [REM_W-1:0] sqrt_csa_val_neg_2 [2-1:0];
logic [REM_W-1:0] sqrt_csa_val_neg_1 [2-1:0];
logic [REM_W-1:0] sqrt_csa_val_pos_1 [2-1:0];
logic [REM_W-1:0] sqrt_csa_val_pos_2 [2-1:0];

logic [REM_W-1:0] sqrt_csa_val [2-1:0];

logic a0_spec_s0 [5-1:0];
logic a2_spec_s0 [5-1:0];
logic a3_spec_s0 [5-1:0];
logic a4_spec_s0 [5-1:0];

logic a0_spec_s1 [5-1:0];
logic a2_spec_s1 [5-1:0];
logic a3_spec_s1 [5-1:0];
logic a4_spec_s1 [5-1:0];

logic [7-1:0] m_neg_1 [2-1:0];
logic [7-1:0] m_neg_0 [2-1:0];
logic [7-1:0] m_pos_1 [2-1:0];
logic [7-1:0] m_pos_2 [2-1:0];

logic [7-1:0] m_neg_1_spec_s0 [5-1:0];
logic [7-1:0] m_neg_0_spec_s0 [5-1:0];
logic [7-1:0] m_pos_1_spec_s0 [5-1:0];
logic [7-1:0] m_pos_2_spec_s0 [5-1:0];

logic [7-1:0] m_neg_1_spec_s1 [5-1:0];
logic [7-1:0] m_neg_0_spec_s1 [5-1:0];
logic [7-1:0] m_pos_1_spec_s1 [5-1:0];
logic [7-1:0] m_pos_2_spec_s1 [5-1:0];

logic [7-1:0] m_neg_1_to_nxt_cycle;
logic [7-1:0] m_neg_0_to_nxt_cycle;
logic [7-1:0] m_pos_1_to_nxt_cycle;
logic [7-1:0] m_pos_2_to_nxt_cycle;

logic [9-1:0] adder_9b_for_nxt_cycle_s0_qds_spec [5-1:0];
logic [10-1:0] adder_10b_for_nxt_cycle_s1_qds_spec [5-1:0];

logic [9-1:0] adder_9b_for_s1_qds_spec [5-1:0];
logic [7-1:0] adder_7b_res_for_s1_qds;


// signals end
// ================================================================================================================================================

// Put the mask into the right position. CSA/OTFC operation is based on this "mask"
assign mask_csa_ext[0] = {
	2'b0,
	3'b0, mask_i[12],
	3'b0, mask_i[11],
	3'b0, mask_i[10],
	3'b0, mask_i[ 9],
	3'b0, mask_i[ 8],
	3'b0, mask_i[ 7],
	3'b0, mask_i[ 6],
	3'b0, mask_i[ 5],
	3'b0, mask_i[ 4],
	3'b0, mask_i[ 3],
	3'b0, mask_i[ 2],
	3'b0, mask_i[ 1],
	3'b0, mask_i[ 0],
	2'b0
};
// Gemerate csa_mask for different rt_dig
assign mask_csa_neg_2[0] = (mask_csa_ext[0] << 2) | (mask_csa_ext[0] << 3);
assign mask_csa_neg_1[0] = mask_csa_ext[0] | (mask_csa_ext[0] << 1) | (mask_csa_ext[0] << 2);
assign mask_csa_pos_1[0] = mask_csa_ext[0];
assign mask_csa_pos_2[0] = mask_csa_ext[0] << 2;
// Gemerate ofc_mask for different rt_dig
assign mask_rt_ext[0] = mask_csa_ext[0][F64_FULL_RT_W-1:0];

assign mask_rt_neg_2[0] = mask_rt_ext[0] << 1;
assign mask_rt_neg_1[0] = mask_rt_ext[0] | (mask_rt_ext[0] << 1);
assign mask_rt_neg_0[0] = '0;
assign mask_rt_pos_1[0] = mask_rt_ext[0];
assign mask_rt_pos_2[0] = mask_rt_ext[0] << 1;

assign mask_rt_m1_neg_2[0] = mask_rt_ext[0];
assign mask_rt_m1_neg_1[0] = mask_rt_ext[0] << 1;
assign mask_rt_m1_neg_0[0] = mask_rt_ext[0] | (mask_rt_ext[0] << 1);
assign mask_rt_m1_pos_1[0] = '0;
assign mask_rt_m1_pos_2[0] = mask_rt_ext[0];

assign mask_csa_ext[1] = mask_csa_ext[0] >> 2;
assign mask_csa_neg_2[1] = (mask_csa_ext[1] << 2) | (mask_csa_ext[1] << 3);
assign mask_csa_neg_1[1] = mask_csa_ext[1] | (mask_csa_ext[1] << 1) | (mask_csa_ext[1] << 2);
assign mask_csa_pos_1[1] = mask_csa_ext[1];
assign mask_csa_pos_2[1] = mask_csa_ext[1] << 2;

assign mask_rt_ext[1] = mask_rt_ext[0] >> 2;

assign mask_rt_neg_2[1] = mask_rt_ext[1] << 1;
assign mask_rt_neg_1[1] = mask_rt_ext[1] | (mask_rt_ext[1] << 1);
assign mask_rt_neg_0[1] = '0;
assign mask_rt_pos_1[1] = mask_rt_ext[1];
assign mask_rt_pos_2[1] = mask_rt_ext[1] << 1;

assign mask_rt_m1_neg_2[1] = mask_rt_ext[1];
assign mask_rt_m1_neg_1[1] = mask_rt_ext[1] << 1;
assign mask_rt_m1_neg_0[1] = mask_rt_ext[1] | (mask_rt_ext[1] << 1);
assign mask_rt_m1_pos_1[1] = '0;
assign mask_rt_m1_pos_2[1] = mask_rt_ext[1];

// ================================================================================================================================================
// stage[0].qds
// ================================================================================================================================================
assign m_neg_1[0] = {2'b0, m_neg_1_for_nxt_cycle_s0_qds_i};
assign m_neg_0[0] = {3'b0, m_neg_0_for_nxt_cycle_s0_qds_i};
assign m_pos_1[0] = {4'b1111, m_pos_1_for_nxt_cycle_s0_qds_i};
assign m_pos_2[0] = {2'b11, m_pos_2_for_nxt_cycle_s0_qds_i, 1'b0};
r4_qds
u_r4_qds_s0 (
	.rem_i(nr_f_r_7b_for_nxt_cycle_s0_qds_i),
	.m_neg_1_i(m_neg_1[0]),
	.m_neg_0_i(m_neg_0[0]),
	.m_pos_1_i(m_pos_1[0]),
	.m_pos_2_i(m_pos_2[0]),
	.rt_dig_o(nxt_rt_dig[0])
);

// ================================================================================================================================================
// stage[0].csa + full-adder
// This is done in parallel with qds
// ================================================================================================================================================
assign rt = {~rt_i[F64_FULL_RT_W-2], rt_i[F64_FULL_RT_W-2:0]};
assign rt_m1 = {1'b0, 1'b1, rt_m1_i[F64_FULL_RT_W-3:0]};

assign sqrt_csa_val_neg_2[0] = ({1'b0, rt_m1} << 2) | mask_csa_neg_2[0];
assign sqrt_csa_val_neg_1[0] = ({1'b0, rt_m1} << 1) | mask_csa_neg_1[0];
assign sqrt_csa_val_pos_1[0] = ~(({1'b0, rt} << 1) | mask_csa_pos_1[0]);
assign sqrt_csa_val_pos_2[0] = ~(({1'b0, rt} << 2) | mask_csa_pos_2[0]); 

generate
if(S0_CSA_SPECULATIVE == 1) begin: g_s0_csa_spec

	// Here we assume nxt_rt_dig[0] = -2
	assign nxt_f_r_s_spec_s0[4] = 
	  {f_r_s_i[(REM_W-1)-2:0], 2'b0}
	^ {f_r_c_i[(REM_W-1)-2:0], 2'b0}
	^ sqrt_csa_val_neg_2[0];
	assign nxt_f_r_c_spec_s0[4] = {
		  ({f_r_s_i[(REM_W-1)-3:0], 2'b0} & {f_r_c_i[(REM_W-1)-3:0], 2'b0})
		| ({f_r_s_i[(REM_W-1)-3:0], 2'b0} & sqrt_csa_val_neg_2[0][(REM_W-1)-1:0])
		| ({f_r_c_i[(REM_W-1)-3:0], 2'b0} & sqrt_csa_val_neg_2[0][(REM_W-1)-1:0]),
		1'b0
	};

	// Here we assume nxt_rt_dig[0] = -1
	assign nxt_f_r_s_spec_s0[3] = 
	  {f_r_s_i[(REM_W-1)-2:0], 2'b0}
	^ {f_r_c_i[(REM_W-1)-2:0], 2'b0}
	^ sqrt_csa_val_neg_1[0];
	assign nxt_f_r_c_spec_s0[3] = {
		  ({f_r_s_i[(REM_W-1)-3:0], 2'b0} & {f_r_c_i[(REM_W-1)-3:0], 2'b0})
		| ({f_r_s_i[(REM_W-1)-3:0], 2'b0} & sqrt_csa_val_neg_1[0][(REM_W-1)-1:0])
		| ({f_r_c_i[(REM_W-1)-3:0], 2'b0} & sqrt_csa_val_neg_1[0][(REM_W-1)-1:0]),
		1'b0
	};

	// Here we assume nxt_rt_dig[0] = 0
	assign nxt_f_r_s_spec_s0[2] = {f_r_s_i[(REM_W-1)-2:0], 2'b0};
	assign nxt_f_r_c_spec_s0[2] = {f_r_c_i[(REM_W-1)-2:0], 2'b0};

	// Here we assume nxt_rt_dig[0] = +1
	assign nxt_f_r_s_spec_s0[1] = 
	  {f_r_s_i[(REM_W-1)-2:0], 2'b0}
	^ {f_r_c_i[(REM_W-1)-2:0], 2'b0}
	^ sqrt_csa_val_pos_1[0];
	assign nxt_f_r_c_spec_s0[1] = {
		  ({f_r_s_i[(REM_W-1)-3:0], 2'b0} & {f_r_c_i[(REM_W-1)-3:0], 2'b0})
		| ({f_r_s_i[(REM_W-1)-3:0], 2'b0} & sqrt_csa_val_pos_1[0][(REM_W-1)-1:0])
		| ({f_r_c_i[(REM_W-1)-3:0], 2'b0} & sqrt_csa_val_pos_1[0][(REM_W-1)-1:0]),
		1'b1
	};

	// Here we assume nxt_rt_dig[0] = +2
	assign nxt_f_r_s_spec_s0[0] = 
	  {f_r_s_i[(REM_W-1)-2:0], 2'b0}
	^ {f_r_c_i[(REM_W-1)-2:0], 2'b0}
	^ sqrt_csa_val_pos_2[0];
	assign nxt_f_r_c_spec_s0[0] = {
		  ({f_r_s_i[(REM_W-1)-3:0], 2'b0} & {f_r_c_i[(REM_W-1)-3:0], 2'b0})
		| ({f_r_s_i[(REM_W-1)-3:0], 2'b0} & sqrt_csa_val_pos_2[0][(REM_W-1)-1:0])
		| ({f_r_c_i[(REM_W-1)-3:0], 2'b0} & sqrt_csa_val_pos_2[0][(REM_W-1)-1:0]),
		1'b1
	};

	assign nxt_f_r_s[0] = 
	  ({(REM_W){nxt_rt_dig[0][4]}} & nxt_f_r_s_spec_s0[4])
	| ({(REM_W){nxt_rt_dig[0][3]}} & nxt_f_r_s_spec_s0[3])
	| ({(REM_W){nxt_rt_dig[0][2]}} & nxt_f_r_s_spec_s0[2])
	| ({(REM_W){nxt_rt_dig[0][1]}} & nxt_f_r_s_spec_s0[1])
	| ({(REM_W){nxt_rt_dig[0][0]}} & nxt_f_r_s_spec_s0[0]);
	assign nxt_f_r_c[0] = 
	  ({(REM_W){nxt_rt_dig[0][4]}} & nxt_f_r_c_spec_s0[4])
	| ({(REM_W){nxt_rt_dig[0][3]}} & nxt_f_r_c_spec_s0[3])
	| ({(REM_W){nxt_rt_dig[0][2]}} & nxt_f_r_c_spec_s0[2])
	| ({(REM_W){nxt_rt_dig[0][1]}} & nxt_f_r_c_spec_s0[1])
	| ({(REM_W){nxt_rt_dig[0][0]}} & nxt_f_r_c_spec_s0[0]);

end else begin: g_s0_csa_no_spec

	// If timing is good enough, let the CSA operation starts after "nxt_rt_dig[0]"" is available, so the area of the CSA is reduced.

	assign sqrt_csa_val[0] = 
	  ({(REM_W){nxt_rt_dig[0][4]}} & sqrt_csa_val_neg_2[0])
	| ({(REM_W){nxt_rt_dig[0][3]}} & sqrt_csa_val_neg_1[0])
	| ({(REM_W){nxt_rt_dig[0][1]}} & sqrt_csa_val_pos_1[0])
	| ({(REM_W){nxt_rt_dig[0][0]}} & sqrt_csa_val_pos_2[0]);

	assign nxt_f_r_s[0] = 
	  {f_r_s_i[(REM_W-1)-2:0], 2'b0}
	^ {f_r_c_i[(REM_W-1)-2:0], 2'b0}
	^ sqrt_csa_val[0];
	assign nxt_f_r_c[0] = {
		  ({f_r_s_i[(REM_W-1)-3:0], 2'b0} & {f_r_c_i[(REM_W-1)-3:0], 2'b0})
		| ({f_r_s_i[(REM_W-1)-3:0], 2'b0} & sqrt_csa_val[0][(REM_W-1)-1:0])
		| ({f_r_c_i[(REM_W-1)-3:0], 2'b0} & sqrt_csa_val[0][(REM_W-1)-1:0]),
		nxt_rt_dig[0][1] | nxt_rt_dig[0][0]
	};
end
endgenerate

// Get the non-redundant form, for stage[1].qds
assign adder_9b_for_s1_qds_spec[4] = nr_f_r_9b_for_nxt_cycle_s1_qds_i + sqrt_csa_val_neg_2[0][(REM_W-1) -: 9];
assign adder_9b_for_s1_qds_spec[3] = nr_f_r_9b_for_nxt_cycle_s1_qds_i + sqrt_csa_val_neg_1[0][(REM_W-1) -: 9];
assign adder_9b_for_s1_qds_spec[2] = nr_f_r_9b_for_nxt_cycle_s1_qds_i;
assign adder_9b_for_s1_qds_spec[1] = nr_f_r_9b_for_nxt_cycle_s1_qds_i + sqrt_csa_val_pos_1[0][(REM_W-1) -: 9];
assign adder_9b_for_s1_qds_spec[0] = nr_f_r_9b_for_nxt_cycle_s1_qds_i + sqrt_csa_val_pos_2[0][(REM_W-1) -: 9];

// ================================================================================================================================================
// stage[0].cg
// This is done in parallel with qds
// ================================================================================================================================================
assign nxt_rt_spec_s0[4] = rt_m1 | mask_rt_neg_2[0];
assign nxt_rt_spec_s0[3] = rt_m1 | mask_rt_neg_1[0];
assign nxt_rt_spec_s0[2] = rt;
assign nxt_rt_spec_s0[1] = rt    | mask_rt_pos_1[0];
assign nxt_rt_spec_s0[0] = rt    | mask_rt_pos_2[0];

assign a0_spec_s0[4] = nxt_rt_spec_s0[4][F64_FULL_RT_W-1];
assign a2_spec_s0[4] = nxt_rt_spec_s0[4][F64_FULL_RT_W-3];
assign a3_spec_s0[4] = nxt_rt_spec_s0[4][F64_FULL_RT_W-4];
assign a4_spec_s0[4] = nxt_rt_spec_s0[4][F64_FULL_RT_W-5];

assign a0_spec_s0[3] = nxt_rt_spec_s0[3][F64_FULL_RT_W-1];
assign a2_spec_s0[3] = nxt_rt_spec_s0[3][F64_FULL_RT_W-3];
assign a3_spec_s0[3] = nxt_rt_spec_s0[3][F64_FULL_RT_W-4];
assign a4_spec_s0[3] = nxt_rt_spec_s0[3][F64_FULL_RT_W-5];

assign a0_spec_s0[2] = nxt_rt_spec_s0[2][F64_FULL_RT_W-1];
assign a2_spec_s0[2] = nxt_rt_spec_s0[2][F64_FULL_RT_W-3];
assign a3_spec_s0[2] = nxt_rt_spec_s0[2][F64_FULL_RT_W-4];
assign a4_spec_s0[2] = nxt_rt_spec_s0[2][F64_FULL_RT_W-5];

assign a0_spec_s0[1] = nxt_rt_spec_s0[1][F64_FULL_RT_W-1];
assign a2_spec_s0[1] = nxt_rt_spec_s0[1][F64_FULL_RT_W-3];
assign a3_spec_s0[1] = nxt_rt_spec_s0[1][F64_FULL_RT_W-4];
assign a4_spec_s0[1] = nxt_rt_spec_s0[1][F64_FULL_RT_W-5];

assign a0_spec_s0[0] = nxt_rt_spec_s0[0][F64_FULL_RT_W-1];
assign a2_spec_s0[0] = nxt_rt_spec_s0[0][F64_FULL_RT_W-3];
assign a3_spec_s0[0] = nxt_rt_spec_s0[0][F64_FULL_RT_W-4];
assign a4_spec_s0[0] = nxt_rt_spec_s0[0][F64_FULL_RT_W-5];

r4_qds_cg 
u_r4_qds_cg_spec_s0_neg_2 (
	.a0_i(a0_spec_s0[4]),
	.a2_i(a2_spec_s0[4]),
	.a3_i(a3_spec_s0[4]),
	.a4_i(a4_spec_s0[4]),
	.m_neg_1_o(m_neg_1_spec_s0[4]),
	.m_neg_0_o(m_neg_0_spec_s0[4]),
	.m_pos_1_o(m_pos_1_spec_s0[4]),
	.m_pos_2_o(m_pos_2_spec_s0[4])
);

r4_qds_cg 
u_r4_qds_cg_spec_s0_neg_1 (
	.a0_i(a0_spec_s0[3]),
	.a2_i(a2_spec_s0[3]),
	.a3_i(a3_spec_s0[3]),
	.a4_i(a4_spec_s0[3]),
	.m_neg_1_o(m_neg_1_spec_s0[3]),
	.m_neg_0_o(m_neg_0_spec_s0[3]),
	.m_pos_1_o(m_pos_1_spec_s0[3]),
	.m_pos_2_o(m_pos_2_spec_s0[3])
);

r4_qds_cg 
u_r4_qds_cg_spec_s0_neg_0 (
	.a0_i(a0_spec_s0[2]),
	.a2_i(a2_spec_s0[2]),
	.a3_i(a3_spec_s0[2]),
	.a4_i(a4_spec_s0[2]),
	.m_neg_1_o(m_neg_1_spec_s0[2]),
	.m_neg_0_o(m_neg_0_spec_s0[2]),
	.m_pos_1_o(m_pos_1_spec_s0[2]),
	.m_pos_2_o(m_pos_2_spec_s0[2])
);

r4_qds_cg 
u_r4_qds_cg_spec_s0_pos_1 (
	.a0_i(a0_spec_s0[1]),
	.a2_i(a2_spec_s0[1]),
	.a3_i(a3_spec_s0[1]),
	.a4_i(a4_spec_s0[1]),
	.m_neg_1_o(m_neg_1_spec_s0[1]),
	.m_neg_0_o(m_neg_0_spec_s0[1]),
	.m_pos_1_o(m_pos_1_spec_s0[1]),
	.m_pos_2_o(m_pos_2_spec_s0[1])
);

r4_qds_cg 
u_r4_qds_cg_spec_s0_pos_2 (
	.a0_i(a0_spec_s0[0]),
	.a2_i(a2_spec_s0[0]),
	.a3_i(a3_spec_s0[0]),
	.a4_i(a4_spec_s0[0]),
	.m_neg_1_o(m_neg_1_spec_s0[0]),
	.m_neg_0_o(m_neg_0_spec_s0[0]),
	.m_pos_1_o(m_pos_1_spec_s0[0]),
	.m_pos_2_o(m_pos_2_spec_s0[0])
);

// ================================================================================================================================================
// Select the signals for stage[1]
// ================================================================================================================================================

assign adder_7b_res_for_s1_qds = 
  ({(7){nxt_rt_dig[0][4]}} & adder_9b_for_s1_qds_spec[4][8:2])
| ({(7){nxt_rt_dig[0][3]}} & adder_9b_for_s1_qds_spec[3][8:2])
| ({(7){nxt_rt_dig[0][2]}} & adder_9b_for_s1_qds_spec[2][8:2])
| ({(7){nxt_rt_dig[0][1]}} & adder_9b_for_s1_qds_spec[1][8:2])
| ({(7){nxt_rt_dig[0][0]}} & adder_9b_for_s1_qds_spec[0][8:2]);

assign m_neg_1[1] = 
  ({(7){nxt_rt_dig[0][4]}} & m_neg_1_spec_s0[4])
| ({(7){nxt_rt_dig[0][3]}} & m_neg_1_spec_s0[3])
| ({(7){nxt_rt_dig[0][2]}} & m_neg_1_spec_s0[2])
| ({(7){nxt_rt_dig[0][1]}} & m_neg_1_spec_s0[1])
| ({(7){nxt_rt_dig[0][0]}} & m_neg_1_spec_s0[0]);
assign m_neg_0[1] = 
  ({(7){nxt_rt_dig[0][4]}} & m_neg_0_spec_s0[4])
| ({(7){nxt_rt_dig[0][3]}} & m_neg_0_spec_s0[3])
| ({(7){nxt_rt_dig[0][2]}} & m_neg_0_spec_s0[2])
| ({(7){nxt_rt_dig[0][1]}} & m_neg_0_spec_s0[1])
| ({(7){nxt_rt_dig[0][0]}} & m_neg_0_spec_s0[0]);
assign m_pos_1[1] = 
  ({(7){nxt_rt_dig[0][4]}} & m_pos_1_spec_s0[4])
| ({(7){nxt_rt_dig[0][3]}} & m_pos_1_spec_s0[3])
| ({(7){nxt_rt_dig[0][2]}} & m_pos_1_spec_s0[2])
| ({(7){nxt_rt_dig[0][1]}} & m_pos_1_spec_s0[1])
| ({(7){nxt_rt_dig[0][0]}} & m_pos_1_spec_s0[0]);
assign m_pos_2[1] = 
  ({(7){nxt_rt_dig[0][4]}} & m_pos_2_spec_s0[4])
| ({(7){nxt_rt_dig[0][3]}} & m_pos_2_spec_s0[3])
| ({(7){nxt_rt_dig[0][2]}} & m_pos_2_spec_s0[2])
| ({(7){nxt_rt_dig[0][1]}} & m_pos_2_spec_s0[1])
| ({(7){nxt_rt_dig[0][0]}} & m_pos_2_spec_s0[0]);

// ================================================================================================================================================
// OFC after stage[0].qds is finished
// ================================================================================================================================================
assign nxt_rt[0] = 
  ({(F64_FULL_RT_W){nxt_rt_dig[0][4]}} & nxt_rt_spec_s0[4])
| ({(F64_FULL_RT_W){nxt_rt_dig[0][3]}} & nxt_rt_spec_s0[3])
| ({(F64_FULL_RT_W){nxt_rt_dig[0][2]}} & nxt_rt_spec_s0[2])
| ({(F64_FULL_RT_W){nxt_rt_dig[0][1]}} & nxt_rt_spec_s0[1])
| ({(F64_FULL_RT_W){nxt_rt_dig[0][0]}} & nxt_rt_spec_s0[0]);
assign nxt_rt_m1[0] = 
  ({(F64_FULL_RT_W){nxt_rt_dig[0][4]}} & (rt_m1 | mask_rt_m1_neg_2[0]))
| ({(F64_FULL_RT_W){nxt_rt_dig[0][3]}} & (rt_m1 | mask_rt_m1_neg_1[0]))
| ({(F64_FULL_RT_W){nxt_rt_dig[0][2]}} & (rt_m1 | mask_rt_m1_neg_0[0]))
| ({(F64_FULL_RT_W){nxt_rt_dig[0][1]}} & rt)
| ({(F64_FULL_RT_W){nxt_rt_dig[0][0]}} & (rt    | mask_rt_m1_pos_2[0]));

// ================================================================================================================================================
// stage[1].csa + full-adder
// This is done in parallel with qds
// ================================================================================================================================================
assign sqrt_csa_val_neg_2[1] = ({1'b0, nxt_rt_m1[0]} << 2) | mask_csa_neg_2[1];
assign sqrt_csa_val_neg_1[1] = ({1'b0, nxt_rt_m1[0]} << 1) | mask_csa_neg_1[1];
assign sqrt_csa_val_pos_1[1] = ~(({1'b0, nxt_rt[0]} << 1) | mask_csa_pos_1[1]);
assign sqrt_csa_val_pos_2[1] = ~(({1'b0, nxt_rt[0]} << 2) | mask_csa_pos_2[1]);

generate
if(S1_CSA_SPECULATIVE == 1) begin

	// Here we assume nxt_rt_dig[1] = -2
	assign nxt_f_r_s_spec_s1[4] = 
	  {nxt_f_r_s[0][(REM_W-1)-2:0], 2'b0}
	^ {nxt_f_r_c[0][(REM_W-1)-2:0], 2'b0}
	^ sqrt_csa_val_neg_2[1];
	assign nxt_f_r_c_spec_s1[4] = {
		  ({nxt_f_r_s[0][(REM_W-1)-3:0], 2'b0} & {nxt_f_r_c[0][(REM_W-1)-3:0], 2'b0})
		| ({nxt_f_r_s[0][(REM_W-1)-3:0], 2'b0} & sqrt_csa_val_neg_2[1][(REM_W-1)-1:0])
		| ({nxt_f_r_c[0][(REM_W-1)-3:0], 2'b0} & sqrt_csa_val_neg_2[1][(REM_W-1)-1:0]),
		1'b0
	};

	// Here we assume nxt_rt_dig[1] = -1
	assign nxt_f_r_s_spec_s1[3] = 
	  {nxt_f_r_s[0][(REM_W-1)-2:0], 2'b0}
	^ {nxt_f_r_c[0][(REM_W-1)-2:0], 2'b0}
	^ sqrt_csa_val_neg_1[1];
	assign nxt_f_r_c_spec_s1[3] = {
		  ({nxt_f_r_s[0][(REM_W-1)-3:0], 2'b0} & {nxt_f_r_c[0][(REM_W-1)-3:0], 2'b0})
		| ({nxt_f_r_s[0][(REM_W-1)-3:0], 2'b0} & sqrt_csa_val_neg_1[1][(REM_W-1)-1:0])
		| ({nxt_f_r_c[0][(REM_W-1)-3:0], 2'b0} & sqrt_csa_val_neg_1[1][(REM_W-1)-1:0]),
		1'b0
	};

	// Here we assume nxt_rt_dig[1] = 0
	assign nxt_f_r_s_spec_s1[2] = {nxt_f_r_s[0][(REM_W-1)-2:0], 2'b0};
	assign nxt_f_r_c_spec_s1[2] = {nxt_f_r_c[0][(REM_W-1)-2:0], 2'b0};

	// Here we assume nxt_rt_dig[1] = +1
	assign nxt_f_r_s_spec_s1[1] = 
	  {nxt_f_r_s[0][(REM_W-1)-2:0], 2'b0}
	^ {nxt_f_r_c[0][(REM_W-1)-2:0], 2'b0}
	^ sqrt_csa_val_pos_1[1];
	assign nxt_f_r_c_spec_s1[1] = {
		  ({nxt_f_r_s[0][(REM_W-1)-3:0], 2'b0} & {nxt_f_r_c[0][(REM_W-1)-3:0], 2'b0})
		| ({nxt_f_r_s[0][(REM_W-1)-3:0], 2'b0} & sqrt_csa_val_pos_1[1][(REM_W-1)-1:0])
		| ({nxt_f_r_c[0][(REM_W-1)-3:0], 2'b0} & sqrt_csa_val_pos_1[1][(REM_W-1)-1:0]),
		1'b1
	};

	// Here we assume nxt_rt_dig[1] = +2
	assign nxt_f_r_s_spec_s1[0] = 
	  {nxt_f_r_s[0][(REM_W-1)-2:0], 2'b0}
	^ {nxt_f_r_c[0][(REM_W-1)-2:0], 2'b0}
	^ sqrt_csa_val_pos_2[1];
	assign nxt_f_r_c_spec_s1[0] = {
		  ({nxt_f_r_s[0][(REM_W-1)-3:0], 2'b0} & {nxt_f_r_c[0][(REM_W-1)-3:0], 2'b0})
		| ({nxt_f_r_s[0][(REM_W-1)-3:0], 2'b0} & sqrt_csa_val_pos_2[1][(REM_W-1)-1:0])
		| ({nxt_f_r_c[0][(REM_W-1)-3:0], 2'b0} & sqrt_csa_val_pos_2[1][(REM_W-1)-1:0]),
		1'b1
	};

	assign nxt_f_r_s[1] = 
	  ({(REM_W){nxt_rt_dig[1][4]}} & nxt_f_r_s_spec_s1[4])
	| ({(REM_W){nxt_rt_dig[1][3]}} & nxt_f_r_s_spec_s1[3])
	| ({(REM_W){nxt_rt_dig[1][2]}} & nxt_f_r_s_spec_s1[2])
	| ({(REM_W){nxt_rt_dig[1][1]}} & nxt_f_r_s_spec_s1[1])
	| ({(REM_W){nxt_rt_dig[1][0]}} & nxt_f_r_s_spec_s1[0]);
	assign nxt_f_r_c[1] = 
	  ({(REM_W){nxt_rt_dig[1][4]}} & nxt_f_r_c_spec_s1[4])
	| ({(REM_W){nxt_rt_dig[1][3]}} & nxt_f_r_c_spec_s1[3])
	| ({(REM_W){nxt_rt_dig[1][2]}} & nxt_f_r_c_spec_s1[2])
	| ({(REM_W){nxt_rt_dig[1][1]}} & nxt_f_r_c_spec_s1[1])
	| ({(REM_W){nxt_rt_dig[1][0]}} & nxt_f_r_c_spec_s1[0]);

end else begin

	// If timing is good enough, let the CSA operation starts after "nxt_rt_dig[1]" is available, so the area of the CSA is reduced.

	assign sqrt_csa_val[1] = 
	  ({(REM_W){nxt_rt_dig[1][4]}} & sqrt_csa_val_neg_2[1])
	| ({(REM_W){nxt_rt_dig[1][3]}} & sqrt_csa_val_neg_1[1])
	| ({(REM_W){nxt_rt_dig[1][1]}} & sqrt_csa_val_pos_1[1])
	| ({(REM_W){nxt_rt_dig[1][0]}} & sqrt_csa_val_pos_2[1]);

	assign nxt_f_r_s[1] = 
	  {nxt_f_r_s[0][(REM_W-1)-2:0], 2'b0}
	^ {nxt_f_r_c[0][(REM_W-1)-2:0], 2'b0}
	^ sqrt_csa_val[1];
	assign nxt_f_r_c[1] = {
		  ({nxt_f_r_s[0][(REM_W-1)-3:0], 2'b0} & {nxt_f_r_c[0][(REM_W-1)-3:0], 2'b0})
		| ({nxt_f_r_s[0][(REM_W-1)-3:0], 2'b0} & sqrt_csa_val[1][(REM_W-1)-1:0])
		| ({nxt_f_r_c[0][(REM_W-1)-3:0], 2'b0} & sqrt_csa_val[1][(REM_W-1)-1:0]),
		nxt_rt_dig[1][1] | nxt_rt_dig[1][0]
	};

end
endgenerate

// Get the non-redundant form, for stage[0].qds in the nxt cycle
assign adder_9b_for_nxt_cycle_s0_qds_spec[4] = 
  nxt_f_r_s[0][(REM_W-1)-2 -: 9]
+ nxt_f_r_c[0][(REM_W-1)-2 -: 9]
+ sqrt_csa_val_neg_2[1][(REM_W-1) -: 9];

assign adder_9b_for_nxt_cycle_s0_qds_spec[3] = 
  nxt_f_r_s[0][(REM_W-1)-2 -: 9]
+ nxt_f_r_c[0][(REM_W-1)-2 -: 9]
+ sqrt_csa_val_neg_1[1][(REM_W-1) -: 9];

assign adder_9b_for_nxt_cycle_s0_qds_spec[2] = 
  nxt_f_r_s[0][(REM_W-1)-2 -: 9]
+ nxt_f_r_c[0][(REM_W-1)-2 -: 9];

assign adder_9b_for_nxt_cycle_s0_qds_spec[1] = 
  nxt_f_r_s[0][(REM_W-1)-2 -: 9]
+ nxt_f_r_c[0][(REM_W-1)-2 -: 9]
+ sqrt_csa_val_pos_1[1][(REM_W-1) -: 9];

assign adder_9b_for_nxt_cycle_s0_qds_spec[0] = 
  nxt_f_r_s[0][(REM_W-1)-2 -: 9]
+ nxt_f_r_c[0][(REM_W-1)-2 -: 9]
+ sqrt_csa_val_pos_2[1][(REM_W-1) -: 9];

// Get the non-redundant form, for stage[1].qds in the nxt cycle
assign adder_10b_for_nxt_cycle_s1_qds_spec[4] = 
  nxt_f_r_s[0][(REM_W-1)-2-2 -: 10]
+ nxt_f_r_c[0][(REM_W-1)-2-2 -: 10]
+ sqrt_csa_val_neg_2[1][(REM_W-1)-2 -: 10];

assign adder_10b_for_nxt_cycle_s1_qds_spec[3] = 
  nxt_f_r_s[0][(REM_W-1)-2-2 -: 10]
+ nxt_f_r_c[0][(REM_W-1)-2-2 -: 10]
+ sqrt_csa_val_neg_1[1][(REM_W-1)-2 -: 10];

assign adder_10b_for_nxt_cycle_s1_qds_spec[2] = 
  nxt_f_r_s[0][(REM_W-1)-2-2 -: 10]
+ nxt_f_r_c[0][(REM_W-1)-2-2 -: 10];

assign adder_10b_for_nxt_cycle_s1_qds_spec[1] = 
  nxt_f_r_s[0][(REM_W-1)-2-2 -: 10]
+ nxt_f_r_c[0][(REM_W-1)-2-2 -: 10]
+ sqrt_csa_val_pos_1[1][(REM_W-1)-2 -: 10];

assign adder_10b_for_nxt_cycle_s1_qds_spec[0] = 
  nxt_f_r_s[0][(REM_W-1)-2-2 -: 10]
+ nxt_f_r_c[0][(REM_W-1)-2-2 -: 10]
+ sqrt_csa_val_pos_2[1][(REM_W-1)-2 -: 10];

// ================================================================================================================================================
// stage[1].cg
// This is done in parallel with qds
// ================================================================================================================================================
assign nxt_rt_spec_s1[4] = nxt_rt_m1[0] | mask_rt_neg_2[1];
assign nxt_rt_spec_s1[3] = nxt_rt_m1[0] | mask_rt_neg_1[1];
assign nxt_rt_spec_s1[2] = nxt_rt[0];
assign nxt_rt_spec_s1[1] = nxt_rt[0]    | mask_rt_pos_1[1];
assign nxt_rt_spec_s1[0] = nxt_rt[0]    | mask_rt_pos_2[1];

assign a0_spec_s1[4] = nxt_rt_spec_s1[4][F64_FULL_RT_W-1];
assign a2_spec_s1[4] = nxt_rt_spec_s1[4][F64_FULL_RT_W-3];
assign a3_spec_s1[4] = nxt_rt_spec_s1[4][F64_FULL_RT_W-4];
assign a4_spec_s1[4] = nxt_rt_spec_s1[4][F64_FULL_RT_W-5];

assign a0_spec_s1[3] = nxt_rt_spec_s1[3][F64_FULL_RT_W-1];
assign a2_spec_s1[3] = nxt_rt_spec_s1[3][F64_FULL_RT_W-3];
assign a3_spec_s1[3] = nxt_rt_spec_s1[3][F64_FULL_RT_W-4];
assign a4_spec_s1[3] = nxt_rt_spec_s1[3][F64_FULL_RT_W-5];

assign a0_spec_s1[2] = nxt_rt_spec_s1[2][F64_FULL_RT_W-1];
assign a2_spec_s1[2] = nxt_rt_spec_s1[2][F64_FULL_RT_W-3];
assign a3_spec_s1[2] = nxt_rt_spec_s1[2][F64_FULL_RT_W-4];
assign a4_spec_s1[2] = nxt_rt_spec_s1[2][F64_FULL_RT_W-5];

assign a0_spec_s1[1] = nxt_rt_spec_s1[1][F64_FULL_RT_W-1];
assign a2_spec_s1[1] = nxt_rt_spec_s1[1][F64_FULL_RT_W-3];
assign a3_spec_s1[1] = nxt_rt_spec_s1[1][F64_FULL_RT_W-4];
assign a4_spec_s1[1] = nxt_rt_spec_s1[1][F64_FULL_RT_W-5];

assign a0_spec_s1[0] = nxt_rt_spec_s1[0][F64_FULL_RT_W-1];
assign a2_spec_s1[0] = nxt_rt_spec_s1[0][F64_FULL_RT_W-3];
assign a3_spec_s1[0] = nxt_rt_spec_s1[0][F64_FULL_RT_W-4];
assign a4_spec_s1[0] = nxt_rt_spec_s1[0][F64_FULL_RT_W-5];

r4_qds_cg 
u_r4_qds_cg_spec_s1_neg_2 (
	.a0_i(a0_spec_s1[4]),
	.a2_i(a2_spec_s1[4]),
	.a3_i(a3_spec_s1[4]),
	.a4_i(a4_spec_s1[4]),
	.m_neg_1_o(m_neg_1_spec_s1[4]),
	.m_neg_0_o(m_neg_0_spec_s1[4]),
	.m_pos_1_o(m_pos_1_spec_s1[4]),
	.m_pos_2_o(m_pos_2_spec_s1[4])
);

r4_qds_cg 
u_r4_qds_cg_spec_s1_neg_1 (
	.a0_i(a0_spec_s1[3]),
	.a2_i(a2_spec_s1[3]),
	.a3_i(a3_spec_s1[3]),
	.a4_i(a4_spec_s1[3]),
	.m_neg_1_o(m_neg_1_spec_s1[3]),
	.m_neg_0_o(m_neg_0_spec_s1[3]),
	.m_pos_1_o(m_pos_1_spec_s1[3]),
	.m_pos_2_o(m_pos_2_spec_s1[3])
);

r4_qds_cg 
u_r4_qds_cg_spec_s1_neg_0 (
	.a0_i(a0_spec_s1[2]),
	.a2_i(a2_spec_s1[2]),
	.a3_i(a3_spec_s1[2]),
	.a4_i(a4_spec_s1[2]),
	.m_neg_1_o(m_neg_1_spec_s1[2]),
	.m_neg_0_o(m_neg_0_spec_s1[2]),
	.m_pos_1_o(m_pos_1_spec_s1[2]),
	.m_pos_2_o(m_pos_2_spec_s1[2])
);

r4_qds_cg 
u_r4_qds_cg_spec_s1_pos_1 (
	.a0_i(a0_spec_s1[1]),
	.a2_i(a2_spec_s1[1]),
	.a3_i(a3_spec_s1[1]),
	.a4_i(a4_spec_s1[1]),
	.m_neg_1_o(m_neg_1_spec_s1[1]),
	.m_neg_0_o(m_neg_0_spec_s1[1]),
	.m_pos_1_o(m_pos_1_spec_s1[1]),
	.m_pos_2_o(m_pos_2_spec_s1[1])
);

r4_qds_cg 
u_r4_qds_cg_spec_s1_pos_2 (
	.a0_i(a0_spec_s1[0]),
	.a2_i(a2_spec_s1[0]),
	.a3_i(a3_spec_s1[0]),
	.a4_i(a4_spec_s1[0]),
	.m_neg_1_o(m_neg_1_spec_s1[0]),
	.m_neg_0_o(m_neg_0_spec_s1[0]),
	.m_pos_1_o(m_pos_1_spec_s1[0]),
	.m_pos_2_o(m_pos_2_spec_s1[0])
);

// ================================================================================================================================================
// stage[1].qds
// ================================================================================================================================================
generate
if(S1_QDS_SPECULATIVE == 1) begin: g_s1_qds_spec
	r4_qds_spec
	u_r4_qds_s1 (
		.rem_i(nr_f_r_9b_for_nxt_cycle_s1_qds_i),
		.sqrt_csa_val_neg_2_msbs_i(sqrt_csa_val_neg_2[0][(REM_W-1) -: 9]),
		.sqrt_csa_val_neg_1_msbs_i(sqrt_csa_val_neg_1[0][(REM_W-1) -: 9]),
		.sqrt_csa_val_pos_1_msbs_i(sqrt_csa_val_pos_1[0][(REM_W-1) -: 9]),
		.sqrt_csa_val_pos_2_msbs_i(sqrt_csa_val_pos_2[0][(REM_W-1) -: 9]),

		.m_neg_1_neg_2_i(m_neg_1_spec_s0[4]),
		.m_neg_0_neg_2_i(m_neg_0_spec_s0[4]),
		.m_pos_1_neg_2_i(m_pos_1_spec_s0[4]),
		.m_pos_2_neg_2_i(m_pos_2_spec_s0[4]),

		.m_neg_1_neg_1_i(m_neg_1_spec_s0[3]),
		.m_neg_0_neg_1_i(m_neg_0_spec_s0[3]),
		.m_pos_1_neg_1_i(m_pos_1_spec_s0[3]),
		.m_pos_2_neg_1_i(m_pos_2_spec_s0[3]),

		.m_neg_1_neg_0_i(m_neg_1_spec_s0[2]),
		.m_neg_0_neg_0_i(m_neg_0_spec_s0[2]),
		.m_pos_1_neg_0_i(m_pos_1_spec_s0[2]),
		.m_pos_2_neg_0_i(m_pos_2_spec_s0[2]),

		.m_neg_1_pos_1_i(m_neg_1_spec_s0[1]),
		.m_neg_0_pos_1_i(m_neg_0_spec_s0[1]),
		.m_pos_1_pos_1_i(m_pos_1_spec_s0[1]),
		.m_pos_2_pos_1_i(m_pos_2_spec_s0[1]),

		.m_neg_1_pos_2_i(m_neg_1_spec_s0[0]),
		.m_neg_0_pos_2_i(m_neg_0_spec_s0[0]),
		.m_pos_1_pos_2_i(m_pos_1_spec_s0[0]),
		.m_pos_2_pos_2_i(m_pos_2_spec_s0[0]),
		
		.prev_rt_dig_i(nxt_rt_dig[0]),
		.rt_dig_o(nxt_rt_dig[1])
	);
end else begin: g_s1_qds_no_spec
	r4_qds
	u_r4_qds_s1 (
		.rem_i(adder_7b_res_for_s1_qds),
		.m_neg_1_i(m_neg_1[1]),
		.m_neg_0_i(m_neg_0[1]),
		.m_pos_1_i(m_pos_1[1]),
		.m_pos_2_i(m_pos_2[1]),
		.rt_dig_o(nxt_rt_dig[1])
	);
end
endgenerate

// ================================================================================================================================================
// Select the signals for nxt cycle
// ================================================================================================================================================
assign adder_7b_res_for_nxt_cycle_s0_qds_o = 
  ({(7){nxt_rt_dig[1][4]}} & adder_9b_for_nxt_cycle_s0_qds_spec[4][8:2])
| ({(7){nxt_rt_dig[1][3]}} & adder_9b_for_nxt_cycle_s0_qds_spec[3][8:2])
| ({(7){nxt_rt_dig[1][2]}} & adder_9b_for_nxt_cycle_s0_qds_spec[2][8:2])
| ({(7){nxt_rt_dig[1][1]}} & adder_9b_for_nxt_cycle_s0_qds_spec[1][8:2])
| ({(7){nxt_rt_dig[1][0]}} & adder_9b_for_nxt_cycle_s0_qds_spec[0][8:2]);
assign adder_9b_res_for_nxt_cycle_s1_qds_o = 
  ({(9){nxt_rt_dig[1][4]}} & adder_10b_for_nxt_cycle_s1_qds_spec[4][9:1])
| ({(9){nxt_rt_dig[1][3]}} & adder_10b_for_nxt_cycle_s1_qds_spec[3][9:1])
| ({(9){nxt_rt_dig[1][2]}} & adder_10b_for_nxt_cycle_s1_qds_spec[2][9:1])
| ({(9){nxt_rt_dig[1][1]}} & adder_10b_for_nxt_cycle_s1_qds_spec[1][9:1])
| ({(9){nxt_rt_dig[1][0]}} & adder_10b_for_nxt_cycle_s1_qds_spec[0][9:1]);

assign m_neg_1_to_nxt_cycle_o = 
  ({(7){nxt_rt_dig[1][4]}} & m_neg_1_spec_s1[4])
| ({(7){nxt_rt_dig[1][3]}} & m_neg_1_spec_s1[3])
| ({(7){nxt_rt_dig[1][2]}} & m_neg_1_spec_s1[2])
| ({(7){nxt_rt_dig[1][1]}} & m_neg_1_spec_s1[1])
| ({(7){nxt_rt_dig[1][0]}} & m_neg_1_spec_s1[0]);
assign m_neg_0_to_nxt_cycle_o = 
  ({(7){nxt_rt_dig[1][4]}} & m_neg_0_spec_s1[4])
| ({(7){nxt_rt_dig[1][3]}} & m_neg_0_spec_s1[3])
| ({(7){nxt_rt_dig[1][2]}} & m_neg_0_spec_s1[2])
| ({(7){nxt_rt_dig[1][1]}} & m_neg_0_spec_s1[1])
| ({(7){nxt_rt_dig[1][0]}} & m_neg_0_spec_s1[0]);
assign m_pos_1_to_nxt_cycle_o = 
  ({(7){nxt_rt_dig[1][4]}} & m_pos_1_spec_s1[4])
| ({(7){nxt_rt_dig[1][3]}} & m_pos_1_spec_s1[3])
| ({(7){nxt_rt_dig[1][2]}} & m_pos_1_spec_s1[2])
| ({(7){nxt_rt_dig[1][1]}} & m_pos_1_spec_s1[1])
| ({(7){nxt_rt_dig[1][0]}} & m_pos_1_spec_s1[0]);
assign m_pos_2_to_nxt_cycle_o = 
  ({(7){nxt_rt_dig[1][4]}} & m_pos_2_spec_s1[4])
| ({(7){nxt_rt_dig[1][3]}} & m_pos_2_spec_s1[3])
| ({(7){nxt_rt_dig[1][2]}} & m_pos_2_spec_s1[2])
| ({(7){nxt_rt_dig[1][1]}} & m_pos_2_spec_s1[1])
| ({(7){nxt_rt_dig[1][0]}} & m_pos_2_spec_s1[0]);

assign nxt_rt[1] = 
  ({(F64_FULL_RT_W){nxt_rt_dig[1][4]}} & nxt_rt_spec_s1[4])
| ({(F64_FULL_RT_W){nxt_rt_dig[1][3]}} & nxt_rt_spec_s1[3])
| ({(F64_FULL_RT_W){nxt_rt_dig[1][2]}} & nxt_rt_spec_s1[2])
| ({(F64_FULL_RT_W){nxt_rt_dig[1][1]}} & nxt_rt_spec_s1[1])
| ({(F64_FULL_RT_W){nxt_rt_dig[1][0]}} & nxt_rt_spec_s1[0]);
assign nxt_rt_m1[1] = 
  ({(F64_FULL_RT_W){nxt_rt_dig[1][4]}} & (nxt_rt_m1[0] | mask_rt_m1_neg_2[1]))
| ({(F64_FULL_RT_W){nxt_rt_dig[1][3]}} & (nxt_rt_m1[0] | mask_rt_m1_neg_1[1]))
| ({(F64_FULL_RT_W){nxt_rt_dig[1][2]}} & (nxt_rt_m1[0] | mask_rt_m1_neg_0[1]))
| ({(F64_FULL_RT_W){nxt_rt_dig[1][1]}} & nxt_rt[0])
| ({(F64_FULL_RT_W){nxt_rt_dig[1][0]}} & (nxt_rt[0]    | mask_rt_m1_pos_2[1]));

assign nxt_rt_o = nxt_rt[1][(F64_FULL_RT_W-1)-1:0];
assign nxt_rt_m1_o = nxt_rt_m1[1][(F64_FULL_RT_W-2)-1:0];
assign nxt_f_r_s_o = nxt_f_r_s;
assign nxt_f_r_c_o = nxt_f_r_c;


endmodule

