add wave -position insertpoint -expand -group CLK_RST sim:/tb_top/clk
add wave -position insertpoint -expand -group CLK_RST sim:/tb_top/rst_n

add wave -position insertpoint -expand -group FSM_CTRL -radix unsigned sim:/tb_top/acq_count
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/dut_start_valid
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/dut_start_ready
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/dut_finish_valid
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/dut_finish_ready
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/u_dut/fsm_q
add wave -position insertpoint -expand -group FSM_CTRL -radix unsigned sim:/tb_top/u_dut/iter_num_q
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/u_dut/final_iter
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/fpsqrt_op
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/rm
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/dut_fpsqrt_res

add wave -position insertpoint -group DECODE -radix binary sim:/tb_top/u_dut/op_exp_0
add wave -position insertpoint -group DECODE -radix binary sim:/tb_top/u_dut/op_exp_1
add wave -position insertpoint -group DECODE -radix binary sim:/tb_top/u_dut/op_exp_2
add wave -position insertpoint -group DECODE -radix binary sim:/tb_top/u_dut/op_exp_3
add wave -position insertpoint -group DECODE sim:/tb_top/u_dut/op_is_zero_0
add wave -position insertpoint -group DECODE sim:/tb_top/u_dut/op_is_zero_1
add wave -position insertpoint -group DECODE sim:/tb_top/u_dut/op_is_zero_2
add wave -position insertpoint -group DECODE sim:/tb_top/u_dut/op_is_zero_3
add wave -position insertpoint -group DECODE sim:/tb_top/u_dut/op_is_inf_0
add wave -position insertpoint -group DECODE sim:/tb_top/u_dut/op_is_inf_1
add wave -position insertpoint -group DECODE sim:/tb_top/u_dut/op_is_inf_2
add wave -position insertpoint -group DECODE sim:/tb_top/u_dut/op_is_inf_3
add wave -position insertpoint -group DECODE sim:/tb_top/u_dut/op_is_nan_0
add wave -position insertpoint -group DECODE sim:/tb_top/u_dut/op_is_nan_1
add wave -position insertpoint -group DECODE sim:/tb_top/u_dut/op_is_nan_2
add wave -position insertpoint -group DECODE sim:/tb_top/u_dut/op_is_nan_3
add wave -position insertpoint -group DECODE sim:/tb_top/u_dut/op_invalid_0_d
add wave -position insertpoint -group DECODE sim:/tb_top/u_dut/op_invalid_1_d
add wave -position insertpoint -group DECODE sim:/tb_top/u_dut/op_invalid_2_d
add wave -position insertpoint -group DECODE sim:/tb_top/u_dut/op_invalid_3_d
add wave -position insertpoint -group DECODE sim:/tb_top/u_dut/res_is_nan_0_d
add wave -position insertpoint -group DECODE sim:/tb_top/u_dut/res_is_nan_1_d
add wave -position insertpoint -group DECODE sim:/tb_top/u_dut/res_is_nan_2_d
add wave -position insertpoint -group DECODE sim:/tb_top/u_dut/res_is_nan_3_d
add wave -position insertpoint -group DECODE sim:/tb_top/u_dut/res_is_exact_zero_0_d
add wave -position insertpoint -group DECODE sim:/tb_top/u_dut/res_is_exact_zero_1_d
add wave -position insertpoint -group DECODE sim:/tb_top/u_dut/res_is_exact_zero_2_d
add wave -position insertpoint -group DECODE sim:/tb_top/u_dut/res_is_exact_zero_3_d
add wave -position insertpoint -group DECODE sim:/tb_top/u_dut/out_sign_0_d
add wave -position insertpoint -group DECODE sim:/tb_top/u_dut/out_sign_1_d
add wave -position insertpoint -group DECODE sim:/tb_top/u_dut/out_sign_2_d
add wave -position insertpoint -group DECODE sim:/tb_top/u_dut/out_sign_3_d
add wave -position insertpoint -group DECODE -radix binary sim:/tb_top/u_dut/out_exp_pre_0
add wave -position insertpoint -group DECODE -radix binary sim:/tb_top/u_dut/out_exp_pre_1
add wave -position insertpoint -group DECODE -radix binary sim:/tb_top/u_dut/out_exp_pre_2
add wave -position insertpoint -group DECODE -radix binary sim:/tb_top/u_dut/out_exp_pre_3
add wave -position insertpoint -group DECODE sim:/tb_top/u_dut/need_2_cycles_init
add wave -position insertpoint -group DECODE sim:/tb_top/u_dut/op_frac_is_zero_0
add wave -position insertpoint -group DECODE sim:/tb_top/u_dut/op_frac_is_zero_1
add wave -position insertpoint -group DECODE sim:/tb_top/u_dut/op_frac_is_zero_2
add wave -position insertpoint -group DECODE sim:/tb_top/u_dut/op_frac_is_zero_3
add wave -position insertpoint -group DECODE sim:/tb_top/u_dut/res_is_sqrt_2_d


