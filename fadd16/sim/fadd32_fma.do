add wave -position insertpoint -expand -group CLK_RST {sim:/tb_top/clk}
add wave -position insertpoint -expand -group CLK_RST {sim:/tb_top/rst_n}

add wave -position insertpoint -radix unsigned {sim:/tb_top/acq_count}
add wave -position insertpoint {sim:/tb_top/dut_opa}
add wave -position insertpoint {sim:/tb_top/dut_opb}
add wave -position insertpoint {sim:/tb_top/dut_opc}
add wave -position insertpoint {sim:/tb_top/dut_rm}
add wave -position insertpoint {sim:/tb_top/dut_opa_q[1]}
add wave -position insertpoint {sim:/tb_top/dut_opb_q[1]}
add wave -position insertpoint {sim:/tb_top/dut_opc_q[1]}
add wave -position insertpoint {sim:/tb_top/dut_rm_q[1]}
add wave -position insertpoint {sim:/tb_top/dut_res}
add wave -position insertpoint {sim:/tb_top/dut_fflags}
add wave -position insertpoint {sim:/tb_top/compare_ok}



add wave -position insertpoint -expand -group SRC_UNPACK {sim:/tb_top/u_dut/signa}
add wave -position insertpoint -expand -group SRC_UNPACK {sim:/tb_top/u_dut/signb}
add wave -position insertpoint -expand -group SRC_UNPACK -radix unsigned {sim:/tb_top/u_dut/expa}
add wave -position insertpoint -expand -group SRC_UNPACK -radix unsigned {sim:/tb_top/u_dut/expb}
add wave -position insertpoint -expand -group SRC_UNPACK {sim:/tb_top/u_dut/siga}
add wave -position insertpoint -expand -group SRC_UNPACK {sim:/tb_top/u_dut/sigb}
add wave -position insertpoint -expand -group SRC_UNPACK {sim:/tb_top/u_dut/do_sub}
add wave -position insertpoint -expand -group SRC_UNPACK {sim:/tb_top/u_dut/opa_zero}
add wave -position insertpoint -expand -group SRC_UNPACK {sim:/tb_top/u_dut/opb_zero}
add wave -position insertpoint -expand -group SRC_UNPACK {sim:/tb_top/u_dut/opa_inf}
add wave -position insertpoint -expand -group SRC_UNPACK {sim:/tb_top/u_dut/opb_inf}
add wave -position insertpoint -expand -group SRC_UNPACK {sim:/tb_top/u_dut/opa_qnan}
add wave -position insertpoint -expand -group SRC_UNPACK {sim:/tb_top/u_dut/opa_snan}
add wave -position insertpoint -expand -group SRC_UNPACK {sim:/tb_top/u_dut/opa_nan}
add wave -position insertpoint -expand -group SRC_UNPACK {sim:/tb_top/u_dut/opb_qnan}
add wave -position insertpoint -expand -group SRC_UNPACK {sim:/tb_top/u_dut/opb_snan}
add wave -position insertpoint -expand -group SRC_UNPACK {sim:/tb_top/u_dut/opb_nan}

