// ========================================================================================================
// File Name			: r4_qds_constants_generator.sv
// Author				: HYF
// How to Contact		: hyf_sysu@qq.com
// Created Time    		: 2022-01-26 15:10:27
// Last Modified Time   : 2022-01-26 15:25:45
// ========================================================================================================
// Description	:
// For more details, please look at "TABLE I" in:
// "Digit-recurrence dividers with reduced logical depth"
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

// include some definitions here

module r4_qds_constants_generator #(
	// Put some parameters here, which can be changed by other modules.
)(
	input  logic [3-1:0] D_msbs_i,
	output logic [7-1:0] m_neg_1_o,
	output logic [7-1:0] m_neg_0_o,
	output logic [7-1:0] m_pos_1_o,
	output logic [7-1:0] m_pos_2_o
);

// ================================================================================================================================================
// (local) parameters begin


// (local) parameters end
// ================================================================================================================================================

// ================================================================================================================================================
// signals begin


// signals end
// ================================================================================================================================================

// For m[-1], the decimal point is between [5] and [4].
// 000: m[-1] = -13, -m[-1] = +13 = 00_1101 -> ext(-m[-1]) = 00_11010
// 001: m[-1] = -15, -m[-1] = +15 = 00_1111 -> ext(-m[-1]) = 00_11110
// 010: m[-1] = -16, -m[-1] = +16 = 01_0000 -> ext(-m[-1]) = 01_00000
// 011: m[-1] = -17, -m[-1] = +17 = 01_0001 -> ext(-m[-1]) = 01_00010
// 100: m[-1] = -19, -m[-1] = +19 = 01_0011 -> ext(-m[-1]) = 01_00110
// 101: m[-1] = -20, -m[-1] = +20 = 01_0100 -> ext(-m[-1]) = 01_01000
// 110: m[-1] = -22, -m[-1] = +22 = 01_0110 -> ext(-m[-1]) = 01_01100
// 111: m[-1] = -24, -m[-1] = +24 = 01_1000 -> ext(-m[-1]) = 01_10000
assign m_neg_1_o = 
  ({(7){D_msbs_i == 3'd0}} & 7'b00_11010)
| ({(7){D_msbs_i == 3'd1}} & 7'b00_11110)
| ({(7){D_msbs_i == 3'd2}} & 7'b01_00000)
| ({(7){D_msbs_i == 3'd3}} & 7'b01_00010)
| ({(7){D_msbs_i == 3'd4}} & 7'b01_00110)
| ({(7){D_msbs_i == 3'd5}} & 7'b01_01000)
| ({(7){D_msbs_i == 3'd6}} & 7'b01_01100)
| ({(7){D_msbs_i == 3'd7}} & 7'b01_10000);

// For m[-0], the decimal point is between [4] and [3].
// 000: m[-0] = -4, -m[-0] = +4 = 000_0100
// 001: m[-0] = -6, -m[-0] = +6 = 000_0110
// 010: m[-0] = -6, -m[-0] = +6 = 000_0110
// 011: m[-0] = -6, -m[-0] = +6 = 000_0110
// 100: m[-0] = -6, -m[-0] = +6 = 000_0110
// 101: m[-0] = -8, -m[-0] = +8 = 000_1000
// 110: m[-0] = -8, -m[-0] = +8 = 000_1000
// 111: m[-0] = -8, -m[-0] = +8 = 000_1000
assign m_neg_0_o = 
  ({(7){D_msbs_i == 3'd0}} & 7'b000_0100)
| ({(7){D_msbs_i == 3'd1}} & 7'b000_0110)
| ({(7){D_msbs_i == 3'd2}} & 7'b000_0110)
| ({(7){D_msbs_i == 3'd3}} & 7'b000_0110)
| ({(7){D_msbs_i == 3'd4}} & 7'b000_0110)
| ({(7){D_msbs_i == 3'd5}} & 7'b000_1000)
| ({(7){D_msbs_i == 3'd6}} & 7'b000_1000)
| ({(7){D_msbs_i == 3'd7}} & 7'b000_1000);

// For m[+1], the decimal point is between [4] and [3].
// 000: m[+1] = +4, -m[+1] = -4 = 111_1100
// 001: m[+1] = +4, -m[+1] = -4 = 111_1100
// 010: m[+1] = +4, -m[+1] = -4 = 111_1100
// 011: m[+1] = +4, -m[+1] = -4 = 111_1100
// 100: m[+1] = +6, -m[+1] = -6 = 111_1010
// 101: m[+1] = +6, -m[+1] = -6 = 111_1010
// 110: m[+1] = +6, -m[+1] = -6 = 111_1010
// 111: m[+1] = +8, -m[+1] = -8 = 111_1000
assign m_pos_1_o = 
  ({(7){D_msbs_i == 3'd0}} & 7'b111_1100)
| ({(7){D_msbs_i == 3'd1}} & 7'b111_1100)
| ({(7){D_msbs_i == 3'd2}} & 7'b111_1100)
| ({(7){D_msbs_i == 3'd3}} & 7'b111_1100)
| ({(7){D_msbs_i == 3'd4}} & 7'b111_1010)
| ({(7){D_msbs_i == 3'd5}} & 7'b111_1010)
| ({(7){D_msbs_i == 3'd6}} & 7'b111_1010)
| ({(7){D_msbs_i == 3'd7}} & 7'b111_1000);

// For m[+2], the decimal point is between [5] and [4].
// 000: m[+2] = +12, -m[+2] = -12 = 11_0100 -> ext(-m[+2]) = 11_01000
// 001: m[+2] = +14, -m[+2] = -14 = 11_0010 -> ext(-m[+2]) = 11_00100
// 010: m[+2] = +15, -m[+2] = -15 = 11_0001 -> ext(-m[+2]) = 11_00010
// 011: m[+2] = +16, -m[+2] = -16 = 11_0000 -> ext(-m[+2]) = 11_00000
// 100: m[+2] = +18, -m[+2] = -18 = 10_1110 -> ext(-m[+2]) = 10_11100
// 101: m[+2] = +20, -m[+2] = -20 = 10_1100 -> ext(-m[+2]) = 10_11000
// 110: m[+2] = +22, -m[+2] = -22 = 10_1010 -> ext(-m[+2]) = 10_10100
// 111: m[+2] = +22, -m[+2] = -22 = 10_1010 -> ext(-m[+2]) = 10_10100
assign m_pos_2_o = 
  ({(7){D_msbs_i == 3'd0}} & 7'b11_01000)
| ({(7){D_msbs_i == 3'd1}} & 7'b11_00100)
| ({(7){D_msbs_i == 3'd2}} & 7'b11_00010)
| ({(7){D_msbs_i == 3'd3}} & 7'b11_00000)
| ({(7){D_msbs_i == 3'd4}} & 7'b10_11100)
| ({(7){D_msbs_i == 3'd5}} & 7'b10_11000)
| ({(7){D_msbs_i == 3'd6}} & 7'b10_10100)
| ({(7){D_msbs_i == 3'd7}} & 7'b10_10100);


endmodule
