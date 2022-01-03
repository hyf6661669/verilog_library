// ========================================================================================================
// File Name			: tb_stim.svh
// Author				: HYF
// How to Contact		: hyf_sysu@qq.com
// Created Time    		: 2021-12-29 16:42:39
// Last Modified Time   : 2022-01-02 11:16:34
// ========================================================================================================
// Description	:
// 
// ========================================================================================================
// ========================================================================================================
// Copyright (C) 2021, HYF. All Rights Reserved.
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


`ifdef TEST_SPECIAL_POINT
// ==================================================================================================================================================
// Some wrong points..
// ==================================================================================================================================================


`else

// ==================================================================================================================================================
// Just random test...
// ==================================================================================================================================================

fp_format = 0;
for(i = 0; i < FP16_RANDOM_NUM; i++) begin
	std::randomize(fpdiv_opa_frac);
	std::randomize(fpdiv_opb_frac);

	// fpdiv_opb_frac[10:7] = 4'b1000;

	fpdiv_opa_frac[10] = 1'b1;
	fpdiv_opb_frac[10] = 1'b1;
	
	`SINGLE_STIM
end

fp_format = 1;
for(i = 0; i < FP32_RANDOM_NUM; i++) begin
	std::randomize(fpdiv_opa_frac);
	std::randomize(fpdiv_opb_frac);

	// fpdiv_opb_frac[23:20] = 4'b1000;

	fpdiv_opa_frac[23] = 1'b1;
	fpdiv_opb_frac[23] = 1'b1;
	
	`SINGLE_STIM
end

fp_format = 2;
fpdiv_opa_frac[52:0] = 53'b11010000100000000000000000000000000000000000000000000;
fpdiv_opb_frac[52:0] = 53'b10001111111000000000000000000000000000000000000000000;
`SINGLE_STIM

fp_format = 2;
fpdiv_opa_frac[52:0] = 53'b10110111001110101111101110101101100100001011001010010;
fpdiv_opb_frac[52:0] = 53'b10100000101010110111010101001000110011111110100011111;
`SINGLE_STIM

fp_format = 2;
fpdiv_opa_frac[52:0] = 53'b10111000010101111001000000111010101100001000100000100;
fpdiv_opb_frac[52:0] = 53'b11111100110010001000101000100010011100100111000000011;
`SINGLE_STIM

fp_format = 2;
for(i = 0; i < FP64_RANDOM_NUM; i++) begin
	std::randomize(fpdiv_opa_frac);
	std::randomize(fpdiv_opb_frac);

	// fpdiv_opb_frac[52:49] = 4'b1000;

	fpdiv_opa_frac[52] = 1'b1;
	fpdiv_opb_frac[52] = 1'b1;
	
	`SINGLE_STIM
end

`endif
