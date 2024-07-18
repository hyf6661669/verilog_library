// ========================================================================================================
// File Name			: fsqrt_r16_block.sv
// Author				: HYF
// How to Contact		: hyf_sysu@qq.com
// Created Time    		: July 5th 2024, 16:39:24
// Last Modified Time   : July 16th 2024, 09:20:17
// ========================================================================================================
// Description	:
// Radix-16 SRT algorithm for the frac part of fpsqrt.
// Here I add more speculation to reduce the delay.
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

module fsqrt_r16_block #(
	// Put some parameters here, which can be changed by other modules
	parameter SRT_2ND_SPEC = 1,
	// Don't change the following value
	parameter REM_W = 2 + 54
)(
	input  logic [REM_W - 1:0]      f_r_s_i,
	input  logic [REM_W - 1:0]      f_r_c_i,
	input  logic [54 - 1:0]         root_i,
	input  logic [53 - 1:0]         root_m1_i,
	input  logic [ 7 - 1:0]         rem_msb_nxt_cycle_1st_srt_i,
	input  logic [ 9 - 1:0]         rem_msb_nxt_cycle_2nd_srt_i,
	input  logic [ 5 - 1:0]         m_n1_last_cycle_i,
	input  logic [ 4 - 1:0]         m_z0_last_cycle_i,
	input  logic [ 3 - 1:0]         m_p1_last_cycle_i,
	input  logic [ 4 - 1:0]         m_p2_last_cycle_i,
	input  logic [13 - 1:0]         mask_i,
	
	output logic [54 - 1:0]         root_1st_o,
	output logic [53 - 1:0]         root_m1_1st_o,
	output logic [54 - 1:0]         root_2nd_o,
	output logic [53 - 1:0]         root_m1_2nd_o,

	output logic [REM_W - 1:0]      f_r_s_1st_o,
	output logic [REM_W - 1:0]      f_r_c_1st_o,
	output logic [REM_W - 1:0]      f_r_s_2nd_o,
	output logic [REM_W - 1:0]      f_r_c_2nd_o,

	output logic [ 7 - 1:0]         rem_msb_nxt_cycle_1st_srt_o,
	output logic [ 9 - 1:0]         rem_msb_nxt_cycle_2nd_srt_o,
	output logic [ 7 - 1:0]         m_n1_nxt_cycle_1st_srt_o,
	output logic [ 7 - 1:0]         m_z0_nxt_cycle_1st_srt_o,
	output logic [ 7 - 1:0]         m_p1_nxt_cycle_1st_srt_o,
	output logic [ 7 - 1:0]         m_p2_nxt_cycle_1st_srt_o
);

// ================================================================================================================================================
// (local) parameters begin

// F64: We would get 4 * 13 + 2 = 54-bit root -> We need 54 + 2 = 56-bit REM.
localparam FSQRT_F64_REM_W = 2 + 54;
// F32: We would get 4 * 6 + 2 = 26-bit root -> We need 26 + 2 = 28-bit REM.
localparam FSQRT_F32_REM_W = 2 + 26;
// F16: We would get 4 * 3 + 2 = 14-bit root -> We need 14 + 2 = 16-bit REM.
localparam FSQRT_F16_REM_W = 2 + 14;

// F64: The root could be 55-bit in the early stage {1.00, 52'b0}, but finally the significant digits must be 54. (0.1, 53'bx)
localparam F64_FULL_ROOT_W = FSQRT_F64_REM_W - 1;
localparam F64_ROOT_W = F64_FULL_ROOT_W - 1;
// F32: The root could be 27-bit in the early stage {1.00, 24'b0}, but finally the significant digits must be 26. (0.1, 25'bx)
localparam F32_FULL_ROOT_W = FSQRT_F32_REM_W - 1;
localparam F32_ROOT_W = F32_FULL_ROOT_W - 1;
// F16: The root could be 15-bit in the early stage {1.00, 12'b0}, but finally the significant digits must be 14. (0.1, 13'bx)
localparam F16_FULL_ROOT_W = FSQRT_F16_REM_W - 1;
localparam F16_ROOT_W = F16_FULL_ROOT_W - 1;

// (local) parameters end
// ================================================================================================================================================

// ================================================================================================================================================
// signals begin

logic [F64_FULL_ROOT_W - 1:0] root_ext_last_cycle;
logic [F64_FULL_ROOT_W - 1:0] root_m1_ext_last_cycle;
 
logic [F64_FULL_ROOT_W - 1:0] root_ext_1st_root_dig_n2_1st;
logic [F64_FULL_ROOT_W - 1:0] root_ext_1st_root_dig_n1_1st;
logic [F64_FULL_ROOT_W - 1:0] root_ext_1st_root_dig_z0_1st;
logic [F64_FULL_ROOT_W - 1:0] root_ext_1st_root_dig_p1_1st;
logic [F64_FULL_ROOT_W - 1:0] root_ext_1st_root_dig_p2_1st;
logic [F64_FULL_ROOT_W - 1:0] root_ext_2nd_root_dig_n2_2nd;
logic [F64_FULL_ROOT_W - 1:0] root_ext_2nd_root_dig_n1_2nd;
logic [F64_FULL_ROOT_W - 1:0] root_ext_2nd_root_dig_z0_2nd;
logic [F64_FULL_ROOT_W - 1:0] root_ext_2nd_root_dig_p1_2nd;
logic [F64_FULL_ROOT_W - 1:0] root_ext_2nd_root_dig_p2_2nd;
logic [F64_FULL_ROOT_W - 1:0] root_ext_1st;
logic [F64_FULL_ROOT_W - 1:0] root_ext_2nd;

logic [F64_FULL_ROOT_W - 1:0] root_m1_ext_1st_root_dig_n2_1st;
logic [F64_FULL_ROOT_W - 1:0] root_m1_ext_1st_root_dig_n1_1st;
logic [F64_FULL_ROOT_W - 1:0] root_m1_ext_1st_root_dig_z0_1st;
logic [F64_FULL_ROOT_W - 1:0] root_m1_ext_1st_root_dig_p1_1st;
logic [F64_FULL_ROOT_W - 1:0] root_m1_ext_1st_root_dig_p2_1st;
logic [F64_FULL_ROOT_W - 1:0] root_m1_ext_2nd_root_dig_n2_2nd;
logic [F64_FULL_ROOT_W - 1:0] root_m1_ext_2nd_root_dig_n1_2nd;
logic [F64_FULL_ROOT_W - 1:0] root_m1_ext_2nd_root_dig_z0_2nd;
logic [F64_FULL_ROOT_W - 1:0] root_m1_ext_2nd_root_dig_p1_2nd;
logic [F64_FULL_ROOT_W - 1:0] root_m1_ext_2nd_root_dig_p2_2nd;
logic [F64_FULL_ROOT_W - 1:0] root_m1_ext_1st;
logic [F64_FULL_ROOT_W - 1:0] root_m1_ext_2nd;

logic root_dig_n2_1st;
logic root_dig_n1_1st;
logic root_dig_z0_1st;
logic root_dig_p1_1st;
logic root_dig_p2_1st;
logic root_dig_n2_2nd;
logic root_dig_n1_2nd;
logic root_dig_z0_2nd;
logic root_dig_p1_2nd;
logic root_dig_p2_2nd;

logic root_dig_n2_2nd_root_dig_n2_1st;
logic root_dig_n2_2nd_root_dig_n1_1st;
logic root_dig_n2_2nd_root_dig_z0_1st;
logic root_dig_n2_2nd_root_dig_p1_1st;
logic root_dig_n2_2nd_root_dig_p2_1st;

logic root_dig_n1_2nd_root_dig_n2_1st;
logic root_dig_n1_2nd_root_dig_n1_1st;
logic root_dig_n1_2nd_root_dig_z0_1st;
logic root_dig_n1_2nd_root_dig_p1_1st;
logic root_dig_n1_2nd_root_dig_p2_1st;

logic root_dig_z0_2nd_root_dig_n2_1st;
logic root_dig_z0_2nd_root_dig_n1_1st;
logic root_dig_z0_2nd_root_dig_z0_1st;
logic root_dig_z0_2nd_root_dig_p1_1st;
logic root_dig_z0_2nd_root_dig_p2_1st;

logic root_dig_p1_2nd_root_dig_n2_1st;
logic root_dig_p1_2nd_root_dig_n1_1st;
logic root_dig_p1_2nd_root_dig_z0_1st;
logic root_dig_p1_2nd_root_dig_p1_1st;
logic root_dig_p1_2nd_root_dig_p2_1st;

logic root_dig_p2_2nd_root_dig_n2_1st;
logic root_dig_p2_2nd_root_dig_n1_1st;
logic root_dig_p2_2nd_root_dig_z0_1st;
logic root_dig_p2_2nd_root_dig_p1_1st;
logic root_dig_p2_2nd_root_dig_p2_1st;

logic [REM_W - 1:0] csa_mask_ext_1st;
logic [REM_W - 1:0] csa_mask_ext_2nd;

logic [REM_W - 1:0] csa_mask_1st_root_dig_n2_1st;
logic [REM_W - 1:0] csa_mask_1st_root_dig_n1_1st;
logic [REM_W - 1:0] csa_mask_1st_root_dig_z0_1st;
logic [REM_W - 1:0] csa_mask_1st_root_dig_p1_1st;
logic [REM_W - 1:0] csa_mask_1st_root_dig_p2_1st;
logic [REM_W - 1:0] csa_mask_2nd_root_dig_n2_2nd;
logic [REM_W - 1:0] csa_mask_2nd_root_dig_n1_2nd;
logic [REM_W - 1:0] csa_mask_2nd_root_dig_z0_2nd;
logic [REM_W - 1:0] csa_mask_2nd_root_dig_p1_2nd;
logic [REM_W - 1:0] csa_mask_2nd_root_dig_p2_2nd;


