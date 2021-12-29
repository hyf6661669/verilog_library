
a0_frac = 10101001100101010101010101001100101010101010101001100
b0_frac = 10000000000000000000010101001100101010101010101001100
a0_frac / b0_frac = 1.0101001100101010100111001000111010000101101100100010111101000010011111000001011000111011111111001011111111101000...


init_rem_sum_adj = 010101001100101010101010101001100101010101010101001100100000000
init_rem_carry = 101111111111111111111101010110011010101010101010110011100000000
csa_val_div = 0000000000000000000010101001100101010101010101001100000

// iter[0]:
rem_sum_f3 = 010101001100101010101010101001100101010101010101001100100000000
rem_carry_f3 = 101111111111111111111101010110011010101010101010110011100000000

quot_dig0[0] = 00

对于所有的i:
csa_plus_val0[i] = 0000000000000000000010101001100101010101010101001100000
csa_minus_val0[i] = 0000000000000000000010101001100101010101010101001100000

csa_val0[0] = 000000000000000000000000000000000000000000000000000
csa_mux[0] = 000000000000000000000000000000000000000000000000000000000
rem_sum_in[0] = rem_sum_f3[61:0] = 10101001100101010101010101001100101010101010101001100100000000
rem_carry_in[0] = rem_carry_f3[61:0] = 01111111111111111111101010110011010101010101010110011100000000

rem_sum_in[0][61:56] = 101010
rem_carry_in[0][61:56] = 011111

rem0_sum_zero[0][5:0] = {01, 1010 ^ 1111} = 010101
rem0_carry_zero[0][5:0] = {1, 1010 & 1111, 0} = 110100
rem_sum_msb0[0][5:0] = 010101
rem_carry_msb0[0][5:0] = 110100

rem_sum_xor[0][56:0] = 
011001010101010101010011001010101010101010011001000000000 ^ 
111111111111111010101100110101010101010101100111000000000 ^ 
000000000000000000000000000000000000000000000000000000000 = 
100110101010101111111111111111111111111111111110000000000
rem_carry_andor[0][57:0] = 0110010101010100000000000000000000000000000000010000000000


