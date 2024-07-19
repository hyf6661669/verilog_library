add wave -position insertpoint -expand -group CLK_RST {sim:/tb_top/clk}
add wave -position insertpoint -expand -group CLK_RST {sim:/tb_top/rst_n}

add wave -position insertpoint -expand -group FSM_CTRL -radix unsigned {sim:/tb_top/acq_count}
add wave -position insertpoint -expand -group FSM_CTRL {sim:/tb_top/dut_start_valid}
add wave -position insertpoint -expand -group FSM_CTRL {sim:/tb_top/dut_start_ready}
add wave -position insertpoint -expand -group FSM_CTRL {sim:/tb_top/dut_finish_valid}
add wave -position insertpoint -expand -group FSM_CTRL {sim:/tb_top/dut_finish_ready}
add wave -position insertpoint -expand -group FSM_CTRL -radix binary {sim:/tb_top/u_dut/fsm_q}
add wave -position insertpoint -expand -group FSM_CTRL {sim:/tb_top/u_dut/f32_after_pre_0_q}
add wave -position insertpoint -expand -group FSM_CTRL {sim:/tb_top/u_dut/f64_after_pre_0_q}
add wave -position insertpoint -expand -group FSM_CTRL {sim:/tb_top/u_dut/final_iter}
add wave -position insertpoint -expand -group FSM_CTRL -radix unsigned {sim:/tb_top/u_dut/iter_counter_q}
add wave -position insertpoint -expand -group FSM_CTRL {sim:/tb_top/compare_ok}
add wave -position insertpoint -expand -group FSM_CTRL {sim:/tb_top/fp_format}
add wave -position insertpoint -expand -group FSM_CTRL {sim:/tb_top/dut_rm}
add wave -position insertpoint -expand -group FSM_CTRL {sim:/tb_top/dut_opa}
add wave -position insertpoint -expand -group FSM_CTRL {sim:/tb_top/dut_opb}
add wave -position insertpoint -expand -group FSM_CTRL {sim:/tb_top/dut_res}




add wave -position insertpoint -expand -group SPECIAL_CASES {sim:/tb_top/u_dut/opa_dn}
add wave -position insertpoint -expand -group SPECIAL_CASES {sim:/tb_top/u_dut/opb_dn}
add wave -position insertpoint -expand -group SPECIAL_CASES {sim:/tb_top/u_dut/has_dn_in}
add wave -position insertpoint -expand -group SPECIAL_CASES {sim:/tb_top/u_dut/early_finish_fdiv_pre_0}
add wave -position insertpoint -expand -group SPECIAL_CASES {sim:/tb_top/u_dut/early_finish_pre_0}
add wave -position insertpoint -expand -group SPECIAL_CASES {sim:/tb_top/u_dut/early_finish_pre_1}
add wave -position insertpoint -expand -group SPECIAL_CASES {sim:/tb_top/u_dut/res_nan_fdiv}
add wave -position insertpoint -expand -group SPECIAL_CASES {sim:/tb_top/u_dut/res_inf_fdiv}
add wave -position insertpoint -expand -group SPECIAL_CASES {sim:/tb_top/u_dut/res_exact_zero_fdiv}
add wave -position insertpoint -expand -group SPECIAL_CASES {sim:/tb_top/u_dut/opb_power_of_2_q}


add wave -position insertpoint -expand -group EXP_LOGIC {sim:/tb_top/u_dut/exp_diff}
add wave -position insertpoint -expand -group EXP_LOGIC {sim:/tb_top/u_dut/res_exp_fdiv_pre_0}
add wave -position insertpoint -expand -group EXP_LOGIC {sim:/tb_top/u_dut/res_exp_fdiv_pre_1}
add wave -position insertpoint -expand -group EXP_LOGIC -radix unsigned {sim:/tb_top/u_dut/iter_counter_nxt}
add wave -position insertpoint -expand -group EXP_LOGIC {sim:/tb_top/u_dut/add_1_to_quot_msb}
add wave -position insertpoint -expand -group EXP_LOGIC {sim:/tb_top/u_dut/res_exp_q}
add wave -position insertpoint -expand -group EXP_LOGIC {sim:/tb_top/u_dut/res_exp_zero}
add wave -position insertpoint -expand -group EXP_LOGIC {sim:/tb_top/u_dut/res_exp_dn}
add wave -position insertpoint -expand -group EXP_LOGIC {sim:/tb_top/u_dut/res_exp_of}
add wave -position insertpoint -expand -group EXP_LOGIC -radix unsigned {sim:/tb_top/u_dut/quot_bits_needed_res_exp_nm}
add wave -position insertpoint -expand -group EXP_LOGIC -radix signed {sim:/tb_top/u_dut/quot_bits_needed_res_exp_dn_temp}
add wave -position insertpoint -expand -group EXP_LOGIC -radix unsigned {sim:/tb_top/u_dut/quot_bits_needed_res_exp_dn}
add wave -position insertpoint -expand -group EXP_LOGIC -radix unsigned {sim:/tb_top/u_dut/quot_bits_needed}
add wave -position insertpoint -expand -group EXP_LOGIC -radix unsigned {sim:/tb_top/u_dut/quot_bits_calculated}
add wave -position insertpoint -expand -group EXP_LOGIC {sim:/tb_top/u_dut/quot_bits_calculated_ge_quot_bits_needed}
add wave -position insertpoint -expand -group EXP_LOGIC -radix binary {sim:/tb_top/u_dut/quot_discard_num_one_hot}


