#include "stdio.h"
#include "stdlib.h"
#include "stdint.h"

#include "softfloat.h"
#include "genCases.h"

int main() {
	softfloat_roundingMode = softfloat_round_minMag;
	float128_t fp128_a, fp128_b;
	// v[1] is high part
	fp128_a.v[1] = ((uint64_t)(1 + 16383) << 48) | (uint64_t)(0b100011110011111111000000000000000000000000000000);
	fp128_a.v[0] = 0;

	f128M_sqrt(&fp128_a, &fp128_b);

	printf("sqrt_0 = %016llX\n", fp128_b.v[1]);
	printf("sqrt_1 = %016llX\n", fp128_b.v[0]);

	return 0;
}
// TODO

