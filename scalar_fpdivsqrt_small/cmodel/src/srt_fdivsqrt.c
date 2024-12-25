#include "stdio.h"
#include "stdlib.h"
#include "stdint.h"
#include "time.h"

#include "platform.h"
#include "internals.h"
#include "softfloat.h"
#include "genCases.h"

#define RM_RNE 0
#define RM_RTZ 1
#define RM_RDN 2
#define RM_RUP 3
#define RM_RMM 4

#define PRINT_INFO 1

const uint16_t fp16_defaultNaN = 0x7E00;
const uint32_t fp32_defaultNaN = 0x7FC00000;
const uint64_t fp64_defaultNaN = 0x7FF8000000000000;

extern float32_t genCases_f32_a, genCases_f32_b, genCases_f32_c;
extern float64_t genCases_f64_a, genCases_f64_b, genCases_f64_c;

void srt_fdiv(uint64_t opa, uint64_t opb, uint8_t rm, uint8_t fmt, uint64_t *fdiv_res, uint8_t *fdiv_fflags);
void srt_fsqrt(uint64_t opa, uint8_t rm, uint64_t *fsqrt_res, uint8_t *fsqrt_fflags);
void fsqrt_r4_qds(
    uint8_t rem_i,
    uint8_t m_n1_i,
    uint8_t m_z0_i,
    uint8_t m_p1_i,
    uint8_t m_p2_i,
    bool *root_dig_n2_o,
    bool *root_dig_n1_o,
    bool *root_dig_z0_o,
    bool *root_dig_p1_o,
    bool *root_dig_p2_o
);
uint64_t fdiv_r4_qds(uint64_t rem_msb);
void fdiv_r16_block(
    uint64_t f_r_s_i,
    uint64_t f_r_c_i,
    uint64_t divisor_i,
    uint64_t quot_i,
    uint64_t quot_m1_i,
    uint64_t *quot_2nd_o,
    uint64_t *quot_m1_2nd_o,
    uint64_t *f_r_s_2nd_o,
    uint64_t *f_r_c_2nd_o
);
void fsqrt_r16_block(
    uint64_t f_r_s_i,
    uint64_t f_r_c_i,
    uint64_t root_i,
    uint64_t root_m1_i,
    uint16_t rem_msb_nxt_cycle_1st_srt_i,
    uint16_t rem_msb_nxt_cycle_2nd_srt_i,
    uint8_t m_n1_last_cycle_i,
    uint8_t m_z0_last_cycle_i,
    uint8_t m_p1_last_cycle_i,
    uint8_t m_p2_last_cycle_i,
    uint16_t mask_i,

    uint64_t *root_2nd_o,
    uint64_t *root_m1_2nd_o,
    uint64_t *f_r_s_2nd_o,
    uint64_t *f_r_c_2nd_o,
    
    uint16_t *rem_msb_nxt_cycle_1st_srt_o,
    uint16_t *rem_msb_nxt_cycle_2nd_srt_o,
    uint8_t *m_n1_nxt_cycle_1st_srt_o,
    uint8_t *m_z0_nxt_cycle_1st_srt_o,
    uint8_t *m_p1_nxt_cycle_1st_srt_o,
    uint8_t *m_p2_nxt_cycle_1st_srt_o
);
void fsqrt_r4_qds_constants_generator(
    bool a0_i,
    bool a2_i,
    bool a3_i,
    bool a4_i,
    uint8_t *m_n1_o,
    uint8_t *m_z0_o,
    uint8_t *m_p1_o,
    uint8_t *m_p2_o
);

bool fp16_is_nan(const uint16_t x);
bool fp32_is_nan(const uint32_t x);
bool fp64_is_nan(const uint64_t x);

int main() {
    uint64_t data_ok;
    uint64_t fflags_ok;
    uint64_t err_count;
    uint64_t dut_res;
    uint8_t dut_fflags;
    float32_t ref_res_f32;
    float64_t ref_res_f64;
    

    // ========================================
    // FDIV
    // ========================================
    // genCases_f64_a.v = 0xbc7ffe000000001f;
    // genCases_f64_b.v = 0xc3effffffffff5ff;
    // srt_fdiv(genCases_f64_a.v, genCases_f64_b.v, 3, 2, &dut_res, &dut_fflags);
    // printf("dut_res = %016llx\n", dut_res);
    // printf("\n\n\n\n\n\n\n\n");
    
    genCases_f32_a.v = 0x9a2757ab;
    genCases_f32_b.v = 0x89bad051;
    srt_fdiv(genCases_f32_a.v, genCases_f32_b.v, 0, 1, &dut_res, &dut_fflags);
    printf("dut_res = %016llx\n", dut_res);
    printf("\n\n\n\n\n\n\n\n");
    

    // ========================================
    // FSQRT
    // ========================================

    // genCases_f64_a.v = 0x6aa61fff80000000;
    // srt_fsqrt(genCases_f64_a.v, 0, &dut_res, &dut_fflags);
    // printf("dut_res = %016llx\n", dut_res);
    // printf("\n\n\n\n\n\n\n\n");

    // genCases_f64_a.v = 0x3ff358d0caeda23d;
    // srt_fsqrt(genCases_f64_a.v, 0, &dut_res, &dut_fflags);
    // printf("dut_res = %016llx\n", dut_res);
    // printf("\n\n\n\n\n\n\n\n");
    

    // srand(1);
    srand(time(NULL));

    genCases_setLevel(2);
    genCases_f32_ab_init();
    genCases_f64_ab_init();
    genCases_f64_a_init();

    err_count = 0;
    if(1) {
        // ========================================
        // FDIV
        // ========================================
        for(uint64_t i = 0; i < 0; i++) {
        // for(uint64_t i = 0; i < 99999; i++) {
            genCases_f32_ab_next();
            genCases_f64_ab_next();


            for(uint8_t rm = 0; rm <= 4; rm++) {
                
                // ========================================
                // F32
                // ========================================
                // clean fflags before every computation
                softfloat_exceptionFlags = 0;
                softfloat_roundingMode = rm;
                ref_res_f32 = f32_div(genCases_f32_a, genCases_f32_b);
                srt_fdiv(genCases_f32_a.v, genCases_f32_b.v, rm, 1, &dut_res, &dut_fflags);
                
                if(fp32_is_nan(ref_res_f32.v))
                    data_ok = ((dut_res & 0xFFFFFFFF) == fp32_defaultNaN) & ((dut_res >> 32) == 0xFFFFFFFF);
                else
                    data_ok = ((dut_res & 0xFFFFFFFF) == ref_res_f32.v) & ((dut_res >> 32) == 0xFFFFFFFF);

                // Don't check underflow
                fflags_ok = ((dut_fflags & 0b11101) == (softfloat_exceptionFlags & 0b11101));

                if((data_ok == 0) | (fflags_ok == 0)) {
                    err_count++;
                    printf("f32_wrong!!!\n");
                    printf("opa_f32 = %08llx\n", genCases_f32_a.v);
                    printf("opb_f32 = %08llx\n", genCases_f32_b.v);
                    printf("rounding_mode = %016llx\n", rm);
                    printf("dut_res = %08llx\n", dut_res);
                    printf("ref_res = %08llx\n", ref_res_f32);
                    printf("dut_fflags = %16x\n", dut_fflags);
                    printf("ref_fflags = %16x\n", softfloat_exceptionFlags);
                }
                
                // ========================================
                // F64
                // ========================================
                // clean fflags before every computation
                softfloat_exceptionFlags = 0;
                softfloat_roundingMode = rm;            
                ref_res_f64 = f64_div(genCases_f64_a, genCases_f64_b);
                srt_fdiv(genCases_f64_a.v, genCases_f64_b.v, rm, 2, &dut_res, &dut_fflags);

                if(fp64_is_nan(ref_res_f64.v))
                    data_ok = (dut_res == fp64_defaultNaN);
                else
                    data_ok = (dut_res == ref_res_f64.v);
                
                // Don't check underflow
                fflags_ok = ((dut_fflags & 0b11101) == (softfloat_exceptionFlags & 0b11101));

                if((data_ok == 0) | (fflags_ok == 0)) {
                    err_count++;
                    printf("f64_wrong!!!\n");
                    printf("opa_f64 = %016llx\n", genCases_f64_a.v);
                    printf("opb_f64 = %016llx\n", genCases_f64_b.v);
                    printf("rounding_mode = %016llx\n", rm);
                    printf("dut_res = %016llx\n", dut_res);
                    printf("ref_res = %016llx\n", ref_res_f64);
                    printf("dut_fflags = %16x\n", dut_fflags);
                    printf("ref_fflags = %16x\n", softfloat_exceptionFlags);
                }
                if(err_count >= 20)
                    break;
            }
            if(err_count >= 20)
                break;
        }
    } else {
        // ========================================
        // FSQRT
        // ========================================
        // for(uint64_t i = 0; i < 9999999009; i++) {
        for(uint64_t i = 0; i < 0; i++) {
            genCases_f64_a_next();

            for(uint8_t rm = 0; rm <= 4; rm++) {
                // clean fflags before every computation
                softfloat_exceptionFlags = 0;
                softfloat_roundingMode = rm;
                ref_res_f64 = f64_sqrt(genCases_f64_a);
                srt_fsqrt(genCases_f64_a.v, rm, &dut_res, &dut_fflags);

                if(fp64_is_nan(ref_res_f64.v))
                    data_ok = (dut_res == fp64_defaultNaN);
                else
                    data_ok = (dut_res == ref_res_f64.v);
                
                fflags_ok = ((dut_fflags & 0b11111) == (softfloat_exceptionFlags & 0b11111));

                if((data_ok == 0) | (fflags_ok == 0)) {
                    err_count++;
                    printf("FSQRT_WRONG!!!\n");
                    printf("opa = %016llx\n", genCases_f64_a.v);
                    printf("rounding_mode = %016llx\n", rm);
                    printf("dut_res = %016llx\n", dut_res);
                    printf("ref_res = %016llx\n", ref_res_f64);
                    printf("dut_fflags = %16x\n", dut_fflags);
                    printf("ref_fflags = %16x\n", softfloat_exceptionFlags);
                }

                // if(1) {
                //     printf("FSQRT_WRONG!!!\n");
                //     printf("opa = %016llx\n", genCases_f64_a.v);
                //     printf("rounding_mode = %016llx\n", rm);
                //     printf("dut_res = %016llx\n", dut_res);
                //     printf("ref_res = %016llx\n", ref_res_f64);
                //     printf("dut_fflags = %16x\n", dut_fflags);
                //     printf("ref_fflags = %16x\n", softfloat_exceptionFlags);
                // }
                
                if(err_count >= 20)
                    break;
            }

            if(err_count >= 20)
                break;

        }
    }

    return 0;
}


