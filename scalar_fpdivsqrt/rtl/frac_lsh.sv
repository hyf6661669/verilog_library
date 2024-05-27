// ========================================================================================================
// File Name			: frac_lsh.sv
// Author				: HYF
// How to Contact		: hyf_sysu@qq.com
// Created Time    		: May 24th 2024, 10:21:38
// Last Modified Time   : 2024-05-24 @ 11:29:34
// ========================================================================================================
// Description	:
// Left shifter for frac.
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

module frac_lsh #(
	// Put some parameters here, which can be changed by other modules.
)(
	input  logic [ 6 - 1:0]  lsh_i,
	input  logic [52 - 1:0]  frac_unshifted,
	output logic [52 - 1:0]  frac_shifted
);

// ================================================================================================================================================
// (local) parameters begin


// (local) parameters end
// ================================================================================================================================================

// ================================================================================================================================================
// signals begin

logic [52 - 1:0] lsh_l1;
logic [52 - 1:0] lsh_l2;
logic [52 - 1:0] lsh_l3;
logic [52 - 1:0] lsh_l4;
logic [52 - 1:0] lsh_l5;
logic [52 - 1:0] lsh_l6;


// signals end
// ================================================================================================================================================

// Since the MSB of "lsh_i" is generated earliest in CLZ Logic, we should start lsh from the MSB of "lsh_i"

assign lsh_l1 = 
  ({(52){ lsh_i[5]}} & {frac_unshifted[19:0], 32'b0})
| ({(52){~lsh_i[5]}} & {frac_unshifted[51:0]});

assign lsh_l2 = 
  ({(52){ lsh_i[4]}} & {lsh_l1[35:0], 16'b0})
| ({(52){~lsh_i[4]}} & {lsh_l1[51:0]});

assign lsh_l3 = 
  ({(52){ lsh_i[3]}} & {lsh_l2[43:0], 8'b0})
| ({(52){~lsh_i[3]}} & {lsh_l2[51:0]});

assign lsh_l4 = 
  ({(52){ lsh_i[2]}} & {lsh_l3[47:0], 4'b0})
| ({(52){~lsh_i[2]}} & {lsh_l3[51:0]});

assign lsh_l5 = 
  ({(52){ lsh_i[1]}} & {lsh_l4[49:0], 2'b0})
| ({(52){~lsh_i[1]}} & {lsh_l4[51:0]});

assign lsh_l6 = 
  ({(52){ lsh_i[0]}} & {lsh_l5[50:0], 1'b0})
| ({(52){~lsh_i[0]}} & {lsh_l5[51:0]});

assign frac_shifted = lsh_l6;


endmodule
