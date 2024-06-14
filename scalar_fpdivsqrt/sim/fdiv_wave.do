add wave -position insertpoint -expand -group CLK_RST {sim:/tb_top/clk}
add wave -position insertpoint -expand -group CLK_RST {sim:/tb_top/rst_n}

add wave -position insertpoint -expand -group FSM_CTRL -radix unsigned {sim:/tb_top/acq_count}
add wave -position insertpoint -expand -group FSM_CTRL {sim:/tb_top/dut_start_valid}
add wave -position insertpoint -expand -group FSM_CTRL {sim:/tb_top/dut_start_ready}
add wave -position insertpoint -expand -group FSM_CTRL {sim:/tb_top/dut_finish_valid}
add wave -position insertpoint -expand -group FSM_CTRL {sim:/tb_top/dut_finish_ready}
add wave -position insertpoint -expand -group FSM_CTRL -radix binary {sim:/tb_top/u_dut/fsm_q}
add wave -position insertpoint -expand -group FSM_CTRL {sim:/tb_top/u_dut/f16_after_pre_0}
add wave -position insertpoint -expand -group FSM_CTRL {sim:/tb_top/u_dut/f32_after_pre_0}
add wave -position insertpoint -expand -group FSM_CTRL {sim:/tb_top/u_dut/f64_after_pre_0}
add wave -position insertpoint -expand -group FSM_CTRL {sim:/tb_top/u_dut/final_iter}
add wave -position insertpoint -expand -group FSM_CTRL -radix unsigned {sim:/tb_top/u_dut/iter_num_q}
add wave -position insertpoint -expand -group FSM_CTRL {sim:/tb_top/compare_ok}
add wave -position insertpoint -expand -group FSM_CTRL {sim:/tb_top/fp_format}
add wave -position insertpoint -expand -group FSM_CTRL {sim:/tb_top/dut_rm}
add wave -position insertpoint -expand -group FSM_CTRL {sim:/tb_top/dut_opa}
add wave -position insertpoint -expand -group FSM_CTRL {sim:/tb_top/dut_opb}
add wave -position insertpoint -expand -group FSM_CTRL {sim:/tb_top/dut_res}
add wave -position insertpoint -expand -group FSM_CTRL {sim:/tb_top/u_dut/final_res_post_0_f16}
add wave -position insertpoint -expand -group FSM_CTRL {sim:/tb_top/u_dut/final_res_post_0_f32}
add wave -position insertpoint -expand -group FSM_CTRL {sim:/tb_top/u_dut/final_res_post_0_f64}
add wave -position insertpoint -expand -group FSM_CTRL {sim:/tb_top/u_dut/final_res_post_1_f16}
add wave -position insertpoint -expand -group FSM_CTRL {sim:/tb_top/u_dut/final_res_post_1_f32}
add wave -position insertpoint -expand -group FSM_CTRL {sim:/tb_top/u_dut/final_res_post_1_f64}






add wave -position insertpoint -expand -group SPECIAL_CASES {sim:/tb_top/u_dut/opa_is_dn}
add wave -position insertpoint -expand -group SPECIAL_CASES {sim:/tb_top/u_dut/opb_is_dn}
add wave -position insertpoint -expand -group SPECIAL_CASES {sim:/tb_top/u_dut/has_dn_in}
add wave -position insertpoint -expand -group SPECIAL_CASES {sim:/tb_top/u_dut/early_finish_to_post_1_pre_0}
add wave -position insertpoint -expand -group SPECIAL_CASES {sim:/tb_top/u_dut/early_finish_to_post_0_pre_0}
add wave -position insertpoint -expand -group SPECIAL_CASES {sim:/tb_top/u_dut/res_is_nan_fdiv}
add wave -position insertpoint -expand -group SPECIAL_CASES {sim:/tb_top/u_dut/res_is_inf_fdiv}
add wave -position insertpoint -expand -group SPECIAL_CASES {sim:/tb_top/u_dut/res_is_exact_zero_fdiv}
add wave -position insertpoint -expand -group SPECIAL_CASES {sim:/tb_top/u_dut/early_finish_fdiv_pre_1}
add wave -position insertpoint -expand -group SPECIAL_CASES {sim:/tb_top/u_dut/early_finish_fsqrt_pre_1}
add wave -position insertpoint -expand -group SPECIAL_CASES {sim:/tb_top/u_dut/early_finish_pre_1}
add wave -position insertpoint -expand -group SPECIAL_CASES {sim:/tb_top/u_dut/opb_is_power_of_2_q}