void srt_fdiv(uint64_t opa, uint64_t opb, uint8_t rm, uint8_t fmt, uint64_t *fdiv_res, uint8_t *fdiv_fflags) {
    bool f32_vld = (fmt == 1);
    // bool f64_vld = (fmt == 2);

    uint64_t signa = f32_vld ? signF32UI(opa) : signF64UI(opa);
    uint64_t signb = f32_vld ? signF32UI(opb) : signF64UI(opb);
    uint64_t normal_res_sign = signa ^ signb;

    uint64_t expa = f32_vld ? expF32UI(opa) : expF64UI(opa);
    uint64_t expb = f32_vld ? expF32UI(opb) : expF64UI(opb);

    bool expa_zero = (expa == 0);
    bool expb_zero = (expb == 0);
    uint64_t expa_all_1 = (expa == (f32_vld ? 0xFF : 0x7FF));
    uint64_t expb_all_1 = (expb == (f32_vld ? 0xFF : 0x7FF));

    uint64_t expa_adj = expa_zero ? 1 : expa;
    uint64_t expb_adj = expb_zero ? 1 : expb;
    uint64_t expa_plus_bias = expa_adj + (f32_vld ? 127 : 1023);
    
    uint64_t fraca = f32_vld ? (fracF32UI(opa) << 29) : fracF64UI(opa);
    uint64_t fracb = f32_vld ? (fracF32UI(opb) << 29) : fracF64UI(opb);

    bool fraca_zero = (fraca == 0);
    bool fracb_zero = (fracb == 0);
    
    bool opa_zero = expa_zero & fraca_zero;
    bool opb_zero = expb_zero & fracb_zero;

    // uint64_t opa_qnan_nan_boxing = f32_vld & ((opa >> 32) != 0xFFFFFFFF);
    // uint64_t opb_qnan_nan_boxing = f32_vld & ((opb >> 32) != 0xFFFFFFFF);
    bool opa_qnan_nan_boxing = 0;
    bool opb_qnan_nan_boxing = 0;
    bool opa_qnan = expa_all_1 & (f32_vld ? (((opa >> 22) & 1) == 1) : (((opa >> 51) & 1) == 1));
    bool opb_qnan = expb_all_1 & (f32_vld ? (((opb >> 22) & 1) == 1) : (((opb >> 51) & 1) == 1));
    bool opa_snan = expa_all_1 & ~fraca_zero & (f32_vld ? (((opa >> 22) & 1) == 0) : (((opa >> 51) & 1) == 0)) & ~opa_qnan_nan_boxing;
    bool opb_snan = expb_all_1 & ~fracb_zero & (f32_vld ? (((opb >> 22) & 1) == 0) : (((opb >> 51) & 1) == 0)) & ~opb_qnan_nan_boxing;
    bool opa_nan = opa_qnan | opa_snan;
    bool opb_nan = opb_qnan | opb_snan;

    bool opa_inf = expa_all_1 & fraca_zero;
    bool opb_inf = expb_all_1 & fracb_zero;

    bool invalid_operation = (opa_inf & opb_inf) | (opa_zero & opb_zero) | opa_snan | opb_snan;    
    
    bool res_nan = invalid_operation | opa_nan | opb_nan;
    bool res_inf = (opa_inf & ~opb_nan & ~opb_inf) | (~opa_zero & ~opa_nan & opb_zero);
    bool res_exact_zero = (opa_zero & ~opb_nan & ~opb_zero) | (~opa_inf & ~opa_nan & opb_inf);

    bool divded_by_zero = ~res_nan & ~opa_inf & opb_zero;

    uint64_t rne = (rm == RM_RNE);
    uint64_t rtz_temp = (rm == RM_RTZ);
    uint64_t rdn_temp = (rm == RM_RDN);
    uint64_t rup_temp = (rm == RM_RUP);
    uint64_t rmm = (rm == RM_RMM);
    
    uint64_t rtz = 
      ( normal_res_sign & rup_temp)
    | (~normal_res_sign & rdn_temp)
    | rtz_temp;
    uint64_t rup = 
      ( normal_res_sign & rdn_temp)
    | (~normal_res_sign & rup_temp);

    // softfloat_countLeadingZeros64(frac) = clz({12'b0, frac[51:0]})
    uint64_t fraca_lsh_num = expa_zero ? (softfloat_countLeadingZeros64(fraca) - 11) : 0;
    uint64_t fracb_lsh_num = expb_zero ? (softfloat_countLeadingZeros64(fracb) - 11) : 0;

    uint64_t fraca_lsh = (fraca << fraca_lsh_num) | UINT64_C( 0x0010000000000000 );
    uint64_t fracb_lsh = (fracb << fracb_lsh_num) | UINT64_C( 0x0010000000000000 );

    uint64_t fraca_lt_fracb = (fraca_lsh < fracb_lsh);

    int64_t exp_after_norm = expa_plus_bias - expb_adj - fraca_lsh_num + fracb_lsh_num - fraca_lt_fracb;
    bool exp_after_norm_of = (exp_after_norm >= (f32_vld ? 255 : 2047));

    // SRC SCALING
    // assign scaling_factor_idx = fracb_prescaled[51 -: 3];
    // [51:49]
    uint64_t scaling_factor_idx = (fracb_lsh >> 49) & 0x7;
    
    uint64_t fraca_prescaled_rsh_0 = fraca_lsh << 3;
    uint64_t fraca_prescaled_rsh_1 = fraca_lsh << 2;
    uint64_t fraca_prescaled_rsh_2 = fraca_lsh << 1;
    uint64_t fraca_prescaled_rsh_3 = fraca_lsh;
    
    uint64_t fracb_prescaled_rsh_0 = fracb_lsh << 3;
    uint64_t fracb_prescaled_rsh_1 = fracb_lsh << 2;
    uint64_t fracb_prescaled_rsh_2 = fracb_lsh << 1;
    uint64_t fracb_prescaled_rsh_3 = fracb_lsh;
    

    // assign fraca_scaled_csa_in_1[55:0] = 
    //   ({(56){~scaling_factor_idx[2] & (scaling_factor_idx[1] | ~scaling_factor_idx[0])}} & fraca_prescaled_rsh_1)
    // | ({(56){~scaling_factor_idx[1] & (scaling_factor_idx[2] |  scaling_factor_idx[0])}} & fraca_prescaled_rsh_2);
    // assign fraca_scaled_csa_in_2[55:0] = 
    //   ({(56){~scaling_factor_idx[2] & ~scaling_factor_idx[1]}} & fraca_prescaled_rsh_1)
    // | ({(56){((scaling_factor_idx[2] | scaling_factor_idx[1]) & ~scaling_factor_idx[0]) | (scaling_factor_idx[2] & scaling_factor_idx[1])}} & fraca_prescaled_rsh_3);

    uint64_t fraca_prescaled_in_0 = fraca_prescaled_rsh_0;
    uint64_t fraca_prescaled_in_1 = 
    ((((scaling_factor_idx >> 2) & 1) == 0) & ((((scaling_factor_idx >> 1) & 1) == 1) | (((scaling_factor_idx >> 0) & 1) == 0))) ? fraca_prescaled_rsh_1 : 
    ((((scaling_factor_idx >> 1) & 1) == 0) & ((((scaling_factor_idx >> 2) & 1) == 1) | (((scaling_factor_idx >> 0) & 1) == 1))) ? fraca_prescaled_rsh_2 : 
    0;
    uint64_t fraca_prescaled_in_2 = 
    ((((scaling_factor_idx >> 2) & 1) == 0) & (((scaling_factor_idx >> 1) & 1) == 0)) ? fraca_prescaled_rsh_1 :
    ((((((scaling_factor_idx >> 2) & 1) == 1) | (((scaling_factor_idx >> 1) & 1) == 1)) & (((scaling_factor_idx >> 0) & 1) == 0)) | ((((scaling_factor_idx >> 2) & 1) == 1) & (((scaling_factor_idx >> 1) & 1) == 1))) ? fraca_prescaled_rsh_3 :
    0;

    uint64_t fraca_scaled = fraca_prescaled_in_0 + fraca_prescaled_in_1 + fraca_prescaled_in_2;

    uint64_t fracb_prescaled_in_0 = fracb_prescaled_rsh_0;
    uint64_t fracb_prescaled_in_1 = 
    ((((scaling_factor_idx >> 2) & 1) == 0) & ((((scaling_factor_idx >> 1) & 1) == 1) | (((scaling_factor_idx >> 0) & 1) == 0))) ? fracb_prescaled_rsh_1 : 
    ((((scaling_factor_idx >> 1) & 1) == 0) & ((((scaling_factor_idx >> 2) & 1) == 1) | (((scaling_factor_idx >> 0) & 1) == 1))) ? fracb_prescaled_rsh_2 : 
    0;
    uint64_t fracb_prescaled_in_2 = 
    ((((scaling_factor_idx >> 2) & 1) == 0) & (((scaling_factor_idx >> 1) & 1) == 0)) ? fracb_prescaled_rsh_1 :
    ((((((scaling_factor_idx >> 2) & 1) == 1) | (((scaling_factor_idx >> 1) & 1) == 1)) & (((scaling_factor_idx >> 0) & 1) == 0)) | ((((scaling_factor_idx >> 2) & 1) == 1) & (((scaling_factor_idx >> 1) & 1) == 1))) ? fracb_prescaled_rsh_3 :
    0;

    uint64_t fracb_scaled = fracb_prescaled_in_0 + fracb_prescaled_in_1 + fracb_prescaled_in_2;
    
    uint64_t f_r_s = fraca_lt_fracb ? (fraca_scaled << 1) : fraca_scaled;
    uint64_t f_r_c = 0;

    uint64_t quot_bits_needed_res_exp_nm = f32_vld ? 25 : 54;
    int64_t quot_bits_needed_res_exp_dn_temp = (f32_vld ? 24 : 53) + exp_after_norm;
    uint64_t quot_bits_needed_res_exp_dn = (quot_bits_needed_res_exp_dn_temp < 0) ? 0 : quot_bits_needed_res_exp_dn_temp;
    uint64_t quot_bits_needed = (exp_after_norm <= 0) ? quot_bits_needed_res_exp_dn : quot_bits_needed_res_exp_nm;
    uint64_t quot_bits_discard = 
    ((quot_bits_needed & 0x3) == 3) ? 0 :
    ((quot_bits_needed & 0x3) == 2) ? 1 :
    ((quot_bits_needed & 0x3) == 1) ? 2 :
    3;
    
    uint64_t quot_bits_calculated = 3;
    uint64_t quot = 0;
    uint64_t quot_m1 = 0;
#ifdef PRINT_INFO
    printf("fraca_lsh_num = %016llx\n", fraca_lsh_num);
    printf("fracb_lsh_num = %016llx\n", fracb_lsh_num);
    printf("scaling_factor_idx = %016llx\n", scaling_factor_idx);
    printf("fraca_prescaled_in_0 = %016llx\n", fraca_prescaled_in_0);
    printf("fraca_prescaled_in_1 = %016llx\n", fraca_prescaled_in_1);
    printf("fraca_prescaled_in_2 = %016llx\n", fraca_prescaled_in_2);
    printf("fracb_prescaled_in_0 = %016llx\n", fracb_prescaled_in_0);
    printf("fracb_prescaled_in_1 = %016llx\n", fracb_prescaled_in_1);
    printf("fracb_prescaled_in_2 = %016llx\n", fracb_prescaled_in_2);
    printf("fraca_scaled = %016llx\n", fraca_scaled);
    printf("fracb_scaled = %016llx\n", fracb_scaled);
    printf("f_r_s_before_iter = %016llx\n", f_r_s);
    printf("quot_bits_needed = %016llx\n", quot_bits_needed);
    printf("quot_bits_discard = %016llx\n", quot_bits_discard);
#endif
    while(1) {
        fdiv_r16_block(
            f_r_s,
            f_r_c,
            fracb_scaled,
            quot,
            quot_m1,
            &quot,
            &quot_m1,
            &f_r_s,
            &f_r_c
        );

        if(quot_bits_calculated >= quot_bits_needed)
            break;

        quot_bits_calculated += 4;
    }

    // Rounding
    uint64_t nr_f_r = f_r_s + f_r_c;
    // REM_W = 61   

    uint64_t quot_bits_discard_not_zero = 
    (quot_bits_discard == 1) ? ((quot & 0x1) != 0) :
    (quot_bits_discard == 2) ? ((quot & 0x3) != 0) :
    (quot_bits_discard == 3) ? ((quot & 0x7) != 0) :
    0;
    // Check "nr_f_r[59:0]"
    uint64_t rem_not_zero = ((nr_f_r & 0xFFFFFFFFFFFFFFF) != 0) | quot_bits_discard_not_zero;
    uint64_t select_quot_m1 = (((nr_f_r >> 60) & 0x1) == 1);

    uint64_t quot_selected = select_quot_m1 ? quot_m1 : quot;
    uint64_t quot_before_inc = 
    (quot_bits_discard == 0) ? (quot_selected >> 0) :
    (quot_bits_discard == 1) ? (quot_selected >> 1) :
    (quot_bits_discard == 2) ? (quot_selected >> 2) :
    (quot_selected >> 3);

    uint64_t quot_inc_res = (quot_before_inc >> 1) + 1;

    // assign quot_before_round_all_1 = f32_after_pre_0_q ? (quot_before_inc[1 +: 23] == {(23){1'b1}}) : (quot_before_inc[1 +: 52] == {(52){1'b1}});
    uint64_t quot_before_round_all_1 = f32_vld ? (((quot_before_inc >> 1) & 0x7FFFFF) == 0x7FFFFF) : (((quot_before_inc >> 1) & 0xFFFFFFFFFFFFF) == 0xFFFFFFFFFFFFF);   

    uint64_t quot_l = ((quot_before_inc >> 1) & 0x1);
    uint64_t quot_g = ((quot_before_inc >> 0) & 0x1);
    uint64_t quot_s = rem_not_zero;
    uint64_t quot_need_p1 = 
      (rne & ((quot_g & quot_s) | (quot_l & quot_g)))
    | (rup & (quot_g | quot_s))
    | (rmm & quot_g);
    uint64_t quot_inexact = quot_g | quot_s;

    uint64_t quot_rounded = quot_need_p1 ? quot_inc_res : (quot_before_inc >> 1);
    uint64_t carry_after_round = quot_need_p1 & quot_before_round_all_1;
    uint64_t exp_before_round = (exp_after_norm <= 0) ? 0 : exp_after_norm;
    uint64_t exp_rounded = carry_after_round ? (exp_before_round + 1) : exp_before_round ;
    

    bool sel_overflow_res = exp_after_norm_of;
    bool sel_special_res = res_nan | res_inf | res_exact_zero;

    uint64_t normal_res_f32 = packToF32UI(normal_res_sign, exp_rounded & 0xFF, fracF32UI(quot_rounded & 0x7FFFFF));
    uint64_t normal_res_f64 = packToF64UI(normal_res_sign, exp_rounded & 0x7FF, fracF64UI(quot_rounded));

    uint64_t overflow_res_f32 = packToF32UI(normal_res_sign, rtz ? 0xFE : 0xFF, rtz ? 0x7FFFFF : 0);
    uint64_t overflow_res_f64 = packToF64UI(normal_res_sign, rtz ? 0x7FE : 0x7FF, rtz ? 0xFFFFFFFFFFFFF : 0);
    
    uint64_t special_res_f32 = packToF32UI(res_nan ? 0 : normal_res_sign, (res_nan | res_inf) ? 0xFF : 0, res_nan ? (1 << 22) : 0);
    uint64_t special_res_f64 = packToF64UI(res_nan ? 0 : normal_res_sign, (res_nan | res_inf) ? 0x7FF : 0, res_nan ? ((uint64_t)1 << 51) : 0);
    
    uint64_t special_res = f32_vld ? (special_res_f32 | 0xFFFFFFFF00000000) : special_res_f64;
    uint64_t overflow_res = f32_vld ? (overflow_res_f32 | 0xFFFFFFFF00000000) : overflow_res_f64;
    uint64_t normal_res = f32_vld ? (normal_res_f32 | 0xFFFFFFFF00000000) : normal_res_f64;

    *fdiv_res = 
    sel_special_res ? special_res :
    sel_overflow_res ? overflow_res :
    normal_res;

    // *fdiv_res = normal_res;
    
    *fdiv_fflags = 0 | (invalid_operation << 4);
    *fdiv_fflags = *fdiv_fflags | (divded_by_zero << 3);
    *fdiv_fflags = *fdiv_fflags | ((sel_overflow_res & ~sel_special_res) << 2);
    *fdiv_fflags = *fdiv_fflags | (((exp_after_norm <= 0) & quot_inexact & ~sel_special_res) << 1);
    *fdiv_fflags = *fdiv_fflags | ((quot_inexact | sel_overflow_res) & ~sel_special_res);

#ifdef PRINT_INFO
    printf("// ==================\n");    
    printf("FDIV: Rounding Step\n");
    printf("// ==================\n");
    printf("nr_f_r = %016llx\n", nr_f_r);
    printf("quot_bits_discard_not_zero = %016llx\n", quot_bits_discard_not_zero);
    printf("rem_not_zero = %016llx\n", rem_not_zero);
    printf("select_quot_m1 = %016llx\n", select_quot_m1);
    printf("quot_selected = %016llx\n", quot_selected);
    printf("quot_before_inc = %016llx\n", quot_before_inc);
    printf("quot_inc_res = %016llx\n", quot_inc_res);
    printf("quot_before_round_all_1 = %016llx\n", quot_before_round_all_1);
    printf("quot_l = %016llx\n", quot_l);
    printf("quot_g = %016llx\n", quot_g);
    printf("quot_s = %016llx\n", quot_s);
    printf("quot_inexact = %016llx\n", quot_inexact);
    printf("quot_need_p1 = %016llx\n", quot_need_p1);
    printf("rne = %016llx\n", rne);
    printf("rup = %016llx\n", rup);
    printf("rmm = %016llx\n", rmm);
    printf("quot_rounded = %016llx\n", quot_rounded);
    printf("carry_after_round = %016llx\n", carry_after_round);
    printf("exp_before_round = %016llx\n", exp_before_round);
    printf("exp_rounded = %016llx\n", exp_rounded);
    // printf("normal_res_f32 = %016llx\n", normal_res_f32);
    // printf("normal_res_f64 = %016llx\n", normal_res_f64);
    printf("normal_res = %016llx\n", normal_res);
    printf("sel_special_res = %016llx\n", sel_special_res);
    printf("sel_overflow_res = %016llx\n", sel_overflow_res);
    printf("fdiv_res = %016llx\n", *fdiv_res);
#endif


}

