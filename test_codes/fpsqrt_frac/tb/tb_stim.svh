// ========================================================================================================
// File Name			: tb_stim.svh
// Author				: HYF
// How to Contact		: hyf_sysu@qq.com
// Created Time    		: 2021-12-29 16:42:39
// Last Modified Time   : 2022-01-24 16:39:56
// ========================================================================================================
// Description	:
// 
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


`ifdef TEST_SPECIAL_POINT
// ==================================================================================================================================================
// Some wrong points..
// ==================================================================================================================================================


`else

// ==================================================================================================================================================
// Just random test...
// ==================================================================================================================================================


fpsqrt_op[52:0] = 53'b1_1010001100000000000000000000000000000000000000000000;
is_odd = 1'b1;
`SINGLE_STIM

fpsqrt_op[52:0] = 53'b1_0111111110111111110111100000000000000000000000000000;
is_odd = 1'b1;
`SINGLE_STIM

fpsqrt_op[52:0] = 53'b1_1111111110000001011110000000000000000000000000000000;
is_odd = 1'b0;
`SINGLE_STIM

fpsqrt_op[52:0] = 53'b1_1100111101000000000000000000000000000000000000000000;
is_odd = 1'b0;
`SINGLE_STIM

fpsqrt_op[52:0] = 53'b1_1101100111000000000000000000000000000000000000000000;
is_odd = 1'b1;
`SINGLE_STIM

fpsqrt_op[52:0] = 53'h151254E10BEACF;
is_odd = 1'b1;
`SINGLE_STIM

for(i = 0; i < FP64_RANDOM_NUM; i++) begin
	std::randomize(fpsqrt_op);
	fpsqrt_op[52] = 1'b1;	
	`SINGLE_STIM
end

for(i = 0; i < FP32_RANDOM_NUM; i++) begin
	std::randomize(fpsqrt_op);
	fpsqrt_op[52] = 1'b1;	
	`SINGLE_STIM
end


`endif
