// ========================================================================================================
// File Name			: r4_qds_v1.sv
// Author				: HYF
// How to Contact		: hyf_sysu@qq.com
// Created Time    		: 2021-12-29 20:40:04
// Last Modified Time   : 2021-12-30 09:19:15
// ========================================================================================================
// Description	:
// Table II (b) in the reference paper.
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

// include some definitions here

module r4_qds_v1 #(
	// Put some parameters here, which can be changed by other modules.
)(
	input  logic [6-1:0] rem_i,
	input  logic carry_i,
	output logic [5-1:0] quo_dig_o
);

// ================================================================================================================================================
// (local) parameters begin


// (local) parameters end
// ================================================================================================================================================

// ================================================================================================================================================
// signals begin


// signals end
// ================================================================================================================================================

assign quo_dig_o[4] = 
  (($signed(rem_i) == -13) & carry_i)
| ($signed(rem_i) <= -14)
| (($signed(rem_i) == 31) & ~carry_i);

assign quo_dig_o[3] = 
  (($signed(rem_i) == -4) & carry_i)
| (($signed(rem_i) <= -5) & ($signed(rem_i) >= -12))
| (($signed(rem_i) == -13) & ~carry_i);

assign quo_dig_o[2] = 
  (($signed(rem_i) == 3) & carry_i)
| (($signed(rem_i) <= 2) & ($signed(rem_i) >= -3))
| (($signed(rem_i) == -4) & ~carry_i);

assign quo_dig_o[1] = 
  (($signed(rem_i) == 12) & carry_i)
| (($signed(rem_i) <= 11) & ($signed(rem_i) >= 4))
| (($signed(rem_i) == 3) & ~carry_i);

assign quo_dig_o[0] = 
  (($signed(rem_i) == 31) & carry_i)
| (($signed(rem_i) <= 30) & ($signed(rem_i) >= 13))
| (($signed(rem_i) == 12) & ~carry_i);

endmodule
