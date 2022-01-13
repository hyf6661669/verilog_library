add wave -position insertpoint -expand -group CLK_RST sim:/tb_top/clk
add wave -position insertpoint -expand -group CLK_RST sim:/tb_top/rst_n

add wave -position insertpoint -expand -group FSM_CTRL -radix unsigned sim:/tb_top/acq_count
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/stim_end
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/dut_start_valid
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/dut_start_ready
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/dut_finish_valid
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/dut_finish_ready
add wave -position insertpoint -expand -group FSM_CTRL -radix binary sim:/tb_top/u_dut/fsm_q
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/u_dut/final_iter
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/u_dut/iter_num_q
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/u_dut/iter_num_d
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/compare_ok
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/fp_format
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/fpdiv_rm
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/fpdiv_opa
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/fpdiv_opb
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/dut_fpdiv_res
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/dut_fpdiv_fflags

add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/early_finish
add wave -position insertpoint -expand -group PRE -radix binary sim:/tb_top/u_dut/init_cycles
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/res_is_nan_q
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/res_is_inf_q
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/res_is_exact_zero_q
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/opb_is_power_of_2_q
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/op_invalid_div_q
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/divided_by_zero_q
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/res_is_denormal
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/out_exp_diff_d
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/out_exp_diff_q



add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/opa_frac_pre_shifted_f32_f16
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/opb_frac_pre_shifted_f32_f16
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/opa_l_shift_num_f32_f16
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/opb_l_shift_num_f32_f16
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/opa_frac_l_shifted_f32_f16
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/opb_frac_l_shifted_f32_f16

add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/opa_frac_pre_shifted
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/opb_frac_pre_shifted
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/opa_l_shift_num
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/opb_l_shift_num
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/opa_frac_l_shifted_s2_to_s0
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/opb_frac_l_shifted_s2_to_s0
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/opa_frac_l_shifted
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/opb_frac_l_shifted

add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/a_frac_lt_b_frac
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/a_frac_lt_b_frac_l_shifted
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/a_frac_lt_b_frac_f32_f16
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/a_frac_lt_b_frac_f32_f16_l_shifted

# Scaling Operation
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/scale_factor_idx
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/scale_factor_idx_f32_f16
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/prescaled_a_frac
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/prescaled_b_frac
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/prescaled_a_frac_f32_f16
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/prescaled_b_frac_f32_f16
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/scaled_a_frac
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/scaled_b_frac

add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/f_r_s_iter_init_pre
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/f_r_s_iter_init
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/f_r_c_iter_init
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/f_r_s_for_integer_quo
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/integer_quo_is_pos_2
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/scaled_b_frac_ext
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/scaled_b_frac_ext_mul_neg_1
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/scaled_b_frac_ext_mul_neg_2

add wave -position insertpoint -expand -group PRE -radix binary sim:/tb_top/u_dut/adder_6b_iter_init
add wave -position insertpoint -expand -group PRE -radix binary sim:/tb_top/u_dut/adder_7b_iter_init
add wave -position insertpoint -expand -group PRE -radix binary sim:/tb_top/u_dut/nr_f_r_6b_for_nxt_cycle_s0_qds_q
add wave -position insertpoint -expand -group PRE -radix binary sim:/tb_top/u_dut/nr_f_r_7b_for_nxt_cycle_s1_qds_q
add wave -position insertpoint -expand -group PRE -radix binary sim:/tb_top/u_dut/adder_6b_res_for_nxt_cycle_s0_qds
add wave -position insertpoint -expand -group PRE -radix binary sim:/tb_top/u_dut/adder_7b_res_for_nxt_cycle_s1_qds

add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/frac_divisor_d
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/frac_divisor_q
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/nxt_frac_divisor_pre_0
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/nxt_frac_divisor_pre_1
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/nxt_frac_divisor_pre_2
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/f_r_s_q
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/f_r_c_q

add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/u_r64_block/divisor_mul_neg_2
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/u_r64_block/divisor_mul_neg_1
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/u_r64_block/divisor_mul_pos_1
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/u_r64_block/divisor_mul_pos_2


add wave -position insertpoint -expand -group Scaling_Adder sim:/tb_top/u_dut/scale_adder_29b_opa_0_in[0]
add wave -position insertpoint -expand -group Scaling_Adder sim:/tb_top/u_dut/scale_adder_29b_opa_0_in[1]
add wave -position insertpoint -expand -group Scaling_Adder sim:/tb_top/u_dut/scale_adder_29b_opa_0_in[2]
add wave -position insertpoint -expand -group Scaling_Adder sim:/tb_top/u_dut/scale_adder_29b_opa_0
add wave -position insertpoint -expand -group Scaling_Adder sim:/tb_top/u_dut/scale_adder_29b_opb_0_in[0]
add wave -position insertpoint -expand -group Scaling_Adder sim:/tb_top/u_dut/scale_adder_29b_opb_0_in[1]
add wave -position insertpoint -expand -group Scaling_Adder sim:/tb_top/u_dut/scale_adder_29b_opb_0_in[2]
add wave -position insertpoint -expand -group Scaling_Adder sim:/tb_top/u_dut/scale_adder_29b_opb_0

