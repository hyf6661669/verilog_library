// ========================================================================================================
// File Name			: tb_top.sv
// Author				: HYF
// How to Contact		: hyf_sysu@qq.com
// Created Time    		: 2021-12-29 16:42:39
// Last Modified Time   : 2022-01-02 11:17:35
// ========================================================================================================
// Description	:
// TB for FPDIV_FRAC.
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


localparam FP64_RANDOM_NUM = 2 ** 18;
localparam FP32_RANDOM_NUM = 2 ** 18;
localparam FP16_RANDOM_NUM = 2 ** 18;

typedef bit [31:0][2] bit_to_array;

localparam RM_RNE = 3'b000;
localparam RM_RTZ = 3'b001;
localparam RM_RDN = 3'b010;
localparam RM_RUP = 3'b011;
localparam RM_RMM = 3'b100;


// ==================================================================================================================================================
// functions
// ==================================================================================================================================================


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

logic compare_ok;
logic dut_start_valid;
logic dut_start_ready;
logic dut_finish_valid;
logic dut_finish_ready;
// tb向dut发送的后一个start_valid和前一个finish_handshake之间的延迟
logic [31:0] dut_start_valid_after_finish_handshake_delay;
// tb向dut发送了start_valid之后，dut向tb发送start_ready之间的延迟
logic [31:0] dut_start_ready_after_start_valid_delay;
// tb发送到dut的finish_ready和dut发送到tb中的finish_valid之间的延迟
logic [31:0] dut_finish_ready_after_finish_valid_delay;
// start_valid = 1之后，dut向tb发送的finish_valid之间的延迟
logic [31:0] dut_finish_valid_after_start_handshake_delay;


// signals related with DUT.
logic [ 2-1:0] fp_format;
logic [53-1:0] fpdiv_opa_frac;
logic [53-1:0] fpdiv_opb_frac;
logic [107-1:0] ref_opa_frac;
logic [107-1:0] ref_opb_frac;
logic [107-1:0] ref_fpdiv_frac_pre;

