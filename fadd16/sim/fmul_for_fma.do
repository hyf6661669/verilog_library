add wave -position insertpoint -expand -group CLK_RST {sim:/tb_top/clk}
add wave -position insertpoint -expand -group CLK_RST {sim:/tb_top/rst_n}

add wave -position insertpoint -radix unsigned {sim:/tb_top/acq_count}
add wave -position insertpoint {sim:/tb_top/dut_start_valid}
add wave -position insertpoint {sim:/tb_top/dut_start_ready}
add wave -position insertpoint {sim:/tb_top/dut_finish_valid}
add wave -position insertpoint {sim:/tb_top/dut_finish_ready}
add wave -position insertpoint {sim:/tb_top/dut_opa}
add wave -position insertpoint {sim:/tb_top/dut_opb}

add wave -position insertpoint {sim:/tb_top/u_dut/signa}
add wave -position insertpoint {sim:/tb_top/u_dut/signb}
add wave -position insertpoint {sim:/tb_top/u_dut/sign_mul}
add wave -position insertpoint {sim:/tb_top/u_dut/expa}
add wave -position insertpoint {sim:/tb_top/u_dut/expb}
add wave -position insertpoint {sim:/tb_top/u_dut/expa_all_1}
add wave -position insertpoint {sim:/tb_top/u_dut/expb_all_1}
add wave -position insertpoint {sim:/tb_top/u_dut/expa_zero}
add wave -position insertpoint {sim:/tb_top/u_dut/expb_zero}
add wave -position insertpoint {sim:/tb_top/u_dut/expa_adj}
add wave -position insertpoint {sim:/tb_top/u_dut/expb_adj}

add wave -position insertpoint {sim:/tb_top/u_dut/siga}
add wave -position insertpoint {sim:/tb_top/u_dut/sigb}
add wave -position insertpoint {sim:/tb_top/u_dut/opa_zero}
add wave -position insertpoint {sim:/tb_top/u_dut/opb_zero}
add wave -position insertpoint {sim:/tb_top/u_dut/opa_qnan}
add wave -position insertpoint {sim:/tb_top/u_dut/opb_qnan}
add wave -position insertpoint {sim:/tb_top/u_dut/opa_snan}
add wave -position insertpoint {sim:/tb_top/u_dut/opb_snan}
add wave -position insertpoint {sim:/tb_top/u_dut/opa_inf}
add wave -position insertpoint {sim:/tb_top/u_dut/opb_inf}

add wave -position insertpoint {sim:/tb_top/u_dut/expa_unbiased}
add wave -position insertpoint {sim:/tb_top/u_dut/expb_unbiased}
add wave -position insertpoint {sim:/tb_top/u_dut/exp_no_lsh}
add wave -position insertpoint {sim:/tb_top/u_dut/exp_lsh}
add wave -position insertpoint {sim:/tb_top/u_dut/exp_no_lsh_zero}
add wave -position insertpoint {sim:/tb_top/u_dut/exp_no_lsh_neg}
add wave -position insertpoint {sim:/tb_top/u_dut/exp_lsh_zero}
add wave -position insertpoint {sim:/tb_top/u_dut/exp_lsh_neg}
add wave -position insertpoint {sim:/tb_top/u_dut/exp_lsh_pos}
add wave -position insertpoint {sim:/tb_top/u_dut/do_rsh}
add wave -position insertpoint {sim:/tb_top/u_dut/rsh_num_f16}
add wave -position insertpoint {sim:/tb_top/u_dut/rsh_num_f32}
add wave -position insertpoint {sim:/tb_top/u_dut/rsh_num_f64}
add wave -position insertpoint {sim:/tb_top/u_dut/rsh_num}
add wave -position insertpoint {sim:/tb_top/u_dut/s_mask_f16}
add wave -position insertpoint {sim:/tb_top/u_dut/s_mask_f32}
add wave -position insertpoint {sim:/tb_top/u_dut/s_mask_f64}
add wave -position insertpoint {sim:/tb_top/u_dut/fma_mul_sticky_f16}
add wave -position insertpoint {sim:/tb_top/u_dut/fma_mul_sticky_f32}
add wave -position insertpoint {sim:/tb_top/u_dut/fma_mul_sticky_f64}
add wave -position insertpoint {sim:/tb_top/u_dut/lzc_fraca}
add wave -position insertpoint {sim:/tb_top/u_dut/lzc_fracb}
add wave -position insertpoint {sim:/tb_top/u_dut/lzc_frac}
add wave -position insertpoint {sim:/tb_top/u_dut/lzc_frac_m1}
add wave -position insertpoint {sim:/tb_top/u_dut/lsh_num}
add wave -position insertpoint {sim:/tb_top/u_dut/exp_mul}
add wave -position insertpoint {sim:/tb_top/u_dut/exp_mul_p1}
add wave -position insertpoint {sim:/tb_top/u_dut/exp_mul_overflow}
add wave -position insertpoint {sim:/tb_top/u_dut/exp_mul_inf}
add wave -position insertpoint {sim:/tb_top/u_dut/exp_mul_zero}
add wave -position insertpoint {sim:/tb_top/u_dut/sig_mul}
add wave -position insertpoint {sim:/tb_top/u_dut/sig_mul_f16}
add wave -position insertpoint {sim:/tb_top/u_dut/sig_mul_f32}
add wave -position insertpoint {sim:/tb_top/u_dut/sig_mul_rsh}
add wave -position insertpoint {sim:/tb_top/u_dut/sig_mul_lsh}
add wave -position insertpoint {sim:/tb_top/u_dut/rsh_overflow}
add wave -position insertpoint {sim:/tb_top/u_dut/lsh_overflow}
add wave -position insertpoint {sim:/tb_top/u_dut/sig_mul_shifted_overflow}
add wave -position insertpoint {sim:/tb_top/u_dut/exp_fma}
add wave -position insertpoint {sim:/tb_top/u_dut/frac_fma_f16}
add wave -position insertpoint {sim:/tb_top/u_dut/frac_fma_f32}
add wave -position insertpoint {sim:/tb_top/u_dut/frac_fma_f64}
add wave -position insertpoint {sim:/tb_top/u_dut/res_snan}
add wave -position insertpoint {sim:/tb_top/u_dut/res_qnan}
add wave -position insertpoint {sim:/tb_top/u_dut/res_zero}
add wave -position insertpoint {sim:/tb_top/u_dut/res_inf}
add wave -position insertpoint {sim:/tb_top/u_dut/fma_intermediate_res_f16}
add wave -position insertpoint {sim:/tb_top/u_dut/fma_intermediate_res_f32}
add wave -position insertpoint {sim:/tb_top/u_dut/fma_intermediate_res_f64}
add wave -position insertpoint {sim:/tb_top/u_dut/fma_intermediate_res_o}
add wave -position insertpoint {sim:/tb_top/u_dut/fma_mul_sticky_o}
add wave -position insertpoint {sim:/tb_top/u_dut/fma_inputs_nan_inf_o}
add wave -position insertpoint {sim:/tb_top/u_dut/fma_mul_exp_gt_inf_o}




