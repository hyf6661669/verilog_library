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
add wave -position insertpoint -expand -group FSM_CTRL {sim:/tb_top/dut_res}


add wave -position insertpoint -group SPECIAL_CASES {sim:/tb_top/u_dut/opa_dn}
add wave -position insertpoint -group SPECIAL_CASES {sim:/tb_top/u_dut/has_dn_in}
add wave -position insertpoint -group SPECIAL_CASES {sim:/tb_top/u_dut/early_finish_fsqrt_pre_0}
add wave -position insertpoint -group SPECIAL_CASES {sim:/tb_top/u_dut/early_finish_pre_1}
add wave -position insertpoint -group SPECIAL_CASES {sim:/tb_top/u_dut/res_exact_zero_fsqrt}
add wave -position insertpoint -group SPECIAL_CASES {sim:/tb_top/u_dut/res_nan_fsqrt}
add wave -position insertpoint -group SPECIAL_CASES {sim:/tb_top/u_dut/res_inf_fsqrt}
add wave -position insertpoint -group SPECIAL_CASES {sim:/tb_top/u_dut/res_sqrt2_pre_0}
add wave -position insertpoint -group SPECIAL_CASES {sim:/tb_top/u_dut/res_sqrt2_pre_1}
add wave -position insertpoint -group SPECIAL_CASES {sim:/tb_top/u_dut/res_sqrt2_q}

add wave -position insertpoint -expand -group SKIPPING_FIRST_ITER {sim:/tb_top/u_dut/res_exp_dn_in_fsqrt_pre_0}
add wave -position insertpoint -expand -group SKIPPING_FIRST_ITER {sim:/tb_top/u_dut/res_exp_nm_in_fsqrt_pre_0}
add wave -position insertpoint -expand -group SKIPPING_FIRST_ITER {sim:/tb_top/u_dut/res_exp_fsqrt_pre_0}
add wave -position insertpoint -expand -group SKIPPING_FIRST_ITER {sim:/tb_top/u_dut/res_exp_fsqrt_pre_1}
add wave -position insertpoint -expand -group SKIPPING_FIRST_ITER {sim:/tb_top/u_dut/exp_odd_fsqrt}
add wave -position insertpoint -expand -group SKIPPING_FIRST_ITER {sim:/tb_top/u_dut/frac_fsqrt}
add wave -position insertpoint -expand -group SKIPPING_FIRST_ITER {sim:/tb_top/u_dut/root_dig_n2_1st}
add wave -position insertpoint -expand -group SKIPPING_FIRST_ITER {sim:/tb_top/u_dut/root_dig_n1_1st}
add wave -position insertpoint -expand -group SKIPPING_FIRST_ITER {sim:/tb_top/u_dut/root_dig_z0_1st}
add wave -position insertpoint -expand -group SKIPPING_FIRST_ITER {sim:/tb_top/u_dut/root_before_iter}
add wave -position insertpoint -expand -group SKIPPING_FIRST_ITER {sim:/tb_top/u_dut/root_m1_before_iter}
add wave -position insertpoint -expand -group SKIPPING_FIRST_ITER {sim:/tb_top/u_dut/f_r_s_before_iter_fsqrt}
add wave -position insertpoint -expand -group SKIPPING_FIRST_ITER {sim:/tb_top/u_dut/f_r_c_before_iter_fsqrt}
add wave -position insertpoint -expand -group SKIPPING_FIRST_ITER -radix binary {sim:/tb_top/u_dut/rem_msb_nxt_cycle_1st_srt_before_iter}
add wave -position insertpoint -expand -group SKIPPING_FIRST_ITER -radix binary {sim:/tb_top/u_dut/rem_msb_nxt_cycle_2nd_srt_before_iter}
add wave -position insertpoint -expand -group SKIPPING_FIRST_ITER {sim:/tb_top/u_dut/a0_before_iter}
add wave -position insertpoint -expand -group SKIPPING_FIRST_ITER {sim:/tb_top/u_dut/a2_before_iter}
add wave -position insertpoint -expand -group SKIPPING_FIRST_ITER {sim:/tb_top/u_dut/a3_before_iter}
add wave -position insertpoint -expand -group SKIPPING_FIRST_ITER {sim:/tb_top/u_dut/a4_before_iter}
add wave -position insertpoint -expand -group SKIPPING_FIRST_ITER -radix binary {sim:/tb_top/u_dut/m_n1_nxt_cycle_1st_srt_before_iter}
add wave -position insertpoint -expand -group SKIPPING_FIRST_ITER -radix binary {sim:/tb_top/u_dut/m_z0_nxt_cycle_1st_srt_before_iter}
add wave -position insertpoint -expand -group SKIPPING_FIRST_ITER -radix binary {sim:/tb_top/u_dut/m_p1_nxt_cycle_1st_srt_before_iter}
add wave -position insertpoint -expand -group SKIPPING_FIRST_ITER -radix binary {sim:/tb_top/u_dut/m_p2_nxt_cycle_1st_srt_before_iter}


