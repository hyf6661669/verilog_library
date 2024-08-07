module fpdiv_scalar_r64_wrapper #(
	// Put some parameters here, which can be changed by other modules
	parameter FDIV_QDS_ARCH = 2,
	parameter UF_AFTER_ROUNDING = 1
)(
	input  logic 			start_valid_i,
	output logic 			start_ready_o,
	input  logic [ 2-1:0] 	fp_format_i,
	input  logic [64-1:0] 	opa_i,
	input  logic [64-1:0] 	opb_i,
	input  logic [ 3-1:0] 	rm_i,

	output logic 			finish_valid_o,
	input  logic 			finish_ready_i,
	output logic [64-1:0] 	fpdiv_res_o,
	output logic [ 5-1:0] 	fflags_o,

	input  logic 			clk,
	input  logic 			rst_n
);


logic start_valid_i_d;
logic start_valid_i_q;
logic start_ready_o_d;
logic start_ready_o_q;
logic [2 - 1:0] fp_format_i_d;
logic [2 - 1:0] fp_format_i_q;
logic [64 - 1:0] opa_i_d;
logic [64 - 1:0] opa_i_q;
logic [64 - 1:0] opb_i_d;
logic [64 - 1:0] opb_i_q;
logic [3 - 1:0] rm_i_d;
logic [3 - 1:0] rm_i_q;
logic finish_valid_o_d;
logic finish_valid_o_q;
logic finish_ready_i_d;
logic finish_ready_i_q;
logic [64-1:0] fpdiv_res_o_d;
logic [64-1:0] fpdiv_res_o_q;
logic [ 5-1:0] fflags_o_d;
logic [ 5-1:0] fflags_o_q;

always_ff @(posedge clk) begin
	start_valid_i_q <= start_valid_i_d;
    start_ready_o_q <= start_ready_o_d;
    fp_format_i_q <= fp_format_i_d;
    opa_i_q <= opa_i_d;
    opb_i_q <= opb_i_d;
    rm_i_q <= rm_i_d;
    finish_valid_o_q <= finish_valid_o_d;
    finish_ready_i_q <= finish_ready_i_d;
    fpdiv_res_o_q <= fpdiv_res_o_d;
    fflags_o_q <= fflags_o_d;
end


assign start_valid_i_d = start_valid_i;
assign fp_format_i_d = fp_format_i;
assign opa_i_d = opa_i;
assign opb_i_d = opb_i;
assign rm_i_d = rm_i;
assign finish_ready_i_d = finish_ready_i;


assign start_ready_o = start_ready_o_q;
assign finish_valid_o = finish_valid_o_q;
assign fpdiv_res_o = fpdiv_res_o_q;
assign fflags_o = fflags_o_q;

fpdiv_scalar_r64 u_dut (
	.start_valid_i              (start_valid_i_q),
	.start_ready_o              (start_ready_o_d),
	.flush_i                    ('0),
	.fp_format_i                (fp_format_i_q),
	.opa_i                      (opa_i_q),
	.opb_i                      (opb_i_q),
	.rm_i                       (rm_i_q),
	.finish_valid_o             (finish_valid_o_d),
	.finish_ready_i             (finish_ready_i_q),
	.fpdiv_res_o                (fpdiv_res_o_d),
	.fflags_o                   (fflags_o_d),
	.clk                        (clk),
	.rst_n                      (rst_n)
);



endmodule 