logic [55-1:0] dut_fpdiv_frac_res;
logic [54-1:0] ref_fpdiv_frac_res;

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

		
		if((compare_ok == 0) | (compare_ok == 1'bX)) begin
			$display("ERROR FOUND:");
			
			$display("[%d]:", acq_count);
			$display("fpdiv_opa = %53b", fpdiv_opa_frac);
			$display("fpdiv_opb = %53b", fpdiv_opb_frac);
			$display("ref_fpdiv_frac_res = %54b", ref_fpdiv_frac_res[53:0]);
			$display("dut_fpdiv_frac_res = %55b", dut_fpdiv_frac_res);

			err_count++;
		end

		// $display("[%d]:", acq_count);
		// $display("fpdiv_opa = %53b", fpdiv_opa_frac);
		// $display("fpdiv_opb = %53b", fpdiv_opb_frac);
		// $display("ref_fpdiv_frac_res = %54b", ref_fpdiv_frac_res[53:0]);
		// $display("dut_fpdiv_frac_res = %55b", dut_fpdiv_frac_res);
		

		if(err_count == `MAX_ERROR_COUNT) begin
			$display("finished_test_num = %d, error_test_num = %d", acq_count, err_count);
			$display("Too many ERRORs, stop simulation!!!");
			$display("Printing error information...");
			$stop();
		end

		acq_count++;
		`RESP_WAIT_SIG(clk, dut_finish_ready, stim_end)
		dut_finish_ready = 0;

		// if((acq_count != 0) & (acq_count % (2 ** 16) == 0))
		// 	$display("Simulation is still running !!!");

	end while(stim_end == 0);

	`WAIT_CYC(clk, 3)
	$display("finished_test_num = %d, error_test_num = %d", acq_count, err_count);
	$display("response acquisition finishes!");
	$display("TB finishes!");
	$display("Printing error information...");
	$stop();
end

// ================================================================================================================================================

// ================================================================================================================================================
// calculate expected result

always_comb begin
	ref_opa_frac = 
	(fp_format == 2'd0) ? {fpdiv_opa_frac[0 +: 11], {(106 - 11){1'b0}}} : 
	(fp_format == 2'd1) ? {fpdiv_opa_frac[0 +: 24], {(106 - 24){1'b0}}} : 
	{fpdiv_opa_frac[0 +: 53], {(106 - 53){1'b0}}};

	ref_opb_frac = 
	(fp_format == 2'd0) ? {54'b0, fpdiv_opb_frac[0 +: 11], {(53 - 11){1'b0}}} : 
	(fp_format == 2'd1) ? {54'b0, fpdiv_opb_frac[0 +: 24], {(53 - 24){1'b0}}} : 
	{54'b0, fpdiv_opb_frac[0 +: 53], {(53 - 53){1'b0}}};

	// Mkae sure we get 12/25/54-bit frac
	if((fp_format == 2'd0) & (fpdiv_opa_frac[0 +: 11] < fpdiv_opb_frac[0 +: 11]))
		ref_opa_frac = ref_opa_frac << 1;
	else if((fp_format == 2'd1) & (fpdiv_opa_frac[0 +: 24] < fpdiv_opb_frac[0 +: 24]))
		ref_opa_frac = ref_opa_frac << 1;
	else if(fpdiv_opa_frac[0 +: 53] < fpdiv_opb_frac[0 +: 53])
		ref_opa_frac = ref_opa_frac << 1;

	ref_fpdiv_frac_pre = ref_opa_frac / ref_opb_frac;
	ref_fpdiv_frac_res = ref_fpdiv_frac_pre[54] ? ref_fpdiv_frac_pre[54:1] : ref_fpdiv_frac_pre[53:0];

	// If we do initialization for the integer part of frac, after the srt iter is finished, the accurate frac width we could get is:
	// fp64: 9 * 6 + 1 = 55
	// fp32: 4 * 6 + 1 = 25
	// fp16: 2 * 6 + 1 = 13
	compare_ok = 
	(fp_format == 2'd0) ? (ref_fpdiv_frac_res[53 -: 13] == dut_fpdiv_frac_res[0 +: 13]) : 
	(fp_format == 2'd1) ? (ref_fpdiv_frac_res[53 -: 25] == dut_fpdiv_frac_res[0 +: 25]) : 
	(ref_fpdiv_frac_res[53 -: 54] == dut_fpdiv_frac_res[1 +: 54]);

	// If we don't do initialization for the integer part of frac, after the srt iter is finished, the accurate frac width we could get is:
	// fp64: 9 * 6 - 1 = 53
	// fp64: 4 * 6 - 1 = 23
	// fp64: 2 * 6 - 1 = 11
	// compare_ok = 
	// (fp_format == 2'd0) ? (ref_fpdiv_frac_res[53 -: 11] == dut_fpdiv_frac_res[0 +: 11]) : 
	// (fp_format == 2'd1) ? (ref_fpdiv_frac_res[53 -: 23] == dut_fpdiv_frac_res[0 +: 23]) : 
	// (ref_fpdiv_frac_res[53 -: 53] == dut_fpdiv_frac_res[0 +: 53]);
end


// ================================================================================================================================================
// Instantiate DUT here.

// fpdiv_frac
// fpdiv_frac_v2
fpdiv_frac_v3
u_dut (
	.start_valid_i(dut_start_valid),
	.start_ready_o(dut_start_ready),
	.flush_i(1'b0),
	.fp_format_i(fp_format),
	.a_frac_i(fpdiv_opa_frac),
	.b_frac_i(fpdiv_opb_frac),

	.finish_valid_o(dut_finish_valid),
	.finish_ready_i(dut_finish_ready),
	.fpdiv_frac_o(dut_fpdiv_frac_res),

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
