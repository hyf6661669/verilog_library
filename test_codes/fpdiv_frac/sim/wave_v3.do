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
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/compare_ok
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/fp_format
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/fpdiv_opa_frac
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/fpdiv_opb_frac
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/dut_fpdiv_frac_res
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/ref_fpdiv_frac_res



add wave -position insertpoint -expand -group MAIN_SIGNALS sim:/tb_top/u_dut/frac_rem_sum_iter_init
add wave -position insertpoint -expand -group MAIN_SIGNALS sim:/tb_top/u_dut/frac_rem_carry_iter_init
add wave -position insertpoint -expand -group MAIN_SIGNALS sim:/tb_top/u_dut/frac_rem_sum_iter_init_pre
add wave -position insertpoint -expand -group MAIN_SIGNALS sim:/tb_top/u_dut/frac_rem_for_int_quo
add wave -position insertpoint -expand -group MAIN_SIGNALS sim:/tb_top/u_dut/int_quo_is_pos_2
add wave -position insertpoint -expand -group MAIN_SIGNALS sim:/tb_top/u_dut/scaled_D_extended
add wave -position insertpoint -expand -group MAIN_SIGNALS sim:/tb_top/u_dut/scaled_D_mul_neg_2
add wave -position insertpoint -expand -group MAIN_SIGNALS sim:/tb_top/u_dut/scaled_D_mul_neg_1

add wave -position insertpoint -expand -group MAIN_SIGNALS sim:/tb_top/u_dut/frac_rem_sum_q
add wave -position insertpoint -expand -group MAIN_SIGNALS sim:/tb_top/u_dut/frac_rem_carry_q
add wave -position insertpoint -expand -group MAIN_SIGNALS sim:/tb_top/u_dut/fp_format_q
add wave -position insertpoint -expand -group MAIN_SIGNALS -radix binary sim:/tb_top/u_dut/nr_rem_6b_for_iter_q
add wave -position insertpoint -expand -group MAIN_SIGNALS -radix binary sim:/tb_top/u_dut/nr_rem_7b_for_iter_q


add wave -position insertpoint -expand -group QUO_REG sim:/tb_top/u_dut/pos_quo_iter_q
add wave -position insertpoint -expand -group QUO_REG sim:/tb_top/u_dut/neg_quo_iter_q

add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/scaled_factor_selector
add wave -position insertpoint -expand -group PRE -radix binary sim:/tb_top/u_dut/scaled_factor
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/prescaled_X
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/prescaled_D
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/scaled_X
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/scaled_D
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/scaled_X_lt_scaled_D


add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/nr_frac_rem
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/nr_frac_rem_plus_d
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/nr_quo
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/nr_quo_m1

add wave -position insertpoint -expand -group stage_0 sim:/tb_top/u_dut/nxt_frac_rem_sum[0]
add wave -position insertpoint -expand -group stage_0 sim:/tb_top/u_dut/nxt_frac_rem_carry[0]
add wave -position insertpoint -expand -group stage_0 sim:/tb_top/u_dut/nxt_frac_rem[0]
#add wave -position insertpoint -expand -group stage_0 sim:/tb_top/u_dut/test_nxt_frac_rem_sum_s0
#add wave -position insertpoint -expand -group stage_0 sim:/tb_top/u_dut/test_nxt_frac_rem_carry_s0
#add wave -position insertpoint -expand -group stage_0 sim:/tb_top/u_dut/test_nxt_frac_rem_s0
add wave -position insertpoint -expand -group stage_0 -radix binary sim:/tb_top/u_dut/quo_dig[0]
add wave -position insertpoint -expand -group stage_0 -radix binary sim:/tb_top/u_dut/adder_7b_s0

# for QDS_V2_with_speculation

# for QDS_V2
# add wave -position insertpoint -expand -group stage_0 -radix binary sim:/tb_top/u_dut/u_r4_qds_s0/rem_i
# add wave -position insertpoint -expand -group stage_0 -radix binary sim:/tb_top/u_dut/u_r4_qds_s0/rem_ge_m_pos_2
# add wave -position insertpoint -expand -group stage_0 -radix binary sim:/tb_top/u_dut/u_r4_qds_s0/rem_ge_m_pos_1
# add wave -position insertpoint -expand -group stage_0 -radix binary sim:/tb_top/u_dut/u_r4_qds_s0/rem_ge_m_neg_0
# add wave -position insertpoint -expand -group stage_0 -radix binary sim:/tb_top/u_dut/u_r4_qds_s0/rem_ge_m_neg_1
# add wave -position insertpoint -expand -group stage_0 -radix binary sim:/tb_top/u_dut/u_r4_qds_s0/qds_sign
# add wave -position insertpoint -expand -group stage_0 -radix binary sim:/tb_top/u_dut/u_r4_qds_s0/unused_bit[3]
# add wave -position insertpoint -expand -group stage_0 -radix binary sim:/tb_top/u_dut/u_r4_qds_s0/unused_bit[2]
# add wave -position insertpoint -expand -group stage_0 -radix binary sim:/tb_top/u_dut/u_r4_qds_s0/unused_bit[1]
# add wave -position insertpoint -expand -group stage_0 -radix binary sim:/tb_top/u_dut/u_r4_qds_s0/unused_bit[0]

