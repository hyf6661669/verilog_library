add wave -position insertpoint -expand -group CLK_RST sim:/tb_top/clk
add wave -position insertpoint -expand -group CLK_RST sim:/tb_top/rst_n

add wave -position insertpoint -expand -group FSM_CTRL -radix unsigned sim:/tb_top/acq_count
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/stim_end
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/dut_start_valid
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/dut_start_ready
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/dut_finish_valid
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/dut_finish_ready
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/compare_ok
add wave -position insertpoint -expand -group FSM_CTRL -radix binary sim:/tb_top/u_dut/fsm_q
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/u_dut/iter_num_q
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/u_dut/final_iter

add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/signed_op_i
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/dividend_i
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/divisor_i
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/N_sign
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/D_sign
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/quo_sign_q
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/rem_sign_q
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/N_abs
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/N_abs_pre_1
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/D_abs
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/D_abs_q
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/D_abs_ext
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/normalized_D_q
add wave -position insertpoint -expand -group PRE -radix unsigned sim:/tb_top/u_dut/N_lzc
add wave -position insertpoint -expand -group PRE -radix unsigned sim:/tb_top/u_dut/D_lzc
add wave -position insertpoint -expand -group PRE -radix unsigned sim:/tb_top/u_dut/lzc_diff
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/N_abs_l_shifted_s5_to_s2
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/D_abs_l_shifted_s5_to_s2
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/N_abs_l_shifted
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/D_abs_l_shifted
add wave -position insertpoint -expand -group PRE -radix unsigned sim:/tb_top/u_dut/lzc_diff_pre_1
add wave -position insertpoint -expand -group PRE -radix unsigned sim:/tb_top/u_dut/correct_lzc_diff

add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/N_too_small
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/D_is_zero
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/D_is_one
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/D_is_neg_power_of_2
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/D_is_zero_q
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/D_is_special_q

add wave -position insertpoint -expand -group QDS_CONSTANTS -radix binary sim:/tb_top/u_dut/m_neg_0_pos_1_lsb_q
add wave -position insertpoint -expand -group QDS_CONSTANTS -radix binary sim:/tb_top/u_dut/m_neg_1_init
add wave -position insertpoint -expand -group QDS_CONSTANTS -radix binary sim:/tb_top/u_dut/m_neg_0_init
add wave -position insertpoint -expand -group QDS_CONSTANTS -radix binary sim:/tb_top/u_dut/m_pos_1_init
add wave -position insertpoint -expand -group QDS_CONSTANTS -radix binary sim:/tb_top/u_dut/m_pos_2_init
add wave -position insertpoint -expand -group QDS_CONSTANTS -radix binary sim:/tb_top/u_dut/u_r16_block/m_neg_1
add wave -position insertpoint -expand -group QDS_CONSTANTS -radix binary sim:/tb_top/u_dut/u_r16_block/m_neg_0
add wave -position insertpoint -expand -group QDS_CONSTANTS -radix binary sim:/tb_top/u_dut/u_r16_block/m_pos_1
add wave -position insertpoint -expand -group QDS_CONSTANTS -radix binary sim:/tb_top/u_dut/u_r16_block/m_pos_2