new_rem_sum0[0][56:0] = {rem_sum_msb0[0][5:0], rem_sum_xor[0][56: 6]} = 010101100110101010101111111111111111111111111111111110000
new_rem_sum_f3[0] = {new_rem_sum0[0][56:0], 6'b0} = 010101100110101010101111111111111111111111111111111110000000000
new_rem_carry0[0][55:0] = {rem_carry_msb0[0][5:1], rem_carry_andor[0][57: 7]} = 11010011001010101010000000000000000000000000000000001000
new_rem_carry_f3[0] = {new_rem_carry0[0][55:0], quot_dig0[0][0], 6'b0} = 110100110010101010100000000000000000000000000000000010000000000

// ====================================
rem_sum_in[1] = new_rem_sum_f3[0][61:0] = 10101100110101010101111111111111111111111111111111110000000000
rem_carry_in[1] = new_rem_carry_f3[0][61:0] = 10100110010101010100000000000000000000000000000000010000000000

rem_sum_msb0[0][5:3] = 010
rem_carry_msb0[0][5:3] = 110
-> 
quot_dig0[1] = 01
csa_val0[1] = ~csa_minus_val0[1][50:0] = 111111111111111101010110011010101010101010110011111
csa_mux[1] = {csa_val0[1], 6'b0} = 111111111111111101010110011010101010101010110011111000000

rem_sum_xor[1][56:0] = 
001101010101011111111111111111111111111111111100000000000 ^ 
100101010101000000000000000000000000000000000100000000000 ^ 
111111111111111101010110011010101010101010110011111000000 = 
010111111111100010101001100101010101010101001011111000000
rem_carry_andor[1][57:0] = 1011010101010111010101100110101010101010101101000000100101


rem_sum_in[1][61:56] 	= 101011
rem_carry_in[1][61:56] 	= 101001
~csa_minus_val0[1][54:51] = 1111
rem0_sum_minus[1][5:0] = 001101
rem0_carry_minus[1][5:0] = 110111

rem_sum_msb0[1][5:0] = 001101
rem_carry_msb0[1][5:0] = 110111

new_rem_sum0[1][56:0] = {rem_sum_msb0[1][5:0], rem_sum_xor[1][56: 6]} = 001101010111111111100010101001100101010101010101001011111
new_rem_sum_f3[1] = {new_rem_sum0[1][56:0], 6'b0} = 001101010111111111100010101001100101010101010101001011111000000
new_rem_carry0[1][55:0] = {rem_carry_msb0[1][5:1], rem_carry_andor[1][57: 7]} = 11011101101010101011101010110011010101010101010110100000
new_rem_carry_f3[1] = {new_rem_carry0[1][55:0], quot_dig0[1][0], 6'b0} = 110111011010101010111010101100110101010101010101101000001000000

// ====================================
rem_sum_in[2] = new_rem_sum_f3[1][61:0] = 01101010111111111100010101001100101010101010101001011111000000
rem_carry_in[2] = new_rem_carry_f3[1][61:0] = 10111011010101010111010101100110101010101010101101000001000000

rem_sum_msb0[1][5:3] = 001
rem_carry_msb0[1][5:3] = 110
-> 
quot_dig0[2] = 00
csa_val0[2] = 000000000000000000000000000000000000000000000000000
csa_mux[2] = {csa_val0[2], 6'b0} = 000000000000000000000000000000000000000000000000000000000


rem_sum_xor[2][56:0] = 
101111111111000101010011001010101010101010010111110000000 ^ 
110101010101110101011001101010101010101011010000010000000 ^ 
000000000000000000000000000000000000000000000000000000000 = 
011010101010110000001010100000000000000001000111100000000
rem_carry_andor[2][57:0] = 1001010101010001010100010010101010101010100100000100000000

rem_sum_in[2][61:56] 	= 011010
rem_carry_in[2][61:56] 	= 101110

rem0_sum_zero[2][5:0] = 010100
rem0_carry_zero[2][5:0] = 110100

rem_sum_msb0[2][5:0] = 010100
rem_carry_msb0[2][5:0] = 110100

new_rem_sum0[2][56:0] = {rem_sum_msb0[2][5:0], rem_sum_xor[2][56: 6]} = 010100011010101010110000001010100000000000000001000111100
new_rem_sum_f3[2] = {new_rem_sum0[2][56:0], 6'b0} = 010100011010101010110000001010100000000000000001000111100000000
new_rem_carry0[2][55:0] = {rem_carry_msb0[2][5:1], rem_carry_andor[2][57: 7]} = 11010100101010101000101010001001010101010101010010000010
new_rem_carry_f3[2] = {new_rem_carry0[2][55:0], quot_dig0[2][0], 6'b0} = 110101001010101010001010100010010101010101010100100000100000000


此时:
new_rem_sum_f3[2] + new_rem_carry_f3[2] = 
010100011010101010110000001010100000000000000001000111100000000 + 110101001010101010001010100010010101010101010100100000100000000 = 
001001100101010100111010101100110101010101010101101000000000000
q = 1010
b0_frac * q = 10100000000000000000011010011111110101010101010011111000
a0_frac << 3 - 10100000000000000000011010011111110101010101010011111000 = 
10101001100101010101010101001100101010101010101001100000 - 10100000000000000000011010011111110101010101010011111000 = 
01001100101010100111010101100110101010101010101101000

// iter[1]:
rem_sum_f3 = 010100011010101010110000001010100000000000000001000111100000000
rem_carry_f3 = 110101001010101010001010100010010101010101010100100000100000000
rem_sum_f3[62:60] = 010
rem_carry_f3[62:60] = 110

quot_dig0[0] = 01

csa_val0[0] = 111111111111111101010110011010101010101010110011111
csa_mux[0] = {csa_val0[0], 6'b0} = 111111111111111101010110011010101010101010110011111000000
rem_sum_in[0] = rem_sum_f3[61:0] = 10100011010101010110000001010100000000000000001000111100000000
rem_carry_in[0] = rem_carry_f3[61:0] = 10101001010101010001010100010010101010101010100100000100000000

rem_sum_xor[0][56:0] = 
110101010101100000010101000000000000000010001111000000000 ^ 
010101010100010101000100101010101010101001000001000000000 ^ 
111111111111111101010110011010101010101010110011111000000 = 
011111111110001000000111110000000000000001111101111000000
rem_carry_andor[0][57:0] = 1101010101011101010101000010101010101010100000110000000001

rem_sum_in[0][61:56] = 101000
rem_carry_in[0][61:56] = 101010
~csa_minus_val0[0][54:51] = 1111
rem0_sum_minus[0][5:0] = 001101
rem0_carry_minus[0][5:0] = 110101

rem_sum_msb0[0][5:0] = 001101
rem_carry_msb0[0][5:0] = 110101

new_rem_sum0[0][56:0] = {rem_sum_msb0[0][5:0], rem_sum_xor[0][56: 6]} = 001101011111111110001000000111110000000000000001111101111
new_rem_sum_f3[0] = {new_rem_sum0[0][56:0], 6'b0} = 001101011111111110001000000111110000000000000001111101111000000
new_rem_carry0[0][55:0] = {rem_carry_msb0[0][5:1], rem_carry_andor[0][57: 7]} = 11010110101010101110101010100001010101010101010000011000
new_rem_carry_f3[0] = {new_rem_carry0[0][55:0], quot_dig0[0][0], 6'b0} = 110101101010101011101010101000010101010101010100000110001000000

// ====================================
rem_sum_in[1] = new_rem_sum_f3[0][61:0] = 01101011111111110001000000111110000000000000001111101111000000
rem_carry_in[1] = new_rem_carry_f3[0][61:0] = 10101101010101011101010101000010101010101010100000110001000000

rem_sum_msb0[0][5:3] = 001
rem_carry_msb0[0][5:3] = 110
->
quot_dig0[1] = 00
csa_val0[1] = csa_plus_val0[1][50:0] = 000000000000000000000000000000000000000000000000000
csa_mux[1] = {csa_val0[1], 6'b0} = 000000000000000000000000000000000000000000000000000000000

rem_sum_xor[1][56:0] = 
111111111100010000001111100000000000000011111011110000000 ^ 
010101010111010101010000101010101010101000001100010000000 ^ 
000000000000000000000000000000000000000000000000000000000 = 
101010101011000101011111001010101010101011110111100000000
rem_carry_andor[1][57:0] = 0101010101000100000000001000000000000000000010000100000000


rem_sum_in[1][61:56] 	= 011010
rem_carry_in[1][61:56] 	= 101011

rem0_sum_zero[1][5:0] = 010001
rem0_carry_zero[1][5:0] = 110100

rem_sum_msb0[1][5:0] = 010001
rem_carry_msb0[1][5:0] = 110100

new_rem_sum0[1][56:0] = {rem_sum_msb0[1][5:0], rem_sum_xor[1][56: 6]} = 010001101010101011000101011111001010101010101011110111100
new_rem_sum_f3[1] = {new_rem_sum0[1][56:0], 6'b0} = 010001101010101011000101011111001010101010101011110111100000000
new_rem_carry0[1][55:0] = {rem_carry_msb0[1][5:1], rem_carry_andor[1][57: 7]} = 11010010101010100010000000000100000000000000000001000010
new_rem_carry_f3[1] = {new_rem_carry0[1][55:0], quot_dig0[1][0], 6'b0} = 110100101010101000100000000001000000000000000000010000100000000

// ====================================
rem_sum_in[2] = new_rem_sum_f3[1][61:0] = 10001101010101011000101011111001010101010101011110111100000000
rem_carry_in[2] = new_rem_carry_f3[1][61:0] = 10100101010101000100000000001000000000000000000010000100000000

rem_sum_msb0[1][5:3] = 010
rem_carry_msb0[1][5:3] = 110
-> 
quot_dig0[2] = 01
csa_val0[2] = ~csa_minus_val0[2][50:0] = 111111111111111101010110011010101010101010110011111
csa_mux[2] = {csa_val0[2], 6'b0} = 111111111111111101010110011010101010101010110011111000000

rem_sum_xor[2][56:0] = 
010101010110001010111110010101010101010111101111000000000 ^ 
010101010001000000000010000000000000000000100001000000000 ^ 
111111111111111101010110011010101010101010110011111000000 = 
111111111000110111101010001111111111111101111101111000000
rem_carry_andor[2][57:0] = 0101010101110010000101100100000000000000101000110000000001


rem_sum_in[2][61:56] 	= 100011
rem_carry_in[2][61:56] 	= 101001
~csa_minus_val0[2][54:51] = 1111
rem0_sum_minus[2][5:0] = 000101
rem0_carry_minus[2][5:0] = 110111
rem_sum_msb0[2][5:0] = 000101
rem_carry_msb0[2][5:0] = 110111


new_rem_sum0[2][56:0] = {rem_sum_msb0[2][5:0], rem_sum_xor[2][56: 6]} = 000101111111111000110111101010001111111111111101111101111
new_rem_sum_f3[2] = {new_rem_sum0[2][56:0], 6'b0} = 000101111111111000110111101010001111111111111101111101111000000
new_rem_carry0[2][55:0] = {rem_carry_msb0[2][5:1], rem_carry_andor[2][57: 7]} = 11011010101010111001000010110010000000000000010100011000
new_rem_carry_f3[2] = {new_rem_carry0[2][55:0], quot_dig0[2][0], 6'b0} = 110110101010101110010000101100100000000000000101000110001000000

此时:
new_rem_sum_f3[2] + new_rem_carry_f3[2] = 
000101111111111000110111101010001111111111111101111101111000000 + 110110101010101110010000101100100000000000000101000110001000000 = 
111100101010100111001000010110110000000000000011000100000000000 = 
-00011010101011000110111101001001111111111111100111100000000000
q = 1010101

b0_frac * q = 10000000000000000000010101001100101010101010101001100 * 1010101 = 
10101010000000000000011100001001110100101010101001000111100
a0_frac << 6 - 10101010000000000000011100001001110100101010101001000111100 = 
10101001100101010101010101001100101010101010101001100000000 - 10101010000000000000011100001001110100101010101001000111100 = 
-11010101011000110111101001001111111111111100111100


-00011010101011000110111101001001111111111111100111100000000000 + 10000000000000000000010101001100101010101010101001100000000000 = 
+01100101010100111001011000000010101010101011000010000000000000

q = 1010100 ->
b0_frac * q = 10000000000000000000010101001100101010101010101001100 * 1010100 = 
10101000000000000000011011110100100111111111111110011110000
a0_frac << 6 - 10101000000000000000011011110100100111111111111110011110000 = 
10101001100101010101010101001100101010101010101001100000000 - 10101000000000000000011011110100100111111111111110011110000 = 
01100101010100111001011000000010101010101011000010000


// ============================================================================================================
// ============================================================================================================
// ============================================================================================================

// Some test for my version of fp_div
a0_frac = 10101001100101010101010101001100101010101010101001100
b0_frac = 10000000000000000000010101001100101010101010101001100
a0_frac / b0_frac = 1.0101001100101010100111001000111010000101101100100010111101000010011111000001011000111011111111001011111111101000...

init_rem_sum = {1'b0, a_frac_i[52:0], 1'b1} = 0101010011001010101010101010011001010101010101010011001
init_rem_carry = {1'b1, ~b_frac_i[52:0], 1'b1} = 1011111111111111111111010101100110101010101010101100111

csa_val_div[53-1:0] = 00000000000000000000101010011001010101010101010011000
csa_plus_val = 00000000000000000000101010011001010101010101010011000
csa_minus_val = 00000000000000000000101010011001010101010101010011000


// iter[0]:
init_rem_sum[54:52] = 010
init_carry_sum[54:52] = 101
->
quo_dig0[0] = 00
csa_mux[0] = 0000000000000000000000000000000000000000000000000
rem_sum_in[0] = 101010011001010101010101010011001010101010101010011001
rem_carry_in[0] = 011111111111111111111010101100110101010101010101100111

rem_sum_in[0][53:48] = 101010
rem_carry_in[0][53:48] = 011111

rem_sum_zero[0][5:0] = 010101
rem_carry_zero[0][5:0] = 110100
rem_sum_msb[0][5:0] = 010101
rem_carry_msb[0][5:0] = 110100

rem_sum_xor[0][48:0] = 
0110010101010101010100110010101010101010100110010 ^
1111111111111110101011001101010101010101011001110 ^
0000000000000000000000000000000000000000000000000 = 
1001101010101011111111111111111111111111111111100
rem_carry_and_or[0][48:0] = 0110010101010100000000000000000000000000000000010

nxt_rem_sum[0] = {rem_sum_msb[0][5:0], rem_sum_xor[0][48:0]} = 0101011001101010101011111111111111111111111111111111100
nxt_rem_carry[0] = {rem_carry_msb[0][5:1], rem_carry_and_or[0][48:0], quo_dig[0][0]} = 1101001100101010101000000000000000000000000000000000100

// ====================================
rem_sum_in[1] = nxt_rem_sum[0][53:0] = 101011001101010101011111111111111111111111111111111100
rem_carry_in[1] = nxt_rem_carry[0][53:0] = 101001100101010101000000000000000000000000000000000100

rem_sum_msb[0][5:3] = 010
rem_carry_msb[0][5:3] = 110
-> 
quo_dig[1] = 01
csa_val[1] = ~csa_minus_val[48:0] = 1111111111111111010101100110101010101010101100111
csa_mux[1] = csa_val[1] = 1111111111111111010101100110101010101010101100111

rem_sum_xor[1][48:0] = 
0011010101010111111111111111111111111111111111000 ^
1001010101010000000000000000000000000000000001000 ^
1111111111111111010101100110101010101010101100111 = 
0101111111111000101010011001010101010101010010111
rem_carry_and_or[1][48:0] = 1011010101010111010101100110101010101010101101000

rem_sum_in[1][53:48] 	= 101011
rem_carry_in[1][53:48] 	= 101001
~csa_minus_val[52:49] = 1111
rem_sum_minus[1][5:0] = 001101
rem_carry_minus[1][5:0] = 110111

rem_sum_msb[1][5:0] = 001101
rem_carry_msb[1][5:0] = 110111

nxt_rem_sum[1] = {rem_sum_msb[1][5:0], rem_sum_xor[1][48:0]} = 0011010101111111111000101010011001010101010101010010111
nxt_rem_carry[1] = {rem_carry_msb[1][5:1], rem_carry_and_or[1][48:0], quo_dig[1][0]} = 1101110110101010101110101011001101010101010101011010001

// ====================================
rem_sum_in[2] = nxt_rem_sum[2][53:0] = 011010101111111111000101010011001010101010101010010111
rem_carry_in[2] = nxt_rem_carry[2][53:0] = 101110110101010101110101011001101010101010101011010001

rem_sum_msb[1][5:3] = 001
rem_carry_msb[1][5:3] = 110
-> 
quo_dig[2] = 00
csa_val[2] = 0000000000000000000000000000000000000000000000000
csa_mux[2] = csa_val[2] = 0000000000000000000000000000000000000000000000000

rem_sum_xor[2][48:0] = 
1011111111110001010100110010101010101010100101110 ^
1101010101011101010110011010101010101010110100010 ^
0000000000000000000000000000000000000000000000000 = 
0110101010101100000010101000000000000000010001100
rem_carry_and_or[2][48:0] = 1001010101010001010100010010101010101010100100010

rem_sum_in[2][53:48] 	= 011010
rem_carry_in[2][53:48] 	= 101110

rem_sum_minus[2][5:0] = 010100
rem_carry_minus[2][5:0] = 110100
rem_sum_msb[2][5:0] = 010100
rem_carry_msb[2][5:0] = 110100

nxt_rem_sum[2] = {rem_sum_msb[2][5:0], rem_sum_xor[2][48:0]} = 0101000110101010101100000010101000000000000000010001100
nxt_rem_carry[2] = {rem_carry_msb[2][5:1], rem_carry_and_or[2][48:0], quo_dig[2][0]} = 1101010010101010100010101000100101010101010101001000100


此时:
nxt_rem_sum[2] + nxt_rem_carry[2] = 
0101000110101010101100000010101000000000000000010001100 + 1101010010101010100010101000100101010101010101001000100 = 
0010011001010101001110101011001101010101010101011010000
q = 1010
b0_frac * q = 10100000000000000000011010011111110101010101010011111000
a0_frac << 3 - 10100000000000000000011010011111110101010101010011111000 = 
10101001100101010101010101001100101010101010101001100000 - 10100000000000000000011010011111110101010101010011111000 = 
01001100101010100111010101100110101010101010101101000







