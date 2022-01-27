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
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/dut_fpsqrt_frac_res

add wave -position insertpoint -expand -group PRE -radix binary sim:/tb_top/u_dut/rt_1th
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/rt_iter_init
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/rt_m1_iter_init
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/f_r_s_iter_init_pre
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/f_r_s_iter_init
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/f_r_c_iter_init
add wave -position insertpoint -expand -group PRE -radix binary sim:/tb_top/u_dut/m_neg_1_iter_init
add wave -position insertpoint -expand -group PRE -radix binary sim:/tb_top/u_dut/m_neg_0_iter_init
add wave -position insertpoint -expand -group PRE -radix binary sim:/tb_top/u_dut/m_pos_1_iter_init
add wave -position insertpoint -expand -group PRE -radix binary sim:/tb_top/u_dut/m_pos_2_iter_init
add wave -position insertpoint -expand -group PRE -radix binary sim:/tb_top/u_dut/m_neg_1_for_nxt_cycle_s0_qds_q
add wave -position insertpoint -expand -group PRE -radix binary sim:/tb_top/u_dut/m_neg_0_for_nxt_cycle_s0_qds_q
add wave -position insertpoint -expand -group PRE -radix binary sim:/tb_top/u_dut/m_pos_1_for_nxt_cycle_s0_qds_q
add wave -position insertpoint -expand -group PRE -radix binary sim:/tb_top/u_dut/m_pos_2_for_nxt_cycle_s0_qds_q

add wave -position insertpoint -expand -group REM_PATH sim:/tb_top/u_dut/f_r_s_q
add wave -position insertpoint -expand -group REM_PATH sim:/tb_top/u_dut/f_r_c_q
add wave -position insertpoint -expand -group REM_PATH -radix binary sim:/tb_top/u_dut/nr_f_r_7b_for_nxt_cycle_s0_qds_q
add wave -position insertpoint -expand -group REM_PATH -radix binary sim:/tb_top/u_dut/nr_f_r_9b_for_nxt_cycle_s1_qds_q
add wave -position insertpoint -expand -group REM_PATH -radix binary sim:/tb_top/u_dut/adder_8b_for_s0_qds
add wave -position insertpoint -expand -group REM_PATH -radix binary sim:/tb_top/u_dut/adder_8b_for_s1_qds
add wave -position insertpoint -expand -group REM_PATH -radix binary sim:/tb_top/u_dut/adder_7b_res_for_s1_qds

add wave -position insertpoint -expand -group ROOT_PATH sim:/tb_top/u_dut/rt_q
add wave -position insertpoint -expand -group ROOT_PATH sim:/tb_top/u_dut/rt_m1_q
add wave -position insertpoint -expand -group ROOT_PATH sim:/tb_top/u_dut/nxt_rt[0]
add wave -position insertpoint -expand -group ROOT_PATH sim:/tb_top/u_dut/nxt_rt_m1[0]
add wave -position insertpoint -expand -group ROOT_PATH sim:/tb_top/u_dut/nxt_rt[1]
add wave -position insertpoint -expand -group ROOT_PATH sim:/tb_top/u_dut/nxt_rt_m1[1]

add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/nr_f_r
# add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/nxt_f_r[0]
# add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/nxt_f_r[1]

add wave -position insertpoint -expand -group S0_ITER -radix binary sim:/tb_top/u_dut/m_neg_1[0]
add wave -position insertpoint -expand -group S0_ITER -radix binary sim:/tb_top/u_dut/m_neg_0[0]
add wave -position insertpoint -expand -group S0_ITER -radix binary sim:/tb_top/u_dut/m_pos_1[0]
add wave -position insertpoint -expand -group S0_ITER -radix binary sim:/tb_top/u_dut/m_pos_2[0]
add wave -position insertpoint -expand -group S0_ITER -radix binary sim:/tb_top/u_dut/u_r4_qds_s0/rem_i
add wave -position insertpoint -expand -group S0_ITER -radix binary sim:/tb_top/u_dut/u_r4_qds_s0/qds_sign
add wave -position insertpoint -expand -group S0_ITER -radix binary sim:/tb_top/u_dut/nxt_rt_dig[0]
add wave -position insertpoint -expand -group S0_ITER sim:/tb_top/u_dut/mask_rt_ext[0]
add wave -position insertpoint -expand -group S0_ITER sim:/tb_top/u_dut/mask_rt_neg_2[0]
add wave -position insertpoint -expand -group S0_ITER sim:/tb_top/u_dut/mask_rt_neg_1[0]
add wave -position insertpoint -expand -group S0_ITER sim:/tb_top/u_dut/mask_rt_neg_0[0]
add wave -position insertpoint -expand -group S0_ITER sim:/tb_top/u_dut/mask_rt_pos_1[0]
add wave -position insertpoint -expand -group S0_ITER sim:/tb_top/u_dut/mask_rt_pos_2[0]
add wave -position insertpoint -expand -group S0_ITER sim:/tb_top/u_dut/mask_rt_m1_neg_2[0]
add wave -position insertpoint -expand -group S0_ITER sim:/tb_top/u_dut/mask_rt_m1_neg_1[0]
add wave -position insertpoint -expand -group S0_ITER sim:/tb_top/u_dut/mask_rt_m1_neg_0[0]
add wave -position insertpoint -expand -group S0_ITER sim:/tb_top/u_dut/mask_rt_m1_pos_1[0]
add wave -position insertpoint -expand -group S0_ITER sim:/tb_top/u_dut/mask_rt_m1_pos_2[0]
add wave -position insertpoint -expand -group S0_ITER sim:/tb_top/u_dut/mask_csa_ext[0]
add wave -position insertpoint -expand -group S0_ITER sim:/tb_top/u_dut/mask_csa_neg_2[0]
add wave -position insertpoint -expand -group S0_ITER sim:/tb_top/u_dut/mask_csa_neg_1[0]
add wave -position insertpoint -expand -group S0_ITER sim:/tb_top/u_dut/mask_csa_pos_1[0]
add wave -position insertpoint -expand -group S0_ITER sim:/tb_top/u_dut/mask_csa_pos_2[0]
add wave -position insertpoint -expand -group S0_ITER sim:/tb_top/u_dut/sqrt_csa_val_neg_2[0]
add wave -position insertpoint -expand -group S0_ITER sim:/tb_top/u_dut/sqrt_csa_val_neg_1[0]
add wave -position insertpoint -expand -group S0_ITER sim:/tb_top/u_dut/sqrt_csa_val_pos_1[0]
add wave -position insertpoint -expand -group S0_ITER sim:/tb_top/u_dut/sqrt_csa_val_pos_2[0]
add wave -position insertpoint -expand -group S0_ITER sim:/tb_top/u_dut/nxt_f_r_s[0]
add wave -position insertpoint -expand -group S0_ITER sim:/tb_top/u_dut/nxt_f_r_c[0]