add wave -position insertpoint -expand -group SRC_UNPACK -radix unsigned {sim:/tb_top/u_dut/expa_sub_expb}
add wave -position insertpoint -expand -group SRC_UNPACK {sim:/tb_top/u_dut/expa_ge_expb}
add wave -position insertpoint -expand -group SRC_UNPACK {sim:/tb_top/u_dut/expb_gt_expa}
add wave -position insertpoint -expand -group SRC_UNPACK -radix unsigned {sim:/tb_top/u_dut/expb_sub_expa}
add wave -position insertpoint -expand -group SRC_UNPACK {sim:/tb_top/u_dut/expb_ge_expa}
add wave -position insertpoint -expand -group SRC_UNPACK {sim:/tb_top/u_dut/expa_gt_expb}
add wave -position insertpoint -expand -group SRC_UNPACK {sim:/tb_top/u_dut/expa_eq_expb}
add wave -position insertpoint -expand -group SRC_UNPACK {sim:/tb_top/u_dut/fracb_ge_fraca}
add wave -position insertpoint -expand -group SRC_UNPACK {sim:/tb_top/u_dut/opb_ge_opa}
add wave -position insertpoint -expand -group SRC_UNPACK {sim:/tb_top/u_dut/sign_large}
add wave -position insertpoint -expand -group SRC_UNPACK -radix unsigned {sim:/tb_top/u_dut/exp_large}
add wave -position insertpoint -expand -group SRC_UNPACK {sim:/tb_top/u_dut/exact_zero_sign}
add wave -position insertpoint -expand -group SRC_UNPACK {sim:/tb_top/u_dut/inf_sign}
add wave -position insertpoint -expand -group SRC_UNPACK {sim:/tb_top/u_dut/res_exact_zero_or_inf_sign_s1_d}
add wave -position insertpoint -expand -group SRC_UNPACK {sim:/tb_top/u_dut/res_non_special_sign_s1_d}
add wave -position insertpoint -expand -group SRC_UNPACK {sim:/tb_top/u_dut/res_nan_s1_d}
add wave -position insertpoint -expand -group SRC_UNPACK {sim:/tb_top/u_dut/invalid_operation_s1_d}
add wave -position insertpoint -expand -group SRC_UNPACK {sim:/tb_top/u_dut/res_exact_zero_s1_d}
add wave -position insertpoint -expand -group SRC_UNPACK {sim:/tb_top/u_dut/opb_overflow_s1_d}
add wave -position insertpoint -expand -group SRC_UNPACK {sim:/tb_top/u_dut/res_inf_s1_d}
add wave -position insertpoint -expand -group SRC_UNPACK {sim:/tb_top/u_dut/use_close_path}