add wave -position insertpoint -expand -group Scaling_Adder sim:/tb_top/u_dut/scale_adder_29b_opa_1_in[0]
add wave -position insertpoint -expand -group Scaling_Adder sim:/tb_top/u_dut/scale_adder_29b_opa_1_in[1]
add wave -position insertpoint -expand -group Scaling_Adder sim:/tb_top/u_dut/scale_adder_29b_opa_1_in[2]
add wave -position insertpoint -expand -group Scaling_Adder sim:/tb_top/u_dut/scale_adder_29b_opa_1
add wave -position insertpoint -expand -group Scaling_Adder sim:/tb_top/u_dut/scale_adder_29b_opb_1_in[0]
add wave -position insertpoint -expand -group Scaling_Adder sim:/tb_top/u_dut/scale_adder_29b_opb_1_in[1]
add wave -position insertpoint -expand -group Scaling_Adder sim:/tb_top/u_dut/scale_adder_29b_opb_1_in[2]
add wave -position insertpoint -expand -group Scaling_Adder sim:/tb_top/u_dut/scale_adder_29b_opb_1

add wave -position insertpoint -expand -group Scaling_Adder sim:/tb_top/u_dut/scale_adder_30b_opa_in[0]
add wave -position insertpoint -expand -group Scaling_Adder sim:/tb_top/u_dut/scale_adder_30b_opa_in[1]
add wave -position insertpoint -expand -group Scaling_Adder sim:/tb_top/u_dut/scale_adder_30b_opa_in[2]
add wave -position insertpoint -expand -group Scaling_Adder sim:/tb_top/u_dut/scale_adder_30b_opa
add wave -position insertpoint -expand -group Scaling_Adder sim:/tb_top/u_dut/scale_adder_30b_opb_in[0]
add wave -position insertpoint -expand -group Scaling_Adder sim:/tb_top/u_dut/scale_adder_30b_opb_in[1]
add wave -position insertpoint -expand -group Scaling_Adder sim:/tb_top/u_dut/scale_adder_30b_opb_in[2]
add wave -position insertpoint -expand -group Scaling_Adder sim:/tb_top/u_dut/scale_adder_30b_opb


add wave -position insertpoint -expand -group QUO_SIGNALS sim:/tb_top/u_dut/quo_iter_d
add wave -position insertpoint -expand -group QUO_SIGNALS sim:/tb_top/u_dut/quo_iter_q
add wave -position insertpoint -expand -group QUO_SIGNALS sim:/tb_top/u_dut/quo_m1_iter_d
add wave -position insertpoint -expand -group QUO_SIGNALS sim:/tb_top/u_dut/quo_m1_iter_q
add wave -position insertpoint -expand -group QUO_SIGNALS sim:/tb_top/u_dut/nxt_quo_iter_pre_0
add wave -position insertpoint -expand -group QUO_SIGNALS sim:/tb_top/u_dut/nxt_quo_iter_pre_1
add wave -position insertpoint -expand -group QUO_SIGNALS sim:/tb_top/u_dut/nxt_quo_iter_pre_2
add wave -position insertpoint -expand -group QUO_SIGNALS sim:/tb_top/u_dut/nxt_quo_m1_iter_pre_0
add wave -position insertpoint -expand -group QUO_SIGNALS sim:/tb_top/u_dut/nxt_quo_m1_iter_pre_1
add wave -position insertpoint -expand -group QUO_SIGNALS sim:/tb_top/u_dut/nxt_quo_m1_iter_post_0
add wave -position insertpoint -expand -group QUO_SIGNALS sim:/tb_top/u_dut/nxt_quo_iter[0]
add wave -position insertpoint -expand -group QUO_SIGNALS sim:/tb_top/u_dut/nxt_quo_iter[1]
add wave -position insertpoint -expand -group QUO_SIGNALS sim:/tb_top/u_dut/nxt_quo_iter[2]
add wave -position insertpoint -expand -group QUO_SIGNALS sim:/tb_top/u_dut/nxt_quo_m1_iter[0]
add wave -position insertpoint -expand -group QUO_SIGNALS sim:/tb_top/u_dut/nxt_quo_m1_iter[1]
add wave -position insertpoint -expand -group QUO_SIGNALS sim:/tb_top/u_dut/nxt_quo_m1_iter[2]