add wave -position insertpoint -expand -group PRESCALING {sim:/tb_top/u_dut/fraca_lt_fracb}
add wave -position insertpoint -expand -group PRESCALING {sim:/tb_top/u_dut/fraca_unlsh}
add wave -position insertpoint -expand -group PRESCALING {sim:/tb_top/u_dut/fracb_unlsh}
add wave -position insertpoint -expand -group PRESCALING -radix unsigned {sim:/tb_top/u_dut/fraca_lsh_num_q}
add wave -position insertpoint -expand -group PRESCALING -radix unsigned {sim:/tb_top/u_dut/fracb_lsh_num_q}
add wave -position insertpoint -expand -group PRESCALING {sim:/tb_top/u_dut/fraca_lsh}
add wave -position insertpoint -expand -group PRESCALING {sim:/tb_top/u_dut/fracb_lsh}
add wave -position insertpoint -expand -group PRESCALING {sim:/tb_top/u_dut/scaling_factor_idx}
add wave -position insertpoint -expand -group PRESCALING {sim:/tb_top/u_dut/fraca_prescaled}
add wave -position insertpoint -expand -group PRESCALING {sim:/tb_top/u_dut/fracb_prescaled}
add wave -position insertpoint -expand -group PRESCALING {sim:/tb_top/u_dut/fraca_scaled_csa_in_0}
add wave -position insertpoint -expand -group PRESCALING {sim:/tb_top/u_dut/fraca_scaled_csa_in_1}
add wave -position insertpoint -expand -group PRESCALING {sim:/tb_top/u_dut/fraca_scaled_csa_in_2}
add wave -position insertpoint -expand -group PRESCALING {sim:/tb_top/u_dut/fracb_scaled_csa_in_0}
add wave -position insertpoint -expand -group PRESCALING {sim:/tb_top/u_dut/fracb_scaled_csa_in_1}
add wave -position insertpoint -expand -group PRESCALING {sim:/tb_top/u_dut/fracb_scaled_csa_in_2}

add wave -position insertpoint -expand -group PRESCALING {sim:/tb_top/u_dut/fraca_scaled_sum}
add wave -position insertpoint -expand -group PRESCALING {sim:/tb_top/u_dut/fraca_scaled_carry}
add wave -position insertpoint -expand -group PRESCALING {sim:/tb_top/u_dut/fracb_scaled_sum}
add wave -position insertpoint -expand -group PRESCALING {sim:/tb_top/u_dut/fracb_scaled_carry}
add wave -position insertpoint -expand -group PRESCALING {sim:/tb_top/u_dut/fraca_scaled}
add wave -position insertpoint -expand -group PRESCALING {sim:/tb_top/u_dut/fracb_scaled}

add wave -position insertpoint -expand -group PRESCALING {sim:/tb_top/u_dut/f_r_s_before_iter_fdiv}
add wave -position insertpoint -expand -group PRESCALING {sim:/tb_top/u_dut/f_r_c_before_iter_fdiv}
add wave -position insertpoint -expand -group PRESCALING {sim:/tb_top/u_dut/fracb_zero_pre_0}
add wave -position insertpoint -expand -group PRESCALING {sim:/tb_top/u_dut/fracb_zero_pre_1}