add wave -position insertpoint -expand -group CLOSE {sim:/tb_top/u_dut/close_opa_rsh1}
add wave -position insertpoint -expand -group CLOSE {sim:/tb_top/u_dut/close_opb_rsh1}
add wave -position insertpoint -expand -group CLOSE {sim:/tb_top/u_dut/close_siga_opa_larger}
add wave -position insertpoint -expand -group CLOSE {sim:/tb_top/u_dut/close_sigb_opa_larger}
add wave -position insertpoint -expand -group CLOSE {sim:/tb_top/u_dut/close_siga_opb_larger}
add wave -position insertpoint -expand -group CLOSE {sim:/tb_top/u_dut/close_sigb_opb_larger}
add wave -position insertpoint -expand -group CLOSE {sim:/tb_top/u_dut/a_sub_b_cin}
add wave -position insertpoint -expand -group CLOSE {sim:/tb_top/u_dut/close_a_sub_b}
add wave -position insertpoint -expand -group CLOSE {sim:/tb_top/u_dut/close_b_sub_a}
add wave -position insertpoint -expand -group CLOSE {sim:/tb_top/u_dut/close_sum}
add wave -position insertpoint -expand -group CLOSE {sim:/tb_top/u_dut/expa_sub_expb_eq_1}
add wave -position insertpoint -expand -group CLOSE {sim:/tb_top/u_dut/expb_sub_expa_eq_1}
add wave -position insertpoint -expand -group CLOSE {sim:/tb_top/u_dut/close_opa_larger}
add wave -position insertpoint -expand -group CLOSE {sim:/tb_top/u_dut/close_opb_larger}
add wave -position insertpoint -expand -group CLOSE -radix unsigned {sim:/tb_top/u_dut/close_lza}
add wave -position insertpoint -expand -group CLOSE {sim:/tb_top/u_dut/close_lza_limited_by_exp}
add wave -position insertpoint -expand -group CLOSE -radix unsigned {sim:/tb_top/u_dut/close_exp}
add wave -position insertpoint -expand -group CLOSE {sim:/tb_top/u_dut/close_overflow_l_mask}
add wave -position insertpoint -expand -group CLOSE {sim:/tb_top/u_dut/close_overflow_g_mask}
add wave -position insertpoint -expand -group CLOSE {sim:/tb_top/u_dut/close_normal_l_mask}
add wave -position insertpoint -expand -group CLOSE {sim:/tb_top/u_dut/close_normal_g_mask}
add wave -position insertpoint -expand -group CLOSE {sim:/tb_top/u_dut/close_overflow_s_mask}
add wave -position insertpoint -expand -group CLOSE {sim:/tb_top/u_dut/close_normal_s_mask}
add wave -position insertpoint -expand -group CLOSE {sim:/tb_top/u_dut/close_overflow_l}
add wave -position insertpoint -expand -group CLOSE {sim:/tb_top/u_dut/close_overflow_g}
add wave -position insertpoint -expand -group CLOSE {sim:/tb_top/u_dut/close_normal_l}
add wave -position insertpoint -expand -group CLOSE {sim:/tb_top/u_dut/close_normal_g}
add wave -position insertpoint -expand -group CLOSE {sim:/tb_top/u_dut/close_overflow_s}
add wave -position insertpoint -expand -group CLOSE {sim:/tb_top/u_dut/close_normal_s}
add wave -position insertpoint -expand -group CLOSE {sim:/tb_top/u_dut/close_sum_lsh_l0}
add wave -position insertpoint -expand -group CLOSE {sim:/tb_top/u_dut/close_sum_lsh_l1}
add wave -position insertpoint -expand -group CLOSE {sim:/tb_top/u_dut/close_sum_lsh_l2}
add wave -position insertpoint -expand -group CLOSE {sim:/tb_top/u_dut/close_sum_lsh_l3}
add wave -position insertpoint -expand -group CLOSE {sim:/tb_top/u_dut/close_sum_lsh_l4}
add wave -position insertpoint -expand -group CLOSE {sim:/tb_top/u_dut/close_sum_lsh_l5}
add wave -position insertpoint -expand -group CLOSE {sim:/tb_top/u_dut/close_sum_unrounded}
add wave -position insertpoint -expand -group CLOSE {sim:/tb_top/u_dut/close_l}
add wave -position insertpoint -expand -group CLOSE {sim:/tb_top/u_dut/close_g}
add wave -position insertpoint -expand -group CLOSE {sim:/tb_top/u_dut/close_s}
add wave -position insertpoint -expand -group CLOSE {sim:/tb_top/u_dut/close_inexact}
add wave -position insertpoint -expand -group CLOSE {sim:/tb_top/u_dut/close_round_up}
add wave -position insertpoint -expand -group CLOSE {sim:/tb_top/u_dut/close_l_uf_check}
add wave -position insertpoint -expand -group CLOSE {sim:/tb_top/u_dut/close_g_uf_check}
add wave -position insertpoint -expand -group CLOSE {sim:/tb_top/u_dut/close_s_uf_check}
add wave -position insertpoint -expand -group CLOSE {sim:/tb_top/u_dut/close_round_up_uf_check}


#add wave -position insertpoint -expand -group CLOSE_LZA_OPA_LARGER {sim:/tb_top/u_dut/u_lza_opa_larger/lzc_in_rsh0}
#add wave -position insertpoint -expand -group CLOSE_LZA_OPA_LARGER {sim:/tb_top/u_dut/u_lza_opa_larger/lzc_in_rsh1}
#add wave -position insertpoint -expand -group CLOSE_LZA_OPA_LARGER {sim:/tb_top/u_dut/u_lza_opa_larger/lzc_in_temp}
#add wave -position insertpoint -expand -group CLOSE_LZA_OPA_LARGER {sim:/tb_top/u_dut/u_lza_opa_larger/lzc_in}
#add wave -position insertpoint -expand -group CLOSE_LZA_OPA_LARGER {sim:/tb_top/u_dut/u_lza_opa_larger/exp_limit}
#add wave -position insertpoint -expand -group CLOSE_LZA_OPA_LARGER {sim:/tb_top/u_dut/u_lza_opa_larger/exp_limit_mask}