add wave -position insertpoint -group Normalization sim:/tb_top/u_dut/op_frac_pre_shifted_0
add wave -position insertpoint -group Normalization -radix unsigned sim:/tb_top/u_dut/op_l_shift_num_0
add wave -position insertpoint -group Normalization sim:/tb_top/u_dut/op_frac_pre_shifted_1
add wave -position insertpoint -group Normalization -radix unsigned sim:/tb_top/u_dut/op_l_shift_num_1
add wave -position insertpoint -group Normalization sim:/tb_top/u_dut/op_frac_pre_shifted_2
add wave -position insertpoint -group Normalization -radix unsigned sim:/tb_top/u_dut/op_l_shift_num_2
add wave -position insertpoint -group Normalization sim:/tb_top/u_dut/op_frac_pre_shifted_3
add wave -position insertpoint -group Normalization -radix unsigned sim:/tb_top/u_dut/op_l_shift_num_3


add wave -position insertpoint -expand -group ROOT_1ST sim:/tb_top/u_dut/exp_is_odd_pre_0_0
add wave -position insertpoint -expand -group ROOT_1ST sim:/tb_top/u_dut/current_exp_is_odd_0
add wave -position insertpoint -expand -group ROOT_1ST sim:/tb_top/u_dut/current_frac_0
add wave -position insertpoint -expand -group ROOT_1ST -radix binary sim:/tb_top/u_dut/rt_1st_0
add wave -position insertpoint -expand -group ROOT_1ST sim:/tb_top/u_dut/rt_iter_init_0
add wave -position insertpoint -expand -group ROOT_1ST sim:/tb_top/u_dut/rt_m1_iter_init_0

add wave -position insertpoint -expand -group ROOT_1ST sim:/tb_top/u_dut/exp_is_odd_pre_0_1
add wave -position insertpoint -expand -group ROOT_1ST sim:/tb_top/u_dut/current_exp_is_odd_1
add wave -position insertpoint -expand -group ROOT_1ST sim:/tb_top/u_dut/current_frac_1
add wave -position insertpoint -expand -group ROOT_1ST -radix binary sim:/tb_top/u_dut/rt_1st_1
add wave -position insertpoint -expand -group ROOT_1ST sim:/tb_top/u_dut/rt_iter_init_1
add wave -position insertpoint -expand -group ROOT_1ST sim:/tb_top/u_dut/rt_m1_iter_init_1

add wave -position insertpoint -expand -group ROOT_1ST sim:/tb_top/u_dut/exp_is_odd_pre_0_2
add wave -position insertpoint -expand -group ROOT_1ST sim:/tb_top/u_dut/current_exp_is_odd_2
add wave -position insertpoint -expand -group ROOT_1ST sim:/tb_top/u_dut/current_frac_2
add wave -position insertpoint -expand -group ROOT_1ST -radix binary sim:/tb_top/u_dut/rt_1st_2
add wave -position insertpoint -expand -group ROOT_1ST sim:/tb_top/u_dut/rt_iter_init_2
add wave -position insertpoint -expand -group ROOT_1ST sim:/tb_top/u_dut/rt_m1_iter_init_2

add wave -position insertpoint -expand -group ROOT_1ST sim:/tb_top/u_dut/exp_is_odd_pre_0_3
add wave -position insertpoint -expand -group ROOT_1ST sim:/tb_top/u_dut/current_exp_is_odd_3
add wave -position insertpoint -expand -group ROOT_1ST sim:/tb_top/u_dut/current_frac_3
add wave -position insertpoint -expand -group ROOT_1ST -radix binary sim:/tb_top/u_dut/rt_1st_3
add wave -position insertpoint -expand -group ROOT_1ST sim:/tb_top/u_dut/rt_iter_init_3
add wave -position insertpoint -expand -group ROOT_1ST sim:/tb_top/u_dut/rt_m1_iter_init_3

