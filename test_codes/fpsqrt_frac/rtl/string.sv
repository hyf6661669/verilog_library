

s[0] = 1111_0010_1111_0010
c[0] = 1101_0110_1001_1111
rem[0] = 1100100110010001

s[0][13:7] + c[0][13:7] = 
11_0010_1 + 
01_0110_1 = 
0010010
carry = 1

s_mod[0] = 1100100101110010
c_mod[0] = 1100000000011111

s_mod[0][13:0] + c_mod[0][13:0] = 00100110010001
s_mod[0][15:14] + c_mod[0][15:14] + carry = 11
->
1100100110010001

// TODO
s_mod[0] ^ c_mod[0] = 0000100101101101
(s_mod[0] & c_mod[0]) << 1 = 1000000000100100
->
1000100110010001