add wave -position insertpoint -expand -group EXP_CALCULATION {sim:/tb_top/u_dut/exp_diff_nm_in}
add wave -position insertpoint -expand -group EXP_CALCULATION {sim:/tb_top/u_dut/exp_diff_dn_in_pre_0}
add wave -position insertpoint -expand -group EXP_CALCULATION {sim:/tb_top/u_dut/opa_frac_lt_opb_frac}
add wave -position insertpoint -expand -group EXP_CALCULATION {sim:/tb_top/u_dut/res_exp_nm_in_fdiv_is_dn}
add wave -position insertpoint -expand -group EXP_CALCULATION {sim:/tb_top/u_dut/res_exp_nm_in_fdiv_is_of}
add wave -position insertpoint -expand -group EXP_CALCULATION {sim:/tb_top/u_dut/res_exp_nm_in_fdiv_is_dn_m1}
add wave -position insertpoint -expand -group EXP_CALCULATION {sim:/tb_top/u_dut/res_exp_nm_in_fdiv_is_of_m1}
add wave -position insertpoint -expand -group EXP_CALCULATION {sim:/tb_top/u_dut/res_exp_dn_in_fdiv_is_dn}
add wave -position insertpoint -expand -group EXP_CALCULATION {sim:/tb_top/u_dut/res_exp_dn_in_fdiv_is_of}
add wave -position insertpoint -expand -group EXP_CALCULATION {sim:/tb_top/u_dut/res_exp_dn_in_fdiv_is_dn_m1}
add wave -position insertpoint -expand -group EXP_CALCULATION {sim:/tb_top/u_dut/res_exp_dn_in_fdiv_is_of_m1}
add wave -position insertpoint -expand -group EXP_CALCULATION {sim:/tb_top/u_dut/r_shift_num_pre_0}
add wave -position insertpoint -expand -group EXP_CALCULATION {sim:/tb_top/u_dut/r_shift_num_pre_1}

add wave -position insertpoint -expand -group PRESCALING {sim:/tb_top/u_dut/opa_frac_unshifted}
add wave -position insertpoint -expand -group PRESCALING {sim:/tb_top/u_dut/opb_frac_unshifted}
add wave -position insertpoint -expand -group PRESCALING {sim:/tb_top/u_dut/opa_frac_l_shift_num}
add wave -position insertpoint -expand -group PRESCALING {sim:/tb_top/u_dut/opb_frac_l_shift_num}
add wave -position insertpoint -expand -group PRESCALING {sim:/tb_top/u_dut/opa_frac_l_shifted}
add wave -position insertpoint -expand -group PRESCALING {sim:/tb_top/u_dut/opb_frac_l_shifted}

add wave -position insertpoint -expand -group PRESCALING {sim:/tb_top/u_dut/scaling_factor_idx}
add wave -position insertpoint -expand -group PRESCALING {sim:/tb_top/u_dut/opa_frac_prescaled}
add wave -position insertpoint -expand -group PRESCALING {sim:/tb_top/u_dut/opb_frac_prescaled}
add wave -position insertpoint -expand -group PRESCALING {sim:/tb_top/u_dut/opa_frac_scaled_csa_in_0}
add wave -position insertpoint -expand -group PRESCALING {sim:/tb_top/u_dut/opa_frac_scaled_csa_in_1}
add wave -position insertpoint -expand -group PRESCALING {sim:/tb_top/u_dut/opa_frac_scaled_csa_in_2}
add wave -position insertpoint -expand -group PRESCALING {sim:/tb_top/u_dut/opb_frac_scaled_csa_in_0}
add wave -position insertpoint -expand -group PRESCALING {sim:/tb_top/u_dut/opb_frac_scaled_csa_in_1}
add wave -position insertpoint -expand -group PRESCALING {sim:/tb_top/u_dut/opb_frac_scaled_csa_in_2}

add wave -position insertpoint -expand -group PRESCALING {sim:/tb_top/u_dut/opa_frac_scaled_sum}
add wave -position insertpoint -expand -group PRESCALING {sim:/tb_top/u_dut/opa_frac_scaled_carry}
add wave -position insertpoint -expand -group PRESCALING {sim:/tb_top/u_dut/opb_frac_scaled_sum}
add wave -position insertpoint -expand -group PRESCALING {sim:/tb_top/u_dut/opb_frac_scaled_carry}
add wave -position insertpoint -expand -group PRESCALING {sim:/tb_top/u_dut/opa_frac_scaled}
add wave -position insertpoint -expand -group PRESCALING {sim:/tb_top/u_dut/opb_frac_scaled}

add wave -position insertpoint -expand -group PRESCALING -radix unsigned {sim:/tb_top/u_dut/rem_msb_1st_quot_opa_frac_ge_opb_frac_temp}
add wave -position insertpoint -expand -group PRESCALING -radix unsigned {sim:/tb_top/u_dut/rem_msb_1st_quot_opa_frac_lt_opb_frac_temp}
add wave -position insertpoint -expand -group PRESCALING -radix unsigned {sim:/tb_top/u_dut/quot_1st_is_p2}