add wave -position insertpoint -expand -group NR_F_R -radix binary sim:/tb_top/u_dut/nr_f_r_7b_for_nxt_cycle_s0_qds_0_q
add wave -position insertpoint -expand -group NR_F_R -radix binary sim:/tb_top/u_dut/nr_f_r_7b_for_nxt_cycle_s0_qds_1_q
add wave -position insertpoint -expand -group NR_F_R -radix binary sim:/tb_top/u_dut/nr_f_r_7b_for_nxt_cycle_s0_qds_2_q
add wave -position insertpoint -expand -group NR_F_R -radix binary sim:/tb_top/u_dut/nr_f_r_7b_for_nxt_cycle_s0_qds_3_q
add wave -position insertpoint -expand -group NR_F_R -radix binary sim:/tb_top/u_dut/nr_f_r_9b_for_nxt_cycle_s1_qds_0_q
add wave -position insertpoint -expand -group NR_F_R -radix binary sim:/tb_top/u_dut/nr_f_r_9b_for_nxt_cycle_s1_qds_1_q
add wave -position insertpoint -expand -group NR_F_R -radix binary sim:/tb_top/u_dut/nr_f_r_9b_for_nxt_cycle_s1_qds_2_q
add wave -position insertpoint -expand -group NR_F_R -radix binary sim:/tb_top/u_dut/nr_f_r_9b_for_nxt_cycle_s1_qds_3_q

add wave -position insertpoint -group NXT_CYCLE_CONSTANTS -radix binary sim:/tb_top/u_dut/m_neg_1_for_nxt_cycle_s0_qds_0_q
add wave -position insertpoint -group NXT_CYCLE_CONSTANTS -radix binary sim:/tb_top/u_dut/m_neg_1_for_nxt_cycle_s0_qds_1_q
add wave -position insertpoint -group NXT_CYCLE_CONSTANTS -radix binary sim:/tb_top/u_dut/m_neg_1_for_nxt_cycle_s0_qds_2_q
add wave -position insertpoint -group NXT_CYCLE_CONSTANTS -radix binary sim:/tb_top/u_dut/m_neg_1_for_nxt_cycle_s0_qds_3_q
add wave -position insertpoint -group NXT_CYCLE_CONSTANTS -radix binary sim:/tb_top/u_dut/m_neg_0_for_nxt_cycle_s0_qds_0_q
add wave -position insertpoint -group NXT_CYCLE_CONSTANTS -radix binary sim:/tb_top/u_dut/m_neg_0_for_nxt_cycle_s0_qds_1_q
add wave -position insertpoint -group NXT_CYCLE_CONSTANTS -radix binary sim:/tb_top/u_dut/m_neg_0_for_nxt_cycle_s0_qds_2_q
add wave -position insertpoint -group NXT_CYCLE_CONSTANTS -radix binary sim:/tb_top/u_dut/m_neg_0_for_nxt_cycle_s0_qds_3_q
add wave -position insertpoint -group NXT_CYCLE_CONSTANTS -radix binary sim:/tb_top/u_dut/m_pos_1_for_nxt_cycle_s0_qds_0_q
add wave -position insertpoint -group NXT_CYCLE_CONSTANTS -radix binary sim:/tb_top/u_dut/m_pos_1_for_nxt_cycle_s0_qds_1_q
add wave -position insertpoint -group NXT_CYCLE_CONSTANTS -radix binary sim:/tb_top/u_dut/m_pos_1_for_nxt_cycle_s0_qds_2_q
add wave -position insertpoint -group NXT_CYCLE_CONSTANTS -radix binary sim:/tb_top/u_dut/m_pos_1_for_nxt_cycle_s0_qds_3_q
add wave -position insertpoint -group NXT_CYCLE_CONSTANTS -radix binary sim:/tb_top/u_dut/m_pos_2_for_nxt_cycle_s0_qds_0_q
add wave -position insertpoint -group NXT_CYCLE_CONSTANTS -radix binary sim:/tb_top/u_dut/m_pos_2_for_nxt_cycle_s0_qds_1_q
add wave -position insertpoint -group NXT_CYCLE_CONSTANTS -radix binary sim:/tb_top/u_dut/m_pos_2_for_nxt_cycle_s0_qds_2_q
add wave -position insertpoint -group NXT_CYCLE_CONSTANTS -radix binary sim:/tb_top/u_dut/m_pos_2_for_nxt_cycle_s0_qds_3_q

