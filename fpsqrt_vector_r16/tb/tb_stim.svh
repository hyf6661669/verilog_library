// ========================================================================================================
// File Name			: tb_stim.svh
// Author				: HYF
// How to Contact		: hyf_sysu@qq.com
// Created Time    		: 2022-02-01 19:52:28
// Last Modified Time   : 2022-02-07 20:22:25
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

`ifdef TEST_OP_IS_POWER_OF_2

vector_mode = 0;

fp_format = 2'd2;
for(i = 0; i < FP64_RANDOM_NUM; i++) begin
	rm = $urandom % 5;
	std::randomize(fpsqrt_op);
	// fpsqrt_op[63] = 1'b0;
	fpsqrt_op[0 +: 52] = '0;
	`SINGLE_STIM
end

fp_format = 2'd1;
for(i = 0; i < FP32_RANDOM_NUM; i++) begin
	rm = $urandom % 5;
	std::randomize(fpsqrt_op);
	// fpsqrt_op[31] = 1'b0;
	fpsqrt_op[0 +: 23] = '0;
	`SINGLE_STIM
end

fp_format = 2'd0;
for(i = 0; i < FP16_RANDOM_NUM; i++) begin
	rm = $urandom % 5;
	std::randomize(fpsqrt_op);
	// fpsqrt_op[15] = 1'b0;
	fpsqrt_op[0 +: 10] = '0;
	`SINGLE_STIM
end

`else

// At the beginning, you must run a single "vector stim" before other stims. This is necessary, DO NOT DELETE !!!
// vector_mode = 1;
// fp_format = 2'd0;
// rm = 4;
// fpsqrt_op[63:0] = 64'h4C1EA9E94E9D53FF;
// `SINGLE_STIM


vector_mode = 1;
// rm = RM_RNE;
// fp_format = 2'd2;

// fpsqrt_op[63] = 1'b0;
// fpsqrt_op[62:52] = 1023 + 1;
// fpsqrt_op[51:0] = 52'b1010001100000000000000000000000000000000000000000000;
// `SINGLE_STIM

// fpsqrt_op[63] = 1'b0;
// fpsqrt_op[62:52] = 1023 + 1;
// fpsqrt_op[51:0] = 52'b0111111110111111110111100000000000000000000000000000;
// `SINGLE_STIM

// fpsqrt_op[63] = 1'b0;
// fpsqrt_op[62:52] = 1023 + 0;
// fpsqrt_op[51:0] = 52'b1111111110000001011110000000000000000000000000000000;
// `SINGLE_STIM

// fpsqrt_op[63] = 1'b0;
// fpsqrt_op[62:52] = 1023 + 0;
// fpsqrt_op[51:0] = 52'b1100111101000000000000000000000000000000000000000000;
// `SINGLE_STIM

// fpsqrt_op[63] = 1'b0;
// fpsqrt_op[62:52] = 1023 + 1;
// fpsqrt_op[51:0] = 52'b1101100111000000000000000000000000000000000000000000;
// `SINGLE_STIM



// fp_format = 2'd0;
// rm = 4;
// fpsqrt_op[63:0] = 64'h4C1EA9E94E9D53FF;
// `SINGLE_STIM

// rm = 3;
// fpsqrt_op[63:0] = 64'h0FB76D2D783643FF;
// `SINGLE_STIM

// rm = 1;
// fpsqrt_op[63:0] = 64'h61381BFB2ED31C34;
// `SINGLE_STIM

// rm = 1;
// fpsqrt_op[63:0] = 64'h35865C6815E91261;
// `SINGLE_STIM

// rm = 0;
// fpsqrt_op[63:0] = 64'h5E881FCF65AE7DE2;
// `SINGLE_STIM

// rm = 4;
// fpsqrt_op[63:0] = 64'h0C474BAE389F0EDC;
// `SINGLE_STIM


// fp_format = 2'd1;
// rm = 4;
// fpsqrt_op[63:0] = 64'h484BE72557B1E5F9;
// `SINGLE_STIM

// rm = 2;
// fpsqrt_op[63:0] = 64'h2BC71ED918631F57;
// `SINGLE_STIM

// rm = 4;
// fpsqrt_op[63:0] = 64'h7BCAAA6928505E2B;
// `SINGLE_STIM

// rm = 1;
// fpsqrt_op[63:0] = 64'h01707F00379847F0;
// `SINGLE_STIM

// rm = 2;
// fpsqrt_op[63:0] = 64'h48D69E5A6F707777;
// `SINGLE_STIM

// rm = 2;
// fpsqrt_op[63:0] = 64'h39D23E065D50DBA5;
// `SINGLE_STIM


fp_format = 2'd2;
for(i = 0; i < FP64_RANDOM_NUM; i++) begin
	rm = $urandom % 5;
	std::randomize(fpsqrt_op);
	fpsqrt_op[63] = 1'b0;
	`SINGLE_STIM
end

fp_format = 2'd1;
for(i = 0; i < FP32_RANDOM_NUM; i++) begin
	rm = $urandom % 5;
	std::randomize(fpsqrt_op);
	fpsqrt_op[31] = 1'b0;
	fpsqrt_op[63] = 1'b0;
	`SINGLE_STIM
end

fp_format = 2'd0;
for(i = 0; i < FP16_RANDOM_NUM; i++) begin
	rm = $urandom % 5;
	std::randomize(fpsqrt_op);
	fpsqrt_op[15] = 1'b0;
	fpsqrt_op[31] = 1'b0;
	fpsqrt_op[47] = 1'b0;
	fpsqrt_op[63] = 1'b0;
	`SINGLE_STIM
end

`endif