add wave -position insertpoint -group 1ST_SRT {sim:/tb_top/u_dut/u_fsqrt_r16_block/mask_i}
add wave -position insertpoint -group 1ST_SRT -radix binary {sim:/tb_top/u_dut/u_fsqrt_r16_block/rem_msb_nxt_cycle_1st_srt_i}
add wave -position insertpoint -group 1ST_SRT -radix binary {sim:/tb_top/u_dut/u_fsqrt_r16_block/rem_msb_nxt_cycle_2nd_srt_i}
add wave -position insertpoint -group 1ST_SRT -radix binary {sim:/tb_top/u_dut/u_fsqrt_r16_block/m_n1_1st}
add wave -position insertpoint -group 1ST_SRT -radix binary {sim:/tb_top/u_dut/u_fsqrt_r16_block/m_z0_1st}
add wave -position insertpoint -group 1ST_SRT -radix binary {sim:/tb_top/u_dut/u_fsqrt_r16_block/m_p1_1st}
add wave -position insertpoint -group 1ST_SRT -radix binary {sim:/tb_top/u_dut/u_fsqrt_r16_block/m_p2_1st}
add wave -position insertpoint -group 1ST_SRT {sim:/tb_top/u_dut/u_fsqrt_r16_block/root_ext_last_cycle}
add wave -position insertpoint -group 1ST_SRT {sim:/tb_top/u_dut/u_fsqrt_r16_block/root_m1_ext_last_cycle}
add wave -position insertpoint -group 1ST_SRT {sim:/tb_top/u_dut/u_fsqrt_r16_block/root_dig_n2_1st}
add wave -position insertpoint -group 1ST_SRT {sim:/tb_top/u_dut/u_fsqrt_r16_block/root_dig_n1_1st}
add wave -position insertpoint -group 1ST_SRT {sim:/tb_top/u_dut/u_fsqrt_r16_block/root_dig_z0_1st}
add wave -position insertpoint -group 1ST_SRT {sim:/tb_top/u_dut/u_fsqrt_r16_block/root_dig_p1_1st}
add wave -position insertpoint -group 1ST_SRT {sim:/tb_top/u_dut/u_fsqrt_r16_block/root_dig_p2_1st}
add wave -position insertpoint -group 1ST_SRT {sim:/tb_top/u_dut/u_fsqrt_r16_block/root_ext_1st}
add wave -position insertpoint -group 1ST_SRT {sim:/tb_top/u_dut/u_fsqrt_r16_block/root_m1_ext_1st}
add wave -position insertpoint -group 1ST_SRT {sim:/tb_top/u_dut/u_fsqrt_r16_block/csa_mask_ext_1st}
add wave -position insertpoint -group 1ST_SRT {sim:/tb_top/u_dut/u_fsqrt_r16_block/csa_mask_1st_root_dig_n2_1st}
add wave -position insertpoint -group 1ST_SRT {sim:/tb_top/u_dut/u_fsqrt_r16_block/csa_mask_1st_root_dig_n1_1st}
add wave -position insertpoint -group 1ST_SRT {sim:/tb_top/u_dut/u_fsqrt_r16_block/csa_mask_1st_root_dig_z0_1st}
add wave -position insertpoint -group 1ST_SRT {sim:/tb_top/u_dut/u_fsqrt_r16_block/csa_mask_1st_root_dig_p1_1st}
add wave -position insertpoint -group 1ST_SRT {sim:/tb_top/u_dut/u_fsqrt_r16_block/csa_mask_1st_root_dig_p2_1st}
add wave -position insertpoint -group 1ST_SRT {sim:/tb_top/u_dut/u_fsqrt_r16_block/f_r_s_1st}
add wave -position insertpoint -group 1ST_SRT {sim:/tb_top/u_dut/u_fsqrt_r16_block/f_r_c_1st}