void srt_fsqrt(uint64_t opa, uint8_t rm, uint64_t *fsqrt_res, uint8_t *fsqrt_fflags) {

    const uint64_t SQRT_2_WITH_ROUND_BIT = 0b101101010000010011110011001100111111100111011110011001;

    bool signa = signF64UI(opa);
    bool normal_res_sign = signa;

    uint16_t expa = expF64UI(opa);

    bool expa_zero = (expa == 0);
    bool expa_all_1 = (expa == 0x7FF);

    uint16_t expa_adj = expa_zero ? 1 : expa;
    
    uint64_t fraca = fracF64UI(opa);

    bool fraca_zero = (fraca == 0);
    
    bool opa_zero = expa_zero & fraca_zero;

    bool opa_qnan_nan_boxing = 0;
    bool opa_qnan = expa_all_1 & (((opa >> 51) & 1) == 1);
    bool opa_snan = expa_all_1 & ~fraca_zero & (((opa >> 51) & 1) == 0) & ~opa_qnan_nan_boxing;
    bool opa_nan = opa_qnan | opa_snan;
    bool opa_inf = expa_all_1 & fraca_zero;

    bool invalid_operation = (signa & ~opa_zero & ~opa_qnan) | opa_snan;  
    
    bool res_nan = invalid_operation | opa_nan;
    bool res_inf = opa_inf & ~signa;
    bool res_exact_zero = opa_zero;

    bool rne = (rm == RM_RNE);
    bool rtz_temp = (rm == RM_RTZ);
    bool rdn_temp = (rm == RM_RDN);
    bool rup_temp = (rm == RM_RUP);
    bool rmm = (rm == RM_RMM);
    
    bool rtz = 
      ( normal_res_sign & rup_temp)
    | (~normal_res_sign & rdn_temp)
    | rtz_temp;
    bool rup = 
      ( normal_res_sign & rdn_temp)
    | (~normal_res_sign & rup_temp);

    uint8_t fraca_lsh_num = expa_zero ? (softfloat_countLeadingZeros64(fraca) - 11) : 0;
    uint64_t fraca_lsh = (fraca << fraca_lsh_num) | UINT64_C( 0x0010000000000000 );
    bool opa_power_of_2 = (fraca_lsh == 0x0010000000000000);
    bool res_sqrt2 = ((expa_zero == 0) & (fraca == 0x0010000000000000) & ((expa & 0x1) == 0)) | ((expa_zero == 1) & (fraca_lsh == 0x0010000000000000) & ((fraca_lsh_num & 0x1) == 1));

    // 1023 = {(10){1'b1}}
    uint16_t res_exp_nm = expa_adj + 1023;
    uint16_t res_exp_dn = expa_adj + ((0b1111 << 6) | (~fraca_lsh_num & 0x3F));
    uint16_t res_exp = (expa_zero ? res_exp_dn : res_exp_nm) >> 1;
    bool exp_odd = expa_zero ? ((fraca_lsh_num & 0x1) == 1) : ((expa & 0x1) == 0);

    // Look at the REF paper for more details.
    // even_exp, digit in (2 ^ -1) is 0: s[1] = -2, root = {0}.{1, 53'b0} , root_m1 = {0}.{01, 52'b0}
    // even_exp, digit in (2 ^ -1) is 1: s[1] = -1, root = {0}.{11, 52'b0}, root_m1 = {0}.{10, 52'b0}
    // odd_exp, digit in (2 ^ -1) is 0 : s[1] = -1, root = {0}.{11, 52'b0}, root_m1 = {0}.{10, 52'b0}
    // odd_exp, digit in (2 ^ -1) is 1 : s[1] =  0, root = {1}.{00, 52'b0}, root_m1 = {0}.{11, 52'b0}
    // F64_FRAC_W = 52 + 1 = 53
    // F64_FRAC_W - 2 = 51
    // assign root_dig_n2_1st = ({exp_odd, fraca_lsh[F64_FRAC_W - 2]} == 2'b00);
    // assign root_dig_n1_1st = ({exp_odd, fraca_lsh[F64_FRAC_W - 2]} == 2'b01) | ({exp_odd, fraca_lsh[F64_FRAC_W - 2]} == 2'b10);
    // assign root_dig_z0_1st = ({exp_odd, fraca_lsh[F64_FRAC_W - 2]} == 2'b11);
    
    bool root_dig_n2_1st = (exp_odd == 0) & (((fraca_lsh >> 51) & 0x1) == 0);
    bool root_dig_n1_1st = ((exp_odd == 0) & (((fraca_lsh >> 51) & 0x1) == 1)) | ((exp_odd == 1) & (((fraca_lsh >> 51) & 0x1) == 0));
    bool root_dig_z0_1st = ((exp_odd == 1) & (((fraca_lsh >> 51) & 0x1) == 1));

// F64_FULL_ROOT_W - 3 = 52
// assign root_before_iter = 
//   ({(F64_FULL_ROOT_W){root_dig_n2_1st}} & {3'b010, {(F64_FULL_ROOT_W - 3){1'b0}}})
// | ({(F64_FULL_ROOT_W){root_dig_n1_1st}} & {3'b011, {(F64_FULL_ROOT_W - 3){1'b0}}})
// | ({(F64_FULL_ROOT_W){root_dig_z0_1st}} & {3'b100, {(F64_FULL_ROOT_W - 3){1'b0}}});
// assign root_m1_before_iter = 
//   ({(F64_FULL_ROOT_W){root_dig_n2_1st}} & {3'b001, {(F64_FULL_ROOT_W - 3){1'b0}}})
// | ({(F64_FULL_ROOT_W){root_dig_n1_1st}} & {3'b010, {(F64_FULL_ROOT_W - 3){1'b0}}})
// | ({(F64_FULL_ROOT_W){root_dig_z0_1st}} & {3'b011, {(F64_FULL_ROOT_W - 3){1'b0}}});

// FSQRT_F64_REM_W = 56
// assign f_r_s_before_iter_pre_fsqrt[FSQRT_F64_REM_W - 1:0] = {2'b11, exp_odd_fsqrt ? {1'b1, frac_fsqrt[51:0], 1'b0} : {1'b0, 1'b1, frac_fsqrt[51:0]}};
// assign f_r_s_before_iter_fsqrt[FSQRT_F64_REM_W - 1:0] = {f_r_s_before_iter_pre_fsqrt[(FSQRT_F64_REM_W - 1) - 2:0], 2'b0};
// assign f_r_c_before_iter_fsqrt = 
//   ({(FSQRT_F64_REM_W){root_dig_n2_1st}} & {2'b11  , {(FSQRT_F64_REM_W - 2){1'b0}}})
// | ({(FSQRT_F64_REM_W){root_dig_n1_1st}} & {4'b0111, {(FSQRT_F64_REM_W - 4){1'b0}}})
// | ({(FSQRT_F64_REM_W){root_dig_z0_1st}} & {			{(FSQRT_F64_REM_W - 0){1'b0}}});

    uint64_t root_before_iter = 
    root_dig_n2_1st ? ((uint64_t)0b010 << 52) :
    root_dig_n1_1st ? ((uint64_t)0b011 << 52) :
    ((uint64_t)0b100 << 52);
    uint64_t root_m1_before_iter = 
    root_dig_n2_1st ? ((uint64_t)0b001 << 52) :
    root_dig_n1_1st ? ((uint64_t)0b010 << 52) :
    ((uint64_t)0b011 << 52);

    // uint64_t f_r_s_before_iter_pre = ((uint64_t)0b11 << 55) | ((exp_odd == 1) ? (((uint64_t)1 << 54) | (fraca_lsh << 1)) : (((uint64_t)1 << 53) | fraca_lsh));
    uint64_t f_r_s_before_iter = ((exp_odd == 1) ? (fraca_lsh << 1) : (fraca_lsh)) << 2;
    uint64_t f_r_c_before_iter = 
    root_dig_n2_1st ? ((uint64_t)0b11 << 54) : 
    root_dig_n1_1st ? ((uint64_t)0b0111 << 52) : 
    0;


// // "f_r_c_before_iter_fsqrt" would only have 4-bit non-zero value, so a 4-bit FA is enough here
// assign rem_msb_nxt_cycle_1st_srt_before_iter[7:0] = {f_r_s_before_iter_fsqrt[(FSQRT_F64_REM_W - 1) -: 4] + f_r_c_before_iter_fsqrt[(FSQRT_F64_REM_W - 1) -: 4], f_r_s_before_iter_fsqrt[(FSQRT_F64_REM_W - 1) - 4 -: 4]};
// // "f_r_c_before_iter_fsqrt * 4" would only have 2-bit non-zero value, so a 2-bit FA is enough here
// assign rem_msb_nxt_cycle_2nd_srt_before_iter[8:0] = {f_r_s_before_iter_fsqrt[(FSQRT_F64_REM_W - 1) - 2 -: 2] + f_r_c_before_iter_fsqrt[(FSQRT_F64_REM_W - 1) - 2 -: 2], f_r_s_before_iter_fsqrt[(FSQRT_F64_REM_W - 1) - 2 - 2 -: 7]};
// [(FSQRT_F64_REM_W - 1) -: 4] = [55:52]
// [(FSQRT_F64_REM_W - 1) - 4 -: 4] = [51:48]
// [(FSQRT_F64_REM_W - 1) - 2 -: 2] = [53:52]
// [(FSQRT_F64_REM_W - 1) - 2 - 2 -: 7] = [51:45]
    
    uint16_t rem_msb_nxt_cycle_1st_srt_before_iter = ((((f_r_s_before_iter >> 52) & 0xF) + ((f_r_c_before_iter >> 52) & 0xF)) << 4) | ((f_r_s_before_iter >> 48) & 0xF);
    uint16_t rem_msb_nxt_cycle_2nd_srt_before_iter = ((((f_r_s_before_iter >> 52) & 0x3) + ((f_r_c_before_iter >> 52) & 0x3)) << 7) | ((f_r_s_before_iter >> 45) & 0x7F);

// F64_FULL_ROOT_W = 55
// assign a0_before_iter = root_before_iter[F64_FULL_ROOT_W - 1];
// assign a2_before_iter = root_before_iter[F64_FULL_ROOT_W - 3];
// assign a3_before_iter = root_before_iter[F64_FULL_ROOT_W - 4];
// assign a4_before_iter = root_before_iter[F64_FULL_ROOT_W - 5];

    bool a0_before_iter = (root_before_iter >> 54) & 0x1;
    bool a2_before_iter = (root_before_iter >> 52) & 0x1;
    bool a3_before_iter = (root_before_iter >> 51) & 0x1;
    bool a4_before_iter = (root_before_iter >> 50) & 0x1;

    uint8_t m_n1_nxt_cycle_1st_srt_before_iter;
    uint8_t m_z0_nxt_cycle_1st_srt_before_iter;
    uint8_t m_p1_nxt_cycle_1st_srt_before_iter;
    uint8_t m_p2_nxt_cycle_1st_srt_before_iter;
    fsqrt_r4_qds_constants_generator(
        a0_before_iter,
        a2_before_iter,
        a3_before_iter,
        a4_before_iter,
        &m_n1_nxt_cycle_1st_srt_before_iter,
        &m_z0_nxt_cycle_1st_srt_before_iter,
        &m_p1_nxt_cycle_1st_srt_before_iter,
        &m_p2_nxt_cycle_1st_srt_before_iter
    );

#ifdef PRINT_INFO
    printf("//===========================================\n");
    printf("fsqrt: init\n");
    printf("//===========================================\n");
    
    printf("fraca_lsh_num = %016llx\n", fraca_lsh_num);
    printf("fraca_lsh = %016llx\n", fraca_lsh);
    printf("res_exp_nm = %016llx\n", res_exp_nm);
    printf("res_exp_dn = %016llx\n", res_exp_dn);
    printf("res_exp = %016llx\n", res_exp);
    printf("exp_odd = %016llx\n", exp_odd);
    printf("root_dig_n2_1st = %016llx\n", root_dig_n2_1st);
    printf("root_dig_n1_1st = %016llx\n", root_dig_n1_1st);
    printf("root_dig_z0_1st = %016llx\n", root_dig_z0_1st);
    printf("root_before_iter = %016llx\n", root_before_iter);
    printf("root_m1_before_iter = %016llx\n", root_m1_before_iter);
    printf("f_r_s_before_iter = %016llx\n", f_r_s_before_iter);
    printf("f_r_c_before_iter = %016llx\n", f_r_c_before_iter);
    printf("rem_msb_nxt_cycle_1st_srt_before_iter = %016llx\n", rem_msb_nxt_cycle_1st_srt_before_iter);
    printf("rem_msb_nxt_cycle_2nd_srt_before_iter = %016llx\n", rem_msb_nxt_cycle_2nd_srt_before_iter);
    printf("a0_before_iter = %016llx\n", a0_before_iter);
    printf("a2_before_iter = %016llx\n", a2_before_iter);
    printf("a3_before_iter = %016llx\n", a3_before_iter);
    printf("a4_before_iter = %016llx\n", a4_before_iter);
    printf("m_n1_nxt_cycle_1st_srt_before_iter = %016llx\n", m_n1_nxt_cycle_1st_srt_before_iter);
    printf("m_z0_nxt_cycle_1st_srt_before_iter = %016llx\n", m_z0_nxt_cycle_1st_srt_before_iter);
    printf("m_p1_nxt_cycle_1st_srt_before_iter = %016llx\n", m_p1_nxt_cycle_1st_srt_before_iter);
    printf("m_p2_nxt_cycle_1st_srt_before_iter = %016llx\n", m_p2_nxt_cycle_1st_srt_before_iter);
#endif

    uint64_t f_r_s_q = f_r_s_before_iter;
    uint64_t f_r_c_q = f_r_c_before_iter;
    uint64_t root_q = root_before_iter;
    uint64_t root_m1_q = root_m1_before_iter;
    // rem_msb_nxt_cycle_1st_srt_d = rem_msb_nxt_cycle_1st_srt_before_iter[7:1]
    uint16_t rem_msb_nxt_cycle_1st_srt_q = rem_msb_nxt_cycle_1st_srt_before_iter >> 1;
    uint16_t rem_msb_nxt_cycle_2nd_srt_q = rem_msb_nxt_cycle_2nd_srt_before_iter;
    uint8_t m_n1_nxt_cycle_1st_srt_q = m_n1_nxt_cycle_1st_srt_before_iter;
    uint8_t m_z0_nxt_cycle_1st_srt_q = m_z0_nxt_cycle_1st_srt_before_iter;
    uint8_t m_p1_nxt_cycle_1st_srt_q = m_p1_nxt_cycle_1st_srt_before_iter;
    uint8_t m_p2_nxt_cycle_1st_srt_q = m_p2_nxt_cycle_1st_srt_before_iter;
    uint16_t mask_q = 1 << 12;
    for(uint8_t i = 0; i <= 12; i++) {
        fsqrt_r16_block(
            f_r_s_q,
            f_r_c_q,
            root_q,
            root_m1_q,
            rem_msb_nxt_cycle_1st_srt_q,
            rem_msb_nxt_cycle_2nd_srt_q,
            m_n1_nxt_cycle_1st_srt_q,
            m_z0_nxt_cycle_1st_srt_q,
            m_p1_nxt_cycle_1st_srt_q,
            m_p2_nxt_cycle_1st_srt_q,
            mask_q,

            &root_q,
            &root_m1_q,
            &f_r_s_q,
            &f_r_c_q,
            
            &rem_msb_nxt_cycle_1st_srt_q,
            &rem_msb_nxt_cycle_2nd_srt_q,
            &m_n1_nxt_cycle_1st_srt_q,
            &m_z0_nxt_cycle_1st_srt_q,
            &m_p1_nxt_cycle_1st_srt_q,
            &m_p2_nxt_cycle_1st_srt_q
        );
        mask_q = mask_q >> 1;
    }


    uint64_t nr_f_r = f_r_s_q + f_r_c_q;
    bool rem_not_zero = ((nr_f_r & 0x7FFFFFFFFFFFFF) != 0) | res_sqrt2;
    // bool select_root_m1 = ((nr_f_r >> 55) & 0x1 == 1) & ~res_sqrt2;
    bool select_root_m1 = ((nr_f_r >> 55) & 0x1 == 1);

    uint64_t root_before_inc = res_sqrt2 ? SQRT_2_WITH_ROUND_BIT : select_root_m1 ? root_m1_q : root_q;
    bool root_before_round_all_1 = (((root_before_inc >> 1) & 0xFFFFFFFFFFFFF) == 0xFFFFFFFFFFFFF); 
    uint64_t root_inc_res = (root_before_inc >> 1) + 1;
    
    bool root_l = (root_before_inc >> 1) & 0x1;
    bool root_g = (root_before_inc >> 0) & 0x1;
    bool root_s = rem_not_zero;
    bool root_need_p1 = 
      (rne & ((root_g & root_s) | (root_l & root_g)))
    | (rup & (root_g | root_s))
    | (rmm & root_g);
    bool root_inexact = root_g | root_s;
    // bool root_inexact = select_root_m1 | root_g | root_s;

    uint64_t root_rounded = root_need_p1 ? root_inc_res : (root_before_inc >> 1);
    bool carry_after_round = root_need_p1 & root_before_round_all_1;
    uint16_t exp_rounded = res_exp + carry_after_round;
    
    bool sel_special_res = res_nan | res_inf | res_exact_zero;

    uint64_t normal_res = packToF64UI(normal_res_sign, exp_rounded & 0x7FF, fracF64UI(root_rounded));
    uint64_t special_res = packToF64UI(res_nan ? 0 : normal_res_sign, (res_nan | res_inf) ? 0x7FF : 0, res_nan ? ((uint64_t)1 << 51) : 0);

    *fsqrt_res = sel_special_res ? special_res : normal_res;

    *fsqrt_fflags = 0 | (invalid_operation << 4);
    *fsqrt_fflags = *fsqrt_fflags | (0 << 3);
    *fsqrt_fflags = *fsqrt_fflags | (0 << 2);
    *fsqrt_fflags = *fsqrt_fflags | (0 << 1);
    *fsqrt_fflags = *fsqrt_fflags | (root_inexact & ~sel_special_res);

#ifdef PRINT_INFO
    printf("//===========================================\n");
    printf("fsqrt: Rounding\n");
    printf("//===========================================\n");
    printf("nr_f_r = %016llx\n", nr_f_r);
    printf("f_r_s_q = %016llx\n", f_r_s_q);
    printf("f_r_c_q = %016llx\n", f_r_c_q);
    printf("root_q = %016llx\n", root_q);
    printf("root_m1_q = %016llx\n", root_m1_q);
    printf("select_root_m1 = %016llx\n", select_root_m1);
    printf("res_sqrt2 = %016llx\n", res_sqrt2);
    printf("root_before_inc = %016llx\n", root_before_inc);
    printf("root_l = %016llx\n", root_l);
    printf("root_g = %016llx\n", root_g);
    printf("root_s = %016llx\n", root_s);
    printf("root_need_p1 = %016llx\n", root_need_p1);
    printf("root_rounded = %016llx\n", root_rounded);
    printf("carry_after_round = %016llx\n", carry_after_round);
    printf("exp_rounded = %016llx\n", exp_rounded);
    printf("sel_special_res = %016llx\n", sel_special_res);
    printf("normal_res = %016llx\n", normal_res);
    printf("special_res = %016llx\n", special_res);
#endif

}