#add wave -position insertpoint -expand -group CLOSE_LZA_OPB_LARGER {sim:/tb_top/u_dut/u_lza_opb_larger/lzc_in_rsh0}
#add wave -position insertpoint -expand -group CLOSE_LZA_OPB_LARGER {sim:/tb_top/u_dut/u_lza_opb_larger/lzc_in_rsh1}
#add wave -position insertpoint -expand -group CLOSE_LZA_OPB_LARGER {sim:/tb_top/u_dut/u_lza_opb_larger/lzc_in_temp}
#add wave -position insertpoint -expand -group CLOSE_LZA_OPB_LARGER {sim:/tb_top/u_dut/u_lza_opb_larger/lzc_in}
#add wave -position insertpoint -expand -group CLOSE_LZA_OPB_LARGER {sim:/tb_top/u_dut/u_lza_opb_larger/exp_limit}
#add wave -position insertpoint -expand -group CLOSE_LZA_OPB_LARGER {sim:/tb_top/u_dut/u_lza_opb_larger/exp_limit_mask}



add wave -position insertpoint -expand -group FAR -radix unsigned {sim:/tb_top/u_dut/a_rsh_num}
add wave -position insertpoint -expand -group FAR {sim:/tb_top/u_dut/cout_lsb_of_expb_sub_expa}
add wave -position insertpoint -expand -group FAR {sim:/tb_top/u_dut/siga_rsh_in}
add wave -position insertpoint -expand -group FAR {sim:/tb_top/u_dut/siga_rsh_l0}
add wave -position insertpoint -expand -group FAR {sim:/tb_top/u_dut/siga_rsh_l1}
add wave -position insertpoint -expand -group FAR {sim:/tb_top/u_dut/siga_rsh_l2}
add wave -position insertpoint -expand -group FAR {sim:/tb_top/u_dut/siga_rsh_l3}
add wave -position insertpoint -expand -group FAR {sim:/tb_top/u_dut/siga_rsh_l4}
add wave -position insertpoint -expand -group FAR {sim:/tb_top/u_dut/siga_rsh_l5}
add wave -position insertpoint -expand -group FAR -radix unsigned {sim:/tb_top/u_dut/b_rsh_num}
add wave -position insertpoint -expand -group FAR {sim:/tb_top/u_dut/cout_lsb_of_expa_sub_expb}
add wave -position insertpoint -expand -group FAR {sim:/tb_top/u_dut/sigb_rsh_in}
add wave -position insertpoint -expand -group FAR {sim:/tb_top/u_dut/sigb_rsh_l0}
add wave -position insertpoint -expand -group FAR {sim:/tb_top/u_dut/sigb_rsh_l1}
add wave -position insertpoint -expand -group FAR {sim:/tb_top/u_dut/sigb_rsh_l2}
add wave -position insertpoint -expand -group FAR {sim:/tb_top/u_dut/sigb_rsh_l3}
add wave -position insertpoint -expand -group FAR {sim:/tb_top/u_dut/sigb_rsh_l4}
add wave -position insertpoint -expand -group FAR {sim:/tb_top/u_dut/sigb_rsh_l5}
add wave -position insertpoint -expand -group FAR {sim:/tb_top/u_dut/sig_small_rsh_l6}
add wave -position insertpoint -expand -group FAR {sim:/tb_top/u_dut/rsh_num}
add wave -position insertpoint -expand -group FAR {sim:/tb_top/u_dut/sig_small_rsh_l7}
add wave -position insertpoint -expand -group FAR {sim:/tb_top/u_dut/sig_small_rsh_l8}
add wave -position insertpoint -expand -group FAR {sim:/tb_top/u_dut/far_sig_small}
add wave -position insertpoint -expand -group FAR {sim:/tb_top/u_dut/sig_large}
add wave -position insertpoint -expand -group FAR {sim:/tb_top/u_dut/far_sig_large}
add wave -position insertpoint -expand -group FAR {sim:/tb_top/u_dut/lost_bits_mask_opa_larger}
add wave -position insertpoint -expand -group FAR {sim:/tb_top/u_dut/lost_bits_mask_opb_larger}
add wave -position insertpoint -expand -group FAR {sim:/tb_top/u_dut/a_rsh_lost_bits_non_zero}
add wave -position insertpoint -expand -group FAR {sim:/tb_top/u_dut/b_rsh_lost_bits_non_zero}
add wave -position insertpoint -expand -group FAR {sim:/tb_top/u_dut/rsh_lost_bits_non_zero}
add wave -position insertpoint -expand -group FAR {sim:/tb_top/u_dut/far_cin}
add wave -position insertpoint -expand -group FAR {sim:/tb_top/u_dut/far_sum}
add wave -position insertpoint -expand -group FAR {sim:/tb_top/u_dut/far_sum_unrounded}
add wave -position insertpoint -expand -group FAR -radix unsigned {sim:/tb_top/u_dut/far_exp}
add wave -position insertpoint -expand -group FAR {sim:/tb_top/u_dut/far_sum_low_bits_sum}
add wave -position insertpoint -expand -group FAR {sim:/tb_top/u_dut/far_sum_low_bits_carry}
add wave -position insertpoint -expand -group FAR {sim:/tb_top/u_dut/far_sum_low_bits_xor}
add wave -position insertpoint -expand -group FAR {sim:/tb_top/u_dut/far_sum_low_bits_or}
add wave -position insertpoint -expand -group FAR {sim:/tb_top/u_dut/far_overflow_s}
add wave -position insertpoint -expand -group FAR {sim:/tb_top/u_dut/far_normal_s}
add wave -position insertpoint -expand -group FAR {sim:/tb_top/u_dut/far_overflow_l}
add wave -position insertpoint -expand -group FAR {sim:/tb_top/u_dut/far_overflow_g}
add wave -position insertpoint -expand -group FAR {sim:/tb_top/u_dut/far_normal_l}
add wave -position insertpoint -expand -group FAR {sim:/tb_top/u_dut/far_normal_g}
add wave -position insertpoint -expand -group FAR {sim:/tb_top/u_dut/far_overflow}
add wave -position insertpoint -expand -group FAR {sim:/tb_top/u_dut/far_l}
add wave -position insertpoint -expand -group FAR {sim:/tb_top/u_dut/far_g}
add wave -position insertpoint -expand -group FAR {sim:/tb_top/u_dut/far_s}
add wave -position insertpoint -expand -group FAR {sim:/tb_top/u_dut/far_inexact}
add wave -position insertpoint -expand -group FAR {sim:/tb_top/u_dut/far_round_up}
add wave -position insertpoint -expand -group FAR {sim:/tb_top/u_dut/far_l_uf_check}
add wave -position insertpoint -expand -group FAR {sim:/tb_top/u_dut/far_g_uf_check}
add wave -position insertpoint -expand -group FAR {sim:/tb_top/u_dut/far_s_uf_check}
add wave -position insertpoint -expand -group FAR {sim:/tb_top/u_dut/far_round_up_uf_check}