add wave -position insertpoint -expand -group ROOT_PATH -radix binary sim:/tb_top/u_dut/mask_q
add wave -position insertpoint -expand -group ROOT_PATH sim:/tb_top/u_dut/rt_iter_init
add wave -position insertpoint -expand -group ROOT_PATH sim:/tb_top/u_dut/rt_m1_iter_init
add wave -position insertpoint -expand -group ROOT_PATH sim:/tb_top/u_dut/rt_q
add wave -position insertpoint -expand -group ROOT_PATH sim:/tb_top/u_dut/rt_m1_q
add wave -position insertpoint -expand -group ROOT_PATH sim:/tb_top/u_dut/nxt_rt
add wave -position insertpoint -expand -group ROOT_PATH sim:/tb_top/u_dut/nxt_rt_m1

add wave -position insertpoint -expand -group REM_PATH sim:/tb_top/u_dut/f_r_s_iter_init
add wave -position insertpoint -expand -group REM_PATH sim:/tb_top/u_dut/f_r_c_iter_init
add wave -position insertpoint -expand -group REM_PATH sim:/tb_top/u_dut/f_r_s_q
add wave -position insertpoint -expand -group REM_PATH sim:/tb_top/u_dut/f_r_c_q
add wave -position insertpoint -expand -group REM_PATH sim:/tb_top/u_dut/nxt_f_r_s
add wave -position insertpoint -expand -group REM_PATH sim:/tb_top/u_dut/nxt_f_r_c


add wave -position insertpoint -group S0_MERGED_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/f_r_s_for_csa_merged[0]
add wave -position insertpoint -group S0_MERGED_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/f_r_c_for_csa_merged[0]
add wave -position insertpoint -group S0_MERGED_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/sqrt_csa_val_merged[0]
add wave -position insertpoint -group S0_MERGED_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/nxt_f_r_s_merged[0]
add wave -position insertpoint -group S0_MERGED_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/nxt_f_r_c_merged_pre[0]
add wave -position insertpoint -group S0_MERGED_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/nxt_f_r_c_merged[0]


add wave -position insertpoint -group S0_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/mask_csa_ext[0]
add wave -position insertpoint -group S0_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/rt_0
add wave -position insertpoint -group S0_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/rt_m1_0
add wave -position insertpoint -group S0_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/rt_1
add wave -position insertpoint -group S0_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/rt_m1_1
add wave -position insertpoint -group S0_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/rt_2
add wave -position insertpoint -group S0_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/rt_m1_2
add wave -position insertpoint -group S0_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/rt_3
add wave -position insertpoint -group S0_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/rt_m1_3

add wave -position insertpoint -group S0_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/m_neg_1_0[0]
add wave -position insertpoint -group S0_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/m_neg_0_0[0]
add wave -position insertpoint -group S0_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/m_pos_1_0[0]
add wave -position insertpoint -group S0_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/m_pos_2_0[0]
add wave -position insertpoint -group S0_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/m_neg_1_1[0]
add wave -position insertpoint -group S0_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/m_neg_0_1[0]
add wave -position insertpoint -group S0_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/m_pos_1_1[0]
add wave -position insertpoint -group S0_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/m_pos_2_1[0]
add wave -position insertpoint -group S0_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/m_neg_1_2[0]
add wave -position insertpoint -group S0_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/m_neg_0_2[0]
add wave -position insertpoint -group S0_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/m_pos_1_2[0]
add wave -position insertpoint -group S0_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/m_pos_2_2[0]
add wave -position insertpoint -group S0_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/m_neg_1_3[0]
add wave -position insertpoint -group S0_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/m_neg_0_3[0]
add wave -position insertpoint -group S0_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/m_pos_1_3[0]
add wave -position insertpoint -group S0_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/m_pos_2_3[0]
add wave -position insertpoint -group S0_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/u_r4_qds_s0_0/rem_i
add wave -position insertpoint -group S0_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/u_r4_qds_s0_0/qds_sign
add wave -position insertpoint -group S0_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/nxt_rt_dig_0[0]
add wave -position insertpoint -group S0_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/u_r4_qds_s0_1/rem_i
add wave -position insertpoint -group S0_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/u_r4_qds_s0_1/qds_sign
add wave -position insertpoint -group S0_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/nxt_rt_dig_1[0]
add wave -position insertpoint -group S0_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/u_r4_qds_s0_2/rem_i
add wave -position insertpoint -group S0_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/u_r4_qds_s0_2/qds_sign
add wave -position insertpoint -group S0_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/nxt_rt_dig_2[0]
add wave -position insertpoint -group S0_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/u_r4_qds_s0_3/rem_i
add wave -position insertpoint -group S0_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/u_r4_qds_s0_3/qds_sign
add wave -position insertpoint -group S0_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/nxt_rt_dig_3[0]


