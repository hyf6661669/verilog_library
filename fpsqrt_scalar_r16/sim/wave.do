add wave -position insertpoint -expand -group CLK_RST sim:/tb_top/clk
add wave -position insertpoint -expand -group CLK_RST sim:/tb_top/rst_n


add wave -position insertpoint -expand -group FSM_CTRL -radix unsigned sim:/tb_top/acq_count
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/stim_end
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/dut_start_valid
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/dut_start_ready
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/dut_finish_valid
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/dut_finish_ready
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/u_dut/fsm_q
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/u_dut/final_iter
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/fpsqrt_op
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/dut_fpsqrt_res

add wave -position insertpoint -expand -group PRE -radix binary sim:/tb_top/u_dut/rt_dig_1st
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/rt_iter_init
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/rt_m1_iter_init
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/f_r_s_iter_init_pre
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/f_r_s_iter_init
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/f_r_c_iter_init
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/out_exp_d
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/op_exp_is_zero
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/op_frac_pre_shifted
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/op_l_shift_num
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/op_frac_l_shifted
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/current_exp_is_odd
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/current_frac
add wave -position insertpoint -expand -group PRE -radix binary sim:/tb_top/u_dut/adder_8b_iter_init
add wave -position insertpoint -expand -group PRE -radix binary sim:/tb_top/u_dut/adder_9b_iter_init
add wave -position insertpoint -expand -group PRE -radix binary sim:/tb_top/u_dut/a0_iter_init
add wave -position insertpoint -expand -group PRE -radix binary sim:/tb_top/u_dut/a2_iter_init
add wave -position insertpoint -expand -group PRE -radix binary sim:/tb_top/u_dut/a3_iter_init
add wave -position insertpoint -expand -group PRE -radix binary sim:/tb_top/u_dut/a4_iter_init
add wave -position insertpoint -expand -group PRE -radix binary sim:/tb_top/u_dut/m_neg_1_iter_init
add wave -position insertpoint -expand -group PRE -radix binary sim:/tb_top/u_dut/m_neg_0_iter_init
add wave -position insertpoint -expand -group PRE -radix binary sim:/tb_top/u_dut/m_pos_1_iter_init
add wave -position insertpoint -expand -group PRE -radix binary sim:/tb_top/u_dut/m_pos_2_iter_init

add wave -position insertpoint -expand -group SPECIAL_SIGNALS sim:/tb_top/u_dut/res_is_nan_d
add wave -position insertpoint -expand -group SPECIAL_SIGNALS sim:/tb_top/u_dut/res_is_inf_d
add wave -position insertpoint -expand -group SPECIAL_SIGNALS sim:/tb_top/u_dut/res_is_exact_zero_d
add wave -position insertpoint -expand -group SPECIAL_SIGNALS sim:/tb_top/u_dut/op_invalid_d
add wave -position insertpoint -expand -group SPECIAL_SIGNALS sim:/tb_top/u_dut/res_is_sqrt_2_d
add wave -position insertpoint -expand -group SPECIAL_SIGNALS sim:/tb_top/u_dut/early_finish


add wave -position insertpoint -expand -group REM_PATH sim:/tb_top/u_dut/f_r_s_q
add wave -position insertpoint -expand -group REM_PATH sim:/tb_top/u_dut/f_r_c_q
add wave -position insertpoint -expand -group REM_PATH -radix binary sim:/tb_top/u_dut/mask_q
add wave -position insertpoint -expand -group REM_PATH -radix binary sim:/tb_top/u_dut/nr_f_r_7b_for_nxt_cycle_s0_qds_q
add wave -position insertpoint -expand -group REM_PATH -radix binary sim:/tb_top/u_dut/nr_f_r_9b_for_nxt_cycle_s1_qds_q
add wave -position insertpoint -expand -group REM_PATH -radix binary sim:/tb_top/u_dut/m_neg_1_for_nxt_cycle_s0_qds_q
add wave -position insertpoint -expand -group REM_PATH -radix binary sim:/tb_top/u_dut/m_neg_0_for_nxt_cycle_s0_qds_q
add wave -position insertpoint -expand -group REM_PATH -radix binary sim:/tb_top/u_dut/m_pos_1_for_nxt_cycle_s0_qds_q
add wave -position insertpoint -expand -group REM_PATH -radix binary sim:/tb_top/u_dut/m_pos_2_for_nxt_cycle_s0_qds_q

