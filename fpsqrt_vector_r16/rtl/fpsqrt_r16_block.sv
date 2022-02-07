// ========================================================================================================
// File Name			: fpsqrt_r16_block.sv
// Author				: HYF
// How to Contact		: hyf_sysu@qq.com
// Created Time    		: 2022-02-01 18:39:18
// Last Modified Time   : 2022-02-07 11:27:24
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
	parameter S0_CSA_MERGED = 1,	
	parameter S1_QDS_SPECULATIVE = 1,
	parameter S1_CSA_SPECULATIVE = 1,
	parameter S1_CSA_MERGED = 0,
	parameter REM_W = ((S0_CSA_SPECULATIVE == 0) & (S0_CSA_MERGED == 1)) ? 70 : 64,
	parameter RT_DIG_W = 5
)(
	input  logic [3-1:0] fp_fmt_i,
	input  logic [REM_W-1:0] f_r_s_i,
	input  logic [REM_W-1:0] f_r_c_i,
	input  logic [56-1:0] rt_i,
	input  logic [53-1:0] rt_m1_i,
	input  logic [13-1:0] mask_i,

	input  logic [7-1:0] nr_f_r_7b_for_nxt_cycle_s0_qds_0_i,
	input  logic [7-1:0] nr_f_r_7b_for_nxt_cycle_s0_qds_1_i,
	input  logic [7-1:0] nr_f_r_7b_for_nxt_cycle_s0_qds_2_i,
	input  logic [7-1:0] nr_f_r_7b_for_nxt_cycle_s0_qds_3_i,

	input  logic [9-1:0] nr_f_r_9b_for_nxt_cycle_s1_qds_0_i,
	input  logic [9-1:0] nr_f_r_9b_for_nxt_cycle_s1_qds_1_i,
	input  logic [9-1:0] nr_f_r_9b_for_nxt_cycle_s1_qds_2_i,
	input  logic [9-1:0] nr_f_r_9b_for_nxt_cycle_s1_qds_3_i,

	input  logic [5-1:0] m_neg_1_for_nxt_cycle_s0_qds_0_i,
	input  logic [5-1:0] m_neg_1_for_nxt_cycle_s0_qds_1_i,
	input  logic [5-1:0] m_neg_1_for_nxt_cycle_s0_qds_2_i,
	input  logic [5-1:0] m_neg_1_for_nxt_cycle_s0_qds_3_i,

	input  logic [4-1:0] m_neg_0_for_nxt_cycle_s0_qds_0_i,
	input  logic [4-1:0] m_neg_0_for_nxt_cycle_s0_qds_1_i,
	input  logic [4-1:0] m_neg_0_for_nxt_cycle_s0_qds_2_i,
	input  logic [4-1:0] m_neg_0_for_nxt_cycle_s0_qds_3_i,

	input  logic [3-1:0] m_pos_1_for_nxt_cycle_s0_qds_0_i,
	input  logic [3-1:0] m_pos_1_for_nxt_cycle_s0_qds_1_i,
	input  logic [3-1:0] m_pos_1_for_nxt_cycle_s0_qds_2_i,
	input  logic [3-1:0] m_pos_1_for_nxt_cycle_s0_qds_3_i,

	input  logic [4-1:0] m_pos_2_for_nxt_cycle_s0_qds_0_i,
	input  logic [4-1:0] m_pos_2_for_nxt_cycle_s0_qds_1_i,
	input  logic [4-1:0] m_pos_2_for_nxt_cycle_s0_qds_2_i,
	input  logic [4-1:0] m_pos_2_for_nxt_cycle_s0_qds_3_i,

	output logic [56-1:0] nxt_rt_o,
	output logic [53-1:0] nxt_rt_m1_o,
	
	output logic [REM_W-1:0] nxt_f_r_s_o,
	output logic [REM_W-1:0] nxt_f_r_c_o,

	output logic [7-1:0] adder_7b_res_for_nxt_cycle_s0_qds_0_o,
	output logic [7-1:0] adder_7b_res_for_nxt_cycle_s0_qds_1_o,
	output logic [7-1:0] adder_7b_res_for_nxt_cycle_s0_qds_2_o,
	output logic [7-1:0] adder_7b_res_for_nxt_cycle_s0_qds_3_o,

	output logic [9-1:0] adder_9b_res_for_nxt_cycle_s1_qds_0_o,
	output logic [9-1:0] adder_9b_res_for_nxt_cycle_s1_qds_1_o,
	output logic [9-1:0] adder_9b_res_for_nxt_cycle_s1_qds_2_o,
	output logic [9-1:0] adder_9b_res_for_nxt_cycle_s1_qds_3_o,

	output logic [7-1:0] m_neg_1_to_nxt_cycle_0_o,
	output logic [7-1:0] m_neg_1_to_nxt_cycle_1_o,
	output logic [7-1:0] m_neg_1_to_nxt_cycle_2_o,
	output logic [7-1:0] m_neg_1_to_nxt_cycle_3_o,

	output logic [7-1:0] m_neg_0_to_nxt_cycle_0_o,
	output logic [7-1:0] m_neg_0_to_nxt_cycle_1_o,
	output logic [7-1:0] m_neg_0_to_nxt_cycle_2_o,
	output logic [7-1:0] m_neg_0_to_nxt_cycle_3_o,

	output logic [7-1:0] m_pos_1_to_nxt_cycle_0_o,
	output logic [7-1:0] m_pos_1_to_nxt_cycle_1_o,
	output logic [7-1:0] m_pos_1_to_nxt_cycle_2_o,
	output logic [7-1:0] m_pos_1_to_nxt_cycle_3_o,

	output logic [7-1:0] m_pos_2_to_nxt_cycle_0_o,
	output logic [7-1:0] m_pos_2_to_nxt_cycle_1_o,
	output logic [7-1:0] m_pos_2_to_nxt_cycle_2_o,
	output logic [7-1:0] m_pos_2_to_nxt_cycle_3_o
);

// ================================================================================================================================================
// (local) parameters begin

// F64: We would get 54-bit root -> We need 54 + 2 = 56-bit REM.
localparam F64_REM_W = 2 + 54;
// F32: We would get 26-bit root -> We need 26 + 2 = 28-bit REM.
localparam F32_REM_W = 2 + 26;
// F16: We would get 14-bit root -> We need 14 + 2 = 16-bit REM.
localparam F16_REM_W = 2 + 14;

localparam MERGED_REM_W = (2 + F16_REM_W) * 3 + F16_REM_W;

// F64: The root could be 55-bit in the early stage, but finally the significant digits must be 54.
localparam F64_FULL_RT_W = F64_REM_W - 1;
// F32: The root could be 27-bit in the early stage, but finally the significant digits must be 26.
localparam F32_FULL_RT_W = F32_REM_W - 1;
// F16: The root could be 15-bit in the early stage, but finally the significant digits must be 14.
localparam F16_FULL_RT_W = F16_REM_W - 1;

// When we want to use the merged implementation for s0.csa, we should add 2-bit ZERO in REM between 2 F16 numbers as an interval.
localparam S0_CSA_IS_MERGED = (S0_CSA_SPECULATIVE == 0) & (S0_CSA_MERGED == 1);
localparam S1_CSA_IS_MERGED = (S1_CSA_SPECULATIVE == 0) & (S1_CSA_MERGED == 1);


// (local) parameters end
// ================================================================================================================================================

// ================================================================================================================================================
// signals begin

logic [F64_FULL_RT_W-1:0] rt_0;
logic [F64_FULL_RT_W-1:0] rt_m1_0;
logic [F64_FULL_RT_W-1:0] rt_for_csa_0 [2-1:0];
logic [F64_FULL_RT_W-1:0] rt_m1_for_csa_0 [2-1:0];

logic [F32_FULL_RT_W-1:0] rt_1;
logic [F32_FULL_RT_W-1:0] rt_m1_1;
logic [F32_FULL_RT_W-1:0] rt_for_csa_1 [2-1:0];
logic [F32_FULL_RT_W-1:0] rt_m1_for_csa_1 [2-1:0];

logic [F16_FULL_RT_W-1:0] rt_2;
logic [F16_FULL_RT_W-1:0] rt_m1_2;

logic [F16_FULL_RT_W-1:0] rt_3;
logic [F16_FULL_RT_W-1:0] rt_m1_3;

logic [F64_FULL_RT_W-1:0] nxt_rt_spec_s0_0 [5-1:0];
logic [F32_FULL_RT_W-1:0] nxt_rt_spec_s0_1 [5-1:0];
logic [F16_FULL_RT_W-1:0] nxt_rt_spec_s0_2 [5-1:0];
logic [F16_FULL_RT_W-1:0] nxt_rt_spec_s0_3 [5-1:0];

logic [F64_FULL_RT_W-1:0] nxt_rt_spec_s1_0 [5-1:0];
logic [F32_FULL_RT_W-1:0] nxt_rt_spec_s1_1 [5-1:0];
logic [F16_FULL_RT_W-1:0] nxt_rt_spec_s1_2 [5-1:0];
logic [F16_FULL_RT_W-1:0] nxt_rt_spec_s1_3 [5-1:0];

logic [F64_FULL_RT_W-1:0] nxt_rt_0 [2-1:0];
logic [F64_FULL_RT_W-1:0] nxt_rt_m1_0 [2-1:0];

logic [F32_FULL_RT_W-1:0] nxt_rt_1 [2-1:0];
logic [F32_FULL_RT_W-1:0] nxt_rt_m1_1 [2-1:0];

logic [F16_FULL_RT_W-1:0] nxt_rt_2 [2-1:0];
logic [F16_FULL_RT_W-1:0] nxt_rt_m1_2 [2-1:0];

logic [F16_FULL_RT_W-1:0] nxt_rt_3 [2-1:0];
logic [F16_FULL_RT_W-1:0] nxt_rt_m1_3 [2-1:0];

logic [RT_DIG_W-1:0] nxt_rt_dig_0 [2-1:0];
logic [RT_DIG_W-1:0] nxt_rt_dig_1 [2-1:0];
logic [RT_DIG_W-1:0] nxt_rt_dig_2 [2-1:0];
logic [RT_DIG_W-1:0] nxt_rt_dig_3 [2-1:0];

logic [F64_REM_W-1:0] mask_csa_ext [2-1:0];
logic [F64_REM_W-1:0] mask_csa_neg_2 [2-1:0];
logic [F64_REM_W-1:0] mask_csa_neg_1 [2-1:0];
logic [F64_REM_W-1:0] mask_csa_pos_1 [2-1:0];
logic [F64_REM_W-1:0] mask_csa_pos_2 [2-1:0];

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

logic [F64_REM_W-1:0] f_r_s_for_csa_0 [2-1:0];
logic [F64_REM_W-1:0] f_r_c_for_csa_0 [2-1:0];

logic [F32_REM_W-1:0] f_r_s_for_csa_1 [2-1:0];
logic [F32_REM_W-1:0] f_r_c_for_csa_1 [2-1:0];

logic [F16_REM_W-1:0] f_r_s_for_csa_2 [2-1:0];
logic [F16_REM_W-1:0] f_r_c_for_csa_2 [2-1:0];

logic [F16_REM_W-1:0] f_r_s_for_csa_3 [2-1:0];
logic [F16_REM_W-1:0] f_r_c_for_csa_3 [2-1:0];

logic [F64_REM_W-1:0] nxt_f_r_s_0 [2-1:0];
logic [F64_REM_W-1:0] nxt_f_r_c_0 [2-1:0];

logic [F32_REM_W-1:0] nxt_f_r_s_1 [2-1:0];
logic [F32_REM_W-1:0] nxt_f_r_c_1 [2-1:0];

logic [F16_REM_W-1:0] nxt_f_r_s_2 [2-1:0];
logic [F16_REM_W-1:0] nxt_f_r_c_2 [2-1:0];

logic [F16_REM_W-1:0] nxt_f_r_s_3 [2-1:0];
logic [F16_REM_W-1:0] nxt_f_r_c_3 [2-1:0];

logic [MERGED_REM_W-1:0] nxt_f_r_s_merged [2-1:0];
logic [MERGED_REM_W-1:0] nxt_f_r_c_merged [2-1:0];
logic [MERGED_REM_W-1:0] nxt_f_r_c_merged_pre [2-1:0];

logic [MERGED_REM_W-1:0] f_r_s_for_csa_merged [2-1:0];
logic [MERGED_REM_W-1:0] f_r_c_for_csa_merged [2-1:0];

logic [F64_REM_W-1:0] nxt_f_r_s_spec_s0_0 [5-1:0];
logic [F64_REM_W-1:0] nxt_f_r_c_spec_s0_0 [5-1:0];
logic [F64_REM_W-1:0] nxt_f_r_c_pre_spec_s0_0 [5-1:0];
logic [F64_REM_W-1:0] nxt_f_r_s_spec_s1_0 [5-1:0];
logic [F64_REM_W-1:0] nxt_f_r_c_spec_s1_0 [5-1:0];
logic [F64_REM_W-1:0] nxt_f_r_c_pre_spec_s1_0 [5-1:0];

logic [F32_REM_W-1:0] nxt_f_r_s_spec_s0_1 [5-1:0];
logic [F32_REM_W-1:0] nxt_f_r_c_spec_s0_1 [5-1:0];
logic [F32_REM_W-1:0] nxt_f_r_c_pre_spec_s0_1 [5-1:0];
logic [F32_REM_W-1:0] nxt_f_r_s_spec_s1_1 [5-1:0];
logic [F32_REM_W-1:0] nxt_f_r_c_spec_s1_1 [5-1:0];
logic [F32_REM_W-1:0] nxt_f_r_c_pre_spec_s1_1 [5-1:0];

logic [F16_REM_W-1:0] nxt_f_r_s_spec_s0_2 [5-1:0];
logic [F16_REM_W-1:0] nxt_f_r_c_spec_s0_2 [5-1:0];
logic [F16_REM_W-1:0] nxt_f_r_c_pre_spec_s0_2 [5-1:0];
logic [F16_REM_W-1:0] nxt_f_r_s_spec_s1_2 [5-1:0];
logic [F16_REM_W-1:0] nxt_f_r_c_spec_s1_2 [5-1:0];
logic [F16_REM_W-1:0] nxt_f_r_c_pre_spec_s1_2 [5-1:0];

logic [F16_REM_W-1:0] nxt_f_r_s_spec_s0_3 [5-1:0];
logic [F16_REM_W-1:0] nxt_f_r_c_spec_s0_3 [5-1:0];
logic [F16_REM_W-1:0] nxt_f_r_c_pre_spec_s0_3 [5-1:0];
logic [F16_REM_W-1:0] nxt_f_r_s_spec_s1_3 [5-1:0];
logic [F16_REM_W-1:0] nxt_f_r_c_spec_s1_3 [5-1:0];
logic [F16_REM_W-1:0] nxt_f_r_c_pre_spec_s1_3 [5-1:0];

logic [F64_REM_W-1:0] sqrt_csa_val_neg_2_0 [2-1:0];
logic [F32_REM_W-1:0] sqrt_csa_val_neg_2_1 [2-1:0];
logic [F16_REM_W-1:0] sqrt_csa_val_neg_2_2 [2-1:0];
logic [F16_REM_W-1:0] sqrt_csa_val_neg_2_3 [2-1:0];

logic [F64_REM_W-1:0] sqrt_csa_val_neg_1_0 [2-1:0];
logic [F32_REM_W-1:0] sqrt_csa_val_neg_1_1 [2-1:0];
logic [F16_REM_W-1:0] sqrt_csa_val_neg_1_2 [2-1:0];
logic [F16_REM_W-1:0] sqrt_csa_val_neg_1_3 [2-1:0];

logic [F64_REM_W-1:0] sqrt_csa_val_pos_1_0 [2-1:0];
logic [F32_REM_W-1:0] sqrt_csa_val_pos_1_1 [2-1:0];
logic [F16_REM_W-1:0] sqrt_csa_val_pos_1_2 [2-1:0];
logic [F16_REM_W-1:0] sqrt_csa_val_pos_1_3 [2-1:0];

logic [F64_REM_W-1:0] sqrt_csa_val_pos_2_0 [2-1:0];
logic [F32_REM_W-1:0] sqrt_csa_val_pos_2_1 [2-1:0];
logic [F16_REM_W-1:0] sqrt_csa_val_pos_2_2 [2-1:0];
logic [F16_REM_W-1:0] sqrt_csa_val_pos_2_3 [2-1:0];

logic [F64_REM_W-1:0] sqrt_csa_val_0 [2-1:0];
logic [F32_REM_W-1:0] sqrt_csa_val_1 [2-1:0];
logic [F16_REM_W-1:0] sqrt_csa_val_2 [2-1:0];
logic [F16_REM_W-1:0] sqrt_csa_val_3 [2-1:0];

logic [MERGED_REM_W-1:0] sqrt_csa_val_merged [2-1:0];

logic a0_spec_s0_0 [5-1:0];
logic a0_spec_s0_1 [5-1:0];
logic a0_spec_s0_2 [5-1:0];
logic a0_spec_s0_3 [5-1:0];
logic a0_spec_s1_0 [5-1:0];
logic a0_spec_s1_1 [5-1:0];
logic a0_spec_s1_2 [5-1:0];
logic a0_spec_s1_3 [5-1:0];

logic a2_spec_s0_0 [5-1:0];
logic a2_spec_s0_1 [5-1:0];
logic a2_spec_s0_2 [5-1:0];
logic a2_spec_s0_3 [5-1:0];
logic a2_spec_s1_0 [5-1:0];
logic a2_spec_s1_1 [5-1:0];
logic a2_spec_s1_2 [5-1:0];
logic a2_spec_s1_3 [5-1:0];

logic a3_spec_s0_0 [5-1:0];
logic a3_spec_s0_1 [5-1:0];
logic a3_spec_s0_2 [5-1:0];
logic a3_spec_s0_3 [5-1:0];
logic a3_spec_s1_0 [5-1:0];
logic a3_spec_s1_1 [5-1:0];
logic a3_spec_s1_2 [5-1:0];
logic a3_spec_s1_3 [5-1:0];

logic a4_spec_s0_0 [5-1:0];
logic a4_spec_s0_1 [5-1:0];
logic a4_spec_s0_2 [5-1:0];
logic a4_spec_s0_3 [5-1:0];
logic a4_spec_s1_0 [5-1:0];
logic a4_spec_s1_1 [5-1:0];
logic a4_spec_s1_2 [5-1:0];
logic a4_spec_s1_3 [5-1:0];


logic [7-1:0] m_neg_1_0 [2-1:0];
logic [7-1:0] m_neg_1_1 [2-1:0];
logic [7-1:0] m_neg_1_2 [2-1:0];
logic [7-1:0] m_neg_1_3 [2-1:0];

logic [7-1:0] m_neg_0_0 [2-1:0];
logic [7-1:0] m_neg_0_1 [2-1:0];
logic [7-1:0] m_neg_0_2 [2-1:0];
logic [7-1:0] m_neg_0_3 [2-1:0];

logic [7-1:0] m_pos_1_0 [2-1:0];
logic [7-1:0] m_pos_1_1 [2-1:0];
logic [7-1:0] m_pos_1_2 [2-1:0];
logic [7-1:0] m_pos_1_3 [2-1:0];

logic [7-1:0] m_pos_2_0 [2-1:0];
logic [7-1:0] m_pos_2_1 [2-1:0];
logic [7-1:0] m_pos_2_2 [2-1:0];
logic [7-1:0] m_pos_2_3 [2-1:0];

logic [7-1:0] m_neg_1_spec_s0_0 [5-1:0];
logic [7-1:0] m_neg_1_spec_s0_1 [5-1:0];
logic [7-1:0] m_neg_1_spec_s0_2 [5-1:0];
logic [7-1:0] m_neg_1_spec_s0_3 [5-1:0];
logic [7-1:0] m_neg_1_spec_s1_0 [5-1:0];
logic [7-1:0] m_neg_1_spec_s1_1 [5-1:0];
logic [7-1:0] m_neg_1_spec_s1_2 [5-1:0];
logic [7-1:0] m_neg_1_spec_s1_3 [5-1:0];

logic [7-1:0] m_neg_0_spec_s0_0 [5-1:0];
logic [7-1:0] m_neg_0_spec_s0_1 [5-1:0];
logic [7-1:0] m_neg_0_spec_s0_2 [5-1:0];
logic [7-1:0] m_neg_0_spec_s0_3 [5-1:0];
logic [7-1:0] m_neg_0_spec_s1_0 [5-1:0];
logic [7-1:0] m_neg_0_spec_s1_1 [5-1:0];
logic [7-1:0] m_neg_0_spec_s1_2 [5-1:0];
logic [7-1:0] m_neg_0_spec_s1_3 [5-1:0];

logic [7-1:0] m_pos_1_spec_s0_0 [5-1:0];
logic [7-1:0] m_pos_1_spec_s0_1 [5-1:0];
logic [7-1:0] m_pos_1_spec_s0_2 [5-1:0];
logic [7-1:0] m_pos_1_spec_s0_3 [5-1:0];
logic [7-1:0] m_pos_1_spec_s1_0 [5-1:0];
logic [7-1:0] m_pos_1_spec_s1_1 [5-1:0];
logic [7-1:0] m_pos_1_spec_s1_2 [5-1:0];
logic [7-1:0] m_pos_1_spec_s1_3 [5-1:0];

logic [7-1:0] m_pos_2_spec_s0_0 [5-1:0];
logic [7-1:0] m_pos_2_spec_s0_1 [5-1:0];
logic [7-1:0] m_pos_2_spec_s0_2 [5-1:0];
logic [7-1:0] m_pos_2_spec_s0_3 [5-1:0];
logic [7-1:0] m_pos_2_spec_s1_0 [5-1:0];
logic [7-1:0] m_pos_2_spec_s1_1 [5-1:0];
logic [7-1:0] m_pos_2_spec_s1_2 [5-1:0];
logic [7-1:0] m_pos_2_spec_s1_3 [5-1:0];

logic [7-1:0] m_neg_1_to_nxt_cycle_0;
logic [7-1:0] m_neg_1_to_nxt_cycle_1;
logic [7-1:0] m_neg_1_to_nxt_cycle_2;
logic [7-1:0] m_neg_1_to_nxt_cycle_3;

logic [7-1:0] m_neg_0_to_nxt_cycle_0;
logic [7-1:0] m_neg_0_to_nxt_cycle_1;
logic [7-1:0] m_neg_0_to_nxt_cycle_2;
logic [7-1:0] m_neg_0_to_nxt_cycle_3;

logic [7-1:0] m_pos_1_to_nxt_cycle_0;
logic [7-1:0] m_pos_1_to_nxt_cycle_1;
logic [7-1:0] m_pos_1_to_nxt_cycle_2;
logic [7-1:0] m_pos_1_to_nxt_cycle_3;

logic [7-1:0] m_pos_2_to_nxt_cycle_0;
logic [7-1:0] m_pos_2_to_nxt_cycle_1;
logic [7-1:0] m_pos_2_to_nxt_cycle_2;
logic [7-1:0] m_pos_2_to_nxt_cycle_3;

logic [9-1:0] adder_9b_for_nxt_cycle_s0_qds_spec_0 [5-1:0];
logic [9-1:0] adder_9b_for_nxt_cycle_s0_qds_spec_1 [5-1:0];
logic [9-1:0] adder_9b_for_nxt_cycle_s0_qds_spec_2 [5-1:0];
logic [9-1:0] adder_9b_for_nxt_cycle_s0_qds_spec_3 [5-1:0];

logic [10-1:0] adder_10b_for_nxt_cycle_s1_qds_spec_0 [5-1:0];
logic [10-1:0] adder_10b_for_nxt_cycle_s1_qds_spec_1 [5-1:0];
logic [10-1:0] adder_10b_for_nxt_cycle_s1_qds_spec_2 [5-1:0];
logic [10-1:0] adder_10b_for_nxt_cycle_s1_qds_spec_3 [5-1:0];

logic [9-1:0] adder_9b_for_s1_qds_spec_0 [5-1:0];
logic [9-1:0] adder_9b_for_s1_qds_spec_1 [5-1:0];
logic [9-1:0] adder_9b_for_s1_qds_spec_2 [5-1:0];
logic [9-1:0] adder_9b_for_s1_qds_spec_3 [5-1:0];

