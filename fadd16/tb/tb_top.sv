// ========================================================================================================
// File Name			: tb_top_fadd.sv
// Author				: HYF
// How to Contact		: hyf_sysu@qq.com
// Created Time    		: June 2nd 2024, 11:24:14
// Last Modified Time   : 
// ========================================================================================================
// Description	:
// 
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

`define MAX_ERR_COUNT 10

`ifndef DUT_LATENCY
	`define DUT_LATENCY 2
`endif

`define USE_ZERO_DELAY
// `define USE_SHORT_DELAY
// `define USE_MIDDLE_DELAY
// `define USE_LONG_DELAY

`include "tb_defines.svh"
// If DUT doesn't have valid-ready control bit itself, don't define this..
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

`ifndef FP16_TEST_NUM
	`define FP16_TEST_NUM 2 ** 9
`endif

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

import "DPI-C" function void cmodel_check_result (
	input  bit [31:0] acq_count,
	input  bit [31:0] err_count,
	input  bit [31:0] opa_hi,
	input  bit [31:0] opa_lo,
	input  bit [31:0] opb_hi,
	input  bit [31:0] opb_lo,
	input  bit [31:0] opc_hi,
	input  bit [31:0] opc_lo,
	input  bit [31:0] is_fma,
	input  bit [31:0] is_fmul,
	input  bit [31:0] fp_format,
	input  bit [31:0] rm,
	input  bit [31:0] dut_res_hi,
	input  bit [31:0] dut_res_lo,
	input  bit [31:0] dut_fflags,
	output bit [31:0] compare_ok
);
import "DPI-C" function void print_error(input bit [31:0] err_count, input bit [31:0] seed);
import "DPI-C" function void gencases_init(input bit [31:0] seed, input bit [31:0] level);
import "DPI-C" function void gencases_for_f16(output bit [15:0] fp16_opa, output bit [15:0] fp16_opb);
import "DPI-C" function void gencases_for_f32(output bit [31:0] fp32_opa, output bit [31:0] fp32_opb);
import "DPI-C" function void gencases_for_f64(
	output bit [31:0] fp64_opa_hi,
	output bit [31:0] fp64_opa_lo, 
	output bit [31:0] fp64_opb_hi, 
	output bit [31:0] fp64_opb_lo
);

import "DPI-C" function void gencases_for_f16_fma(output bit [15:0] fp16_opa, output bit [15:0] fp16_opb, output bit [15:0] fp16_opc);
import "DPI-C" function void gencases_for_f32_fma(output bit [31:0] fp32_opa, output bit [31:0] fp32_opb, output bit [31:0] fp32_opc);
import "DPI-C" function void gencases_for_f64_fma(
	output bit [31:0] fp64_opa_hi,
	output bit [31:0] fp64_opa_lo, 
	output bit [31:0] fp64_opb_hi, 
	output bit [31:0] fp64_opb_lo,
	output bit [31:0] fp64_opc_hi, 
	output bit [31:0] fp64_opc_lo
);

// ==================================================================================================================================================
// signals
// ==================================================================================================================================================

// common signals
bit clk;
bit rst_n;
int i;
genvar j;
bit simulation_start;
bit stim_end;
bit acq_trig;
bit [31:0] acq_count;
bit [31:0] err_count;
bit [31:0] seed_used;

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
bit [ 1-1:0] dut_is_fma;
bit [ 3-1:0] dut_fp_format;
bit [64-1:0] dut_opa;
bit [64-1:0] dut_opb;
bit [64-1:0] dut_opc;
bit [ 3-1:0] dut_rm;

bit [ 1-1:0] dut_is_fma_q [`DUT_LATENCY - 1:0];
bit [ 3-1:0] dut_fp_format_q [`DUT_LATENCY - 1:0];
bit [64-1:0] dut_opa_q [`DUT_LATENCY - 1:0];
bit [64-1:0] dut_opb_q [`DUT_LATENCY - 1:0];
bit [64-1:0] dut_opc_q [`DUT_LATENCY - 1:0];
bit [ 3-1:0] dut_rm_q [`DUT_LATENCY - 1:0];

bit [64-1:0] dut_res;
bit [ 5-1:0] dut_fflags;

logic fma_mul_exp_gt_inf;
logic fma_mul_sticky;
logic fma_inputs_nan_inf;
logic [117 - 1:0] fma_intermediate_res;

// ==================================================================================================================================================
// main codes
// ==================================================================================================================================================



// ================================================================================================================================================
// application process

initial begin
	dut_start_valid = 0;
	acq_trig = 0;
	stim_end = 0;

	seed_used = $get_initial_random_seed();

	`APPL_WAIT_SIG(clk, simulation_start, 0)
	$display("simulation seed = %d\n", seed_used);
	$display("TB: stimuli application starts!");

	acq_trig = 1;
	`APPL_WAIT_CYC(clk, 2)
	acq_trig = 0;

	dut_opa = '0;
	dut_opb = '0;
	dut_opc = '0;

    `include "tb_stim.svh"
	
	`WAIT_CYC(clk, 5)
	stim_end = 1;
end

// ================================================================================================================================================

// ================================================================================================================================================
// acquisition process