add wave -position insertpoint -expand -group S1_ITER -radix binary sim:/tb_top/u_dut/m_neg_1[1]
add wave -position insertpoint -expand -group S1_ITER -radix binary sim:/tb_top/u_dut/m_neg_0[1]
add wave -position insertpoint -expand -group S1_ITER -radix binary sim:/tb_top/u_dut/m_pos_1[1]
add wave -position insertpoint -expand -group S1_ITER -radix binary sim:/tb_top/u_dut/m_pos_2[1]
add wave -position insertpoint -expand -group S1_ITER -radix binary sim:/tb_top/u_dut/u_r4_qds_s1/rem_i
add wave -position insertpoint -expand -group S1_ITER -radix binary sim:/tb_top/u_dut/u_r4_qds_s1/qds_sign
add wave -position insertpoint -expand -group S1_ITER -radix binary sim:/tb_top/u_dut/nxt_rt_dig[1]
add wave -position insertpoint -expand -group S1_ITER sim:/tb_top/u_dut/mask_rt_ext[1]
add wave -position insertpoint -expand -group S1_ITER sim:/tb_top/u_dut/mask_rt_neg_2[1]
add wave -position insertpoint -expand -group S1_ITER sim:/tb_top/u_dut/mask_rt_neg_1[1]
add wave -position insertpoint -expand -group S1_ITER sim:/tb_top/u_dut/mask_rt_neg_0[1]
add wave -position insertpoint -expand -group S1_ITER sim:/tb_top/u_dut/mask_rt_pos_1[1]
add wave -position insertpoint -expand -group S1_ITER sim:/tb_top/u_dut/mask_rt_pos_2[1]
add wave -position insertpoint -expand -group S1_ITER sim:/tb_top/u_dut/mask_rt_m1_neg_2[1]
add wave -position insertpoint -expand -group S1_ITER sim:/tb_top/u_dut/mask_rt_m1_neg_1[1]
add wave -position insertpoint -expand -group S1_ITER sim:/tb_top/u_dut/mask_rt_m1_neg_0[1]
add wave -position insertpoint -expand -group S1_ITER sim:/tb_top/u_dut/mask_rt_m1_pos_1[1]
add wave -position insertpoint -expand -group S1_ITER sim:/tb_top/u_dut/mask_rt_m1_pos_2[1]
add wave -position insertpoint -expand -group S1_ITER sim:/tb_top/u_dut/mask_csa_ext[1]
add wave -position insertpoint -expand -group S1_ITER sim:/tb_top/u_dut/mask_csa_neg_2[1]
add wave -position insertpoint -expand -group S1_ITER sim:/tb_top/u_dut/mask_csa_neg_1[1]
add wave -position insertpoint -expand -group S1_ITER sim:/tb_top/u_dut/mask_csa_pos_1[1]
add wave -position insertpoint -expand -group S1_ITER sim:/tb_top/u_dut/mask_csa_pos_2[1]
add wave -position insertpoint -expand -group S1_ITER sim:/tb_top/u_dut/sqrt_csa_val_neg_2[1]
add wave -position insertpoint -expand -group S1_ITER sim:/tb_top/u_dut/sqrt_csa_val_neg_1[1]
add wave -position insertpoint -expand -group S1_ITER sim:/tb_top/u_dut/sqrt_csa_val_pos_1[1]
add wave -position insertpoint -expand -group S1_ITER sim:/tb_top/u_dut/sqrt_csa_val_pos_2[1]
add wave -position insertpoint -expand -group S1_ITER sim:/tb_top/u_dut/nxt_f_r_s[1]
add wave -position insertpoint -expand -group S1_ITER sim:/tb_top/u_dut/nxt_f_r_c[1]





