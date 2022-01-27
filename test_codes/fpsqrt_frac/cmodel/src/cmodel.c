#include "stdio.h"
#include "stdlib.h"
#include "stdint.h"

#include "svdpi.h"
#include "softfloat.h"
#include "genCases.h"

#define MAX_ERR_COUNT 10

uint32_t recorded_stim_idx[MAX_ERR_COUNT];
uint64_t recorded_op[MAX_ERR_COUNT];
uint32_t recorded_is_odd[MAX_ERR_COUNT];
uint64_t recorded_dut_res[MAX_ERR_COUNT];
uint64_t recorded_ref_res[MAX_ERR_COUNT];

const uint16_t fp16_defaultNaN = 0x7E00;
const uint32_t fp32_defaultNaN = 0x7FC00000;
const uint64_t fp64_defaultNaN = 0x7FF8000000000000;

const uint16_t fp16_min_pos_normal = 0x0400;
const uint16_t fp16_min_neg_normal = 0x8400;
const uint32_t fp32_min_pos_normal = 0x00800000;
const uint32_t fp32_min_neg_normal = 0x80800000;
const uint64_t fp64_min_pos_normal = 0x0010000000000000;
const uint64_t fp64_min_neg_normal = 0x8010000000000000;

// ================================================================================================================================================
// Function Declarations
// ================================================================================================================================================
void fpsqrt_frac_check(
	const svBitVecVal *acq_count,
	const svBitVecVal *err_count,
	const svBitVecVal *op_hi,
	const svBitVecVal *op_lo,
	const svBitVecVal *is_odd,
	const svBitVecVal *dut_res_hi,
	const svBitVecVal *dut_res_lo,
	svBitVecVal *ref_sqrt_res_hi,
	svBitVecVal *ref_sqrt_res_lo,
	svBitVecVal *compare_ok
);
void print_error(const svBitVecVal *err_count);


// ================================================================================================================================================
// Function Implementations
// ================================================================================================================================================
void fpsqrt_frac_check(
	const svBitVecVal *acq_count,
	const svBitVecVal *err_count,
	const svBitVecVal *op_hi,
	const svBitVecVal *op_lo,
	const svBitVecVal *is_odd,
	const svBitVecVal *dut_res_hi,
	const svBitVecVal *dut_res_lo,
	svBitVecVal *ref_sqrt_res_hi,
	svBitVecVal *ref_sqrt_res_lo,
	svBitVecVal *compare_ok
) {
	float128_t fp128_op, fp128_sqrt_res;
	uint64_t ref_frac_res;
	uint64_t dut_frac_res;
	if(*is_odd == 1)
		fp128_op.v[1] = (uint64_t)(1 + 16383) << 48;
	else
		fp128_op.v[1] = (uint64_t)(0 + 16383) << 48;

	// *op_hi[19:0] = frac[51:32]
	// *op_lo[31:0] = frac[31:0]
	fp128_op.v[1] = fp128_op.v[1] | (((uint64_t)(*op_hi & 0xFFFFF)) << 28);
	fp128_op.v[1] = fp128_op.v[1] | (*op_lo >> 4);
	fp128_op.v[0] = (uint64_t)(*op_lo) << 60;

	softfloat_roundingMode = softfloat_round_minMag;
	f128M_sqrt(&fp128_op, &fp128_sqrt_res);

	// Only need to compare 54-bit frac
	ref_frac_res = (uint64_t)(1) << 53;
	ref_frac_res = ref_frac_res | (fp128_sqrt_res.v[1] << 5);
	ref_frac_res = ref_frac_res | (fp128_sqrt_res.v[0] >> 59);
	ref_frac_res = ref_frac_res & (((uint64_t)1 << 54) - 1);

	*ref_sqrt_res_hi = (uint32_t)(ref_frac_res >> 32);
	*ref_sqrt_res_lo = (uint32_t)(ref_frac_res & 0xFFFFFFFF);

	dut_frac_res = ((uint64_t)(*dut_res_hi) << 32) | *dut_res_lo;
	dut_frac_res = dut_frac_res & (((uint64_t)1 << 54) - 1);

	*compare_ok = (ref_frac_res == dut_frac_res);
	if(*compare_ok == 0) {
		recorded_stim_idx[*err_count] = *acq_count;
		recorded_op[*err_count] = (((uint64_t)(*op_hi)) << 32) | *op_lo;
		recorded_is_odd[*err_count] = *is_odd;
		recorded_dut_res[*err_count] = dut_frac_res;
		recorded_ref_res[*err_count] = ref_frac_res;
	}
}


void print_error(const svBitVecVal *err_count) {
	FILE *fptr;
	fptr = fopen("result.log", "w+");
	for(uint32_t i = 0; i < *err_count; i++) {
		fprintf(fptr, "[%d]:\n", i);
		fprintf(fptr, "stim_idx = %d\n", recorded_stim_idx[i]);
		fprintf(fptr, "op = %014llX\n", recorded_op[i]);
		fprintf(fptr, "id_odd = %d\n", recorded_is_odd[i]);
		fprintf(fptr, "dut_res = %014llX\n", recorded_dut_res[i]);
		fprintf(fptr, "ref_res = %014llX\n", recorded_ref_res[i]);
	}
	fclose(fptr);
}