#add wave -position insertpoint -group FAR_RSH_LOST_BITS_MASK_OPA_LARGER {sim:/tb_top/u_dut/u_rsh_lost_bits_mask_opa_larger/mask_temp}
#add wave -position insertpoint -group FAR_RSH_LOST_BITS_MASK_OPA_LARGER {sim:/tb_top/u_dut/u_rsh_lost_bits_mask_opa_larger/mask_temp_rsh1}
#add wave -position insertpoint -group FAR_RSH_LOST_BITS_MASK_OPA_LARGER {sim:/tb_top/u_dut/u_rsh_lost_bits_mask_opa_larger/mask_temp_rsh2}
#add wave -position insertpoint -group FAR_RSH_LOST_BITS_MASK_OPA_LARGER -radix unsigned {sim:/tb_top/u_dut/u_rsh_lost_bits_mask_opa_larger/exp_diff_i}
#add wave -position insertpoint -group FAR_RSH_LOST_BITS_MASK_OPA_LARGER {sim:/tb_top/u_dut/u_rsh_lost_bits_mask_opa_larger/exp_zero_i}
#add wave -position insertpoint -group FAR_RSH_LOST_BITS_MASK_OPA_LARGER {sim:/tb_top/u_dut/u_rsh_lost_bits_mask_opa_larger/do_sub_i}