add wave -position insertpoint -expand -group PRESCALING {sim:/tb_top/u_dut/f_r_s_before_iter_fdiv}
add wave -position insertpoint -expand -group PRESCALING {sim:/tb_top/u_dut/f_r_c_before_iter_fdiv}
add wave -position insertpoint -expand -group PRESCALING {sim:/tb_top/u_dut/opb_frac_is_zero_pre_0}
add wave -position insertpoint -expand -group PRESCALING {sim:/tb_top/u_dut/opb_frac_is_zero_pre_1}


add wave -position insertpoint -expand -group 1ST_SRT -radix binary {sim:/tb_top/u_dut/u_fpdiv_r64_block/rem_msb_1st}
add wave -position insertpoint -expand -group 1ST_SRT {sim:/tb_top/u_dut/u_fpdiv_r64_block/f_r_s_1st}
add wave -position insertpoint -expand -group 1ST_SRT {sim:/tb_top/u_dut/u_fpdiv_r64_block/f_r_c_1st}
add wave -position insertpoint -expand -group 1ST_SRT {sim:/tb_top/u_dut/u_fpdiv_r64_block/quot_dig_n2_1st}
add wave -position insertpoint -expand -group 1ST_SRT {sim:/tb_top/u_dut/u_fpdiv_r64_block/quot_dig_n1_1st}
add wave -position insertpoint -expand -group 1ST_SRT {sim:/tb_top/u_dut/u_fpdiv_r64_block/quot_dig_z0_1st}
add wave -position insertpoint -expand -group 1ST_SRT {sim:/tb_top/u_dut/u_fpdiv_r64_block/quot_dig_p1_1st}
add wave -position insertpoint -expand -group 1ST_SRT {sim:/tb_top/u_dut/u_fpdiv_r64_block/quot_dig_p2_1st}
add wave -position insertpoint -expand -group 1ST_SRT {sim:/tb_top/u_dut/quot_1st}
add wave -position insertpoint -expand -group 1ST_SRT {sim:/tb_top/u_dut/quot_m1_1st}
add wave -position insertpoint -expand -group 1ST_SRT {sim:/tb_top/u_dut/u_fpdiv_r64_block/rem_msb_quot_dig_n2_2nd}
add wave -position insertpoint -expand -group 1ST_SRT {sim:/tb_top/u_dut/u_fpdiv_r64_block/rem_msb_quot_dig_n1_2nd}
add wave -position insertpoint -expand -group 1ST_SRT {sim:/tb_top/u_dut/u_fpdiv_r64_block/rem_msb_quot_dig_z0_2nd}
add wave -position insertpoint -expand -group 1ST_SRT {sim:/tb_top/u_dut/u_fpdiv_r64_block/rem_msb_quot_dig_p1_2nd}
add wave -position insertpoint -expand -group 1ST_SRT {sim:/tb_top/u_dut/u_fpdiv_r64_block/rem_msb_quot_dig_p2_2nd}

add wave -position insertpoint -expand -group 1ST_SRT {sim:/tb_top/u_dut/u_fpdiv_r64_block/rem_msb_quot_dig_n2_3rd_temp}
add wave -position insertpoint -expand -group 1ST_SRT {sim:/tb_top/u_dut/u_fpdiv_r64_block/rem_msb_quot_dig_n1_3rd_temp}
add wave -position insertpoint -expand -group 1ST_SRT {sim:/tb_top/u_dut/u_fpdiv_r64_block/rem_msb_quot_dig_z0_3rd_temp}
add wave -position insertpoint -expand -group 1ST_SRT {sim:/tb_top/u_dut/u_fpdiv_r64_block/rem_msb_quot_dig_p1_3rd_temp}
add wave -position insertpoint -expand -group 1ST_SRT {sim:/tb_top/u_dut/u_fpdiv_r64_block/rem_msb_quot_dig_p2_3rd_temp}
add wave -position insertpoint -expand -group 1ST_SRT {sim:/tb_top/u_dut/u_fpdiv_r64_block/rem_msb_3rd_temp}




