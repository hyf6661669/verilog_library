add wave -position insertpoint -expand -group CLK_RST {sim:/tb_top_fmul/clk}
add wave -position insertpoint -expand -group CLK_RST {sim:/tb_top_fmul/rst_n}

add wave -position insertpoint -radix unsigned {sim:/tb_top_fmul/acq_count}
add wave -position insertpoint {sim:/tb_top_fmul/dut_start_valid}
add wave -position insertpoint {sim:/tb_top_fmul/dut_start_ready}
add wave -position insertpoint {sim:/tb_top_fmul/dut_finish_valid}
add wave -position insertpoint {sim:/tb_top_fmul/dut_finish_ready}
add wave -position insertpoint {sim:/tb_top_fmul/dut_opa}
add wave -position insertpoint {sim:/tb_top_fmul/dut_opb}

add wave -position insertpoint {sim:/tb_top_fmul/u_dut/signa}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/signb}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/sign_mul}
add wave -position insertpoint -radix unsigned {sim:/tb_top_fmul/u_dut/expa}
add wave -position insertpoint -radix unsigned {sim:/tb_top_fmul/u_dut/expb}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/expa_all_1}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/expb_all_1}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/expa_zero}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/expb_zero}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/expa_adj}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/expb_adj}

add wave -position insertpoint {sim:/tb_top_fmul/u_dut/siga}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/sigb}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/opa_zero}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/opb_zero}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/opa_qnan}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/opb_qnan}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/opa_snan}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/opb_snan}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/opa_inf}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/opb_inf}

add wave -position insertpoint -radix unsigned {sim:/tb_top_fmul/u_dut/expa_unbiased}
add wave -position insertpoint -radix unsigned {sim:/tb_top_fmul/u_dut/expb_unbiased}
add wave -position insertpoint -radix unsigned {sim:/tb_top_fmul/u_dut/exp_no_lsh}
add wave -position insertpoint -radix unsigned {sim:/tb_top_fmul/u_dut/exp_lsh}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/exp_no_lsh_zero}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/exp_no_lsh_neg}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/exp_lsh_zero}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/exp_lsh_neg}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/exp_lsh_pos}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/do_rsh}
add wave -position insertpoint -radix unsigned {sim:/tb_top_fmul/u_dut/rsh_num_f16}
add wave -position insertpoint -radix unsigned {sim:/tb_top_fmul/u_dut/rsh_num_f32}
add wave -position insertpoint -radix unsigned {sim:/tb_top_fmul/u_dut/rsh_num_f64}
add wave -position insertpoint -radix unsigned {sim:/tb_top_fmul/u_dut/rsh_num}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/s_mask_f16}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/s_mask_f32}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/s_mask_f64}
add wave -position insertpoint -radix unsigned {sim:/tb_top_fmul/u_dut/lzc_fraca}
add wave -position insertpoint -radix unsigned {sim:/tb_top_fmul/u_dut/lzc_fracb}
add wave -position insertpoint -radix unsigned {sim:/tb_top_fmul/u_dut/lzc_frac}
add wave -position insertpoint -radix unsigned {sim:/tb_top_fmul/u_dut/lzc_frac_m1}
add wave -position insertpoint -radix unsigned {sim:/tb_top_fmul/u_dut/lsh_num}
add wave -position insertpoint -radix unsigned {sim:/tb_top_fmul/u_dut/exp_mul}
add wave -position insertpoint -radix unsigned {sim:/tb_top_fmul/u_dut/exp_mul_p1}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/exp_mul_overflow}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/exp_mul_inf}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/exp_mul_max}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/exp_mul_zero}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/sig_mul}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/sig_mul_f16}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/sig_mul_f32}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/sig_mul_rsh}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/sig_mul_lsh}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/rsh_overflow}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_overflow}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_denormal_to_normal}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/sel_overflow_exp}
add wave -position insertpoint -radix unsigned {sim:/tb_top_fmul/u_dut/exp_fmul}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/res_snan}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/res_qnan}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/res_zero}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/res_inf}

#add wave -position insertpoint {sim:/tb_top_fmul/u_dut/rsh_l_mask_f16}
#add wave -position insertpoint {sim:/tb_top_fmul/u_dut/rsh_g_mask_f16}
#add wave -position insertpoint {sim:/tb_top_fmul/u_dut/rsh_s_mask_f16}
#add wave -position insertpoint {sim:/tb_top_fmul/u_dut/rsh_l_mask_f32}
#add wave -position insertpoint {sim:/tb_top_fmul/u_dut/rsh_g_mask_f32}
#add wave -position insertpoint {sim:/tb_top_fmul/u_dut/rsh_s_mask_f32}
#add wave -position insertpoint {sim:/tb_top_fmul/u_dut/rsh_l_mask_f64}
#add wave -position insertpoint {sim:/tb_top_fmul/u_dut/rsh_g_mask_f64}
#add wave -position insertpoint {sim:/tb_top_fmul/u_dut/rsh_s_mask_f64}