void fsqrt_r16_block(
    uint64_t f_r_s_i,
    uint64_t f_r_c_i,
    uint64_t root_i,
    uint64_t root_m1_i,
    uint16_t rem_msb_nxt_cycle_1st_srt_i,
    uint16_t rem_msb_nxt_cycle_2nd_srt_i,
    uint8_t m_n1_last_cycle_i,
    uint8_t m_z0_last_cycle_i,
    uint8_t m_p1_last_cycle_i,
    uint8_t m_p2_last_cycle_i,
    uint16_t mask_i,

    uint64_t *root_2nd_o,
    uint64_t *root_m1_2nd_o,
    uint64_t *f_r_s_2nd_o,
    uint64_t *f_r_c_2nd_o,
    
    uint16_t *rem_msb_nxt_cycle_1st_srt_o,
    uint16_t *rem_msb_nxt_cycle_2nd_srt_o,
    uint8_t *m_n1_nxt_cycle_1st_srt_o,
    uint8_t *m_z0_nxt_cycle_1st_srt_o,
    uint8_t *m_p1_nxt_cycle_1st_srt_o,
    uint8_t *m_p2_nxt_cycle_1st_srt_o
) {

    uint64_t csa_mask_ext_1st =     
      ((uint64_t)((mask_i >> 12) & 0x1) << 50)
    | ((uint64_t)((mask_i >> 11) & 0x1) << 46)
    | ((uint64_t)((mask_i >> 10) & 0x1) << 42)
    | ((uint64_t)((mask_i >>  9) & 0x1) << 38)
    | ((uint64_t)((mask_i >>  8) & 0x1) << 34)
    | ((uint64_t)((mask_i >>  7) & 0x1) << 30)
    | ((uint64_t)((mask_i >>  6) & 0x1) << 26)
    | ((uint64_t)((mask_i >>  5) & 0x1) << 22)
    | ((uint64_t)((mask_i >>  4) & 0x1) << 18)
    | ((uint64_t)((mask_i >>  3) & 0x1) << 14)
    | ((uint64_t)((mask_i >>  2) & 0x1) << 10)
    | ((uint64_t)((mask_i >>  1) & 0x1) <<  6)
    | ((uint64_t)((mask_i >>  0) & 0x1) <<  2);

    uint64_t csa_mask_1st_root_dig_n2_1st = (csa_mask_ext_1st << 2) | (csa_mask_ext_1st << 3);
    uint64_t csa_mask_1st_root_dig_n1_1st = csa_mask_ext_1st | (csa_mask_ext_1st << 1) | (csa_mask_ext_1st << 2);
    uint64_t csa_mask_1st_root_dig_z0_1st = 0;
    uint64_t csa_mask_1st_root_dig_p1_1st = csa_mask_ext_1st;
    uint64_t csa_mask_1st_root_dig_p2_1st = csa_mask_ext_1st << 2;

    // assign root_mask_ext_1st = csa_mask_ext_1st[F64_FULL_ROOT_W - 1:0] = csa_mask_ext_1st[54:0]
    uint64_t root_mask_ext_1st = csa_mask_ext_1st & 0x7FFFFFFFFFFFFF;
    
    uint64_t root_mask_1st_root_dig_n2_1st = root_mask_ext_1st << 1;
    uint64_t root_mask_1st_root_dig_n1_1st = root_mask_ext_1st | (root_mask_ext_1st << 1);
    uint64_t root_mask_1st_root_dig_z0_1st = 0;
    uint64_t root_mask_1st_root_dig_p1_1st = root_mask_ext_1st;
    uint64_t root_mask_1st_root_dig_p2_1st = root_mask_ext_1st << 1;
    
    uint64_t root_m1_mask_1st_root_dig_n2_1st = root_mask_ext_1st;
    uint64_t root_m1_mask_1st_root_dig_n1_1st = root_mask_ext_1st << 1;
    uint64_t root_m1_mask_1st_root_dig_z0_1st = root_mask_ext_1st | (root_mask_ext_1st << 1);
    uint64_t root_m1_mask_1st_root_dig_p1_1st = 0;
    uint64_t root_m1_mask_1st_root_dig_p2_1st = root_mask_ext_1st;
    
    uint64_t csa_mask_ext_2nd = csa_mask_ext_1st >> 2;

    uint64_t csa_mask_2nd_root_dig_n2_2nd = (csa_mask_ext_2nd << 2) | (csa_mask_ext_2nd << 3);
    uint64_t csa_mask_2nd_root_dig_n1_2nd = csa_mask_ext_2nd | (csa_mask_ext_2nd << 1) | (csa_mask_ext_2nd << 2);
    uint64_t csa_mask_2nd_root_dig_z0_2nd = 0;
    uint64_t csa_mask_2nd_root_dig_p1_2nd = csa_mask_ext_2nd;
    uint64_t csa_mask_2nd_root_dig_p2_2nd = csa_mask_ext_2nd << 2;

    uint64_t root_mask_ext_2nd = root_mask_ext_1st >> 2;

    uint64_t root_mask_2nd_root_dig_n2_2nd = root_mask_ext_2nd << 1;
    uint64_t root_mask_2nd_root_dig_n1_2nd = root_mask_ext_2nd | (root_mask_ext_2nd << 1);
    uint64_t root_mask_2nd_root_dig_z0_2nd = 0;
    uint64_t root_mask_2nd_root_dig_p1_2nd = root_mask_ext_2nd;
    uint64_t root_mask_2nd_root_dig_p2_2nd = root_mask_ext_2nd << 1;
    
    uint64_t root_m1_mask_2nd_root_dig_n2_2nd = root_mask_ext_2nd;
    uint64_t root_m1_mask_2nd_root_dig_n1_2nd = root_mask_ext_2nd << 1;
    uint64_t root_m1_mask_2nd_root_dig_z0_2nd = root_mask_ext_2nd | (root_mask_ext_2nd << 1);
    uint64_t root_m1_mask_2nd_root_dig_p1_2nd = 0;
    uint64_t root_m1_mask_2nd_root_dig_p2_2nd = root_mask_ext_2nd;


    // assign root_ext_last_cycle = {~root_i[F64_FULL_ROOT_W - 2], root_i[F64_FULL_ROOT_W - 2:0]};
    // assign root_m1_ext_last_cycle = {1'b0, 1'b1, root_m1_i[F64_FULL_ROOT_W - 3:0]};
    // uint64_t root_ext_last_cycle = (((((root_i >> 53) & 0x1) == 1) ? 0 : 1) << 54) | (root_i & 0x3FFFFFFFFFFFFF);
    // uint64_t root_m1_ext_last_cycle = ((uint64_t)1 << 53) | (root_m1_i & 0x1FFFFFFFFFFFFF);
    uint64_t root_ext_last_cycle = root_i;
    uint64_t root_m1_ext_last_cycle = root_m1_i;

    uint8_t m_n1_1st = m_n1_last_cycle_i;
    uint8_t m_z0_1st = m_z0_last_cycle_i;
    uint8_t m_p1_1st = m_p1_last_cycle_i;
    uint8_t m_p2_1st = m_p2_last_cycle_i;

    bool root_dig_n2_1st;
    bool root_dig_n1_1st;
    bool root_dig_z0_1st;
    bool root_dig_p1_1st;
    bool root_dig_p2_1st;
    fsqrt_r4_qds(
        rem_msb_nxt_cycle_1st_srt_i,
        m_n1_1st,
        m_z0_1st,
        m_p1_1st,
        m_p2_1st,
        &root_dig_n2_1st,
        &root_dig_n1_1st,
        &root_dig_z0_1st,
        &root_dig_p1_1st,
        &root_dig_p2_1st
    );

    uint64_t csa_in_1st_root_dig_n2_1st = (root_m1_ext_last_cycle << 2) | csa_mask_1st_root_dig_n2_1st;
    uint64_t csa_in_1st_root_dig_n1_1st = (root_m1_ext_last_cycle << 1) | csa_mask_1st_root_dig_n1_1st;
    uint64_t csa_in_1st_root_dig_z0_1st = 0;
    uint64_t csa_in_1st_root_dig_p1_1st = ~((root_ext_last_cycle << 1) | csa_mask_1st_root_dig_p1_1st);
    uint64_t csa_in_1st_root_dig_p2_1st = ~((root_ext_last_cycle << 2) | csa_mask_1st_root_dig_p2_1st);

    uint64_t f_r_s_1st_root_dig_n2_1st =
      (f_r_s_i << 2)
    ^ (f_r_c_i << 2)
    ^ csa_in_1st_root_dig_n2_1st;
    uint64_t f_r_c_1st_root_dig_n2_1st = (
          ((f_r_s_i << 2) & (f_r_c_i << 2))
        | ((f_r_s_i << 2) & csa_in_1st_root_dig_n2_1st)
        | ((f_r_c_i << 2) & csa_in_1st_root_dig_n2_1st)
    ) << 1;

    uint64_t f_r_s_1st_root_dig_n1_1st =
      (f_r_s_i << 2)
    ^ (f_r_c_i << 2)
    ^ csa_in_1st_root_dig_n1_1st;
    uint64_t f_r_c_1st_root_dig_n1_1st = (
          ((f_r_s_i << 2) & (f_r_c_i << 2))
        | ((f_r_s_i << 2) & csa_in_1st_root_dig_n1_1st)
        | ((f_r_c_i << 2) & csa_in_1st_root_dig_n1_1st)
    ) << 1;

    uint64_t f_r_s_1st_root_dig_z0_1st = f_r_s_i << 2;
    uint64_t f_r_c_1st_root_dig_z0_1st = f_r_c_i << 2;

    uint64_t f_r_s_1st_root_dig_p1_1st = 
      (f_r_s_i << 2)
    ^ (f_r_c_i << 2)
    ^ csa_in_1st_root_dig_p1_1st;
    uint64_t f_r_c_1st_root_dig_p1_1st = ((
          ((f_r_s_i << 2) & (f_r_c_i << 2))
        | ((f_r_s_i << 2) & csa_in_1st_root_dig_p1_1st)
        | ((f_r_c_i << 2) & csa_in_1st_root_dig_p1_1st)
    ) << 1) | 1;

    uint64_t f_r_s_1st_root_dig_p2_1st = 
      (f_r_s_i << 2)
    ^ (f_r_c_i << 2)
    ^ csa_in_1st_root_dig_p2_1st;
    uint64_t f_r_c_1st_root_dig_p2_1st = ((
          ((f_r_s_i << 2) & (f_r_c_i << 2))
        | ((f_r_s_i << 2) & csa_in_1st_root_dig_p2_1st)
        | ((f_r_c_i << 2) & csa_in_1st_root_dig_p2_1st)
    ) << 1) | 1;

    uint16_t rem_msb_2nd_root_dig_n2_1st = rem_msb_nxt_cycle_2nd_srt_i + ((csa_in_1st_root_dig_n2_1st >> 47) & 0x1FF);
    uint16_t rem_msb_2nd_root_dig_n1_1st = rem_msb_nxt_cycle_2nd_srt_i + ((csa_in_1st_root_dig_n1_1st >> 47) & 0x1FF);
    uint16_t rem_msb_2nd_root_dig_z0_1st = rem_msb_nxt_cycle_2nd_srt_i;
    uint16_t rem_msb_2nd_root_dig_p1_1st = rem_msb_nxt_cycle_2nd_srt_i + ((csa_in_1st_root_dig_p1_1st >> 47) & 0x1FF);
    uint16_t rem_msb_2nd_root_dig_p2_1st = rem_msb_nxt_cycle_2nd_srt_i + ((csa_in_1st_root_dig_p2_1st >> 47) & 0x1FF);

    uint64_t root_ext_1st_root_dig_n2_1st = root_m1_ext_last_cycle | root_mask_1st_root_dig_n2_1st;
    uint64_t root_ext_1st_root_dig_n1_1st = root_m1_ext_last_cycle | root_mask_1st_root_dig_n1_1st;
    uint64_t root_ext_1st_root_dig_z0_1st = root_ext_last_cycle;
    uint64_t root_ext_1st_root_dig_p1_1st = root_ext_last_cycle | root_mask_1st_root_dig_p1_1st;
    uint64_t root_ext_1st_root_dig_p2_1st = root_ext_last_cycle | root_mask_1st_root_dig_p2_1st;
    
    uint64_t root_m1_ext_1st_root_dig_n2_1st = root_m1_ext_last_cycle | root_m1_mask_1st_root_dig_n2_1st;
    uint64_t root_m1_ext_1st_root_dig_n1_1st = root_m1_ext_last_cycle | root_m1_mask_1st_root_dig_n1_1st;
    uint64_t root_m1_ext_1st_root_dig_z0_1st = root_m1_ext_last_cycle | root_m1_mask_1st_root_dig_z0_1st;
    uint64_t root_m1_ext_1st_root_dig_p1_1st = root_ext_last_cycle;
    uint64_t root_m1_ext_1st_root_dig_p2_1st = root_ext_last_cycle | root_m1_mask_1st_root_dig_p2_1st;
    
    bool a0_1st_root_dig_n2_1st = (root_ext_1st_root_dig_n2_1st >> 54) & 0x1;
    bool a2_1st_root_dig_n2_1st = (root_ext_1st_root_dig_n2_1st >> 52) & 0x1;
    bool a3_1st_root_dig_n2_1st = (root_ext_1st_root_dig_n2_1st >> 51) & 0x1;
    bool a4_1st_root_dig_n2_1st = (root_ext_1st_root_dig_n2_1st >> 50) & 0x1;
    
    bool a0_1st_root_dig_n1_1st = (root_ext_1st_root_dig_n1_1st >> 54) & 0x1;
    bool a2_1st_root_dig_n1_1st = (root_ext_1st_root_dig_n1_1st >> 52) & 0x1;
    bool a3_1st_root_dig_n1_1st = (root_ext_1st_root_dig_n1_1st >> 51) & 0x1;
    bool a4_1st_root_dig_n1_1st = (root_ext_1st_root_dig_n1_1st >> 50) & 0x1;
    
    bool a0_1st_root_dig_z0_1st = (root_ext_1st_root_dig_z0_1st >> 54) & 0x1;
    bool a2_1st_root_dig_z0_1st = (root_ext_1st_root_dig_z0_1st >> 52) & 0x1;
    bool a3_1st_root_dig_z0_1st = (root_ext_1st_root_dig_z0_1st >> 51) & 0x1;
    bool a4_1st_root_dig_z0_1st = (root_ext_1st_root_dig_z0_1st >> 50) & 0x1;

    bool a0_1st_root_dig_p1_1st = (root_ext_1st_root_dig_p1_1st >> 54) & 0x1;
    bool a2_1st_root_dig_p1_1st = (root_ext_1st_root_dig_p1_1st >> 52) & 0x1;
    bool a3_1st_root_dig_p1_1st = (root_ext_1st_root_dig_p1_1st >> 51) & 0x1;
    bool a4_1st_root_dig_p1_1st = (root_ext_1st_root_dig_p1_1st >> 50) & 0x1;

    bool a0_1st_root_dig_p2_1st = (root_ext_1st_root_dig_p2_1st >> 54) & 0x1;
    bool a2_1st_root_dig_p2_1st = (root_ext_1st_root_dig_p2_1st >> 52) & 0x1;
    bool a3_1st_root_dig_p2_1st = (root_ext_1st_root_dig_p2_1st >> 51) & 0x1;
    bool a4_1st_root_dig_p2_1st = (root_ext_1st_root_dig_p2_1st >> 50) & 0x1;

    uint8_t m_n1_2nd_root_dig_n2_1st;
    uint8_t m_z0_2nd_root_dig_n2_1st;
    uint8_t m_p1_2nd_root_dig_n2_1st;
    uint8_t m_p2_2nd_root_dig_n2_1st;
    fsqrt_r4_qds_constants_generator(
        a0_1st_root_dig_n2_1st,
        a2_1st_root_dig_n2_1st,
        a3_1st_root_dig_n2_1st,
        a4_1st_root_dig_n2_1st,
        &m_n1_2nd_root_dig_n2_1st,
        &m_z0_2nd_root_dig_n2_1st,
        &m_p1_2nd_root_dig_n2_1st,
        &m_p2_2nd_root_dig_n2_1st
    );

    uint8_t m_n1_2nd_root_dig_n1_1st;
    uint8_t m_z0_2nd_root_dig_n1_1st;
    uint8_t m_p1_2nd_root_dig_n1_1st;
    uint8_t m_p2_2nd_root_dig_n1_1st;
    fsqrt_r4_qds_constants_generator(
        a0_1st_root_dig_n1_1st,
        a2_1st_root_dig_n1_1st,
        a3_1st_root_dig_n1_1st,
        a4_1st_root_dig_n1_1st,
        &m_n1_2nd_root_dig_n1_1st,
        &m_z0_2nd_root_dig_n1_1st,
        &m_p1_2nd_root_dig_n1_1st,
        &m_p2_2nd_root_dig_n1_1st
    );

    uint8_t m_n1_2nd_root_dig_z0_1st;
    uint8_t m_z0_2nd_root_dig_z0_1st;
    uint8_t m_p1_2nd_root_dig_z0_1st;
    uint8_t m_p2_2nd_root_dig_z0_1st;
    fsqrt_r4_qds_constants_generator(
        a0_1st_root_dig_z0_1st,
        a2_1st_root_dig_z0_1st,
        a3_1st_root_dig_z0_1st,
        a4_1st_root_dig_z0_1st,
        &m_n1_2nd_root_dig_z0_1st,
        &m_z0_2nd_root_dig_z0_1st,
        &m_p1_2nd_root_dig_z0_1st,
        &m_p2_2nd_root_dig_z0_1st
    );

    uint8_t m_n1_2nd_root_dig_p1_1st;
    uint8_t m_z0_2nd_root_dig_p1_1st;
    uint8_t m_p1_2nd_root_dig_p1_1st;
    uint8_t m_p2_2nd_root_dig_p1_1st;
    fsqrt_r4_qds_constants_generator(
        a0_1st_root_dig_p1_1st,
        a2_1st_root_dig_p1_1st,
        a3_1st_root_dig_p1_1st,
        a4_1st_root_dig_p1_1st,
        &m_n1_2nd_root_dig_p1_1st,
        &m_z0_2nd_root_dig_p1_1st,
        &m_p1_2nd_root_dig_p1_1st,
        &m_p2_2nd_root_dig_p1_1st
    );

    uint8_t m_n1_2nd_root_dig_p2_1st;
    uint8_t m_z0_2nd_root_dig_p2_1st;
    uint8_t m_p1_2nd_root_dig_p2_1st;
    uint8_t m_p2_2nd_root_dig_p2_1st;
    fsqrt_r4_qds_constants_generator(
        a0_1st_root_dig_p2_1st,
        a2_1st_root_dig_p2_1st,
        a3_1st_root_dig_p2_1st,
        a4_1st_root_dig_p2_1st,
        &m_n1_2nd_root_dig_p2_1st,
        &m_z0_2nd_root_dig_p2_1st,
        &m_p1_2nd_root_dig_p2_1st,
        &m_p2_2nd_root_dig_p2_1st
    );

    uint64_t root_ext_1st = 
    root_dig_n2_1st ? root_ext_1st_root_dig_n2_1st : 
    root_dig_n1_1st ? root_ext_1st_root_dig_n1_1st : 
    root_dig_z0_1st ? root_ext_1st_root_dig_z0_1st : 
    root_dig_p1_1st ? root_ext_1st_root_dig_p1_1st : 
    root_ext_1st_root_dig_p2_1st;
    uint64_t root_m1_ext_1st = 
    root_dig_n2_1st ? root_m1_ext_1st_root_dig_n2_1st : 
    root_dig_n1_1st ? root_m1_ext_1st_root_dig_n1_1st : 
    root_dig_z0_1st ? root_m1_ext_1st_root_dig_z0_1st : 
    root_dig_p1_1st ? root_m1_ext_1st_root_dig_p1_1st : 
    root_m1_ext_1st_root_dig_p2_1st;
    
    uint8_t m_n1_2nd = 
    root_dig_n2_1st ? m_n1_2nd_root_dig_n2_1st :
    root_dig_n1_1st ? m_n1_2nd_root_dig_n1_1st :
    root_dig_z0_1st ? m_n1_2nd_root_dig_z0_1st :
    root_dig_p1_1st ? m_n1_2nd_root_dig_p1_1st :
    m_n1_2nd_root_dig_p2_1st;
    uint8_t m_z0_2nd = 
    root_dig_n2_1st ? m_z0_2nd_root_dig_n2_1st :
    root_dig_n1_1st ? m_z0_2nd_root_dig_n1_1st :
    root_dig_z0_1st ? m_z0_2nd_root_dig_z0_1st :
    root_dig_p1_1st ? m_z0_2nd_root_dig_p1_1st :
    m_z0_2nd_root_dig_p2_1st;
    uint8_t m_p1_2nd = 
    root_dig_n2_1st ? m_p1_2nd_root_dig_n2_1st :
    root_dig_n1_1st ? m_p1_2nd_root_dig_n1_1st :
    root_dig_z0_1st ? m_p1_2nd_root_dig_z0_1st :
    root_dig_p1_1st ? m_p1_2nd_root_dig_p1_1st :
    m_p1_2nd_root_dig_p2_1st;
    uint8_t m_p2_2nd = 
    root_dig_n2_1st ? m_p2_2nd_root_dig_n2_1st :
    root_dig_n1_1st ? m_p2_2nd_root_dig_n1_1st :
    root_dig_z0_1st ? m_p2_2nd_root_dig_z0_1st :
    root_dig_p1_1st ? m_p2_2nd_root_dig_p1_1st :
    m_p2_2nd_root_dig_p2_1st;



    bool root_dig_n2_2nd_root_dig_n2_1st;
    bool root_dig_n1_2nd_root_dig_n2_1st;
    bool root_dig_z0_2nd_root_dig_n2_1st;
    bool root_dig_p1_2nd_root_dig_n2_1st;
    bool root_dig_p2_2nd_root_dig_n2_1st;
    fsqrt_r4_qds(
        rem_msb_2nd_root_dig_n2_1st >> 2,
        m_n1_2nd_root_dig_n2_1st,
        m_z0_2nd_root_dig_n2_1st,
        m_p1_2nd_root_dig_n2_1st,
        m_p2_2nd_root_dig_n2_1st,
        &root_dig_n2_2nd_root_dig_n2_1st,
        &root_dig_n1_2nd_root_dig_n2_1st,
        &root_dig_z0_2nd_root_dig_n2_1st,
        &root_dig_p1_2nd_root_dig_n2_1st,
        &root_dig_p2_2nd_root_dig_n2_1st
    );

    bool root_dig_n2_2nd_root_dig_n1_1st;
    bool root_dig_n1_2nd_root_dig_n1_1st;
    bool root_dig_z0_2nd_root_dig_n1_1st;
    bool root_dig_p1_2nd_root_dig_n1_1st;
    bool root_dig_p2_2nd_root_dig_n1_1st;
    fsqrt_r4_qds(
        rem_msb_2nd_root_dig_n1_1st >> 2,
        m_n1_2nd_root_dig_n1_1st,
        m_z0_2nd_root_dig_n1_1st,
        m_p1_2nd_root_dig_n1_1st,
        m_p2_2nd_root_dig_n1_1st,
        &root_dig_n2_2nd_root_dig_n1_1st,
        &root_dig_n1_2nd_root_dig_n1_1st,
        &root_dig_z0_2nd_root_dig_n1_1st,
        &root_dig_p1_2nd_root_dig_n1_1st,
        &root_dig_p2_2nd_root_dig_n1_1st
    );

    bool root_dig_n2_2nd_root_dig_z0_1st;
    bool root_dig_n1_2nd_root_dig_z0_1st;
    bool root_dig_z0_2nd_root_dig_z0_1st;
    bool root_dig_p1_2nd_root_dig_z0_1st;
    bool root_dig_p2_2nd_root_dig_z0_1st;
    fsqrt_r4_qds(
        rem_msb_2nd_root_dig_z0_1st >> 2,
        m_n1_2nd_root_dig_z0_1st,
        m_z0_2nd_root_dig_z0_1st,
        m_p1_2nd_root_dig_z0_1st,
        m_p2_2nd_root_dig_z0_1st,
        &root_dig_n2_2nd_root_dig_z0_1st,
        &root_dig_n1_2nd_root_dig_z0_1st,
        &root_dig_z0_2nd_root_dig_z0_1st,
        &root_dig_p1_2nd_root_dig_z0_1st,
        &root_dig_p2_2nd_root_dig_z0_1st
    );

    bool root_dig_n2_2nd_root_dig_p1_1st;
    bool root_dig_n1_2nd_root_dig_p1_1st;
    bool root_dig_z0_2nd_root_dig_p1_1st;
    bool root_dig_p1_2nd_root_dig_p1_1st;
    bool root_dig_p2_2nd_root_dig_p1_1st;
    fsqrt_r4_qds(
        rem_msb_2nd_root_dig_p1_1st >> 2,
        m_n1_2nd_root_dig_p1_1st,
        m_z0_2nd_root_dig_p1_1st,
        m_p1_2nd_root_dig_p1_1st,
        m_p2_2nd_root_dig_p1_1st,
        &root_dig_n2_2nd_root_dig_p1_1st,
        &root_dig_n1_2nd_root_dig_p1_1st,
        &root_dig_z0_2nd_root_dig_p1_1st,
        &root_dig_p1_2nd_root_dig_p1_1st,
        &root_dig_p2_2nd_root_dig_p1_1st
    );

    bool root_dig_n2_2nd_root_dig_p2_1st;
    bool root_dig_n1_2nd_root_dig_p2_1st;
    bool root_dig_z0_2nd_root_dig_p2_1st;
    bool root_dig_p1_2nd_root_dig_p2_1st;
    bool root_dig_p2_2nd_root_dig_p2_1st;
    fsqrt_r4_qds(
        rem_msb_2nd_root_dig_p2_1st >> 2,
        m_n1_2nd_root_dig_p2_1st,
        m_z0_2nd_root_dig_p2_1st,
        m_p1_2nd_root_dig_p2_1st,
        m_p2_2nd_root_dig_p2_1st,
        &root_dig_n2_2nd_root_dig_p2_1st,
        &root_dig_n1_2nd_root_dig_p2_1st,
        &root_dig_z0_2nd_root_dig_p2_1st,
        &root_dig_p1_2nd_root_dig_p2_1st,
        &root_dig_p2_2nd_root_dig_p2_1st
    );
    
    bool root_dig_n2_2nd = 
    root_dig_n2_1st ? root_dig_n2_2nd_root_dig_n2_1st :
    root_dig_n1_1st ? root_dig_n2_2nd_root_dig_n1_1st :
    root_dig_z0_1st ? root_dig_n2_2nd_root_dig_z0_1st :
    root_dig_p1_1st ? root_dig_n2_2nd_root_dig_p1_1st :
    root_dig_n2_2nd_root_dig_p2_1st;
    
    bool root_dig_n1_2nd = 
    root_dig_n2_1st ? root_dig_n1_2nd_root_dig_n2_1st :
    root_dig_n1_1st ? root_dig_n1_2nd_root_dig_n1_1st :
    root_dig_z0_1st ? root_dig_n1_2nd_root_dig_z0_1st :
    root_dig_p1_1st ? root_dig_n1_2nd_root_dig_p1_1st :
    root_dig_n1_2nd_root_dig_p2_1st;
    
    bool root_dig_z0_2nd = 
    root_dig_n2_1st ? root_dig_z0_2nd_root_dig_n2_1st :
    root_dig_n1_1st ? root_dig_z0_2nd_root_dig_n1_1st :
    root_dig_z0_1st ? root_dig_z0_2nd_root_dig_z0_1st :
    root_dig_p1_1st ? root_dig_z0_2nd_root_dig_p1_1st :
    root_dig_z0_2nd_root_dig_p2_1st;
    
    bool root_dig_p1_2nd = 
    root_dig_n2_1st ? root_dig_p1_2nd_root_dig_n2_1st :
    root_dig_n1_1st ? root_dig_p1_2nd_root_dig_n1_1st :
    root_dig_z0_1st ? root_dig_p1_2nd_root_dig_z0_1st :
    root_dig_p1_1st ? root_dig_p1_2nd_root_dig_p1_1st :
    root_dig_p1_2nd_root_dig_p2_1st;
    
    bool root_dig_p2_2nd = 
    root_dig_n2_1st ? root_dig_p2_2nd_root_dig_n2_1st :
    root_dig_n1_1st ? root_dig_p2_2nd_root_dig_n1_1st :
    root_dig_z0_1st ? root_dig_p2_2nd_root_dig_z0_1st :
    root_dig_p1_1st ? root_dig_p2_2nd_root_dig_p1_1st :
    root_dig_p2_2nd_root_dig_p2_1st;
    
    uint64_t csa_in_2nd_root_dig_n2_2nd = (root_m1_ext_1st << 2) | csa_mask_2nd_root_dig_n2_2nd;
    uint64_t csa_in_2nd_root_dig_n1_2nd = (root_m1_ext_1st << 1) | csa_mask_2nd_root_dig_n1_2nd;
    uint64_t csa_in_2nd_root_dig_z0_2nd = 0;
    uint64_t csa_in_2nd_root_dig_p1_2nd = ~((root_ext_1st << 1) | csa_mask_2nd_root_dig_p1_2nd);
    uint64_t csa_in_2nd_root_dig_p2_2nd = ~((root_ext_1st << 2) | csa_mask_2nd_root_dig_p2_2nd);

    uint64_t f_r_s_1st = 
    root_dig_n2_1st ? f_r_s_1st_root_dig_n2_1st :
    root_dig_n1_1st ? f_r_s_1st_root_dig_n1_1st :
    root_dig_z0_1st ? f_r_s_1st_root_dig_z0_1st :
    root_dig_p1_1st ? f_r_s_1st_root_dig_p1_1st :
    f_r_s_1st_root_dig_p2_1st;
    uint64_t f_r_c_1st = 
    root_dig_n2_1st ? f_r_c_1st_root_dig_n2_1st :
    root_dig_n1_1st ? f_r_c_1st_root_dig_n1_1st :
    root_dig_z0_1st ? f_r_c_1st_root_dig_z0_1st :
    root_dig_p1_1st ? f_r_c_1st_root_dig_p1_1st :
    f_r_c_1st_root_dig_p2_1st;


    uint64_t f_r_s_2nd_root_dig_n2_2nd =
      (f_r_s_1st << 2)
    ^ (f_r_c_1st << 2)
    ^ csa_in_2nd_root_dig_n2_2nd;
    uint64_t f_r_c_2nd_root_dig_n2_2nd = (
          ((f_r_s_1st << 2) & (f_r_c_1st << 2))
        | ((f_r_s_1st << 2) & csa_in_2nd_root_dig_n2_2nd)
        | ((f_r_c_1st << 2) & csa_in_2nd_root_dig_n2_2nd)
    ) << 1;

    uint64_t f_r_s_2nd_root_dig_n1_2nd =
      (f_r_s_1st << 2)
    ^ (f_r_c_1st << 2)
    ^ csa_in_2nd_root_dig_n1_2nd;
    uint64_t f_r_c_2nd_root_dig_n1_2nd = (
          ((f_r_s_1st << 2) & (f_r_c_1st << 2))
        | ((f_r_s_1st << 2) & csa_in_2nd_root_dig_n1_2nd)
        | ((f_r_c_1st << 2) & csa_in_2nd_root_dig_n1_2nd)
    ) << 1;

    uint64_t f_r_s_2nd_root_dig_z0_2nd = f_r_s_1st << 2;
    uint64_t f_r_c_2nd_root_dig_z0_2nd = f_r_c_1st << 2;

    uint64_t f_r_s_2nd_root_dig_p1_2nd = 
      (f_r_s_1st << 2)
    ^ (f_r_c_1st << 2)
    ^ csa_in_2nd_root_dig_p1_2nd;
    uint64_t f_r_c_2nd_root_dig_p1_2nd = ((
          ((f_r_s_1st << 2) & (f_r_c_1st << 2))
        | ((f_r_s_1st << 2) & csa_in_2nd_root_dig_p1_2nd)
        | ((f_r_c_1st << 2) & csa_in_2nd_root_dig_p1_2nd)
    ) << 1) | 1;

    uint64_t f_r_s_2nd_root_dig_p2_2nd = 
      (f_r_s_1st << 2)
    ^ (f_r_c_1st << 2)
    ^ csa_in_2nd_root_dig_p2_2nd;
    uint64_t f_r_c_2nd_root_dig_p2_2nd = ((
          ((f_r_s_1st << 2) & (f_r_c_1st << 2))
        | ((f_r_s_1st << 2) & csa_in_2nd_root_dig_p2_2nd)
        | ((f_r_c_1st << 2) & csa_in_2nd_root_dig_p2_2nd)
    ) << 1) | 1;
    
    
    // [(REM_W - 1) - 2 -: 9] = [53:45]
    // [(REM_W - 1) -: 9] = [55:47]
    // assign rem_msb_nxt_cycle_1st_srt_root_dig_n2_2nd = f_r_s_1st[(REM_W - 1) - 2 -: 9] + f_r_c_1st[(REM_W - 1) - 2 -: 9] + csa_in_2nd_root_dig_n2_2nd[(REM_W - 1) -: 9];
    // assign rem_msb_nxt_cycle_1st_srt_root_dig_n1_2nd = f_r_s_1st[(REM_W - 1) - 2 -: 9] + f_r_c_1st[(REM_W - 1) - 2 -: 9] + csa_in_2nd_root_dig_n1_2nd[(REM_W - 1) -: 9];
    // assign rem_msb_nxt_cycle_1st_srt_root_dig_z0_2nd = f_r_s_1st[(REM_W - 1) - 2 -: 9] + f_r_c_1st[(REM_W - 1) - 2 -: 9];
    // assign rem_msb_nxt_cycle_1st_srt_root_dig_p1_2nd = f_r_s_1st[(REM_W - 1) - 2 -: 9] + f_r_c_1st[(REM_W - 1) - 2 -: 9] + csa_in_2nd_root_dig_p1_2nd[(REM_W - 1) -: 9];
    // assign rem_msb_nxt_cycle_1st_srt_root_dig_p2_2nd = f_r_s_1st[(REM_W - 1) - 2 -: 9] + f_r_c_1st[(REM_W - 1) - 2 -: 9] + csa_in_2nd_root_dig_p2_2nd[(REM_W - 1) -: 9];

    // [(REM_W - 1) - 2 - 2 -: 10] = [51:42]
    // [(REM_W - 1) - 2 -: 10] = [53:44]
    // assign rem_msb_nxt_cycle_2nd_srt_root_dig_n2_2nd = f_r_s_1st[(REM_W - 1) - 2 - 2 -: 10] + f_r_c_1st[(REM_W - 1) - 2 - 2 -: 10] + csa_in_2nd_root_dig_n2_2nd[(REM_W - 1) - 2 -: 10];
    // assign rem_msb_nxt_cycle_2nd_srt_root_dig_n1_2nd = f_r_s_1st[(REM_W - 1) - 2 - 2 -: 10] + f_r_c_1st[(REM_W - 1) - 2 - 2 -: 10] + csa_in_2nd_root_dig_n1_2nd[(REM_W - 1) - 2 -: 10];
    // assign rem_msb_nxt_cycle_2nd_srt_root_dig_z0_2nd = f_r_s_1st[(REM_W - 1) - 2 - 2 -: 10] + f_r_c_1st[(REM_W - 1) - 2 - 2 -: 10];
    // assign rem_msb_nxt_cycle_2nd_srt_root_dig_p1_2nd = f_r_s_1st[(REM_W - 1) - 2 - 2 -: 10] + f_r_c_1st[(REM_W - 1) - 2 - 2 -: 10] + csa_in_2nd_root_dig_p1_2nd[(REM_W - 1) - 2 -: 10];
    // assign rem_msb_nxt_cycle_2nd_srt_root_dig_p2_2nd = f_r_s_1st[(REM_W - 1) - 2 - 2 -: 10] + f_r_c_1st[(REM_W - 1) - 2 - 2 -: 10] + csa_in_2nd_root_dig_p2_2nd[(REM_W - 1) - 2 -: 10];

    uint16_t rem_msb_nxt_cycle_1st_srt_root_dig_n2_2nd = ((f_r_s_1st >> 45) & 0x1FF) + ((f_r_c_1st >> 45) & 0x1FF) + ((csa_in_2nd_root_dig_n2_2nd >> 47) & 0x1FF);
    uint16_t rem_msb_nxt_cycle_1st_srt_root_dig_n1_2nd = ((f_r_s_1st >> 45) & 0x1FF) + ((f_r_c_1st >> 45) & 0x1FF) + ((csa_in_2nd_root_dig_n1_2nd >> 47) & 0x1FF);
    uint16_t rem_msb_nxt_cycle_1st_srt_root_dig_z0_2nd = ((f_r_s_1st >> 45) & 0x1FF) + ((f_r_c_1st >> 45) & 0x1FF);
    uint16_t rem_msb_nxt_cycle_1st_srt_root_dig_p1_2nd = ((f_r_s_1st >> 45) & 0x1FF) + ((f_r_c_1st >> 45) & 0x1FF) + ((csa_in_2nd_root_dig_p1_2nd >> 47) & 0x1FF);
    uint16_t rem_msb_nxt_cycle_1st_srt_root_dig_p2_2nd = ((f_r_s_1st >> 45) & 0x1FF) + ((f_r_c_1st >> 45) & 0x1FF) + ((csa_in_2nd_root_dig_p2_2nd >> 47) & 0x1FF);
    
    uint16_t rem_msb_nxt_cycle_2nd_srt_root_dig_n2_2nd = ((f_r_s_1st >> 42) & 0x3FF) + ((f_r_c_1st >> 42) & 0x3FF) + ((csa_in_2nd_root_dig_n2_2nd >> 44) & 0x3FF);
    uint16_t rem_msb_nxt_cycle_2nd_srt_root_dig_n1_2nd = ((f_r_s_1st >> 42) & 0x3FF) + ((f_r_c_1st >> 42) & 0x3FF) + ((csa_in_2nd_root_dig_n1_2nd >> 44) & 0x3FF);
    uint16_t rem_msb_nxt_cycle_2nd_srt_root_dig_z0_2nd = ((f_r_s_1st >> 42) & 0x3FF) + ((f_r_c_1st >> 42) & 0x3FF);
    uint16_t rem_msb_nxt_cycle_2nd_srt_root_dig_p1_2nd = ((f_r_s_1st >> 42) & 0x3FF) + ((f_r_c_1st >> 42) & 0x3FF) + ((csa_in_2nd_root_dig_p1_2nd >> 44) & 0x3FF);
    uint16_t rem_msb_nxt_cycle_2nd_srt_root_dig_p2_2nd = ((f_r_s_1st >> 42) & 0x3FF) + ((f_r_c_1st >> 42) & 0x3FF) + ((csa_in_2nd_root_dig_p2_2nd >> 44) & 0x3FF);

    uint64_t root_ext_2nd_root_dig_n2_2nd = root_m1_ext_1st | root_mask_2nd_root_dig_n2_2nd;
    uint64_t root_ext_2nd_root_dig_n1_2nd = root_m1_ext_1st | root_mask_2nd_root_dig_n1_2nd;
    uint64_t root_ext_2nd_root_dig_z0_2nd = root_ext_1st;
    uint64_t root_ext_2nd_root_dig_p1_2nd = root_ext_1st | root_mask_2nd_root_dig_p1_2nd;
    uint64_t root_ext_2nd_root_dig_p2_2nd = root_ext_1st | root_mask_2nd_root_dig_p2_2nd;
    
    uint64_t root_m1_ext_2nd_root_dig_n2_2nd = root_m1_ext_1st | root_m1_mask_2nd_root_dig_n2_2nd;
    uint64_t root_m1_ext_2nd_root_dig_n1_2nd = root_m1_ext_1st | root_m1_mask_2nd_root_dig_n1_2nd;
    uint64_t root_m1_ext_2nd_root_dig_z0_2nd = root_m1_ext_1st | root_m1_mask_2nd_root_dig_z0_2nd;
    uint64_t root_m1_ext_2nd_root_dig_p1_2nd = root_ext_1st;
    uint64_t root_m1_ext_2nd_root_dig_p2_2nd = root_ext_1st | root_m1_mask_2nd_root_dig_p2_2nd;
    
    bool a0_2nd_root_dig_n2_2nd = (root_ext_2nd_root_dig_n2_2nd >> 54) & 0x1;
    bool a2_2nd_root_dig_n2_2nd = (root_ext_2nd_root_dig_n2_2nd >> 52) & 0x1;
    bool a3_2nd_root_dig_n2_2nd = (root_ext_2nd_root_dig_n2_2nd >> 51) & 0x1;
    bool a4_2nd_root_dig_n2_2nd = (root_ext_2nd_root_dig_n2_2nd >> 50) & 0x1;
    
    bool a0_2nd_root_dig_n1_2nd = (root_ext_2nd_root_dig_n1_2nd >> 54) & 0x1;
    bool a2_2nd_root_dig_n1_2nd = (root_ext_2nd_root_dig_n1_2nd >> 52) & 0x1;
    bool a3_2nd_root_dig_n1_2nd = (root_ext_2nd_root_dig_n1_2nd >> 51) & 0x1;
    bool a4_2nd_root_dig_n1_2nd = (root_ext_2nd_root_dig_n1_2nd >> 50) & 0x1;
    
    bool a0_2nd_root_dig_z0_2nd = (root_ext_2nd_root_dig_z0_2nd >> 54) & 0x1;
    bool a2_2nd_root_dig_z0_2nd = (root_ext_2nd_root_dig_z0_2nd >> 52) & 0x1;
    bool a3_2nd_root_dig_z0_2nd = (root_ext_2nd_root_dig_z0_2nd >> 51) & 0x1;
    bool a4_2nd_root_dig_z0_2nd = (root_ext_2nd_root_dig_z0_2nd >> 50) & 0x1;
    
    bool a0_2nd_root_dig_p1_2nd = (root_ext_2nd_root_dig_p1_2nd >> 54) & 0x1;
    bool a2_2nd_root_dig_p1_2nd = (root_ext_2nd_root_dig_p1_2nd >> 52) & 0x1;
    bool a3_2nd_root_dig_p1_2nd = (root_ext_2nd_root_dig_p1_2nd >> 51) & 0x1;
    bool a4_2nd_root_dig_p1_2nd = (root_ext_2nd_root_dig_p1_2nd >> 50) & 0x1;
    
    bool a0_2nd_root_dig_p2_2nd = (root_ext_2nd_root_dig_p2_2nd >> 54) & 0x1;
    bool a2_2nd_root_dig_p2_2nd = (root_ext_2nd_root_dig_p2_2nd >> 52) & 0x1;
    bool a3_2nd_root_dig_p2_2nd = (root_ext_2nd_root_dig_p2_2nd >> 51) & 0x1;
    bool a4_2nd_root_dig_p2_2nd = (root_ext_2nd_root_dig_p2_2nd >> 50) & 0x1;

    uint8_t m_n1_nxt_cycle_root_dig_n2_2nd;
    uint8_t m_z0_nxt_cycle_root_dig_n2_2nd;
    uint8_t m_p1_nxt_cycle_root_dig_n2_2nd;
    uint8_t m_p2_nxt_cycle_root_dig_n2_2nd;
    fsqrt_r4_qds_constants_generator(
        a0_2nd_root_dig_n2_2nd,
        a2_2nd_root_dig_n2_2nd,
        a3_2nd_root_dig_n2_2nd,
        a4_2nd_root_dig_n2_2nd,
        &m_n1_nxt_cycle_root_dig_n2_2nd,
        &m_z0_nxt_cycle_root_dig_n2_2nd,
        &m_p1_nxt_cycle_root_dig_n2_2nd,
        &m_p2_nxt_cycle_root_dig_n2_2nd
    );
    
    uint8_t m_n1_nxt_cycle_root_dig_n1_2nd;
    uint8_t m_z0_nxt_cycle_root_dig_n1_2nd;
    uint8_t m_p1_nxt_cycle_root_dig_n1_2nd;
    uint8_t m_p2_nxt_cycle_root_dig_n1_2nd;    
    fsqrt_r4_qds_constants_generator(
        a0_2nd_root_dig_n1_2nd,
        a2_2nd_root_dig_n1_2nd,
        a3_2nd_root_dig_n1_2nd,
        a4_2nd_root_dig_n1_2nd,
        &m_n1_nxt_cycle_root_dig_n1_2nd,
        &m_z0_nxt_cycle_root_dig_n1_2nd,
        &m_p1_nxt_cycle_root_dig_n1_2nd,
        &m_p2_nxt_cycle_root_dig_n1_2nd
    );
    
    uint8_t m_n1_nxt_cycle_root_dig_z0_2nd;
    uint8_t m_z0_nxt_cycle_root_dig_z0_2nd;
    uint8_t m_p1_nxt_cycle_root_dig_z0_2nd;
    uint8_t m_p2_nxt_cycle_root_dig_z0_2nd;    
    fsqrt_r4_qds_constants_generator(
        a0_2nd_root_dig_z0_2nd,
        a2_2nd_root_dig_z0_2nd,
        a3_2nd_root_dig_z0_2nd,
        a4_2nd_root_dig_z0_2nd,
        &m_n1_nxt_cycle_root_dig_z0_2nd,
        &m_z0_nxt_cycle_root_dig_z0_2nd,
        &m_p1_nxt_cycle_root_dig_z0_2nd,
        &m_p2_nxt_cycle_root_dig_z0_2nd
    );
    
    uint8_t m_n1_nxt_cycle_root_dig_p1_2nd;
    uint8_t m_z0_nxt_cycle_root_dig_p1_2nd;
    uint8_t m_p1_nxt_cycle_root_dig_p1_2nd;
    uint8_t m_p2_nxt_cycle_root_dig_p1_2nd;    
    fsqrt_r4_qds_constants_generator(
        a0_2nd_root_dig_p1_2nd,
        a2_2nd_root_dig_p1_2nd,
        a3_2nd_root_dig_p1_2nd,
        a4_2nd_root_dig_p1_2nd,
        &m_n1_nxt_cycle_root_dig_p1_2nd,
        &m_z0_nxt_cycle_root_dig_p1_2nd,
        &m_p1_nxt_cycle_root_dig_p1_2nd,
        &m_p2_nxt_cycle_root_dig_p1_2nd
    );
    
    uint8_t m_n1_nxt_cycle_root_dig_p2_2nd;
    uint8_t m_z0_nxt_cycle_root_dig_p2_2nd;
    uint8_t m_p1_nxt_cycle_root_dig_p2_2nd;
    uint8_t m_p2_nxt_cycle_root_dig_p2_2nd;    
    fsqrt_r4_qds_constants_generator(
        a0_2nd_root_dig_p2_2nd,
        a2_2nd_root_dig_p2_2nd,
        a3_2nd_root_dig_p2_2nd,
        a4_2nd_root_dig_p2_2nd,
        &m_n1_nxt_cycle_root_dig_p2_2nd,
        &m_z0_nxt_cycle_root_dig_p2_2nd,
        &m_p1_nxt_cycle_root_dig_p2_2nd,
        &m_p2_nxt_cycle_root_dig_p2_2nd
    );

    *root_2nd_o = 
    root_dig_n2_2nd ? root_ext_2nd_root_dig_n2_2nd :
    root_dig_n1_2nd ? root_ext_2nd_root_dig_n1_2nd :
    root_dig_z0_2nd ? root_ext_2nd_root_dig_z0_2nd :
    root_dig_p1_2nd ? root_ext_2nd_root_dig_p1_2nd :
    root_ext_2nd_root_dig_p2_2nd;
    
    *root_m1_2nd_o = 
    root_dig_n2_2nd ? root_m1_ext_2nd_root_dig_n2_2nd :
    root_dig_n1_2nd ? root_m1_ext_2nd_root_dig_n1_2nd :
    root_dig_z0_2nd ? root_m1_ext_2nd_root_dig_z0_2nd :
    root_dig_p1_2nd ? root_m1_ext_2nd_root_dig_p1_2nd :
    root_m1_ext_2nd_root_dig_p2_2nd;

    *f_r_s_2nd_o = 
    root_dig_n2_2nd ? f_r_s_2nd_root_dig_n2_2nd :
    root_dig_n1_2nd ? f_r_s_2nd_root_dig_n1_2nd :
    root_dig_z0_2nd ? f_r_s_2nd_root_dig_z0_2nd :
    root_dig_p1_2nd ? f_r_s_2nd_root_dig_p1_2nd :
    f_r_s_2nd_root_dig_p2_2nd;

    *f_r_c_2nd_o = 
    root_dig_n2_2nd ? f_r_c_2nd_root_dig_n2_2nd :
    root_dig_n1_2nd ? f_r_c_2nd_root_dig_n1_2nd :
    root_dig_z0_2nd ? f_r_c_2nd_root_dig_z0_2nd :
    root_dig_p1_2nd ? f_r_c_2nd_root_dig_p1_2nd :
    f_r_c_2nd_root_dig_p2_2nd;

    *rem_msb_nxt_cycle_1st_srt_o = (
    root_dig_n2_2nd ? rem_msb_nxt_cycle_1st_srt_root_dig_n2_2nd :
    root_dig_n1_2nd ? rem_msb_nxt_cycle_1st_srt_root_dig_n1_2nd :
    root_dig_z0_2nd ? rem_msb_nxt_cycle_1st_srt_root_dig_z0_2nd :
    root_dig_p1_2nd ? rem_msb_nxt_cycle_1st_srt_root_dig_p1_2nd :
    rem_msb_nxt_cycle_1st_srt_root_dig_p2_2nd) >> 2;

    *rem_msb_nxt_cycle_2nd_srt_o = (
    root_dig_n2_2nd ? rem_msb_nxt_cycle_2nd_srt_root_dig_n2_2nd :
    root_dig_n1_2nd ? rem_msb_nxt_cycle_2nd_srt_root_dig_n1_2nd :
    root_dig_z0_2nd ? rem_msb_nxt_cycle_2nd_srt_root_dig_z0_2nd :
    root_dig_p1_2nd ? rem_msb_nxt_cycle_2nd_srt_root_dig_p1_2nd :
    rem_msb_nxt_cycle_2nd_srt_root_dig_p2_2nd) >> 1;

    *m_n1_nxt_cycle_1st_srt_o = 
    root_dig_n2_2nd ? m_n1_nxt_cycle_root_dig_n2_2nd :
    root_dig_n1_2nd ? m_n1_nxt_cycle_root_dig_n1_2nd :
    root_dig_z0_2nd ? m_n1_nxt_cycle_root_dig_z0_2nd :
    root_dig_p1_2nd ? m_n1_nxt_cycle_root_dig_p1_2nd :
    m_n1_nxt_cycle_root_dig_p2_2nd;

    *m_z0_nxt_cycle_1st_srt_o = 
    root_dig_n2_2nd ? m_z0_nxt_cycle_root_dig_n2_2nd :
    root_dig_n1_2nd ? m_z0_nxt_cycle_root_dig_n1_2nd :
    root_dig_z0_2nd ? m_z0_nxt_cycle_root_dig_z0_2nd :
    root_dig_p1_2nd ? m_z0_nxt_cycle_root_dig_p1_2nd :
    m_z0_nxt_cycle_root_dig_p2_2nd;

    *m_p1_nxt_cycle_1st_srt_o = 
    root_dig_n2_2nd ? m_p1_nxt_cycle_root_dig_n2_2nd :
    root_dig_n1_2nd ? m_p1_nxt_cycle_root_dig_n1_2nd :
    root_dig_z0_2nd ? m_p1_nxt_cycle_root_dig_z0_2nd :
    root_dig_p1_2nd ? m_p1_nxt_cycle_root_dig_p1_2nd :
    m_p1_nxt_cycle_root_dig_p2_2nd;

    *m_p2_nxt_cycle_1st_srt_o = 
    root_dig_n2_2nd ? m_p2_nxt_cycle_root_dig_n2_2nd :
    root_dig_n1_2nd ? m_p2_nxt_cycle_root_dig_n1_2nd :
    root_dig_z0_2nd ? m_p2_nxt_cycle_root_dig_z0_2nd :
    root_dig_p1_2nd ? m_p2_nxt_cycle_root_dig_p1_2nd :
    m_p2_nxt_cycle_root_dig_p2_2nd;

#ifdef PRINT_INFO
    printf("//===========================================\n");
    printf("fsqrt: srt\n");
    printf("//===========================================\n");
    
    printf("csa_mask_ext_1st = %016llx\n", csa_mask_ext_1st);

    printf("csa_mask_1st_root_dig_n2_1st = %016llx\n", csa_mask_1st_root_dig_n2_1st);
    printf("csa_mask_1st_root_dig_n1_1st = %016llx\n", csa_mask_1st_root_dig_n1_1st);
    printf("csa_mask_1st_root_dig_z0_1st = %016llx\n", csa_mask_1st_root_dig_z0_1st);
    printf("csa_mask_1st_root_dig_p1_1st = %016llx\n", csa_mask_1st_root_dig_p1_1st);
    printf("csa_mask_1st_root_dig_p2_1st = %016llx\n", csa_mask_1st_root_dig_p2_1st);
    
    printf("root_mask_ext_1st = %016llx\n", root_mask_ext_1st);    
    printf("root_mask_1st_root_dig_n2_1st = %016llx\n", root_mask_1st_root_dig_n2_1st);
    printf("root_mask_1st_root_dig_n1_1st = %016llx\n", root_mask_1st_root_dig_n1_1st);
    printf("root_mask_1st_root_dig_z0_1st = %016llx\n", root_mask_1st_root_dig_z0_1st);
    printf("root_mask_1st_root_dig_p1_1st = %016llx\n", root_mask_1st_root_dig_p1_1st);
    printf("root_mask_1st_root_dig_p2_1st = %016llx\n", root_mask_1st_root_dig_p2_1st);
    printf("root_m1_mask_1st_root_dig_n2_1st = %016llx\n", root_m1_mask_1st_root_dig_n2_1st);
    printf("root_m1_mask_1st_root_dig_n1_1st = %016llx\n", root_m1_mask_1st_root_dig_n1_1st);
    printf("root_m1_mask_1st_root_dig_z0_1st = %016llx\n", root_m1_mask_1st_root_dig_z0_1st);
    printf("root_m1_mask_1st_root_dig_p1_1st = %016llx\n", root_m1_mask_1st_root_dig_p1_1st);
    printf("root_m1_mask_1st_root_dig_p2_1st = %016llx\n", root_m1_mask_1st_root_dig_p2_1st);    
    

    printf("root_ext_last_cycle = %016llx\n", root_ext_last_cycle);  
    printf("root_m1_ext_last_cycle = %016llx\n", root_m1_ext_last_cycle);  
    
    printf("rem_msb_nxt_cycle_1st_srt_i = %016llx\n", rem_msb_nxt_cycle_1st_srt_i);       
    printf("m_n1_1st = %016llx\n", m_n1_1st);
    printf("m_z0_1st = %016llx\n", m_z0_1st);
    printf("m_p1_1st = %016llx\n", m_p1_1st);
    printf("m_p2_1st = %016llx\n", m_p2_1st);
    printf("root_dig_n2_1st = %016llx\n", root_dig_n2_1st);
    printf("root_dig_n1_1st = %016llx\n", root_dig_n1_1st);
    printf("root_dig_z0_1st = %016llx\n", root_dig_z0_1st);
    printf("root_dig_p1_1st = %016llx\n", root_dig_p1_1st);
    printf("root_dig_p2_1st = %016llx\n", root_dig_p2_1st);
    printf("root_ext_1st = %016llx\n", root_ext_1st);
    printf("root_m1_ext_1st = %016llx\n", root_m1_ext_1st);
    printf("f_r_s_1st = %016llx\n", f_r_s_1st);
    printf("f_r_c_1st = %016llx\n", f_r_c_1st);
    
    
    printf("rem_msb_nxt_cycle_2nd_srt_i = %016llx\n", rem_msb_nxt_cycle_2nd_srt_i); 
    printf("m_n1_2nd = %016llx\n", m_n1_2nd);
    printf("m_z0_2nd = %016llx\n", m_z0_2nd);
    printf("m_p1_2nd = %016llx\n", m_p1_2nd);
    printf("m_p2_2nd = %016llx\n", m_p2_2nd);
    printf("root_dig_n2_2nd = %016llx\n", root_dig_n2_2nd);
    printf("root_dig_n1_2nd = %016llx\n", root_dig_n1_2nd);
    printf("root_dig_z0_2nd = %016llx\n", root_dig_z0_2nd);
    printf("root_dig_p1_2nd = %016llx\n", root_dig_p1_2nd);
    printf("root_dig_p2_2nd = %016llx\n", root_dig_p2_2nd);
    printf("root_ext_2nd = %016llx\n", *root_2nd_o);
    printf("root_m1_ext_2nd = %016llx\n", *root_m1_2nd_o);


    printf("csa_mask_ext_2nd = %016llx\n", csa_mask_ext_2nd);
    printf("csa_mask_2nd_root_dig_n2_2nd = %016llx\n", csa_mask_2nd_root_dig_n2_2nd);
    printf("csa_mask_2nd_root_dig_n1_2nd = %016llx\n", csa_mask_2nd_root_dig_n1_2nd);
    printf("csa_mask_2nd_root_dig_z0_2nd = %016llx\n", csa_mask_2nd_root_dig_z0_2nd);
    printf("csa_mask_2nd_root_dig_p1_2nd = %016llx\n", csa_mask_2nd_root_dig_p1_2nd);
    printf("csa_mask_2nd_root_dig_p2_2nd = %016llx\n", csa_mask_2nd_root_dig_p2_2nd);

    // printf("root_mask_ext_2nd = %016llx\n", root_mask_ext_2nd);
    // printf("root_mask_2nd_root_dig_n2_2nd = %016llx\n", root_mask_2nd_root_dig_n2_2nd);
    // printf("root_mask_2nd_root_dig_n1_2nd = %016llx\n", root_mask_2nd_root_dig_n1_2nd);
    // printf("root_mask_2nd_root_dig_z0_2nd = %016llx\n", root_mask_2nd_root_dig_z0_2nd);
    // printf("root_mask_2nd_root_dig_p1_2nd = %016llx\n", root_mask_2nd_root_dig_p1_2nd);
    // printf("root_mask_2nd_root_dig_p2_2nd = %016llx\n", root_mask_2nd_root_dig_p2_2nd);
    // printf("root_m1_mask_2nd_root_dig_n2_2nd = %016llx\n", root_m1_mask_2nd_root_dig_n2_2nd);
    // printf("root_m1_mask_2nd_root_dig_n1_2nd = %016llx\n", root_m1_mask_2nd_root_dig_n1_2nd);
    // printf("root_m1_mask_2nd_root_dig_z0_2nd = %016llx\n", root_m1_mask_2nd_root_dig_z0_2nd);
    // printf("root_m1_mask_2nd_root_dig_p1_2nd = %016llx\n", root_m1_mask_2nd_root_dig_p1_2nd);
    // printf("root_m1_mask_2nd_root_dig_p2_2nd = %016llx\n", root_m1_mask_2nd_root_dig_p2_2nd);
    // printf("root_ext_2nd_root_dig_n2_2nd = %016llx\n", root_ext_2nd_root_dig_n2_2nd);
    // printf("root_ext_2nd_root_dig_n1_2nd = %016llx\n", root_ext_2nd_root_dig_n1_2nd);
    // printf("root_ext_2nd_root_dig_z0_2nd = %016llx\n", root_ext_2nd_root_dig_z0_2nd);
    // printf("root_ext_2nd_root_dig_p1_2nd = %016llx\n", root_ext_2nd_root_dig_p1_2nd);
    // printf("root_ext_2nd_root_dig_p2_2nd = %016llx\n", root_ext_2nd_root_dig_p2_2nd);
    // printf("root_m1_ext_2nd_root_dig_n2_2nd = %016llx\n", root_m1_ext_2nd_root_dig_n2_2nd);
    // printf("root_m1_ext_2nd_root_dig_n1_2nd = %016llx\n", root_m1_ext_2nd_root_dig_n1_2nd);
    // printf("root_m1_ext_2nd_root_dig_z0_2nd = %016llx\n", root_m1_ext_2nd_root_dig_z0_2nd);
    // printf("root_m1_ext_2nd_root_dig_p1_2nd = %016llx\n", root_m1_ext_2nd_root_dig_p1_2nd);
    // printf("root_m1_ext_2nd_root_dig_p2_2nd = %016llx\n", root_m1_ext_2nd_root_dig_p2_2nd);
    
    printf("f_r_s_2nd = %016llx\n", *f_r_s_2nd_o);
    printf("f_r_c_2nd = %016llx\n", *f_r_c_2nd_o);
    
    printf("rem_msb_nxt_cycle_1st_srt_o = %016llx\n", *rem_msb_nxt_cycle_1st_srt_o);
    printf("rem_msb_nxt_cycle_2nd_srt_o = %016llx\n", *rem_msb_nxt_cycle_2nd_srt_o);
    printf("m_n1_nxt_cycle_1st_srt_o = %016llx\n", *m_n1_nxt_cycle_1st_srt_o);
    printf("m_z0_nxt_cycle_1st_srt_o = %016llx\n", *m_z0_nxt_cycle_1st_srt_o);
    printf("m_p1_nxt_cycle_1st_srt_o = %016llx\n", *m_p1_nxt_cycle_1st_srt_o);
    printf("m_p2_nxt_cycle_1st_srt_o = %016llx\n", *m_p2_nxt_cycle_1st_srt_o);
#endif
}