logic [F64_FULL_ROOT_W-1:0] root_mask_ext_1st;
logic [F64_FULL_ROOT_W-1:0] root_mask_ext_2nd;
logic [F64_FULL_ROOT_W-1:0] root_mask_1st_root_dig_n2_1st;
logic [F64_FULL_ROOT_W-1:0] root_mask_1st_root_dig_n1_1st;
logic [F64_FULL_ROOT_W-1:0] root_mask_1st_root_dig_z0_1st;
logic [F64_FULL_ROOT_W-1:0] root_mask_1st_root_dig_p1_1st;
logic [F64_FULL_ROOT_W-1:0] root_mask_1st_root_dig_p2_1st;
logic [F64_FULL_ROOT_W-1:0] root_mask_2nd_root_dig_n2_2nd;
logic [F64_FULL_ROOT_W-1:0] root_mask_2nd_root_dig_n1_2nd;
logic [F64_FULL_ROOT_W-1:0] root_mask_2nd_root_dig_z0_2nd;
logic [F64_FULL_ROOT_W-1:0] root_mask_2nd_root_dig_p1_2nd;
logic [F64_FULL_ROOT_W-1:0] root_mask_2nd_root_dig_p2_2nd;
logic [F64_FULL_ROOT_W-1:0] root_m1_mask_1st_root_dig_n2_1st;
logic [F64_FULL_ROOT_W-1:0] root_m1_mask_1st_root_dig_n1_1st;
logic [F64_FULL_ROOT_W-1:0] root_m1_mask_1st_root_dig_z0_1st;
logic [F64_FULL_ROOT_W-1:0] root_m1_mask_1st_root_dig_p1_1st;
logic [F64_FULL_ROOT_W-1:0] root_m1_mask_1st_root_dig_p2_1st;
logic [F64_FULL_ROOT_W-1:0] root_m1_mask_2nd_root_dig_n2_2nd;
logic [F64_FULL_ROOT_W-1:0] root_m1_mask_2nd_root_dig_n1_2nd;
logic [F64_FULL_ROOT_W-1:0] root_m1_mask_2nd_root_dig_z0_2nd;
logic [F64_FULL_ROOT_W-1:0] root_m1_mask_2nd_root_dig_p1_2nd;
logic [F64_FULL_ROOT_W-1:0] root_m1_mask_2nd_root_dig_p2_2nd;


logic [REM_W - 1:0] f_r_s_1st;
logic [REM_W - 1:0] f_r_s_2nd;
logic [REM_W - 1:0] f_r_c_1st;
logic [REM_W - 1:0] f_r_c_2nd;

logic [REM_W - 1:0] f_r_s_1st_root_dig_n2_1st;
logic [REM_W - 1:0] f_r_s_1st_root_dig_n1_1st;
logic [REM_W - 1:0] f_r_s_1st_root_dig_z0_1st;
logic [REM_W - 1:0] f_r_s_1st_root_dig_p1_1st;
logic [REM_W - 1:0] f_r_s_1st_root_dig_p2_1st;
logic [REM_W - 1:0] f_r_s_2nd_root_dig_n2_2nd;
logic [REM_W - 1:0] f_r_s_2nd_root_dig_n1_2nd;
logic [REM_W - 1:0] f_r_s_2nd_root_dig_z0_2nd;
logic [REM_W - 1:0] f_r_s_2nd_root_dig_p1_2nd;
logic [REM_W - 1:0] f_r_s_2nd_root_dig_p2_2nd;
logic [REM_W - 1:0] f_r_c_1st_root_dig_n2_1st;
logic [REM_W - 1:0] f_r_c_1st_root_dig_n1_1st;
logic [REM_W - 1:0] f_r_c_1st_root_dig_z0_1st;
logic [REM_W - 1:0] f_r_c_1st_root_dig_p1_1st;
logic [REM_W - 1:0] f_r_c_1st_root_dig_p2_1st;
logic [REM_W - 1:0] f_r_c_2nd_root_dig_n2_2nd;
logic [REM_W - 1:0] f_r_c_2nd_root_dig_n1_2nd;
logic [REM_W - 1:0] f_r_c_2nd_root_dig_z0_2nd;
logic [REM_W - 1:0] f_r_c_2nd_root_dig_p1_2nd;
logic [REM_W - 1:0] f_r_c_2nd_root_dig_p2_2nd;

logic [REM_W - 1:0] csa_in_1st_root_dig_n2_1st;
logic [REM_W - 1:0] csa_in_1st_root_dig_n1_1st;
logic [REM_W - 1:0] csa_in_1st_root_dig_z0_1st;
logic [REM_W - 1:0] csa_in_1st_root_dig_p1_1st;
logic [REM_W - 1:0] csa_in_1st_root_dig_p2_1st;
logic [REM_W - 1:0] csa_in_2nd_root_dig_n2_2nd;
logic [REM_W - 1:0] csa_in_2nd_root_dig_n1_2nd;
logic [REM_W - 1:0] csa_in_2nd_root_dig_z0_2nd;
logic [REM_W - 1:0] csa_in_2nd_root_dig_p1_2nd;
logic [REM_W - 1:0] csa_in_2nd_root_dig_p2_2nd;


logic a0_1st_root_dig_n2_1st;
logic a0_1st_root_dig_n1_1st;
logic a0_1st_root_dig_z0_1st;
logic a0_1st_root_dig_p1_1st;
logic a0_1st_root_dig_p2_1st;
logic a0_2nd_root_dig_n2_2nd;
logic a0_2nd_root_dig_n1_2nd;
logic a0_2nd_root_dig_z0_2nd;
logic a0_2nd_root_dig_p1_2nd;
logic a0_2nd_root_dig_p2_2nd;

logic a2_1st_root_dig_n2_1st;
logic a2_1st_root_dig_n1_1st;
logic a2_1st_root_dig_z0_1st;
logic a2_1st_root_dig_p1_1st;
logic a2_1st_root_dig_p2_1st;
logic a2_2nd_root_dig_n2_2nd;
logic a2_2nd_root_dig_n1_2nd;
logic a2_2nd_root_dig_z0_2nd;
logic a2_2nd_root_dig_p1_2nd;
logic a2_2nd_root_dig_p2_2nd;

logic a3_1st_root_dig_n2_1st;
logic a3_1st_root_dig_n1_1st;
logic a3_1st_root_dig_z0_1st;
logic a3_1st_root_dig_p1_1st;
logic a3_1st_root_dig_p2_1st;
logic a3_2nd_root_dig_n2_2nd;
logic a3_2nd_root_dig_n1_2nd;
logic a3_2nd_root_dig_z0_2nd;
logic a3_2nd_root_dig_p1_2nd;
logic a3_2nd_root_dig_p2_2nd;

logic a4_1st_root_dig_n2_1st;
logic a4_1st_root_dig_n1_1st;
logic a4_1st_root_dig_z0_1st;
logic a4_1st_root_dig_p1_1st;
logic a4_1st_root_dig_p2_1st;
logic a4_2nd_root_dig_n2_2nd;
logic a4_2nd_root_dig_n1_2nd;
logic a4_2nd_root_dig_z0_2nd;
logic a4_2nd_root_dig_p1_2nd;
logic a4_2nd_root_dig_p2_2nd;

logic [7 - 1:0] m_n1_1st;
logic [7 - 1:0] m_z0_1st;
logic [7 - 1:0] m_p1_1st;
logic [7 - 1:0] m_p2_1st;
logic [7 - 1:0] m_n1_2nd;
logic [7 - 1:0] m_z0_2nd;
logic [7 - 1:0] m_p1_2nd;
logic [7 - 1:0] m_p2_2nd;

logic [7 - 1:0] m_n1_2nd_root_dig_n2_1st;
logic [7 - 1:0] m_n1_2nd_root_dig_n1_1st;
logic [7 - 1:0] m_n1_2nd_root_dig_z0_1st;
logic [7 - 1:0] m_n1_2nd_root_dig_p1_1st;
logic [7 - 1:0] m_n1_2nd_root_dig_p2_1st;
logic [7 - 1:0] m_n1_nxt_cycle_root_dig_n2_2nd;
logic [7 - 1:0] m_n1_nxt_cycle_root_dig_n1_2nd;
logic [7 - 1:0] m_n1_nxt_cycle_root_dig_z0_2nd;
logic [7 - 1:0] m_n1_nxt_cycle_root_dig_p1_2nd;
logic [7 - 1:0] m_n1_nxt_cycle_root_dig_p2_2nd;

logic [7 - 1:0] m_z0_2nd_root_dig_n2_1st;
logic [7 - 1:0] m_z0_2nd_root_dig_n1_1st;
logic [7 - 1:0] m_z0_2nd_root_dig_z0_1st;
logic [7 - 1:0] m_z0_2nd_root_dig_p1_1st;
logic [7 - 1:0] m_z0_2nd_root_dig_p2_1st;
logic [7 - 1:0] m_z0_nxt_cycle_root_dig_n2_2nd;
logic [7 - 1:0] m_z0_nxt_cycle_root_dig_n1_2nd;
logic [7 - 1:0] m_z0_nxt_cycle_root_dig_z0_2nd;
logic [7 - 1:0] m_z0_nxt_cycle_root_dig_p1_2nd;
logic [7 - 1:0] m_z0_nxt_cycle_root_dig_p2_2nd;

logic [7 - 1:0] m_p1_2nd_root_dig_n2_1st;
logic [7 - 1:0] m_p1_2nd_root_dig_n1_1st;
logic [7 - 1:0] m_p1_2nd_root_dig_z0_1st;
logic [7 - 1:0] m_p1_2nd_root_dig_p1_1st;
logic [7 - 1:0] m_p1_2nd_root_dig_p2_1st;
logic [7 - 1:0] m_p1_nxt_cycle_root_dig_n2_2nd;
logic [7 - 1:0] m_p1_nxt_cycle_root_dig_n1_2nd;
logic [7 - 1:0] m_p1_nxt_cycle_root_dig_z0_2nd;
logic [7 - 1:0] m_p1_nxt_cycle_root_dig_p1_2nd;
logic [7 - 1:0] m_p1_nxt_cycle_root_dig_p2_2nd;