add wave -position insertpoint {sim:/tb_top_fmul/u_dut/rsh_l_f16}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/rsh_g_f16}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/rsh_s_f16}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/rsh_l_uf_check_f16}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/rsh_g_uf_check_f16}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/rsh_s_uf_check_f16}

add wave -position insertpoint {sim:/tb_top_fmul/u_dut/rsh_l_f32}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/rsh_g_f32}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/rsh_s_f32}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/rsh_l_uf_check_f32}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/rsh_g_uf_check_f32}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/rsh_s_uf_check_f32}

add wave -position insertpoint {sim:/tb_top_fmul/u_dut/rsh_l_f64}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/rsh_g_f64}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/rsh_s_f64}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/rsh_l_uf_check_f64}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/rsh_g_uf_check_f64}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/rsh_s_uf_check_f64}

add wave -position insertpoint {sim:/tb_top_fmul/u_dut/rsh_l}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/rsh_g}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/rsh_s}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/rsh_l_uf_check}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/rsh_g_uf_check}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/rsh_s_uf_check}


#add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_overflow_mask_f16}
#add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_overflow_l_mask_f16}
#add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_overflow_g_mask_f16}
#add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_overflow_s_mask_f16}
#add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_normal_l_mask_f16}
#add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_normal_g_mask_f16}
#add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_normal_s_mask_f16}

add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_overflow_f16}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_overflow_l_f16}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_overflow_g_f16}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_overflow_s_f16}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_overflow_l_uf_check_f16}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_overflow_g_uf_check_f16}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_overflow_s_uf_check_f16}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_normal_l_f16}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_normal_g_f16}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_normal_s_f16}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_normal_l_uf_check_f16}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_normal_g_uf_check_f16}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_normal_s_uf_check_f16}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_l_f16}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_g_f16}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_s_f16}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_l_uf_check_f16}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_g_uf_check_f16}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_s_uf_check_f16}


#add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_overflow_mask_f32}
#add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_overflow_l_mask_f32}
#add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_overflow_g_mask_f32}
#add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_overflow_s_mask_f32}
#add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_normal_l_mask_f32}
#add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_normal_g_mask_f32}
#add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_normal_s_mask_f32}

add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_overflow_f32}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_overflow_l_f32}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_overflow_g_f32}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_overflow_s_f32}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_overflow_l_uf_check_f32}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_overflow_g_uf_check_f32}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_overflow_s_uf_check_f32}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_normal_l_f32}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_normal_g_f32}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_normal_s_f32}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_normal_l_uf_check_f32}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_normal_g_uf_check_f32}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_normal_s_uf_check_f32}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_l_f32}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_g_f32}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_s_f32}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_l_uf_check_f32}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_g_uf_check_f32}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_s_uf_check_f32}


#add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_overflow_mask_f64}
#add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_overflow_l_mask_f64}
#add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_overflow_g_mask_f64}
#add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_overflow_s_mask_f64}
#add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_normal_l_mask_f64}
#add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_normal_g_mask_f64}
#add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_normal_s_mask_f64}

add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_overflow_f64}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_overflow_l_f64}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_overflow_g_f64}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_overflow_s_f64}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_overflow_l_uf_check_f64}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_overflow_g_uf_check_f64}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_overflow_s_uf_check_f64}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_normal_l_f64}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_normal_g_f64}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_normal_s_f64}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_normal_l_uf_check_f64}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_normal_g_uf_check_f64}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_normal_s_uf_check_f64}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_l_f64}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_g_f64}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_s_f64}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_l_uf_check_f64}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_g_uf_check_f64}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/lsh_s_uf_check_f64}

add wave -position insertpoint {sim:/tb_top_fmul/u_dut/l_for_round}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/g_for_round}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/s_for_round}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/l_for_uf_check}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/g_for_uf_check}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/s_for_uf_check}

add wave -position insertpoint {sim:/tb_top_fmul/u_dut/rne}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/rmm}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/rtz}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/rup}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/round_up}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/round_up_uf_check}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/frac_unrounded_fmul}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/round_up_poisition}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/frac_rounded_fmul}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/sel_exp_p1_fmul}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/sel_overflow_res_fmul}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/fmul_res_f16}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/fmul_res_f32}
add wave -position insertpoint {sim:/tb_top_fmul/u_dut/fmul_res_f64}