add wave -position insertpoint -expand -group R_PATH sim:/tb_top/u_dut/N_abs_r_shift_num
add wave -position insertpoint -expand -group R_PATH sim:/tb_top/u_dut/N_abs_r_shifted_raw
add wave -position insertpoint -expand -group R_PATH sim:/tb_top/u_dut/N_abs_r_shifted_msbs
add wave -position insertpoint -expand -group R_PATH sim:/tb_top/u_dut/N_abs_r_shifted_lsbs
add wave -position insertpoint -expand -group R_PATH sim:/tb_top/u_dut/N_r_shifted_lsbs_q
add wave -position insertpoint -expand -group R_PATH sim:/tb_top/u_dut/D_inversed_mask
add wave -position insertpoint -expand -group R_PATH sim:/tb_top/u_dut/rem_r_aligned_s_iter_init_normal
add wave -position insertpoint -expand -group R_PATH sim:/tb_top/u_dut/rem_r_aligned_s_iter_init
add wave -position insertpoint -expand -group R_PATH sim:/tb_top/u_dut/N_r_shifted_lsbs_iter_init
add wave -position insertpoint -expand -group R_PATH sim:/tb_top/u_dut/rem_s_iter_init
add wave -position insertpoint -expand -group R_PATH sim:/tb_top/u_dut/rem_s_q
add wave -position insertpoint -expand -group R_PATH sim:/tb_top/u_dut/rem_c_q
add wave -position insertpoint -expand -group R_PATH sim:/tb_top/u_dut/nxt_rem_s[0]
add wave -position insertpoint -expand -group R_PATH sim:/tb_top/u_dut/nxt_rem_c[0]
add wave -position insertpoint -expand -group R_PATH sim:/tb_top/u_dut/nxt_rem_s[1]
add wave -position insertpoint -expand -group R_PATH sim:/tb_top/u_dut/nxt_rem_c[1]
add wave -position insertpoint -expand -group R_PATH sim:/tb_top/u_dut/nxt_rem_r_aligned_s[0]
add wave -position insertpoint -expand -group R_PATH sim:/tb_top/u_dut/nxt_rem_r_aligned_c[0]
add wave -position insertpoint -expand -group R_PATH sim:/tb_top/u_dut/nxt_rem_r_aligned_s[1]
add wave -position insertpoint -expand -group R_PATH sim:/tb_top/u_dut/nxt_rem_r_aligned_c[1]

add wave -position insertpoint -expand -group Q_PATH -radix binary sim:/tb_top/u_dut/quo_dig_1st
add wave -position insertpoint -expand -group Q_PATH -radix binary sim:/tb_top/u_dut/rem_trunc_1_4_for_1st_quo
add wave -position insertpoint -expand -group Q_PATH -radix binary sim:/tb_top/u_dut/m_pos_1_for_1st_quo
add wave -position insertpoint -expand -group Q_PATH -radix binary sim:/tb_top/u_dut/m_pos_2_for_1st_quo
add wave -position insertpoint -expand -group Q_PATH -radix binary sim:/tb_top/u_dut/prev_quo_dig_q
add wave -position insertpoint -expand -group Q_PATH -radix binary sim:/tb_top/u_dut/nxt_quo_dig[0]
add wave -position insertpoint -expand -group Q_PATH sim:/tb_top/u_dut/nxt_quo_iter[0]
add wave -position insertpoint -expand -group Q_PATH sim:/tb_top/u_dut/nxt_quo_m1_iter[0]
add wave -position insertpoint -expand -group Q_PATH -radix binary sim:/tb_top/u_dut/nxt_quo_dig[1]
add wave -position insertpoint -expand -group Q_PATH sim:/tb_top/u_dut/nxt_quo_iter[1]
add wave -position insertpoint -expand -group Q_PATH sim:/tb_top/u_dut/nxt_quo_m1_iter[1]

# add wave -position insertpoint -expand -group SRT_D sim:/tb_top/u_dut/u_r16_block/D_ext
# add wave -position insertpoint -expand -group SRT_D sim:/tb_top/u_dut/u_r16_block/D_mul_4
# add wave -position insertpoint -expand -group SRT_D sim:/tb_top/u_dut/u_r16_block/D_mul_8
# add wave -position insertpoint -expand -group SRT_D sim:/tb_top/u_dut/u_r16_block/D_mul_neg_4
# add wave -position insertpoint -expand -group SRT_D sim:/tb_top/u_dut/u_r16_block/D_mul_neg_8