add wave -position insertpoint -expand -group 2ND_SRT -radix binary {sim:/tb_top/u_dut/u_fpdiv_r64_block/rem_msb_2nd}
add wave -position insertpoint -expand -group 2ND_SRT {sim:/tb_top/u_dut/u_fpdiv_r64_block/f_r_s_2nd}
add wave -position insertpoint -expand -group 2ND_SRT {sim:/tb_top/u_dut/u_fpdiv_r64_block/f_r_c_2nd}
add wave -position insertpoint -expand -group 2ND_SRT {sim:/tb_top/u_dut/u_fpdiv_r64_block/quot_dig_n2_2nd}
add wave -position insertpoint -expand -group 2ND_SRT {sim:/tb_top/u_dut/u_fpdiv_r64_block/quot_dig_n1_2nd}
add wave -position insertpoint -expand -group 2ND_SRT {sim:/tb_top/u_dut/u_fpdiv_r64_block/quot_dig_z0_2nd}
add wave -position insertpoint -expand -group 2ND_SRT {sim:/tb_top/u_dut/u_fpdiv_r64_block/quot_dig_p1_2nd}
add wave -position insertpoint -expand -group 2ND_SRT {sim:/tb_top/u_dut/u_fpdiv_r64_block/quot_dig_p2_2nd}
add wave -position insertpoint -expand -group 2ND_SRT {sim:/tb_top/u_dut/quot_2nd}
add wave -position insertpoint -expand -group 2ND_SRT {sim:/tb_top/u_dut/quot_m1_2nd}
add wave -position insertpoint -expand -group 2ND_SRT {sim:/tb_top/u_dut/u_fpdiv_r64_block/rem_msb_quot_dig_n2_3rd}
add wave -position insertpoint -expand -group 2ND_SRT {sim:/tb_top/u_dut/u_fpdiv_r64_block/rem_msb_quot_dig_n1_3rd}
add wave -position insertpoint -expand -group 2ND_SRT {sim:/tb_top/u_dut/u_fpdiv_r64_block/rem_msb_quot_dig_z0_3rd}
add wave -position insertpoint -expand -group 2ND_SRT {sim:/tb_top/u_dut/u_fpdiv_r64_block/rem_msb_quot_dig_p1_3rd}
add wave -position insertpoint -expand -group 2ND_SRT {sim:/tb_top/u_dut/u_fpdiv_r64_block/rem_msb_quot_dig_p2_3rd}





add wave -position insertpoint -expand -group 3RD_SRT -radix binary {sim:/tb_top/u_dut/u_fpdiv_r64_block/rem_msb_3rd}
add wave -position insertpoint -expand -group 3RD_SRT {sim:/tb_top/u_dut/u_fpdiv_r64_block/f_r_s_3rd}
add wave -position insertpoint -expand -group 3RD_SRT {sim:/tb_top/u_dut/u_fpdiv_r64_block/f_r_c_3rd}
add wave -position insertpoint -expand -group 3RD_SRT {sim:/tb_top/u_dut/u_fpdiv_r64_block/quot_dig_n2_3rd}
add wave -position insertpoint -expand -group 3RD_SRT {sim:/tb_top/u_dut/u_fpdiv_r64_block/quot_dig_n1_3rd}
add wave -position insertpoint -expand -group 3RD_SRT {sim:/tb_top/u_dut/u_fpdiv_r64_block/quot_dig_z0_3rd}
add wave -position insertpoint -expand -group 3RD_SRT {sim:/tb_top/u_dut/u_fpdiv_r64_block/quot_dig_p1_3rd}
add wave -position insertpoint -expand -group 3RD_SRT {sim:/tb_top/u_dut/u_fpdiv_r64_block/quot_dig_p2_3rd}
add wave -position insertpoint -expand -group 3RD_SRT {sim:/tb_top/u_dut/quot_3rd}
add wave -position insertpoint -expand -group 3RD_SRT {sim:/tb_top/u_dut/quot_m1_3rd}


add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/quot_root_iter_q}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/quot_root_m1_iter_q}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/f_r_s_q}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/f_r_c_q}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/nr_f_r}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/select_quot_m1}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/quot_unshifted}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/quot_m1_unshifted}
add wave -position insertpoint -expand -group POST -radix unsigned {sim:/tb_top/u_dut/r_shift_num_post_0}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/correct_quot_frac_shifted}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/sticky_without_rem}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/rem_is_not_zero_post_0}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/rem_is_not_zero_post_1}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/quot_before_inc}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/quot_root_before_inc}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/quot_m1_before_inc}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/inc_poisition}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/quot_root_inc_res}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/quot_m1_inc_res}

add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/quot_l}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/quot_g}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/quot_s}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/quot_need_rup}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/quot_m1_l}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/quot_m1_g}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/quot_m1_s}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/quot_m1_need_rup}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/frac_rounded_post_0_fdiv}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/carry_after_round_fdiv}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/quot_uf_check_l}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/quot_uf_check_g}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/quot_uf_check_s}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/quot_uf_check_need_rup}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/of}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/of_to_inf}


add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/exp_res_post_0_f16}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/exp_res_post_0_f32}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/exp_res_post_0_f64}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/frac_res_post_0_f16}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/frac_res_post_0_f32}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/frac_res_post_0_f64}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/exp_res_post_1_f16}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/exp_res_post_1_f32}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/exp_res_post_1_f64}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/frac_res_post_1_f16}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/frac_res_post_1_f32}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/frac_res_post_1_f64}