add wave -position insertpoint -group 2ND_SRT -radix binary {sim:/tb_top/u_dut/u_fsqrt_r16_block/rem_msb_2nd}
add wave -position insertpoint -group 2ND_SRT -radix binary {sim:/tb_top/u_dut/u_fsqrt_r16_block/m_n1_2nd}
add wave -position insertpoint -group 2ND_SRT -radix binary {sim:/tb_top/u_dut/u_fsqrt_r16_block/m_z0_2nd}
add wave -position insertpoint -group 2ND_SRT -radix binary {sim:/tb_top/u_dut/u_fsqrt_r16_block/m_p1_2nd}
add wave -position insertpoint -group 2ND_SRT -radix binary {sim:/tb_top/u_dut/u_fsqrt_r16_block/m_p2_2nd}
add wave -position insertpoint -group 2ND_SRT {sim:/tb_top/u_dut/u_fsqrt_r16_block/root_dig_n2_2nd}
add wave -position insertpoint -group 2ND_SRT {sim:/tb_top/u_dut/u_fsqrt_r16_block/root_dig_n1_2nd}
add wave -position insertpoint -group 2ND_SRT {sim:/tb_top/u_dut/u_fsqrt_r16_block/root_dig_z0_2nd}
add wave -position insertpoint -group 2ND_SRT {sim:/tb_top/u_dut/u_fsqrt_r16_block/root_dig_p1_2nd}
add wave -position insertpoint -group 2ND_SRT {sim:/tb_top/u_dut/u_fsqrt_r16_block/root_dig_p2_2nd}
add wave -position insertpoint -group 2ND_SRT {sim:/tb_top/u_dut/u_fsqrt_r16_block/root_ext_2nd}
add wave -position insertpoint -group 2ND_SRT {sim:/tb_top/u_dut/u_fsqrt_r16_block/root_m1_ext_2nd}
add wave -position insertpoint -group 2ND_SRT {sim:/tb_top/u_dut/u_fsqrt_r16_block/csa_mask_ext_2nd}
add wave -position insertpoint -group 2ND_SRT {sim:/tb_top/u_dut/u_fsqrt_r16_block/csa_mask_2nd_root_dig_n2_2nd}
add wave -position insertpoint -group 2ND_SRT {sim:/tb_top/u_dut/u_fsqrt_r16_block/csa_mask_2nd_root_dig_n1_2nd}
add wave -position insertpoint -group 2ND_SRT {sim:/tb_top/u_dut/u_fsqrt_r16_block/csa_mask_2nd_root_dig_z0_2nd}
add wave -position insertpoint -group 2ND_SRT {sim:/tb_top/u_dut/u_fsqrt_r16_block/csa_mask_2nd_root_dig_p1_2nd}
add wave -position insertpoint -group 2ND_SRT {sim:/tb_top/u_dut/u_fsqrt_r16_block/csa_mask_2nd_root_dig_p2_2nd}
add wave -position insertpoint -group 2ND_SRT {sim:/tb_top/u_dut/u_fsqrt_r16_block/f_r_s_2nd}
add wave -position insertpoint -group 2ND_SRT {sim:/tb_top/u_dut/u_fsqrt_r16_block/f_r_c_2nd}
add wave -position insertpoint -group 2ND_SRT -radix binary {sim:/tb_top/u_dut/u_fsqrt_r16_block/rem_msb_nxt_cycle_1st_srt_o}
add wave -position insertpoint -group 2ND_SRT -radix binary {sim:/tb_top/u_dut/u_fsqrt_r16_block/rem_msb_nxt_cycle_2nd_srt_o}
add wave -position insertpoint -group 2ND_SRT -radix binary {sim:/tb_top/u_dut/u_fsqrt_r16_block/m_n1_nxt_cycle_1st_srt_o}
add wave -position insertpoint -group 2ND_SRT -radix binary {sim:/tb_top/u_dut/u_fsqrt_r16_block/m_z0_nxt_cycle_1st_srt_o}
add wave -position insertpoint -group 2ND_SRT -radix binary {sim:/tb_top/u_dut/u_fsqrt_r16_block/m_p1_nxt_cycle_1st_srt_o}
add wave -position insertpoint -group 2ND_SRT -radix binary {sim:/tb_top/u_dut/u_fsqrt_r16_block/m_p2_nxt_cycle_1st_srt_o}