generate
for(j = 0; j < `DUT_LATENCY; j++) begin

if(j == 0) begin
    always_ff @(posedge clk) begin
        if(~rst_n) begin
            dut_is_fma_q[j] <= '0;
            dut_fp_format_q[j] <= '0;
            dut_opa_q[j] <= '0;
            dut_opb_q[j] <= '0;
            dut_opc_q[j] <= '0;
            dut_rm_q[j] <= '0;
        end else begin
            dut_is_fma_q[j] <= dut_is_fma;
            dut_fp_format_q[j] <= dut_fp_format;
            dut_opa_q[j] <= dut_opa;
            dut_opb_q[j] <= dut_opb;
            dut_opc_q[j] <= dut_opc;
            dut_rm_q[j] <= dut_rm;
        end
    end
end else begin
    always_ff @(posedge clk) begin
        if(~rst_n) begin
            dut_is_fma_q[j] <= '0;
            dut_fp_format_q[j] <= '0;
            dut_opa_q[j] <= '0;
            dut_opb_q[j] <= '0;
            dut_opc_q[j] <= '0;
            dut_rm_q[j] <= '0;
        end else begin
            dut_is_fma_q[j] <= dut_is_fma_q[j - 1];
            dut_fp_format_q[j] <= dut_fp_format_q[j - 1];
            dut_opa_q[j] <= dut_opa_q[j - 1];
            dut_opb_q[j] <= dut_opb_q[j - 1];
            dut_opc_q[j] <= dut_opc_q[j - 1];
            dut_rm_q[j] <= dut_rm_q[j - 1];
        end
    end
end


end

endgenerate


initial begin
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

        `RESP_WAIT_SIG(clk, dut_finish_ready, stim_end)
        if(1) begin
            cmodel_check_result (
                .acq_count          (acq_count),
                .err_count          (err_count),
                .opa_hi             (dut_opa_q[`DUT_LATENCY - 1][63:32]),
                .opa_lo             (dut_opa_q[`DUT_LATENCY - 1][31:00]),
                .opb_hi             (dut_opb_q[`DUT_LATENCY - 1][63:32]),
                .opb_lo             (dut_opb_q[`DUT_LATENCY - 1][31:00]),
                .opc_hi             (dut_opc_q[`DUT_LATENCY - 1][63:32]),
                .opc_lo             (dut_opc_q[`DUT_LATENCY - 1][31:00]),
                .is_fma             (dut_is_fma_q[`DUT_LATENCY - 1]),
                .is_fmul            ('0),
                .fp_format          (dut_fp_format_q[`DUT_LATENCY - 1]),
                .rm                 (dut_rm_q[`DUT_LATENCY - 1]),
                .dut_res_hi         (dut_res[63:32]),
                .dut_res_lo         (dut_res[31:00]),
                .dut_fflags         (dut_fflags),
                .compare_ok         (compare_ok)
            );
        end
        
		acq_count++;		
		if((compare_ok == 0) | (compare_ok == 1'bX))
			err_count++;

		if(err_count == `MAX_ERR_COUNT) begin
			$display("finished_test_num = %d, error_test_num = %d", acq_count, err_count);
			$display("Too many ERRORs, stop simulation!!!");
			$display("Printing error information...");
			print_error(err_count, seed_used);
			$stop();
		end

        
        dut_finish_ready = 0;

	end while(stim_end == 0);

	`WAIT_CYC(clk, 3)
	$display("finished_test_num = %d, error_test_num = %d", acq_count, err_count);
	$display("response acquisition finishes!");
	$display("TB finishes!");
	$display("Printing error information...");
	print_error(err_count, seed_used);
	$stop();
end

// ================================================================================================================================================

// ================================================================================================================================================
// calculate expected result


// ================================================================================================================================================
// Instantiate DUT here.

fmul_simulation u_fmul_simulation (
	.opa_i						(dut_opa),
	.opb_i						(dut_opb),
	.format_i					(3'b001),
	.rm_i						(dut_rm),
	.fma_mul_exp_gt_inf_o		(fma_mul_exp_gt_inf),
	.fma_mul_sticky_o			(fma_mul_sticky),
	.fma_inputs_nan_inf_o		(fma_inputs_nan_inf),
	.fma_intermediate_res_o		(fma_intermediate_res),
	.fmul_res_o					(),
	.fmul_fflags_o				()
);

assign dut_start_ready = '1;
assign dut_finish_valid = '1;

fadd16 #(
	.UF_AFTER_ROUNDING(1)
) u_dut (
	.opa_i						(dut_is_fma ? dut_opc[15:0] : dut_opa[15:0]),
	.opb_i						(dut_is_fma ? fma_intermediate_res[0 +: 27] : {dut_opb[15:0], {(27 - 16){1'b0}}}),
	.rm_i						(dut_rm),
	.s0_vld_i					(1'b1),
	.fma_vld_i					(dut_is_fma),
	.fma_mul_exp_gt_inf_i		(fma_mul_exp_gt_inf),
	.fma_mul_sticky_i			(fma_mul_sticky),
	.fma_inputs_nan_inf_i		(fma_inputs_nan_inf),

	.fadd_res_o					(dut_res[15:0]),
	.fadd_fflags_o				(dut_fflags),

	.clk						(clk),
	.rst_n						(rst_n)
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
