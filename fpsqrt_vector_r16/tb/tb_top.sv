// ========================================================================================================
// File Name			: tb_top.sv
// Author				: HYF
// How to Contact		: hyf_sysu@qq.com
// Created Time    		: 2022-01-15 11:10:46
// Last Modified Time   : 2022-02-06 21:39:02
// ========================================================================================================
// Description	:
// TB for FPSQRT.
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
`ifndef MAX_ERROR_COUNT
	`define MAX_ERROR_COUNT 10
`endif

`define USE_ZERO_DELAY
// `define USE_SHORT_DELAY
// `define USE_MIDDLE_DELAY
// `define USE_LONG_DELAY

`include "tb_defines.svh"
// If DUT doesn't have valid-ready control logic itself, don't define this..
`define DUT_HAS_VALID_READY

`define SINGLE_STIM \
dut_start_valid = 1; \
`WAIT_COMB_SIG(clk, (dut_start_valid & dut_start_ready), 0) \
`APPL_WAIT_CYC(clk, 1) \
dut_start_valid = 0; \
 \
`WAIT_SIG(clk, (dut_finish_valid & dut_finish_ready), 0) \
dut_start_valid_after_finish_handshake_delay = $urandom() % `VALID_READY_DELAY; \
`APPL_WAIT_CYC(clk, dut_start_valid_after_finish_handshake_delay)


module tb_top #(
	// Put some parameters here, which can be changed by other modules
)(
);

// ==================================================================================================================================================
// (local) params
// ==================================================================================================================================================

`ifndef FP64_TEST_NUM
	`define FP64_TEST_NUM 2 ** 15
`endif
`ifndef FP32_TEST_NUM
	`define FP32_TEST_NUM 2 ** 15
`endif
`ifndef FP16_TEST_NUM
	`define FP16_TEST_NUM 2 ** 15
`endif
localparam FP64_RANDOM_NUM = `FP64_TEST_NUM;
localparam FP32_RANDOM_NUM = `FP32_TEST_NUM;
localparam FP16_RANDOM_NUM = `FP16_TEST_NUM;

typedef bit [31:0][2] bit_to_array;

localparam RM_RNE = 3'b000;
localparam RM_RTZ = 3'b001;
localparam RM_RDN = 3'b010;
localparam RM_RUP = 3'b011;
localparam RM_RMM = 3'b100;


// ==================================================================================================================================================
// functions
// ==================================================================================================================================================

import "DPI-C" function void fpsqrt_check(
	input  bit [31:0] acq_count,
	input  bit [31:0] err_count,
	input  bit [31:0] op_hi,
	input  bit [31:0] op_lo,
	input  bit [31:0] fp_format,
	input  bit [31:0] rm,
	input  bit [31:0] vector,
	input  bit [31:0] dut_res_hi,
	input  bit [31:0] dut_res_lo,
	input  bit [31:0] dut_fflags,
	output bit [31:0] compare_ok
);
import "DPI-C" function void print_error(input bit [31:0] err_count);

// ==================================================================================================================================================
// signals
// ==================================================================================================================================================

// common signals
logic clk;
logic rst_n;
int i;
logic simulation_start;
logic stim_end;
logic acq_trig;
logic [31:0] acq_count;
logic [31:0] err_count;

bit compare_ok;
bit dut_start_valid;
bit dut_start_ready;
bit dut_finish_valid;
bit dut_finish_ready;
// tb向dut发送的后一个start_valid和前一个finish_handshake之间的延迟
bit [31:0] dut_start_valid_after_finish_handshake_delay;
// tb向dut发送了start_valid之后，dut向tb发送start_ready之间的延迟
bit [31:0] dut_start_ready_after_start_valid_delay;
// tb发送到dut的finish_ready和dut发送到tb中的finish_valid之间的延迟
bit [31:0] dut_finish_ready_after_finish_valid_delay;
// start_valid = 1之后，dut向tb发送的finish_valid之间的延迟
bit [31:0] dut_finish_valid_after_start_handshake_delay;


// signals related with DUT.
bit [64-1:0] fpsqrt_op;
bit [64-1:0] dut_fpsqrt_res;
bit [ 5-1:0] dut_fflags;
bit [ 2-1:0] fp_format;
bit [ 3-1:0] rm;
bit vector_mode;

// ==================================================================================================================================================
// main codes
// ==================================================================================================================================================


// ================================================================================================================================================
// application process

initial begin
	dut_start_valid = 0;
	acq_trig = 0;
	stim_end = 0;

	`APPL_WAIT_SIG(clk, simulation_start, 0)
	$display("TB: stimuli application starts!");

	acq_trig = 1;
	`APPL_WAIT_CYC(clk, 2)
	acq_trig = 0;

	`include "tb_stim.svh"
	
	// `WAIT_CYC(clk, 5)
	stim_end = 1;
end

// ================================================================================================================================================

// ================================================================================================================================================
// acquisition process