add wave -position insertpoint -expand -group SRT_TO_RESTORING {sim:/tb_top/u_dut/u_fsqrt_srt_to_restoring/iter_start_i}
add wave -position insertpoint -expand -group SRT_TO_RESTORING {sim:/tb_top/u_dut/u_fsqrt_srt_to_restoring/rem_init}
add wave -position insertpoint -expand -group SRT_TO_RESTORING {sim:/tb_top/u_dut/u_fsqrt_srt_to_restoring/nr_f_r_before_iter}
add wave -position insertpoint -expand -group SRT_TO_RESTORING {sim:/tb_top/u_dut/u_fsqrt_srt_to_restoring/select_root_m1_before_iter}
add wave -position insertpoint -expand -group SRT_TO_RESTORING {sim:/tb_top/u_dut/u_fsqrt_srt_to_restoring/root_dig_before_iter}
add wave -position insertpoint -expand -group SRT_TO_RESTORING {sim:/tb_top/u_dut/u_fsqrt_srt_to_restoring/rem_before_iter_0}
add wave -position insertpoint -expand -group SRT_TO_RESTORING {sim:/tb_top/u_dut/u_fsqrt_srt_to_restoring/root_before_iter_0}
add wave -position insertpoint -expand -group SRT_TO_RESTORING {sim:/tb_top/u_dut/u_fsqrt_srt_to_restoring/rem_before_iter}
add wave -position insertpoint -expand -group SRT_TO_RESTORING {sim:/tb_top/u_dut/u_fsqrt_srt_to_restoring/root_before_iter}
add wave -position insertpoint -expand -group SRT_TO_RESTORING {sim:/tb_top/u_dut/u_fsqrt_srt_to_restoring/srt_root_ext}
add wave -position insertpoint -expand -group SRT_TO_RESTORING {sim:/tb_top/u_dut/u_fsqrt_srt_to_restoring/srt_root_m1_ext}
add wave -position insertpoint -expand -group SRT_TO_RESTORING {sim:/tb_top/u_dut/u_fsqrt_srt_to_restoring/srt_nr_f_r}
add wave -position insertpoint -expand -group SRT_TO_RESTORING {sim:/tb_top/u_dut/u_fsqrt_srt_to_restoring/select_srt_root_m1}
add wave -position insertpoint -expand -group SRT_TO_RESTORING {sim:/tb_top/u_dut/u_fsqrt_srt_to_restoring/srt_root_dig_1st}
add wave -position insertpoint -expand -group SRT_TO_RESTORING {sim:/tb_top/u_dut/u_fsqrt_srt_to_restoring/srt_root_dig_2nd}
add wave -position insertpoint -expand -group SRT_TO_RESTORING {sim:/tb_top/u_dut/u_fsqrt_srt_to_restoring/srt_root_dig_3rd}
add wave -position insertpoint -expand -group SRT_TO_RESTORING {sim:/tb_top/u_dut/u_fsqrt_srt_to_restoring/srt_root_dig_4th}
add wave -position insertpoint -expand -group SRT_TO_RESTORING {sim:/tb_top/u_dut/u_fsqrt_srt_to_restoring/rem_1st}
add wave -position insertpoint -expand -group SRT_TO_RESTORING {sim:/tb_top/u_dut/u_fsqrt_srt_to_restoring/rem_2nd}
add wave -position insertpoint -expand -group SRT_TO_RESTORING {sim:/tb_top/u_dut/u_fsqrt_srt_to_restoring/rem_3rd}
add wave -position insertpoint -expand -group SRT_TO_RESTORING {sim:/tb_top/u_dut/u_fsqrt_srt_to_restoring/rem_4th}
add wave -position insertpoint -expand -group SRT_TO_RESTORING {sim:/tb_top/u_dut/u_fsqrt_srt_to_restoring/root_1st}
add wave -position insertpoint -expand -group SRT_TO_RESTORING {sim:/tb_top/u_dut/u_fsqrt_srt_to_restoring/root_2nd}
add wave -position insertpoint -expand -group SRT_TO_RESTORING {sim:/tb_top/u_dut/u_fsqrt_srt_to_restoring/root_3rd}
add wave -position insertpoint -expand -group SRT_TO_RESTORING {sim:/tb_top/u_dut/u_fsqrt_srt_to_restoring/root_4th}
add wave -position insertpoint -expand -group SRT_TO_RESTORING {sim:/tb_top/u_dut/u_fsqrt_srt_to_restoring/rem_final}
add wave -position insertpoint -expand -group SRT_TO_RESTORING {sim:/tb_top/u_dut/u_fsqrt_srt_to_restoring/rem_3rd[108:54]}
add wave -position insertpoint -expand -group SRT_TO_RESTORING {sim:/tb_top/u_dut/u_fsqrt_srt_to_restoring/rem_4th[108:54]}
add wave -position insertpoint -expand -group SRT_TO_RESTORING {sim:/tb_top/u_dut/u_fsqrt_srt_to_restoring/root_final}
add wave -position insertpoint -expand -group SRT_TO_RESTORING {sim:/tb_top/u_dut/u_fsqrt_srt_to_restoring/root_final_square}
add wave -position insertpoint -expand -group SRT_TO_RESTORING {sim:/tb_top/u_dut/u_fsqrt_srt_to_restoring/rem_final_check_q}
add wave -position insertpoint -expand -group SRT_TO_RESTORING {sim:/tb_top/u_dut/u_fsqrt_srt_to_restoring/restoring_correct}



