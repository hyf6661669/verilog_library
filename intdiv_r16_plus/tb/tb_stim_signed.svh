// ========================================================================================================
// File Name			: tb_stim_signed.svh
// Author				: HYF
// How to Contact		: hyf_sysu@qq.com
// Created Time    		: 2021-07-23 10:08:49
// Last Modified Time   : 2022-01-26 09:36:23
// ========================================================================================================
// Description	:
// Stim for signed op.
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


opcode = OPCODE_SIGNED;


dividend_64 = -100;
divisor_64 = 0;
dividend_32 = dividend_64[32-1:0];
divisor_32 = divisor_64[32-1:0];
dividend_16 = dividend_64[16-1:0];
divisor_16 = divisor_64[16-1:0];
`SINGLE_STIM

dividend_64 = -2090966090;
divisor_64 = 0;
dividend_32 = dividend_64[32-1:0];
divisor_32 = divisor_64[32-1:0];
dividend_16 = dividend_64[16-1:0];
divisor_16 = divisor_64[16-1:0];
`SINGLE_STIM

dividend_64 = S64_NEG_MIN;
divisor_64 = 1;
dividend_32 = S32_NEG_MIN;
divisor_32 = 1;
dividend_16 = S16_NEG_MIN;
divisor_16 = 1;
`SINGLE_STIM

dividend_64 = S64_NEG_MIN;
divisor_64 = -1;
dividend_32 = S32_NEG_MIN;
divisor_32 = -1;
dividend_16 = S16_NEG_MIN;
divisor_16 = -1;
`SINGLE_STIM

for(i = 0; i < SDIV_TEST_NUM; i++) begin
	// Make sure divisor_lzc >= dividend_lzc, so "ITER" is always needed.

`ifdef DUT_WIDTH_64
	
	dividend_64_lzc = $urandom() % 64;	
	divisor_64_lzc = ($urandom() % (64 - dividend_64_lzc)) + dividend_64_lzc;
	std::randomize(dividend_64);
	dividend_64[63] = 1'b1;
	dividend_64 = dividend_64 >> dividend_64_lzc;
	std::randomize(divisor_64);
	divisor_64[63] = 1'b1;
	divisor_64 = divisor_64 >> divisor_64_lzc;

`elsif DUT_WIDTH_32

	dividend_32_lzc = $urandom() % 32;
	divisor_32_lzc = ($urandom() % (32 - dividend_32_lzc)) + dividend_32_lzc;
	std::randomize(dividend_32);
	dividend_32[31] = 1'b1;
	dividend_32 = dividend_32 >> dividend_32_lzc;
	std::randomize(divisor_32);
	divisor_32[31] = 1'b1;
	divisor_32 = divisor_32 >> divisor_32_lzc;

`else

	dividend_16_lzc = $urandom() % 16;
	divisor_16_lzc = ($urandom() % (16 - dividend_16_lzc)) + dividend_16_lzc;
	std::randomize(dividend_16);
	dividend_16[15] = 1'b1;
	dividend_16 = dividend_16 >> dividend_16_lzc;
	std::randomize(divisor_16);
	divisor_16[15] = 1'b1;
	divisor_16 = divisor_16 >> divisor_16_lzc;

`endif

	`SINGLE_STIM
end