add wave -position insertpoint -expand -group SRT_S0 sim:/tb_top/u_dut/u_r16_block/D_to_csa[0]
add wave -position insertpoint -expand -group SRT_S0 -radix binary sim:/tb_top/u_dut/u_r16_block/u_r4_qds_s0/rem_s_trunc_2_5
add wave -position insertpoint -expand -group SRT_S0 -radix binary sim:/tb_top/u_dut/u_r16_block/u_r4_qds_s0/rem_s_trunc_3_4
add wave -position insertpoint -expand -group SRT_S0 -radix binary sim:/tb_top/u_dut/u_r16_block/u_r4_qds_s0/rem_c_trunc_2_5
add wave -position insertpoint -expand -group SRT_S0 -radix binary sim:/tb_top/u_dut/u_r16_block/u_r4_qds_s0/rem_c_trunc_3_4
add wave -position insertpoint -expand -group SRT_S0 -radix binary sim:/tb_top/u_dut/u_r16_block/u_r4_qds_s0/D_trunc_2_5
add wave -position insertpoint -expand -group SRT_S0 -radix binary sim:/tb_top/u_dut/u_r16_block/u_r4_qds_s0/D_trunc_3_4
add wave -position insertpoint -expand -group SRT_S0 -radix binary sim:/tb_top/u_dut/u_r16_block/u_r4_qds_s0/qds_sign

add wave -position insertpoint -expand -group SRT_S0 sim:/tb_top/u_dut/u_r16_block/D_to_csa[1]
add wave -position insertpoint -expand -group SRT_S1 -radix binary sim:/tb_top/u_dut/u_r16_block/u_r4_qds_s1/rem_s_trunc_2_5
add wave -position insertpoint -expand -group SRT_S1 -radix binary sim:/tb_top/u_dut/u_r16_block/u_r4_qds_s1/rem_s_trunc_3_4
add wave -position insertpoint -expand -group SRT_S1 -radix binary sim:/tb_top/u_dut/u_r16_block/u_r4_qds_s1/rem_c_trunc_2_5
add wave -position insertpoint -expand -group SRT_S1 -radix binary sim:/tb_top/u_dut/u_r16_block/u_r4_qds_s1/rem_c_trunc_3_4
add wave -position insertpoint -expand -group SRT_S1 -radix binary sim:/tb_top/u_dut/u_r16_block/u_r4_qds_s1/D_mul_4_trunc_2_5_i
add wave -position insertpoint -expand -group SRT_S1 -radix binary sim:/tb_top/u_dut/u_r16_block/u_r4_qds_s1/D_mul_4_trunc_3_4_i
add wave -position insertpoint -expand -group SRT_S1 -radix binary sim:/tb_top/u_dut/u_r16_block/u_r4_qds_s1/D_mul_8_trunc_2_5_i
add wave -position insertpoint -expand -group SRT_S1 -radix binary sim:/tb_top/u_dut/u_r16_block/u_r4_qds_s1/D_mul_8_trunc_3_4_i
add wave -position insertpoint -expand -group SRT_S1 -radix binary sim:/tb_top/u_dut/u_r16_block/u_r4_qds_s1/D_mul_neg_4_trunc_2_5_i
add wave -position insertpoint -expand -group SRT_S1 -radix binary sim:/tb_top/u_dut/u_r16_block/u_r4_qds_s1/D_mul_neg_4_trunc_3_4_i
add wave -position insertpoint -expand -group SRT_S1 -radix binary sim:/tb_top/u_dut/u_r16_block/u_r4_qds_s1/D_mul_neg_8_trunc_2_5_i
add wave -position insertpoint -expand -group SRT_S1 -radix binary sim:/tb_top/u_dut/u_r16_block/u_r4_qds_s1/D_mul_neg_8_trunc_3_4_i
add wave -position insertpoint -expand -group SRT_S1 -radix binary sim:/tb_top/u_dut/u_r16_block/u_r4_qds_s1/qds_sign


add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/nr_rem_r_aligned
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/nr_rem_r_aligned_plus_D
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/nr_rem_r_aligned_is_not_zero
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/select_quo_m1
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/quo_sign_adjusted
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/quo_m1_sign_adjusted
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/quotient_o
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/remainder_o