add wave -position insertpoint -group POST {sim:/tb_top/u_dut/quot_root_iter_q}
add wave -position insertpoint -group POST {sim:/tb_top/u_dut/quot_root_m1_iter_q}
add wave -position insertpoint -group POST {sim:/tb_top/u_dut/f_r_s_fsqrt_q}
add wave -position insertpoint -group POST {sim:/tb_top/u_dut/f_r_c_fsqrt_q}
add wave -position insertpoint -group POST {sim:/tb_top/u_dut/nr_f_r}
add wave -position insertpoint -group POST {sim:/tb_top/u_dut/select_root_m1}
add wave -position insertpoint -group POST {sim:/tb_top/u_dut/root_before_inc}
add wave -position insertpoint -group POST {sim:/tb_top/u_dut/root_m1_before_inc}
add wave -position insertpoint -group POST {sim:/tb_top/u_dut/inc_poisition_fsqrt}
add wave -position insertpoint -group POST {sim:/tb_top/u_dut/quot_root_inc_res}
add wave -position insertpoint -group POST {sim:/tb_top/u_dut/root_m1_inc_res}
add wave -position insertpoint -group POST {sim:/tb_top/u_dut/root_l}
add wave -position insertpoint -group POST {sim:/tb_top/u_dut/root_g}
add wave -position insertpoint -group POST {sim:/tb_top/u_dut/root_s}
add wave -position insertpoint -group POST {sim:/tb_top/u_dut/root_need_round_up}
add wave -position insertpoint -group POST {sim:/tb_top/u_dut/root_m1_l}
add wave -position insertpoint -group POST {sim:/tb_top/u_dut/root_m1_g}
add wave -position insertpoint -group POST {sim:/tb_top/u_dut/root_m1_s}
add wave -position insertpoint -group POST {sim:/tb_top/u_dut/root_m1_need_round_up}
add wave -position insertpoint -group POST {sim:/tb_top/u_dut/root_rounded}
add wave -position insertpoint -group POST {sim:/tb_top/u_dut/root_m1_rounded}
add wave -position insertpoint -group POST {sim:/tb_top/u_dut/frac_rounded_fsqrt}
add wave -position insertpoint -group POST {sim:/tb_top/u_dut/carry_after_round_fsqrt}
add wave -position insertpoint -group POST {sim:/tb_top/u_dut/exp_rounded_fsqrt}