logic [7 - 1:0] m_p2_2nd_root_dig_n2_1st;
logic [7 - 1:0] m_p2_2nd_root_dig_n1_1st;
logic [7 - 1:0] m_p2_2nd_root_dig_z0_1st;
logic [7 - 1:0] m_p2_2nd_root_dig_p1_1st;
logic [7 - 1:0] m_p2_2nd_root_dig_p2_1st;
logic [7 - 1:0] m_p2_nxt_cycle_root_dig_n2_2nd;
logic [7 - 1:0] m_p2_nxt_cycle_root_dig_n1_2nd;
logic [7 - 1:0] m_p2_nxt_cycle_root_dig_z0_2nd;
logic [7 - 1:0] m_p2_nxt_cycle_root_dig_p1_2nd;
logic [7 - 1:0] m_p2_nxt_cycle_root_dig_p2_2nd;


logic [9 - 1:0] rem_msb_2nd_root_dig_n2_1st;
logic [9 - 1:0] rem_msb_2nd_root_dig_n1_1st;
logic [9 - 1:0] rem_msb_2nd_root_dig_z0_1st;
logic [9 - 1:0] rem_msb_2nd_root_dig_p1_1st;
logic [9 - 1:0] rem_msb_2nd_root_dig_p2_1st;
logic [7 - 1:0] rem_msb_2nd;

logic [9 - 1:0] rem_msb_nxt_cycle_1st_srt_root_dig_n2_2nd;
logic [9 - 1:0] rem_msb_nxt_cycle_1st_srt_root_dig_n1_2nd;
logic [9 - 1:0] rem_msb_nxt_cycle_1st_srt_root_dig_z0_2nd;
logic [9 - 1:0] rem_msb_nxt_cycle_1st_srt_root_dig_p1_2nd;
logic [9 - 1:0] rem_msb_nxt_cycle_1st_srt_root_dig_p2_2nd;

logic [10 - 1:0] rem_msb_nxt_cycle_2nd_srt_root_dig_n2_2nd;
logic [10 - 1:0] rem_msb_nxt_cycle_2nd_srt_root_dig_n1_2nd;
logic [10 - 1:0] rem_msb_nxt_cycle_2nd_srt_root_dig_z0_2nd;
logic [10 - 1:0] rem_msb_nxt_cycle_2nd_srt_root_dig_p1_2nd;
logic [10 - 1:0] rem_msb_nxt_cycle_2nd_srt_root_dig_p2_2nd;

// signals end
// ================================================================================================================================================

// Put the mask into the right position. CSA/OTFC operation is based on this "mask"
assign csa_mask_ext_1st = {
	2'b0,
	3'b0, mask_i[12],
	3'b0, mask_i[11],
	3'b0, mask_i[10],
	3'b0, mask_i[09],
	3'b0, mask_i[08],
	3'b0, mask_i[07],
	3'b0, mask_i[06],
	3'b0, mask_i[05],
	3'b0, mask_i[04],
	3'b0, mask_i[03],
	3'b0, mask_i[02],
	3'b0, mask_i[01],
	3'b0, mask_i[00],
	2'b0
};

// Gemerate csa_mask for different root_dit
assign csa_mask_1st_root_dig_n2_1st = (csa_mask_ext_1st << 2) | (csa_mask_ext_1st << 3);
assign csa_mask_1st_root_dig_n1_1st = csa_mask_ext_1st | (csa_mask_ext_1st << 1) | (csa_mask_ext_1st << 2);
assign csa_mask_1st_root_dig_z0_1st = '0;
assign csa_mask_1st_root_dig_p1_1st = csa_mask_ext_1st;
assign csa_mask_1st_root_dig_p2_1st = csa_mask_ext_1st << 2;

// Gemerate ofc_mask for different root_dit
assign root_mask_ext_1st = csa_mask_ext_1st[F64_FULL_ROOT_W - 1:0];

assign root_mask_1st_root_dig_n2_1st = root_mask_ext_1st << 1;
assign root_mask_1st_root_dig_n1_1st = root_mask_ext_1st | (root_mask_ext_1st << 1);
assign root_mask_1st_root_dig_z0_1st = '0;
assign root_mask_1st_root_dig_p1_1st = root_mask_ext_1st;
assign root_mask_1st_root_dig_p2_1st = root_mask_ext_1st << 1;

assign root_m1_mask_1st_root_dig_n2_1st = root_mask_ext_1st;
assign root_m1_mask_1st_root_dig_n1_1st = root_mask_ext_1st << 1;
assign root_m1_mask_1st_root_dig_z0_1st = root_mask_ext_1st | (root_mask_ext_1st << 1);
assign root_m1_mask_1st_root_dig_p1_1st = '0;
assign root_m1_mask_1st_root_dig_p2_1st = root_mask_ext_1st;

assign csa_mask_ext_2nd = csa_mask_ext_1st >> 2;
assign csa_mask_2nd_root_dig_n2_2nd = (csa_mask_ext_2nd << 2) | (csa_mask_ext_2nd << 3);
assign csa_mask_2nd_root_dig_n1_2nd = csa_mask_ext_2nd | (csa_mask_ext_2nd << 1) | (csa_mask_ext_2nd << 2);
assign csa_mask_2nd_root_dig_z0_2nd = '0;
assign csa_mask_2nd_root_dig_p1_2nd = csa_mask_ext_2nd;
assign csa_mask_2nd_root_dig_p2_2nd = csa_mask_ext_2nd << 2;

assign root_mask_ext_2nd = root_mask_ext_1st >> 2;

assign root_mask_2nd_root_dig_n2_2nd = root_mask_ext_2nd << 1;
assign root_mask_2nd_root_dig_n1_2nd = root_mask_ext_2nd | (root_mask_ext_2nd << 1);
assign root_mask_2nd_root_dig_z0_2nd = '0;
assign root_mask_2nd_root_dig_p1_2nd = root_mask_ext_2nd;
assign root_mask_2nd_root_dig_p2_2nd = root_mask_ext_2nd << 1;

assign root_m1_mask_2nd_root_dig_n2_2nd = root_mask_ext_2nd;
assign root_m1_mask_2nd_root_dig_n1_2nd = root_mask_ext_2nd << 1;
assign root_m1_mask_2nd_root_dig_z0_2nd = root_mask_ext_2nd | (root_mask_ext_2nd << 1);
assign root_m1_mask_2nd_root_dig_p1_2nd = '0;
assign root_m1_mask_2nd_root_dig_p2_2nd = root_mask_ext_2nd;

// ================================================================================================================================================
// 1ST SRT
// ================================================================================================================================================

assign root_ext_last_cycle = {~root_i[F64_FULL_ROOT_W - 2], root_i[F64_FULL_ROOT_W - 2:0]};
assign root_m1_ext_last_cycle = {1'b0, 1'b1, root_m1_i[F64_FULL_ROOT_W - 3:0]};