initial begin
	dut_finish_ready = 0;
	$display("TB: response acquisition starts!");

	// wait for acquisition trigger
	do begin
		`RESP_WAIT_CYC(clk, 1)
		if(stim_end == 1) begin
			$display("response acquisition finishes!");
			$display("TB finishes!");
			$stop();
		end
	end while(acq_trig == 1'b0);

	acq_count = 0;
	err_count = 0;

	do begin
		`WAIT_COMB_SIG(clk, dut_start_valid, stim_end)
		`WAIT_COMB_SIG(clk, dut_finish_valid, stim_end)
		dut_finish_ready_after_finish_valid_delay = $urandom() % `VALID_READY_DELAY;
		`RESP_WAIT_CYC(clk, dut_finish_ready_after_finish_valid_delay)
		dut_finish_ready = 1;

		if(stim_end)
			break;

		fpsqrt_check(
			.acq_count(acq_count),
			.err_count(err_count),
			.op_hi(fpsqrt_op[63:32]),
			.op_lo(fpsqrt_op[31: 0]),
			.fp_format(fp_format),
			.rm(rm),
			.vector(vector_mode),
			.dut_res_hi(dut_fpsqrt_res[63:32]),
			.dut_res_lo(dut_fpsqrt_res[31: 0]),
			.dut_fflags(dut_fflags),
			.compare_ok(compare_ok)
		);

		
		if((compare_ok == 0) | (compare_ok == 1'bX)) begin
			// $display("ERROR FOUND:");
			
			// $display("[%d]:", acq_count);
			// $display("fpsqrt_op = %53b", fpsqrt_op);

			err_count++;
		end

		

		if(err_count == `MAX_ERROR_COUNT) begin
			$display("finished_test_num = %d, error_test_num = %d", acq_count, err_count);
			$display("Too many ERRORs, stop simulation!!!");
			$display("Printing error information...");
			print_error(err_count);
			$stop();
		end

		acq_count++;
		`RESP_WAIT_SIG(clk, dut_finish_ready, stim_end)
		dut_finish_ready = 0;


	end while(stim_end == 0);

	`WAIT_CYC(clk, 3)
	$display("finished_test_num = %d, error_test_num = %d", acq_count, err_count);
	$display("response acquisition finishes!");
	$display("TB finishes!");
	$display("Printing error information...");
	print_error(err_count);
	$stop();
end

// ================================================================================================================================================

// ================================================================================================================================================
// calculate expected result


// ================================================================================================================================================
// Instantiate DUT here.

fpsqrt_vector_r16 #(
	.S0_CSA_SPECULATIVE(1),
	.S0_CSA_MERGED(1),	
	.S1_QDS_SPECULATIVE(0),
	.S1_CSA_SPECULATIVE(1),
	.S1_CSA_MERGED(0)
) u_dut (
	.start_valid_i(dut_start_valid),
	.start_ready_o(dut_start_ready),
	.flush_i(1'b0),
	.fp_format_i(fp_format),
	.op_i(fpsqrt_op),
	.rm_i(rm),
	.vector_mode_i(vector_mode),

	.finish_valid_o(dut_finish_valid),
	.finish_ready_i(dut_finish_ready),
	.fpsqrt_res_o(dut_fpsqrt_res),
	.fflags_o(dut_fflags),

	.clk(clk),
	.rst_n(rst_n)
);

// ================================================================================================================================================
// Simulate valid-ready signals of dut

`ifndef DUT_HAS_VALID_READY
initial begin
	do begin
		dut_start_ready = 0;
		`RESP_WAIT_SIG(clk, dut_start_valid, 0)
		dut_start_ready_after_start_valid_delay = $urandom() % `VALID_READY_DELAY;
		`RESP_WAIT_CYC(clk, dut_start_ready_after_start_valid_delay)
		dut_start_ready = 1;
		`RESP_WAIT_SIG(clk, dut_start_ready, 0)
	end while(1);
end

initial begin
	do begin
		dut_finish_valid = 0;
		`WAIT_SIG(clk, (dut_start_valid & dut_start_ready), 0)
		dut_finish_valid_after_start_handshake_delay = $urandom() % `VALID_READY_DELAY;
		`APPL_WAIT_CYC(clk, dut_finish_valid_after_start_handshake_delay)
		dut_finish_valid = 1;
		`APPL_WAIT_SIG(clk, (dut_finish_valid & dut_finish_ready), 0)		
	end while(1);
end
`else

`endif

// ================================================================================================================================================


// ================================================================================================================================================
// clk generator
initial begin
	clk = 0;
	while(1) begin
		clk = 0;
		#(`CLK_LO);
		clk = 1;
		#(`CLK_HI);
	end
end
// reset and start signal generator
initial begin
	rst_n = 0;
	simulation_start = 0;
	`APPL_WAIT_CYC(clk, 3)
	rst_n = 1;
	`APPL_WAIT_CYC(clk, 2)
	$display("TB: simulation starts!");
	simulation_start <= 1;
end
// ================================================================================================================================================


endmodule
