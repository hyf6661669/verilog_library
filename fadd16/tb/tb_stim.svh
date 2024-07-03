// ========================================================================================================
// File Name			: tb_stim.svh
// Author				: HYF
// How to Contact		: hyf_sysu@qq.com
// Created Time    		: June 2nd 2024, 11:24:14
// Last Modified Time   : July 3rd 2024, 15:54:56
// ========================================================================================================
// Description	:
// 
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
`ifndef RAND_SEED
	`define RAND_SEED 999
`endif
`ifndef TEST_LEVEL
	`define TEST_LEVEL 1
`endif

gencases_init(`RAND_SEED, `TEST_LEVEL);

// dut_fp_format = 3'b001;
// dut_rm = 'd2;

// for(i = 0; i < 100; i++) begin
// 	dut_opa = {32'b0, $urandom()};
// 	dut_opb = {32'b0, $urandom()};
// 	`SINGLE_STIM
// end


// dut_fp_format = 3'b001;
// dut_is_fma = 1;
// dut_opa = 64'h000000000000F811;
// dut_opb = 64'h000000000000F800;
// dut_opc = 64'h000000000000B411;
// dut_rm = 0;
// `SINGLE_STIM

// dut_opa = 64'h00000000000003F0;
// dut_opb = 64'h0000000000004010;
// dut_opc = 64'h0000000000008000;
// dut_rm = 3;
// `SINGLE_STIM




// ==================================================================================================================================================
// TEST for fadd/fma
// ==================================================================================================================================================

dut_fp_format = 3'b001;
for(i = 0; i < FP16_RANDOM_NUM; i++) begin
	dut_is_fma = dut_opa[0];
	// dut_is_fma = 1'b1;
	if(dut_is_fma)
		gencases_for_f16_fma(dut_opa[15:0], dut_opb[15:0], dut_opc[15:0]);
	else
		gencases_for_f16(dut_opa[15:0], dut_opb[15:0]);
	
`ifdef RANDOM_RM
	dut_rm = $urandom % 5;
	`SINGLE_STIM
`else
	dut_rm = RM_RNE;
	`SINGLE_STIM
	dut_rm = RM_RTZ;
	`SINGLE_STIM
	dut_rm = RM_RDN;
	`SINGLE_STIM
	dut_rm = RM_RUP;
	`SINGLE_STIM
	dut_rm = RM_RMM;
	`SINGLE_STIM
`endif

end


// ==================================================================================================================================================
// TEST for fmul
// ==================================================================================================================================================

// dut_fp_format = 3'b001;

// dut_opa = 64'h000000000000063E;
// dut_opb = 64'h0000000000003920;
// dut_rm = 0;
// `SINGLE_STIM

// dut_opa = 64'h0000000000000080;
// dut_opb = 64'h00000000000047FF;
// dut_rm = 0;
// `SINGLE_STIM


// dut_fp_format = 3'b001;
// for(i = 0; i < FP16_RANDOM_NUM; i++) begin
// 	gencases_for_f16(dut_opa[15:0], dut_opb[15:0]);
	
// `ifdef RANDOM_RM
// 	dut_rm = $urandom % 5;
// 	`SINGLE_STIM
// `else
// 	dut_rm = RM_RNE;
// 	`SINGLE_STIM
// 	dut_rm = RM_RTZ;
// 	`SINGLE_STIM
// 	dut_rm = RM_RDN;
// 	`SINGLE_STIM
// 	dut_rm = RM_RUP;
// 	`SINGLE_STIM
// 	dut_rm = RM_RMM;
// 	`SINGLE_STIM
// `endif

// end

// dut_fp_format = 3'b010;
// for(i = 0; i < FP32_RANDOM_NUM; i++) begin
// 	gencases_for_f32(dut_opa[31:0], dut_opb[31:0]);
	
// `ifdef RANDOM_RM
// 	dut_rm = $urandom % 5;
// 	`SINGLE_STIM
// `else
// 	dut_rm = RM_RNE;
// 	`SINGLE_STIM
// 	dut_rm = RM_RTZ;
// 	`SINGLE_STIM
// 	dut_rm = RM_RDN;
// 	`SINGLE_STIM
// 	dut_rm = RM_RUP;
// 	`SINGLE_STIM
// 	dut_rm = RM_RMM;
// 	`SINGLE_STIM
// `endif

// end

// dut_fp_format = 3'b100;
// for(i = 0; i < FP64_RANDOM_NUM; i++) begin
// 	gencases_for_f64(dut_opa[63:32], dut_opa[31:00], dut_opb[63:32], dut_opb[31:00]);
	
// `ifdef RANDOM_RM
// 	dut_rm = $urandom % 5;
// 	`SINGLE_STIM
// `else
// 	dut_rm = RM_RNE;
// 	`SINGLE_STIM
// 	dut_rm = RM_RTZ;
// 	`SINGLE_STIM
// 	dut_rm = RM_RDN;
// 	`SINGLE_STIM
// 	dut_rm = RM_RUP;
// 	`SINGLE_STIM
// 	dut_rm = RM_RMM;
// 	`SINGLE_STIM
// `endif

// end
