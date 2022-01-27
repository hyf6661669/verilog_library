// ========================================================================================================
// File Name			: tb_top.sv
// Author				: HYF
// How to Contact		: hyf_sysu@qq.com
// Created Time    		: 2022-01-24 21:57:45
// Last Modified Time   : 2022-01-26 09:27:56
// ========================================================================================================
// Description	:
// TB for intdiv.
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

localparam OPCODE_SIGNED   = 1'b1;
localparam OPCODE_UNSIGNED = 1'b0;

`ifndef SDIV_TEST_NUM
	`define SDIV_TEST_NUM 2 ** 15
`endif
`ifndef UDIV_TEST_NUM
	`define UDIV_TEST_NUM 2 ** 15
`endif
localparam SDIV_TEST_NUM = `SDIV_TEST_NUM;
localparam UDIV_TEST_NUM = `UDIV_TEST_NUM;


localparam U64_POS_MAX = {(64){1'b1}};
localparam S64_POS_MAX  = {1'b0, {(63){1'b1}}};
localparam S64_NEG_MIN  = {1'b1, {(63){1'b0}}};
localparam S64_NEG_ONE  = {(64){1'b1}};

localparam U32_POS_MAX = {(32){1'b1}};
localparam S32_POS_MAX  = {1'b0, {(31){1'b1}}};
localparam S32_NEG_MIN  = {1'b1, {(31){1'b0}}};
localparam S32_NEG_ONE  = {(32){1'b1}};

localparam U16_POS_MAX = {(16){1'b1}};
localparam S16_POS_MAX  = {1'b0, {(15){1'b1}}};
localparam S16_NEG_MIN  = {1'b1, {(15){1'b0}}};
localparam S16_NEG_ONE  = {(16){1'b1}};

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
int fptr;

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
bit [ 1-1:0] opcode;
bit [64-1:0] dividend_64;
bit [64-1:0] dividend_abs_64;
bit [64-1:0] divisor_64;
bit [64-1:0] divisor_abs_64;

bit [32-1:0] dividend_32;
bit [32-1:0] dividend_abs_32;
bit [32-1:0] divisor_32;
bit [32-1:0] divisor_abs_32;

bit [16-1:0] dividend_16;
bit [16-1:0] dividend_abs_16;
bit [16-1:0] divisor_16;
bit [16-1:0] divisor_abs_16;

bit [5:0] dividend_64_lzc;
bit [4:0] dividend_32_lzc;
bit [3:0] dividend_16_lzc;

bit [5:0] divisor_64_lzc;
bit [4:0] divisor_32_lzc;
bit [3:0] divisor_16_lzc;

bit neg_quotient_64;
bit neg_remainder_64;
bit neg_quotient_32;
bit neg_remainder_32;
bit neg_quotient_16;
bit neg_remainder_16;
bit [64-1:0] quotient_64;
bit [64-1:0] remainder_64;
bit [32-1:0] quotient_32;
bit [32-1:0] remainder_32;
bit [16-1:0] quotient_16;
bit [16-1:0] remainder_16;
bit divisor_is_zero_64;
bit divisor_is_zero_32;
bit divisor_is_zero_16;

bit [64-1:0] dut_quotient_64;
bit [64-1:0] dut_remainder_64;
bit [32-1:0] dut_quotient_32;
bit [32-1:0] dut_remainder_32;
bit [16-1:0] dut_quotient_16;
bit [16-1:0] dut_remainder_16;
bit dut_divisor_is_zero_64;
bit dut_divisor_is_zero_32;
bit dut_divisor_is_zero_16;

// ==================================================================================================================================================
// main codes
// ==================================================================================================================================================



// ================================================================================================================================================
// application process

initial begin
	dividend_64 = 0;
	divisor_64 = 0;
	dividend_32 = 0;
	divisor_32 = 0;
	dividend_32 = 0;
	divisor_32 = 0;
	opcode = OPCODE_SIGNED;
	dut_start_valid = 0;
	acq_trig = 0;
	stim_end = 0;

	`APPL_WAIT_SIG(clk, simulation_start, 0)
	$display("TB: stimuli application starts!");

	acq_trig = 1;
	`APPL_WAIT_CYC(clk, 2)
	acq_trig = 0;

	`include "tb_stim_unsigned.svh"
	`include "tb_stim_signed.svh"
	
	// `WAIT_CYC(clk, 5)
	stim_end = 1;
end

// ================================================================================================================================================

// ================================================================================================================================================
// acquisition process

initial begin
	dut_finish_ready = 0;
	fptr = $fopen("result.log", "w+");
	$display("TB: response acquisition starts!");

	// wait for acquisition trigger
	do begin
		`RESP_WAIT_CYC(clk, 1)
		if(stim_end == 1)
		begin
			$display("response acquisition finishes!");
			$display("TB finishes!");
			$fclose(fptr);
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
			// $display("ERROR FOUND:");

			$fdisplay(fptr, "[%d]:", acq_count);

`ifdef DUT_WIDTH_64
			$fdisplay(fptr, "dividend = %08H%08H", dividend_64[63:32], dividend_64[31:0]);
			$fdisplay(fptr, "divisor  = %08H%08H", divisor_64[63:32], divisor_64[31:0]);
			$fdisplay(fptr, "opcode   = %b", opcode);
			$fdisplay(fptr, "ref_quo  = %08H%08H", quotient_64[63:32], quotient_64[31:0]);
			$fdisplay(fptr, "dut_quo  = %08H%08H", dut_quotient_64[63:32], dut_quotient_64[31:0]);
			$fdisplay(fptr, "ref_rem  = %08H%08H", remainder_64[63:32], remainder_64[31:0]);
			$fdisplay(fptr, "dut_rem  = %08H%08H", dut_remainder_64[63:32], dut_remainder_64[31:0]);
`elsif DUT_WIDTH_32
			$fdisplay(fptr, "dividend = %08H", dividend_32);
			$fdisplay(fptr, "divisor  = %08H", divisor_32);
			$fdisplay(fptr, "opcode   = %b", opcode);
			$fdisplay(fptr, "ref_quo  = %08H", quotient_32);
			$fdisplay(fptr, "dut_quo  = %08H", dut_quotient_32);
			$fdisplay(fptr, "ref_rem  = %08H", remainder_32);
			$fdisplay(fptr, "dut_rem  = %08H", dut_remainder_32);
`else
			$fdisplay(fptr, "dividend = %04H", dividend_16);
			$fdisplay(fptr, "divisor  = %04H", divisor_16);
			$fdisplay(fptr, "opcode   = %b", opcode);
			$fdisplay(fptr, "ref_quo  = %04H", quotient_16);
			$fdisplay(fptr, "dut_quo  = %04H", dut_quotient_16);
			$fdisplay(fptr, "ref_rem  = %04H", remainder_16);
			$fdisplay(fptr, "dut_rem  = %04H", dut_remainder_16);
`endif

			err_count++;
		end

		if(err_count == `MAX_ERROR_COUNT) begin
			$fdisplay(fptr, "finished_test_num = %d, error_test_num = %d", acq_count, err_count);
			$fdisplay(fptr, "Too many ERRORs, stop simulation!!!");
			$fclose(fptr);
			$stop();
		end

		acq_count++;
		`RESP_WAIT_SIG(clk, dut_finish_ready, stim_end)
		dut_finish_ready = 0;

		// if((acq_count != 0) & (acq_count % (2 ** 16) == 0))
		// 	$display("Simulation is still running !!!");

	end while(stim_end == 0);

	`WAIT_CYC(clk, 5)
	$fdisplay(fptr, "\n");
	$fdisplay(fptr, "finished_test_num = %d, error_test_num = %d", acq_count, err_count);
	$display("response acquisition finishes!");
	$display("TB finishes!");
	$fclose(fptr);
	$stop();
end

// ================================================================================================================================================

// ================================================================================================================================================
// calculate expected result

always_comb begin
	neg_quotient_64 = (opcode == OPCODE_SIGNED) & (dividend_64[63] ^ divisor_64[63]);
	neg_remainder_64 = (opcode == OPCODE_SIGNED) & (dividend_64[63]);
	neg_quotient_32 = (opcode == OPCODE_SIGNED) & (dividend_32[31] ^ divisor_32[31]);
	neg_remainder_32 = (opcode == OPCODE_SIGNED) & (dividend_32[31]);
	neg_quotient_16 = (opcode == OPCODE_SIGNED) & (dividend_16[15] ^ divisor_16[15]);
	neg_remainder_16 = (opcode == OPCODE_SIGNED) & (dividend_16[15]);

	dividend_abs_64 = (dividend_64[63] & (opcode == OPCODE_SIGNED)) ? -dividend_64 : dividend_64;
	divisor_abs_64 = (divisor_64[63] & (opcode == OPCODE_SIGNED)) ? -divisor_64 : divisor_64;
	dividend_abs_32 = (dividend_32[31] & (opcode == OPCODE_SIGNED)) ? -dividend_32 : dividend_32;
	divisor_abs_32 = (divisor_32[31] & (opcode == OPCODE_SIGNED)) ? -divisor_32 : divisor_32;
	dividend_abs_16 = (dividend_16[15] & (opcode == OPCODE_SIGNED)) ? -dividend_16 : dividend_16;
	divisor_abs_16 = (divisor_16[15] & (opcode == OPCODE_SIGNED)) ? -divisor_16 : divisor_16;

	quotient_64 = neg_quotient_64 ? -(dividend_abs_64 / divisor_abs_64) : (dividend_abs_64 / divisor_abs_64);
	remainder_64 = neg_remainder_64 ? -(dividend_abs_64 % divisor_abs_64) : (dividend_abs_64 % divisor_abs_64);
	quotient_32 = neg_quotient_32 ? -(dividend_abs_32 / divisor_abs_32) : (dividend_abs_32 / divisor_abs_32);
	remainder_32 = neg_remainder_32 ? -(dividend_abs_32 % divisor_abs_32) : (dividend_abs_32 % divisor_abs_32);
	quotient_16 = neg_quotient_16 ? -(dividend_abs_16 / divisor_abs_16) : (dividend_abs_16 / divisor_abs_16);
	remainder_16 = neg_remainder_16 ? -(dividend_abs_16 % divisor_abs_16) : (dividend_abs_16 % divisor_abs_16);

	divisor_is_zero_64 = (divisor_64 == 0);
	divisor_is_zero_32 = (divisor_32 == 0);
	divisor_is_zero_16 = (divisor_16 == 0);

	if(opcode == OPCODE_SIGNED) begin
		if(divisor_64 == 0) begin
			quotient_64 = U64_POS_MAX;
			remainder_64 = dividend_64;
		end
		else if((dividend_64 == S64_NEG_MIN) & (divisor_64 == S64_NEG_ONE)) begin
			quotient_64 = S64_NEG_MIN;
			remainder_64 = 0;
		end

		if(divisor_32 == 0) begin
			quotient_32 = U32_POS_MAX;
			remainder_32 = dividend_32;
		end
		else if((dividend_32 == S32_NEG_MIN) & (divisor_32 == S32_NEG_ONE)) begin
			quotient_32 = S32_NEG_MIN;
			remainder_32 = 0;
		end

		if(divisor_16 == 0) begin
			quotient_16 = U16_POS_MAX;
			remainder_16 = dividend_16;
		end
		else if((dividend_16 == S16_NEG_MIN) & (divisor_16 == S16_NEG_ONE)) begin
			quotient_16 = S16_NEG_MIN;
			remainder_16 = 0;
		end
	end
	else begin
		if(divisor_64 == 0) begin
			quotient_64 = U64_POS_MAX;
			remainder_64 = dividend_64;
		end

		if(divisor_32 == 0) begin
			quotient_32 = U32_POS_MAX;
			remainder_32 = dividend_32;
		end

		if(divisor_16 == 0) begin
			quotient_16 = U16_POS_MAX;
			remainder_16 = dividend_16;
		end
	end


`ifdef DUT_WIDTH_64
		compare_ok = (quotient_64 == dut_quotient_64) & (remainder_64 == dut_remainder_64) & (divisor_is_zero_64 == dut_divisor_is_zero_64);
`elsif DUT_WIDTH_32
		compare_ok = (quotient_32 == dut_quotient_32) & (remainder_32 == dut_remainder_32) & (divisor_is_zero_32 == dut_divisor_is_zero_32);
`else
		compare_ok = (quotient_16 == dut_quotient_16) & (remainder_16 == dut_remainder_16) & (divisor_is_zero_16 == dut_divisor_is_zero_16);
`endif

end

// ================================================================================================================================================
// Instantiate DUT here.

`ifdef DUT_WIDTH_64
int_div_radix_16_v4 #(
	.WIDTH(64)
) u_dut (
	.flush_i(1'b0),
	.div_start_valid_i(dut_start_valid),
	.div_start_ready_o(dut_start_ready),
	.signed_op_i(opcode),
	.dividend_i(dividend_64),
	.divisor_i(divisor_64),
	.div_finish_valid_o(dut_finish_valid),
	.div_finish_ready_i(dut_finish_ready),
	.quotient_o(dut_quotient_64),
	.remainder_o(dut_remainder_64),
	.divisor_is_zero_o(dut_divisor_is_zero_64),

	.clk(clk),
	.rst_n(rst_n)
);
`elsif DUT_WIDTH_32
int_div_radix_16_v4 #(
	.WIDTH(32)
) u_dut (
	.flush_i(1'b0),
	.div_start_valid_i(dut_start_valid),
	.div_start_ready_o(dut_start_ready),
	.signed_op_i(opcode),
	.dividend_i(dividend_32),
	.divisor_i(divisor_32),
	.div_finish_valid_o(dut_finish_valid),
	.div_finish_ready_i(dut_finish_ready),
	.quotient_o(dut_quotient_32),
	.remainder_o(dut_remainder_32),
	.divisor_is_zero_o(dut_divisor_is_zero_32),

	.clk(clk),
	.rst_n(rst_n)
);
`else
int_div_radix_16_v4 #(
	.WIDTH(16)
) u_dut (
	.flush_i(1'b0),
	.div_start_valid_i(dut_start_valid),
	.div_start_ready_o(dut_start_ready),
	.signed_op_i(opcode),
	.dividend_i(dividend_16),
	.divisor_i(divisor_16),
	.div_finish_valid_o(dut_finish_valid),
	.div_finish_ready_i(dut_finish_ready),
	.quotient_o(dut_quotient_16),
	.remainder_o(dut_remainder_16),
	.divisor_is_zero_o(dut_divisor_is_zero_16),

	.clk(clk),
	.rst_n(rst_n)
);
`endif

// ================================================================================================================================================
// Simulate valid-ready signals of dut

`ifndef DUT_HAS_VALID_READY
initial begin
	do begin
		dut_start_ready = 0;
		`RESP_WAIT_COMB_SIG(clk, dut_start_valid, 0)
		dut_start_ready_after_start_valid_delay = $urandom() % `VALID_READY_DELAY;
		`RESP_WAIT_CYC(clk, dut_start_ready_after_start_valid_delay)
		dut_start_ready = 1;
		`RESP_WAIT_SIG(clk, dut_start_ready, 0)
	end while(1);
end

initial begin
	do begin
		dut_finish_valid = 0;
		`WAIT_COMB_SIG(clk, (dut_start_valid & dut_start_ready), 0)
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
	`APPL_WAIT_CYC(clk, 5)
	rst_n = 1;
	`APPL_WAIT_CYC(clk, 5)
	$display("TB: simulation starts!");
	simulation_start <= 1;
end
// ================================================================================================================================================


endmodule