#add wave -position insertpoint -group FAR_RSH_LOST_BITS_MASK_OPB_LARGER {sim:/tb_top/u_dut/u_rsh_lost_bits_mask_opb_larger/mask_temp}
#add wave -position insertpoint -group FAR_RSH_LOST_BITS_MASK_OPB_LARGER {sim:/tb_top/u_dut/u_rsh_lost_bits_mask_opb_larger/mask_temp_rsh1}
#add wave -position insertpoint -group FAR_RSH_LOST_BITS_MASK_OPB_LARGER {sim:/tb_top/u_dut/u_rsh_lost_bits_mask_opb_larger/mask_temp_rsh2}
#add wave -position insertpoint -group FAR_RSH_LOST_BITS_MASK_OPB_LARGER -radix unsigned {sim:/tb_top/u_dut/u_rsh_lost_bits_mask_opb_larger/exp_diff_i}
#add wave -position insertpoint -group FAR_RSH_LOST_BITS_MASK_OPB_LARGER {sim:/tb_top/u_dut/u_rsh_lost_bits_mask_opb_larger/exp_zero_i}
#add wave -position insertpoint -group FAR_RSH_LOST_BITS_MASK_OPB_LARGER {sim:/tb_top/u_dut/u_rsh_lost_bits_mask_opb_larger/do_sub_i}



add wave -position insertpoint -expand -group ROUNDING_MODE {sim:/tb_top/u_dut/rne}
add wave -position insertpoint -expand -group ROUNDING_MODE {sim:/tb_top/u_dut/rmm}
add wave -position insertpoint -expand -group ROUNDING_MODE {sim:/tb_top/u_dut/rtz}
add wave -position insertpoint -expand -group ROUNDING_MODE {sim:/tb_top/u_dut/rup}


add wave -position insertpoint -expand -group S0_ADDER_RES {sim:/tb_top/u_dut/sum_overflow_before_rounding_s1_d}
add wave -position insertpoint -expand -group S0_ADDER_RES {sim:/tb_top/u_dut/sig_sum_unrounded_s1_d}
add wave -position insertpoint -expand -group S0_ADDER_RES {sim:/tb_top/u_dut/round_up_s1_d}
add wave -position insertpoint -expand -group S0_ADDER_RES {sim:/tb_top/u_dut/round_up_uf_check_s1_d}
add wave -position insertpoint -expand -group S0_ADDER_RES {sim:/tb_top/u_dut/l_uf_check_s1_d}
add wave -position insertpoint -expand -group S0_ADDER_RES {sim:/tb_top/u_dut/exp_s1_d}
add wave -position insertpoint -expand -group S0_ADDER_RES {sim:/tb_top/u_dut/inexact_s1_d}
add wave -position insertpoint -expand -group S0_ADDER_RES {sim:/tb_top/u_dut/fma_vld_s1_d}
add wave -position insertpoint -expand -group S0_ADDER_RES {sim:/tb_top/u_dut/rtz_s1_d}