assign m_n1_1st = {2'b0, m_n1_last_cycle_i[4:0]};
assign m_z0_1st = {3'b0, m_z0_last_cycle_i[3:0]};
assign m_p1_1st = {4'b1111, m_p1_last_cycle_i[2:0]};
assign m_p2_1st = {2'b11, m_p2_last_cycle_i[3:0], 1'b0};

fsqrt_r4_qds u_fsqrt_r4_qds_1st (
	.rem_i              (rem_msb_nxt_cycle_1st_srt_i),
	.m_n1_i             (m_n1_1st),
	.m_z0_i             (m_z0_1st),
	.m_p1_i             (m_p1_1st),
	.m_p2_i             (m_p2_1st),
	.root_dig_n2_o      (root_dig_n2_1st),
	.root_dig_n1_o      (root_dig_n1_1st),
	.root_dig_z0_o      (root_dig_z0_1st),
	.root_dig_p1_o      (root_dig_p1_1st),
	.root_dig_p2_o      (root_dig_p2_1st)
);

assign csa_in_1st_root_dig_n2_1st = ({1'b0, root_m1_ext_last_cycle} << 2) | csa_mask_1st_root_dig_n2_1st;
assign csa_in_1st_root_dig_n1_1st = ({1'b0, root_m1_ext_last_cycle} << 1) | csa_mask_1st_root_dig_n1_1st;
assign csa_in_1st_root_dig_z0_1st = '0;
assign csa_in_1st_root_dig_p1_1st = ~(({1'b0, root_ext_last_cycle} << 1) | csa_mask_1st_root_dig_p1_1st);
assign csa_in_1st_root_dig_p2_1st = ~(({1'b0, root_ext_last_cycle} << 2) | csa_mask_1st_root_dig_p2_1st); 

assign f_r_s_1st_root_dig_n2_1st = 
  {f_r_s_i[(REM_W-1)-2:0], 2'b0}
^ {f_r_c_i[(REM_W-1)-2:0], 2'b0}
^ csa_in_1st_root_dig_n2_1st;
assign f_r_c_1st_root_dig_n2_1st = {
      ({f_r_s_i[(REM_W-1)-3:0], 2'b0} & {f_r_c_i[(REM_W-1)-3:0], 2'b0})
    | ({f_r_s_i[(REM_W-1)-3:0], 2'b0} & csa_in_1st_root_dig_n2_1st[(REM_W-1)-1:0])
    | ({f_r_c_i[(REM_W-1)-3:0], 2'b0} & csa_in_1st_root_dig_n2_1st[(REM_W-1)-1:0]),
    1'b0
};

assign f_r_s_1st_root_dig_n1_1st = 
  {f_r_s_i[(REM_W-1)-2:0], 2'b0}
^ {f_r_c_i[(REM_W-1)-2:0], 2'b0}
^ csa_in_1st_root_dig_n1_1st;
assign f_r_c_1st_root_dig_n1_1st = {
      ({f_r_s_i[(REM_W-1)-3:0], 2'b0} & {f_r_c_i[(REM_W-1)-3:0], 2'b0})
    | ({f_r_s_i[(REM_W-1)-3:0], 2'b0} & csa_in_1st_root_dig_n1_1st[(REM_W-1)-1:0])
    | ({f_r_c_i[(REM_W-1)-3:0], 2'b0} & csa_in_1st_root_dig_n1_1st[(REM_W-1)-1:0]),
    1'b0
};

assign f_r_s_1st_root_dig_z0_1st = {f_r_s_i[(REM_W-1)-2:0], 2'b0};
assign f_r_c_1st_root_dig_z0_1st = {f_r_c_i[(REM_W-1)-2:0], 2'b0};

assign f_r_s_1st_root_dig_p1_1st = 
  {f_r_s_i[(REM_W-1)-2:0], 2'b0}
^ {f_r_c_i[(REM_W-1)-2:0], 2'b0}
^ csa_in_1st_root_dig_p1_1st;
assign f_r_c_1st_root_dig_p1_1st = {
      ({f_r_s_i[(REM_W-1)-3:0], 2'b0} & {f_r_c_i[(REM_W-1)-3:0], 2'b0})
    | ({f_r_s_i[(REM_W-1)-3:0], 2'b0} & csa_in_1st_root_dig_p1_1st[(REM_W-1)-1:0])
    | ({f_r_c_i[(REM_W-1)-3:0], 2'b0} & csa_in_1st_root_dig_p1_1st[(REM_W-1)-1:0]),
    1'b1
};

assign f_r_s_1st_root_dig_p2_1st = 
  {f_r_s_i[(REM_W-1)-2:0], 2'b0}
^ {f_r_c_i[(REM_W-1)-2:0], 2'b0}
^ csa_in_1st_root_dig_p2_1st;
assign f_r_c_1st_root_dig_p2_1st = {
      ({f_r_s_i[(REM_W-1)-3:0], 2'b0} & {f_r_c_i[(REM_W-1)-3:0], 2'b0})
    | ({f_r_s_i[(REM_W-1)-3:0], 2'b0} & csa_in_1st_root_dig_p2_1st[(REM_W-1)-1:0])
    | ({f_r_c_i[(REM_W-1)-3:0], 2'b0} & csa_in_1st_root_dig_p2_1st[(REM_W-1)-1:0]),
    1'b1
};

// ========================================================
// Will these be faster ?

// assign rem_msb_2nd_root_dig_n2_1st[8:0] = f_r_s_i[(REM_W - 1) - 2 -: 9] + f_r_c_i[(REM_W - 1) - 2 -: 9] + csa_in_1st_root_dig_n2_1st[(REM_W - 1) -: 9];
// assign rem_msb_2nd_root_dig_n1_1st[8:0] = f_r_s_i[(REM_W - 1) - 2 -: 9] + f_r_c_i[(REM_W - 1) - 2 -: 9] + csa_in_1st_root_dig_n1_1st[(REM_W - 1) -: 9];
// assign rem_msb_2nd_root_dig_z0_1st[8:0] = f_r_s_i[(REM_W - 1) - 2 -: 9] + f_r_c_i[(REM_W - 1) - 2 -: 9];
// assign rem_msb_2nd_root_dig_p1_1st[8:0] = f_r_s_i[(REM_W - 1) - 2 -: 9] + f_r_c_i[(REM_W - 1) - 2 -: 9] + csa_in_1st_root_dig_p1_1st[(REM_W - 1) -: 9];
// assign rem_msb_2nd_root_dig_p2_1st[8:0] = f_r_s_i[(REM_W - 1) - 2 -: 9] + f_r_c_i[(REM_W - 1) - 2 -: 9] + csa_in_1st_root_dig_p2_1st[(REM_W - 1) -: 9];
// ========================================================

// ========================================================
// assign rem_msb_2nd_root_dig_n2_1st[8:0] = f_r_s_1st_root_dig_n2_1st[(REM_W - 1) -: 9] + f_r_c_1st_root_dig_n2_1st[(REM_W - 1) -: 9];
// assign rem_msb_2nd_root_dig_n1_1st[8:0] = f_r_s_1st_root_dig_n1_1st[(REM_W - 1) -: 9] + f_r_c_1st_root_dig_n1_1st[(REM_W - 1) -: 9];
// assign rem_msb_2nd_root_dig_z0_1st[8:0] = f_r_s_1st_root_dig_z0_1st[(REM_W - 1) -: 9] + f_r_c_1st_root_dig_z0_1st[(REM_W - 1) -: 9];
// assign rem_msb_2nd_root_dig_p1_1st[8:0] = f_r_s_1st_root_dig_p1_1st[(REM_W - 1) -: 9] + f_r_c_1st_root_dig_p1_1st[(REM_W - 1) -: 9];
// assign rem_msb_2nd_root_dig_p2_1st[8:0] = f_r_s_1st_root_dig_p2_1st[(REM_W - 1) -: 9] + f_r_c_1st_root_dig_p2_1st[(REM_W - 1) -: 9];
// ========================================================

assign rem_msb_2nd_root_dig_n2_1st[8:0] = rem_msb_nxt_cycle_2nd_srt_i + csa_in_1st_root_dig_n2_1st[(REM_W - 1) -: 9];
assign rem_msb_2nd_root_dig_n1_1st[8:0] = rem_msb_nxt_cycle_2nd_srt_i + csa_in_1st_root_dig_n1_1st[(REM_W - 1) -: 9];
assign rem_msb_2nd_root_dig_z0_1st[8:0] = rem_msb_nxt_cycle_2nd_srt_i;
assign rem_msb_2nd_root_dig_p1_1st[8:0] = rem_msb_nxt_cycle_2nd_srt_i + csa_in_1st_root_dig_p1_1st[(REM_W - 1) -: 9];
assign rem_msb_2nd_root_dig_p2_1st[8:0] = rem_msb_nxt_cycle_2nd_srt_i + csa_in_1st_root_dig_p2_1st[(REM_W - 1) -: 9];

assign root_ext_1st_root_dig_n2_1st = root_m1_ext_last_cycle | root_mask_1st_root_dig_n2_1st;
assign root_ext_1st_root_dig_n1_1st = root_m1_ext_last_cycle | root_mask_1st_root_dig_n1_1st;
assign root_ext_1st_root_dig_z0_1st = root_ext_last_cycle;
assign root_ext_1st_root_dig_p1_1st = root_ext_last_cycle | root_mask_1st_root_dig_p1_1st;
assign root_ext_1st_root_dig_p2_1st = root_ext_last_cycle | root_mask_1st_root_dig_p2_1st;

assign root_m1_ext_1st_root_dig_n2_1st = root_m1_ext_last_cycle | root_m1_mask_1st_root_dig_n2_1st;
assign root_m1_ext_1st_root_dig_n1_1st = root_m1_ext_last_cycle | root_m1_mask_1st_root_dig_n1_1st;
assign root_m1_ext_1st_root_dig_z0_1st = root_m1_ext_last_cycle | root_m1_mask_1st_root_dig_z0_1st;
assign root_m1_ext_1st_root_dig_p1_1st = root_ext_last_cycle;
assign root_m1_ext_1st_root_dig_p2_1st = root_ext_last_cycle | root_m1_mask_1st_root_dig_p2_1st;

assign a0_1st_root_dig_n2_1st = root_ext_1st_root_dig_n2_1st[F64_FULL_ROOT_W - 1];
assign a2_1st_root_dig_n2_1st = root_ext_1st_root_dig_n2_1st[F64_FULL_ROOT_W - 3];
assign a3_1st_root_dig_n2_1st = root_ext_1st_root_dig_n2_1st[F64_FULL_ROOT_W - 4];
assign a4_1st_root_dig_n2_1st = root_ext_1st_root_dig_n2_1st[F64_FULL_ROOT_W - 5];

assign a0_1st_root_dig_n1_1st = root_ext_1st_root_dig_n1_1st[F64_FULL_ROOT_W - 1];
assign a2_1st_root_dig_n1_1st = root_ext_1st_root_dig_n1_1st[F64_FULL_ROOT_W - 3];
assign a3_1st_root_dig_n1_1st = root_ext_1st_root_dig_n1_1st[F64_FULL_ROOT_W - 4];
assign a4_1st_root_dig_n1_1st = root_ext_1st_root_dig_n1_1st[F64_FULL_ROOT_W - 5];

assign a0_1st_root_dig_z0_1st = root_ext_1st_root_dig_z0_1st[F64_FULL_ROOT_W - 1];
assign a2_1st_root_dig_z0_1st = root_ext_1st_root_dig_z0_1st[F64_FULL_ROOT_W - 3];
assign a3_1st_root_dig_z0_1st = root_ext_1st_root_dig_z0_1st[F64_FULL_ROOT_W - 4];
assign a4_1st_root_dig_z0_1st = root_ext_1st_root_dig_z0_1st[F64_FULL_ROOT_W - 5];

assign a0_1st_root_dig_p1_1st = root_ext_1st_root_dig_p1_1st[F64_FULL_ROOT_W - 1];
assign a2_1st_root_dig_p1_1st = root_ext_1st_root_dig_p1_1st[F64_FULL_ROOT_W - 3];
assign a3_1st_root_dig_p1_1st = root_ext_1st_root_dig_p1_1st[F64_FULL_ROOT_W - 4];
assign a4_1st_root_dig_p1_1st = root_ext_1st_root_dig_p1_1st[F64_FULL_ROOT_W - 5];

assign a0_1st_root_dig_p2_1st = root_ext_1st_root_dig_p2_1st[F64_FULL_ROOT_W - 1];
assign a2_1st_root_dig_p2_1st = root_ext_1st_root_dig_p2_1st[F64_FULL_ROOT_W - 3];
assign a3_1st_root_dig_p2_1st = root_ext_1st_root_dig_p2_1st[F64_FULL_ROOT_W - 4];
assign a4_1st_root_dig_p2_1st = root_ext_1st_root_dig_p2_1st[F64_FULL_ROOT_W - 5];

fsqrt_r4_qds_constants_generator u_fsqrt_r4_qds_constants_generator_root_dig_n2_1st (
	.a0_i           (a0_1st_root_dig_n2_1st),
	.a2_i           (a2_1st_root_dig_n2_1st),
	.a3_i           (a3_1st_root_dig_n2_1st),
	.a4_i           (a4_1st_root_dig_n2_1st),
	.m_n1_o         (m_n1_2nd_root_dig_n2_1st),
	.m_z0_o         (m_z0_2nd_root_dig_n2_1st),
	.m_p1_o         (m_p1_2nd_root_dig_n2_1st),
	.m_p2_o         (m_p2_2nd_root_dig_n2_1st)
);

fsqrt_r4_qds_constants_generator u_fsqrt_r4_qds_constants_generator_root_dig_n1_1st (
	.a0_i           (a0_1st_root_dig_n1_1st),
	.a2_i           (a2_1st_root_dig_n1_1st),
	.a3_i           (a3_1st_root_dig_n1_1st),
	.a4_i           (a4_1st_root_dig_n1_1st),
	.m_n1_o         (m_n1_2nd_root_dig_n1_1st),
	.m_z0_o         (m_z0_2nd_root_dig_n1_1st),
	.m_p1_o         (m_p1_2nd_root_dig_n1_1st),
	.m_p2_o         (m_p2_2nd_root_dig_n1_1st)
);

fsqrt_r4_qds_constants_generator u_fsqrt_r4_qds_constants_generator_root_dig_z0_1st (
	.a0_i           (a0_1st_root_dig_z0_1st),
	.a2_i           (a2_1st_root_dig_z0_1st),
	.a3_i           (a3_1st_root_dig_z0_1st),
	.a4_i           (a4_1st_root_dig_z0_1st),
	.m_n1_o         (m_n1_2nd_root_dig_z0_1st),
	.m_z0_o         (m_z0_2nd_root_dig_z0_1st),
	.m_p1_o         (m_p1_2nd_root_dig_z0_1st),
	.m_p2_o         (m_p2_2nd_root_dig_z0_1st)
);

fsqrt_r4_qds_constants_generator u_fsqrt_r4_qds_constants_generator_root_dig_p1_1st (
	.a0_i           (a0_1st_root_dig_p1_1st),
	.a2_i           (a2_1st_root_dig_p1_1st),
	.a3_i           (a3_1st_root_dig_p1_1st),
	.a4_i           (a4_1st_root_dig_p1_1st),
	.m_n1_o         (m_n1_2nd_root_dig_p1_1st),
	.m_z0_o         (m_z0_2nd_root_dig_p1_1st),
	.m_p1_o         (m_p1_2nd_root_dig_p1_1st),
	.m_p2_o         (m_p2_2nd_root_dig_p1_1st)
);

fsqrt_r4_qds_constants_generator u_fsqrt_r4_qds_constants_generator_root_dig_p2_1st (
	.a0_i           (a0_1st_root_dig_p2_1st),
	.a2_i           (a2_1st_root_dig_p2_1st),
	.a3_i           (a3_1st_root_dig_p2_1st),
	.a4_i           (a4_1st_root_dig_p2_1st),
	.m_n1_o         (m_n1_2nd_root_dig_p2_1st),
	.m_z0_o         (m_z0_2nd_root_dig_p2_1st),
	.m_p1_o         (m_p1_2nd_root_dig_p2_1st),
	.m_p2_o         (m_p2_2nd_root_dig_p2_1st)
);


// ================================================================================================================================================
// 2ND SRT
// ================================================================================================================================================

assign root_ext_1st = 
  ({(F64_FULL_ROOT_W){root_dig_n2_1st}} & root_ext_1st_root_dig_n2_1st)
| ({(F64_FULL_ROOT_W){root_dig_n1_1st}} & root_ext_1st_root_dig_n1_1st)
| ({(F64_FULL_ROOT_W){root_dig_z0_1st}} & root_ext_1st_root_dig_z0_1st)
| ({(F64_FULL_ROOT_W){root_dig_p1_1st}} & root_ext_1st_root_dig_p1_1st)
| ({(F64_FULL_ROOT_W){root_dig_p2_1st}} & root_ext_1st_root_dig_p2_1st);
assign root_m1_ext_1st = 
  ({(F64_FULL_ROOT_W){root_dig_n2_1st}} & root_m1_ext_1st_root_dig_n2_1st)
| ({(F64_FULL_ROOT_W){root_dig_n1_1st}} & root_m1_ext_1st_root_dig_n1_1st)
| ({(F64_FULL_ROOT_W){root_dig_z0_1st}} & root_m1_ext_1st_root_dig_z0_1st)
| ({(F64_FULL_ROOT_W){root_dig_p1_1st}} & root_m1_ext_1st_root_dig_p1_1st)
| ({(F64_FULL_ROOT_W){root_dig_p2_1st}} & root_m1_ext_1st_root_dig_p2_1st);


assign m_n1_2nd = 
  ({(7){root_dig_n2_1st}} & m_n1_2nd_root_dig_n2_1st)
| ({(7){root_dig_n1_1st}} & m_n1_2nd_root_dig_n1_1st)
| ({(7){root_dig_z0_1st}} & m_n1_2nd_root_dig_z0_1st)
| ({(7){root_dig_p1_1st}} & m_n1_2nd_root_dig_p1_1st)
| ({(7){root_dig_p2_1st}} & m_n1_2nd_root_dig_p2_1st);
assign m_z0_2nd = 
  ({(7){root_dig_n2_1st}} & m_z0_2nd_root_dig_n2_1st)
| ({(7){root_dig_n1_1st}} & m_z0_2nd_root_dig_n1_1st)
| ({(7){root_dig_z0_1st}} & m_z0_2nd_root_dig_z0_1st)
| ({(7){root_dig_p1_1st}} & m_z0_2nd_root_dig_p1_1st)
| ({(7){root_dig_p2_1st}} & m_z0_2nd_root_dig_p2_1st);
assign m_p1_2nd = 
  ({(7){root_dig_n2_1st}} & m_p1_2nd_root_dig_n2_1st)
| ({(7){root_dig_n1_1st}} & m_p1_2nd_root_dig_n1_1st)
| ({(7){root_dig_z0_1st}} & m_p1_2nd_root_dig_z0_1st)
| ({(7){root_dig_p1_1st}} & m_p1_2nd_root_dig_p1_1st)
| ({(7){root_dig_p2_1st}} & m_p1_2nd_root_dig_p2_1st);
assign m_p2_2nd = 
  ({(7){root_dig_n2_1st}} & m_p2_2nd_root_dig_n2_1st)
| ({(7){root_dig_n1_1st}} & m_p2_2nd_root_dig_n1_1st)
| ({(7){root_dig_z0_1st}} & m_p2_2nd_root_dig_z0_1st)
| ({(7){root_dig_p1_1st}} & m_p2_2nd_root_dig_p1_1st)
| ({(7){root_dig_p2_1st}} & m_p2_2nd_root_dig_p2_1st);

generate
if(SRT_2ND_SPEC) begin

fsqrt_r4_qds u_fsqrt_r4_qds_2nd_root_dig_n2_1st (
	.rem_i              (rem_msb_2nd_root_dig_n2_1st[8:2]),
	.m_n1_i             (m_n1_2nd_root_dig_n2_1st),
	.m_z0_i             (m_z0_2nd_root_dig_n2_1st),
	.m_p1_i             (m_p1_2nd_root_dig_n2_1st),
	.m_p2_i             (m_p2_2nd_root_dig_n2_1st),
	.root_dig_n2_o      (root_dig_n2_2nd_root_dig_n2_1st),
	.root_dig_n1_o      (root_dig_n1_2nd_root_dig_n2_1st),
	.root_dig_z0_o      (root_dig_z0_2nd_root_dig_n2_1st),
	.root_dig_p1_o      (root_dig_p1_2nd_root_dig_n2_1st),
	.root_dig_p2_o      (root_dig_p2_2nd_root_dig_n2_1st)
);

fsqrt_r4_qds u_fsqrt_r4_qds_2nd_root_dig_n1_1st (
	.rem_i              (rem_msb_2nd_root_dig_n1_1st[8:2]),
	.m_n1_i             (m_n1_2nd_root_dig_n1_1st),
	.m_z0_i             (m_z0_2nd_root_dig_n1_1st),
	.m_p1_i             (m_p1_2nd_root_dig_n1_1st),
	.m_p2_i             (m_p2_2nd_root_dig_n1_1st),
	.root_dig_n2_o      (root_dig_n2_2nd_root_dig_n1_1st),
	.root_dig_n1_o      (root_dig_n1_2nd_root_dig_n1_1st),
	.root_dig_z0_o      (root_dig_z0_2nd_root_dig_n1_1st),
	.root_dig_p1_o      (root_dig_p1_2nd_root_dig_n1_1st),
	.root_dig_p2_o      (root_dig_p2_2nd_root_dig_n1_1st)
);

fsqrt_r4_qds u_fsqrt_r4_qds_2nd_root_dig_z0_1st (
	.rem_i              (rem_msb_2nd_root_dig_z0_1st[8:2]),
	.m_n1_i             (m_n1_2nd_root_dig_z0_1st),
	.m_z0_i             (m_z0_2nd_root_dig_z0_1st),
	.m_p1_i             (m_p1_2nd_root_dig_z0_1st),
	.m_p2_i             (m_p2_2nd_root_dig_z0_1st),
	.root_dig_n2_o      (root_dig_n2_2nd_root_dig_z0_1st),
	.root_dig_n1_o      (root_dig_n1_2nd_root_dig_z0_1st),
	.root_dig_z0_o      (root_dig_z0_2nd_root_dig_z0_1st),
	.root_dig_p1_o      (root_dig_p1_2nd_root_dig_z0_1st),
	.root_dig_p2_o      (root_dig_p2_2nd_root_dig_z0_1st)
);

fsqrt_r4_qds u_fsqrt_r4_qds_2nd_root_dig_p1_1st (
	.rem_i              (rem_msb_2nd_root_dig_p1_1st[8:2]),
	.m_n1_i             (m_n1_2nd_root_dig_p1_1st),
	.m_z0_i             (m_z0_2nd_root_dig_p1_1st),
	.m_p1_i             (m_p1_2nd_root_dig_p1_1st),
	.m_p2_i             (m_p2_2nd_root_dig_p1_1st),
	.root_dig_n2_o      (root_dig_n2_2nd_root_dig_p1_1st),
	.root_dig_n1_o      (root_dig_n1_2nd_root_dig_p1_1st),
	.root_dig_z0_o      (root_dig_z0_2nd_root_dig_p1_1st),
	.root_dig_p1_o      (root_dig_p1_2nd_root_dig_p1_1st),
	.root_dig_p2_o      (root_dig_p2_2nd_root_dig_p1_1st)
);

fsqrt_r4_qds u_fsqrt_r4_qds_2nd_root_dig_p2_1st (
	.rem_i              (rem_msb_2nd_root_dig_p2_1st[8:2]),
	.m_n1_i             (m_n1_2nd_root_dig_p2_1st),
	.m_z0_i             (m_z0_2nd_root_dig_p2_1st),
	.m_p1_i             (m_p1_2nd_root_dig_p2_1st),
	.m_p2_i             (m_p2_2nd_root_dig_p2_1st),
	.root_dig_n2_o      (root_dig_n2_2nd_root_dig_p2_1st),
	.root_dig_n1_o      (root_dig_n1_2nd_root_dig_p2_1st),
	.root_dig_z0_o      (root_dig_z0_2nd_root_dig_p2_1st),
	.root_dig_p1_o      (root_dig_p1_2nd_root_dig_p2_1st),
	.root_dig_p2_o      (root_dig_p2_2nd_root_dig_p2_1st)
);

assign root_dig_n2_2nd = 
  (root_dig_n2_1st & root_dig_n2_2nd_root_dig_n2_1st)
| (root_dig_n1_1st & root_dig_n2_2nd_root_dig_n1_1st)
| (root_dig_z0_1st & root_dig_n2_2nd_root_dig_z0_1st)
| (root_dig_p1_1st & root_dig_n2_2nd_root_dig_p1_1st)
| (root_dig_p2_1st & root_dig_n2_2nd_root_dig_p2_1st);

assign root_dig_n1_2nd = 
  (root_dig_n2_1st & root_dig_n1_2nd_root_dig_n2_1st)
| (root_dig_n1_1st & root_dig_n1_2nd_root_dig_n1_1st)
| (root_dig_z0_1st & root_dig_n1_2nd_root_dig_z0_1st)
| (root_dig_p1_1st & root_dig_n1_2nd_root_dig_p1_1st)
| (root_dig_p2_1st & root_dig_n1_2nd_root_dig_p2_1st);

assign root_dig_z0_2nd = 
  (root_dig_n2_1st & root_dig_z0_2nd_root_dig_n2_1st)
| (root_dig_n1_1st & root_dig_z0_2nd_root_dig_n1_1st)
| (root_dig_z0_1st & root_dig_z0_2nd_root_dig_z0_1st)
| (root_dig_p1_1st & root_dig_z0_2nd_root_dig_p1_1st)
| (root_dig_p2_1st & root_dig_z0_2nd_root_dig_p2_1st);

assign root_dig_p1_2nd = 
  (root_dig_n2_1st & root_dig_p1_2nd_root_dig_n2_1st)
| (root_dig_n1_1st & root_dig_p1_2nd_root_dig_n1_1st)
| (root_dig_z0_1st & root_dig_p1_2nd_root_dig_z0_1st)
| (root_dig_p1_1st & root_dig_p1_2nd_root_dig_p1_1st)
| (root_dig_p2_1st & root_dig_p1_2nd_root_dig_p2_1st);

assign root_dig_p2_2nd = 
  (root_dig_n2_1st & root_dig_p2_2nd_root_dig_n2_1st)
| (root_dig_n1_1st & root_dig_p2_2nd_root_dig_n1_1st)
| (root_dig_z0_1st & root_dig_p2_2nd_root_dig_z0_1st)
| (root_dig_p1_1st & root_dig_p2_2nd_root_dig_p1_1st)
| (root_dig_p2_1st & root_dig_p2_2nd_root_dig_p2_1st);

end else begin

assign rem_msb_2nd = 
  ({(7){root_dig_n2_1st}} & rem_msb_2nd_root_dig_n2_1st[8:2])
| ({(7){root_dig_n1_1st}} & rem_msb_2nd_root_dig_n1_1st[8:2])
| ({(7){root_dig_z0_1st}} & rem_msb_2nd_root_dig_z0_1st[8:2])
| ({(7){root_dig_p1_1st}} & rem_msb_2nd_root_dig_p1_1st[8:2])
| ({(7){root_dig_p2_1st}} & rem_msb_2nd_root_dig_p2_1st[8:2]);

fsqrt_r4_qds u_fsqrt_r4_qds_2nd (
	.rem_i              (rem_msb_2nd),
	.m_n1_i             (m_n1_2nd),
	.m_z0_i             (m_z0_2nd),
	.m_p1_i             (m_p1_2nd),
	.m_p2_i             (m_p2_2nd),
	.root_dig_n2_o      (root_dig_n2_2nd),
	.root_dig_n1_o      (root_dig_n1_2nd),
	.root_dig_z0_o      (root_dig_z0_2nd),
	.root_dig_p1_o      (root_dig_p1_2nd),
	.root_dig_p2_o      (root_dig_p2_2nd)
);

end
endgenerate




assign csa_in_2nd_root_dig_n2_2nd = ({1'b0, root_m1_ext_1st} << 2) | csa_mask_2nd_root_dig_n2_2nd;
assign csa_in_2nd_root_dig_n1_2nd = ({1'b0, root_m1_ext_1st} << 1) | csa_mask_2nd_root_dig_n1_2nd;
assign csa_in_2nd_root_dig_z0_2nd = '0;
assign csa_in_2nd_root_dig_p1_2nd = ~(({1'b0, root_ext_1st} << 1) | csa_mask_2nd_root_dig_p1_2nd);
assign csa_in_2nd_root_dig_p2_2nd = ~(({1'b0, root_ext_1st} << 2) | csa_mask_2nd_root_dig_p2_2nd); 

assign f_r_s_1st = 
  ({(REM_W){root_dig_n2_1st}} & f_r_s_1st_root_dig_n2_1st)
| ({(REM_W){root_dig_n1_1st}} & f_r_s_1st_root_dig_n1_1st)
| ({(REM_W){root_dig_z0_1st}} & f_r_s_1st_root_dig_z0_1st)
| ({(REM_W){root_dig_p1_1st}} & f_r_s_1st_root_dig_p1_1st)
| ({(REM_W){root_dig_p2_1st}} & f_r_s_1st_root_dig_p2_1st);
assign f_r_c_1st = 
  ({(REM_W){root_dig_n2_1st}} & f_r_c_1st_root_dig_n2_1st)
| ({(REM_W){root_dig_n1_1st}} & f_r_c_1st_root_dig_n1_1st)
| ({(REM_W){root_dig_z0_1st}} & f_r_c_1st_root_dig_z0_1st)
| ({(REM_W){root_dig_p1_1st}} & f_r_c_1st_root_dig_p1_1st)
| ({(REM_W){root_dig_p2_1st}} & f_r_c_1st_root_dig_p2_1st);


assign f_r_s_2nd_root_dig_n2_2nd = 
  {f_r_s_1st[(REM_W-1)-2:0], 2'b0}
^ {f_r_c_1st[(REM_W-1)-2:0], 2'b0}
^ csa_in_2nd_root_dig_n2_2nd;
assign f_r_c_2nd_root_dig_n2_2nd = {
      ({f_r_s_1st[(REM_W-1)-3:0], 2'b0} & {f_r_c_1st[(REM_W-1)-3:0], 2'b0})
    | ({f_r_s_1st[(REM_W-1)-3:0], 2'b0} & csa_in_2nd_root_dig_n2_2nd[(REM_W-1)-1:0])
    | ({f_r_c_1st[(REM_W-1)-3:0], 2'b0} & csa_in_2nd_root_dig_n2_2nd[(REM_W-1)-1:0]),
    1'b0
};

assign f_r_s_2nd_root_dig_n1_2nd = 
  {f_r_s_1st[(REM_W-1)-2:0], 2'b0}
^ {f_r_c_1st[(REM_W-1)-2:0], 2'b0}
^ csa_in_2nd_root_dig_n1_2nd;
assign f_r_c_2nd_root_dig_n1_2nd = {
      ({f_r_s_1st[(REM_W-1)-3:0], 2'b0} & {f_r_c_1st[(REM_W-1)-3:0], 2'b0})
    | ({f_r_s_1st[(REM_W-1)-3:0], 2'b0} & csa_in_2nd_root_dig_n1_2nd[(REM_W-1)-1:0])
    | ({f_r_c_1st[(REM_W-1)-3:0], 2'b0} & csa_in_2nd_root_dig_n1_2nd[(REM_W-1)-1:0]),
    1'b0
};

assign f_r_s_2nd_root_dig_z0_2nd = {f_r_s_1st[(REM_W-1)-2:0], 2'b0};
assign f_r_c_2nd_root_dig_z0_2nd = {f_r_c_1st[(REM_W-1)-2:0], 2'b0};

assign f_r_s_2nd_root_dig_p1_2nd = 
  {f_r_s_1st[(REM_W-1)-2:0], 2'b0}
^ {f_r_c_1st[(REM_W-1)-2:0], 2'b0}
^ csa_in_2nd_root_dig_p1_2nd;
assign f_r_c_2nd_root_dig_p1_2nd = {
      ({f_r_s_1st[(REM_W-1)-3:0], 2'b0} & {f_r_c_1st[(REM_W-1)-3:0], 2'b0})
    | ({f_r_s_1st[(REM_W-1)-3:0], 2'b0} & csa_in_2nd_root_dig_p1_2nd[(REM_W-1)-1:0])
    | ({f_r_c_1st[(REM_W-1)-3:0], 2'b0} & csa_in_2nd_root_dig_p1_2nd[(REM_W-1)-1:0]),
    1'b1
};

assign f_r_s_2nd_root_dig_p2_2nd = 
  {f_r_s_1st[(REM_W-1)-2:0], 2'b0}
^ {f_r_c_1st[(REM_W-1)-2:0], 2'b0}
^ csa_in_2nd_root_dig_p2_2nd;
assign f_r_c_2nd_root_dig_p2_2nd = {
      ({f_r_s_1st[(REM_W-1)-3:0], 2'b0} & {f_r_c_1st[(REM_W-1)-3:0], 2'b0})
    | ({f_r_s_1st[(REM_W-1)-3:0], 2'b0} & csa_in_2nd_root_dig_p2_2nd[(REM_W-1)-1:0])
    | ({f_r_c_1st[(REM_W-1)-3:0], 2'b0} & csa_in_2nd_root_dig_p2_2nd[(REM_W-1)-1:0]),
    1'b1
};

assign rem_msb_nxt_cycle_1st_srt_root_dig_n2_2nd = f_r_s_1st[(REM_W - 1) - 2 -: 9] + f_r_c_1st[(REM_W - 1) - 2 -: 9] + csa_in_2nd_root_dig_n2_2nd[(REM_W - 1) -: 9];
assign rem_msb_nxt_cycle_1st_srt_root_dig_n1_2nd = f_r_s_1st[(REM_W - 1) - 2 -: 9] + f_r_c_1st[(REM_W - 1) - 2 -: 9] + csa_in_2nd_root_dig_n1_2nd[(REM_W - 1) -: 9];
assign rem_msb_nxt_cycle_1st_srt_root_dig_z0_2nd = f_r_s_1st[(REM_W - 1) - 2 -: 9] + f_r_c_1st[(REM_W - 1) - 2 -: 9];
assign rem_msb_nxt_cycle_1st_srt_root_dig_p1_2nd = f_r_s_1st[(REM_W - 1) - 2 -: 9] + f_r_c_1st[(REM_W - 1) - 2 -: 9] + csa_in_2nd_root_dig_p1_2nd[(REM_W - 1) -: 9];
assign rem_msb_nxt_cycle_1st_srt_root_dig_p2_2nd = f_r_s_1st[(REM_W - 1) - 2 -: 9] + f_r_c_1st[(REM_W - 1) - 2 -: 9] + csa_in_2nd_root_dig_p2_2nd[(REM_W - 1) -: 9];

assign rem_msb_nxt_cycle_2nd_srt_root_dig_n2_2nd = f_r_s_1st[(REM_W - 1) - 2 - 2 -: 10] + f_r_c_1st[(REM_W - 1) - 2 - 2 -: 10] + csa_in_2nd_root_dig_n2_2nd[(REM_W - 1) - 2 -: 10];
assign rem_msb_nxt_cycle_2nd_srt_root_dig_n1_2nd = f_r_s_1st[(REM_W - 1) - 2 - 2 -: 10] + f_r_c_1st[(REM_W - 1) - 2 - 2 -: 10] + csa_in_2nd_root_dig_n1_2nd[(REM_W - 1) - 2 -: 10];
assign rem_msb_nxt_cycle_2nd_srt_root_dig_z0_2nd = f_r_s_1st[(REM_W - 1) - 2 - 2 -: 10] + f_r_c_1st[(REM_W - 1) - 2 - 2 -: 10];
assign rem_msb_nxt_cycle_2nd_srt_root_dig_p1_2nd = f_r_s_1st[(REM_W - 1) - 2 - 2 -: 10] + f_r_c_1st[(REM_W - 1) - 2 - 2 -: 10] + csa_in_2nd_root_dig_p1_2nd[(REM_W - 1) - 2 -: 10];
assign rem_msb_nxt_cycle_2nd_srt_root_dig_p2_2nd = f_r_s_1st[(REM_W - 1) - 2 - 2 -: 10] + f_r_c_1st[(REM_W - 1) - 2 - 2 -: 10] + csa_in_2nd_root_dig_p2_2nd[(REM_W - 1) - 2 -: 10];

assign root_ext_2nd_root_dig_n2_2nd = root_m1_ext_1st | root_mask_2nd_root_dig_n2_2nd;
assign root_ext_2nd_root_dig_n1_2nd = root_m1_ext_1st | root_mask_2nd_root_dig_n1_2nd;
assign root_ext_2nd_root_dig_z0_2nd = root_ext_1st;
assign root_ext_2nd_root_dig_p1_2nd = root_ext_1st | root_mask_2nd_root_dig_p1_2nd;
assign root_ext_2nd_root_dig_p2_2nd = root_ext_1st | root_mask_2nd_root_dig_p2_2nd;

assign root_m1_ext_2nd_root_dig_n2_2nd = root_m1_ext_1st | root_m1_mask_2nd_root_dig_n2_2nd;
assign root_m1_ext_2nd_root_dig_n1_2nd = root_m1_ext_1st | root_m1_mask_2nd_root_dig_n1_2nd;
assign root_m1_ext_2nd_root_dig_z0_2nd = root_m1_ext_1st | root_m1_mask_2nd_root_dig_z0_2nd;
assign root_m1_ext_2nd_root_dig_p1_2nd = root_ext_1st;
assign root_m1_ext_2nd_root_dig_p2_2nd = root_ext_1st | root_m1_mask_2nd_root_dig_p2_2nd;

assign a0_2nd_root_dig_n2_2nd = root_ext_2nd_root_dig_n2_2nd[F64_FULL_ROOT_W - 1];
assign a2_2nd_root_dig_n2_2nd = root_ext_2nd_root_dig_n2_2nd[F64_FULL_ROOT_W - 3];
assign a3_2nd_root_dig_n2_2nd = root_ext_2nd_root_dig_n2_2nd[F64_FULL_ROOT_W - 4];
assign a4_2nd_root_dig_n2_2nd = root_ext_2nd_root_dig_n2_2nd[F64_FULL_ROOT_W - 5];

assign a0_2nd_root_dig_n1_2nd = root_ext_2nd_root_dig_n1_2nd[F64_FULL_ROOT_W - 1];
assign a2_2nd_root_dig_n1_2nd = root_ext_2nd_root_dig_n1_2nd[F64_FULL_ROOT_W - 3];
assign a3_2nd_root_dig_n1_2nd = root_ext_2nd_root_dig_n1_2nd[F64_FULL_ROOT_W - 4];
assign a4_2nd_root_dig_n1_2nd = root_ext_2nd_root_dig_n1_2nd[F64_FULL_ROOT_W - 5];

assign a0_2nd_root_dig_z0_2nd = root_ext_2nd_root_dig_z0_2nd[F64_FULL_ROOT_W - 1];
assign a2_2nd_root_dig_z0_2nd = root_ext_2nd_root_dig_z0_2nd[F64_FULL_ROOT_W - 3];
assign a3_2nd_root_dig_z0_2nd = root_ext_2nd_root_dig_z0_2nd[F64_FULL_ROOT_W - 4];
assign a4_2nd_root_dig_z0_2nd = root_ext_2nd_root_dig_z0_2nd[F64_FULL_ROOT_W - 5];

assign a0_2nd_root_dig_p1_2nd = root_ext_2nd_root_dig_p1_2nd[F64_FULL_ROOT_W - 1];
assign a2_2nd_root_dig_p1_2nd = root_ext_2nd_root_dig_p1_2nd[F64_FULL_ROOT_W - 3];
assign a3_2nd_root_dig_p1_2nd = root_ext_2nd_root_dig_p1_2nd[F64_FULL_ROOT_W - 4];
assign a4_2nd_root_dig_p1_2nd = root_ext_2nd_root_dig_p1_2nd[F64_FULL_ROOT_W - 5];

assign a0_2nd_root_dig_p2_2nd = root_ext_2nd_root_dig_p2_2nd[F64_FULL_ROOT_W - 1];
assign a2_2nd_root_dig_p2_2nd = root_ext_2nd_root_dig_p2_2nd[F64_FULL_ROOT_W - 3];
assign a3_2nd_root_dig_p2_2nd = root_ext_2nd_root_dig_p2_2nd[F64_FULL_ROOT_W - 4];
assign a4_2nd_root_dig_p2_2nd = root_ext_2nd_root_dig_p2_2nd[F64_FULL_ROOT_W - 5];

fsqrt_r4_qds_constants_generator u_fsqrt_r4_qds_constants_generator_2nd_root_dig_n2_2nd (
	.a0_i           (a0_2nd_root_dig_n2_2nd),
	.a2_i           (a2_2nd_root_dig_n2_2nd),
	.a3_i           (a3_2nd_root_dig_n2_2nd),
	.a4_i           (a4_2nd_root_dig_n2_2nd),
	.m_n1_o         (m_n1_nxt_cycle_root_dig_n2_2nd),
	.m_z0_o         (m_z0_nxt_cycle_root_dig_n2_2nd),
	.m_p1_o         (m_p1_nxt_cycle_root_dig_n2_2nd),
	.m_p2_o         (m_p2_nxt_cycle_root_dig_n2_2nd)
);

fsqrt_r4_qds_constants_generator u_fsqrt_r4_qds_constants_generator_2nd_root_dig_n1_2nd (
	.a0_i           (a0_2nd_root_dig_n1_2nd),
	.a2_i           (a2_2nd_root_dig_n1_2nd),
	.a3_i           (a3_2nd_root_dig_n1_2nd),
	.a4_i           (a4_2nd_root_dig_n1_2nd),
	.m_n1_o         (m_n1_nxt_cycle_root_dig_n1_2nd),
	.m_z0_o         (m_z0_nxt_cycle_root_dig_n1_2nd),
	.m_p1_o         (m_p1_nxt_cycle_root_dig_n1_2nd),
	.m_p2_o         (m_p2_nxt_cycle_root_dig_n1_2nd)
);

fsqrt_r4_qds_constants_generator u_fsqrt_r4_qds_constants_generator_2nd_root_dig_z0_2nd (
	.a0_i           (a0_2nd_root_dig_z0_2nd),
	.a2_i           (a2_2nd_root_dig_z0_2nd),
	.a3_i           (a3_2nd_root_dig_z0_2nd),
	.a4_i           (a4_2nd_root_dig_z0_2nd),
	.m_n1_o         (m_n1_nxt_cycle_root_dig_z0_2nd),
	.m_z0_o         (m_z0_nxt_cycle_root_dig_z0_2nd),
	.m_p1_o         (m_p1_nxt_cycle_root_dig_z0_2nd),
	.m_p2_o         (m_p2_nxt_cycle_root_dig_z0_2nd)
);

fsqrt_r4_qds_constants_generator u_fsqrt_r4_qds_constants_generator_2nd_root_dig_p1_2nd (
	.a0_i           (a0_2nd_root_dig_p1_2nd),
	.a2_i           (a2_2nd_root_dig_p1_2nd),
	.a3_i           (a3_2nd_root_dig_p1_2nd),
	.a4_i           (a4_2nd_root_dig_p1_2nd),
	.m_n1_o         (m_n1_nxt_cycle_root_dig_p1_2nd),
	.m_z0_o         (m_z0_nxt_cycle_root_dig_p1_2nd),
	.m_p1_o         (m_p1_nxt_cycle_root_dig_p1_2nd),
	.m_p2_o         (m_p2_nxt_cycle_root_dig_p1_2nd)
);

fsqrt_r4_qds_constants_generator u_fsqrt_r4_qds_constants_generator_2nd_root_dig_p2_2nd (
	.a0_i           (a0_2nd_root_dig_p2_2nd),
	.a2_i           (a2_2nd_root_dig_p2_2nd),
	.a3_i           (a3_2nd_root_dig_p2_2nd),
	.a4_i           (a4_2nd_root_dig_p2_2nd),
	.m_n1_o         (m_n1_nxt_cycle_root_dig_p2_2nd),
	.m_z0_o         (m_z0_nxt_cycle_root_dig_p2_2nd),
	.m_p1_o         (m_p1_nxt_cycle_root_dig_p2_2nd),
	.m_p2_o         (m_p2_nxt_cycle_root_dig_p2_2nd)
);

assign root_ext_2nd = 
  ({(F64_FULL_ROOT_W){root_dig_n2_2nd}} & root_ext_2nd_root_dig_n2_2nd)
| ({(F64_FULL_ROOT_W){root_dig_n1_2nd}} & root_ext_2nd_root_dig_n1_2nd)
| ({(F64_FULL_ROOT_W){root_dig_z0_2nd}} & root_ext_2nd_root_dig_z0_2nd)
| ({(F64_FULL_ROOT_W){root_dig_p1_2nd}} & root_ext_2nd_root_dig_p1_2nd)
| ({(F64_FULL_ROOT_W){root_dig_p2_2nd}} & root_ext_2nd_root_dig_p2_2nd);
assign root_m1_ext_2nd = 
  ({(F64_FULL_ROOT_W){root_dig_n2_2nd}} & root_m1_ext_2nd_root_dig_n2_2nd)
| ({(F64_FULL_ROOT_W){root_dig_n1_2nd}} & root_m1_ext_2nd_root_dig_n1_2nd)
| ({(F64_FULL_ROOT_W){root_dig_z0_2nd}} & root_m1_ext_2nd_root_dig_z0_2nd)
| ({(F64_FULL_ROOT_W){root_dig_p1_2nd}} & root_m1_ext_2nd_root_dig_p1_2nd)
| ({(F64_FULL_ROOT_W){root_dig_p2_2nd}} & root_m1_ext_2nd_root_dig_p2_2nd);

assign f_r_s_2nd = 
  ({(REM_W){root_dig_n2_2nd}} & f_r_s_2nd_root_dig_n2_2nd)
| ({(REM_W){root_dig_n1_2nd}} & f_r_s_2nd_root_dig_n1_2nd)
| ({(REM_W){root_dig_z0_2nd}} & f_r_s_2nd_root_dig_z0_2nd)
| ({(REM_W){root_dig_p1_2nd}} & f_r_s_2nd_root_dig_p1_2nd)
| ({(REM_W){root_dig_p2_2nd}} & f_r_s_2nd_root_dig_p2_2nd);
assign f_r_c_2nd = 
  ({(REM_W){root_dig_n2_2nd}} & f_r_c_2nd_root_dig_n2_2nd)
| ({(REM_W){root_dig_n1_2nd}} & f_r_c_2nd_root_dig_n1_2nd)
| ({(REM_W){root_dig_z0_2nd}} & f_r_c_2nd_root_dig_z0_2nd)
| ({(REM_W){root_dig_p1_2nd}} & f_r_c_2nd_root_dig_p1_2nd)
| ({(REM_W){root_dig_p2_2nd}} & f_r_c_2nd_root_dig_p2_2nd);

assign root_1st_o = root_ext_1st[(F64_FULL_ROOT_W - 1) - 1:0];
assign root_m1_1st_o = root_m1_ext_1st[(F64_FULL_ROOT_W - 2) - 1:0];
assign root_2nd_o = root_ext_2nd[(F64_FULL_ROOT_W - 1) - 1:0];
assign root_m1_2nd_o = root_m1_ext_2nd[(F64_FULL_ROOT_W - 2) - 1:0];


assign f_r_s_1st_o = f_r_s_1st;
assign f_r_c_1st_o = f_r_c_1st;
assign f_r_s_2nd_o = f_r_s_2nd;
assign f_r_c_2nd_o = f_r_c_2nd;

assign rem_msb_nxt_cycle_1st_srt_o = 
  ({(7){root_dig_n2_2nd}} & rem_msb_nxt_cycle_1st_srt_root_dig_n2_2nd[8:2])
| ({(7){root_dig_n1_2nd}} & rem_msb_nxt_cycle_1st_srt_root_dig_n1_2nd[8:2])
| ({(7){root_dig_z0_2nd}} & rem_msb_nxt_cycle_1st_srt_root_dig_z0_2nd[8:2])
| ({(7){root_dig_p1_2nd}} & rem_msb_nxt_cycle_1st_srt_root_dig_p1_2nd[8:2])
| ({(7){root_dig_p2_2nd}} & rem_msb_nxt_cycle_1st_srt_root_dig_p2_2nd[8:2]);

assign rem_msb_nxt_cycle_2nd_srt_o =
  ({(9){root_dig_n2_2nd}} & rem_msb_nxt_cycle_2nd_srt_root_dig_n2_2nd[9:1])
| ({(9){root_dig_n1_2nd}} & rem_msb_nxt_cycle_2nd_srt_root_dig_n1_2nd[9:1])
| ({(9){root_dig_z0_2nd}} & rem_msb_nxt_cycle_2nd_srt_root_dig_z0_2nd[9:1])
| ({(9){root_dig_p1_2nd}} & rem_msb_nxt_cycle_2nd_srt_root_dig_p1_2nd[9:1])
| ({(9){root_dig_p2_2nd}} & rem_msb_nxt_cycle_2nd_srt_root_dig_p2_2nd[9:1]);

assign m_n1_nxt_cycle_1st_srt_o = 
  ({(7){root_dig_n2_2nd}} & m_n1_nxt_cycle_root_dig_n2_2nd)
| ({(7){root_dig_n1_2nd}} & m_n1_nxt_cycle_root_dig_n1_2nd)
| ({(7){root_dig_z0_2nd}} & m_n1_nxt_cycle_root_dig_z0_2nd)
| ({(7){root_dig_p1_2nd}} & m_n1_nxt_cycle_root_dig_p1_2nd)
| ({(7){root_dig_p2_2nd}} & m_n1_nxt_cycle_root_dig_p2_2nd);

assign m_z0_nxt_cycle_1st_srt_o = 
  ({(7){root_dig_n2_2nd}} & m_z0_nxt_cycle_root_dig_n2_2nd)
| ({(7){root_dig_n1_2nd}} & m_z0_nxt_cycle_root_dig_n1_2nd)
| ({(7){root_dig_z0_2nd}} & m_z0_nxt_cycle_root_dig_z0_2nd)
| ({(7){root_dig_p1_2nd}} & m_z0_nxt_cycle_root_dig_p1_2nd)
| ({(7){root_dig_p2_2nd}} & m_z0_nxt_cycle_root_dig_p2_2nd);

assign m_p1_nxt_cycle_1st_srt_o = 
  ({(7){root_dig_n2_2nd}} & m_p1_nxt_cycle_root_dig_n2_2nd)
| ({(7){root_dig_n1_2nd}} & m_p1_nxt_cycle_root_dig_n1_2nd)
| ({(7){root_dig_z0_2nd}} & m_p1_nxt_cycle_root_dig_z0_2nd)
| ({(7){root_dig_p1_2nd}} & m_p1_nxt_cycle_root_dig_p1_2nd)
| ({(7){root_dig_p2_2nd}} & m_p1_nxt_cycle_root_dig_p2_2nd);

assign m_p2_nxt_cycle_1st_srt_o = 
  ({(7){root_dig_n2_2nd}} & m_p2_nxt_cycle_root_dig_n2_2nd)
| ({(7){root_dig_n1_2nd}} & m_p2_nxt_cycle_root_dig_n1_2nd)
| ({(7){root_dig_z0_2nd}} & m_p2_nxt_cycle_root_dig_z0_2nd)
| ({(7){root_dig_p1_2nd}} & m_p2_nxt_cycle_root_dig_p1_2nd)
| ({(7){root_dig_p2_2nd}} & m_p2_nxt_cycle_root_dig_p2_2nd);


endmodule