void fdiv_r16_block(
    uint64_t f_r_s_i,
    uint64_t f_r_c_i,
    uint64_t divisor_i,
    uint64_t quot_i,
    uint64_t quot_m1_i,
    uint64_t *quot_2nd_o,
    uint64_t *quot_m1_2nd_o,
    uint64_t *f_r_s_2nd_o,
    uint64_t *f_r_c_2nd_o
) {
    uint64_t divisor_ext = divisor_i << 2;
    uint64_t divisor_mul_neg_2 = ~(divisor_ext << 1);
    uint64_t divisor_mul_neg_1 = ~divisor_ext;
    uint64_t divisor_mul_pos_1 = divisor_ext;
    uint64_t divisor_mul_pos_2 = divisor_ext << 1;

    uint64_t f_r_s_quot_dig_n2_1st = 
      (f_r_s_i << 2)
    ^ (f_r_c_i << 2)
    ^ divisor_mul_pos_2;
    uint64_t f_r_c_quot_dig_n2_1st = (
          ((f_r_s_i << 2) & (f_r_c_i << 2))
        | ((f_r_s_i << 2) & divisor_mul_pos_2)
        | ((f_r_c_i << 2) & divisor_mul_pos_2)
    ) << 1;

    uint64_t f_r_s_quot_dig_n1_1st = 
      (f_r_s_i << 2)
    ^ (f_r_c_i << 2)
    ^ divisor_mul_pos_1;
    uint64_t f_r_c_quot_dig_n1_1st = (
          ((f_r_s_i << 2) & (f_r_c_i << 2))
        | ((f_r_s_i << 2) & divisor_mul_pos_1)
        | ((f_r_c_i << 2) & divisor_mul_pos_1)
    ) << 1;

    uint64_t f_r_s_quot_dig_z0_1st = f_r_s_i << 2;
    uint64_t f_r_c_quot_dig_z0_1st = f_r_c_i << 2;

    uint64_t f_r_s_quot_dig_p1_1st = 
      (f_r_s_i << 2)
    ^ (f_r_c_i << 2)
    ^ divisor_mul_neg_1;
    uint64_t f_r_c_quot_dig_p1_1st = ((
          ((f_r_s_i << 2) & (f_r_c_i << 2))
        | ((f_r_s_i << 2) & divisor_mul_neg_1)
        | ((f_r_c_i << 2) & divisor_mul_neg_1)
    ) << 1) | 1;

    uint64_t f_r_s_quot_dig_p2_1st = 
      (f_r_s_i << 2)
    ^ (f_r_c_i << 2)
    ^ divisor_mul_neg_2;
    uint64_t f_r_c_quot_dig_p2_1st = ((
          ((f_r_s_i << 2) & (f_r_c_i << 2))
        | ((f_r_s_i << 2) & divisor_mul_neg_2)
        | ((f_r_c_i << 2) & divisor_mul_neg_2)
    ) << 1) | 1;

    // REM_W = 1 + 1 + 2 + 1 + 53 + 3 = 61
    // assign rem_msb_1st[5:0] = f_r_s_i[(REM_W - 1) - 2 -: 6] + f_r_c_i[(REM_W - 1) - 2 -: 6];
    // [58:53]
    uint64_t rem_msb_1st = ((f_r_s_i >> 53) & 0x3F) + ((f_r_c_i >> 53) & 0x3F);    

    uint64_t quot_dig_1st = fdiv_r4_qds(rem_msb_1st);
    bool quot_dig_p2_1st = (((quot_dig_1st >> 0) & 1) == 1);
    bool quot_dig_p1_1st = (((quot_dig_1st >> 1) & 1) == 1);
    bool quot_dig_z0_1st = (((quot_dig_1st >> 2) & 1) == 1);
    bool quot_dig_n1_1st = (((quot_dig_1st >> 3) & 1) == 1);
    bool quot_dig_n2_1st = (((quot_dig_1st >> 4) & 1) == 1);
    
    uint64_t f_r_s_1st = 
    quot_dig_p2_1st ? f_r_s_quot_dig_p2_1st : 
    quot_dig_p1_1st ? f_r_s_quot_dig_p1_1st : 
    quot_dig_z0_1st ? f_r_s_quot_dig_z0_1st : 
    quot_dig_n1_1st ? f_r_s_quot_dig_n1_1st : 
    f_r_s_quot_dig_n2_1st;
    uint64_t f_r_c_1st = 
    quot_dig_p2_1st ? f_r_c_quot_dig_p2_1st : 
    quot_dig_p1_1st ? f_r_c_quot_dig_p1_1st : 
    quot_dig_z0_1st ? f_r_c_quot_dig_z0_1st : 
    quot_dig_n1_1st ? f_r_c_quot_dig_n1_1st : 
    f_r_c_quot_dig_n2_1st;




    uint64_t f_r_s_quot_dig_n2_2nd = 
      (f_r_s_1st << 2)
    ^ (f_r_c_1st << 2)
    ^ divisor_mul_pos_2;
    uint64_t f_r_c_quot_dig_n2_2nd = (
          ((f_r_s_1st << 2) & (f_r_c_1st << 2))
        | ((f_r_s_1st << 2) & divisor_mul_pos_2)
        | ((f_r_c_1st << 2) & divisor_mul_pos_2)
    ) << 1;

    uint64_t f_r_s_quot_dig_n1_2nd = 
      (f_r_s_1st << 2)
    ^ (f_r_c_1st << 2)
    ^ divisor_mul_pos_1;
    uint64_t f_r_c_quot_dig_n1_2nd = (
          ((f_r_s_1st << 2) & (f_r_c_1st << 2))
        | ((f_r_s_1st << 2) & divisor_mul_pos_1)
        | ((f_r_c_1st << 2) & divisor_mul_pos_1)
    ) << 1;

    uint64_t f_r_s_quot_dig_z0_2nd = f_r_s_1st << 2;
    uint64_t f_r_c_quot_dig_z0_2nd = f_r_c_1st << 2;

    uint64_t f_r_s_quot_dig_p1_2nd = 
      (f_r_s_1st << 2)
    ^ (f_r_c_1st << 2)
    ^ divisor_mul_neg_1;
    uint64_t f_r_c_quot_dig_p1_2nd = ((
          ((f_r_s_1st << 2) & (f_r_c_1st << 2))
        | ((f_r_s_1st << 2) & divisor_mul_neg_1)
        | ((f_r_c_1st << 2) & divisor_mul_neg_1)
    ) << 1) | 1;

    uint64_t f_r_s_quot_dig_p2_2nd = 
      (f_r_s_1st << 2)
    ^ (f_r_c_1st << 2)
    ^ divisor_mul_neg_2;
    uint64_t f_r_c_quot_dig_p2_2nd = ((
          ((f_r_s_1st << 2) & (f_r_c_1st << 2))
        | ((f_r_s_1st << 2) & divisor_mul_neg_2)
        | ((f_r_c_1st << 2) & divisor_mul_neg_2)
    ) << 1) | 1;

    // assign rem_msb_quot_dig_n2_2nd[6:0] = f_r_s_i[(REM_W - 1) - 2 - 2 -: 7] + f_r_c_i[(REM_W - 1) - 2 - 2 -: 7] + divisor_mul_pos_2[(REM_W - 1) - 2 -: 7];
    // assign rem_msb_quot_dig_n1_2nd[6:0] = f_r_s_i[(REM_W - 1) - 2 - 2 -: 7] + f_r_c_i[(REM_W - 1) - 2 - 2 -: 7] + divisor_mul_pos_1[(REM_W - 1) - 2 -: 7];
    // assign rem_msb_quot_dig_z0_2nd[6:0] = f_r_s_i[(REM_W - 1) - 2 - 2 -: 7] + f_r_c_i[(REM_W - 1) - 2 - 2 -: 7];
    // assign rem_msb_quot_dig_p1_2nd[6:0] = f_r_s_i[(REM_W - 1) - 2 - 2 -: 7] + f_r_c_i[(REM_W - 1) - 2 - 2 -: 7] + divisor_mul_neg_1[(REM_W - 1) - 2 -: 7];
    // assign rem_msb_quot_dig_p2_2nd[6:0] = f_r_s_i[(REM_W - 1) - 2 - 2 -: 7] + f_r_c_i[(REM_W - 1) - 2 - 2 -: 7] + divisor_mul_neg_2[(REM_W - 1) - 2 -: 7];
    // assign rem_msb_2nd[5:0] = 
    //   ({(6){quot_dig_p2_1st}} & rem_msb_quot_dig_p2_2nd[6:1])
    // | ({(6){quot_dig_p1_1st}} & rem_msb_quot_dig_p1_2nd[6:1])
    // | ({(6){quot_dig_z0_1st}} & rem_msb_quot_dig_z0_2nd[6:1])
    // | ({(6){quot_dig_n1_1st}} & rem_msb_quot_dig_n1_2nd[6:1])
    // | ({(6){quot_dig_n2_1st}} & rem_msb_quot_dig_n2_2nd[6:1]);
    // REM_W = 1 + 1 + 2 + 1 + 53 + 3 = 61
    
    
    // (REM_W - 1) - 2 - 2 -: 7 = 56:50
    // (REM_W - 1) - 2 -: 7 = 58:52
    uint64_t rem_msb_quot_dig_n2_2nd = ((f_r_s_i >> 50) & 0x7F) + ((f_r_c_i >> 50) & 0x7F) + ((divisor_mul_pos_2 >> 52) & 0x7F);
    uint64_t rem_msb_quot_dig_n1_2nd = ((f_r_s_i >> 50) & 0x7F) + ((f_r_c_i >> 50) & 0x7F) + ((divisor_mul_pos_1 >> 52) & 0x7F);
    uint64_t rem_msb_quot_dig_z0_2nd = ((f_r_s_i >> 50) & 0x7F) + ((f_r_c_i >> 50) & 0x7F);
    uint64_t rem_msb_quot_dig_p1_2nd = ((f_r_s_i >> 50) & 0x7F) + ((f_r_c_i >> 50) & 0x7F) + ((divisor_mul_neg_1 >> 52) & 0x7F);
    uint64_t rem_msb_quot_dig_p2_2nd = ((f_r_s_i >> 50) & 0x7F) + ((f_r_c_i >> 50) & 0x7F) + ((divisor_mul_neg_2 >> 52) & 0x7F);

    uint64_t rem_msb_2nd =
    quot_dig_p2_1st ? rem_msb_quot_dig_p2_2nd :
    quot_dig_p1_1st ? rem_msb_quot_dig_p1_2nd :
    quot_dig_z0_1st ? rem_msb_quot_dig_z0_2nd :
    quot_dig_n1_1st ? rem_msb_quot_dig_n1_2nd :
    rem_msb_quot_dig_n2_2nd;
    rem_msb_2nd = rem_msb_2nd >> 1;

    // assign rem_msb_2nd[5:0] = f_r_s_1st[(REM_W - 1) - 2 -: 6] + f_r_c_1st[(REM_W - 1) - 2 -: 6];
    // (REM_W - 1) - 2 -: 6 = 58:53
    // uint64_t rem_msb_2nd = ((f_r_s_1st >> 53) & 0x3F) + ((f_r_c_1st >> 53) & 0x3F);  

    uint64_t quot_dig_2nd = fdiv_r4_qds(rem_msb_2nd);
    bool quot_dig_p2_2nd = (((quot_dig_2nd >> 0) & 1) == 1);
    bool quot_dig_p1_2nd = (((quot_dig_2nd >> 1) & 1) == 1);
    bool quot_dig_z0_2nd = (((quot_dig_2nd >> 2) & 1) == 1);
    bool quot_dig_n1_2nd = (((quot_dig_2nd >> 3) & 1) == 1);
    bool quot_dig_n2_2nd = (((quot_dig_2nd >> 4) & 1) == 1);
    
    uint64_t f_r_s_2nd = 
    quot_dig_p2_2nd ? f_r_s_quot_dig_p2_2nd : 
    quot_dig_p1_2nd ? f_r_s_quot_dig_p1_2nd : 
    quot_dig_z0_2nd ? f_r_s_quot_dig_z0_2nd : 
    quot_dig_n1_2nd ? f_r_s_quot_dig_n1_2nd : 
    f_r_s_quot_dig_n2_2nd;
    uint64_t f_r_c_2nd = 
    quot_dig_p2_2nd ? f_r_c_quot_dig_p2_2nd : 
    quot_dig_p1_2nd ? f_r_c_quot_dig_p1_2nd : 
    quot_dig_z0_2nd ? f_r_c_quot_dig_z0_2nd : 
    quot_dig_n1_2nd ? f_r_c_quot_dig_n1_2nd : 
    f_r_c_quot_dig_n2_2nd;

    *f_r_s_2nd_o = f_r_s_2nd;
    *f_r_c_2nd_o = f_r_c_2nd;

    
    // assign quot_1st = 
    // ({(56){quot_dig_p2_1st}} & {quot_root_iter_q   [54 - 1:0], 2'b10})
    // | ({(56){quot_dig_p1_1st}} & {quot_root_iter_q   [54 - 1:0], 2'b01})
    // | ({(56){quot_dig_z0_1st}} & {quot_root_iter_q   [54 - 1:0], 2'b00})
    // | ({(56){quot_dig_n1_1st}} & {quot_root_m1_iter_q[54 - 1:0], 2'b11})
    // | ({(56){quot_dig_n2_1st}} & {quot_root_m1_iter_q[54 - 1:0], 2'b10});
    // assign quot_m1_1st = 
    // ({(56){quot_dig_p2_1st}} & {quot_root_iter_q   [54 - 1:0], 2'b01})
    // | ({(56){quot_dig_p1_1st}} & {quot_root_iter_q   [54 - 1:0], 2'b00})
    // | ({(56){quot_dig_z0_1st}} & {quot_root_m1_iter_q[54 - 1:0], 2'b11})
    // | ({(56){quot_dig_n1_1st}} & {quot_root_m1_iter_q[54 - 1:0], 2'b10})
    // | ({(56){quot_dig_n2_1st}} & {quot_root_m1_iter_q[54 - 1:0], 2'b01});

    // assign quot_2nd = 
    // ({(56){quot_dig_p2_2nd}} & {quot_1st   [(56 - 1) - 2:0], 2'b10})
    // | ({(56){quot_dig_p1_2nd}} & {quot_1st   [(56 - 1) - 2:0], 2'b01})
    // | ({(56){quot_dig_z0_2nd}} & {quot_1st   [(56 - 1) - 2:0], 2'b00})
    // | ({(56){quot_dig_n1_2nd}} & {quot_m1_1st[(56 - 1) - 2:0], 2'b11})
    // | ({(56){quot_dig_n2_2nd}} & {quot_m1_1st[(56 - 1) - 2:0], 2'b10});
    // assign quot_m1_2nd = 
    // ({(56){quot_dig_p2_2nd}} & {quot_1st   [(56 - 1) - 2:0], 2'b01})
    // | ({(56){quot_dig_p1_2nd}} & {quot_1st   [(56 - 1) - 2:0], 2'b00})
    // | ({(56){quot_dig_z0_2nd}} & {quot_m1_1st[(56 - 1) - 2:0], 2'b11})
    // | ({(56){quot_dig_n1_2nd}} & {quot_m1_1st[(56 - 1) - 2:0], 2'b10})
    // | ({(56){quot_dig_n2_2nd}} & {quot_m1_1st[(56 - 1) - 2:0], 2'b01});

    uint64_t quot_1st = 
    quot_dig_p2_1st ? ((quot_i    << 2) | 0b10) :
    quot_dig_p1_1st ? ((quot_i    << 2) | 0b01) :
    quot_dig_z0_1st ? ((quot_i    << 2) | 0b00) :
    quot_dig_n1_1st ? ((quot_m1_i << 2) | 0b11) :
    ((quot_m1_i << 2) | 0b10);
    uint64_t quot_m1_1st = 
    quot_dig_p2_1st ? ((quot_i    << 2) | 0b01) :
    quot_dig_p1_1st ? ((quot_i    << 2) | 0b00) :
    quot_dig_z0_1st ? ((quot_m1_i << 2) | 0b11) :
    quot_dig_n1_1st ? ((quot_m1_i << 2) | 0b10) :
    ((quot_m1_i << 2) | 0b01);

    uint64_t quot_2nd = 
    quot_dig_p2_2nd ? ((quot_1st    << 2) | 0b10) :
    quot_dig_p1_2nd ? ((quot_1st    << 2) | 0b01) :
    quot_dig_z0_2nd ? ((quot_1st    << 2) | 0b00) :
    quot_dig_n1_2nd ? ((quot_m1_1st << 2) | 0b11) :
    ((quot_m1_1st << 2) | 0b10);
    uint64_t quot_m1_2nd = 
    quot_dig_p2_2nd ? ((quot_1st    << 2) | 0b01) :
    quot_dig_p1_2nd ? ((quot_1st    << 2) | 0b00) :
    quot_dig_z0_2nd ? ((quot_m1_1st << 2) | 0b11) :
    quot_dig_n1_2nd ? ((quot_m1_1st << 2) | 0b10) :
    ((quot_m1_1st << 2) | 0b01);

    *quot_2nd_o = quot_2nd;
    *quot_m1_2nd_o = quot_m1_2nd;

#ifdef PRINT_INFO
    printf("//===========================================\n");
    printf("fdiv: srt\n");
    printf("//===========================================\n");

    printf("rem_msb_1st = %016llx\n", rem_msb_1st & 0x3F);
    printf("f_r_s_1st = %016llx\n", f_r_s_1st);
    printf("f_r_c_1st = %016llx\n", f_r_c_1st);
    printf("quot_1st = %016llx\n", quot_1st);
    printf("quot_m1_1st = %016llx\n", quot_m1_1st);
    printf("quot_dig_n2_1st = %016llx\n", quot_dig_n2_1st);
    printf("quot_dig_n1_1st = %016llx\n", quot_dig_n1_1st);
    printf("quot_dig_z0_1st = %016llx\n", quot_dig_z0_1st);
    printf("quot_dig_p1_1st = %016llx\n", quot_dig_p1_1st);
    printf("quot_dig_p2_1st = %016llx\n", quot_dig_p2_1st);

    printf("rem_msb_2nd = %016llx\n", rem_msb_2nd & 0x3F);
    printf("f_r_s_2nd = %016llx\n", f_r_s_2nd);
    printf("f_r_c_2nd = %016llx\n", f_r_c_2nd);
    printf("quot_2nd = %016llx\n", quot_2nd);
    printf("quot_m1_2nd = %016llx\n", quot_m1_2nd);
    printf("quot_dig_n2_2nd = %016llx\n", quot_dig_n2_2nd);
    printf("quot_dig_n1_2nd = %016llx\n", quot_dig_n1_2nd);
    printf("quot_dig_z0_2nd = %016llx\n", quot_dig_z0_2nd);
    printf("quot_dig_p1_2nd = %016llx\n", quot_dig_p1_2nd);
    printf("quot_dig_p2_2nd = %016llx\n", quot_dig_p2_2nd);
#endif
}