add wave -position insertpoint -expand -group 1ST_SRT -radix binary {sim:/tb_top/u_dut/u_fdiv_r16_block/rem_msb_1st}
#add wave -position insertpoint -expand -group 1ST_SRT {sim:/tb_top/u_dut/u_fdiv_r16_block/divisor_ext}
add wave -position insertpoint -expand -group 1ST_SRT {sim:/tb_top/u_dut/u_fdiv_r16_block/f_r_s_1st}
add wave -position insertpoint -expand -group 1ST_SRT {sim:/tb_top/u_dut/u_fdiv_r16_block/f_r_c_1st}
add wave -position insertpoint -expand -group 1ST_SRT {sim:/tb_top/u_dut/u_fdiv_r16_block/quot_dig_n2_1st}
add wave -position insertpoint -expand -group 1ST_SRT {sim:/tb_top/u_dut/u_fdiv_r16_block/quot_dig_n1_1st}
add wave -position insertpoint -expand -group 1ST_SRT {sim:/tb_top/u_dut/u_fdiv_r16_block/quot_dig_z0_1st}
add wave -position insertpoint -expand -group 1ST_SRT {sim:/tb_top/u_dut/u_fdiv_r16_block/quot_dig_p1_1st}
add wave -position insertpoint -expand -group 1ST_SRT {sim:/tb_top/u_dut/u_fdiv_r16_block/quot_dig_p2_1st}
add wave -position insertpoint -expand -group 1ST_SRT {sim:/tb_top/u_dut/quot_1st}
add wave -position insertpoint -expand -group 1ST_SRT {sim:/tb_top/u_dut/quot_m1_1st}
add wave -position insertpoint -expand -group 1ST_SRT -radix binary {sim:/tb_top/u_dut/u_fdiv_r16_block/rem_msb_quot_dig_n2_2nd}
add wave -position insertpoint -expand -group 1ST_SRT -radix binary {sim:/tb_top/u_dut/u_fdiv_r16_block/rem_msb_quot_dig_n1_2nd}
add wave -position insertpoint -expand -group 1ST_SRT -radix binary {sim:/tb_top/u_dut/u_fdiv_r16_block/rem_msb_quot_dig_z0_2nd}
add wave -position insertpoint -expand -group 1ST_SRT -radix binary {sim:/tb_top/u_dut/u_fdiv_r16_block/rem_msb_quot_dig_p1_2nd}
add wave -position insertpoint -expand -group 1ST_SRT -radix binary {sim:/tb_top/u_dut/u_fdiv_r16_block/rem_msb_quot_dig_p2_2nd}


add wave -position insertpoint -expand -group 2ND_SRT -radix binary {sim:/tb_top/u_dut/u_fdiv_r16_block/rem_msb_2nd}
add wave -position insertpoint -expand -group 2ND_SRT {sim:/tb_top/u_dut/u_fdiv_r16_block/f_r_s_2nd}
add wave -position insertpoint -expand -group 2ND_SRT {sim:/tb_top/u_dut/u_fdiv_r16_block/f_r_c_2nd}
add wave -position insertpoint -expand -group 2ND_SRT {sim:/tb_top/u_dut/u_fdiv_r16_block/quot_dig_n2_2nd}
add wave -position insertpoint -expand -group 2ND_SRT {sim:/tb_top/u_dut/u_fdiv_r16_block/quot_dig_n1_2nd}
add wave -position insertpoint -expand -group 2ND_SRT {sim:/tb_top/u_dut/u_fdiv_r16_block/quot_dig_z0_2nd}
add wave -position insertpoint -expand -group 2ND_SRT {sim:/tb_top/u_dut/u_fdiv_r16_block/quot_dig_p1_2nd}
add wave -position insertpoint -expand -group 2ND_SRT {sim:/tb_top/u_dut/u_fdiv_r16_block/quot_dig_p2_2nd}
add wave -position insertpoint -expand -group 2ND_SRT {sim:/tb_top/u_dut/quot_2nd}
add wave -position insertpoint -expand -group 2ND_SRT {sim:/tb_top/u_dut/quot_m1_2nd}



add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/quot_root_iter_q}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/quot_root_m1_iter_q}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/f_r_s_q}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/f_r_c_q}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/nr_f_r}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/quot_discard_not_zero}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/rem_not_zero}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/add_1_to_quot_msb_post}
add wave -position insertpoint -expand -group POST -radix binary {sim:/tb_top/u_dut/quot_discard_num_post}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/select_quot_m1}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/quot_before_inc}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/quot_root_before_inc}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/quot_m1_before_inc}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/inc_poisition}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/quot_root_inc_res}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/quot_m1_inc_res}

add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/quot_l}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/quot_g}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/quot_s}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/quot_need_round_up}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/quot_m1_l}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/quot_m1_g}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/quot_m1_s}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/quot_m1_need_round_up}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/quot_l_uf_check}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/quot_g_uf_check}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/quot_s_uf_check}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/quot_uf_check_need_round_up}


add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/frac_rounded_fdiv}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/carry_after_round_fdiv}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/exp_before_round_fdiv}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/exp_rounded_fdiv}

add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/sel_overflow_res}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/overflow_res}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/sel_special_res}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/special_res}
add wave -position insertpoint -expand -group POST {sim:/tb_top/u_dut/normal_res}