add wave -position insertpoint -expand -group ROOT_PATH sim:/tb_top/u_dut/rt_q
add wave -position insertpoint -expand -group ROOT_PATH sim:/tb_top/u_dut/rt_m1_q
add wave -position insertpoint -expand -group ROOT_PATH -radix binary sim:/tb_top/u_dut/iter_num_q

add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/nr_f_r
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/rem_is_not_zero
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/rt_pre_inc
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/rt_m1_pre_inc
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/rt_inc_res
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/rt_m1_inc_res
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/select_rt_m1
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/guard_bit_rt
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/round_bit_rt
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/sticky_bit_rt
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/rt_need_rup
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/rt_m1_need_rup
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/frac_rounded
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/exp_rounded
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/f16_res
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/f32_res
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/f64_res

add wave -position insertpoint -expand -group S0_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/m_neg_1[0]
add wave -position insertpoint -expand -group S0_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/m_neg_0[0]
add wave -position insertpoint -expand -group S0_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/m_pos_1[0]
add wave -position insertpoint -expand -group S0_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/m_pos_2[0]
add wave -position insertpoint -expand -group S0_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/u_r4_qds_s0/rem_i
add wave -position insertpoint -expand -group S0_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/u_r4_qds_s0/qds_sign
add wave -position insertpoint -expand -group S0_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/nxt_rt_dig[0]
add wave -position insertpoint -expand -group S0_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/mask_csa_ext[0]
add wave -position insertpoint -expand -group S0_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/sqrt_csa_val_neg_2[0]
add wave -position insertpoint -expand -group S0_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/sqrt_csa_val_neg_1[0]
add wave -position insertpoint -expand -group S0_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/sqrt_csa_val_pos_1[0]
add wave -position insertpoint -expand -group S0_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/sqrt_csa_val_pos_2[0]
add wave -position insertpoint -expand -group S0_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/sqrt_csa_val[0]
add wave -position insertpoint -expand -group S0_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/rt
add wave -position insertpoint -expand -group S0_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/rt_m1
add wave -position insertpoint -expand -group S0_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/nxt_f_r_s[0]
add wave -position insertpoint -expand -group S0_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/nxt_f_r_c[0]
add wave -position insertpoint -expand -group S0_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/nxt_rt[0]
add wave -position insertpoint -expand -group S0_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/nxt_rt_m1[0]


add wave -position insertpoint -expand -group S1_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/m_neg_1[1]
add wave -position insertpoint -expand -group S1_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/m_neg_0[1]
add wave -position insertpoint -expand -group S1_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/m_pos_1[1]
add wave -position insertpoint -expand -group S1_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/m_pos_2[1]

# Used for S1_QDS_SPECULATIVE = 0
add wave -position insertpoint -expand -group S1_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/g_s1_qds_no_spec/u_r4_qds_s1/rem_i
add wave -position insertpoint -expand -group S1_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/g_s1_qds_no_spec/u_r4_qds_s1/qds_sign