add wave -position insertpoint -group S0_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/rt_for_csa_0[0]
add wave -position insertpoint -group S0_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/rt_m1_for_csa_0[0]
add wave -position insertpoint -group S0_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/f_r_s_for_csa_0[0]
add wave -position insertpoint -group S0_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/f_r_c_for_csa_0[0]
add wave -position insertpoint -group S0_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/sqrt_csa_val_neg_2_0[0]
add wave -position insertpoint -group S0_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/sqrt_csa_val_neg_1_0[0]
add wave -position insertpoint -group S0_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/sqrt_csa_val_pos_1_0[0]
add wave -position insertpoint -group S0_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/sqrt_csa_val_pos_2_0[0]
add wave -position insertpoint -group S0_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/sqrt_csa_val_0[0]
add wave -position insertpoint -group S0_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/nxt_f_r_s_0[0]
add wave -position insertpoint -group S0_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/nxt_f_r_c_0[0]
add wave -position insertpoint -group S0_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/nxt_rt_0[0]
add wave -position insertpoint -group S0_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/nxt_rt_m1_0[0]


add wave -position insertpoint -group S0_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/rt_for_csa_1[0]
add wave -position insertpoint -group S0_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/rt_m1_for_csa_1[0]
add wave -position insertpoint -group S0_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/f_r_s_for_csa_1[0]
add wave -position insertpoint -group S0_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/f_r_c_for_csa_1[0]
add wave -position insertpoint -group S0_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/sqrt_csa_val_neg_2_1[0]
add wave -position insertpoint -group S0_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/sqrt_csa_val_neg_1_1[0]
add wave -position insertpoint -group S0_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/sqrt_csa_val_pos_1_1[0]
add wave -position insertpoint -group S0_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/sqrt_csa_val_pos_2_1[0]
add wave -position insertpoint -group S0_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/sqrt_csa_val_1[0]
add wave -position insertpoint -group S0_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/nxt_f_r_s_1[0]
add wave -position insertpoint -group S0_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/nxt_f_r_c_1[0]
add wave -position insertpoint -group S0_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/nxt_rt_1[0]
add wave -position insertpoint -group S0_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/nxt_rt_m1_1[0]


add wave -position insertpoint -group S0_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/f_r_s_for_csa_2[0]
add wave -position insertpoint -group S0_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/f_r_c_for_csa_2[0]
add wave -position insertpoint -group S0_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/sqrt_csa_val_neg_2_2[0]
add wave -position insertpoint -group S0_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/sqrt_csa_val_neg_1_2[0]
add wave -position insertpoint -group S0_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/sqrt_csa_val_pos_1_2[0]
add wave -position insertpoint -group S0_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/sqrt_csa_val_pos_2_2[0]
add wave -position insertpoint -group S0_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/sqrt_csa_val_2[0]
add wave -position insertpoint -group S0_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/nxt_f_r_s_2[0]
add wave -position insertpoint -group S0_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/nxt_f_r_c_2[0]
add wave -position insertpoint -group S0_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/nxt_rt_2[0]
add wave -position insertpoint -group S0_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/nxt_rt_m1_2[0]


add wave -position insertpoint -group S0_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/f_r_s_for_csa_3[0]
add wave -position insertpoint -group S0_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/f_r_c_for_csa_3[0]
add wave -position insertpoint -group S0_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/sqrt_csa_val_neg_2_3[0]
add wave -position insertpoint -group S0_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/sqrt_csa_val_neg_1_3[0]
add wave -position insertpoint -group S0_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/sqrt_csa_val_pos_1_3[0]
add wave -position insertpoint -group S0_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/sqrt_csa_val_pos_2_3[0]
add wave -position insertpoint -group S0_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/sqrt_csa_val_3[0]
add wave -position insertpoint -group S0_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/nxt_f_r_s_3[0]
add wave -position insertpoint -group S0_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/nxt_f_r_c_3[0]
add wave -position insertpoint -group S0_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/nxt_rt_3[0]
add wave -position insertpoint -group S0_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/nxt_rt_m1_3[0]


