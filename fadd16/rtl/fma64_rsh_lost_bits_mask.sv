// ========================================================================================================
// File Name			: fma64_rsh_lost_bits_mask.sv
// Author				: HYF
// How to Contact		: hyf_sysu@qq.com
// Created Time    		: June 17th 2024, 15:24:15
// Last Modified Time   : 2024-06-20 @ 14:50:00
// ========================================================================================================
// Description	:
// Get mask to extract lost bits in rsh process
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

module fma64_rsh_lost_bits_mask #(
	// Put some parameters here, which can be changed by other modules
)(
	input  logic [ 6 - 1:0] 	rsh_num_i,
	output logic [62 - 1:0] 	s_mask_o
);

// ================================================================================================================================================
// (local) parameters begin



// (local) parameters end
// ================================================================================================================================================

// ================================================================================================================================================
// signals begin

genvar i;
logic [64 - 1:0] s_mask_temp;

// signals end
// ================================================================================================================================================


// 1. "rsh_num_max" is 63
// 2. For fma, the sticky_bit only occurs when "rsh_num >= 2"
// So we need a "64 - 2 = 62"-bit s_mask

generate
for(i = 0; i <= 63; i++)
    assign s_mask_temp[i] = (i[5:0] <= rsh_num_i);
endgenerate

assign s_mask_o = s_mask_temp[2 +: 62];

endmodule

