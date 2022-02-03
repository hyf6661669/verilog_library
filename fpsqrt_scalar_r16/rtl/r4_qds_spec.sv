// ========================================================================================================
// File Name			: r4_qds_spec.sv
// Author				: HYF
// How to Contact		: hyf_sysu@qq.com
// Created Time    		: 2022-02-01 15:56:17
// Last Modified Time   : 2022-02-03 20:15:07
// ========================================================================================================
// Description	:
// Comparing with the original version, more speculation is added to this module.
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

module r4_qds_spec #(
	// Put some parameters here, which can be changed by other modules.
)(
	input  logic [9-1:0] rem_i,
	input  logic [9-1:0] sqrt_csa_val_neg_2_msbs_i,
	input  logic [9-1:0] sqrt_csa_val_neg_1_msbs_i,
	input  logic [9-1:0] sqrt_csa_val_pos_1_msbs_i,
	input  logic [9-1:0] sqrt_csa_val_pos_2_msbs_i,
	
	input  logic [7-1:0] m_neg_1_neg_2_i,
	input  logic [7-1:0] m_neg_0_neg_2_i,
	input  logic [7-1:0] m_pos_1_neg_2_i,
	input  logic [7-1:0] m_pos_2_neg_2_i,

	input  logic [7-1:0] m_neg_1_neg_1_i,
	input  logic [7-1:0] m_neg_0_neg_1_i,
	input  logic [7-1:0] m_pos_1_neg_1_i,
	input  logic [7-1:0] m_pos_2_neg_1_i,

	input  logic [7-1:0] m_neg_1_neg_0_i,
	input  logic [7-1:0] m_neg_0_neg_0_i,
	input  logic [7-1:0] m_pos_1_neg_0_i,
	input  logic [7-1:0] m_pos_2_neg_0_i,

	input  logic [7-1:0] m_neg_1_pos_1_i,
	input  logic [7-1:0] m_neg_0_pos_1_i,
	input  logic [7-1:0] m_pos_1_pos_1_i,
	input  logic [7-1:0] m_pos_2_pos_1_i,
	
	input  logic [7-1:0] m_neg_1_pos_2_i,
	input  logic [7-1:0] m_neg_0_pos_2_i,
	input  logic [7-1:0] m_pos_1_pos_2_i,
	input  logic [7-1:0] m_pos_2_pos_2_i,

	input  logic [5-1:0] prev_rt_dig_i,
	output logic [5-1:0] rt_dig_o
);

// ================================================================================================================================================
// (local) parameters begin


// (local) parameters end
// ================================================================================================================================================

// ================================================================================================================================================
// signals begin

logic [4-1:0] qds_sign;
logic [4-1:0] qds_sign_spec [5-1:0];
logic [8-1:0] unused_bit_prev_q_neg_2 [4-1:0];
logic [8-1:0] unused_bit_prev_q_neg_1 [4-1:0];
logic [8-1:0] unused_bit_prev_q_neg_0 [4-1:0];
logic [8-1:0] unused_bit_prev_q_pos_1 [4-1:0];
logic [8-1:0] unused_bit_prev_q_pos_2 [4-1:0];

// signals end
// ================================================================================================================================================

