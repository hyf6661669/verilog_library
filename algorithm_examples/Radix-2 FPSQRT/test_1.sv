a_frac = 11111111111111111111111111111111111111111111111111111
sqrt(11.1111111111111111111111111111111111111111111111111110) = 1.1111111111111111111111111111111111111111111111111111_0111111111111111111111111111111111111111111111...

init_rem_sum_adj = 010111111111111111111111111111111111111111111111111111000000000

// ================================================================================================================================================
// iter[0]:
// ================================================================================================================================================
rem_sum_f3 = 010111111111111111111111111111111111111111111111111111000000000
rem_carry_f3 = 000000000000000000000000000000000000000000000000000000000000000

raw_mask_f3 = 000000000000000000
quot_f3 = 1000000000000000000000000000000000000000000000000000000
quot_m1_f3 = 0000000000000000000000000000000000000000000000000000000

mask_f3[0] = 10000000000000000000000000000000000000000000000000000000
msk_dig[0] = mask_f3[0][55:0] ^ {1'b1, mask_f3[0][55:1]} = 
10000000000000000000000000000000000000000000000000000000 ^ 
11000000000000000000000000000000000000000000000000000000 = 
01000000000000000000000000000000000000000000000000000000
msk_dig_3[0] = msk_dig[0][55:1] | msk_dig[0][54:0] = 
0100000000000000000000000000000000000000000000000000000 |
1000000000000000000000000000000000000000000000000000000 = 
1100000000000000000000000000000000000000000000000000000

mask_f3[1] 		= 11000000000000000000000000000000000000000000000000000000
msk_dig[1] 		= 00100000000000000000000000000000000000000000000000000000
msk_dig_3[1] 	= 0110000000000000000000000000000000000000000000000000000

mask_f3[2] 		= 11100000000000000000000000000000000000000000000000000000
msk_dig[2] 		= 00010000000000000000000000000000000000000000000000000000
msk_dig_3[2] 	= 0011000000000000000000000000000000000000000000000000000


rem_sum_f3[62:60] = 010
rem_carry_f3[62:60] = 000
->
quot_dig0[0] = 01
->
prev_quot[0] = quot_f3 = 1000000000000000000000000000000000000000000000000000000
prev_quot_m1[0] = quot_m1_f3 = 0000000000000000000000000000000000000000000000000000000
new_quot0_f3[0] = prev_quot[0] & mask_f3[0][55:1] | msk_dig[0][55:1] = 1100000000000000000000000000000000000000000000000000000
new_quot0_m1_f3[0] = prev_quot[0] & mask_f3[0][55:1] = 1000000000000000000000000000000000000000000000000000000

csa_minus_val_sqrt0[0] = {quot_f3[53: 1], 2'b0} | msk_dig[0][55: 1] = 
0000000000000000000000000000000000000000000000000000000 | 
0100000000000000000000000000000000000000000000000000000 = 
0100000000000000000000000000000000000000000000000000000
csa_val0[0] = ~csa_minus_val0[0][50:0] = 111111111111111111111111111111111111111111111111111
csa_mux[0] = 111111111111111111111111111111111111111111111111111000000

rem_sum_in[0] = rem_sum_f3[61:0] = 10111111111111111111111111111111111111111111111111111000000000
rem_carry_in[0] = rem_carry_f3[61:0] = 00000000000000000000000000000000000000000000000000000000000000

rem_sum_in[0][61:56] 		= 101111
rem_carry_in[0][61:56] 		= 000000
csa_minus_val0[0][54:51] 	=   0100
rem0_sum_minus[0][5:0] 		= 000100
rem0_carry_minus[0][5:0] 	= 010111
rem_sum_msb0[0][5:0] 		= 000100
rem_carry_msb0[0][5:0] 		= 010111

rem_sum_xor[0][56:0] = 
111111111111111111111111111111111111111111111110000000000 ^ 
000000000000000000000000000000000000000000000000000000000 ^ 
111111111111111111111111111111111111111111111111111000000 = 
000000000000000000000000000000000000000000000001111000000
rem_carry_andor[0][57:0] = 1111111111111111111111111111111111111111111111100000000001

new_rem_sum0[0][56:0] = {rem_sum_msb0[0][5:0], rem_sum_xor[0][56: 6]} = 000100000000000000000000000000000000000000000000000001111
new_rem_sum_f3[0] = {new_rem_sum0[0][56:0], 6'b0} = 000100000000000000000000000000000000000000000000000001111000000
new_rem_carry0[0][55:0] = {rem_carry_msb0[0][5:1], rem_carry_andor[0][57: 7]} = 01011111111111111111111111111111111111111111111111110000
new_rem_carry_f3[0] = {new_rem_carry0[0][55:0], quot_dig0[0][0], 6'b0} = 010111111111111111111111111111111111111111111111111100001000000

此时:
new_rem_sum_f3[0] + new_rem_carry_f3[0] = 
000100000000000000000000000000000000000000000000000001111000000 +
010111111111111111111111111111111111111111111111111100001000000 = 
011011111111111111111111111111111111111111111111111110000000000

q_real = 1.1
q_real ^ 2 = 10.0100000000000000000000000000000000000000000000000000
a = 11.1111111111111111111111111111111111111111111111111110
rem = 01.1011111111111111111111111111111111111111111111111110

// ====================================
rem_sum_in[1] = new_rem_sum_f3[0][61:0] = 01110110011010101010101010110011010101010101010110011111000000
rem_carry_in[1] = new_rem_carry_f3[0][61:0] = 00010011001010101010101010011001010101010101010011000001000000

rem_sum_msb0[0][5:3] = 001
rem_carry_msb0[0][5:3] = 100
->
quot_dig0[1] = 10
->
prev_quot[1] = new_quot0_f3[0] = 1100000000000000000000000000000000000000000000000000000
prev_quot_m1[1] = new_quot0_m1_f3[0] = 1000000000000000000000000000000000000000000000000000000
new_quot0_f3[1] = prev_quot_m1[1] & mask_f3[1][55:1] | msk_dig[1][55:1] = 1010000000000000000000000000000000000000000000000000000
new_quot0_m1_f3[1] = prev_quot_m1[1] & mask_f3[1][55:1] = 1000000000000000000000000000000000000000000000000000000


csa_plus_val_sqrt0[1] = {new_quot0_m1_f3[0][53:1], 2'b0} | msk_dig_3[1][54: 0] = 
0000000000000000000000000000000000000000000000000000000 | 
0110000000000000000000000000000000000000000000000000000 = 
0110000000000000000000000000000000000000000000000000000
csa_val0[1] = csa_plus_val0[1][50:0] = 000000000000000000000000000000000000000000000000000
csa_mux[1] = 000000000000000000000000000000000000000000000000000000000

rem_sum_in[1][61:56] 		= 011101
rem_carry_in[1][61:56] 		= 000100
csa_plus_val0[1][54:51] 	=   0110
rem0_sum_plus[1][5:0] 		= 001111
rem0_carry_plus[1][5:0] 	= 101000
rem_sum_msb0[1][5:0] 		= 001111
rem_carry_msb0[1][5:0] 		= 101000


rem_sum_xor[1][56:0] = 
100110101010101010101100110101010101010101100111110000000 ^ 
110010101010101010100110010101010101010100110000010000000 ^ 
000000000000000000000000000000000000000000000000000000000 = 
010100000000000000001010100000000000000001010111100000000
rem_carry_andor[1][57:0] = 1000101010101010101001000101010101010101001000000100000000

new_rem_sum0[1][56:0] = {rem_sum_msb0[1][5:0], rem_sum_xor[1][56: 6]} = 001111010100000000000000001010100000000000000001010111100
new_rem_sum_f3[1] = {new_rem_sum0[1][56:0], 6'b0} = 001111010100000000000000001010100000000000000001010111100000000
new_rem_carry0[1][55:0] = {rem_carry_msb0[1][5:1], rem_carry_andor[1][57: 7]} = 10100100010101010101010100100010101010101010100100000010
new_rem_carry_f3[1] = {new_rem_carry0[1][55:0], quot_dig0[1][0], 6'b0} = 101001000101010101010101001000101010101010101001000000100000000

// ====================================
rem_sum_in[2] = new_rem_sum_f3[1][61:0] = 01111010100000000000000001010100000000000000001010111100000000
rem_carry_in[2] = new_rem_carry_f3[1][61:0] = 01001000101010101010101001000101010101010101001000000100000000

rem_sum_msb0[1][5:3] = 001
rem_carry_msb0[1][5:3] = 101
->
quot_dig0[2] = 10
->
prev_quot[2] = new_quot0_f3[1] = 1010000000000000000000000000000000000000000000000000000
prev_quot_m1[2] = new_quot0_m1_f3[1] = 1000000000000000000000000000000000000000000000000000000
new_quot0_f3[2] = prev_quot_m1[2] & mask_f3[2][55:1] | msk_dig[2][55:1] = 1001000000000000000000000000000000000000000000000000000
new_quot0_m1_f3[2] = prev_quot_m1[2] & mask_f3[2][55:1] = 1000000000000000000000000000000000000000000000000000000

csa_plus_val_sqrt0[2] = {new_quot0_m1_f3[1][53:1], 2'b0} | msk_dig_3[2][54: 0] = 
0000000000000000000000000000000000000000000000000000000 |
0011000000000000000000000000000000000000000000000000000 = 
0011000000000000000000000000000000000000000000000000000

csa_val0[2] = csa_plus_val0[2][50:0] = 000000000000000000000000000000000000000000000000000
csa_mux[1] = 000000000000000000000000000000000000000000000000000000000

rem_sum_in[2][61:56] 		= 011110
rem_carry_in[2][61:56] 		= 010010
csa_plus_val0[2][54:51] 	=   0011
rem0_sum_plus[2][5:0] 		= 011111
rem0_carry_plus[2][5:0] 	= 100100
rem_sum_msb0[2][5:0] 		= 011111
rem_carry_msb0[2][5:0] 		= 100100

rem_sum_xor[2][56:0] = 
101000000000000000010101000000000000000010101111000000000 ^ 
001010101010101010010001010101010101010010000001000000000 ^ 
000000000000000000000000000000000000000000000000000000000 = 
100010101010101010000100010101010101010000101110000000000
rem_carry_andor[2][57:0] = 0010000000000000000100010000000000000000100000010000000000

new_rem_sum0[2][56:0] = {rem_sum_msb0[2][5:0], rem_sum_xor[2][56: 6]} = 011111100010101010101010000100010101010101010000101110000
new_rem_sum_f3[2] = {new_rem_sum0[2][56:0], 6'b0} = 011111100010101010101010000100010101010101010000101110000000000
new_rem_carry0[2][55:0] = {rem_carry_msb0[2][5:1], rem_carry_andor[2][57: 7]} = 10010001000000000000000010001000000000000000010000001000
new_rem_carry_f3[2] = {new_rem_carry0[2][55:0], quot_dig0[2][0], 6'b0} = 100100010000000000000000100010000000000000000100000010000000000

此时:
new_rem_sum_f3[2] + new_rem_carry_f3[2] = 
011111100010101010101010000100010101010101010000101110000000000 + 100100010000000000000000100010000000000000000100000010000000000 = 
000011110010101010101010100110010101010101010100110000000000000
q = 1.001
q ^ 2 = 1.0100010000000000000000000000000000000000000000000000
a_frac - q ^ 2 = 10101001100101010101010101001100101010101010101001100 - 10100010000000000000000000000000000000000000000000000 = 
00000111100101010101010101001100101010101010101001100

// ================================================================================================================================================
// iter[1]:
// ================================================================================================================================================
rem_sum_f3 = 011111100010101010101010000100010101010101010000101110000000000
rem_carry_f3 = 100100010000000000000000100010000000000000000100000010000000000

raw_mask_f3 = 100000000000000000
quot_f3 = 1001000000000000000000000000000000000000000000000000000
quot_m1_f3 = 1000000000000000000000000000000000000000000000000000000

mask_f3[0] = 11110000000000000000000000000000000000000000000000000000
msk_dig[0] = mask_f3[0][55:0] ^ {1'b1, mask_f3[0][55:1]} = 
11110000000000000000000000000000000000000000000000000000 ^ 
11111000000000000000000000000000000000000000000000000000 = 
00001000000000000000000000000000000000000000000000000000
msk_dig_3[0] = msk_dig[0][55:1] | msk_dig[0][54:0] = 
0000100000000000000000000000000000000000000000000000000 |
0001000000000000000000000000000000000000000000000000000 = 
0001100000000000000000000000000000000000000000000000000

mask_f3[1] 		= 11111000000000000000000000000000000000000000000000000000
msk_dig[1] 		= 00000100000000000000000000000000000000000000000000000000
msk_dig_3[1] 	= 0000110000000000000000000000000000000000000000000000000

mask_f3[2] 		= 11111100000000000000000000000000000000000000000000000000
msk_dig[2] 		= 00000010000000000000000000000000000000000000000000000000
msk_dig_3[2] 	= 0000011000000000000000000000000000000000000000000000000


rem_sum_f3[62:60] = 011
rem_carry_f3[62:60] = 100
-> 
quot_dig0[0] = 00
->
prev_quot[0] = quot_f3 = 1001000000000000000000000000000000000000000000000000000
prev_quot_m1[0] = quot_m1_f3 = 1000000000000000000000000000000000000000000000000000000
new_quot0_f3[0] = prev_quot[0] & mask_f3[0][55:1] = 1001000000000000000000000000000000000000000000000000000
new_quot0_m1_f3[0] = prev_quot_m1[i] & mask_f3[0][55:1] | msk_dig[0][55:1] = 1000100000000000000000000000000000000000000000000000000

csa_val0[0] = 000000000000000000000000000000000000000000000000000
csa_mux[0] = 000000000000000000000000000000000000000000000000000000000

rem_sum_in[0] = rem_sum_f3[61:0] = 11111100010101010101010000100010101010101010000101110000000000
rem_carry_in[0] = rem_carry_f3[61:0] = 00100010000000000000000100010000000000000000100000010000000000

rem_sum_in[0][61:56] 		= 111111
rem_carry_in[0][61:56] 		= 001000

rem0_sum_zero[0][5:0] 		= 010111
rem0_carry_zero[0][5:0] 	= 110000
rem_sum_msb0[0][5:0] 		= 010111
rem_carry_msb0[0][5:0] 		= 110000

rem_sum_xor[0][56:0] = 
000101010101010100001000101010101010100001011100000000000 ^ 
100000000000000001000100000000000000001000000100000000000 ^ 
000000000000000000000000000000000000000000000000000000000 = 
100101010101010101001100101010101010101001011000000000000
rem_carry_andor[0][57:0] = 0000000000000000000000000000000000000000000001000000000000

new_rem_sum0[0][56:0] = {rem_sum_msb0[0][5:0], rem_sum_xor[0][56: 6]} = 010111100101010101010101001100101010101010101001011000000
new_rem_sum_f3[0] = {new_rem_sum0[0][56:0], 6'b0} = 010111100101010101010101001100101010101010101001011000000000000
new_rem_carry0[0][55:0] = {rem_carry_msb0[0][5:1], rem_carry_andor[0][57: 7]} = 11000000000000000000000000000000000000000000000000100000
new_rem_carry_f3[0] = {new_rem_carry0[0][55:0], quot_dig0[0][0], 6'b0} = 110000000000000000000000000000000000000000000000001000000000000


// ====================================
rem_sum_in[1] = new_rem_sum_f3[0][61:0] = 10111100101010101010101001100101010101010101001011000000000000
rem_carry_in[1] = new_rem_carry_f3[0][61:0] = 10000000000000000000000000000000000000000000000001000000000000

rem_sum_msb0[0][5:3] = 010
rem_carry_msb0[0][5:3] = 110
->
quot_dig0[1] = 01
->
prev_quot[1] = new_quot0_f3[0] = 1001000000000000000000000000000000000000000000000000000
prev_quot_m1[1] = new_quot0_m1_f3[0] = 1000100000000000000000000000000000000000000000000000000
new_quot0_f3[1] = prev_quot[1] & mask_f3[1][55:1] | msk_dig[1][55:1] = 1001010000000000000000000000000000000000000000000000000
new_quot0_m1_f3[1] = prev_quot[1] & mask_f3[1][55:1] = 1001000000000000000000000000000000000000000000000000000

csa_minus_val_sqrt0[1] = {new_quot0_f3[0][53:1], 2'b0} | msk_dig[1][55: 1] = 
0010000000000000000000000000000000000000000000000000000 | 
0000010000000000000000000000000000000000000000000000000 = 
0010010000000000000000000000000000000000000000000000000
csa_val0[1] = ~csa_minus_val0[1][50:0] = 101111111111111111111111111111111111111111111111111
csa_mux[1] = 101111111111111111111111111111111111111111111111111000000

rem_sum_in[1][61:56] 		= 101111
rem_carry_in[1][61:56] 		= 100000
csa_minus_val0[1][54:51] 	=   0010
rem0_sum_minus[1][5:0] 		= 000010
rem0_carry_minus[1][5:0] 	= 111010
rem_sum_msb0[1][5:0] 		= 000010
rem_carry_msb0[1][5:0] 		= 111010

rem_sum_xor[1][56:0] = 
001010101010101010011001010101010101010010110000000000000 ^ 
000000000000000000000000000000000000000000010000000000000 ^ 
101111111111111111111111111111111111111111111111111000000 = 
100101010101010101100110101010101010101101011111111000000
rem_carry_andor[1][57:0] = 0010101010101010100110010101010101010100101100000000000001

new_rem_sum0[1][56:0] = {rem_sum_msb0[1][5:0], rem_sum_xor[1][56: 6]} = 000010100101010101010101100110101010101010101101011111111
new_rem_sum_f3[1] = {new_rem_sum0[1][56:0], 6'b0} = 000010100101010101010101100110101010101010101101011111111000000
new_rem_carry0[1][55:0] = {rem_carry_msb0[1][5:1], rem_carry_andor[1][57: 7]} = 11101001010101010101010011001010101010101010010110000000
new_rem_carry_f3[1] = {new_rem_carry0[1][55:0], quot_dig0[1][0], 6'b0} = 111010010101010101010100110010101010101010100101100000001000000

此时:
new_rem_sum_f3[1] + new_rem_carry_f3[1] = 
000010100101010101010101100110101010101010101101011111111000000 + 111010010101010101010100110010101010101010100101100000001000000 = 
111100111010101010101010011001010101010101010011000000000000000 < 0
q_real = 1.00100
q_real ^ 2 = 1.0100010000000000000000000000000000000000000000000000
a_frac = 1.0101001100101010101010101001100101010101010101001100
diff = 0.0000111100101010101010101001100101010101010101001100

{new_quot0_m1_f3[1], 1'b0} | msk_dig[2] = 
10010000000000000000000000000000000000000000000000000000 |
00000010000000000000000000000000000000000000000000000000 =
10010010000000000000000000000000000000000000000000000000
{1'b0, ({new_quot0_m1_f3[1], 1'b0} | msk_dig[2]), 6'b0} = 010010010000000000000000000000000000000000000000000000000000000
111100111010101010101010011001010101010101010011000000000000000 +
010010010000000000000000000000000000000000000000000000000000000 = 
001111001010101010101010011001010101010101010011000000000000000
00000111100101010101010101001100101010101010101001100

// ====================================
rem_sum_in[2] = new_rem_sum_f3[1][61:0] = 00010100101010101010101100110101010101010101101011111111000000
rem_carry_in[2] = new_rem_carry_f3[1][61:0] = 11010010101010101010100110010101010101010100101100000001000000

rem_sum_msb0[1][5:3] = 000
rem_carry_msb0[1][5:3] = 111
->
quot_dig0[2] = 00
->
prev_quot[2] = new_quot0_f3[1] = 1001010000000000000000000000000000000000000000000000000
prev_quot_m1[2] = new_quot0_m1_f3[1] = 1001000000000000000000000000000000000000000000000000000
new_quot0_f3[2] = prev_quot[2] & mask_f3[2][55:1] = 1001010000000000000000000000000000000000000000000000000
new_quot0_m1_f3[2] = prev_quot_m1[2] & mask_f3[2][55:1] | msk_dig[2][55:1] = 1001001000000000000000000000000000000000000000000000000

csa_val0[2] = csa_plus_val0[2][50:0] = 000000000000000000000000000000000000000000000000000
csa_mux[1] = 000000000000000000000000000000000000000000000000000000000

rem_sum_in[2][61:56] 		= 000101
rem_carry_in[2][61:56] 		= 110100

rem0_sum_zero[2][5:0] 		= 010001
rem0_carry_zero[2][5:0] 	= 101000
rem_sum_msb0[2][5:0] 		= 010001
rem_carry_msb0[2][5:0] 		= 101000

rem_sum_xor[2][56:0] = 
001010101010101011001101010101010101011010111111110000000 ^ 
101010101010101001100101010101010101001011000000010000000 ^ 
000000000000000000000000000000000000000000000000000000000 = 
100000000000000010101000000000000000010001111111100000000
rem_carry_andor[2][57:0] = 0010101010101010010001010101010101010010100000000100000000

new_rem_sum0[2][56:0] = {rem_sum_msb0[2][5:0], rem_sum_xor[2][56: 6]} = 010001100000000000000010101000000000000000010001111111100
new_rem_sum_f3[2] = {new_rem_sum0[2][56:0], 6'b0} = 010001100000000000000010101000000000000000010001111111100000000
new_rem_carry0[2][55:0] = {rem_carry_msb0[2][5:1], rem_carry_andor[2][57: 7]} = 10100001010101010101001000101010101010101001010000000010
new_rem_carry_f3[2] = {new_rem_carry0[2][55:0], quot_dig0[2][0], 6'b0} = 101000010101010101010010001010101010101010010100000000100000000

此时:
new_rem_sum_f3[2] + new_rem_carry_f3[2] = 
010001100000000000000010101000000000000000010001111111100000000 + 101000010101010101010010001010101010101010010100000000100000000 = 
111001110101010101010100110010101010101010100110000000000000000 < 0
q_real = 1.001_001
q_real ^ 2 = 1.0100110100010000000000000000000000000000000000000000
a_frac - q ^ 2 = 10101001100101010101010101001100101010101010101001100 - 10100110100010000000000000000000000000000000000000000 = 
0.0000011000011010101010101001100101010101010101001100

// 下个iter中: 
msk_dig[0] = 00000001000000000000000000000000000000000000000000000000
{new_quot0_m1_f3[2], 1'b0} | msk_dig[0] = 
10010010000000000000000000000000000000000000000000000000 |
00000001000000000000000000000000000000000000000000000000 = 
10010011000000000000000000000000000000000000000000000000
{1'b0, ({new_quot0_m1_f3[2], 1'b0} | msk_dig[0]), 6'b0} = 
010010011000000000000000000000000000000000000000000000000000000

111001110101010101010100110010101010101010100110000000000000000 + 
010010011000000000000000000000000000000000000000000000000000000 = 
001100001101010101010100110010101010101010100110000000000000000

// ================================================================================================================================================
// iter[1]:
// ================================================================================================================================================
rem_sum_f3 = 010001100000000000000010101000000000000000010001111111100000000
rem_carry_f3 = 101000010101010101010010001010101010101010010100000000100000000

raw_mask_f3 = 110000000000000000
quot_f3 = 1001010000000000000000000000000000000000000000000000000
quot_m1_f3 = 1001001000000000000000000000000000000000000000000000000

mask_f3[0] = 11111110000000000000000000000000000000000000000000000000
msk_dig[0] = mask_f3[0][55:0] ^ {1'b1, mask_f3[0][55:1]} = 
11111110000000000000000000000000000000000000000000000000 ^ 
11111111000000000000000000000000000000000000000000000000 = 
00000001000000000000000000000000000000000000000000000000
msk_dig_3[0] = msk_dig[0][55:1] | msk_dig[0][54:0] = 
0000000100000000000000000000000000000000000000000000000 |
0000001000000000000000000000000000000000000000000000000 = 
0000001100000000000000000000000000000000000000000000000

mask_f3[1] 		= 11111111000000000000000000000000000000000000000000000000
msk_dig[1] 		= 00000000100000000000000000000000000000000000000000000000
msk_dig_3[1] 	= 0000000110000000000000000000000000000000000000000000000

mask_f3[2] 		= 11111111100000000000000000000000000000000000000000000000
msk_dig[2] 		= 00000000010000000000000000000000000000000000000000000000
msk_dig_3[2] 	= 0000000011000000000000000000000000000000000000000000000




