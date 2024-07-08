// ========================================================================================================
// File Name			: fadd32_rsh_lost_bits_mask.sv
// Author				: HYF
// How to Contact		: hyf_sysu@qq.com
// Created Time    		: July 4th 2024, 19:36:24
// Last Modified Time   : July 5th 2024, 10:31:04
// ========================================================================================================
// Description	:
// Get mask to extract lost bits in rsh process for far_path
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

module fadd32_rsh_lost_bits_mask #(
	// Put some parameters here, which can be changed by other modules
)(
	input  logic [ 8 - 1:0] 	exp_diff_i,
	input  logic             	exp_zero_i,
	input  logic             	do_sub_i,
    output logic [48 - 1:0]     lost_bits_mask_o
);

// ================================================================================================================================================
// (local) parameters begin



// (local) parameters end
// ================================================================================================================================================

// ================================================================================================================================================
// signals begin

genvar i;
logic [64 - 1:0] mask_temp;
logic [64 - 1:0] mask_temp_rsh1;
logic [64 - 1:0] mask_temp_rsh2;

// signals end
// ================================================================================================================================================

generate
for(i = 0; i < 64; i++) begin
    assign mask_temp[i] = ({2'b0, i[5:0]} < exp_diff_i);
end
endgenerate
assign mask_temp_rsh1 = mask_temp >> 1;
assign mask_temp_rsh2 = mask_temp >> 2;
// When "small_op is denormal and large_op is normal", exp_diff_real = exp_diff - 1 -> rsh_num_real = exp_diff - 1
// When small_op and large_op are both denormal, we must have "exp_diff_i = 0", so we would not do any rsh. And here we don't need to consider whether large_op is normal.
// When "do_sub", sig_small would be lsh 1 bit -> rsh_num_real = exp_diff - 1
// {denormal, do_sub},
// 00: mask = mask_temp
// 01: mask = mask_temp >> 1
// 10: mask = mask_temp >> 1
// 11: mask = mask_temp >> 2
assign lost_bits_mask_o = 
  ({(48){{exp_zero_i, do_sub_i} == 2'b00}} & mask_temp[47:0])
| ({(48){{exp_zero_i, do_sub_i} == 2'b01}} & mask_temp_rsh1[47:0])
| ({(48){{exp_zero_i, do_sub_i} == 2'b10}} & mask_temp_rsh1[47:0])
| ({(48){{exp_zero_i, do_sub_i} == 2'b11}} & mask_temp_rsh2[47:0]);


endmodule