void fsqrt_r4_qds(
    uint8_t rem_i,
    uint8_t m_n1_i,
    uint8_t m_z0_i,
    uint8_t m_p1_i,
    uint8_t m_p2_i,
    bool *root_dig_n2_o,
    bool *root_dig_n1_o,
    bool *root_dig_z0_o,
    bool *root_dig_p1_o,
    bool *root_dig_p2_o
) {
    bool sign0;
    bool sign1;
    bool sign2;
    bool sign3;

    sign0 = ((rem_i + m_n1_i) >> 6) & 0x1;
    sign1 = ((rem_i + m_z0_i) >> 6) & 0x1;
    sign2 = ((rem_i + m_p1_i) >> 6) & 0x1;
    sign3 = ((rem_i + m_p2_i) >> 6) & 0x1;

    *root_dig_n2_o = (sign1 == 1) & (sign0 == 1);
    *root_dig_n1_o = (sign1 == 1) & (sign0 == 0);
    *root_dig_z0_o = (sign2 == 1) & (sign1 == 0);
    *root_dig_p1_o = (sign3 == 1) & (sign2 == 0);
    *root_dig_p2_o = (sign3 == 0) & (sign2 == 0);    
}

uint64_t fdiv_r4_qds(uint64_t rem_msb) {
    uint64_t sign0;
    uint64_t sign1;
    uint64_t sign2;
    uint64_t sign3;
    uint64_t quot_dig = 0;

    // 2's complement of -12
    uint64_t m_pos_2_neg = 0b110100;
    // 2's complement of -3
    uint64_t m_pos_1_neg = 0b111101;
    // 2's complement of 4
    uint64_t m_neg_0_neg = 4;
    // 2's complement of 13
    uint64_t m_neg_1_neg = 13;
    
    sign3 = ((rem_msb + m_pos_2_neg) >> 5) & 1;
    sign2 = ((rem_msb + m_pos_1_neg) >> 5) & 1;
    sign1 = ((rem_msb + m_neg_0_neg) >> 5) & 1;
    sign0 = ((rem_msb + m_neg_1_neg) >> 5) & 1;
    
    // if((sign1 == 1) & (sign0 == 1))
    //     quot_dig |= 0b10000;
    // if((sign1 == 1) & (sign0 == 0))
    //     quot_dig |= 0b01000;
    // if((sign2 == 1) & (sign1 == 0))
    //     quot_dig |= 0b00100;
    // if((sign3 == 1) & (sign2 == 0))
    //     quot_dig |= 0b00010;
    // if((sign3 == 0) & (sign2 == 0))
    //     quot_dig |= 0b00001;
    
    if((sign1 == 1) & (sign0 == 1))
        quot_dig = 0b10000;
    if((sign1 == 1) & (sign0 == 0))
        quot_dig = 0b01000;
    if((sign2 == 1) & (sign1 == 0))
        quot_dig = 0b00100;
    if((sign3 == 1) & (sign2 == 0))
        quot_dig = 0b00010;
    if((sign3 == 0) & (sign2 == 0))
        quot_dig = 0b00001;

    return quot_dig;
}