add wave -position insertpoint -expand -group SRT_S0 sim:/tb_top/u_dut/u_r64_block/nxt_nr_f_r[0]
add wave -position insertpoint -expand -group SRT_S0 sim:/tb_top/u_dut/u_r64_block/nxt_f_r_s[0]
add wave -position insertpoint -expand -group SRT_S0 sim:/tb_top/u_dut/u_r64_block/nxt_f_r_c[0]
add wave -position insertpoint -expand -group SRT_S0 -radix binary sim:/tb_top/u_dut/u_r64_block/nxt_quo_dig[0]
add wave -position insertpoint -expand -group SRT_S0 -radix binary sim:/tb_top/u_dut/u_r64_block/adder_7b_res_for_s2_qds_in_s0
add wave -position insertpoint -expand -group SRT_S0 -radix binary sim:/tb_top/u_dut/u_r64_block/u_r4_qds_s0/rem_i
add wave -position insertpoint -expand -group SRT_S0 -radix binary sim:/tb_top/u_dut/u_r64_block/u_r4_qds_s0/rem_ge_m_pos_2
add wave -position insertpoint -expand -group SRT_S0 -radix binary sim:/tb_top/u_dut/u_r64_block/u_r4_qds_s0/rem_ge_m_pos_1
add wave -position insertpoint -expand -group SRT_S0 -radix binary sim:/tb_top/u_dut/u_r64_block/u_r4_qds_s0/rem_ge_m_neg_0
add wave -position insertpoint -expand -group SRT_S0 -radix binary sim:/tb_top/u_dut/u_r64_block/u_r4_qds_s0/rem_ge_m_neg_1
add wave -position insertpoint -expand -group SRT_S0 -radix binary sim:/tb_top/u_dut/u_r64_block/u_r4_qds_s0/qds_sign

add wave -position insertpoint -expand -group SRT_S1 sim:/tb_top/u_dut/u_r64_block/nxt_nr_f_r[1]
add wave -position insertpoint -expand -group SRT_S1 sim:/tb_top/u_dut/u_r64_block/nxt_f_r_s[1]
add wave -position insertpoint -expand -group SRT_S1 sim:/tb_top/u_dut/u_r64_block/nxt_f_r_c[1]
add wave -position insertpoint -expand -group SRT_S1 -radix binary sim:/tb_top/u_dut/u_r64_block/nxt_quo_dig[1]
add wave -position insertpoint -expand -group SRT_S1 -radix binary sim:/tb_top/u_dut/u_r64_block/adder_6b_res_for_s2_qds_in_s1
add wave -position insertpoint -expand -group SRT_S1 -radix binary sim:/tb_top/u_dut/u_r64_block/g_speculative_s1_qds/u_r4_qds_s1/rem_i
add wave -position insertpoint -expand -group SRT_S1 -radix binary sim:/tb_top/u_dut/u_r64_block/g_speculative_s1_qds/u_r4_qds_s1/qds_sign

add wave -position insertpoint -expand -group SRT_S2 sim:/tb_top/u_dut/u_r64_block/nxt_nr_f_r[2]
add wave -position insertpoint -expand -group SRT_S2 sim:/tb_top/u_dut/u_r64_block/nxt_f_r_s[2]
add wave -position insertpoint -expand -group SRT_S2 sim:/tb_top/u_dut/u_r64_block/nxt_f_r_c[2]
add wave -position insertpoint -expand -group SRT_S2 -radix binary sim:/tb_top/u_dut/u_r64_block/nxt_quo_dig[2]
add wave -position insertpoint -expand -group SRT_S2 -radix binary sim:/tb_top/u_dut/u_r64_block/u_r4_qds_s2/rem_i
add wave -position insertpoint -expand -group SRT_S2 -radix binary sim:/tb_top/u_dut/u_r64_block/u_r4_qds_s2/rem_ge_m_pos_2
add wave -position insertpoint -expand -group SRT_S2 -radix binary sim:/tb_top/u_dut/u_r64_block/u_r4_qds_s2/rem_ge_m_pos_1
add wave -position insertpoint -expand -group SRT_S2 -radix binary sim:/tb_top/u_dut/u_r64_block/u_r4_qds_s2/rem_ge_m_neg_0
add wave -position insertpoint -expand -group SRT_S2 -radix binary sim:/tb_top/u_dut/u_r64_block/u_r4_qds_s2/rem_ge_m_neg_1
add wave -position insertpoint -expand -group SRT_S2 -radix binary sim:/tb_top/u_dut/u_r64_block/u_r4_qds_s2/qds_sign


add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/nr_f_r
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/f_r_xor
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/f_r_or
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/rem_is_not_zero
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/quo_pre_shift
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/quo_m1_pre_shift
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/r_shift_num
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/quo_r_shifted
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/quo_m1_r_shifted
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/quo_pre_inc
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/quo_m1_pre_inc
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/quo_inc_res
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/quo_m1_inc_res
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/guard_bit_quo
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/round_bit_quo
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/sticky_bit_quo
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/quo_need_rup
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/guard_bit_quo_m1
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/round_bit_quo_m1
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/quo_m1_need_rup
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/inexact
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/frac_rounded_post_0
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/carry_after_round
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/overflow
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/overflow_to_inf

add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/f16_out_exp_post_0
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/f16_out_frac_post_0
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/f32_out_exp_post_0
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/f32_out_frac_post_0
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/f64_out_exp_post_0
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/f64_out_frac_post_0
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/f16_out_exp_post_1
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/f16_out_frac_post_1
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/f32_out_exp_post_1
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/f32_out_frac_post_1
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/f64_out_exp_post_1
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/f64_out_frac_post_1

