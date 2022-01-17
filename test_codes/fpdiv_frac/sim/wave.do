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
add wave -position insertpoint -expand -group MAIN_SIGNALS sim:/tb_top/u_dut/frac_rem_sum_q
add wave -position insertpoint -expand -group MAIN_SIGNALS sim:/tb_top/u_dut/frac_rem_carry_q
add wave -position insertpoint -expand -group MAIN_SIGNALS sim:/tb_top/u_dut/fp_format_q

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
add wave -position insertpoint -expand -group stage_0 -radix binary sim:/tb_top/u_dut/adder_6b
add wave -position insertpoint -expand -group stage_0 -radix binary sim:/tb_top/u_dut/quo_dig[0]
add wave -position insertpoint -expand -group stage_0 -radix binary sim:/tb_top/u_dut/adder_9b
add wave -position insertpoint -expand -group stage_0 -radix binary sim:/tb_top/u_dut/adder_9b_carry

add wave -position insertpoint -expand -group stage_1 sim:/tb_top/u_dut/nxt_frac_rem_sum[1]
add wave -position insertpoint -expand -group stage_1 sim:/tb_top/u_dut/nxt_frac_rem_carry[1]
add wave -position insertpoint -expand -group stage_1 sim:/tb_top/u_dut/nxt_frac_rem[1]
add wave -position insertpoint -expand -group stage_1 -radix binary sim:/tb_top/u_dut/quo_dig[1]
add wave -position insertpoint -expand -group stage_1 -radix binary sim:/tb_top/u_dut/adder_7b

add wave -position insertpoint -expand -group stage_2 sim:/tb_top/u_dut/nxt_frac_rem_sum[2]
add wave -position insertpoint -expand -group stage_2 sim:/tb_top/u_dut/nxt_frac_rem_carry[2]
add wave -position insertpoint -expand -group stage_2 -radix binary sim:/tb_top/u_dut/nxt_frac_rem[2]
add wave -position insertpoint -expand -group stage_2 sim:/tb_top/u_dut/quo_dig[2]