add wave -position insertpoint -group S1_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/m_neg_1_0[1]
add wave -position insertpoint -group S1_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/m_neg_0_0[1]
add wave -position insertpoint -group S1_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/m_pos_1_0[1]
add wave -position insertpoint -group S1_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/m_pos_2_0[1]
add wave -position insertpoint -group S1_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/m_neg_1_1[1]
add wave -position insertpoint -group S1_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/m_neg_0_1[1]
add wave -position insertpoint -group S1_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/m_pos_1_1[1]
add wave -position insertpoint -group S1_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/m_pos_2_1[1]
add wave -position insertpoint -group S1_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/m_neg_1_2[1]
add wave -position insertpoint -group S1_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/m_neg_0_2[1]
add wave -position insertpoint -group S1_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/m_pos_1_2[1]
add wave -position insertpoint -group S1_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/m_pos_2_2[1]
add wave -position insertpoint -group S1_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/m_neg_1_3[1]
add wave -position insertpoint -group S1_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/m_neg_0_3[1]
add wave -position insertpoint -group S1_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/m_pos_1_3[1]
add wave -position insertpoint -group S1_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/m_pos_2_3[1]
add wave -position insertpoint -group S1_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/g_n_s1_qds_spec/u_r4_qds_s1_0/rem_i
add wave -position insertpoint -group S1_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/g_n_s1_qds_spec/u_r4_qds_s1_0/qds_sign
add wave -position insertpoint -group S1_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/nxt_rt_dig_0[1]
add wave -position insertpoint -group S1_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/g_n_s1_qds_spec/u_r4_qds_s1_1/rem_i
add wave -position insertpoint -group S1_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/g_n_s1_qds_spec/u_r4_qds_s1_1/qds_sign
add wave -position insertpoint -group S1_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/nxt_rt_dig_1[1]
add wave -position insertpoint -group S1_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/g_n_s1_qds_spec/u_r4_qds_s1_2/rem_i
add wave -position insertpoint -group S1_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/g_n_s1_qds_spec/u_r4_qds_s1_2/qds_sign
add wave -position insertpoint -group S1_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/nxt_rt_dig_2[1]
add wave -position insertpoint -group S1_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/g_n_s1_qds_spec/u_r4_qds_s1_3/rem_i
add wave -position insertpoint -group S1_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/g_n_s1_qds_spec/u_r4_qds_s1_3/qds_sign
add wave -position insertpoint -group S1_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/nxt_rt_dig_3[1]


add wave -position insertpoint -group S1_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/rt_for_csa_0[1]
add wave -position insertpoint -group S1_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/rt_m1_for_csa_0[1]
add wave -position insertpoint -group S1_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/f_r_s_for_csa_0[1]
add wave -position insertpoint -group S1_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/f_r_c_for_csa_0[1]
add wave -position insertpoint -group S1_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/sqrt_csa_val_neg_2_0[1]
add wave -position insertpoint -group S1_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/sqrt_csa_val_neg_1_0[1]
add wave -position insertpoint -group S1_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/sqrt_csa_val_pos_1_0[1]
add wave -position insertpoint -group S1_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/sqrt_csa_val_pos_2_0[1]
add wave -position insertpoint -group S1_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/sqrt_csa_val_0[1]
add wave -position insertpoint -group S1_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/nxt_f_r_s_0[1]
add wave -position insertpoint -group S1_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/nxt_f_r_c_0[1]
add wave -position insertpoint -group S1_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/nxt_rt_0[1]
add wave -position insertpoint -group S1_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/nxt_rt_m1_0[1]


add wave -position insertpoint -group S1_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/rt_for_csa_1[1]
add wave -position insertpoint -group S1_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/rt_m1_for_csa_1[1]
add wave -position insertpoint -group S1_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/f_r_s_for_csa_1[1]
add wave -position insertpoint -group S1_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/f_r_c_for_csa_1[1]
add wave -position insertpoint -group S1_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/sqrt_csa_val_neg_2_1[1]
add wave -position insertpoint -group S1_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/sqrt_csa_val_neg_1_1[1]
add wave -position insertpoint -group S1_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/sqrt_csa_val_pos_1_1[1]
add wave -position insertpoint -group S1_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/sqrt_csa_val_pos_2_1[1]
add wave -position insertpoint -group S1_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/sqrt_csa_val_1[1]
add wave -position insertpoint -group S1_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/nxt_f_r_s_1[1]
add wave -position insertpoint -group S1_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/nxt_f_r_c_1[1]
add wave -position insertpoint -group S1_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/nxt_rt_1[1]
add wave -position insertpoint -group S1_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/nxt_rt_m1_1[1]