assign {qds_sign_spec[4][3], unused_bit_prev_q_neg_2[3]} = rem_i + sqrt_csa_val_neg_2_msbs_i + {m_pos_2_neg_2_i, 2'b0};
assign {qds_sign_spec[4][2], unused_bit_prev_q_neg_2[2]} = rem_i + sqrt_csa_val_neg_2_msbs_i + {m_pos_1_neg_2_i, 2'b0};
assign {qds_sign_spec[4][1], unused_bit_prev_q_neg_2[1]} = rem_i + sqrt_csa_val_neg_2_msbs_i + {m_neg_0_neg_2_i, 2'b0};
assign {qds_sign_spec[4][0], unused_bit_prev_q_neg_2[0]} = rem_i + sqrt_csa_val_neg_2_msbs_i + {m_neg_1_neg_2_i, 2'b0};

assign {qds_sign_spec[3][3], unused_bit_prev_q_neg_1[3]} = rem_i + sqrt_csa_val_neg_1_msbs_i + {m_pos_2_neg_1_i, 2'b0};
assign {qds_sign_spec[3][2], unused_bit_prev_q_neg_1[2]} = rem_i + sqrt_csa_val_neg_1_msbs_i + {m_pos_1_neg_1_i, 2'b0};
assign {qds_sign_spec[3][1], unused_bit_prev_q_neg_1[1]} = rem_i + sqrt_csa_val_neg_1_msbs_i + {m_neg_0_neg_1_i, 2'b0};
assign {qds_sign_spec[3][0], unused_bit_prev_q_neg_1[0]} = rem_i + sqrt_csa_val_neg_1_msbs_i + {m_neg_1_neg_1_i, 2'b0};

assign {qds_sign_spec[2][3], unused_bit_prev_q_neg_0[3]} = rem_i + {m_pos_2_neg_0_i, 2'b0};
assign {qds_sign_spec[2][2], unused_bit_prev_q_neg_0[2]} = rem_i + {m_pos_1_neg_0_i, 2'b0};
assign {qds_sign_spec[2][1], unused_bit_prev_q_neg_0[1]} = rem_i + {m_neg_0_neg_0_i, 2'b0};
assign {qds_sign_spec[2][0], unused_bit_prev_q_neg_0[0]} = rem_i + {m_neg_1_neg_0_i, 2'b0};

assign {qds_sign_spec[1][3], unused_bit_prev_q_pos_1[3]} = rem_i + sqrt_csa_val_pos_1_msbs_i + {m_pos_2_pos_1_i, 2'b0};
assign {qds_sign_spec[1][2], unused_bit_prev_q_pos_1[2]} = rem_i + sqrt_csa_val_pos_1_msbs_i + {m_pos_1_pos_1_i, 2'b0};
assign {qds_sign_spec[1][1], unused_bit_prev_q_pos_1[1]} = rem_i + sqrt_csa_val_pos_1_msbs_i + {m_neg_0_pos_1_i, 2'b0};
assign {qds_sign_spec[1][0], unused_bit_prev_q_pos_1[0]} = rem_i + sqrt_csa_val_pos_1_msbs_i + {m_neg_1_pos_1_i, 2'b0};

assign {qds_sign_spec[0][3], unused_bit_prev_q_pos_2[3]} = rem_i + sqrt_csa_val_pos_2_msbs_i + {m_pos_2_pos_2_i, 2'b0};
assign {qds_sign_spec[0][2], unused_bit_prev_q_pos_2[2]} = rem_i + sqrt_csa_val_pos_2_msbs_i + {m_pos_1_pos_2_i, 2'b0};
assign {qds_sign_spec[0][1], unused_bit_prev_q_pos_2[1]} = rem_i + sqrt_csa_val_pos_2_msbs_i + {m_neg_0_pos_2_i, 2'b0};
assign {qds_sign_spec[0][0], unused_bit_prev_q_pos_2[0]} = rem_i + sqrt_csa_val_pos_2_msbs_i + {m_neg_1_pos_2_i, 2'b0};

// The "prev_rt_dig_i" must be ready, before the results of the above FAs are available.

assign qds_sign = 
  ({(5){prev_rt_dig_i[4]}} & qds_sign_spec[4])
| ({(5){prev_rt_dig_i[3]}} & qds_sign_spec[3])
| ({(5){prev_rt_dig_i[2]}} & qds_sign_spec[2])
| ({(5){prev_rt_dig_i[1]}} & qds_sign_spec[1])
| ({(5){prev_rt_dig_i[0]}} & qds_sign_spec[0]);

assign rt_dig_o[4] = (qds_sign[1:0] == 2'b11);
assign rt_dig_o[3] = (qds_sign[1:0] == 2'b10);
assign rt_dig_o[2] = (qds_sign[2:1] == 2'b10);
assign rt_dig_o[1] = (qds_sign[3:2] == 2'b10);
assign rt_dig_o[0] = (qds_sign[3:2] == 2'b00);

endmodule
