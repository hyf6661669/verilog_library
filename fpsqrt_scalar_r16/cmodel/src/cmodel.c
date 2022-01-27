#include "stdio.h"
#include "stdlib.h"
#include "stdint.h"

#include "svdpi.h"
#include "softfloat.h"
#include "genCases.h"

#define MAX_ERR_COUNT 10

uint32_t recorded_stim_idx[MAX_ERR_COUNT];
uint64_t recorded_op[MAX_ERR_COUNT];
uint32_t recorded_fp_format[MAX_ERR_COUNT];
uint32_t recorded_rm[MAX_ERR_COUNT];
uint64_t recorded_dut_res[MAX_ERR_COUNT];
uint32_t recorded_dut_fflags[MAX_ERR_COUNT];
uint64_t recorded_ref_res[MAX_ERR_COUNT];
uint32_t recorded_ref_fflags[MAX_ERR_COUNT];

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
void fpsqrt_check(
	const svBitVecVal *acq_count,
	const svBitVecVal *err_count,
	const svBitVecVal *op_hi,
	const svBitVecVal *op_lo,
	const svBitVecVal *fp_format,
	const svBitVecVal *rm,
	const svBitVecVal *dut_res_hi,
	const svBitVecVal *dut_res_lo,
	const svBitVecVal *dut_fflags,
	svBitVecVal *compare_ok
);
void print_error(const svBitVecVal *err_count);
uint32_t fp16_is_nan(const uint16_t x);
uint32_t fp32_is_nan(const uint32_t x);
uint32_t fp64_is_nan(const uint64_t x);


// ================================================================================================================================================
// Function Implementations
// ================================================================================================================================================
void fpsqrt_check(
	const svBitVecVal *acq_count,
	const svBitVecVal *err_count,
	const svBitVecVal *op_hi,
	const svBitVecVal *op_lo,
	const svBitVecVal *fp_format,
	const svBitVecVal *rm,
	const svBitVecVal *dut_res_hi,
	const svBitVecVal *dut_res_lo,
	const svBitVecVal *dut_fflags,
	svBitVecVal *compare_ok
) {
	float16_t f16_op;
	float32_t f32_op;
	float64_t f64_op;
	float16_t f16_fpsqrt_res;
	float32_t f32_fpsqrt_res;
	float64_t f64_fpsqrt_res;

	uint32_t data_ok;
	uint32_t fflags_ok;

	uint64_t dut_res, ref_res;

	f16_op.v = (uint16_t)(*op_lo);
	f32_op.v = *op_lo;
	f64_op.v = ((uint64_t)(*op_hi) << 32) | *op_lo;

	// Clear the fflags.
	softfloat_exceptionFlags = 0;
	softfloat_roundingMode = *rm;

	if(*fp_format == 0) {
		f16_fpsqrt_res = f16_sqrt(f16_op);
		if(fp16_is_nan(f16_fpsqrt_res.v))
			data_ok = ((*dut_res_lo & 0xFFFF) == fp16_defaultNaN);
		else
			data_ok = ((*dut_res_lo & 0xFFFF) == f16_fpsqrt_res.v);

		dut_res = *dut_res_lo & 0xFFFF;
		ref_res = f16_fpsqrt_res.v;
	} else if(*fp_format == 1) {
		f32_fpsqrt_res = f32_sqrt(f32_op);
		if(fp32_is_nan(f32_fpsqrt_res.v))
			data_ok = (*dut_res_lo == fp32_defaultNaN);
		else
			data_ok = (*dut_res_lo == f32_fpsqrt_res.v);
		
		dut_res = *dut_res_lo;
		ref_res = f32_fpsqrt_res.v;
	} else {
		f64_fpsqrt_res = f64_sqrt(f64_op);
		if(fp64_is_nan(f64_fpsqrt_res.v))
			data_ok = ((((uint64_t)(*dut_res_hi) << 32) | *dut_res_lo) == fp64_defaultNaN);
		else
			data_ok = ((((uint64_t)(*dut_res_hi) << 32) | *dut_res_lo) == f64_fpsqrt_res.v);
		
		dut_res = (((uint64_t)(*dut_res_hi) << 32) | *dut_res_lo);
		ref_res = f64_fpsqrt_res.v;
	}

	fflags_ok = (*dut_fflags == softfloat_exceptionFlags);

	*compare_ok = data_ok & fflags_ok;
	if(*compare_ok == 0) {
		recorded_stim_idx[*err_count] = *acq_count;
		recorded_op[*err_count] = (((uint64_t)(*op_hi)) << 32) | *op_lo;
		recorded_fp_format[*err_count] = *fp_format;
		recorded_rm[*err_count] = *rm;
		recorded_dut_res[*err_count] = dut_res;
		recorded_dut_fflags[*err_count] = *dut_fflags;
		recorded_ref_res[*err_count] = ref_res;
		recorded_ref_fflags[*err_count] = softfloat_exceptionFlags;
	}
}


void print_error(const svBitVecVal *err_count) {
	FILE *fptr;
	fptr = fopen("result.log", "w+");
	for(uint32_t i = 0; i < *err_count; i++) {
		fprintf(fptr, "[%d]:\n", i);
		fprintf(fptr, "stim_idx = %d\n", recorded_stim_idx[i]);
		fprintf(fptr, "op = %016llX\n", recorded_op[i]);
		fprintf(fptr, "fp_format = %d\n", recorded_fp_format[i]);
		fprintf(fptr, "rm = %d\n", recorded_rm[i]);
		fprintf(fptr, "dut_res = %016llX\n", recorded_dut_res[i]);
		fprintf(fptr, "dut_fflags = %X\n", recorded_dut_fflags[i]);
		fprintf(fptr, "ref_res = %016llX\n", recorded_ref_res[i]);
		fprintf(fptr, "ref_fflags = %X\n", recorded_ref_fflags[i]);
	}
	fclose(fptr);
}

uint32_t fp16_is_nan(const uint16_t x) {
	return ((((x >> 10) == 31) | ((x >> 10) == 63)) & ((x & ((1 << 10) - 1)) != 0));
}
uint32_t fp32_is_nan(const uint32_t x) {
	return ((((x >> 23) == 255) | ((x >> 23) == 511)) & ((x & ((1 << 23) - 1)) != 0));
}
uint32_t fp64_is_nan(const uint64_t x) {
	return ((((x >> 52) == 2047) | ((x >> 52) == 4095)) & ((x & (((uint64_t)1 << 52) - 1)) != 0));
}