add wave -position insertpoint -expand -group S1 {sim:/tb_top/u_dut/sig_sum_rounded_s1}
add wave -position insertpoint -expand -group S1 {sim:/tb_top/u_dut/frac_unrounded_all_1_s1}
add wave -position insertpoint -expand -group S1 {sim:/tb_top/u_dut/sum_overflow_after_rounding_s1}
add wave -position insertpoint -expand -group S1 {sim:/tb_top/u_dut/denormal_before_rounding_s1}
add wave -position insertpoint -expand -group S1 {sim:/tb_top/u_dut/exp_adjusted_s1}
add wave -position insertpoint -expand -group S1 {sim:/tb_top/u_dut/exp_plus_2_s1}
add wave -position insertpoint -expand -group S1 {sim:/tb_top/u_dut/exp_plus_1_s1}
add wave -position insertpoint -expand -group S1 {sim:/tb_top/u_dut/exp_max_s1}
add wave -position insertpoint -expand -group S1 {sim:/tb_top/u_dut/exp_max_m1_s1}
add wave -position insertpoint -expand -group S1 {sim:/tb_top/u_dut/exp_inf_s1}
add wave -position insertpoint -expand -group S1 {sim:/tb_top/u_dut/sel_overflow_res_s1}
add wave -position insertpoint -expand -group S1 -radix unsigned {sim:/tb_top/u_dut/normal_res_s1}
add wave -position insertpoint -expand -group S1 {sim:/tb_top/u_dut/normal_exp_s1}
add wave -position insertpoint -expand -group S1 {sim:/tb_top/u_dut/overflow_res_s1}
add wave -position insertpoint -expand -group S1 {sim:/tb_top/u_dut/special_res_s1}
add wave -position insertpoint -expand -group S1 {sim:/tb_top/u_dut/sel_special_res_s1}
add wave -position insertpoint -expand -group S1 {sim:/tb_top/u_dut/inexact_s1_q}












# ======================================================================================================
# FMUL Signals
# ======================================================================================================

add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/signa}
add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/signb}
add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/sign_mul}
add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/expa}
add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/expb}
add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/expa_all_1}
add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/expb_all_1}
add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/expa_zero}
add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/expb_zero}
add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/expa_adj}
add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/expb_adj}

add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/siga}
add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/sigb}
add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/opa_zero}
add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/opb_zero}
add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/opa_qnan}
add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/opb_qnan}
add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/opa_snan}
add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/opb_snan}
add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/opa_inf}
add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/opb_inf}

add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/expa_unbiased}
add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/expb_unbiased}
add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/exp_no_lsh}
add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/exp_lsh}
add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/exp_no_lsh_zero}
add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/exp_no_lsh_neg}
add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/exp_lsh_zero}
add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/exp_lsh_neg}
add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/exp_lsh_pos}
add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/do_rsh}
add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/rsh_num_f16}
add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/rsh_num_f32}
add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/rsh_num_f64}
add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/rsh_num}
add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/s_mask_f16}
add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/s_mask_f32}
add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/s_mask_f64}
add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/fma_mul_sticky_f16}
add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/fma_mul_sticky_f32}
add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/fma_mul_sticky_f64}
add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/lzc_fraca}
add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/lzc_fracb}
add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/lzc_frac}
add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/lzc_frac_m1}
add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/lsh_num}
add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/exp_mul}
add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/exp_mul_p1}
add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/exp_mul_overflow}
add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/exp_mul_inf}
add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/exp_mul_max}
add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/exp_mul_zero}
add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/sig_mul}
add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/sig_mul_f16}
add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/sig_mul_f32}
add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/sig_mul_rsh}
add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/sig_mul_lsh}
add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/rsh_overflow}
add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/lsh_overflow}
add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/lsh_denormal_to_normal}
add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/sel_overflow_exp}
add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/exp_fma}
add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/frac_fma_f16}
add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/frac_fma_f32}
add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/frac_fma_f64}
add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/res_snan}
add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/res_qnan}
add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/res_zero}
add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/res_inf}
add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/fma_intermediate_res_f16}
add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/fma_intermediate_res_f32}
add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/fma_intermediate_res_f64}
add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/fma_intermediate_res_o}
add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/fma_mul_sticky_o}
add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/fma_inputs_nan_inf_o}
add wave -position insertpoint -expand -group FMUL_FOR_FMA {sim:/tb_top/u_fmul_simulation/fma_mul_exp_gt_inf_o}