add wave -position insertpoint -expand -group stage_1 sim:/tb_top/u_dut/nxt_frac_rem_sum[1]
add wave -position insertpoint -expand -group stage_1 sim:/tb_top/u_dut/nxt_frac_rem_carry[1]
add wave -position insertpoint -expand -group stage_1 sim:/tb_top/u_dut/nxt_frac_rem[1]
add wave -position insertpoint -expand -group stage_1 -radix binary sim:/tb_top/u_dut/quo_dig[1]
add wave -position insertpoint -expand -group stage_1 -radix binary sim:/tb_top/u_dut/adder_7b_s1

# for QDS_V2
# add wave -position insertpoint -expand -group stage_1 -radix binary sim:/tb_top/u_dut/u_r4_qds_s1/rem_i
# add wave -position insertpoint -expand -group stage_1 -radix binary sim:/tb_top/u_dut/u_r4_qds_s1/rem_ge_m_pos_2
# add wave -position insertpoint -expand -group stage_1 -radix binary sim:/tb_top/u_dut/u_r4_qds_s1/rem_ge_m_pos_1
# add wave -position insertpoint -expand -group stage_1 -radix binary sim:/tb_top/u_dut/u_r4_qds_s1/rem_ge_m_neg_0
# add wave -position insertpoint -expand -group stage_1 -radix binary sim:/tb_top/u_dut/u_r4_qds_s1/rem_ge_m_neg_1
# add wave -position insertpoint -expand -group stage_1 -radix binary sim:/tb_top/u_dut/u_r4_qds_s1/qds_sign
# add wave -position insertpoint -expand -group stage_1 -radix binary sim:/tb_top/u_dut/u_r4_qds_s1/unused_bit[3]
# add wave -position insertpoint -expand -group stage_1 -radix binary sim:/tb_top/u_dut/u_r4_qds_s1/unused_bit[2]
# add wave -position insertpoint -expand -group stage_1 -radix binary sim:/tb_top/u_dut/u_r4_qds_s1/unused_bit[1]
# add wave -position insertpoint -expand -group stage_1 -radix binary sim:/tb_top/u_dut/u_r4_qds_s1/unused_bit[0]

add wave -position insertpoint -expand -group stage_2 sim:/tb_top/u_dut/nxt_frac_rem_sum[2]
add wave -position insertpoint -expand -group stage_2 sim:/tb_top/u_dut/nxt_frac_rem_carry[2]
add wave -position insertpoint -expand -group stage_2 sim:/tb_top/u_dut/nxt_frac_rem[2]
add wave -position insertpoint -expand -group stage_2 -radix binary sim:/tb_top/u_dut/quo_dig[2]
add wave -position insertpoint -expand -group stage_2 -radix binary sim:/tb_top/u_dut/adder_7b_s2
add wave -position insertpoint -expand -group stage_2 -radix binary sim:/tb_top/u_dut/nxt_nr_rem_6b_for_iter
add wave -position insertpoint -expand -group stage_2 -radix binary sim:/tb_top/u_dut/nxt_nr_rem_7b_for_iter

# for QDS_V2
# add wave -position insertpoint -expand -group stage_2 -radix binary sim:/tb_top/u_dut/u_r4_qds_s2/rem_i
# add wave -position insertpoint -expand -group stage_2 -radix binary sim:/tb_top/u_dut/u_r4_qds_s2/rem_ge_m_pos_2
# add wave -position insertpoint -expand -group stage_2 -radix binary sim:/tb_top/u_dut/u_r4_qds_s2/rem_ge_m_pos_1
# add wave -position insertpoint -expand -group stage_2 -radix binary sim:/tb_top/u_dut/u_r4_qds_s2/rem_ge_m_neg_0
# add wave -position insertpoint -expand -group stage_2 -radix binary sim:/tb_top/u_dut/u_r4_qds_s2/rem_ge_m_neg_1
# add wave -position insertpoint -expand -group stage_2 -radix binary sim:/tb_top/u_dut/u_r4_qds_s2/qds_sign
# add wave -position insertpoint -expand -group stage_2 -radix binary sim:/tb_top/u_dut/u_r4_qds_s2/unused_bit[3]
# add wave -position insertpoint -expand -group stage_2 -radix binary sim:/tb_top/u_dut/u_r4_qds_s2/unused_bit[2]
# add wave -position insertpoint -expand -group stage_2 -radix binary sim:/tb_top/u_dut/u_r4_qds_s2/unused_bit[1]
# add wave -position insertpoint -expand -group stage_2 -radix binary sim:/tb_top/u_dut/u_r4_qds_s2/unused_bit[0]