# Used for S1_QDS_SPECULATIVE = 1
# add wave -position insertpoint -expand -group S1_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/g_s1_qds_spec/u_r4_qds_s1/rem_i
# add wave -position insertpoint -expand -group S1_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/g_s1_qds_spec/u_r4_qds_s1/sqrt_csa_val_neg_2_msbs_i
# add wave -position insertpoint -expand -group S1_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/g_s1_qds_spec/u_r4_qds_s1/sqrt_csa_val_neg_1_msbs_i
# add wave -position insertpoint -expand -group S1_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/g_s1_qds_spec/u_r4_qds_s1/sqrt_csa_val_pos_1_msbs_i
# add wave -position insertpoint -expand -group S1_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/g_s1_qds_spec/u_r4_qds_s1/sqrt_csa_val_pos_2_msbs_i
# add wave -position insertpoint -expand -group S1_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/g_s1_qds_spec/u_r4_qds_s1/m_neg_1_neg_2_i
# add wave -position insertpoint -expand -group S1_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/g_s1_qds_spec/u_r4_qds_s1/m_neg_0_neg_2_i
# add wave -position insertpoint -expand -group S1_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/g_s1_qds_spec/u_r4_qds_s1/m_pos_1_neg_2_i
# add wave -position insertpoint -expand -group S1_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/g_s1_qds_spec/u_r4_qds_s1/m_pos_2_neg_2_i
# add wave -position insertpoint -expand -group S1_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/g_s1_qds_spec/u_r4_qds_s1/m_neg_1_neg_1_i
# add wave -position insertpoint -expand -group S1_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/g_s1_qds_spec/u_r4_qds_s1/m_neg_0_neg_1_i
# add wave -position insertpoint -expand -group S1_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/g_s1_qds_spec/u_r4_qds_s1/m_pos_1_neg_1_i
# add wave -position insertpoint -expand -group S1_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/g_s1_qds_spec/u_r4_qds_s1/m_pos_2_neg_1_i
# add wave -position insertpoint -expand -group S1_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/g_s1_qds_spec/u_r4_qds_s1/m_neg_1_neg_0_i
# add wave -position insertpoint -expand -group S1_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/g_s1_qds_spec/u_r4_qds_s1/m_neg_0_neg_0_i
# add wave -position insertpoint -expand -group S1_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/g_s1_qds_spec/u_r4_qds_s1/m_pos_1_neg_0_i
# add wave -position insertpoint -expand -group S1_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/g_s1_qds_spec/u_r4_qds_s1/m_pos_2_neg_0_i
# add wave -position insertpoint -expand -group S1_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/g_s1_qds_spec/u_r4_qds_s1/m_neg_1_pos_1_i
# add wave -position insertpoint -expand -group S1_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/g_s1_qds_spec/u_r4_qds_s1/m_neg_0_pos_1_i
# add wave -position insertpoint -expand -group S1_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/g_s1_qds_spec/u_r4_qds_s1/m_pos_1_pos_1_i
# add wave -position insertpoint -expand -group S1_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/g_s1_qds_spec/u_r4_qds_s1/m_pos_2_pos_1_i
# add wave -position insertpoint -expand -group S1_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/g_s1_qds_spec/u_r4_qds_s1/m_neg_1_pos_2_i
# add wave -position insertpoint -expand -group S1_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/g_s1_qds_spec/u_r4_qds_s1/m_neg_0_pos_2_i
# add wave -position insertpoint -expand -group S1_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/g_s1_qds_spec/u_r4_qds_s1/m_pos_1_pos_2_i
# add wave -position insertpoint -expand -group S1_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/g_s1_qds_spec/u_r4_qds_s1/m_pos_2_pos_2_i
# add wave -position insertpoint -expand -group S1_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/g_s1_qds_spec/u_r4_qds_s1/prev_rt_dig_i
# add wave -position insertpoint -expand -group S1_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/g_s1_qds_spec/u_r4_qds_s1/qds_sign_spec[4]
# add wave -position insertpoint -expand -group S1_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/g_s1_qds_spec/u_r4_qds_s1/qds_sign_spec[3]
# add wave -position insertpoint -expand -group S1_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/g_s1_qds_spec/u_r4_qds_s1/qds_sign_spec[2]
# add wave -position insertpoint -expand -group S1_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/g_s1_qds_spec/u_r4_qds_s1/qds_sign_spec[1]
# add wave -position insertpoint -expand -group S1_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/g_s1_qds_spec/u_r4_qds_s1/qds_sign_spec[0]
# add wave -position insertpoint -expand -group S1_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/g_s1_qds_spec/u_r4_qds_s1/qds_sign

add wave -position insertpoint -expand -group S1_ITER -radix binary sim:/tb_top/u_dut/u_fpsqrt_r16_block/nxt_rt_dig[1]
add wave -position insertpoint -expand -group S1_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/mask_csa_ext[1]
add wave -position insertpoint -expand -group S1_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/sqrt_csa_val_neg_2[1]
add wave -position insertpoint -expand -group S1_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/sqrt_csa_val_neg_1[1]
add wave -position insertpoint -expand -group S1_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/sqrt_csa_val_pos_1[1]
add wave -position insertpoint -expand -group S1_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/sqrt_csa_val_pos_2[1]
add wave -position insertpoint -expand -group S1_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/sqrt_csa_val[1]
add wave -position insertpoint -expand -group S1_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/nxt_f_r_s[1]
add wave -position insertpoint -expand -group S1_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/nxt_f_r_c[1]
add wave -position insertpoint -expand -group S1_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/nxt_rt[1]
add wave -position insertpoint -expand -group S1_ITER sim:/tb_top/u_dut/u_fpsqrt_r16_block/nxt_rt_m1[1]