add wave -position insertpoint -group S1_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/f_r_s_for_csa_2[1]
add wave -position insertpoint -group S1_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/f_r_c_for_csa_2[1]
add wave -position insertpoint -group S1_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/sqrt_csa_val_neg_2_2[1]
add wave -position insertpoint -group S1_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/sqrt_csa_val_neg_1_2[1]
add wave -position insertpoint -group S1_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/sqrt_csa_val_pos_1_2[1]
add wave -position insertpoint -group S1_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/sqrt_csa_val_pos_2_2[1]
add wave -position insertpoint -group S1_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/sqrt_csa_val_2[1]
add wave -position insertpoint -group S1_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/nxt_f_r_s_2[1]
add wave -position insertpoint -group S1_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/nxt_f_r_c_2[1]
add wave -position insertpoint -group S1_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/nxt_rt_2[1]
add wave -position insertpoint -group S1_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/nxt_rt_m1_2[1]


add wave -position insertpoint -group S1_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/f_r_s_for_csa_3[1]
add wave -position insertpoint -group S1_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/f_r_c_for_csa_3[1]
add wave -position insertpoint -group S1_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/sqrt_csa_val_neg_2_3[1]
add wave -position insertpoint -group S1_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/sqrt_csa_val_neg_1_3[1]
add wave -position insertpoint -group S1_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/sqrt_csa_val_pos_1_3[1]
add wave -position insertpoint -group S1_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/sqrt_csa_val_pos_2_3[1]
add wave -position insertpoint -group S1_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/sqrt_csa_val_3[1]
add wave -position insertpoint -group S1_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/nxt_f_r_s_3[1]
add wave -position insertpoint -group S1_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/nxt_f_r_c_3[1]
add wave -position insertpoint -group S1_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/nxt_rt_3[1]
add wave -position insertpoint -group S1_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/nxt_rt_m1_3[1]


add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/nr_f_r_adder_in[0]
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/nr_f_r_adder_in[1]
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/nr_f_r
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/nr_f_r_merged
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/f_r_xor
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/f_r_or
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/rem_is_not_zero_0
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/rem_is_not_zero_1
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/rem_is_not_zero_2
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/rem_is_not_zero_3
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/select_rt_m1_0
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/select_rt_m1_1
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/select_rt_m1_2
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/select_rt_m1_3
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/f64_res_is_sqrt_2
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/f32_res_is_sqrt_2
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/f16_res_is_sqrt_2
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/rt_pre_inc
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/rt_inc_lane
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/rt_inc_res
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/rt_m1_pre_inc_0
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/rt_m1_pre_inc_1
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/rt_m1_pre_inc_2
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/rt_m1_pre_inc_3
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/rt_m1_inc_res_0
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/rt_m1_inc_res_1
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/rt_m1_inc_res_2
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/rt_m1_inc_res_3


add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/round_bit_rt_0
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/round_bit_rt_1
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/round_bit_rt_2
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/round_bit_rt_3
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/rt_need_rup_0
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/rt_need_rup_1
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/rt_need_rup_2
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/rt_need_rup_3
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/rt_m1_need_rup_0
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/rt_m1_need_rup_1
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/rt_m1_need_rup_2
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/rt_m1_need_rup_3
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/rt_rounded_0
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/rt_rounded_1
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/rt_rounded_2
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/rt_rounded_3
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/rt_m1_rounded_0
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/rt_m1_rounded_1
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/rt_m1_rounded_2
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/rt_m1_rounded_3
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/frac_rounded_0
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/frac_rounded_1
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/frac_rounded_2
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/frac_rounded_3
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/exp_rounded_0
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/exp_rounded_1
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/exp_rounded_2
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/exp_rounded_3


add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/f16_res_0
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/f16_res_1
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/f16_res_2
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/f16_res_3
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/f32_res_0
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/f32_res_1
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/f64_res_0