void fsqrt_r4_qds_constants_generator(
    bool a0_i,
    bool a2_i,
    bool a3_i,
    bool a4_i,
    uint8_t *m_n1_o,
    uint8_t *m_z0_o,
    uint8_t *m_p1_o,
    uint8_t *m_p2_o
) {

    *m_n1_o = 
    (a0_i == 1) ? 0b0010111 : 
    (((a2_i << 2) | (a3_i << 1) | a4_i) == 0) ? 0b0001101 : 
    (((a2_i << 2) | (a3_i << 1) | a4_i) == 1) ? 0b0001110 : 
    (((a2_i << 2) | (a3_i << 1) | a4_i) == 2) ? 0b0010000 : 
    (((a2_i << 2) | (a3_i << 1) | a4_i) == 3) ? 0b0010001 : 
    (((a2_i << 2) | (a3_i << 1) | a4_i) == 4) ? 0b0010010 : 
    (((a2_i << 2) | (a3_i << 1) | a4_i) == 5) ? 0b0010100 : 
    (((a2_i << 2) | (a3_i << 1) | a4_i) == 6) ? 0b0010110 : 
    0b0010111;
    
    *m_z0_o = 
    (a0_i == 1) ? 0b0001000 : 
    (((a2_i << 2) | (a3_i << 1) | a4_i) == 0) ? 0b0000100 : 
    (((a2_i << 2) | (a3_i << 1) | a4_i) == 1) ? 0b0000101 : 
    (((a2_i << 2) | (a3_i << 1) | a4_i) == 2) ? 0b0000110 : 
    (((a2_i << 2) | (a3_i << 1) | a4_i) == 3) ? 0b0000110 : 
    (((a2_i << 2) | (a3_i << 1) | a4_i) == 4) ? 0b0000110 : 
    (((a2_i << 2) | (a3_i << 1) | a4_i) == 5) ? 0b0001000 : 
    (((a2_i << 2) | (a3_i << 1) | a4_i) == 6) ? 0b0001000 : 
    0b0001000;
    
    *m_p1_o = 
    (a0_i == 1) ? 0b1111000 : 
    (((a2_i << 2) | (a3_i << 1) | a4_i) == 0) ? 0b1111100 : 
    (((a2_i << 2) | (a3_i << 1) | a4_i) == 1) ? 0b1111100 : 
    (((a2_i << 2) | (a3_i << 1) | a4_i) == 2) ? 0b1111100 : 
    (((a2_i << 2) | (a3_i << 1) | a4_i) == 3) ? 0b1111100 : 
    (((a2_i << 2) | (a3_i << 1) | a4_i) == 4) ? 0b1111010 : 
    (((a2_i << 2) | (a3_i << 1) | a4_i) == 5) ? 0b1111010 : 
    (((a2_i << 2) | (a3_i << 1) | a4_i) == 6) ? 0b1111000 : 
    0b1111000;
    
    *m_p2_o = 
    (a0_i == 1) ? 0b1101010 : 
    (((a2_i << 2) | (a3_i << 1) | a4_i) == 0) ? 0b1110100 : 
    (((a2_i << 2) | (a3_i << 1) | a4_i) == 1) ? 0b1110010 : 
    (((a2_i << 2) | (a3_i << 1) | a4_i) == 2) ? 0b1110000 : 
    (((a2_i << 2) | (a3_i << 1) | a4_i) == 3) ? 0b1110000 : 
    (((a2_i << 2) | (a3_i << 1) | a4_i) == 4) ? 0b1101110 : 
    (((a2_i << 2) | (a3_i << 1) | a4_i) == 5) ? 0b1101100 : 
    (((a2_i << 2) | (a3_i << 1) | a4_i) == 6) ? 0b1101100 : 
    0b1101010;

}

bool fp16_is_nan(const uint16_t x) {
	return ((((x >> 10) == 31) | ((x >> 10) == 63)) & ((x & ((1 << 10) - 1)) != 0));
}
bool fp32_is_nan(const uint32_t x) {
	return ((((x >> 23) == 255) | ((x >> 23) == 511)) & ((x & ((1 << 23) - 1)) != 0));
}
bool fp64_is_nan(const uint64_t x) {
	return ((((x >> 52) == 2047) | ((x >> 52) == 4095)) & ((x & (((uint64_t)1 << 52) - 1)) != 0));
}