logic [7-1:0] adder_7b_res_for_s1_qds_0;
logic [7-1:0] adder_7b_res_for_s1_qds_1;
logic [7-1:0] adder_7b_res_for_s1_qds_2;
logic [7-1:0] adder_7b_res_for_s1_qds_3;


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
assign mask_rt_ext[0] = mask_csa_ext[0][0 +: F64_FULL_RT_W];

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
assign m_neg_1_0[0] = {2'b0, m_neg_1_for_nxt_cycle_s0_qds_0_i};
assign m_neg_0_0[0] = {3'b0, m_neg_0_for_nxt_cycle_s0_qds_0_i};
assign m_pos_1_0[0] = {4'b1111, m_pos_1_for_nxt_cycle_s0_qds_0_i};
assign m_pos_2_0[0] = {2'b11, m_pos_2_for_nxt_cycle_s0_qds_0_i, 1'b0};
r4_qds
u_r4_qds_s0_0 (
	.rem_i(nr_f_r_7b_for_nxt_cycle_s0_qds_0_i),
	.m_neg_1_i(m_neg_1_0[0]),
	.m_neg_0_i(m_neg_0_0[0]),
	.m_pos_1_i(m_pos_1_0[0]),
	.m_pos_2_i(m_pos_2_0[0]),
	.rt_dig_o(nxt_rt_dig_0[0])
);

assign m_neg_1_1[0] = {2'b0, m_neg_1_for_nxt_cycle_s0_qds_1_i};
assign m_neg_0_1[0] = {3'b0, m_neg_0_for_nxt_cycle_s0_qds_1_i};
assign m_pos_1_1[0] = {4'b1111, m_pos_1_for_nxt_cycle_s0_qds_1_i};
assign m_pos_2_1[0] = {2'b11, m_pos_2_for_nxt_cycle_s0_qds_1_i, 1'b0};
r4_qds
u_r4_qds_s0_1 (
	.rem_i(nr_f_r_7b_for_nxt_cycle_s0_qds_1_i),
	.m_neg_1_i(m_neg_1_1[0]),
	.m_neg_0_i(m_neg_0_1[0]),
	.m_pos_1_i(m_pos_1_1[0]),
	.m_pos_2_i(m_pos_2_1[0]),
	.rt_dig_o(nxt_rt_dig_1[0])
);

assign m_neg_1_2[0] = {2'b0, m_neg_1_for_nxt_cycle_s0_qds_2_i};
assign m_neg_0_2[0] = {3'b0, m_neg_0_for_nxt_cycle_s0_qds_2_i};
assign m_pos_1_2[0] = {4'b1111, m_pos_1_for_nxt_cycle_s0_qds_2_i};
assign m_pos_2_2[0] = {2'b11, m_pos_2_for_nxt_cycle_s0_qds_2_i, 1'b0};
r4_qds
u_r4_qds_s0_2 (
	.rem_i(nr_f_r_7b_for_nxt_cycle_s0_qds_2_i),
	.m_neg_1_i(m_neg_1_2[0]),
	.m_neg_0_i(m_neg_0_2[0]),
	.m_pos_1_i(m_pos_1_2[0]),
	.m_pos_2_i(m_pos_2_2[0]),
	.rt_dig_o(nxt_rt_dig_2[0])
);

assign m_neg_1_3[0] = {2'b0, m_neg_1_for_nxt_cycle_s0_qds_3_i};
assign m_neg_0_3[0] = {3'b0, m_neg_0_for_nxt_cycle_s0_qds_3_i};
assign m_pos_1_3[0] = {4'b1111, m_pos_1_for_nxt_cycle_s0_qds_3_i};
assign m_pos_2_3[0] = {2'b11, m_pos_2_for_nxt_cycle_s0_qds_3_i, 1'b0};
r4_qds
u_r4_qds_s0_3 (
	.rem_i(nr_f_r_7b_for_nxt_cycle_s0_qds_3_i),
	.m_neg_1_i(m_neg_1_3[0]),
	.m_neg_0_i(m_neg_0_3[0]),
	.m_pos_1_i(m_pos_1_3[0]),
	.m_pos_2_i(m_pos_2_3[0]),
	.rt_dig_o(nxt_rt_dig_3[0])
);

// ================================================================================================================================================
// stage[0].csa + full-adder
// ================================================================================================================================================

// MSB.idx is 55:
// rt_q[55: 2]: For f64_0
// rt_q[55:30]: For f32_0
// rt_q[55:42]: For f16_0
// MSB.idx is 41:
// rt_q[41:28]: For f16_2
// MSB.idx is 27:
// rt_q[27: 2]: For f32_1
// rt_q[27:14]: For f16_1
// MSB.idx is 13:
// rt_q[13: 0]: For f16_3

// MSB.idx is 52:
// rt_m1_q[52: 0]: For f64_0
// rt_m1_q[52:28]: For f32_0
// rt_m1_q[52:40]: For f16_0
// MSB.idx is 39:
// rt_m1_q[39:27]: For f16_2
// MSB.idx is 26:
// rt_m1_q[26: 2]: For f32_1
// rt_m1_q[26:14]: For f16_1
// MSB.idx is 13:
// rt_m1_q[13: 1]: For f16_3

assign rt_0 = {~rt_i[55], rt_i[55:2]};
assign rt_m1_0 = {1'b0, 1'b1, rt_m1_i[52:0]};

assign rt_1 = {~rt_i[27], rt_i[27:2]};
assign rt_m1_1 = {1'b0, 1'b1, rt_m1_i[26:2]};

assign rt_2 = {~rt_i[41], rt_i[41:28]};
assign rt_m1_2 = {1'b0, 1'b1, rt_m1_i[39:27]};

assign rt_3 = {~rt_i[13], rt_i[13:0]};
assign rt_m1_3 = {1'b0, 1'b1, rt_m1_i[13:1]};

// Clear the lower part of rt/rt_m1 when necessary -> Make sure the lower part will not influence the higher part 
// when we are doing "<< 1" and "<< 2" operation to generate "sqrt_csa_val_xxx"
// Only "*_0" and "*_1" will need this operation.
assign rt_for_csa_0[0] = {
	rt_0[54:40],
	fp_fmt_i[0] ? 2'b0 : rt_0[39:38],
	rt_0[37:28],
	fp_fmt_i[1] ? 2'b0 : rt_0[27:26],
	rt_0[25:0]
};
assign rt_m1_for_csa_0[0] = {
	rt_m1_0[54:40],
	fp_fmt_i[0] ? 2'b0 : rt_m1_0[39:38],
	rt_m1_0[37:28],
	fp_fmt_i[1] ? 2'b0 : rt_m1_0[27:26],
	rt_m1_0[25:0]
};

assign rt_for_csa_1[0] = {
	rt_1[26:12],
	fp_fmt_i[0] ? 2'b0 : rt_1[11:10],
	rt_1[9:0]
};
assign rt_m1_for_csa_1[0] = {
	rt_m1_1[26:12],
	fp_fmt_i[0] ? 2'b0 : rt_m1_1[11:10],
	rt_m1_1[9:0]
};

// ================================================================================================================================================
// stage[0].csa for *_0
// ================================================================================================================================================
assign sqrt_csa_val_neg_2_0[0] = ({1'b0, rt_m1_for_csa_0[0]} << 2) | mask_csa_neg_2[0];
assign sqrt_csa_val_neg_1_0[0] = ({1'b0, rt_m1_for_csa_0[0]} << 1) | mask_csa_neg_1[0];
assign sqrt_csa_val_pos_1_0[0] = ~(({1'b0, rt_for_csa_0[0]} << 1) | mask_csa_pos_1[0]);
assign sqrt_csa_val_pos_2_0[0] = ~(({1'b0, rt_for_csa_0[0]} << 2) | mask_csa_pos_2[0]);

assign sqrt_csa_val_0[0] = 
  ({(F64_REM_W){nxt_rt_dig_0[0][4]}} & sqrt_csa_val_neg_2_0[0])
| ({(F64_REM_W){nxt_rt_dig_0[0][3]}} & sqrt_csa_val_neg_1_0[0])
| ({(F64_REM_W){nxt_rt_dig_0[0][1]}} & sqrt_csa_val_pos_1_0[0])
| ({(F64_REM_W){nxt_rt_dig_0[0][0]}} & sqrt_csa_val_pos_2_0[0]);

// "f_r_s/f_r_c * 4" is used for csa
// f64: {f_r_s/f_r_c[61:8], 2'b00} should be used for csa
// f32: {f_r_s/f_r_c[61:36], 2'b00, f_r_s/f_r_c[33:8], 2'b00} should be used for csa, csa_res[27:0] will be ignored.
// f16: {f_r_s/f_r_c[61:48], 2'b00, f_r_s/f_r_c[45:8], 2'b00} should be used for csa, csa_res[39:0] will be ignored.
assign f_r_s_for_csa_0[0] = {
	f_r_s_i[61:48],
	fp_fmt_i[0] ? 2'b00 : f_r_s_i[47:46],
	f_r_s_i[45:36],
	fp_fmt_i[1] ? 2'b00 : f_r_s_i[35:34],
	f_r_s_i[33:8],
	2'b00
};
assign f_r_c_for_csa_0[0] = {
	f_r_c_i[61:48],
	fp_fmt_i[0] ? 2'b00 : f_r_c_i[47:46],
	f_r_c_i[45:36],
	fp_fmt_i[1] ? 2'b00 : f_r_c_i[35:34],
	f_r_c_i[33:8],
	2'b00
};

// Here we assume s0.qds will generate rt_dig = -2
assign nxt_f_r_s_spec_s0_0[4] = 
  f_r_s_for_csa_0[0]
^ f_r_c_for_csa_0[0]
^ sqrt_csa_val_neg_2_0[0];
assign nxt_f_r_c_pre_spec_s0_0[4] = {
	  (f_r_s_for_csa_0[0][(F64_REM_W-1)-1:0] & f_r_c_for_csa_0[0][(F64_REM_W-1)-1:0])
	| (f_r_s_for_csa_0[0][(F64_REM_W-1)-1:0] & sqrt_csa_val_neg_2_0[0][(F64_REM_W-1)-1:0])
	| (f_r_c_for_csa_0[0][(F64_REM_W-1)-1:0] & sqrt_csa_val_neg_2_0[0][(F64_REM_W-1)-1:0]),
	1'b0
};
assign nxt_f_r_c_spec_s0_0[4] = {
	nxt_f_r_c_pre_spec_s0_0[4][55:41],
	fp_fmt_i[0] ? 1'b0 : nxt_f_r_c_pre_spec_s0_0[4][40],
	nxt_f_r_c_pre_spec_s0_0[4][39:29],
	fp_fmt_i[1] ? 1'b0 : nxt_f_r_c_pre_spec_s0_0[4][28],
	nxt_f_r_c_pre_spec_s0_0[4][27:0]
};

// Here we assume s0.qds will generate rt_dig = -1
assign nxt_f_r_s_spec_s0_0[3] = 
  f_r_s_for_csa_0[0]
^ f_r_c_for_csa_0[0]
^ sqrt_csa_val_neg_1_0[0];
assign nxt_f_r_c_pre_spec_s0_0[3] = {
	  (f_r_s_for_csa_0[0][(F64_REM_W-1)-1:0] & f_r_c_for_csa_0[0][(F64_REM_W-1)-1:0])
	| (f_r_s_for_csa_0[0][(F64_REM_W-1)-1:0] & sqrt_csa_val_neg_1_0[0][(F64_REM_W-1)-1:0])
	| (f_r_c_for_csa_0[0][(F64_REM_W-1)-1:0] & sqrt_csa_val_neg_1_0[0][(F64_REM_W-1)-1:0]),
	1'b0
};
assign nxt_f_r_c_spec_s0_0[3] = {
	nxt_f_r_c_pre_spec_s0_0[3][55:41],
	fp_fmt_i[0] ? 1'b0 : nxt_f_r_c_pre_spec_s0_0[3][40],
	nxt_f_r_c_pre_spec_s0_0[3][39:29],
	fp_fmt_i[1] ? 1'b0 : nxt_f_r_c_pre_spec_s0_0[3][28],
	nxt_f_r_c_pre_spec_s0_0[3][27:0]
};

// Here we assume s0.qds will generate rt_dig = 0
assign nxt_f_r_s_spec_s0_0[2] = f_r_s_for_csa_0[0];
assign nxt_f_r_c_pre_spec_s0_0[2] = f_r_c_for_csa_0[0];
assign nxt_f_r_c_spec_s0_0[2] = nxt_f_r_c_pre_spec_s0_0[2];

// Here we assume s0.qds will generate rt_dig = +1
assign nxt_f_r_s_spec_s0_0[1] = 
  f_r_s_for_csa_0[0]
^ f_r_c_for_csa_0[0]
^ sqrt_csa_val_pos_1_0[0];
assign nxt_f_r_c_pre_spec_s0_0[1] = {
	  (f_r_s_for_csa_0[0][(F64_REM_W-1)-1:0] & f_r_c_for_csa_0[0][(F64_REM_W-1)-1:0])
	| (f_r_s_for_csa_0[0][(F64_REM_W-1)-1:0] & sqrt_csa_val_pos_1_0[0][(F64_REM_W-1)-1:0])
	| (f_r_c_for_csa_0[0][(F64_REM_W-1)-1:0] & sqrt_csa_val_pos_1_0[0][(F64_REM_W-1)-1:0]),
	1'b1
};
assign nxt_f_r_c_spec_s0_0[1] = {
	nxt_f_r_c_pre_spec_s0_0[1][55:41],
	fp_fmt_i[0] ? 1'b1 : nxt_f_r_c_pre_spec_s0_0[1][40],
	nxt_f_r_c_pre_spec_s0_0[1][39:29],
	fp_fmt_i[1] ? 1'b1 : nxt_f_r_c_pre_spec_s0_0[1][28],
	nxt_f_r_c_pre_spec_s0_0[1][27:0]
};

// Here we assume s0.qds will generate rt_dig = +2
assign nxt_f_r_s_spec_s0_0[0] = 
  f_r_s_for_csa_0[0]
^ f_r_c_for_csa_0[0]
^ sqrt_csa_val_pos_2_0[0];
assign nxt_f_r_c_pre_spec_s0_0[0] = {
	  (f_r_s_for_csa_0[0][(F64_REM_W-1)-1:0] & f_r_c_for_csa_0[0][(F64_REM_W-1)-1:0])
	| (f_r_s_for_csa_0[0][(F64_REM_W-1)-1:0] & sqrt_csa_val_pos_2_0[0][(F64_REM_W-1)-1:0])
	| (f_r_c_for_csa_0[0][(F64_REM_W-1)-1:0] & sqrt_csa_val_pos_2_0[0][(F64_REM_W-1)-1:0]),
	1'b1
};
assign nxt_f_r_c_spec_s0_0[0] = {
	nxt_f_r_c_pre_spec_s0_0[0][55:41],
	fp_fmt_i[0] ? 1'b1 : nxt_f_r_c_pre_spec_s0_0[0][40],
	nxt_f_r_c_pre_spec_s0_0[0][39:29],
	fp_fmt_i[1] ? 1'b1 : nxt_f_r_c_pre_spec_s0_0[0][28],
	nxt_f_r_c_pre_spec_s0_0[0][27:0]
};

// ================================================================================================================================================
// stage[0].csa for *_1
// ================================================================================================================================================
assign sqrt_csa_val_neg_2_1[0] = ({1'b0, rt_m1_for_csa_1[0]} << 2) | mask_csa_neg_2[0][F64_REM_W-1 -: F32_REM_W];
assign sqrt_csa_val_neg_1_1[0] = ({1'b0, rt_m1_for_csa_1[0]} << 1) | mask_csa_neg_1[0][F64_REM_W-1 -: F32_REM_W];
assign sqrt_csa_val_pos_1_1[0] = ~(({1'b0, rt_for_csa_1[0]} << 1) | mask_csa_pos_1[0][F64_REM_W-1 -: F32_REM_W]);
assign sqrt_csa_val_pos_2_1[0] = ~(({1'b0, rt_for_csa_1[0]} << 2) | mask_csa_pos_2[0][F64_REM_W-1 -: F32_REM_W]);

assign sqrt_csa_val_1[0] = 
  ({(F32_REM_W){nxt_rt_dig_1[0][4]}} & sqrt_csa_val_neg_2_1[0])
| ({(F32_REM_W){nxt_rt_dig_1[0][3]}} & sqrt_csa_val_neg_1_1[0])
| ({(F32_REM_W){nxt_rt_dig_1[0][1]}} & sqrt_csa_val_pos_1_1[0])
| ({(F32_REM_W){nxt_rt_dig_1[0][0]}} & sqrt_csa_val_pos_2_1[0]);

// f32: {f_r_s/f_r_c[29:4], 2'b00} should be used for csa
// f16: {f_r_s/f_r_c[29:16], 2'b00, f_r_s/f_r_c[13:4], 2'b00} should be used for csa, csa_res[11:0] will be ignored.
assign f_r_s_for_csa_1[0] = {
	f_r_s_i[29:16],
	fp_fmt_i[0] ? 2'b00 : f_r_s_i[15:14],
	f_r_s_i[13:4],
	2'b00
};
assign f_r_c_for_csa_1[0] = {
	f_r_c_i[29:16],
	fp_fmt_i[0] ? 2'b00 : f_r_c_i[15:14],
	f_r_c_i[13:4],
	2'b00
};

// Here we assume s0.qds will generate rt_dig = -2
assign nxt_f_r_s_spec_s0_1[4] = 
  f_r_s_for_csa_1[0]
^ f_r_c_for_csa_1[0]
^ sqrt_csa_val_neg_2_1[0];
assign nxt_f_r_c_pre_spec_s0_1[4] = {
	  (f_r_s_for_csa_1[0][(F32_REM_W-1)-1:0] & f_r_c_for_csa_1[0][(F32_REM_W-1)-1:0])
	| (f_r_s_for_csa_1[0][(F32_REM_W-1)-1:0] & sqrt_csa_val_neg_2_1[0][(F32_REM_W-1)-1:0])
	| (f_r_c_for_csa_1[0][(F32_REM_W-1)-1:0] & sqrt_csa_val_neg_2_1[0][(F32_REM_W-1)-1:0]),
	1'b0
};
assign nxt_f_r_c_spec_s0_1[4] = {
	nxt_f_r_c_pre_spec_s0_1[4][27:13],
	fp_fmt_i[0] ? 1'b0 : nxt_f_r_c_pre_spec_s0_1[4][12],
	nxt_f_r_c_pre_spec_s0_1[4][11:0]
};

// Here we assume s0.qds will generate rt_dig = -1
assign nxt_f_r_s_spec_s0_1[3] = 
  f_r_s_for_csa_1[0]
^ f_r_c_for_csa_1[0]
^ sqrt_csa_val_neg_1_1[0];
assign nxt_f_r_c_pre_spec_s0_1[3] = {
	  (f_r_s_for_csa_1[0][(F32_REM_W-1)-1:0] & f_r_c_for_csa_1[0][(F32_REM_W-1)-1:0])
	| (f_r_s_for_csa_1[0][(F32_REM_W-1)-1:0] & sqrt_csa_val_neg_1_1[0][(F32_REM_W-1)-1:0])
	| (f_r_c_for_csa_1[0][(F32_REM_W-1)-1:0] & sqrt_csa_val_neg_1_1[0][(F32_REM_W-1)-1:0]),
	1'b0
};
assign nxt_f_r_c_spec_s0_1[3] = {
	nxt_f_r_c_pre_spec_s0_1[3][27:13],
	fp_fmt_i[0] ? 1'b0 : nxt_f_r_c_pre_spec_s0_1[3][12],
	nxt_f_r_c_pre_spec_s0_1[3][11:0]
};

// Here we assume s0.qds will generate rt_dig = 0
assign nxt_f_r_s_spec_s0_1[2] = f_r_s_for_csa_1[0];
assign nxt_f_r_c_pre_spec_s0_1[2] = f_r_c_for_csa_1[0];
assign nxt_f_r_c_spec_s0_1[2] = nxt_f_r_c_pre_spec_s0_1[2];

// Here we assume s0.qds will generate rt_dig = +1
assign nxt_f_r_s_spec_s0_1[1] = 
  f_r_s_for_csa_1[0]
^ f_r_c_for_csa_1[0]
^ sqrt_csa_val_pos_1_1[0];
assign nxt_f_r_c_pre_spec_s0_1[1] = {
	  (f_r_s_for_csa_1[0][(F32_REM_W-1)-1:0] & f_r_c_for_csa_1[0][(F32_REM_W-1)-1:0])
	| (f_r_s_for_csa_1[0][(F32_REM_W-1)-1:0] & sqrt_csa_val_pos_1_1[0][(F32_REM_W-1)-1:0])
	| (f_r_c_for_csa_1[0][(F32_REM_W-1)-1:0] & sqrt_csa_val_pos_1_1[0][(F32_REM_W-1)-1:0]),
	1'b1
};
assign nxt_f_r_c_spec_s0_1[1] = {
	nxt_f_r_c_pre_spec_s0_1[1][27:13],
	fp_fmt_i[0] ? 1'b1 : nxt_f_r_c_pre_spec_s0_1[1][12],
	nxt_f_r_c_pre_spec_s0_1[1][11:0]
};

// Here we assume s0.qds will generate rt_dig = +2
assign nxt_f_r_s_spec_s0_1[0] = 
  f_r_s_for_csa_1[0]
^ f_r_c_for_csa_1[0]
^ sqrt_csa_val_pos_2_1[0];
assign nxt_f_r_c_pre_spec_s0_1[0] = {
	  (f_r_s_for_csa_1[0][(F32_REM_W-1)-1:0] & f_r_c_for_csa_1[0][(F32_REM_W-1)-1:0])
	| (f_r_s_for_csa_1[0][(F32_REM_W-1)-1:0] & sqrt_csa_val_pos_2_1[0][(F32_REM_W-1)-1:0])
	| (f_r_c_for_csa_1[0][(F32_REM_W-1)-1:0] & sqrt_csa_val_pos_2_1[0][(F32_REM_W-1)-1:0]),
	1'b1
};
assign nxt_f_r_c_spec_s0_1[0] = {
	nxt_f_r_c_pre_spec_s0_1[0][27:13],
	fp_fmt_i[0] ? 1'b1 : nxt_f_r_c_pre_spec_s0_1[0][12],
	nxt_f_r_c_pre_spec_s0_1[0][11:0]
};

// ================================================================================================================================================
// stage[0].csa for *_2
// ================================================================================================================================================
assign sqrt_csa_val_neg_2_2[0] = ({1'b0, rt_m1_2} << 2) | mask_csa_neg_2[0][F64_REM_W-1 -: F16_REM_W];
assign sqrt_csa_val_neg_1_2[0] = ({1'b0, rt_m1_2} << 1) | mask_csa_neg_1[0][F64_REM_W-1 -: F16_REM_W];
assign sqrt_csa_val_pos_1_2[0] = ~(({1'b0, rt_2} << 1) | mask_csa_pos_1[0][F64_REM_W-1 -: F16_REM_W]);
assign sqrt_csa_val_pos_2_2[0] = ~(({1'b0, rt_2} << 2) | mask_csa_pos_2[0][F64_REM_W-1 -: F16_REM_W]);

assign sqrt_csa_val_2[0] = 
  ({(F16_REM_W){nxt_rt_dig_2[0][4]}} & sqrt_csa_val_neg_2_2[0])
| ({(F16_REM_W){nxt_rt_dig_2[0][3]}} & sqrt_csa_val_neg_1_2[0])
| ({(F16_REM_W){nxt_rt_dig_2[0][1]}} & sqrt_csa_val_pos_1_2[0])
| ({(F16_REM_W){nxt_rt_dig_2[0][0]}} & sqrt_csa_val_pos_2_2[0]);

assign f_r_s_for_csa_2[0] = {f_r_s_i[45:32], 2'b00};
assign f_r_c_for_csa_2[0] = {f_r_c_i[45:32], 2'b00};

// Here we assume s0.qds will generate rt_dig = -2
assign nxt_f_r_s_spec_s0_2[4] = 
  f_r_s_for_csa_2[0]
^ f_r_c_for_csa_2[0]
^ sqrt_csa_val_neg_2_2[0];
assign nxt_f_r_c_pre_spec_s0_2[4] = {
	  (f_r_s_for_csa_2[0][(F16_REM_W-1)-1:0] & f_r_c_for_csa_2[0][(F16_REM_W-1)-1:0])
	| (f_r_s_for_csa_2[0][(F16_REM_W-1)-1:0] & sqrt_csa_val_neg_2_2[0][(F16_REM_W-1)-1:0])
	| (f_r_c_for_csa_2[0][(F16_REM_W-1)-1:0] & sqrt_csa_val_neg_2_2[0][(F16_REM_W-1)-1:0]),
	1'b0
};
assign nxt_f_r_c_spec_s0_2[4] = nxt_f_r_c_pre_spec_s0_2[4];

// Here we assume s0.qds will generate rt_dig = -1
assign nxt_f_r_s_spec_s0_2[3] = 
  f_r_s_for_csa_2[0]
^ f_r_c_for_csa_2[0]
^ sqrt_csa_val_neg_1_2[0];
assign nxt_f_r_c_pre_spec_s0_2[3] = {
	  (f_r_s_for_csa_2[0][(F16_REM_W-1)-1:0] & f_r_c_for_csa_2[0][(F16_REM_W-1)-1:0])
	| (f_r_s_for_csa_2[0][(F16_REM_W-1)-1:0] & sqrt_csa_val_neg_1_2[0][(F16_REM_W-1)-1:0])
	| (f_r_c_for_csa_2[0][(F16_REM_W-1)-1:0] & sqrt_csa_val_neg_1_2[0][(F16_REM_W-1)-1:0]),
	1'b0
};
assign nxt_f_r_c_spec_s0_2[3] = nxt_f_r_c_pre_spec_s0_2[3];

// Here we assume s0.qds will generate rt_dig = 0
assign nxt_f_r_s_spec_s0_2[2] = f_r_s_for_csa_2[0];
assign nxt_f_r_c_pre_spec_s0_2[2] = f_r_c_for_csa_2[0];
assign nxt_f_r_c_spec_s0_2[2] = nxt_f_r_c_pre_spec_s0_2[2];

// Here we assume s0.qds will generate rt_dig = +1
assign nxt_f_r_s_spec_s0_2[1] = 
  f_r_s_for_csa_2[0]
^ f_r_c_for_csa_2[0]
^ sqrt_csa_val_pos_1_2[0];
assign nxt_f_r_c_pre_spec_s0_2[1] = {
	  (f_r_s_for_csa_2[0][(F16_REM_W-1)-1:0] & f_r_c_for_csa_2[0][(F16_REM_W-1)-1:0])
	| (f_r_s_for_csa_2[0][(F16_REM_W-1)-1:0] & sqrt_csa_val_pos_1_2[0][(F16_REM_W-1)-1:0])
	| (f_r_c_for_csa_2[0][(F16_REM_W-1)-1:0] & sqrt_csa_val_pos_1_2[0][(F16_REM_W-1)-1:0]),
	1'b1
};
assign nxt_f_r_c_spec_s0_2[1] = nxt_f_r_c_pre_spec_s0_2[1];

// Here we assume s0.qds will generate rt_dig = +2
assign nxt_f_r_s_spec_s0_2[0] = 
  f_r_s_for_csa_2[0]
^ f_r_c_for_csa_2[0]
^ sqrt_csa_val_pos_2_2[0];
assign nxt_f_r_c_pre_spec_s0_2[0] = {
	  (f_r_s_for_csa_2[0][(F16_REM_W-1)-1:0] & f_r_c_for_csa_2[0][(F16_REM_W-1)-1:0])
	| (f_r_s_for_csa_2[0][(F16_REM_W-1)-1:0] & sqrt_csa_val_pos_2_2[0][(F16_REM_W-1)-1:0])
	| (f_r_c_for_csa_2[0][(F16_REM_W-1)-1:0] & sqrt_csa_val_pos_2_2[0][(F16_REM_W-1)-1:0]),
	1'b1
};
assign nxt_f_r_c_spec_s0_2[0] = nxt_f_r_c_pre_spec_s0_2[0];

// ================================================================================================================================================
// stage[0].csa for *_3
// ================================================================================================================================================
assign sqrt_csa_val_neg_2_3[0] = ({1'b0, rt_m1_3} << 2) | mask_csa_neg_2[0][F64_REM_W-1 -: F16_REM_W];
assign sqrt_csa_val_neg_1_3[0] = ({1'b0, rt_m1_3} << 1) | mask_csa_neg_1[0][F64_REM_W-1 -: F16_REM_W];
assign sqrt_csa_val_pos_1_3[0] = ~(({1'b0, rt_3} << 1) | mask_csa_pos_1[0][F64_REM_W-1 -: F16_REM_W]);
assign sqrt_csa_val_pos_2_3[0] = ~(({1'b0, rt_3} << 2) | mask_csa_pos_2[0][F64_REM_W-1 -: F16_REM_W]);

assign sqrt_csa_val_3[0] = 
  ({(F16_REM_W){nxt_rt_dig_3[0][4]}} & sqrt_csa_val_neg_2_3[0])
| ({(F16_REM_W){nxt_rt_dig_3[0][3]}} & sqrt_csa_val_neg_1_3[0])
| ({(F16_REM_W){nxt_rt_dig_3[0][1]}} & sqrt_csa_val_pos_1_3[0])
| ({(F16_REM_W){nxt_rt_dig_3[0][0]}} & sqrt_csa_val_pos_2_3[0]);

assign f_r_s_for_csa_3[0] = {f_r_s_i[13:0], 2'b00};
assign f_r_c_for_csa_3[0] = {f_r_c_i[13:0], 2'b00};

// Here we assume s0.qds will generate rt_dig = -2
assign nxt_f_r_s_spec_s0_3[4] = 
  f_r_s_for_csa_3[0]
^ f_r_c_for_csa_3[0]
^ sqrt_csa_val_neg_2_3[0];
assign nxt_f_r_c_pre_spec_s0_3[4] = {
	  (f_r_s_for_csa_3[0][(F16_REM_W-1)-1:0] & f_r_c_for_csa_3[0][(F16_REM_W-1)-1:0])
	| (f_r_s_for_csa_3[0][(F16_REM_W-1)-1:0] & sqrt_csa_val_neg_2_3[0][(F16_REM_W-1)-1:0])
	| (f_r_c_for_csa_3[0][(F16_REM_W-1)-1:0] & sqrt_csa_val_neg_2_3[0][(F16_REM_W-1)-1:0]),
	1'b0
};
assign nxt_f_r_c_spec_s0_3[4] = nxt_f_r_c_pre_spec_s0_3[4];

// Here we assume s0.qds will generate rt_dig = -1
assign nxt_f_r_s_spec_s0_3[3] = 
  f_r_s_for_csa_3[0]
^ f_r_c_for_csa_3[0]
^ sqrt_csa_val_neg_1_3[0];
assign nxt_f_r_c_pre_spec_s0_3[3] = {
	  (f_r_s_for_csa_3[0][(F16_REM_W-1)-1:0] & f_r_c_for_csa_3[0][(F16_REM_W-1)-1:0])
	| (f_r_s_for_csa_3[0][(F16_REM_W-1)-1:0] & sqrt_csa_val_neg_1_3[0][(F16_REM_W-1)-1:0])
	| (f_r_c_for_csa_3[0][(F16_REM_W-1)-1:0] & sqrt_csa_val_neg_1_3[0][(F16_REM_W-1)-1:0]),
	1'b0
};
assign nxt_f_r_c_spec_s0_3[3] = nxt_f_r_c_pre_spec_s0_3[3];

// Here we assume s0.qds will generate rt_dig = 0
assign nxt_f_r_s_spec_s0_3[2] = f_r_s_for_csa_3[0];
assign nxt_f_r_c_pre_spec_s0_3[2] = f_r_c_for_csa_3[0];
assign nxt_f_r_c_spec_s0_3[2] = nxt_f_r_c_pre_spec_s0_3[2];

// Here we assume s0.qds will generate rt_dig = +1
assign nxt_f_r_s_spec_s0_3[1] = 
  f_r_s_for_csa_3[0]
^ f_r_c_for_csa_3[0]
^ sqrt_csa_val_pos_1_3[0];
assign nxt_f_r_c_pre_spec_s0_3[1] = {
	  (f_r_s_for_csa_3[0][(F16_REM_W-1)-1:0] & f_r_c_for_csa_3[0][(F16_REM_W-1)-1:0])
	| (f_r_s_for_csa_3[0][(F16_REM_W-1)-1:0] & sqrt_csa_val_pos_1_3[0][(F16_REM_W-1)-1:0])
	| (f_r_c_for_csa_3[0][(F16_REM_W-1)-1:0] & sqrt_csa_val_pos_1_3[0][(F16_REM_W-1)-1:0]),
	1'b1
};
assign nxt_f_r_c_spec_s0_3[1] = nxt_f_r_c_pre_spec_s0_3[1];

// Here we assume s0.qds will generate rt_dig = +2
assign nxt_f_r_s_spec_s0_3[0] = 
  f_r_s_for_csa_3[0]
^ f_r_c_for_csa_3[0]
^ sqrt_csa_val_pos_2_3[0];
assign nxt_f_r_c_pre_spec_s0_3[0] = {
	  (f_r_s_for_csa_3[0][(F16_REM_W-1)-1:0] & f_r_c_for_csa_3[0][(F16_REM_W-1)-1:0])
	| (f_r_s_for_csa_3[0][(F16_REM_W-1)-1:0] & sqrt_csa_val_pos_2_3[0][(F16_REM_W-1)-1:0])
	| (f_r_c_for_csa_3[0][(F16_REM_W-1)-1:0] & sqrt_csa_val_pos_2_3[0][(F16_REM_W-1)-1:0]),
	1'b1
};
assign nxt_f_r_c_spec_s0_3[0] = nxt_f_r_c_pre_spec_s0_3[0];

// ================================================================================================================================================
// stage[0].fa for *_0
// ================================================================================================================================================
assign adder_9b_for_s1_qds_spec_0[4] = nr_f_r_9b_for_nxt_cycle_s1_qds_0_i + sqrt_csa_val_neg_2_0[0][(F64_REM_W-1) -: 9];
assign adder_9b_for_s1_qds_spec_0[3] = nr_f_r_9b_for_nxt_cycle_s1_qds_0_i + sqrt_csa_val_neg_1_0[0][(F64_REM_W-1) -: 9];
assign adder_9b_for_s1_qds_spec_0[2] = nr_f_r_9b_for_nxt_cycle_s1_qds_0_i;
assign adder_9b_for_s1_qds_spec_0[1] = nr_f_r_9b_for_nxt_cycle_s1_qds_0_i + sqrt_csa_val_pos_1_0[0][(F64_REM_W-1) -: 9];
assign adder_9b_for_s1_qds_spec_0[0] = nr_f_r_9b_for_nxt_cycle_s1_qds_0_i + sqrt_csa_val_pos_2_0[0][(F64_REM_W-1) -: 9];

// ================================================================================================================================================
// stage[0].fa for *_1
// ================================================================================================================================================
assign adder_9b_for_s1_qds_spec_1[4] = nr_f_r_9b_for_nxt_cycle_s1_qds_1_i + sqrt_csa_val_neg_2_1[0][(F32_REM_W-1) -: 9];
assign adder_9b_for_s1_qds_spec_1[3] = nr_f_r_9b_for_nxt_cycle_s1_qds_1_i + sqrt_csa_val_neg_1_1[0][(F32_REM_W-1) -: 9];
assign adder_9b_for_s1_qds_spec_1[2] = nr_f_r_9b_for_nxt_cycle_s1_qds_1_i;
assign adder_9b_for_s1_qds_spec_1[1] = nr_f_r_9b_for_nxt_cycle_s1_qds_1_i + sqrt_csa_val_pos_1_1[0][(F32_REM_W-1) -: 9];
assign adder_9b_for_s1_qds_spec_1[0] = nr_f_r_9b_for_nxt_cycle_s1_qds_1_i + sqrt_csa_val_pos_2_1[0][(F32_REM_W-1) -: 9];

// ================================================================================================================================================
// stage[0].fa for *_2
// ================================================================================================================================================
assign adder_9b_for_s1_qds_spec_2[4] = nr_f_r_9b_for_nxt_cycle_s1_qds_2_i + sqrt_csa_val_neg_2_2[0][(F16_REM_W-1) -: 9];
assign adder_9b_for_s1_qds_spec_2[3] = nr_f_r_9b_for_nxt_cycle_s1_qds_2_i + sqrt_csa_val_neg_1_2[0][(F16_REM_W-1) -: 9];
assign adder_9b_for_s1_qds_spec_2[2] = nr_f_r_9b_for_nxt_cycle_s1_qds_2_i;
assign adder_9b_for_s1_qds_spec_2[1] = nr_f_r_9b_for_nxt_cycle_s1_qds_2_i + sqrt_csa_val_pos_1_2[0][(F16_REM_W-1) -: 9];
assign adder_9b_for_s1_qds_spec_2[0] = nr_f_r_9b_for_nxt_cycle_s1_qds_2_i + sqrt_csa_val_pos_2_2[0][(F16_REM_W-1) -: 9];

// ================================================================================================================================================
// stage[0].fa for *_3
// ================================================================================================================================================
assign adder_9b_for_s1_qds_spec_3[4] = nr_f_r_9b_for_nxt_cycle_s1_qds_3_i + sqrt_csa_val_neg_2_3[0][(F16_REM_W-1) -: 9];
assign adder_9b_for_s1_qds_spec_3[3] = nr_f_r_9b_for_nxt_cycle_s1_qds_3_i + sqrt_csa_val_neg_1_3[0][(F16_REM_W-1) -: 9];
assign adder_9b_for_s1_qds_spec_3[2] = nr_f_r_9b_for_nxt_cycle_s1_qds_3_i;
assign adder_9b_for_s1_qds_spec_3[1] = nr_f_r_9b_for_nxt_cycle_s1_qds_3_i + sqrt_csa_val_pos_1_3[0][(F16_REM_W-1) -: 9];
assign adder_9b_for_s1_qds_spec_3[0] = nr_f_r_9b_for_nxt_cycle_s1_qds_3_i + sqrt_csa_val_pos_2_3[0][(F16_REM_W-1) -: 9];

// ================================================================================================================================================
// stage[0].cg for *_0
// ================================================================================================================================================
assign nxt_rt_spec_s0_0[4] = rt_m1_0 | mask_rt_neg_2[0];
assign nxt_rt_spec_s0_0[3] = rt_m1_0 | mask_rt_neg_1[0];
assign nxt_rt_spec_s0_0[2] = rt_0;
assign nxt_rt_spec_s0_0[1] = rt_0    | mask_rt_pos_1[0];
assign nxt_rt_spec_s0_0[0] = rt_0    | mask_rt_pos_2[0];

// Here we assume s0.qds will generate rt_dig = -2
assign a0_spec_s0_0[4] = nxt_rt_spec_s0_0[4][F64_FULL_RT_W-1];
assign a2_spec_s0_0[4] = nxt_rt_spec_s0_0[4][F64_FULL_RT_W-3];
assign a3_spec_s0_0[4] = nxt_rt_spec_s0_0[4][F64_FULL_RT_W-4];
assign a4_spec_s0_0[4] = nxt_rt_spec_s0_0[4][F64_FULL_RT_W-5];

r4_qds_cg 
u_r4_qds_cg_spec_s0_neg_2_0 (
	.a0_i(a0_spec_s0_0[4]),
	.a2_i(a2_spec_s0_0[4]),
	.a3_i(a3_spec_s0_0[4]),
	.a4_i(a4_spec_s0_0[4]),
	.m_neg_1_o(m_neg_1_spec_s0_0[4]),
	.m_neg_0_o(m_neg_0_spec_s0_0[4]),
	.m_pos_1_o(m_pos_1_spec_s0_0[4]),
	.m_pos_2_o(m_pos_2_spec_s0_0[4])
);

// Here we assume s0.qds will generate rt_dig = -1
assign a0_spec_s0_0[3] = nxt_rt_spec_s0_0[3][F64_FULL_RT_W-1];
assign a2_spec_s0_0[3] = nxt_rt_spec_s0_0[3][F64_FULL_RT_W-3];
assign a3_spec_s0_0[3] = nxt_rt_spec_s0_0[3][F64_FULL_RT_W-4];
assign a4_spec_s0_0[3] = nxt_rt_spec_s0_0[3][F64_FULL_RT_W-5];

r4_qds_cg 
u_r4_qds_cg_spec_s0_neg_1_0 (
	.a0_i(a0_spec_s0_0[3]),
	.a2_i(a2_spec_s0_0[3]),
	.a3_i(a3_spec_s0_0[3]),
	.a4_i(a4_spec_s0_0[3]),
	.m_neg_1_o(m_neg_1_spec_s0_0[3]),
	.m_neg_0_o(m_neg_0_spec_s0_0[3]),
	.m_pos_1_o(m_pos_1_spec_s0_0[3]),
	.m_pos_2_o(m_pos_2_spec_s0_0[3])
);

// Here we assume s0.qds will generate rt_dig = 0
assign a0_spec_s0_0[2] = nxt_rt_spec_s0_0[2][F64_FULL_RT_W-1];
assign a2_spec_s0_0[2] = nxt_rt_spec_s0_0[2][F64_FULL_RT_W-3];
assign a3_spec_s0_0[2] = nxt_rt_spec_s0_0[2][F64_FULL_RT_W-4];
assign a4_spec_s0_0[2] = nxt_rt_spec_s0_0[2][F64_FULL_RT_W-5];

r4_qds_cg 
u_r4_qds_cg_spec_s0_neg_0_0 (
	.a0_i(a0_spec_s0_0[2]),
	.a2_i(a2_spec_s0_0[2]),
	.a3_i(a3_spec_s0_0[2]),
	.a4_i(a4_spec_s0_0[2]),
	.m_neg_1_o(m_neg_1_spec_s0_0[2]),
	.m_neg_0_o(m_neg_0_spec_s0_0[2]),
	.m_pos_1_o(m_pos_1_spec_s0_0[2]),
	.m_pos_2_o(m_pos_2_spec_s0_0[2])
);

// Here we assume s0.qds will generate rt_dig = +1
assign a0_spec_s0_0[1] = nxt_rt_spec_s0_0[1][F64_FULL_RT_W-1];
assign a2_spec_s0_0[1] = nxt_rt_spec_s0_0[1][F64_FULL_RT_W-3];
assign a3_spec_s0_0[1] = nxt_rt_spec_s0_0[1][F64_FULL_RT_W-4];
assign a4_spec_s0_0[1] = nxt_rt_spec_s0_0[1][F64_FULL_RT_W-5];

r4_qds_cg 
u_r4_qds_cg_spec_s0_pos_1_0 (
	.a0_i(a0_spec_s0_0[1]),
	.a2_i(a2_spec_s0_0[1]),
	.a3_i(a3_spec_s0_0[1]),
	.a4_i(a4_spec_s0_0[1]),
	.m_neg_1_o(m_neg_1_spec_s0_0[1]),
	.m_neg_0_o(m_neg_0_spec_s0_0[1]),
	.m_pos_1_o(m_pos_1_spec_s0_0[1]),
	.m_pos_2_o(m_pos_2_spec_s0_0[1])
);

// Here we assume s0.qds will generate rt_dig = +2
assign a0_spec_s0_0[0] = nxt_rt_spec_s0_0[0][F64_FULL_RT_W-1];
assign a2_spec_s0_0[0] = nxt_rt_spec_s0_0[0][F64_FULL_RT_W-3];
assign a3_spec_s0_0[0] = nxt_rt_spec_s0_0[0][F64_FULL_RT_W-4];
assign a4_spec_s0_0[0] = nxt_rt_spec_s0_0[0][F64_FULL_RT_W-5];

r4_qds_cg 
u_r4_qds_cg_spec_s0_pos_2_0 (
	.a0_i(a0_spec_s0_0[0]),
	.a2_i(a2_spec_s0_0[0]),
	.a3_i(a3_spec_s0_0[0]),
	.a4_i(a4_spec_s0_0[0]),
	.m_neg_1_o(m_neg_1_spec_s0_0[0]),
	.m_neg_0_o(m_neg_0_spec_s0_0[0]),
	.m_pos_1_o(m_pos_1_spec_s0_0[0]),
	.m_pos_2_o(m_pos_2_spec_s0_0[0])
);

// ================================================================================================================================================
// stage[0].cg for *_1
// ================================================================================================================================================
assign nxt_rt_spec_s0_1[4] = rt_m1_1 | mask_rt_neg_2[0][F64_FULL_RT_W-1 -: F32_FULL_RT_W];
assign nxt_rt_spec_s0_1[3] = rt_m1_1 | mask_rt_neg_1[0][F64_FULL_RT_W-1 -: F32_FULL_RT_W];
assign nxt_rt_spec_s0_1[2] = rt_1;
assign nxt_rt_spec_s0_1[1] = rt_1    | mask_rt_pos_1[0][F64_FULL_RT_W-1 -: F32_FULL_RT_W];
assign nxt_rt_spec_s0_1[0] = rt_1    | mask_rt_pos_2[0][F64_FULL_RT_W-1 -: F32_FULL_RT_W];

// Here we assume s0.qds will generate rt_dig = -2
assign a0_spec_s0_1[4] = nxt_rt_spec_s0_1[4][F32_FULL_RT_W-1];
assign a2_spec_s0_1[4] = nxt_rt_spec_s0_1[4][F32_FULL_RT_W-3];
assign a3_spec_s0_1[4] = nxt_rt_spec_s0_1[4][F32_FULL_RT_W-4];
assign a4_spec_s0_1[4] = nxt_rt_spec_s0_1[4][F32_FULL_RT_W-5];

r4_qds_cg 
u_r4_qds_cg_spec_s0_neg_2_1 (
	.a0_i(a0_spec_s0_1[4]),
	.a2_i(a2_spec_s0_1[4]),
	.a3_i(a3_spec_s0_1[4]),
	.a4_i(a4_spec_s0_1[4]),
	.m_neg_1_o(m_neg_1_spec_s0_1[4]),
	.m_neg_0_o(m_neg_0_spec_s0_1[4]),
	.m_pos_1_o(m_pos_1_spec_s0_1[4]),
	.m_pos_2_o(m_pos_2_spec_s0_1[4])
);

// Here we assume s0.qds will generate rt_dig = -1
assign a0_spec_s0_1[3] = nxt_rt_spec_s0_1[3][F32_FULL_RT_W-1];
assign a2_spec_s0_1[3] = nxt_rt_spec_s0_1[3][F32_FULL_RT_W-3];
assign a3_spec_s0_1[3] = nxt_rt_spec_s0_1[3][F32_FULL_RT_W-4];
assign a4_spec_s0_1[3] = nxt_rt_spec_s0_1[3][F32_FULL_RT_W-5];

r4_qds_cg 
u_r4_qds_cg_spec_s0_neg_1_1 (
	.a0_i(a0_spec_s0_1[3]),
	.a2_i(a2_spec_s0_1[3]),
	.a3_i(a3_spec_s0_1[3]),
	.a4_i(a4_spec_s0_1[3]),
	.m_neg_1_o(m_neg_1_spec_s0_1[3]),
	.m_neg_0_o(m_neg_0_spec_s0_1[3]),
	.m_pos_1_o(m_pos_1_spec_s0_1[3]),
	.m_pos_2_o(m_pos_2_spec_s0_1[3])
);

// Here we assume s0.qds will generate rt_dig = 0
assign a0_spec_s0_1[2] = nxt_rt_spec_s0_1[2][F32_FULL_RT_W-1];
assign a2_spec_s0_1[2] = nxt_rt_spec_s0_1[2][F32_FULL_RT_W-3];
assign a3_spec_s0_1[2] = nxt_rt_spec_s0_1[2][F32_FULL_RT_W-4];
assign a4_spec_s0_1[2] = nxt_rt_spec_s0_1[2][F32_FULL_RT_W-5];

r4_qds_cg 
u_r4_qds_cg_spec_s0_neg_0_1 (
	.a0_i(a0_spec_s0_1[2]),
	.a2_i(a2_spec_s0_1[2]),
	.a3_i(a3_spec_s0_1[2]),
	.a4_i(a4_spec_s0_1[2]),
	.m_neg_1_o(m_neg_1_spec_s0_1[2]),
	.m_neg_0_o(m_neg_0_spec_s0_1[2]),
	.m_pos_1_o(m_pos_1_spec_s0_1[2]),
	.m_pos_2_o(m_pos_2_spec_s0_1[2])
);

// Here we assume s0.qds will generate rt_dig = +1
assign a0_spec_s0_1[1] = nxt_rt_spec_s0_1[1][F32_FULL_RT_W-1];
assign a2_spec_s0_1[1] = nxt_rt_spec_s0_1[1][F32_FULL_RT_W-3];
assign a3_spec_s0_1[1] = nxt_rt_spec_s0_1[1][F32_FULL_RT_W-4];
assign a4_spec_s0_1[1] = nxt_rt_spec_s0_1[1][F32_FULL_RT_W-5];

r4_qds_cg 
u_r4_qds_cg_spec_s0_pos_1_1 (
	.a0_i(a0_spec_s0_1[1]),
	.a2_i(a2_spec_s0_1[1]),
	.a3_i(a3_spec_s0_1[1]),
	.a4_i(a4_spec_s0_1[1]),
	.m_neg_1_o(m_neg_1_spec_s0_1[1]),
	.m_neg_0_o(m_neg_0_spec_s0_1[1]),
	.m_pos_1_o(m_pos_1_spec_s0_1[1]),
	.m_pos_2_o(m_pos_2_spec_s0_1[1])
);

// Here we assume s0.qds will generate rt_dig = +2
assign a0_spec_s0_1[0] = nxt_rt_spec_s0_1[0][F32_FULL_RT_W-1];
assign a2_spec_s0_1[0] = nxt_rt_spec_s0_1[0][F32_FULL_RT_W-3];
assign a3_spec_s0_1[0] = nxt_rt_spec_s0_1[0][F32_FULL_RT_W-4];
assign a4_spec_s0_1[0] = nxt_rt_spec_s0_1[0][F32_FULL_RT_W-5];

r4_qds_cg 
u_r4_qds_cg_spec_s0_pos_2_1 (
	.a0_i(a0_spec_s0_1[0]),
	.a2_i(a2_spec_s0_1[0]),
	.a3_i(a3_spec_s0_1[0]),
	.a4_i(a4_spec_s0_1[0]),
	.m_neg_1_o(m_neg_1_spec_s0_1[0]),
	.m_neg_0_o(m_neg_0_spec_s0_1[0]),
	.m_pos_1_o(m_pos_1_spec_s0_1[0]),
	.m_pos_2_o(m_pos_2_spec_s0_1[0])
);

// ================================================================================================================================================
// stage[0].cg for *_2
// ================================================================================================================================================
assign nxt_rt_spec_s0_2[4] = rt_m1_2 | mask_rt_neg_2[0][F64_FULL_RT_W-1 -: F16_FULL_RT_W];
assign nxt_rt_spec_s0_2[3] = rt_m1_2 | mask_rt_neg_1[0][F64_FULL_RT_W-1 -: F16_FULL_RT_W];
assign nxt_rt_spec_s0_2[2] = rt_2;
assign nxt_rt_spec_s0_2[1] = rt_2    | mask_rt_pos_1[0][F64_FULL_RT_W-1 -: F16_FULL_RT_W];
assign nxt_rt_spec_s0_2[0] = rt_2    | mask_rt_pos_2[0][F64_FULL_RT_W-1 -: F16_FULL_RT_W];

// Here we assume s0.qds will generate rt_dig = -2
assign a0_spec_s0_2[4] = nxt_rt_spec_s0_2[4][F16_FULL_RT_W-1];
assign a2_spec_s0_2[4] = nxt_rt_spec_s0_2[4][F16_FULL_RT_W-3];
assign a3_spec_s0_2[4] = nxt_rt_spec_s0_2[4][F16_FULL_RT_W-4];
assign a4_spec_s0_2[4] = nxt_rt_spec_s0_2[4][F16_FULL_RT_W-5];

r4_qds_cg 
u_r4_qds_cg_spec_s0_neg_2_2 (
	.a0_i(a0_spec_s0_2[4]),
	.a2_i(a2_spec_s0_2[4]),
	.a3_i(a3_spec_s0_2[4]),
	.a4_i(a4_spec_s0_2[4]),
	.m_neg_1_o(m_neg_1_spec_s0_2[4]),
	.m_neg_0_o(m_neg_0_spec_s0_2[4]),
	.m_pos_1_o(m_pos_1_spec_s0_2[4]),
	.m_pos_2_o(m_pos_2_spec_s0_2[4])
);

// Here we assume s0.qds will generate rt_dig = -1
assign a0_spec_s0_2[3] = nxt_rt_spec_s0_2[3][F16_FULL_RT_W-1];
assign a2_spec_s0_2[3] = nxt_rt_spec_s0_2[3][F16_FULL_RT_W-3];
assign a3_spec_s0_2[3] = nxt_rt_spec_s0_2[3][F16_FULL_RT_W-4];
assign a4_spec_s0_2[3] = nxt_rt_spec_s0_2[3][F16_FULL_RT_W-5];

r4_qds_cg 
u_r4_qds_cg_spec_s0_neg_1_2 (
	.a0_i(a0_spec_s0_2[3]),
	.a2_i(a2_spec_s0_2[3]),
	.a3_i(a3_spec_s0_2[3]),
	.a4_i(a4_spec_s0_2[3]),
	.m_neg_1_o(m_neg_1_spec_s0_2[3]),
	.m_neg_0_o(m_neg_0_spec_s0_2[3]),
	.m_pos_1_o(m_pos_1_spec_s0_2[3]),
	.m_pos_2_o(m_pos_2_spec_s0_2[3])
);

// Here we assume s0.qds will generate rt_dig = 0
assign a0_spec_s0_2[2] = nxt_rt_spec_s0_2[2][F16_FULL_RT_W-1];
assign a2_spec_s0_2[2] = nxt_rt_spec_s0_2[2][F16_FULL_RT_W-3];
assign a3_spec_s0_2[2] = nxt_rt_spec_s0_2[2][F16_FULL_RT_W-4];
assign a4_spec_s0_2[2] = nxt_rt_spec_s0_2[2][F16_FULL_RT_W-5];

r4_qds_cg 
u_r4_qds_cg_spec_s0_neg_0_2 (
	.a0_i(a0_spec_s0_2[2]),
	.a2_i(a2_spec_s0_2[2]),
	.a3_i(a3_spec_s0_2[2]),
	.a4_i(a4_spec_s0_2[2]),
	.m_neg_1_o(m_neg_1_spec_s0_2[2]),
	.m_neg_0_o(m_neg_0_spec_s0_2[2]),
	.m_pos_1_o(m_pos_1_spec_s0_2[2]),
	.m_pos_2_o(m_pos_2_spec_s0_2[2])
);

// Here we assume s0.qds will generate rt_dig = +1
assign a0_spec_s0_2[1] = nxt_rt_spec_s0_2[1][F16_FULL_RT_W-1];
assign a2_spec_s0_2[1] = nxt_rt_spec_s0_2[1][F16_FULL_RT_W-3];
assign a3_spec_s0_2[1] = nxt_rt_spec_s0_2[1][F16_FULL_RT_W-4];
assign a4_spec_s0_2[1] = nxt_rt_spec_s0_2[1][F16_FULL_RT_W-5];

r4_qds_cg 
u_r4_qds_cg_spec_s0_pos_1_2 (
	.a0_i(a0_spec_s0_2[1]),
	.a2_i(a2_spec_s0_2[1]),
	.a3_i(a3_spec_s0_2[1]),
	.a4_i(a4_spec_s0_2[1]),
	.m_neg_1_o(m_neg_1_spec_s0_2[1]),
	.m_neg_0_o(m_neg_0_spec_s0_2[1]),
	.m_pos_1_o(m_pos_1_spec_s0_2[1]),
	.m_pos_2_o(m_pos_2_spec_s0_2[1])
);

// Here we assume s0.qds will generate rt_dig = +2
assign a0_spec_s0_2[0] = nxt_rt_spec_s0_2[0][F16_FULL_RT_W-1];
assign a2_spec_s0_2[0] = nxt_rt_spec_s0_2[0][F16_FULL_RT_W-3];
assign a3_spec_s0_2[0] = nxt_rt_spec_s0_2[0][F16_FULL_RT_W-4];
assign a4_spec_s0_2[0] = nxt_rt_spec_s0_2[0][F16_FULL_RT_W-5];

r4_qds_cg 
u_r4_qds_cg_spec_s0_pos_2_2 (
	.a0_i(a0_spec_s0_2[0]),
	.a2_i(a2_spec_s0_2[0]),
	.a3_i(a3_spec_s0_2[0]),
	.a4_i(a4_spec_s0_2[0]),
	.m_neg_1_o(m_neg_1_spec_s0_2[0]),
	.m_neg_0_o(m_neg_0_spec_s0_2[0]),
	.m_pos_1_o(m_pos_1_spec_s0_2[0]),
	.m_pos_2_o(m_pos_2_spec_s0_2[0])
);

// ================================================================================================================================================
// stage[0].cg for *_3
// ================================================================================================================================================
assign nxt_rt_spec_s0_3[4] = rt_m1_3 | mask_rt_neg_2[0][F64_FULL_RT_W-1 -: F16_FULL_RT_W];
assign nxt_rt_spec_s0_3[3] = rt_m1_3 | mask_rt_neg_1[0][F64_FULL_RT_W-1 -: F16_FULL_RT_W];
assign nxt_rt_spec_s0_3[2] = rt_3;
assign nxt_rt_spec_s0_3[1] = rt_3    | mask_rt_pos_1[0][F64_FULL_RT_W-1 -: F16_FULL_RT_W];
assign nxt_rt_spec_s0_3[0] = rt_3    | mask_rt_pos_2[0][F64_FULL_RT_W-1 -: F16_FULL_RT_W];

// Here we assume s0.qds will generate rt_dig = -2
assign a0_spec_s0_3[4] = nxt_rt_spec_s0_3[4][F16_FULL_RT_W-1];
assign a2_spec_s0_3[4] = nxt_rt_spec_s0_3[4][F16_FULL_RT_W-3];
assign a3_spec_s0_3[4] = nxt_rt_spec_s0_3[4][F16_FULL_RT_W-4];
assign a4_spec_s0_3[4] = nxt_rt_spec_s0_3[4][F16_FULL_RT_W-5];

r4_qds_cg 
u_r4_qds_cg_spec_s0_neg_2_3 (
	.a0_i(a0_spec_s0_3[4]),
	.a2_i(a2_spec_s0_3[4]),
	.a3_i(a3_spec_s0_3[4]),
	.a4_i(a4_spec_s0_3[4]),
	.m_neg_1_o(m_neg_1_spec_s0_3[4]),
	.m_neg_0_o(m_neg_0_spec_s0_3[4]),
	.m_pos_1_o(m_pos_1_spec_s0_3[4]),
	.m_pos_2_o(m_pos_2_spec_s0_3[4])
);

// Here we assume s0.qds will generate rt_dig = -1
assign a0_spec_s0_3[3] = nxt_rt_spec_s0_3[3][F16_FULL_RT_W-1];
assign a2_spec_s0_3[3] = nxt_rt_spec_s0_3[3][F16_FULL_RT_W-3];
assign a3_spec_s0_3[3] = nxt_rt_spec_s0_3[3][F16_FULL_RT_W-4];
assign a4_spec_s0_3[3] = nxt_rt_spec_s0_3[3][F16_FULL_RT_W-5];

r4_qds_cg 
u_r4_qds_cg_spec_s0_neg_1_3 (
	.a0_i(a0_spec_s0_3[3]),
	.a2_i(a2_spec_s0_3[3]),
	.a3_i(a3_spec_s0_3[3]),
	.a4_i(a4_spec_s0_3[3]),
	.m_neg_1_o(m_neg_1_spec_s0_3[3]),
	.m_neg_0_o(m_neg_0_spec_s0_3[3]),
	.m_pos_1_o(m_pos_1_spec_s0_3[3]),
	.m_pos_2_o(m_pos_2_spec_s0_3[3])
);

// Here we assume s0.qds will generate rt_dig = 0
assign a0_spec_s0_3[2] = nxt_rt_spec_s0_3[2][F16_FULL_RT_W-1];
assign a2_spec_s0_3[2] = nxt_rt_spec_s0_3[2][F16_FULL_RT_W-3];
assign a3_spec_s0_3[2] = nxt_rt_spec_s0_3[2][F16_FULL_RT_W-4];
assign a4_spec_s0_3[2] = nxt_rt_spec_s0_3[2][F16_FULL_RT_W-5];

r4_qds_cg 
u_r4_qds_cg_spec_s0_neg_0_3 (
	.a0_i(a0_spec_s0_3[2]),
	.a2_i(a2_spec_s0_3[2]),
	.a3_i(a3_spec_s0_3[2]),
	.a4_i(a4_spec_s0_3[2]),
	.m_neg_1_o(m_neg_1_spec_s0_3[2]),
	.m_neg_0_o(m_neg_0_spec_s0_3[2]),
	.m_pos_1_o(m_pos_1_spec_s0_3[2]),
	.m_pos_2_o(m_pos_2_spec_s0_3[2])
);

// Here we assume s0.qds will generate rt_dig = +1
assign a0_spec_s0_3[1] = nxt_rt_spec_s0_3[1][F16_FULL_RT_W-1];
assign a2_spec_s0_3[1] = nxt_rt_spec_s0_3[1][F16_FULL_RT_W-3];
assign a3_spec_s0_3[1] = nxt_rt_spec_s0_3[1][F16_FULL_RT_W-4];
assign a4_spec_s0_3[1] = nxt_rt_spec_s0_3[1][F16_FULL_RT_W-5];

r4_qds_cg 
u_r4_qds_cg_spec_s0_pos_1_3 (
	.a0_i(a0_spec_s0_3[1]),
	.a2_i(a2_spec_s0_3[1]),
	.a3_i(a3_spec_s0_3[1]),
	.a4_i(a4_spec_s0_3[1]),
	.m_neg_1_o(m_neg_1_spec_s0_3[1]),
	.m_neg_0_o(m_neg_0_spec_s0_3[1]),
	.m_pos_1_o(m_pos_1_spec_s0_3[1]),
	.m_pos_2_o(m_pos_2_spec_s0_3[1])
);

// Here we assume s0.qds will generate rt_dig = +2
assign a0_spec_s0_3[0] = nxt_rt_spec_s0_3[0][F16_FULL_RT_W-1];
assign a2_spec_s0_3[0] = nxt_rt_spec_s0_3[0][F16_FULL_RT_W-3];
assign a3_spec_s0_3[0] = nxt_rt_spec_s0_3[0][F16_FULL_RT_W-4];
assign a4_spec_s0_3[0] = nxt_rt_spec_s0_3[0][F16_FULL_RT_W-5];

r4_qds_cg 
u_r4_qds_cg_spec_s0_pos_2_3 (
	.a0_i(a0_spec_s0_3[0]),
	.a2_i(a2_spec_s0_3[0]),
	.a3_i(a3_spec_s0_3[0]),
	.a4_i(a4_spec_s0_3[0]),
	.m_neg_1_o(m_neg_1_spec_s0_3[0]),
	.m_neg_0_o(m_neg_0_spec_s0_3[0]),
	.m_pos_1_o(m_pos_1_spec_s0_3[0]),
	.m_pos_2_o(m_pos_2_spec_s0_3[0])
);

// ================================================================================================================================================
// Select the signals for stage[1]
// ================================================================================================================================================
assign nxt_f_r_s_0[0] = 
  ({(F64_REM_W){nxt_rt_dig_0[0][4]}} & nxt_f_r_s_spec_s0_0[4])
| ({(F64_REM_W){nxt_rt_dig_0[0][3]}} & nxt_f_r_s_spec_s0_0[3])
| ({(F64_REM_W){nxt_rt_dig_0[0][2]}} & nxt_f_r_s_spec_s0_0[2])
| ({(F64_REM_W){nxt_rt_dig_0[0][1]}} & nxt_f_r_s_spec_s0_0[1])
| ({(F64_REM_W){nxt_rt_dig_0[0][0]}} & nxt_f_r_s_spec_s0_0[0]);

assign nxt_f_r_s_1[0] = 
  ({(F32_REM_W){nxt_rt_dig_1[0][4]}} & nxt_f_r_s_spec_s0_1[4])
| ({(F32_REM_W){nxt_rt_dig_1[0][3]}} & nxt_f_r_s_spec_s0_1[3])
| ({(F32_REM_W){nxt_rt_dig_1[0][2]}} & nxt_f_r_s_spec_s0_1[2])
| ({(F32_REM_W){nxt_rt_dig_1[0][1]}} & nxt_f_r_s_spec_s0_1[1])
| ({(F32_REM_W){nxt_rt_dig_1[0][0]}} & nxt_f_r_s_spec_s0_1[0]);

assign nxt_f_r_s_2[0] = 
  ({(F16_REM_W){nxt_rt_dig_2[0][4]}} & nxt_f_r_s_spec_s0_2[4])
| ({(F16_REM_W){nxt_rt_dig_2[0][3]}} & nxt_f_r_s_spec_s0_2[3])
| ({(F16_REM_W){nxt_rt_dig_2[0][2]}} & nxt_f_r_s_spec_s0_2[2])
| ({(F16_REM_W){nxt_rt_dig_2[0][1]}} & nxt_f_r_s_spec_s0_2[1])
| ({(F16_REM_W){nxt_rt_dig_2[0][0]}} & nxt_f_r_s_spec_s0_2[0]);

assign nxt_f_r_s_3[0] = 
  ({(F16_REM_W){nxt_rt_dig_3[0][4]}} & nxt_f_r_s_spec_s0_3[4])
| ({(F16_REM_W){nxt_rt_dig_3[0][3]}} & nxt_f_r_s_spec_s0_3[3])
| ({(F16_REM_W){nxt_rt_dig_3[0][2]}} & nxt_f_r_s_spec_s0_3[2])
| ({(F16_REM_W){nxt_rt_dig_3[0][1]}} & nxt_f_r_s_spec_s0_3[1])
| ({(F16_REM_W){nxt_rt_dig_3[0][0]}} & nxt_f_r_s_spec_s0_3[0]);

assign nxt_f_r_c_0[0] = 
  ({(F64_REM_W){nxt_rt_dig_0[0][4]}} & nxt_f_r_c_spec_s0_0[4])
| ({(F64_REM_W){nxt_rt_dig_0[0][3]}} & nxt_f_r_c_spec_s0_0[3])
| ({(F64_REM_W){nxt_rt_dig_0[0][2]}} & nxt_f_r_c_spec_s0_0[2])
| ({(F64_REM_W){nxt_rt_dig_0[0][1]}} & nxt_f_r_c_spec_s0_0[1])
| ({(F64_REM_W){nxt_rt_dig_0[0][0]}} & nxt_f_r_c_spec_s0_0[0]);

assign nxt_f_r_c_1[0] = 
  ({(F32_REM_W){nxt_rt_dig_1[0][4]}} & nxt_f_r_c_spec_s0_1[4])
| ({(F32_REM_W){nxt_rt_dig_1[0][3]}} & nxt_f_r_c_spec_s0_1[3])
| ({(F32_REM_W){nxt_rt_dig_1[0][2]}} & nxt_f_r_c_spec_s0_1[2])
| ({(F32_REM_W){nxt_rt_dig_1[0][1]}} & nxt_f_r_c_spec_s0_1[1])
| ({(F32_REM_W){nxt_rt_dig_1[0][0]}} & nxt_f_r_c_spec_s0_1[0]);

assign nxt_f_r_c_2[0] = 
  ({(F16_REM_W){nxt_rt_dig_2[0][4]}} & nxt_f_r_c_spec_s0_2[4])
| ({(F16_REM_W){nxt_rt_dig_2[0][3]}} & nxt_f_r_c_spec_s0_2[3])
| ({(F16_REM_W){nxt_rt_dig_2[0][2]}} & nxt_f_r_c_spec_s0_2[2])
| ({(F16_REM_W){nxt_rt_dig_2[0][1]}} & nxt_f_r_c_spec_s0_2[1])
| ({(F16_REM_W){nxt_rt_dig_2[0][0]}} & nxt_f_r_c_spec_s0_2[0]);

assign nxt_f_r_c_3[0] = 
  ({(F16_REM_W){nxt_rt_dig_3[0][4]}} & nxt_f_r_c_spec_s0_3[4])
| ({(F16_REM_W){nxt_rt_dig_3[0][3]}} & nxt_f_r_c_spec_s0_3[3])
| ({(F16_REM_W){nxt_rt_dig_3[0][2]}} & nxt_f_r_c_spec_s0_3[2])
| ({(F16_REM_W){nxt_rt_dig_3[0][1]}} & nxt_f_r_c_spec_s0_3[1])
| ({(F16_REM_W){nxt_rt_dig_3[0][0]}} & nxt_f_r_c_spec_s0_3[0]);


// TODO: Implement merged csa later
// generate
// if(S0_CSA_IS_MERGED == 1) begin
// 	// For MERGED REM, the width is 70, the meaning of different positions:
// 	// [69:54]
// 	// f16: f16_0.rem[15: 0]
// 	// f32: f32_0.rem[27:12]
// 	// f64: f64_0.rem[55:40]
// 	// [53:52]
// 	// f16: 2'b0
// 	// f32: f32_0.rem[11:10]
// 	// f64: f64_0.rem[39:38]
// 	// [51:36]
// 	// f16: f16_2.rem[15: 0]
// 	// f32: f32_0.rem[ 9: 0], 6'b0
// 	// f64: f64_0.rem[37:22]
// 	// [35:34]
// 	// f16: 2'b0
// 	// f32: 2'b0
// 	// f64: f64_0.rem[21:20]
// 	// [33:18]
// 	// f16: f16_1.rem[15: 0]
// 	// f32: f32_1.rem[27:12]
// 	// f64: f64_0.rem[19: 4]
// 	// [17:16]
// 	// f16: 2'b0
// 	// f32: f32_1.rem[11:10]
// 	// f64: f64_0.rem[ 3: 2]
// 	// [15: 0]
// 	// f16: f16_3.rem[15: 0]
// 	// f32: f32_1.rem[ 9: 0], 6'b0
// 	// f64: f64_0.rem[ 1: 0], 14'b0
	
// 	assign f_r_s_for_csa_merged[0] = {f_r_s_i[(REM_W-2)-1:0], 2'b0};
// 	assign f_r_c_for_csa_merged[0] = {f_r_c_i[(REM_W-2)-1:0], 2'b0};
// 	assign sqrt_csa_val_merged[0] = 
// 	  ({(REM_W){fp_fmt_i[0]}} & {
// 		sqrt_csa_val_0[0][F64_REM_W-1 -: F16_REM_W],
// 		2'b00,
// 		sqrt_csa_val_2[0],
// 		2'b00,
// 		sqrt_csa_val_1[0][F32_REM_W-1 -: F16_REM_W],
// 		2'b00,
// 		sqrt_csa_val_3[0]
// 	})
// 	| ({(REM_W){fp_fmt_i[1]}} & {sqrt_csa_val_0[0][F64_REM_W-1 -: F32_REM_W], 6'b0, 2'b0, sqrt_csa_val_1[0], 6'b0})
// 	| ({(REM_W){fp_fmt_i[2]}} & {sqrt_csa_val_0[0], 14'b0});

// 	assign nxt_f_r_s_merged[0] = 
// 	  f_r_s_for_csa_merged[0]
// 	^ f_r_c_for_csa_merged[0]
// 	^ sqrt_csa_val_merged[0];

// 	assign nxt_f_r_c_merged_pre[0] = {
// 		  (f_r_s_for_csa_merged[0][(REM_W-1)-1:0] & f_r_c_for_csa_merged[0][(REM_W-1)-1:0])
// 		| (f_r_s_for_csa_merged[0][(REM_W-1)-1:0] & sqrt_csa_val_merged[0][(REM_W-1)-1:0])
// 		| (f_r_c_for_csa_merged[0][(REM_W-1)-1:0] & sqrt_csa_val_merged[0][(REM_W-1)-1:0]),
// 		1'b0
// 	};

// 	assign nxt_f_r_c_merged[0] = 
// 	  ({(REM_W){fp_fmt_i[0]}} & {
// 		nxt_f_r_c_merged_pre[0][69:55],
// 		nxt_rt_dig_0[0][1] | nxt_rt_dig_0[0][0],
// 		2'b0,
// 		nxt_f_r_c_merged_pre[0][51:37],
// 		nxt_rt_dig_2[0][1] | nxt_rt_dig_2[0][0],
// 		2'b0,
// 		nxt_f_r_c_merged_pre[0][33:19],
// 		nxt_rt_dig_1[0][1] | nxt_rt_dig_1[0][0],
// 		2'b0,
// 		nxt_f_r_c_merged_pre[0][15:1],
// 		nxt_rt_dig_3[0][1] | nxt_rt_dig_3[0][0]
// 	})
// 	| ({(REM_W){fp_fmt_i[1]}} & {
// 		nxt_f_r_c_merged_pre[0][69:43],
// 		nxt_rt_dig_0[0][1] | nxt_rt_dig_0[0][0],
// 		6'b0,
// 		2'b0,
// 		nxt_f_r_c_merged_pre[0][33:7],
// 		nxt_rt_dig_1[0][1] | nxt_rt_dig_1[0][0],
// 		6'b0
// 	})
// 	| ({(REM_W){fp_fmt_i[2]}} & nxt_f_r_c_merged_pre[0][69:15], nxt_rt_dig_0[0][1] | nxt_rt_dig_0[0][0], 14'b0);


// end else begin

	

// end
// endgenerate


assign adder_7b_res_for_s1_qds_0 = 
  ({(7){nxt_rt_dig_0[0][4]}} & adder_9b_for_s1_qds_spec_0[4][8:2])
| ({(7){nxt_rt_dig_0[0][3]}} & adder_9b_for_s1_qds_spec_0[3][8:2])
| ({(7){nxt_rt_dig_0[0][2]}} & adder_9b_for_s1_qds_spec_0[2][8:2])
| ({(7){nxt_rt_dig_0[0][1]}} & adder_9b_for_s1_qds_spec_0[1][8:2])
| ({(7){nxt_rt_dig_0[0][0]}} & adder_9b_for_s1_qds_spec_0[0][8:2]);

assign adder_7b_res_for_s1_qds_1 = 
  ({(7){nxt_rt_dig_1[0][4]}} & adder_9b_for_s1_qds_spec_1[4][8:2])
| ({(7){nxt_rt_dig_1[0][3]}} & adder_9b_for_s1_qds_spec_1[3][8:2])
| ({(7){nxt_rt_dig_1[0][2]}} & adder_9b_for_s1_qds_spec_1[2][8:2])
| ({(7){nxt_rt_dig_1[0][1]}} & adder_9b_for_s1_qds_spec_1[1][8:2])
| ({(7){nxt_rt_dig_1[0][0]}} & adder_9b_for_s1_qds_spec_1[0][8:2]);

assign adder_7b_res_for_s1_qds_2 = 
  ({(7){nxt_rt_dig_2[0][4]}} & adder_9b_for_s1_qds_spec_2[4][8:2])
| ({(7){nxt_rt_dig_2[0][3]}} & adder_9b_for_s1_qds_spec_2[3][8:2])
| ({(7){nxt_rt_dig_2[0][2]}} & adder_9b_for_s1_qds_spec_2[2][8:2])
| ({(7){nxt_rt_dig_2[0][1]}} & adder_9b_for_s1_qds_spec_2[1][8:2])
| ({(7){nxt_rt_dig_2[0][0]}} & adder_9b_for_s1_qds_spec_2[0][8:2]);

assign adder_7b_res_for_s1_qds_3 = 
  ({(7){nxt_rt_dig_3[0][4]}} & adder_9b_for_s1_qds_spec_3[4][8:2])
| ({(7){nxt_rt_dig_3[0][3]}} & adder_9b_for_s1_qds_spec_3[3][8:2])
| ({(7){nxt_rt_dig_3[0][2]}} & adder_9b_for_s1_qds_spec_3[2][8:2])
| ({(7){nxt_rt_dig_3[0][1]}} & adder_9b_for_s1_qds_spec_3[1][8:2])
| ({(7){nxt_rt_dig_3[0][0]}} & adder_9b_for_s1_qds_spec_3[0][8:2]);


assign m_neg_1_0[1] = 
  ({(7){nxt_rt_dig_0[0][4]}} & m_neg_1_spec_s0_0[4])
| ({(7){nxt_rt_dig_0[0][3]}} & m_neg_1_spec_s0_0[3])
| ({(7){nxt_rt_dig_0[0][2]}} & m_neg_1_spec_s0_0[2])
| ({(7){nxt_rt_dig_0[0][1]}} & m_neg_1_spec_s0_0[1])
| ({(7){nxt_rt_dig_0[0][0]}} & m_neg_1_spec_s0_0[0]);

assign m_neg_1_1[1] = 
  ({(7){nxt_rt_dig_1[0][4]}} & m_neg_1_spec_s0_1[4])
| ({(7){nxt_rt_dig_1[0][3]}} & m_neg_1_spec_s0_1[3])
| ({(7){nxt_rt_dig_1[0][2]}} & m_neg_1_spec_s0_1[2])
| ({(7){nxt_rt_dig_1[0][1]}} & m_neg_1_spec_s0_1[1])
| ({(7){nxt_rt_dig_1[0][0]}} & m_neg_1_spec_s0_1[0]);

assign m_neg_1_2[1] = 
  ({(7){nxt_rt_dig_2[0][4]}} & m_neg_1_spec_s0_2[4])
| ({(7){nxt_rt_dig_2[0][3]}} & m_neg_1_spec_s0_2[3])
| ({(7){nxt_rt_dig_2[0][2]}} & m_neg_1_spec_s0_2[2])
| ({(7){nxt_rt_dig_2[0][1]}} & m_neg_1_spec_s0_2[1])
| ({(7){nxt_rt_dig_2[0][0]}} & m_neg_1_spec_s0_2[0]);

assign m_neg_1_3[1] = 
  ({(7){nxt_rt_dig_3[0][4]}} & m_neg_1_spec_s0_3[4])
| ({(7){nxt_rt_dig_3[0][3]}} & m_neg_1_spec_s0_3[3])
| ({(7){nxt_rt_dig_3[0][2]}} & m_neg_1_spec_s0_3[2])
| ({(7){nxt_rt_dig_3[0][1]}} & m_neg_1_spec_s0_3[1])
| ({(7){nxt_rt_dig_3[0][0]}} & m_neg_1_spec_s0_3[0]);

assign m_neg_0_0[1] = 
  ({(7){nxt_rt_dig_0[0][4]}} & m_neg_0_spec_s0_0[4])
| ({(7){nxt_rt_dig_0[0][3]}} & m_neg_0_spec_s0_0[3])
| ({(7){nxt_rt_dig_0[0][2]}} & m_neg_0_spec_s0_0[2])
| ({(7){nxt_rt_dig_0[0][1]}} & m_neg_0_spec_s0_0[1])
| ({(7){nxt_rt_dig_0[0][0]}} & m_neg_0_spec_s0_0[0]);

assign m_neg_0_1[1] = 
  ({(7){nxt_rt_dig_1[0][4]}} & m_neg_0_spec_s0_1[4])
| ({(7){nxt_rt_dig_1[0][3]}} & m_neg_0_spec_s0_1[3])
| ({(7){nxt_rt_dig_1[0][2]}} & m_neg_0_spec_s0_1[2])
| ({(7){nxt_rt_dig_1[0][1]}} & m_neg_0_spec_s0_1[1])
| ({(7){nxt_rt_dig_1[0][0]}} & m_neg_0_spec_s0_1[0]);

assign m_neg_0_2[1] = 
  ({(7){nxt_rt_dig_2[0][4]}} & m_neg_0_spec_s0_2[4])
| ({(7){nxt_rt_dig_2[0][3]}} & m_neg_0_spec_s0_2[3])
| ({(7){nxt_rt_dig_2[0][2]}} & m_neg_0_spec_s0_2[2])
| ({(7){nxt_rt_dig_2[0][1]}} & m_neg_0_spec_s0_2[1])
| ({(7){nxt_rt_dig_2[0][0]}} & m_neg_0_spec_s0_2[0]);

assign m_neg_0_3[1] = 
  ({(7){nxt_rt_dig_3[0][4]}} & m_neg_0_spec_s0_3[4])
| ({(7){nxt_rt_dig_3[0][3]}} & m_neg_0_spec_s0_3[3])
| ({(7){nxt_rt_dig_3[0][2]}} & m_neg_0_spec_s0_3[2])
| ({(7){nxt_rt_dig_3[0][1]}} & m_neg_0_spec_s0_3[1])
| ({(7){nxt_rt_dig_3[0][0]}} & m_neg_0_spec_s0_3[0]);

assign m_pos_1_0[1] = 
  ({(7){nxt_rt_dig_0[0][4]}} & m_pos_1_spec_s0_0[4])
| ({(7){nxt_rt_dig_0[0][3]}} & m_pos_1_spec_s0_0[3])
| ({(7){nxt_rt_dig_0[0][2]}} & m_pos_1_spec_s0_0[2])
| ({(7){nxt_rt_dig_0[0][1]}} & m_pos_1_spec_s0_0[1])
| ({(7){nxt_rt_dig_0[0][0]}} & m_pos_1_spec_s0_0[0]);

assign m_pos_1_1[1] = 
  ({(7){nxt_rt_dig_1[0][4]}} & m_pos_1_spec_s0_1[4])
| ({(7){nxt_rt_dig_1[0][3]}} & m_pos_1_spec_s0_1[3])
| ({(7){nxt_rt_dig_1[0][2]}} & m_pos_1_spec_s0_1[2])
| ({(7){nxt_rt_dig_1[0][1]}} & m_pos_1_spec_s0_1[1])
| ({(7){nxt_rt_dig_1[0][0]}} & m_pos_1_spec_s0_1[0]);

assign m_pos_1_2[1] = 
  ({(7){nxt_rt_dig_2[0][4]}} & m_pos_1_spec_s0_2[4])
| ({(7){nxt_rt_dig_2[0][3]}} & m_pos_1_spec_s0_2[3])
| ({(7){nxt_rt_dig_2[0][2]}} & m_pos_1_spec_s0_2[2])
| ({(7){nxt_rt_dig_2[0][1]}} & m_pos_1_spec_s0_2[1])
| ({(7){nxt_rt_dig_2[0][0]}} & m_pos_1_spec_s0_2[0]);

assign m_pos_1_3[1] = 
  ({(7){nxt_rt_dig_3[0][4]}} & m_pos_1_spec_s0_3[4])
| ({(7){nxt_rt_dig_3[0][3]}} & m_pos_1_spec_s0_3[3])
| ({(7){nxt_rt_dig_3[0][2]}} & m_pos_1_spec_s0_3[2])
| ({(7){nxt_rt_dig_3[0][1]}} & m_pos_1_spec_s0_3[1])
| ({(7){nxt_rt_dig_3[0][0]}} & m_pos_1_spec_s0_3[0]);

assign m_pos_2_0[1] = 
  ({(7){nxt_rt_dig_0[0][4]}} & m_pos_2_spec_s0_0[4])
| ({(7){nxt_rt_dig_0[0][3]}} & m_pos_2_spec_s0_0[3])
| ({(7){nxt_rt_dig_0[0][2]}} & m_pos_2_spec_s0_0[2])
| ({(7){nxt_rt_dig_0[0][1]}} & m_pos_2_spec_s0_0[1])
| ({(7){nxt_rt_dig_0[0][0]}} & m_pos_2_spec_s0_0[0]);

assign m_pos_2_1[1] = 
  ({(7){nxt_rt_dig_1[0][4]}} & m_pos_2_spec_s0_1[4])
| ({(7){nxt_rt_dig_1[0][3]}} & m_pos_2_spec_s0_1[3])
| ({(7){nxt_rt_dig_1[0][2]}} & m_pos_2_spec_s0_1[2])
| ({(7){nxt_rt_dig_1[0][1]}} & m_pos_2_spec_s0_1[1])
| ({(7){nxt_rt_dig_1[0][0]}} & m_pos_2_spec_s0_1[0]);

assign m_pos_2_2[1] = 
  ({(7){nxt_rt_dig_2[0][4]}} & m_pos_2_spec_s0_2[4])
| ({(7){nxt_rt_dig_2[0][3]}} & m_pos_2_spec_s0_2[3])
| ({(7){nxt_rt_dig_2[0][2]}} & m_pos_2_spec_s0_2[2])
| ({(7){nxt_rt_dig_2[0][1]}} & m_pos_2_spec_s0_2[1])
| ({(7){nxt_rt_dig_2[0][0]}} & m_pos_2_spec_s0_2[0]);

assign m_pos_2_3[1] = 
  ({(7){nxt_rt_dig_3[0][4]}} & m_pos_2_spec_s0_3[4])
| ({(7){nxt_rt_dig_3[0][3]}} & m_pos_2_spec_s0_3[3])
| ({(7){nxt_rt_dig_3[0][2]}} & m_pos_2_spec_s0_3[2])
| ({(7){nxt_rt_dig_3[0][1]}} & m_pos_2_spec_s0_3[1])
| ({(7){nxt_rt_dig_3[0][0]}} & m_pos_2_spec_s0_3[0]);

// ================================================================================================================================================
// Update root after stage[0].qds is finished
// ================================================================================================================================================
assign nxt_rt_0[0] = 
  ({(F64_FULL_RT_W){nxt_rt_dig_0[0][4]}} & nxt_rt_spec_s0_0[4])
| ({(F64_FULL_RT_W){nxt_rt_dig_0[0][3]}} & nxt_rt_spec_s0_0[3])
| ({(F64_FULL_RT_W){nxt_rt_dig_0[0][2]}} & nxt_rt_spec_s0_0[2])
| ({(F64_FULL_RT_W){nxt_rt_dig_0[0][1]}} & nxt_rt_spec_s0_0[1])
| ({(F64_FULL_RT_W){nxt_rt_dig_0[0][0]}} & nxt_rt_spec_s0_0[0]);

assign nxt_rt_m1_0[0] = 
  ({(F64_FULL_RT_W){nxt_rt_dig_0[0][4]}} & (rt_m1_0 | mask_rt_m1_neg_2[0]))
| ({(F64_FULL_RT_W){nxt_rt_dig_0[0][3]}} & (rt_m1_0 | mask_rt_m1_neg_1[0]))
| ({(F64_FULL_RT_W){nxt_rt_dig_0[0][2]}} & (rt_m1_0 | mask_rt_m1_neg_0[0]))
| ({(F64_FULL_RT_W){nxt_rt_dig_0[0][1]}} & rt_0)
| ({(F64_FULL_RT_W){nxt_rt_dig_0[0][0]}} & (rt_0    | mask_rt_m1_pos_2[0]));

assign nxt_rt_1[0] = 
  ({(F32_FULL_RT_W){nxt_rt_dig_1[0][4]}} & nxt_rt_spec_s0_1[4])
| ({(F32_FULL_RT_W){nxt_rt_dig_1[0][3]}} & nxt_rt_spec_s0_1[3])
| ({(F32_FULL_RT_W){nxt_rt_dig_1[0][2]}} & nxt_rt_spec_s0_1[2])
| ({(F32_FULL_RT_W){nxt_rt_dig_1[0][1]}} & nxt_rt_spec_s0_1[1])
| ({(F32_FULL_RT_W){nxt_rt_dig_1[0][0]}} & nxt_rt_spec_s0_1[0]);

assign nxt_rt_m1_1[0] = 
  ({(F32_FULL_RT_W){nxt_rt_dig_1[0][4]}} & (rt_m1_1 | mask_rt_m1_neg_2[0][F64_FULL_RT_W-1 -: F32_FULL_RT_W]))
| ({(F32_FULL_RT_W){nxt_rt_dig_1[0][3]}} & (rt_m1_1 | mask_rt_m1_neg_1[0][F64_FULL_RT_W-1 -: F32_FULL_RT_W]))
| ({(F32_FULL_RT_W){nxt_rt_dig_1[0][2]}} & (rt_m1_1 | mask_rt_m1_neg_0[0][F64_FULL_RT_W-1 -: F32_FULL_RT_W]))
| ({(F32_FULL_RT_W){nxt_rt_dig_1[0][1]}} & rt_1)
| ({(F32_FULL_RT_W){nxt_rt_dig_1[0][0]}} & (rt_1    | mask_rt_m1_pos_2[0][F64_FULL_RT_W-1 -: F32_FULL_RT_W]));

// Clear the lower part of rt/rt_m1 when necessary -> Make sure the lower part will not influence the higher part 
// when we are doing "<< 1" and "<< 2" operation to generate "sqrt_csa_val_xxx"
// Only "*_0" and "*_1" will need this operation.
assign rt_for_csa_0[1] = {
	nxt_rt_0[0][54:40],
	fp_fmt_i[0] ? 2'b0 : nxt_rt_0[0][39:38],
	nxt_rt_0[0][37:28],
	fp_fmt_i[1] ? 2'b0 : nxt_rt_0[0][27:26],
	nxt_rt_0[0][25:0]
};
assign rt_m1_for_csa_0[1] = {
	nxt_rt_m1_0[0][54:40],
	fp_fmt_i[0] ? 2'b0 : nxt_rt_m1_0[0][39:38],
	nxt_rt_m1_0[0][37:28],
	fp_fmt_i[1] ? 2'b0 : nxt_rt_m1_0[0][27:26],
	nxt_rt_m1_0[0][25:0]
};

assign rt_for_csa_1[1] = {
	nxt_rt_1[0][26:12],
	fp_fmt_i[0] ? 2'b0 : nxt_rt_1[0][11:10],
	nxt_rt_1[0][9:0]
};
assign rt_m1_for_csa_1[1] = {
	nxt_rt_m1_1[0][26:12],
	fp_fmt_i[0] ? 2'b0 : nxt_rt_m1_1[0][11:10],
	nxt_rt_m1_1[0][9:0]
};

assign nxt_rt_2[0] = 
  ({(F16_FULL_RT_W){nxt_rt_dig_2[0][4]}} & nxt_rt_spec_s0_2[4])
| ({(F16_FULL_RT_W){nxt_rt_dig_2[0][3]}} & nxt_rt_spec_s0_2[3])
| ({(F16_FULL_RT_W){nxt_rt_dig_2[0][2]}} & nxt_rt_spec_s0_2[2])
| ({(F16_FULL_RT_W){nxt_rt_dig_2[0][1]}} & nxt_rt_spec_s0_2[1])
| ({(F16_FULL_RT_W){nxt_rt_dig_2[0][0]}} & nxt_rt_spec_s0_2[0]);

assign nxt_rt_m1_2[0] = 
  ({(F16_FULL_RT_W){nxt_rt_dig_2[0][4]}} & (rt_m1_2 | mask_rt_m1_neg_2[0][F64_FULL_RT_W-1 -: F16_FULL_RT_W]))
| ({(F16_FULL_RT_W){nxt_rt_dig_2[0][3]}} & (rt_m1_2 | mask_rt_m1_neg_1[0][F64_FULL_RT_W-1 -: F16_FULL_RT_W]))
| ({(F16_FULL_RT_W){nxt_rt_dig_2[0][2]}} & (rt_m1_2 | mask_rt_m1_neg_0[0][F64_FULL_RT_W-1 -: F16_FULL_RT_W]))
| ({(F16_FULL_RT_W){nxt_rt_dig_2[0][1]}} & rt_2)
| ({(F16_FULL_RT_W){nxt_rt_dig_2[0][0]}} & (rt_2    | mask_rt_m1_pos_2[0][F64_FULL_RT_W-1 -: F16_FULL_RT_W]));

assign nxt_rt_3[0] = 
  ({(F16_FULL_RT_W){nxt_rt_dig_3[0][4]}} & nxt_rt_spec_s0_3[4])
| ({(F16_FULL_RT_W){nxt_rt_dig_3[0][3]}} & nxt_rt_spec_s0_3[3])
| ({(F16_FULL_RT_W){nxt_rt_dig_3[0][2]}} & nxt_rt_spec_s0_3[2])
| ({(F16_FULL_RT_W){nxt_rt_dig_3[0][1]}} & nxt_rt_spec_s0_3[1])
| ({(F16_FULL_RT_W){nxt_rt_dig_3[0][0]}} & nxt_rt_spec_s0_3[0]);

assign nxt_rt_m1_3[0] = 
  ({(F16_FULL_RT_W){nxt_rt_dig_3[0][4]}} & (rt_m1_3 | mask_rt_m1_neg_2[0][F64_FULL_RT_W-1 -: F16_FULL_RT_W]))
| ({(F16_FULL_RT_W){nxt_rt_dig_3[0][3]}} & (rt_m1_3 | mask_rt_m1_neg_1[0][F64_FULL_RT_W-1 -: F16_FULL_RT_W]))
| ({(F16_FULL_RT_W){nxt_rt_dig_3[0][2]}} & (rt_m1_3 | mask_rt_m1_neg_0[0][F64_FULL_RT_W-1 -: F16_FULL_RT_W]))
| ({(F16_FULL_RT_W){nxt_rt_dig_3[0][1]}} & rt_3)
| ({(F16_FULL_RT_W){nxt_rt_dig_3[0][0]}} & (rt_3    | mask_rt_m1_pos_2[0][F64_FULL_RT_W-1 -: F16_FULL_RT_W]));


// ================================================================================================================================================
// stage[1].csa for *_0
// ================================================================================================================================================
assign sqrt_csa_val_neg_2_0[1] = ({1'b0, rt_m1_for_csa_0[1]} << 2) | mask_csa_neg_2[1];
assign sqrt_csa_val_neg_1_0[1] = ({1'b0, rt_m1_for_csa_0[1]} << 1) | mask_csa_neg_1[1];
assign sqrt_csa_val_pos_1_0[1] = ~(({1'b0, rt_for_csa_0[1]} << 1) | mask_csa_pos_1[1]);
assign sqrt_csa_val_pos_2_0[1] = ~(({1'b0, rt_for_csa_0[1]} << 2) | mask_csa_pos_2[1]);

assign sqrt_csa_val_0[1] = 
  ({(F64_REM_W){nxt_rt_dig_0[1][4]}} & sqrt_csa_val_neg_2_0[1])
| ({(F64_REM_W){nxt_rt_dig_0[1][3]}} & sqrt_csa_val_neg_1_0[1])
| ({(F64_REM_W){nxt_rt_dig_0[1][1]}} & sqrt_csa_val_pos_1_0[1])
| ({(F64_REM_W){nxt_rt_dig_0[1][0]}} & sqrt_csa_val_pos_2_0[1]);

// f64: {f_r_s/f_r_c[53:0], 2'b00} should be used for csa
// f32: {f_r_s/f_r_c[53:28], 2'b00, f_r_s/f_r_c[25:0], 2'b00} should be used for csa, csa_res[27:0] will be ignored.
// f16: {f_r_s/f_r_c[53:40], 2'b00, f_r_s/f_r_c[37:0], 2'b00} should be used for csa, csa_res[39:0] will be ignored.
assign f_r_s_for_csa_0[1] = {
	nxt_f_r_s_0[0][53:40],
	fp_fmt_i[0] ? 2'b00 : nxt_f_r_s_0[0][39:38],
	nxt_f_r_s_0[0][37:28],
	fp_fmt_i[1] ? 2'b00 : nxt_f_r_s_0[0][27:26],
	nxt_f_r_s_0[0][25:0],
	2'b00
};
assign f_r_c_for_csa_0[1] = {
	nxt_f_r_c_0[0][53:40],
	fp_fmt_i[0] ? 2'b00 : nxt_f_r_c_0[0][39:38],
	nxt_f_r_c_0[0][37:28],
	fp_fmt_i[1] ? 2'b00 : nxt_f_r_c_0[0][27:26],
	nxt_f_r_c_0[0][25:0],
	2'b00
};

// Here we assume s1.qds will generate rt_dig = -2
assign nxt_f_r_s_spec_s1_0[4] = 
  f_r_s_for_csa_0[1]
^ f_r_c_for_csa_0[1]
^ sqrt_csa_val_neg_2_0[1];
assign nxt_f_r_c_pre_spec_s1_0[4] = {
	  (f_r_s_for_csa_0[1][(F64_REM_W-1)-1:0] & f_r_c_for_csa_0[1][(F64_REM_W-1)-1:0])
	| (f_r_s_for_csa_0[1][(F64_REM_W-1)-1:0] & sqrt_csa_val_neg_2_0[1][(F64_REM_W-1)-1:0])
	| (f_r_c_for_csa_0[1][(F64_REM_W-1)-1:0] & sqrt_csa_val_neg_2_0[1][(F64_REM_W-1)-1:0]),
	1'b0
};
assign nxt_f_r_c_spec_s1_0[4] = {
	nxt_f_r_c_pre_spec_s1_0[4][55:41],
	fp_fmt_i[0] ? 1'b0 : nxt_f_r_c_pre_spec_s1_0[4][40],
	nxt_f_r_c_pre_spec_s1_0[4][39:29],
	fp_fmt_i[1] ? 1'b0 : nxt_f_r_c_pre_spec_s1_0[4][28],
	nxt_f_r_c_pre_spec_s1_0[4][27:0]
};

// Here we assume s1.qds will generate rt_dig = -1
assign nxt_f_r_s_spec_s1_0[3] = 
  f_r_s_for_csa_0[1]
^ f_r_c_for_csa_0[1]
^ sqrt_csa_val_neg_1_0[1];
assign nxt_f_r_c_pre_spec_s1_0[3] = {
	  (f_r_s_for_csa_0[1][(F64_REM_W-1)-1:0] & f_r_c_for_csa_0[1][(F64_REM_W-1)-1:0])
	| (f_r_s_for_csa_0[1][(F64_REM_W-1)-1:0] & sqrt_csa_val_neg_1_0[1][(F64_REM_W-1)-1:0])
	| (f_r_c_for_csa_0[1][(F64_REM_W-1)-1:0] & sqrt_csa_val_neg_1_0[1][(F64_REM_W-1)-1:0]),
	1'b0
};
assign nxt_f_r_c_spec_s1_0[3] = {
	nxt_f_r_c_pre_spec_s1_0[3][55:41],
	fp_fmt_i[0] ? 1'b0 : nxt_f_r_c_pre_spec_s1_0[3][40],
	nxt_f_r_c_pre_spec_s1_0[3][39:29],
	fp_fmt_i[1] ? 1'b0 : nxt_f_r_c_pre_spec_s1_0[3][28],
	nxt_f_r_c_pre_spec_s1_0[3][27:0]
};

// Here we assume s1.qds will generate rt_dig = 0
assign nxt_f_r_s_spec_s1_0[2] = f_r_s_for_csa_0[1];
assign nxt_f_r_c_pre_spec_s1_0[2] = f_r_c_for_csa_0[1];
assign nxt_f_r_c_spec_s1_0[2] = nxt_f_r_c_pre_spec_s1_0[2];

// Here we assume s1.qds will generate rt_dig = +1
assign nxt_f_r_s_spec_s1_0[1] = 
  f_r_s_for_csa_0[1]
^ f_r_c_for_csa_0[1]
^ sqrt_csa_val_pos_1_0[1];
assign nxt_f_r_c_pre_spec_s1_0[1] = {
	  (f_r_s_for_csa_0[1][(F64_REM_W-1)-1:0] & f_r_c_for_csa_0[1][(F64_REM_W-1)-1:0])
	| (f_r_s_for_csa_0[1][(F64_REM_W-1)-1:0] & sqrt_csa_val_pos_1_0[1][(F64_REM_W-1)-1:0])
	| (f_r_c_for_csa_0[1][(F64_REM_W-1)-1:0] & sqrt_csa_val_pos_1_0[1][(F64_REM_W-1)-1:0]),
	1'b1
};
assign nxt_f_r_c_spec_s1_0[1] = {
	nxt_f_r_c_pre_spec_s1_0[1][55:41],
	fp_fmt_i[0] ? 1'b1 : nxt_f_r_c_pre_spec_s1_0[1][40],
	nxt_f_r_c_pre_spec_s1_0[1][39:29],
	fp_fmt_i[1] ? 1'b1 : nxt_f_r_c_pre_spec_s1_0[1][28],
	nxt_f_r_c_pre_spec_s1_0[1][27:0]
};

// Here we assume s1.qds will generate rt_dig = +2
assign nxt_f_r_s_spec_s1_0[0] = 
  f_r_s_for_csa_0[1]
^ f_r_c_for_csa_0[1]
^ sqrt_csa_val_pos_2_0[1];
assign nxt_f_r_c_pre_spec_s1_0[0] = {
	  (f_r_s_for_csa_0[1][(F64_REM_W-1)-1:0] & f_r_c_for_csa_0[1][(F64_REM_W-1)-1:0])
	| (f_r_s_for_csa_0[1][(F64_REM_W-1)-1:0] & sqrt_csa_val_pos_2_0[1][(F64_REM_W-1)-1:0])
	| (f_r_c_for_csa_0[1][(F64_REM_W-1)-1:0] & sqrt_csa_val_pos_2_0[1][(F64_REM_W-1)-1:0]),
	1'b1
};
assign nxt_f_r_c_spec_s1_0[0] = {
	nxt_f_r_c_pre_spec_s1_0[0][55:41],
	fp_fmt_i[0] ? 1'b1 : nxt_f_r_c_pre_spec_s1_0[0][40],
	nxt_f_r_c_pre_spec_s1_0[0][39:29],
	fp_fmt_i[1] ? 1'b1 : nxt_f_r_c_pre_spec_s1_0[0][28],
	nxt_f_r_c_pre_spec_s1_0[0][27:0]
};

// ================================================================================================================================================
// stage[1].csa for *_1
// ================================================================================================================================================
assign sqrt_csa_val_neg_2_1[1] = ({1'b0, rt_m1_for_csa_1[1]} << 2) | mask_csa_neg_2[1][F64_REM_W-1 -: F32_REM_W];
assign sqrt_csa_val_neg_1_1[1] = ({1'b0, rt_m1_for_csa_1[1]} << 1) | mask_csa_neg_1[1][F64_REM_W-1 -: F32_REM_W];
assign sqrt_csa_val_pos_1_1[1] = ~(({1'b0, rt_for_csa_1[1]} << 1) | mask_csa_pos_1[1][F64_REM_W-1 -: F32_REM_W]);
assign sqrt_csa_val_pos_2_1[1] = ~(({1'b0, rt_for_csa_1[1]} << 2) | mask_csa_pos_2[1][F64_REM_W-1 -: F32_REM_W]);

assign sqrt_csa_val_1[1] = 
  ({(F32_REM_W){nxt_rt_dig_1[1][4]}} & sqrt_csa_val_neg_2_1[1])
| ({(F32_REM_W){nxt_rt_dig_1[1][3]}} & sqrt_csa_val_neg_1_1[1])
| ({(F32_REM_W){nxt_rt_dig_1[1][1]}} & sqrt_csa_val_pos_1_1[1])
| ({(F32_REM_W){nxt_rt_dig_1[1][0]}} & sqrt_csa_val_pos_2_1[1]);

// f32: {f_r_s/f_r_c[25:0], 2'b00} should be used for csa
// f16: {f_r_s/f_r_c[25:12], 2'b00, f_r_s/f_r_c[9:0], 2'b00} should be used for csa, csa_res[11:0] will be ignored.
assign f_r_s_for_csa_1[1] = {
	nxt_f_r_s_1[0][25:12],
	fp_fmt_i[0] ? 2'b00 : nxt_f_r_s_1[0][11:10],
	nxt_f_r_s_1[0][9:0],
	2'b00
};
assign f_r_c_for_csa_1[1] = {
	nxt_f_r_c_1[0][25:12],
	fp_fmt_i[0] ? 2'b00 : nxt_f_r_c_1[0][11:10],
	nxt_f_r_c_1[0][9:0],
	2'b00
};

// Here we assume s1.qds will generate rt_dig = -2
assign nxt_f_r_s_spec_s1_1[4] = 
  f_r_s_for_csa_1[1]
^ f_r_c_for_csa_1[1]
^ sqrt_csa_val_neg_2_1[1];
assign nxt_f_r_c_pre_spec_s1_1[4] = {
	  (f_r_s_for_csa_1[1][(F32_REM_W-1)-1:0] & f_r_c_for_csa_1[1][(F32_REM_W-1)-1:0])
	| (f_r_s_for_csa_1[1][(F32_REM_W-1)-1:0] & sqrt_csa_val_neg_2_1[1][(F32_REM_W-1)-1:0])
	| (f_r_c_for_csa_1[1][(F32_REM_W-1)-1:0] & sqrt_csa_val_neg_2_1[1][(F32_REM_W-1)-1:0]),
	1'b0
};
assign nxt_f_r_c_spec_s1_1[4] = {
	nxt_f_r_c_pre_spec_s1_1[4][27:13],
	fp_fmt_i[0] ? 1'b0 : nxt_f_r_c_pre_spec_s1_1[4][12],
	nxt_f_r_c_pre_spec_s1_1[4][11:0]
};

// Here we assume s1.qds will generate rt_dig = -1
assign nxt_f_r_s_spec_s1_1[3] = 
  f_r_s_for_csa_1[1]
^ f_r_c_for_csa_1[1]
^ sqrt_csa_val_neg_1_1[1];
assign nxt_f_r_c_pre_spec_s1_1[3] = {
	  (f_r_s_for_csa_1[1][(F32_REM_W-1)-1:0] & f_r_c_for_csa_1[1][(F32_REM_W-1)-1:0])
	| (f_r_s_for_csa_1[1][(F32_REM_W-1)-1:0] & sqrt_csa_val_neg_1_1[1][(F32_REM_W-1)-1:0])
	| (f_r_c_for_csa_1[1][(F32_REM_W-1)-1:0] & sqrt_csa_val_neg_1_1[1][(F32_REM_W-1)-1:0]),
	1'b0
};
assign nxt_f_r_c_spec_s1_1[3] = {
	nxt_f_r_c_pre_spec_s1_1[3][27:13],
	fp_fmt_i[0] ? 1'b0 : nxt_f_r_c_pre_spec_s1_1[3][12],
	nxt_f_r_c_pre_spec_s1_1[3][11:0]
};

// Here we assume s1.qds will generate rt_dig = 0
assign nxt_f_r_s_spec_s1_1[2] = f_r_s_for_csa_1[1];
assign nxt_f_r_c_pre_spec_s1_1[2] = f_r_c_for_csa_1[1];
assign nxt_f_r_c_spec_s1_1[2] = nxt_f_r_c_pre_spec_s1_1[2];

// Here we assume s1.qds will generate rt_dig = +1
assign nxt_f_r_s_spec_s1_1[1] = 
  f_r_s_for_csa_1[1]
^ f_r_c_for_csa_1[1]
^ sqrt_csa_val_pos_1_1[1];
assign nxt_f_r_c_pre_spec_s1_1[1] = {
	  (f_r_s_for_csa_1[1][(F32_REM_W-1)-1:0] & f_r_c_for_csa_1[1][(F32_REM_W-1)-1:0])
	| (f_r_s_for_csa_1[1][(F32_REM_W-1)-1:0] & sqrt_csa_val_pos_1_1[1][(F32_REM_W-1)-1:0])
	| (f_r_c_for_csa_1[1][(F32_REM_W-1)-1:0] & sqrt_csa_val_pos_1_1[1][(F32_REM_W-1)-1:0]),
	1'b1
};
assign nxt_f_r_c_spec_s1_1[1] = {
	nxt_f_r_c_pre_spec_s1_1[1][27:13],
	fp_fmt_i[0] ? 1'b1 : nxt_f_r_c_pre_spec_s1_1[1][12],
	nxt_f_r_c_pre_spec_s1_1[1][11:0]
};

// Here we assume s1.qds will generate rt_dig = +2
assign nxt_f_r_s_spec_s1_1[0] = 
  f_r_s_for_csa_1[1]
^ f_r_c_for_csa_1[1]
^ sqrt_csa_val_pos_2_1[1];
assign nxt_f_r_c_pre_spec_s1_1[0] = {
	  (f_r_s_for_csa_1[1][(F32_REM_W-1)-1:0] & f_r_c_for_csa_1[1][(F32_REM_W-1)-1:0])
	| (f_r_s_for_csa_1[1][(F32_REM_W-1)-1:0] & sqrt_csa_val_pos_2_1[1][(F32_REM_W-1)-1:0])
	| (f_r_c_for_csa_1[1][(F32_REM_W-1)-1:0] & sqrt_csa_val_pos_2_1[1][(F32_REM_W-1)-1:0]),
	1'b1
};
assign nxt_f_r_c_spec_s1_1[0] = {
	nxt_f_r_c_pre_spec_s1_1[0][27:13],
	fp_fmt_i[0] ? 1'b1 : nxt_f_r_c_pre_spec_s1_1[0][12],
	nxt_f_r_c_pre_spec_s1_1[0][11:0]
};

// ================================================================================================================================================
// stage[1].csa for *_2
// ================================================================================================================================================
assign sqrt_csa_val_neg_2_2[1] = ({1'b0, nxt_rt_m1_2[0]} << 2) | mask_csa_neg_2[1][F64_REM_W-1 -: F16_REM_W];
assign sqrt_csa_val_neg_1_2[1] = ({1'b0, nxt_rt_m1_2[0]} << 1) | mask_csa_neg_1[1][F64_REM_W-1 -: F16_REM_W];
assign sqrt_csa_val_pos_1_2[1] = ~(({1'b0, nxt_rt_2[0]} << 1) | mask_csa_pos_1[1][F64_REM_W-1 -: F16_REM_W]);
assign sqrt_csa_val_pos_2_2[1] = ~(({1'b0, nxt_rt_2[0]} << 2) | mask_csa_pos_2[1][F64_REM_W-1 -: F16_REM_W]);

assign sqrt_csa_val_2[1] = 
  ({(F16_REM_W){nxt_rt_dig_2[1][4]}} & sqrt_csa_val_neg_2_2[1])
| ({(F16_REM_W){nxt_rt_dig_2[1][3]}} & sqrt_csa_val_neg_1_2[1])
| ({(F16_REM_W){nxt_rt_dig_2[1][1]}} & sqrt_csa_val_pos_1_2[1])
| ({(F16_REM_W){nxt_rt_dig_2[1][0]}} & sqrt_csa_val_pos_2_2[1]);

assign f_r_s_for_csa_2[1] = {nxt_f_r_s_2[0][13:0], 2'b00};
assign f_r_c_for_csa_2[1] = {nxt_f_r_c_2[0][13:0], 2'b00};

// Here we assume s1.qds will generate rt_dig = -2
assign nxt_f_r_s_spec_s1_2[4] = 
  f_r_s_for_csa_2[1]
^ f_r_c_for_csa_2[1]
^ sqrt_csa_val_neg_2_2[1];
assign nxt_f_r_c_pre_spec_s1_2[4] = {
	  (f_r_s_for_csa_2[1][(F16_REM_W-1)-1:0] & f_r_c_for_csa_2[1][(F16_REM_W-1)-1:0])
	| (f_r_s_for_csa_2[1][(F16_REM_W-1)-1:0] & sqrt_csa_val_neg_2_2[1][(F16_REM_W-1)-1:0])
	| (f_r_c_for_csa_2[1][(F16_REM_W-1)-1:0] & sqrt_csa_val_neg_2_2[1][(F16_REM_W-1)-1:0]),
	1'b0
};
assign nxt_f_r_c_spec_s1_2[4] = nxt_f_r_c_pre_spec_s1_2[4];

// Here we assume s1.qds will generate rt_dig = -1
assign nxt_f_r_s_spec_s1_2[3] = 
  f_r_s_for_csa_2[1]
^ f_r_c_for_csa_2[1]
^ sqrt_csa_val_neg_1_2[1];
assign nxt_f_r_c_pre_spec_s1_2[3] = {
	  (f_r_s_for_csa_2[1][(F16_REM_W-1)-1:0] & f_r_c_for_csa_2[1][(F16_REM_W-1)-1:0])
	| (f_r_s_for_csa_2[1][(F16_REM_W-1)-1:0] & sqrt_csa_val_neg_1_2[1][(F16_REM_W-1)-1:0])
	| (f_r_c_for_csa_2[1][(F16_REM_W-1)-1:0] & sqrt_csa_val_neg_1_2[1][(F16_REM_W-1)-1:0]),
	1'b0
};
assign nxt_f_r_c_spec_s1_2[3] = nxt_f_r_c_pre_spec_s1_2[3];

// Here we assume s1.qds will generate rt_dig = 0
assign nxt_f_r_s_spec_s1_2[2] = f_r_s_for_csa_2[1];
assign nxt_f_r_c_pre_spec_s1_2[2] = f_r_c_for_csa_2[1];
assign nxt_f_r_c_spec_s1_2[2] = nxt_f_r_c_pre_spec_s1_2[2];

// Here we assume s1.qds will generate rt_dig = +1
assign nxt_f_r_s_spec_s1_2[1] = 
  f_r_s_for_csa_2[1]
^ f_r_c_for_csa_2[1]
^ sqrt_csa_val_pos_1_2[1];
assign nxt_f_r_c_pre_spec_s1_2[1] = {
	  (f_r_s_for_csa_2[1][(F16_REM_W-1)-1:0] & f_r_c_for_csa_2[1][(F16_REM_W-1)-1:0])
	| (f_r_s_for_csa_2[1][(F16_REM_W-1)-1:0] & sqrt_csa_val_pos_1_2[1][(F16_REM_W-1)-1:0])
	| (f_r_c_for_csa_2[1][(F16_REM_W-1)-1:0] & sqrt_csa_val_pos_1_2[1][(F16_REM_W-1)-1:0]),
	1'b1
};
assign nxt_f_r_c_spec_s1_2[1] = nxt_f_r_c_pre_spec_s1_2[1];

// Here we assume s1.qds will generate rt_dig = +2
assign nxt_f_r_s_spec_s1_2[0] = 
  f_r_s_for_csa_2[1]
^ f_r_c_for_csa_2[1]
^ sqrt_csa_val_pos_2_2[1];
assign nxt_f_r_c_pre_spec_s1_2[0] = {
	  (f_r_s_for_csa_2[1][(F16_REM_W-1)-1:0] & f_r_c_for_csa_2[1][(F16_REM_W-1)-1:0])
	| (f_r_s_for_csa_2[1][(F16_REM_W-1)-1:0] & sqrt_csa_val_pos_2_2[1][(F16_REM_W-1)-1:0])
	| (f_r_c_for_csa_2[1][(F16_REM_W-1)-1:0] & sqrt_csa_val_pos_2_2[1][(F16_REM_W-1)-1:0]),
	1'b1
};
assign nxt_f_r_c_spec_s1_2[0] = nxt_f_r_c_pre_spec_s1_2[0];

// ================================================================================================================================================
// stage[1].csa for *_3
// ================================================================================================================================================
assign sqrt_csa_val_neg_2_3[1] = ({1'b0, nxt_rt_m1_3[0]} << 2) | mask_csa_neg_2[1][F64_REM_W-1 -: F16_REM_W];
assign sqrt_csa_val_neg_1_3[1] = ({1'b0, nxt_rt_m1_3[0]} << 1) | mask_csa_neg_1[1][F64_REM_W-1 -: F16_REM_W];
assign sqrt_csa_val_pos_1_3[1] = ~(({1'b0, nxt_rt_3[0]} << 1) | mask_csa_pos_1[1][F64_REM_W-1 -: F16_REM_W]);
assign sqrt_csa_val_pos_2_3[1] = ~(({1'b0, nxt_rt_3[0]} << 2) | mask_csa_pos_2[1][F64_REM_W-1 -: F16_REM_W]);

assign sqrt_csa_val_3[1] = 
  ({(F16_REM_W){nxt_rt_dig_3[1][4]}} & sqrt_csa_val_neg_2_3[1])
| ({(F16_REM_W){nxt_rt_dig_3[1][3]}} & sqrt_csa_val_neg_1_3[1])
| ({(F16_REM_W){nxt_rt_dig_3[1][1]}} & sqrt_csa_val_pos_1_3[1])
| ({(F16_REM_W){nxt_rt_dig_3[1][0]}} & sqrt_csa_val_pos_2_3[1]);

assign f_r_s_for_csa_3[1] = {nxt_f_r_s_3[0][13:0], 2'b00};
assign f_r_c_for_csa_3[1] = {nxt_f_r_c_3[0][13:0], 2'b00};

// Here we assume s1.qds will generate rt_dig = -2
assign nxt_f_r_s_spec_s1_3[4] = 
  f_r_s_for_csa_3[1]
^ f_r_c_for_csa_3[1]
^ sqrt_csa_val_neg_2_3[1];
assign nxt_f_r_c_pre_spec_s1_3[4] = {
	  (f_r_s_for_csa_3[1][(F16_REM_W-1)-1:0] & f_r_c_for_csa_3[1][(F16_REM_W-1)-1:0])
	| (f_r_s_for_csa_3[1][(F16_REM_W-1)-1:0] & sqrt_csa_val_neg_2_3[1][(F16_REM_W-1)-1:0])
	| (f_r_c_for_csa_3[1][(F16_REM_W-1)-1:0] & sqrt_csa_val_neg_2_3[1][(F16_REM_W-1)-1:0]),
	1'b0
};
assign nxt_f_r_c_spec_s1_3[4] = nxt_f_r_c_pre_spec_s1_3[4];

// Here we assume s1.qds will generate rt_dig = -1
assign nxt_f_r_s_spec_s1_3[3] = 
  f_r_s_for_csa_3[1]
^ f_r_c_for_csa_3[1]
^ sqrt_csa_val_neg_1_3[1];
assign nxt_f_r_c_pre_spec_s1_3[3] = {
	  (f_r_s_for_csa_3[1][(F16_REM_W-1)-1:0] & f_r_c_for_csa_3[1][(F16_REM_W-1)-1:0])
	| (f_r_s_for_csa_3[1][(F16_REM_W-1)-1:0] & sqrt_csa_val_neg_1_3[1][(F16_REM_W-1)-1:0])
	| (f_r_c_for_csa_3[1][(F16_REM_W-1)-1:0] & sqrt_csa_val_neg_1_3[1][(F16_REM_W-1)-1:0]),
	1'b0
};
assign nxt_f_r_c_spec_s1_3[3] = nxt_f_r_c_pre_spec_s1_3[3];

// Here we assume s1.qds will generate rt_dig = 0
assign nxt_f_r_s_spec_s1_3[2] = f_r_s_for_csa_3[1];
assign nxt_f_r_c_pre_spec_s1_3[2] = f_r_c_for_csa_3[1];
assign nxt_f_r_c_spec_s1_3[2] = nxt_f_r_c_pre_spec_s1_3[2];

// Here we assume s1.qds will generate rt_dig = +1
assign nxt_f_r_s_spec_s1_3[1] = 
  f_r_s_for_csa_3[1]
^ f_r_c_for_csa_3[1]
^ sqrt_csa_val_pos_1_3[1];
assign nxt_f_r_c_pre_spec_s1_3[1] = {
	  (f_r_s_for_csa_3[1][(F16_REM_W-1)-1:0] & f_r_c_for_csa_3[1][(F16_REM_W-1)-1:0])
	| (f_r_s_for_csa_3[1][(F16_REM_W-1)-1:0] & sqrt_csa_val_pos_1_3[1][(F16_REM_W-1)-1:0])
	| (f_r_c_for_csa_3[1][(F16_REM_W-1)-1:0] & sqrt_csa_val_pos_1_3[1][(F16_REM_W-1)-1:0]),
	1'b1
};
assign nxt_f_r_c_spec_s1_3[1] = nxt_f_r_c_pre_spec_s1_3[1];

// Here we assume s1.qds will generate rt_dig = +2
assign nxt_f_r_s_spec_s1_3[0] = 
  f_r_s_for_csa_3[1]
^ f_r_c_for_csa_3[1]
^ sqrt_csa_val_pos_2_3[1];
assign nxt_f_r_c_pre_spec_s1_3[0] = {
	  (f_r_s_for_csa_3[1][(F16_REM_W-1)-1:0] & f_r_c_for_csa_3[1][(F16_REM_W-1)-1:0])
	| (f_r_s_for_csa_3[1][(F16_REM_W-1)-1:0] & sqrt_csa_val_pos_2_3[1][(F16_REM_W-1)-1:0])
	| (f_r_c_for_csa_3[1][(F16_REM_W-1)-1:0] & sqrt_csa_val_pos_2_3[1][(F16_REM_W-1)-1:0]),
	1'b1
};
assign nxt_f_r_c_spec_s1_3[0] = nxt_f_r_c_pre_spec_s1_3[0];

// ================================================================================================================================================
// stage[1].fa for *_0
// ================================================================================================================================================
assign adder_9b_for_nxt_cycle_s0_qds_spec_0[4] = 
  nxt_f_r_s_0[0][(F64_REM_W-1)-2 -: 9]
+ nxt_f_r_c_0[0][(F64_REM_W-1)-2 -: 9]
+ sqrt_csa_val_neg_2_0[1][(F64_REM_W-1) -: 9];

assign adder_9b_for_nxt_cycle_s0_qds_spec_0[3] = 
  nxt_f_r_s_0[0][(F64_REM_W-1)-2 -: 9]
+ nxt_f_r_c_0[0][(F64_REM_W-1)-2 -: 9]
+ sqrt_csa_val_neg_1_0[1][(F64_REM_W-1) -: 9];

assign adder_9b_for_nxt_cycle_s0_qds_spec_0[2] = 
  nxt_f_r_s_0[0][(F64_REM_W-1)-2 -: 9]
+ nxt_f_r_c_0[0][(F64_REM_W-1)-2 -: 9];

assign adder_9b_for_nxt_cycle_s0_qds_spec_0[1] = 
  nxt_f_r_s_0[0][(F64_REM_W-1)-2 -: 9]
+ nxt_f_r_c_0[0][(F64_REM_W-1)-2 -: 9]
+ sqrt_csa_val_pos_1_0[1][(F64_REM_W-1) -: 9];

assign adder_9b_for_nxt_cycle_s0_qds_spec_0[0] = 
  nxt_f_r_s_0[0][(F64_REM_W-1)-2 -: 9]
+ nxt_f_r_c_0[0][(F64_REM_W-1)-2 -: 9]
+ sqrt_csa_val_pos_2_0[1][(F64_REM_W-1) -: 9];



assign adder_10b_for_nxt_cycle_s1_qds_spec_0[4] = 
  nxt_f_r_s_0[0][(F64_REM_W-1)-2-2 -: 10]
+ nxt_f_r_c_0[0][(F64_REM_W-1)-2-2 -: 10]
+ sqrt_csa_val_neg_2_0[1][(F64_REM_W-1)-2 -: 10];

assign adder_10b_for_nxt_cycle_s1_qds_spec_0[3] = 
  nxt_f_r_s_0[0][(F64_REM_W-1)-2-2 -: 10]
+ nxt_f_r_c_0[0][(F64_REM_W-1)-2-2 -: 10]
+ sqrt_csa_val_neg_1_0[1][(F64_REM_W-1)-2 -: 10];

assign adder_10b_for_nxt_cycle_s1_qds_spec_0[2] = 
  nxt_f_r_s_0[0][(F64_REM_W-1)-2-2 -: 10]
+ nxt_f_r_c_0[0][(F64_REM_W-1)-2-2 -: 10];

assign adder_10b_for_nxt_cycle_s1_qds_spec_0[1] = 
  nxt_f_r_s_0[0][(F64_REM_W-1)-2-2 -: 10]
+ nxt_f_r_c_0[0][(F64_REM_W-1)-2-2 -: 10]
+ sqrt_csa_val_pos_1_0[1][(F64_REM_W-1)-2 -: 10];

assign adder_10b_for_nxt_cycle_s1_qds_spec_0[0] = 
  nxt_f_r_s_0[0][(F64_REM_W-1)-2-2 -: 10]
+ nxt_f_r_c_0[0][(F64_REM_W-1)-2-2 -: 10]
+ sqrt_csa_val_pos_2_0[1][(F64_REM_W-1)-2 -: 10];

// ================================================================================================================================================
// stage[1].fa for *_1
// ================================================================================================================================================
assign adder_9b_for_nxt_cycle_s0_qds_spec_1[4] = 
  nxt_f_r_s_1[0][(F32_REM_W-1)-2 -: 9]
+ nxt_f_r_c_1[0][(F32_REM_W-1)-2 -: 9]
+ sqrt_csa_val_neg_2_1[1][(F32_REM_W-1) -: 9];

assign adder_9b_for_nxt_cycle_s0_qds_spec_1[3] = 
  nxt_f_r_s_1[0][(F32_REM_W-1)-2 -: 9]
+ nxt_f_r_c_1[0][(F32_REM_W-1)-2 -: 9]
+ sqrt_csa_val_neg_1_1[1][(F32_REM_W-1) -: 9];

assign adder_9b_for_nxt_cycle_s0_qds_spec_1[2] = 
  nxt_f_r_s_1[0][(F32_REM_W-1)-2 -: 9]
+ nxt_f_r_c_1[0][(F32_REM_W-1)-2 -: 9];

assign adder_9b_for_nxt_cycle_s0_qds_spec_1[1] = 
  nxt_f_r_s_1[0][(F32_REM_W-1)-2 -: 9]
+ nxt_f_r_c_1[0][(F32_REM_W-1)-2 -: 9]
+ sqrt_csa_val_pos_1_1[1][(F32_REM_W-1) -: 9];

assign adder_9b_for_nxt_cycle_s0_qds_spec_1[0] = 
  nxt_f_r_s_1[0][(F32_REM_W-1)-2 -: 9]
+ nxt_f_r_c_1[0][(F32_REM_W-1)-2 -: 9]
+ sqrt_csa_val_pos_2_1[1][(F32_REM_W-1) -: 9];



assign adder_10b_for_nxt_cycle_s1_qds_spec_1[4] = 
  nxt_f_r_s_1[0][(F32_REM_W-1)-2-2 -: 10]
+ nxt_f_r_c_1[0][(F32_REM_W-1)-2-2 -: 10]
+ sqrt_csa_val_neg_2_1[1][(F32_REM_W-1)-2 -: 10];

assign adder_10b_for_nxt_cycle_s1_qds_spec_1[3] = 
  nxt_f_r_s_1[0][(F32_REM_W-1)-2-2 -: 10]
+ nxt_f_r_c_1[0][(F32_REM_W-1)-2-2 -: 10]
+ sqrt_csa_val_neg_1_1[1][(F32_REM_W-1)-2 -: 10];

assign adder_10b_for_nxt_cycle_s1_qds_spec_1[2] = 
  nxt_f_r_s_1[0][(F32_REM_W-1)-2-2 -: 10]
+ nxt_f_r_c_1[0][(F32_REM_W-1)-2-2 -: 10];

assign adder_10b_for_nxt_cycle_s1_qds_spec_1[1] = 
  nxt_f_r_s_1[0][(F32_REM_W-1)-2-2 -: 10]
+ nxt_f_r_c_1[0][(F32_REM_W-1)-2-2 -: 10]
+ sqrt_csa_val_pos_1_1[1][(F32_REM_W-1)-2 -: 10];

assign adder_10b_for_nxt_cycle_s1_qds_spec_1[0] = 
  nxt_f_r_s_1[0][(F32_REM_W-1)-2-2 -: 10]
+ nxt_f_r_c_1[0][(F32_REM_W-1)-2-2 -: 10]
+ sqrt_csa_val_pos_2_1[1][(F32_REM_W-1)-2 -: 10];

// ================================================================================================================================================
// stage[1].fa for *_2
// ================================================================================================================================================
assign adder_9b_for_nxt_cycle_s0_qds_spec_2[4] = 
  nxt_f_r_s_2[0][(F16_REM_W-1)-2 -: 9]
+ nxt_f_r_c_2[0][(F16_REM_W-1)-2 -: 9]
+ sqrt_csa_val_neg_2_2[1][(F16_REM_W-1) -: 9];

assign adder_9b_for_nxt_cycle_s0_qds_spec_2[3] = 
  nxt_f_r_s_2[0][(F16_REM_W-1)-2 -: 9]
+ nxt_f_r_c_2[0][(F16_REM_W-1)-2 -: 9]
+ sqrt_csa_val_neg_1_2[1][(F16_REM_W-1) -: 9];

assign adder_9b_for_nxt_cycle_s0_qds_spec_2[2] = 
  nxt_f_r_s_2[0][(F16_REM_W-1)-2 -: 9]
+ nxt_f_r_c_2[0][(F16_REM_W-1)-2 -: 9];

assign adder_9b_for_nxt_cycle_s0_qds_spec_2[1] = 
  nxt_f_r_s_2[0][(F16_REM_W-1)-2 -: 9]
+ nxt_f_r_c_2[0][(F16_REM_W-1)-2 -: 9]
+ sqrt_csa_val_pos_1_2[1][(F16_REM_W-1) -: 9];

assign adder_9b_for_nxt_cycle_s0_qds_spec_2[0] = 
  nxt_f_r_s_2[0][(F16_REM_W-1)-2 -: 9]
+ nxt_f_r_c_2[0][(F16_REM_W-1)-2 -: 9]
+ sqrt_csa_val_pos_2_2[1][(F16_REM_W-1) -: 9];



assign adder_10b_for_nxt_cycle_s1_qds_spec_2[4] = 
  nxt_f_r_s_2[0][(F16_REM_W-1)-2-2 -: 10]
+ nxt_f_r_c_2[0][(F16_REM_W-1)-2-2 -: 10]
+ sqrt_csa_val_neg_2_2[1][(F16_REM_W-1)-2 -: 10];

assign adder_10b_for_nxt_cycle_s1_qds_spec_2[3] = 
  nxt_f_r_s_2[0][(F16_REM_W-1)-2-2 -: 10]
+ nxt_f_r_c_2[0][(F16_REM_W-1)-2-2 -: 10]
+ sqrt_csa_val_neg_1_2[1][(F16_REM_W-1)-2 -: 10];

assign adder_10b_for_nxt_cycle_s1_qds_spec_2[2] = 
  nxt_f_r_s_2[0][(F16_REM_W-1)-2-2 -: 10]
+ nxt_f_r_c_2[0][(F16_REM_W-1)-2-2 -: 10];

assign adder_10b_for_nxt_cycle_s1_qds_spec_2[1] = 
  nxt_f_r_s_2[0][(F16_REM_W-1)-2-2 -: 10]
+ nxt_f_r_c_2[0][(F16_REM_W-1)-2-2 -: 10]
+ sqrt_csa_val_pos_1_2[1][(F16_REM_W-1)-2 -: 10];

assign adder_10b_for_nxt_cycle_s1_qds_spec_2[0] = 
  nxt_f_r_s_2[0][(F16_REM_W-1)-2-2 -: 10]
+ nxt_f_r_c_2[0][(F16_REM_W-1)-2-2 -: 10]
+ sqrt_csa_val_pos_2_2[1][(F16_REM_W-1)-2 -: 10];

// ================================================================================================================================================
// stage[1].fa for *_3
// ================================================================================================================================================
assign adder_9b_for_nxt_cycle_s0_qds_spec_3[4] = 
  nxt_f_r_s_3[0][(F16_REM_W-1)-2 -: 9]
+ nxt_f_r_c_3[0][(F16_REM_W-1)-2 -: 9]
+ sqrt_csa_val_neg_2_3[1][(F16_REM_W-1) -: 9];

assign adder_9b_for_nxt_cycle_s0_qds_spec_3[3] = 
  nxt_f_r_s_3[0][(F16_REM_W-1)-2 -: 9]
+ nxt_f_r_c_3[0][(F16_REM_W-1)-2 -: 9]
+ sqrt_csa_val_neg_1_3[1][(F16_REM_W-1) -: 9];

assign adder_9b_for_nxt_cycle_s0_qds_spec_3[2] = 
  nxt_f_r_s_3[0][(F16_REM_W-1)-2 -: 9]
+ nxt_f_r_c_3[0][(F16_REM_W-1)-2 -: 9];

assign adder_9b_for_nxt_cycle_s0_qds_spec_3[1] = 
  nxt_f_r_s_3[0][(F16_REM_W-1)-2 -: 9]
+ nxt_f_r_c_3[0][(F16_REM_W-1)-2 -: 9]
+ sqrt_csa_val_pos_1_3[1][(F16_REM_W-1) -: 9];

assign adder_9b_for_nxt_cycle_s0_qds_spec_3[0] = 
  nxt_f_r_s_3[0][(F16_REM_W-1)-2 -: 9]
+ nxt_f_r_c_3[0][(F16_REM_W-1)-2 -: 9]
+ sqrt_csa_val_pos_2_3[1][(F16_REM_W-1) -: 9];



assign adder_10b_for_nxt_cycle_s1_qds_spec_3[4] = 
  nxt_f_r_s_3[0][(F16_REM_W-1)-2-2 -: 10]
+ nxt_f_r_c_3[0][(F16_REM_W-1)-2-2 -: 10]
+ sqrt_csa_val_neg_2_3[1][(F16_REM_W-1)-2 -: 10];

assign adder_10b_for_nxt_cycle_s1_qds_spec_3[3] = 
  nxt_f_r_s_3[0][(F16_REM_W-1)-2-2 -: 10]
+ nxt_f_r_c_3[0][(F16_REM_W-1)-2-2 -: 10]
+ sqrt_csa_val_neg_1_3[1][(F16_REM_W-1)-2 -: 10];

assign adder_10b_for_nxt_cycle_s1_qds_spec_3[2] = 
  nxt_f_r_s_3[0][(F16_REM_W-1)-2-2 -: 10]
+ nxt_f_r_c_3[0][(F16_REM_W-1)-2-2 -: 10];

assign adder_10b_for_nxt_cycle_s1_qds_spec_3[1] = 
  nxt_f_r_s_3[0][(F16_REM_W-1)-2-2 -: 10]
+ nxt_f_r_c_3[0][(F16_REM_W-1)-2-2 -: 10]
+ sqrt_csa_val_pos_1_3[1][(F16_REM_W-1)-2 -: 10];

assign adder_10b_for_nxt_cycle_s1_qds_spec_3[0] = 
  nxt_f_r_s_3[0][(F16_REM_W-1)-2-2 -: 10]
+ nxt_f_r_c_3[0][(F16_REM_W-1)-2-2 -: 10]
+ sqrt_csa_val_pos_2_3[1][(F16_REM_W-1)-2 -: 10];

// ================================================================================================================================================
// stage[1].cg for *_0
// ================================================================================================================================================
assign nxt_rt_spec_s1_0[4] = nxt_rt_m1_0[0] | mask_rt_neg_2[1];
assign nxt_rt_spec_s1_0[3] = nxt_rt_m1_0[0] | mask_rt_neg_1[1];
assign nxt_rt_spec_s1_0[2] = nxt_rt_0[0];
assign nxt_rt_spec_s1_0[1] = nxt_rt_0[0]    | mask_rt_pos_1[1];
assign nxt_rt_spec_s1_0[0] = nxt_rt_0[0]    | mask_rt_pos_2[1];

// Here we assume s1.qds will generate rt_dig = -2
assign a0_spec_s1_0[4] = nxt_rt_spec_s1_0[4][F64_FULL_RT_W-1];
assign a2_spec_s1_0[4] = nxt_rt_spec_s1_0[4][F64_FULL_RT_W-3];
assign a3_spec_s1_0[4] = nxt_rt_spec_s1_0[4][F64_FULL_RT_W-4];
assign a4_spec_s1_0[4] = nxt_rt_spec_s1_0[4][F64_FULL_RT_W-5];

r4_qds_cg 
u_r4_qds_cg_spec_s1_neg_2_0 (
	.a0_i(a0_spec_s1_0[4]),
	.a2_i(a2_spec_s1_0[4]),
	.a3_i(a3_spec_s1_0[4]),
	.a4_i(a4_spec_s1_0[4]),
	.m_neg_1_o(m_neg_1_spec_s1_0[4]),
	.m_neg_0_o(m_neg_0_spec_s1_0[4]),
	.m_pos_1_o(m_pos_1_spec_s1_0[4]),
	.m_pos_2_o(m_pos_2_spec_s1_0[4])
);

// Here we assume s1.qds will generate rt_dig = -1
assign a0_spec_s1_0[3] = nxt_rt_spec_s1_0[3][F64_FULL_RT_W-1];
assign a2_spec_s1_0[3] = nxt_rt_spec_s1_0[3][F64_FULL_RT_W-3];
assign a3_spec_s1_0[3] = nxt_rt_spec_s1_0[3][F64_FULL_RT_W-4];
assign a4_spec_s1_0[3] = nxt_rt_spec_s1_0[3][F64_FULL_RT_W-5];

r4_qds_cg 
u_r4_qds_cg_spec_s1_neg_1_0 (
	.a0_i(a0_spec_s1_0[3]),
	.a2_i(a2_spec_s1_0[3]),
	.a3_i(a3_spec_s1_0[3]),
	.a4_i(a4_spec_s1_0[3]),
	.m_neg_1_o(m_neg_1_spec_s1_0[3]),
	.m_neg_0_o(m_neg_0_spec_s1_0[3]),
	.m_pos_1_o(m_pos_1_spec_s1_0[3]),
	.m_pos_2_o(m_pos_2_spec_s1_0[3])
);

// Here we assume s1.qds will generate rt_dig = 0
assign a0_spec_s1_0[2] = nxt_rt_spec_s1_0[2][F64_FULL_RT_W-1];
assign a2_spec_s1_0[2] = nxt_rt_spec_s1_0[2][F64_FULL_RT_W-3];
assign a3_spec_s1_0[2] = nxt_rt_spec_s1_0[2][F64_FULL_RT_W-4];
assign a4_spec_s1_0[2] = nxt_rt_spec_s1_0[2][F64_FULL_RT_W-5];

r4_qds_cg 
u_r4_qds_cg_spec_s1_neg_0_0 (
	.a0_i(a0_spec_s1_0[2]),
	.a2_i(a2_spec_s1_0[2]),
	.a3_i(a3_spec_s1_0[2]),
	.a4_i(a4_spec_s1_0[2]),
	.m_neg_1_o(m_neg_1_spec_s1_0[2]),
	.m_neg_0_o(m_neg_0_spec_s1_0[2]),
	.m_pos_1_o(m_pos_1_spec_s1_0[2]),
	.m_pos_2_o(m_pos_2_spec_s1_0[2])
);

// Here we assume s1.qds will generate rt_dig = +1
assign a0_spec_s1_0[1] = nxt_rt_spec_s1_0[1][F64_FULL_RT_W-1];
assign a2_spec_s1_0[1] = nxt_rt_spec_s1_0[1][F64_FULL_RT_W-3];
assign a3_spec_s1_0[1] = nxt_rt_spec_s1_0[1][F64_FULL_RT_W-4];
assign a4_spec_s1_0[1] = nxt_rt_spec_s1_0[1][F64_FULL_RT_W-5];

r4_qds_cg 
u_r4_qds_cg_spec_s1_pos_1_0 (
	.a0_i(a0_spec_s1_0[1]),
	.a2_i(a2_spec_s1_0[1]),
	.a3_i(a3_spec_s1_0[1]),
	.a4_i(a4_spec_s1_0[1]),
	.m_neg_1_o(m_neg_1_spec_s1_0[1]),
	.m_neg_0_o(m_neg_0_spec_s1_0[1]),
	.m_pos_1_o(m_pos_1_spec_s1_0[1]),
	.m_pos_2_o(m_pos_2_spec_s1_0[1])
);

// Here we assume s1.qds will generate rt_dig = +2
assign a0_spec_s1_0[0] = nxt_rt_spec_s1_0[0][F64_FULL_RT_W-1];
assign a2_spec_s1_0[0] = nxt_rt_spec_s1_0[0][F64_FULL_RT_W-3];
assign a3_spec_s1_0[0] = nxt_rt_spec_s1_0[0][F64_FULL_RT_W-4];
assign a4_spec_s1_0[0] = nxt_rt_spec_s1_0[0][F64_FULL_RT_W-5];

r4_qds_cg 
u_r4_qds_cg_spec_s1_pos_2_0 (
	.a0_i(a0_spec_s1_0[0]),
	.a2_i(a2_spec_s1_0[0]),
	.a3_i(a3_spec_s1_0[0]),
	.a4_i(a4_spec_s1_0[0]),
	.m_neg_1_o(m_neg_1_spec_s1_0[0]),
	.m_neg_0_o(m_neg_0_spec_s1_0[0]),
	.m_pos_1_o(m_pos_1_spec_s1_0[0]),
	.m_pos_2_o(m_pos_2_spec_s1_0[0])
);

// ================================================================================================================================================
// stage[1].cg for *_1
// ================================================================================================================================================
assign nxt_rt_spec_s1_1[4] = nxt_rt_m1_1[0] | mask_rt_neg_2[1][F64_FULL_RT_W-1 -: F32_FULL_RT_W];
assign nxt_rt_spec_s1_1[3] = nxt_rt_m1_1[0] | mask_rt_neg_1[1][F64_FULL_RT_W-1 -: F32_FULL_RT_W];
assign nxt_rt_spec_s1_1[2] = nxt_rt_1[0];
assign nxt_rt_spec_s1_1[1] = nxt_rt_1[0]    | mask_rt_pos_1[1][F64_FULL_RT_W-1 -: F32_FULL_RT_W];
assign nxt_rt_spec_s1_1[0] = nxt_rt_1[0]    | mask_rt_pos_2[1][F64_FULL_RT_W-1 -: F32_FULL_RT_W];

// Here we assume s1.qds will generate rt_dig = -2
assign a0_spec_s1_1[4] = nxt_rt_spec_s1_1[4][F32_FULL_RT_W-1];
assign a2_spec_s1_1[4] = nxt_rt_spec_s1_1[4][F32_FULL_RT_W-3];
assign a3_spec_s1_1[4] = nxt_rt_spec_s1_1[4][F32_FULL_RT_W-4];
assign a4_spec_s1_1[4] = nxt_rt_spec_s1_1[4][F32_FULL_RT_W-5];

r4_qds_cg 
u_r4_qds_cg_spec_s1_neg_2_1 (
	.a0_i(a0_spec_s1_1[4]),
	.a2_i(a2_spec_s1_1[4]),
	.a3_i(a3_spec_s1_1[4]),
	.a4_i(a4_spec_s1_1[4]),
	.m_neg_1_o(m_neg_1_spec_s1_1[4]),
	.m_neg_0_o(m_neg_0_spec_s1_1[4]),
	.m_pos_1_o(m_pos_1_spec_s1_1[4]),
	.m_pos_2_o(m_pos_2_spec_s1_1[4])
);

// Here we assume s1.qds will generate rt_dig = -1
assign a0_spec_s1_1[3] = nxt_rt_spec_s1_1[3][F32_FULL_RT_W-1];
assign a2_spec_s1_1[3] = nxt_rt_spec_s1_1[3][F32_FULL_RT_W-3];
assign a3_spec_s1_1[3] = nxt_rt_spec_s1_1[3][F32_FULL_RT_W-4];
assign a4_spec_s1_1[3] = nxt_rt_spec_s1_1[3][F32_FULL_RT_W-5];

r4_qds_cg 
u_r4_qds_cg_spec_s1_neg_1_1 (
	.a0_i(a0_spec_s1_1[3]),
	.a2_i(a2_spec_s1_1[3]),
	.a3_i(a3_spec_s1_1[3]),
	.a4_i(a4_spec_s1_1[3]),
	.m_neg_1_o(m_neg_1_spec_s1_1[3]),
	.m_neg_0_o(m_neg_0_spec_s1_1[3]),
	.m_pos_1_o(m_pos_1_spec_s1_1[3]),
	.m_pos_2_o(m_pos_2_spec_s1_1[3])
);

// Here we assume s1.qds will generate rt_dig = 0
assign a0_spec_s1_1[2] = nxt_rt_spec_s1_1[2][F32_FULL_RT_W-1];
assign a2_spec_s1_1[2] = nxt_rt_spec_s1_1[2][F32_FULL_RT_W-3];
assign a3_spec_s1_1[2] = nxt_rt_spec_s1_1[2][F32_FULL_RT_W-4];
assign a4_spec_s1_1[2] = nxt_rt_spec_s1_1[2][F32_FULL_RT_W-5];

r4_qds_cg 
u_r4_qds_cg_spec_s1_neg_0_1 (
	.a0_i(a0_spec_s1_1[2]),
	.a2_i(a2_spec_s1_1[2]),
	.a3_i(a3_spec_s1_1[2]),
	.a4_i(a4_spec_s1_1[2]),
	.m_neg_1_o(m_neg_1_spec_s1_1[2]),
	.m_neg_0_o(m_neg_0_spec_s1_1[2]),
	.m_pos_1_o(m_pos_1_spec_s1_1[2]),
	.m_pos_2_o(m_pos_2_spec_s1_1[2])
);

// Here we assume s1.qds will generate rt_dig = +1
assign a0_spec_s1_1[1] = nxt_rt_spec_s1_1[1][F32_FULL_RT_W-1];
assign a2_spec_s1_1[1] = nxt_rt_spec_s1_1[1][F32_FULL_RT_W-3];
assign a3_spec_s1_1[1] = nxt_rt_spec_s1_1[1][F32_FULL_RT_W-4];
assign a4_spec_s1_1[1] = nxt_rt_spec_s1_1[1][F32_FULL_RT_W-5];

r4_qds_cg 
u_r4_qds_cg_spec_s1_pos_1_1 (
	.a0_i(a0_spec_s1_1[1]),
	.a2_i(a2_spec_s1_1[1]),
	.a3_i(a3_spec_s1_1[1]),
	.a4_i(a4_spec_s1_1[1]),
	.m_neg_1_o(m_neg_1_spec_s1_1[1]),
	.m_neg_0_o(m_neg_0_spec_s1_1[1]),
	.m_pos_1_o(m_pos_1_spec_s1_1[1]),
	.m_pos_2_o(m_pos_2_spec_s1_1[1])
);

// Here we assume s1.qds will generate rt_dig = +2
assign a0_spec_s1_1[0] = nxt_rt_spec_s1_1[0][F32_FULL_RT_W-1];
assign a2_spec_s1_1[0] = nxt_rt_spec_s1_1[0][F32_FULL_RT_W-3];
assign a3_spec_s1_1[0] = nxt_rt_spec_s1_1[0][F32_FULL_RT_W-4];
assign a4_spec_s1_1[0] = nxt_rt_spec_s1_1[0][F32_FULL_RT_W-5];

r4_qds_cg 
u_r4_qds_cg_spec_s1_pos_2_1 (
	.a0_i(a0_spec_s1_1[0]),
	.a2_i(a2_spec_s1_1[0]),
	.a3_i(a3_spec_s1_1[0]),
	.a4_i(a4_spec_s1_1[0]),
	.m_neg_1_o(m_neg_1_spec_s1_1[0]),
	.m_neg_0_o(m_neg_0_spec_s1_1[0]),
	.m_pos_1_o(m_pos_1_spec_s1_1[0]),
	.m_pos_2_o(m_pos_2_spec_s1_1[0])
);

// ================================================================================================================================================
// stage[1].cg for *_2
// ================================================================================================================================================
assign nxt_rt_spec_s1_2[4] = nxt_rt_m1_2[0] | mask_rt_neg_2[1][F64_FULL_RT_W-1 -: F16_FULL_RT_W];
assign nxt_rt_spec_s1_2[3] = nxt_rt_m1_2[0] | mask_rt_neg_1[1][F64_FULL_RT_W-1 -: F16_FULL_RT_W];
assign nxt_rt_spec_s1_2[2] = nxt_rt_2[0];
assign nxt_rt_spec_s1_2[1] = nxt_rt_2[0]    | mask_rt_pos_1[1][F64_FULL_RT_W-1 -: F16_FULL_RT_W];
assign nxt_rt_spec_s1_2[0] = nxt_rt_2[0]    | mask_rt_pos_2[1][F64_FULL_RT_W-1 -: F16_FULL_RT_W];

// Here we assume s1.qds will generate rt_dig = -2
assign a0_spec_s1_2[4] = nxt_rt_spec_s1_2[4][F16_FULL_RT_W-1];
assign a2_spec_s1_2[4] = nxt_rt_spec_s1_2[4][F16_FULL_RT_W-3];
assign a3_spec_s1_2[4] = nxt_rt_spec_s1_2[4][F16_FULL_RT_W-4];
assign a4_spec_s1_2[4] = nxt_rt_spec_s1_2[4][F16_FULL_RT_W-5];

r4_qds_cg 
u_r4_qds_cg_spec_s1_neg_2_2 (
	.a0_i(a0_spec_s1_2[4]),
	.a2_i(a2_spec_s1_2[4]),
	.a3_i(a3_spec_s1_2[4]),
	.a4_i(a4_spec_s1_2[4]),
	.m_neg_1_o(m_neg_1_spec_s1_2[4]),
	.m_neg_0_o(m_neg_0_spec_s1_2[4]),
	.m_pos_1_o(m_pos_1_spec_s1_2[4]),
	.m_pos_2_o(m_pos_2_spec_s1_2[4])
);

// Here we assume s1.qds will generate rt_dig = -1
assign a0_spec_s1_2[3] = nxt_rt_spec_s1_2[3][F16_FULL_RT_W-1];
assign a2_spec_s1_2[3] = nxt_rt_spec_s1_2[3][F16_FULL_RT_W-3];
assign a3_spec_s1_2[3] = nxt_rt_spec_s1_2[3][F16_FULL_RT_W-4];
assign a4_spec_s1_2[3] = nxt_rt_spec_s1_2[3][F16_FULL_RT_W-5];

r4_qds_cg
u_r4_qds_cg_spec_s1_neg_1_2 (
	.a0_i(a0_spec_s1_2[3]),
	.a2_i(a2_spec_s1_2[3]),
	.a3_i(a3_spec_s1_2[3]),
	.a4_i(a4_spec_s1_2[3]),
	.m_neg_1_o(m_neg_1_spec_s1_2[3]),
	.m_neg_0_o(m_neg_0_spec_s1_2[3]),
	.m_pos_1_o(m_pos_1_spec_s1_2[3]),
	.m_pos_2_o(m_pos_2_spec_s1_2[3])
);

// Here we assume s1.qds will generate rt_dig = 0
assign a0_spec_s1_2[2] = nxt_rt_spec_s1_2[2][F16_FULL_RT_W-1];
assign a2_spec_s1_2[2] = nxt_rt_spec_s1_2[2][F16_FULL_RT_W-3];
assign a3_spec_s1_2[2] = nxt_rt_spec_s1_2[2][F16_FULL_RT_W-4];
assign a4_spec_s1_2[2] = nxt_rt_spec_s1_2[2][F16_FULL_RT_W-5];

r4_qds_cg 
u_r4_qds_cg_spec_s1_neg_0_2 (
	.a0_i(a0_spec_s1_2[2]),
	.a2_i(a2_spec_s1_2[2]),
	.a3_i(a3_spec_s1_2[2]),
	.a4_i(a4_spec_s1_2[2]),
	.m_neg_1_o(m_neg_1_spec_s1_2[2]),
	.m_neg_0_o(m_neg_0_spec_s1_2[2]),
	.m_pos_1_o(m_pos_1_spec_s1_2[2]),
	.m_pos_2_o(m_pos_2_spec_s1_2[2])
);

// Here we assume s1.qds will generate rt_dig = +1
assign a0_spec_s1_2[1] = nxt_rt_spec_s1_2[1][F16_FULL_RT_W-1];
assign a2_spec_s1_2[1] = nxt_rt_spec_s1_2[1][F16_FULL_RT_W-3];
assign a3_spec_s1_2[1] = nxt_rt_spec_s1_2[1][F16_FULL_RT_W-4];
assign a4_spec_s1_2[1] = nxt_rt_spec_s1_2[1][F16_FULL_RT_W-5];

r4_qds_cg 
u_r4_qds_cg_spec_s1_pos_1_2 (
	.a0_i(a0_spec_s1_2[1]),
	.a2_i(a2_spec_s1_2[1]),
	.a3_i(a3_spec_s1_2[1]),
	.a4_i(a4_spec_s1_2[1]),
	.m_neg_1_o(m_neg_1_spec_s1_2[1]),
	.m_neg_0_o(m_neg_0_spec_s1_2[1]),
	.m_pos_1_o(m_pos_1_spec_s1_2[1]),
	.m_pos_2_o(m_pos_2_spec_s1_2[1])
);

// Here we assume s1.qds will generate rt_dig = +2
assign a0_spec_s1_2[0] = nxt_rt_spec_s1_2[0][F16_FULL_RT_W-1];
assign a2_spec_s1_2[0] = nxt_rt_spec_s1_2[0][F16_FULL_RT_W-3];
assign a3_spec_s1_2[0] = nxt_rt_spec_s1_2[0][F16_FULL_RT_W-4];
assign a4_spec_s1_2[0] = nxt_rt_spec_s1_2[0][F16_FULL_RT_W-5];

r4_qds_cg 
u_r4_qds_cg_spec_s1_pos_2_2 (
	.a0_i(a0_spec_s1_2[0]),
	.a2_i(a2_spec_s1_2[0]),
	.a3_i(a3_spec_s1_2[0]),
	.a4_i(a4_spec_s1_2[0]),
	.m_neg_1_o(m_neg_1_spec_s1_2[0]),
	.m_neg_0_o(m_neg_0_spec_s1_2[0]),
	.m_pos_1_o(m_pos_1_spec_s1_2[0]),
	.m_pos_2_o(m_pos_2_spec_s1_2[0])
);

// ================================================================================================================================================
// stage[1].cg for *_3
// ================================================================================================================================================
assign nxt_rt_spec_s1_3[4] = nxt_rt_m1_3[0] | mask_rt_neg_2[1][F64_FULL_RT_W-1 -: F16_FULL_RT_W];
assign nxt_rt_spec_s1_3[3] = nxt_rt_m1_3[0] | mask_rt_neg_1[1][F64_FULL_RT_W-1 -: F16_FULL_RT_W];
assign nxt_rt_spec_s1_3[2] = nxt_rt_3[0];
assign nxt_rt_spec_s1_3[1] = nxt_rt_3[0]    | mask_rt_pos_1[1][F64_FULL_RT_W-1 -: F16_FULL_RT_W];
assign nxt_rt_spec_s1_3[0] = nxt_rt_3[0]    | mask_rt_pos_2[1][F64_FULL_RT_W-1 -: F16_FULL_RT_W];

// Here we assume s1.qds will generate rt_dig = -2
assign a0_spec_s1_3[4] = nxt_rt_spec_s1_3[4][F16_FULL_RT_W-1];
assign a2_spec_s1_3[4] = nxt_rt_spec_s1_3[4][F16_FULL_RT_W-3];
assign a3_spec_s1_3[4] = nxt_rt_spec_s1_3[4][F16_FULL_RT_W-4];
assign a4_spec_s1_3[4] = nxt_rt_spec_s1_3[4][F16_FULL_RT_W-5];

r4_qds_cg 
u_r4_qds_cg_spec_s1_neg_2_3 (
	.a0_i(a0_spec_s1_3[4]),
	.a2_i(a2_spec_s1_3[4]),
	.a3_i(a3_spec_s1_3[4]),
	.a4_i(a4_spec_s1_3[4]),
	.m_neg_1_o(m_neg_1_spec_s1_3[4]),
	.m_neg_0_o(m_neg_0_spec_s1_3[4]),
	.m_pos_1_o(m_pos_1_spec_s1_3[4]),
	.m_pos_2_o(m_pos_2_spec_s1_3[4])
);

// Here we assume s1.qds will generate rt_dig = -1
assign a0_spec_s1_3[3] = nxt_rt_spec_s1_3[3][F16_FULL_RT_W-1];
assign a2_spec_s1_3[3] = nxt_rt_spec_s1_3[3][F16_FULL_RT_W-3];
assign a3_spec_s1_3[3] = nxt_rt_spec_s1_3[3][F16_FULL_RT_W-4];
assign a4_spec_s1_3[3] = nxt_rt_spec_s1_3[3][F16_FULL_RT_W-5];

r4_qds_cg
u_r4_qds_cg_spec_s1_neg_1_3 (
	.a0_i(a0_spec_s1_3[3]),
	.a2_i(a2_spec_s1_3[3]),
	.a3_i(a3_spec_s1_3[3]),
	.a4_i(a4_spec_s1_3[3]),
	.m_neg_1_o(m_neg_1_spec_s1_3[3]),
	.m_neg_0_o(m_neg_0_spec_s1_3[3]),
	.m_pos_1_o(m_pos_1_spec_s1_3[3]),
	.m_pos_2_o(m_pos_2_spec_s1_3[3])
);

// Here we assume s1.qds will generate rt_dig = 0
assign a0_spec_s1_3[2] = nxt_rt_spec_s1_3[2][F16_FULL_RT_W-1];
assign a2_spec_s1_3[2] = nxt_rt_spec_s1_3[2][F16_FULL_RT_W-3];
assign a3_spec_s1_3[2] = nxt_rt_spec_s1_3[2][F16_FULL_RT_W-4];
assign a4_spec_s1_3[2] = nxt_rt_spec_s1_3[2][F16_FULL_RT_W-5];

r4_qds_cg 
u_r4_qds_cg_spec_s1_neg_0_3 (
	.a0_i(a0_spec_s1_3[2]),
	.a2_i(a2_spec_s1_3[2]),
	.a3_i(a3_spec_s1_3[2]),
	.a4_i(a4_spec_s1_3[2]),
	.m_neg_1_o(m_neg_1_spec_s1_3[2]),
	.m_neg_0_o(m_neg_0_spec_s1_3[2]),
	.m_pos_1_o(m_pos_1_spec_s1_3[2]),
	.m_pos_2_o(m_pos_2_spec_s1_3[2])
);

// Here we assume s1.qds will generate rt_dig = +1
assign a0_spec_s1_3[1] = nxt_rt_spec_s1_3[1][F16_FULL_RT_W-1];
assign a2_spec_s1_3[1] = nxt_rt_spec_s1_3[1][F16_FULL_RT_W-3];
assign a3_spec_s1_3[1] = nxt_rt_spec_s1_3[1][F16_FULL_RT_W-4];
assign a4_spec_s1_3[1] = nxt_rt_spec_s1_3[1][F16_FULL_RT_W-5];

r4_qds_cg 
u_r4_qds_cg_spec_s1_pos_1_3 (
	.a0_i(a0_spec_s1_3[1]),
	.a2_i(a2_spec_s1_3[1]),
	.a3_i(a3_spec_s1_3[1]),
	.a4_i(a4_spec_s1_3[1]),
	.m_neg_1_o(m_neg_1_spec_s1_3[1]),
	.m_neg_0_o(m_neg_0_spec_s1_3[1]),
	.m_pos_1_o(m_pos_1_spec_s1_3[1]),
	.m_pos_2_o(m_pos_2_spec_s1_3[1])
);

// Here we assume s1.qds will generate rt_dig = +2
assign a0_spec_s1_3[0] = nxt_rt_spec_s1_3[0][F16_FULL_RT_W-1];
assign a2_spec_s1_3[0] = nxt_rt_spec_s1_3[0][F16_FULL_RT_W-3];
assign a3_spec_s1_3[0] = nxt_rt_spec_s1_3[0][F16_FULL_RT_W-4];
assign a4_spec_s1_3[0] = nxt_rt_spec_s1_3[0][F16_FULL_RT_W-5];

r4_qds_cg 
u_r4_qds_cg_spec_s1_pos_2_3 (
	.a0_i(a0_spec_s1_3[0]),
	.a2_i(a2_spec_s1_3[0]),
	.a3_i(a3_spec_s1_3[0]),
	.a4_i(a4_spec_s1_3[0]),
	.m_neg_1_o(m_neg_1_spec_s1_3[0]),
	.m_neg_0_o(m_neg_0_spec_s1_3[0]),
	.m_pos_1_o(m_pos_1_spec_s1_3[0]),
	.m_pos_2_o(m_pos_2_spec_s1_3[0])
);

// ================================================================================================================================================
// stage[1].qds
// ================================================================================================================================================
generate
if(S1_QDS_SPECULATIVE == 1) begin: g_s1_qds_spec

	r4_qds_spec
	u_r4_qds_s1_0 (
		.rem_i(nr_f_r_9b_for_nxt_cycle_s1_qds_0_i),
		.sqrt_csa_val_neg_2_msbs_i(sqrt_csa_val_neg_2_0[0][(F64_REM_W-1) -: 9]),
		.sqrt_csa_val_neg_1_msbs_i(sqrt_csa_val_neg_1_0[0][(F64_REM_W-1) -: 9]),
		.sqrt_csa_val_pos_1_msbs_i(sqrt_csa_val_pos_1_0[0][(F64_REM_W-1) -: 9]),
		.sqrt_csa_val_pos_2_msbs_i(sqrt_csa_val_pos_2_0[0][(F64_REM_W-1) -: 9]),

		.m_neg_1_neg_2_i(m_neg_1_spec_s0_0[4]),
		.m_neg_0_neg_2_i(m_neg_0_spec_s0_0[4]),
		.m_pos_1_neg_2_i(m_pos_1_spec_s0_0[4]),
		.m_pos_2_neg_2_i(m_pos_2_spec_s0_0[4]),

		.m_neg_1_neg_1_i(m_neg_1_spec_s0_0[3]),
		.m_neg_0_neg_1_i(m_neg_0_spec_s0_0[3]),
		.m_pos_1_neg_1_i(m_pos_1_spec_s0_0[3]),
		.m_pos_2_neg_1_i(m_pos_2_spec_s0_0[3]),

		.m_neg_1_neg_0_i(m_neg_1_spec_s0_0[2]),
		.m_neg_0_neg_0_i(m_neg_0_spec_s0_0[2]),
		.m_pos_1_neg_0_i(m_pos_1_spec_s0_0[2]),
		.m_pos_2_neg_0_i(m_pos_2_spec_s0_0[2]),

		.m_neg_1_pos_1_i(m_neg_1_spec_s0_0[1]),
		.m_neg_0_pos_1_i(m_neg_0_spec_s0_0[1]),
		.m_pos_1_pos_1_i(m_pos_1_spec_s0_0[1]),
		.m_pos_2_pos_1_i(m_pos_2_spec_s0_0[1]),

		.m_neg_1_pos_2_i(m_neg_1_spec_s0_0[0]),
		.m_neg_0_pos_2_i(m_neg_0_spec_s0_0[0]),
		.m_pos_1_pos_2_i(m_pos_1_spec_s0_0[0]),
		.m_pos_2_pos_2_i(m_pos_2_spec_s0_0[0]),
		
		.prev_rt_dig_i(nxt_rt_dig_0[0]),
		.rt_dig_o(nxt_rt_dig_0[1])
	);

	r4_qds_spec
	u_r4_qds_s1_1 (
		.rem_i(nr_f_r_9b_for_nxt_cycle_s1_qds_1_i),
		.sqrt_csa_val_neg_2_msbs_i(sqrt_csa_val_neg_2_1[0][(F32_REM_W-1) -: 9]),
		.sqrt_csa_val_neg_1_msbs_i(sqrt_csa_val_neg_1_1[0][(F32_REM_W-1) -: 9]),
		.sqrt_csa_val_pos_1_msbs_i(sqrt_csa_val_pos_1_1[0][(F32_REM_W-1) -: 9]),
		.sqrt_csa_val_pos_2_msbs_i(sqrt_csa_val_pos_2_1[0][(F32_REM_W-1) -: 9]),

		.m_neg_1_neg_2_i(m_neg_1_spec_s0_1[4]),
		.m_neg_0_neg_2_i(m_neg_0_spec_s0_1[4]),
		.m_pos_1_neg_2_i(m_pos_1_spec_s0_1[4]),
		.m_pos_2_neg_2_i(m_pos_2_spec_s0_1[4]),

		.m_neg_1_neg_1_i(m_neg_1_spec_s0_1[3]),
		.m_neg_0_neg_1_i(m_neg_0_spec_s0_1[3]),
		.m_pos_1_neg_1_i(m_pos_1_spec_s0_1[3]),
		.m_pos_2_neg_1_i(m_pos_2_spec_s0_1[3]),

		.m_neg_1_neg_0_i(m_neg_1_spec_s0_1[2]),
		.m_neg_0_neg_0_i(m_neg_0_spec_s0_1[2]),
		.m_pos_1_neg_0_i(m_pos_1_spec_s0_1[2]),
		.m_pos_2_neg_0_i(m_pos_2_spec_s0_1[2]),

		.m_neg_1_pos_1_i(m_neg_1_spec_s0_1[1]),
		.m_neg_0_pos_1_i(m_neg_0_spec_s0_1[1]),
		.m_pos_1_pos_1_i(m_pos_1_spec_s0_1[1]),
		.m_pos_2_pos_1_i(m_pos_2_spec_s0_1[1]),

		.m_neg_1_pos_2_i(m_neg_1_spec_s0_1[0]),
		.m_neg_0_pos_2_i(m_neg_0_spec_s0_1[0]),
		.m_pos_1_pos_2_i(m_pos_1_spec_s0_1[0]),
		.m_pos_2_pos_2_i(m_pos_2_spec_s0_1[0]),
		
		.prev_rt_dig_i(nxt_rt_dig_1[0]),
		.rt_dig_o(nxt_rt_dig_1[1])
	);

	r4_qds_spec
	u_r4_qds_s1_2 (
		.rem_i(nr_f_r_9b_for_nxt_cycle_s1_qds_2_i),
		.sqrt_csa_val_neg_2_msbs_i(sqrt_csa_val_neg_2_2[0][(F16_REM_W-1) -: 9]),
		.sqrt_csa_val_neg_1_msbs_i(sqrt_csa_val_neg_1_2[0][(F16_REM_W-1) -: 9]),
		.sqrt_csa_val_pos_1_msbs_i(sqrt_csa_val_pos_1_2[0][(F16_REM_W-1) -: 9]),
		.sqrt_csa_val_pos_2_msbs_i(sqrt_csa_val_pos_2_2[0][(F16_REM_W-1) -: 9]),

		.m_neg_1_neg_2_i(m_neg_1_spec_s0_2[4]),
		.m_neg_0_neg_2_i(m_neg_0_spec_s0_2[4]),
		.m_pos_1_neg_2_i(m_pos_1_spec_s0_2[4]),
		.m_pos_2_neg_2_i(m_pos_2_spec_s0_2[4]),

		.m_neg_1_neg_1_i(m_neg_1_spec_s0_2[3]),
		.m_neg_0_neg_1_i(m_neg_0_spec_s0_2[3]),
		.m_pos_1_neg_1_i(m_pos_1_spec_s0_2[3]),
		.m_pos_2_neg_1_i(m_pos_2_spec_s0_2[3]),

		.m_neg_1_neg_0_i(m_neg_1_spec_s0_2[2]),
		.m_neg_0_neg_0_i(m_neg_0_spec_s0_2[2]),
		.m_pos_1_neg_0_i(m_pos_1_spec_s0_2[2]),
		.m_pos_2_neg_0_i(m_pos_2_spec_s0_2[2]),

		.m_neg_1_pos_1_i(m_neg_1_spec_s0_2[1]),
		.m_neg_0_pos_1_i(m_neg_0_spec_s0_2[1]),
		.m_pos_1_pos_1_i(m_pos_1_spec_s0_2[1]),
		.m_pos_2_pos_1_i(m_pos_2_spec_s0_2[1]),

		.m_neg_1_pos_2_i(m_neg_1_spec_s0_2[0]),
		.m_neg_0_pos_2_i(m_neg_0_spec_s0_2[0]),
		.m_pos_1_pos_2_i(m_pos_1_spec_s0_2[0]),
		.m_pos_2_pos_2_i(m_pos_2_spec_s0_2[0]),
		
		.prev_rt_dig_i(nxt_rt_dig_2[0]),
		.rt_dig_o(nxt_rt_dig_2[1])
	);

	r4_qds_spec
	u_r4_qds_s1_3 (
		.rem_i(nr_f_r_9b_for_nxt_cycle_s1_qds_3_i),
		.sqrt_csa_val_neg_2_msbs_i(sqrt_csa_val_neg_2_3[0][(F16_REM_W-1) -: 9]),
		.sqrt_csa_val_neg_1_msbs_i(sqrt_csa_val_neg_1_3[0][(F16_REM_W-1) -: 9]),
		.sqrt_csa_val_pos_1_msbs_i(sqrt_csa_val_pos_1_3[0][(F16_REM_W-1) -: 9]),
		.sqrt_csa_val_pos_2_msbs_i(sqrt_csa_val_pos_2_3[0][(F16_REM_W-1) -: 9]),

		.m_neg_1_neg_2_i(m_neg_1_spec_s0_3[4]),
		.m_neg_0_neg_2_i(m_neg_0_spec_s0_3[4]),
		.m_pos_1_neg_2_i(m_pos_1_spec_s0_3[4]),
		.m_pos_2_neg_2_i(m_pos_2_spec_s0_3[4]),

		.m_neg_1_neg_1_i(m_neg_1_spec_s0_3[3]),
		.m_neg_0_neg_1_i(m_neg_0_spec_s0_3[3]),
		.m_pos_1_neg_1_i(m_pos_1_spec_s0_3[3]),
		.m_pos_2_neg_1_i(m_pos_2_spec_s0_3[3]),

		.m_neg_1_neg_0_i(m_neg_1_spec_s0_3[2]),
		.m_neg_0_neg_0_i(m_neg_0_spec_s0_3[2]),
		.m_pos_1_neg_0_i(m_pos_1_spec_s0_3[2]),
		.m_pos_2_neg_0_i(m_pos_2_spec_s0_3[2]),

		.m_neg_1_pos_1_i(m_neg_1_spec_s0_3[1]),
		.m_neg_0_pos_1_i(m_neg_0_spec_s0_3[1]),
		.m_pos_1_pos_1_i(m_pos_1_spec_s0_3[1]),
		.m_pos_2_pos_1_i(m_pos_2_spec_s0_3[1]),

		.m_neg_1_pos_2_i(m_neg_1_spec_s0_3[0]),
		.m_neg_0_pos_2_i(m_neg_0_spec_s0_3[0]),
		.m_pos_1_pos_2_i(m_pos_1_spec_s0_3[0]),
		.m_pos_2_pos_2_i(m_pos_2_spec_s0_3[0]),
		
		.prev_rt_dig_i(nxt_rt_dig_3[0]),
		.rt_dig_o(nxt_rt_dig_3[1])
	);

end else begin: g_n_s1_qds_spec

	r4_qds
	u_r4_qds_s1_0 (
		.rem_i(adder_7b_res_for_s1_qds_0),
		.m_neg_1_i(m_neg_1_0[1]),
		.m_neg_0_i(m_neg_0_0[1]),
		.m_pos_1_i(m_pos_1_0[1]),
		.m_pos_2_i(m_pos_2_0[1]),
		.rt_dig_o(nxt_rt_dig_0[1])
	);

	r4_qds
	u_r4_qds_s1_1 (
		.rem_i(adder_7b_res_for_s1_qds_1),
		.m_neg_1_i(m_neg_1_1[1]),
		.m_neg_0_i(m_neg_0_1[1]),
		.m_pos_1_i(m_pos_1_1[1]),
		.m_pos_2_i(m_pos_2_1[1]),
		.rt_dig_o(nxt_rt_dig_1[1])
	);

	r4_qds
	u_r4_qds_s1_2 (
		.rem_i(adder_7b_res_for_s1_qds_2),
		.m_neg_1_i(m_neg_1_2[1]),
		.m_neg_0_i(m_neg_0_2[1]),
		.m_pos_1_i(m_pos_1_2[1]),
		.m_pos_2_i(m_pos_2_2[1]),
		.rt_dig_o(nxt_rt_dig_2[1])
	);

	r4_qds
	u_r4_qds_s1_3 (
		.rem_i(adder_7b_res_for_s1_qds_3),
		.m_neg_1_i(m_neg_1_3[1]),
		.m_neg_0_i(m_neg_0_3[1]),
		.m_pos_1_i(m_pos_1_3[1]),
		.m_pos_2_i(m_pos_2_3[1]),
		.rt_dig_o(nxt_rt_dig_3[1])
	);

end
endgenerate

// ================================================================================================================================================
// Select the signals for nxt cycle
// ================================================================================================================================================
assign adder_7b_res_for_nxt_cycle_s0_qds_0_o = 
  ({(7){nxt_rt_dig_0[1][4]}} & adder_9b_for_nxt_cycle_s0_qds_spec_0[4][8:2])
| ({(7){nxt_rt_dig_0[1][3]}} & adder_9b_for_nxt_cycle_s0_qds_spec_0[3][8:2])
| ({(7){nxt_rt_dig_0[1][2]}} & adder_9b_for_nxt_cycle_s0_qds_spec_0[2][8:2])
| ({(7){nxt_rt_dig_0[1][1]}} & adder_9b_for_nxt_cycle_s0_qds_spec_0[1][8:2])
| ({(7){nxt_rt_dig_0[1][0]}} & adder_9b_for_nxt_cycle_s0_qds_spec_0[0][8:2]);

assign adder_7b_res_for_nxt_cycle_s0_qds_1_o = 
  ({(7){nxt_rt_dig_1[1][4]}} & adder_9b_for_nxt_cycle_s0_qds_spec_1[4][8:2])
| ({(7){nxt_rt_dig_1[1][3]}} & adder_9b_for_nxt_cycle_s0_qds_spec_1[3][8:2])
| ({(7){nxt_rt_dig_1[1][2]}} & adder_9b_for_nxt_cycle_s0_qds_spec_1[2][8:2])
| ({(7){nxt_rt_dig_1[1][1]}} & adder_9b_for_nxt_cycle_s0_qds_spec_1[1][8:2])
| ({(7){nxt_rt_dig_1[1][0]}} & adder_9b_for_nxt_cycle_s0_qds_spec_1[0][8:2]);

assign adder_7b_res_for_nxt_cycle_s0_qds_2_o = 
  ({(7){nxt_rt_dig_2[1][4]}} & adder_9b_for_nxt_cycle_s0_qds_spec_2[4][8:2])
| ({(7){nxt_rt_dig_2[1][3]}} & adder_9b_for_nxt_cycle_s0_qds_spec_2[3][8:2])
| ({(7){nxt_rt_dig_2[1][2]}} & adder_9b_for_nxt_cycle_s0_qds_spec_2[2][8:2])
| ({(7){nxt_rt_dig_2[1][1]}} & adder_9b_for_nxt_cycle_s0_qds_spec_2[1][8:2])
| ({(7){nxt_rt_dig_2[1][0]}} & adder_9b_for_nxt_cycle_s0_qds_spec_2[0][8:2]);

assign adder_7b_res_for_nxt_cycle_s0_qds_3_o = 
  ({(7){nxt_rt_dig_3[1][4]}} & adder_9b_for_nxt_cycle_s0_qds_spec_3[4][8:2])
| ({(7){nxt_rt_dig_3[1][3]}} & adder_9b_for_nxt_cycle_s0_qds_spec_3[3][8:2])
| ({(7){nxt_rt_dig_3[1][2]}} & adder_9b_for_nxt_cycle_s0_qds_spec_3[2][8:2])
| ({(7){nxt_rt_dig_3[1][1]}} & adder_9b_for_nxt_cycle_s0_qds_spec_3[1][8:2])
| ({(7){nxt_rt_dig_3[1][0]}} & adder_9b_for_nxt_cycle_s0_qds_spec_3[0][8:2]);


assign adder_9b_res_for_nxt_cycle_s1_qds_0_o = 
  ({(9){nxt_rt_dig_0[1][4]}} & adder_10b_for_nxt_cycle_s1_qds_spec_0[4][9:1])
| ({(9){nxt_rt_dig_0[1][3]}} & adder_10b_for_nxt_cycle_s1_qds_spec_0[3][9:1])
| ({(9){nxt_rt_dig_0[1][2]}} & adder_10b_for_nxt_cycle_s1_qds_spec_0[2][9:1])
| ({(9){nxt_rt_dig_0[1][1]}} & adder_10b_for_nxt_cycle_s1_qds_spec_0[1][9:1])
| ({(9){nxt_rt_dig_0[1][0]}} & adder_10b_for_nxt_cycle_s1_qds_spec_0[0][9:1]);

assign adder_9b_res_for_nxt_cycle_s1_qds_1_o = 
  ({(9){nxt_rt_dig_1[1][4]}} & adder_10b_for_nxt_cycle_s1_qds_spec_1[4][9:1])
| ({(9){nxt_rt_dig_1[1][3]}} & adder_10b_for_nxt_cycle_s1_qds_spec_1[3][9:1])
| ({(9){nxt_rt_dig_1[1][2]}} & adder_10b_for_nxt_cycle_s1_qds_spec_1[2][9:1])
| ({(9){nxt_rt_dig_1[1][1]}} & adder_10b_for_nxt_cycle_s1_qds_spec_1[1][9:1])
| ({(9){nxt_rt_dig_1[1][0]}} & adder_10b_for_nxt_cycle_s1_qds_spec_1[0][9:1]);

assign adder_9b_res_for_nxt_cycle_s1_qds_2_o = 
  ({(9){nxt_rt_dig_2[1][4]}} & adder_10b_for_nxt_cycle_s1_qds_spec_2[4][9:1])
| ({(9){nxt_rt_dig_2[1][3]}} & adder_10b_for_nxt_cycle_s1_qds_spec_2[3][9:1])
| ({(9){nxt_rt_dig_2[1][2]}} & adder_10b_for_nxt_cycle_s1_qds_spec_2[2][9:1])
| ({(9){nxt_rt_dig_2[1][1]}} & adder_10b_for_nxt_cycle_s1_qds_spec_2[1][9:1])
| ({(9){nxt_rt_dig_2[1][0]}} & adder_10b_for_nxt_cycle_s1_qds_spec_2[0][9:1]);

assign adder_9b_res_for_nxt_cycle_s1_qds_3_o = 
  ({(9){nxt_rt_dig_3[1][4]}} & adder_10b_for_nxt_cycle_s1_qds_spec_3[4][9:1])
| ({(9){nxt_rt_dig_3[1][3]}} & adder_10b_for_nxt_cycle_s1_qds_spec_3[3][9:1])
| ({(9){nxt_rt_dig_3[1][2]}} & adder_10b_for_nxt_cycle_s1_qds_spec_3[2][9:1])
| ({(9){nxt_rt_dig_3[1][1]}} & adder_10b_for_nxt_cycle_s1_qds_spec_3[1][9:1])
| ({(9){nxt_rt_dig_3[1][0]}} & adder_10b_for_nxt_cycle_s1_qds_spec_3[0][9:1]);



assign m_neg_1_to_nxt_cycle_0_o = 
  ({(7){nxt_rt_dig_0[1][4]}} & m_neg_1_spec_s1_0[4])
| ({(7){nxt_rt_dig_0[1][3]}} & m_neg_1_spec_s1_0[3])
| ({(7){nxt_rt_dig_0[1][2]}} & m_neg_1_spec_s1_0[2])
| ({(7){nxt_rt_dig_0[1][1]}} & m_neg_1_spec_s1_0[1])
| ({(7){nxt_rt_dig_0[1][0]}} & m_neg_1_spec_s1_0[0]);

assign m_neg_1_to_nxt_cycle_1_o = 
  ({(7){nxt_rt_dig_1[1][4]}} & m_neg_1_spec_s1_1[4])
| ({(7){nxt_rt_dig_1[1][3]}} & m_neg_1_spec_s1_1[3])
| ({(7){nxt_rt_dig_1[1][2]}} & m_neg_1_spec_s1_1[2])
| ({(7){nxt_rt_dig_1[1][1]}} & m_neg_1_spec_s1_1[1])
| ({(7){nxt_rt_dig_1[1][0]}} & m_neg_1_spec_s1_1[0]);

assign m_neg_1_to_nxt_cycle_2_o = 
  ({(7){nxt_rt_dig_2[1][4]}} & m_neg_1_spec_s1_2[4])
| ({(7){nxt_rt_dig_2[1][3]}} & m_neg_1_spec_s1_2[3])
| ({(7){nxt_rt_dig_2[1][2]}} & m_neg_1_spec_s1_2[2])
| ({(7){nxt_rt_dig_2[1][1]}} & m_neg_1_spec_s1_2[1])
| ({(7){nxt_rt_dig_2[1][0]}} & m_neg_1_spec_s1_2[0]);

assign m_neg_1_to_nxt_cycle_3_o = 
  ({(7){nxt_rt_dig_3[1][4]}} & m_neg_1_spec_s1_3[4])
| ({(7){nxt_rt_dig_3[1][3]}} & m_neg_1_spec_s1_3[3])
| ({(7){nxt_rt_dig_3[1][2]}} & m_neg_1_spec_s1_3[2])
| ({(7){nxt_rt_dig_3[1][1]}} & m_neg_1_spec_s1_3[1])
| ({(7){nxt_rt_dig_3[1][0]}} & m_neg_1_spec_s1_3[0]);

assign m_neg_0_to_nxt_cycle_0_o = 
  ({(7){nxt_rt_dig_0[1][4]}} & m_neg_0_spec_s1_0[4])
| ({(7){nxt_rt_dig_0[1][3]}} & m_neg_0_spec_s1_0[3])
| ({(7){nxt_rt_dig_0[1][2]}} & m_neg_0_spec_s1_0[2])
| ({(7){nxt_rt_dig_0[1][1]}} & m_neg_0_spec_s1_0[1])
| ({(7){nxt_rt_dig_0[1][0]}} & m_neg_0_spec_s1_0[0]);

assign m_neg_0_to_nxt_cycle_1_o = 
  ({(7){nxt_rt_dig_1[1][4]}} & m_neg_0_spec_s1_1[4])
| ({(7){nxt_rt_dig_1[1][3]}} & m_neg_0_spec_s1_1[3])
| ({(7){nxt_rt_dig_1[1][2]}} & m_neg_0_spec_s1_1[2])
| ({(7){nxt_rt_dig_1[1][1]}} & m_neg_0_spec_s1_1[1])
| ({(7){nxt_rt_dig_1[1][0]}} & m_neg_0_spec_s1_1[0]);

assign m_neg_0_to_nxt_cycle_2_o = 
  ({(7){nxt_rt_dig_2[1][4]}} & m_neg_0_spec_s1_2[4])
| ({(7){nxt_rt_dig_2[1][3]}} & m_neg_0_spec_s1_2[3])
| ({(7){nxt_rt_dig_2[1][2]}} & m_neg_0_spec_s1_2[2])
| ({(7){nxt_rt_dig_2[1][1]}} & m_neg_0_spec_s1_2[1])
| ({(7){nxt_rt_dig_2[1][0]}} & m_neg_0_spec_s1_2[0]);

assign m_neg_0_to_nxt_cycle_3_o = 
  ({(7){nxt_rt_dig_3[1][4]}} & m_neg_0_spec_s1_3[4])
| ({(7){nxt_rt_dig_3[1][3]}} & m_neg_0_spec_s1_3[3])
| ({(7){nxt_rt_dig_3[1][2]}} & m_neg_0_spec_s1_3[2])
| ({(7){nxt_rt_dig_3[1][1]}} & m_neg_0_spec_s1_3[1])
| ({(7){nxt_rt_dig_3[1][0]}} & m_neg_0_spec_s1_3[0]);

assign m_pos_1_to_nxt_cycle_0_o = 
  ({(7){nxt_rt_dig_0[1][4]}} & m_pos_1_spec_s1_0[4])
| ({(7){nxt_rt_dig_0[1][3]}} & m_pos_1_spec_s1_0[3])
| ({(7){nxt_rt_dig_0[1][2]}} & m_pos_1_spec_s1_0[2])
| ({(7){nxt_rt_dig_0[1][1]}} & m_pos_1_spec_s1_0[1])
| ({(7){nxt_rt_dig_0[1][0]}} & m_pos_1_spec_s1_0[0]);

assign m_pos_1_to_nxt_cycle_1_o = 
  ({(7){nxt_rt_dig_1[1][4]}} & m_pos_1_spec_s1_1[4])
| ({(7){nxt_rt_dig_1[1][3]}} & m_pos_1_spec_s1_1[3])
| ({(7){nxt_rt_dig_1[1][2]}} & m_pos_1_spec_s1_1[2])
| ({(7){nxt_rt_dig_1[1][1]}} & m_pos_1_spec_s1_1[1])
| ({(7){nxt_rt_dig_1[1][0]}} & m_pos_1_spec_s1_1[0]);

assign m_pos_1_to_nxt_cycle_2_o = 
  ({(7){nxt_rt_dig_2[1][4]}} & m_pos_1_spec_s1_2[4])
| ({(7){nxt_rt_dig_2[1][3]}} & m_pos_1_spec_s1_2[3])
| ({(7){nxt_rt_dig_2[1][2]}} & m_pos_1_spec_s1_2[2])
| ({(7){nxt_rt_dig_2[1][1]}} & m_pos_1_spec_s1_2[1])
| ({(7){nxt_rt_dig_2[1][0]}} & m_pos_1_spec_s1_2[0]);

assign m_pos_1_to_nxt_cycle_3_o = 
  ({(7){nxt_rt_dig_3[1][4]}} & m_pos_1_spec_s1_3[4])
| ({(7){nxt_rt_dig_3[1][3]}} & m_pos_1_spec_s1_3[3])
| ({(7){nxt_rt_dig_3[1][2]}} & m_pos_1_spec_s1_3[2])
| ({(7){nxt_rt_dig_3[1][1]}} & m_pos_1_spec_s1_3[1])
| ({(7){nxt_rt_dig_3[1][0]}} & m_pos_1_spec_s1_3[0]);

assign m_pos_2_to_nxt_cycle_0_o = 
  ({(7){nxt_rt_dig_0[1][4]}} & m_pos_2_spec_s1_0[4])
| ({(7){nxt_rt_dig_0[1][3]}} & m_pos_2_spec_s1_0[3])
| ({(7){nxt_rt_dig_0[1][2]}} & m_pos_2_spec_s1_0[2])
| ({(7){nxt_rt_dig_0[1][1]}} & m_pos_2_spec_s1_0[1])
| ({(7){nxt_rt_dig_0[1][0]}} & m_pos_2_spec_s1_0[0]);

assign m_pos_2_to_nxt_cycle_1_o = 
  ({(7){nxt_rt_dig_1[1][4]}} & m_pos_2_spec_s1_1[4])
| ({(7){nxt_rt_dig_1[1][3]}} & m_pos_2_spec_s1_1[3])
| ({(7){nxt_rt_dig_1[1][2]}} & m_pos_2_spec_s1_1[2])
| ({(7){nxt_rt_dig_1[1][1]}} & m_pos_2_spec_s1_1[1])
| ({(7){nxt_rt_dig_1[1][0]}} & m_pos_2_spec_s1_1[0]);

assign m_pos_2_to_nxt_cycle_2_o = 
  ({(7){nxt_rt_dig_2[1][4]}} & m_pos_2_spec_s1_2[4])
| ({(7){nxt_rt_dig_2[1][3]}} & m_pos_2_spec_s1_2[3])
| ({(7){nxt_rt_dig_2[1][2]}} & m_pos_2_spec_s1_2[2])
| ({(7){nxt_rt_dig_2[1][1]}} & m_pos_2_spec_s1_2[1])
| ({(7){nxt_rt_dig_2[1][0]}} & m_pos_2_spec_s1_2[0]);

assign m_pos_2_to_nxt_cycle_3_o = 
  ({(7){nxt_rt_dig_3[1][4]}} & m_pos_2_spec_s1_3[4])
| ({(7){nxt_rt_dig_3[1][3]}} & m_pos_2_spec_s1_3[3])
| ({(7){nxt_rt_dig_3[1][2]}} & m_pos_2_spec_s1_3[2])
| ({(7){nxt_rt_dig_3[1][1]}} & m_pos_2_spec_s1_3[1])
| ({(7){nxt_rt_dig_3[1][0]}} & m_pos_2_spec_s1_3[0]);

// ================================================================================================================================================
// Update root after stage[1].qds is finished
// ================================================================================================================================================
assign nxt_rt_0[1] = 
  ({(F64_FULL_RT_W){nxt_rt_dig_0[1][4]}} & nxt_rt_spec_s1_0[4])
| ({(F64_FULL_RT_W){nxt_rt_dig_0[1][3]}} & nxt_rt_spec_s1_0[3])
| ({(F64_FULL_RT_W){nxt_rt_dig_0[1][2]}} & nxt_rt_spec_s1_0[2])
| ({(F64_FULL_RT_W){nxt_rt_dig_0[1][1]}} & nxt_rt_spec_s1_0[1])
| ({(F64_FULL_RT_W){nxt_rt_dig_0[1][0]}} & nxt_rt_spec_s1_0[0]);

assign nxt_rt_m1_0[1] = 
  ({(F64_FULL_RT_W){nxt_rt_dig_0[1][4]}} & (nxt_rt_m1_0[0] | mask_rt_m1_neg_2[1]))
| ({(F64_FULL_RT_W){nxt_rt_dig_0[1][3]}} & (nxt_rt_m1_0[0] | mask_rt_m1_neg_1[1]))
| ({(F64_FULL_RT_W){nxt_rt_dig_0[1][2]}} & (nxt_rt_m1_0[0] | mask_rt_m1_neg_0[1]))
| ({(F64_FULL_RT_W){nxt_rt_dig_0[1][1]}} & nxt_rt_0[0])
| ({(F64_FULL_RT_W){nxt_rt_dig_0[1][0]}} & (nxt_rt_0[0]    | mask_rt_m1_pos_2[1]));

assign nxt_rt_1[1] = 
  ({(F32_FULL_RT_W){nxt_rt_dig_1[1][4]}} & nxt_rt_spec_s1_1[4])
| ({(F32_FULL_RT_W){nxt_rt_dig_1[1][3]}} & nxt_rt_spec_s1_1[3])
| ({(F32_FULL_RT_W){nxt_rt_dig_1[1][2]}} & nxt_rt_spec_s1_1[2])
| ({(F32_FULL_RT_W){nxt_rt_dig_1[1][1]}} & nxt_rt_spec_s1_1[1])
| ({(F32_FULL_RT_W){nxt_rt_dig_1[1][0]}} & nxt_rt_spec_s1_1[0]);

assign nxt_rt_m1_1[1] = 
  ({(F32_FULL_RT_W){nxt_rt_dig_1[1][4]}} & (nxt_rt_m1_1[0] | mask_rt_m1_neg_2[1][F64_FULL_RT_W-1 -: F32_FULL_RT_W]))
| ({(F32_FULL_RT_W){nxt_rt_dig_1[1][3]}} & (nxt_rt_m1_1[0] | mask_rt_m1_neg_1[1][F64_FULL_RT_W-1 -: F32_FULL_RT_W]))
| ({(F32_FULL_RT_W){nxt_rt_dig_1[1][2]}} & (nxt_rt_m1_1[0] | mask_rt_m1_neg_0[1][F64_FULL_RT_W-1 -: F32_FULL_RT_W]))
| ({(F32_FULL_RT_W){nxt_rt_dig_1[1][1]}} & nxt_rt_1[0])
| ({(F32_FULL_RT_W){nxt_rt_dig_1[1][0]}} & (nxt_rt_1[0]    | mask_rt_m1_pos_2[1][F64_FULL_RT_W-1 -: F32_FULL_RT_W]));

assign nxt_rt_2[1] = 
  ({(F16_FULL_RT_W){nxt_rt_dig_2[1][4]}} & nxt_rt_spec_s1_2[4])
| ({(F16_FULL_RT_W){nxt_rt_dig_2[1][3]}} & nxt_rt_spec_s1_2[3])
| ({(F16_FULL_RT_W){nxt_rt_dig_2[1][2]}} & nxt_rt_spec_s1_2[2])
| ({(F16_FULL_RT_W){nxt_rt_dig_2[1][1]}} & nxt_rt_spec_s1_2[1])
| ({(F16_FULL_RT_W){nxt_rt_dig_2[1][0]}} & nxt_rt_spec_s1_2[0]);

assign nxt_rt_m1_2[1] = 
  ({(F16_FULL_RT_W){nxt_rt_dig_2[1][4]}} & (nxt_rt_m1_2[0] | mask_rt_m1_neg_2[1][F64_FULL_RT_W-1 -: F16_FULL_RT_W]))
| ({(F16_FULL_RT_W){nxt_rt_dig_2[1][3]}} & (nxt_rt_m1_2[0] | mask_rt_m1_neg_1[1][F64_FULL_RT_W-1 -: F16_FULL_RT_W]))
| ({(F16_FULL_RT_W){nxt_rt_dig_2[1][2]}} & (nxt_rt_m1_2[0] | mask_rt_m1_neg_0[1][F64_FULL_RT_W-1 -: F16_FULL_RT_W]))
| ({(F16_FULL_RT_W){nxt_rt_dig_2[1][1]}} & nxt_rt_2[0])
| ({(F16_FULL_RT_W){nxt_rt_dig_2[1][0]}} & (nxt_rt_2[0]    | mask_rt_m1_pos_2[1][F64_FULL_RT_W-1 -: F16_FULL_RT_W]));

assign nxt_rt_3[1] = 
  ({(F16_FULL_RT_W){nxt_rt_dig_3[1][4]}} & nxt_rt_spec_s1_3[4])
| ({(F16_FULL_RT_W){nxt_rt_dig_3[1][3]}} & nxt_rt_spec_s1_3[3])
| ({(F16_FULL_RT_W){nxt_rt_dig_3[1][2]}} & nxt_rt_spec_s1_3[2])
| ({(F16_FULL_RT_W){nxt_rt_dig_3[1][1]}} & nxt_rt_spec_s1_3[1])
| ({(F16_FULL_RT_W){nxt_rt_dig_3[1][0]}} & nxt_rt_spec_s1_3[0]);

assign nxt_rt_m1_3[1] = 
  ({(F16_FULL_RT_W){nxt_rt_dig_3[1][4]}} & (nxt_rt_m1_3[0] | mask_rt_m1_neg_2[1][F64_FULL_RT_W-1 -: F16_FULL_RT_W]))
| ({(F16_FULL_RT_W){nxt_rt_dig_3[1][3]}} & (nxt_rt_m1_3[0] | mask_rt_m1_neg_1[1][F64_FULL_RT_W-1 -: F16_FULL_RT_W]))
| ({(F16_FULL_RT_W){nxt_rt_dig_3[1][2]}} & (nxt_rt_m1_3[0] | mask_rt_m1_neg_0[1][F64_FULL_RT_W-1 -: F16_FULL_RT_W]))
| ({(F16_FULL_RT_W){nxt_rt_dig_3[1][1]}} & nxt_rt_3[0])
| ({(F16_FULL_RT_W){nxt_rt_dig_3[1][0]}} & (nxt_rt_3[0]    | mask_rt_m1_pos_2[1][F64_FULL_RT_W-1 -: F16_FULL_RT_W]));


// MSB.idx is 55:
// rt_q[55: 2]: For f64_0
// rt_q[55:30]: For f32_0
// rt_q[55:42]: For f16_0
// MSB.idx is 41:
// rt_q[41:28]: For f16_2
// MSB.idx is 27:
// rt_q[27: 2]: For f32_1
// rt_q[27:14]: For f16_1
// MSB.idx is 13:
// rt_q[13: 0]: For f16_3

// MSB.idx is 52:
// rt_m1_q[52: 0]: For f64_0
// rt_m1_q[52:28]: For f32_0
// rt_m1_q[52:40]: For f16_0
// MSB.idx is 39:
// rt_m1_q[39:27]: For f16_2
// MSB.idx is 26:
// rt_m1_q[26: 2]: For f32_1
// rt_m1_q[26:14]: For f16_1
// MSB.idx is 13:
// rt_m1_q[13: 1]: For f16_3

assign nxt_rt_o = 
  ({(56){fp_fmt_i[0]}} & {
	nxt_rt_0[1][53:40],
	nxt_rt_2[1][13:0],
	nxt_rt_1[1][25:12],
	nxt_rt_3[1][13:0]
})
| ({(56){fp_fmt_i[1]}} & {nxt_rt_0[1][53:28], 2'b0, nxt_rt_1[1][25:0], 2'b0})
| ({(56){fp_fmt_i[2]}} & {nxt_rt_0[1][53:0], 2'b0});

assign nxt_rt_m1_o = 
  ({(53){fp_fmt_i[0]}} & {
	nxt_rt_m1_0[1][52:40],
	nxt_rt_m1_2[1][12:0],
	nxt_rt_m1_1[1][24:12],
	nxt_rt_m1_3[1][12:0],
	1'b0
})
| ({(53){fp_fmt_i[1]}} & {nxt_rt_m1_0[1][52:28], 1'b0, nxt_rt_m1_1[1][24:0], 2'b0})
| ({(53){fp_fmt_i[2]}} & {nxt_rt_m1_0[1][52:0]});



assign nxt_f_r_s_0[1] = 
  ({(F64_REM_W){nxt_rt_dig_0[1][4]}} & nxt_f_r_s_spec_s1_0[4])
| ({(F64_REM_W){nxt_rt_dig_0[1][3]}} & nxt_f_r_s_spec_s1_0[3])
| ({(F64_REM_W){nxt_rt_dig_0[1][2]}} & nxt_f_r_s_spec_s1_0[2])
| ({(F64_REM_W){nxt_rt_dig_0[1][1]}} & nxt_f_r_s_spec_s1_0[1])
| ({(F64_REM_W){nxt_rt_dig_0[1][0]}} & nxt_f_r_s_spec_s1_0[0]);

assign nxt_f_r_s_1[1] = 
  ({(F32_REM_W){nxt_rt_dig_1[1][4]}} & nxt_f_r_s_spec_s1_1[4])
| ({(F32_REM_W){nxt_rt_dig_1[1][3]}} & nxt_f_r_s_spec_s1_1[3])
| ({(F32_REM_W){nxt_rt_dig_1[1][2]}} & nxt_f_r_s_spec_s1_1[2])
| ({(F32_REM_W){nxt_rt_dig_1[1][1]}} & nxt_f_r_s_spec_s1_1[1])
| ({(F32_REM_W){nxt_rt_dig_1[1][0]}} & nxt_f_r_s_spec_s1_1[0]);

assign nxt_f_r_s_2[1] = 
  ({(F16_REM_W){nxt_rt_dig_2[1][4]}} & nxt_f_r_s_spec_s1_2[4])
| ({(F16_REM_W){nxt_rt_dig_2[1][3]}} & nxt_f_r_s_spec_s1_2[3])
| ({(F16_REM_W){nxt_rt_dig_2[1][2]}} & nxt_f_r_s_spec_s1_2[2])
| ({(F16_REM_W){nxt_rt_dig_2[1][1]}} & nxt_f_r_s_spec_s1_2[1])
| ({(F16_REM_W){nxt_rt_dig_2[1][0]}} & nxt_f_r_s_spec_s1_2[0]);

assign nxt_f_r_s_3[1] = 
  ({(F16_REM_W){nxt_rt_dig_3[1][4]}} & nxt_f_r_s_spec_s1_3[4])
| ({(F16_REM_W){nxt_rt_dig_3[1][3]}} & nxt_f_r_s_spec_s1_3[3])
| ({(F16_REM_W){nxt_rt_dig_3[1][2]}} & nxt_f_r_s_spec_s1_3[2])
| ({(F16_REM_W){nxt_rt_dig_3[1][1]}} & nxt_f_r_s_spec_s1_3[1])
| ({(F16_REM_W){nxt_rt_dig_3[1][0]}} & nxt_f_r_s_spec_s1_3[0]);


assign nxt_f_r_c_0[1] = 
  ({(F64_REM_W){nxt_rt_dig_0[1][4]}} & nxt_f_r_c_spec_s1_0[4])
| ({(F64_REM_W){nxt_rt_dig_0[1][3]}} & nxt_f_r_c_spec_s1_0[3])
| ({(F64_REM_W){nxt_rt_dig_0[1][2]}} & nxt_f_r_c_spec_s1_0[2])
| ({(F64_REM_W){nxt_rt_dig_0[1][1]}} & nxt_f_r_c_spec_s1_0[1])
| ({(F64_REM_W){nxt_rt_dig_0[1][0]}} & nxt_f_r_c_spec_s1_0[0]);

assign nxt_f_r_c_1[1] = 
  ({(F32_REM_W){nxt_rt_dig_1[1][4]}} & nxt_f_r_c_spec_s1_1[4])
| ({(F32_REM_W){nxt_rt_dig_1[1][3]}} & nxt_f_r_c_spec_s1_1[3])
| ({(F32_REM_W){nxt_rt_dig_1[1][2]}} & nxt_f_r_c_spec_s1_1[2])
| ({(F32_REM_W){nxt_rt_dig_1[1][1]}} & nxt_f_r_c_spec_s1_1[1])
| ({(F32_REM_W){nxt_rt_dig_1[1][0]}} & nxt_f_r_c_spec_s1_1[0]);

assign nxt_f_r_c_2[1] = 
  ({(F16_REM_W){nxt_rt_dig_2[1][4]}} & nxt_f_r_c_spec_s1_2[4])
| ({(F16_REM_W){nxt_rt_dig_2[1][3]}} & nxt_f_r_c_spec_s1_2[3])
| ({(F16_REM_W){nxt_rt_dig_2[1][2]}} & nxt_f_r_c_spec_s1_2[2])
| ({(F16_REM_W){nxt_rt_dig_2[1][1]}} & nxt_f_r_c_spec_s1_2[1])
| ({(F16_REM_W){nxt_rt_dig_2[1][0]}} & nxt_f_r_c_spec_s1_2[0]);

assign nxt_f_r_c_3[1] = 
  ({(F16_REM_W){nxt_rt_dig_3[1][4]}} & nxt_f_r_c_spec_s1_3[4])
| ({(F16_REM_W){nxt_rt_dig_3[1][3]}} & nxt_f_r_c_spec_s1_3[3])
| ({(F16_REM_W){nxt_rt_dig_3[1][2]}} & nxt_f_r_c_spec_s1_3[2])
| ({(F16_REM_W){nxt_rt_dig_3[1][1]}} & nxt_f_r_c_spec_s1_3[1])
| ({(F16_REM_W){nxt_rt_dig_3[1][0]}} & nxt_f_r_c_spec_s1_3[0]);

// For NOT_MERGED REM, the width is 64, the meaning of different positions:
// [63:48]
// f16: f16_0.rem[15: 0]
// f32: f32_0.rem[27:12]
// f64: f64_0.rem[55:40]
// [47:32]
// f16: f16_2.rem[15: 0]
// f32: f32_0.rem[11: 0], 4'b0
// f64: f64_0.rem[39:24]
// [31:16]
// f16: f16_1.rem[15: 0]
// f32: f32_1.rem[27:12]
// f64: f64_0.rem[23: 8]
// [15: 0]
// f16: f16_3.rem[15: 0]
// f32: f32_1.rem[11: 0], 4'b0
// f64: f64_0.rem[ 7: 0], 8'b0

assign nxt_f_r_s_o = 
  ({(REM_W){fp_fmt_i[0]}} & {
	nxt_f_r_s_0[1][F64_REM_W-1 -: F16_REM_W],
	nxt_f_r_s_2[1],
	nxt_f_r_s_1[1][F32_REM_W-1 -: F16_REM_W],
	nxt_f_r_s_3[1]
})
| ({(REM_W){fp_fmt_i[1]}} & {nxt_f_r_s_0[1][F64_REM_W-1 -: F32_REM_W], 4'b0, nxt_f_r_s_1[1], 4'b0})
| ({(REM_W){fp_fmt_i[2]}} & {nxt_f_r_s_0[1], 8'b0});

assign nxt_f_r_c_o = 
  ({(REM_W){fp_fmt_i[0]}} & {
	nxt_f_r_c_0[1][F64_REM_W-1 -: F16_REM_W],
	nxt_f_r_c_2[1],
	nxt_f_r_c_1[1][F32_REM_W-1 -: F16_REM_W],
	nxt_f_r_c_3[1]
})
| ({(REM_W){fp_fmt_i[1]}} & {nxt_f_r_c_0[1][F64_REM_W-1 -: F32_REM_W], 4'b0, nxt_f_r_c_1[1], 4'b0})
| ({(REM_W){fp_fmt_i[2]}} & {nxt_f_r_c_0[1], 8'b0});



endmodule

