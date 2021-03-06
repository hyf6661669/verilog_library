测试sqrt计算.


// ---------------------------------------------------------------------------------------------------------------------------------------
WIDTH = 16;
// ---------------------------------------------------------------------------------------------------------------------------------------
X[WIDTH-1:0] = 1001001011110011 = 37619
sqrt(X) = 193 = 11000001
REM = 370 = 101110010

stage[0]:
{0, X[15:14]} - 001
010 -
001 = 
{0_01} >= 0
rem[0] = 01
q = 1

stage[1]:
{rem[0][1:0], X[13:12]} - {0, q[7], 01}
0101 -
0101 = 
{0_000} >= 0
rem[1] = 000
q = 11

stage[2]:
{rem[1][2:0], X[11:10]} - {0, q[7:6], 01}
00000 -
01101 = 
{1_0011} < 0
rem[2] = 0000
q = 110

stage[3]:
{rem[2][3:0], X[9:8]} - {0, q[7:5], 01}
000010 -
011001 = 
{1_01001} < 0
rem[3] = 00010
q = 1100

stage[4]:
{rem[3][4:0], X[7:6]} - {0, q[7:4], 01}
0001011 -
0110001 = 
{1_011010} < 0
rem[4] = 001011
q = 11000

stage[5]:
{rem[4][5:0], X[5:4]} - {0, q[7:3], 01}
00101111 -
01100001 = 
{1_1001110} < 0
rem[5] = 0101111
q = 110000

stage[6]:
{rem[5][6:0], X[3:2]} - {0, q[7:2], 01}
010111100 -
011000001 = 
{1_11111011} < 0
rem[6] = 10111100
q = 1100000

stage[7]:
{rem[6][7:0], X[1:0]} - {0, q[7:1], 01}
1011110011 -
0110000001 = 
{0_101110010} >= 0
rem[7] = 101110010
q = 11000001


// ---------------------------------------------------------------------------------------------------------------------------------------
X[WIDTH-1:0] = 1001110101001001 = 40265
sqrt(X) = 200 = 11001000
REM = 265 = 100001001

stage[0]:
{0, X[15:14]} - 001
010 -
001 = 
{0_01} >= 0
rem[0] = 01
q = 1

stage[1]:
{rem[0][1:0], X[13:12]} - {0, q[7], 01}
0101 -
0101 = 
{0_000} >= 0
rem[1] = 000
q = 11

stage[2]:
{rem[1][2:0], X[11:10]} - {0, q[7:6], 01}
00011 -
01101 = 
{1_0110} < 0
rem[2] = 0011
q = 110

stage[3]:
{rem[2][3:0], X[9:8]} - {0, q[7:5], 01}
001101 -
011001 = 
{1_10100} < 0
rem[3] = 01101
q = 1100

stage[4]:
{rem[3][4:0], X[7:6]} - {0, q[7:4], 01}
0110101 -
0110001 = 
{0_000100} >= 0
rem[4] = 000100
q = 11001

stage[5]:
{rem[4][5:0], X[5:4]} - {0, q[7:3], 01}
00010000 -
01100101 = 
{1_0101011} < 0
rem[5] = 0010000
q = 110010

stage[6]:
{rem[5][6:0], X[3:2]} - {0, q[7:2], 01}
001000010 -
011001001 = 
{1_01111001} < 0
rem[6] = 01000010
q = 1100100

stage[7]:
{rem[6][7:0], X[1:0]} - {0, q[7:1], 01}
0100001001 -
0110010001 = 
{0_101111000} >= 0
rem[7] = 100001001
q = 11001000

// ---------------------------------------------------------------------------------------------------------------------------------------
X[WIDTH-1:0] = 1101110101001110 = 56654
sqrt(X) = 238 = 11101110
REM = 10 = 000001010

// ---------------------------------------------------------------------------------------------------------------------------------------
求浮点数尾数部分的sqrt时, X[WIDTH-1]必然为1, 因此stage[0]的计算可以简化.
if(X[WIDTH-2])
	rem[0] = 10
else
	rem[0] = 01
必然有:
q[WIDTH-1] = 1
// ---------------------------------------------------------------------------------------------------------------------------------------

stage[0]:
X[14] = 1 -> 
rem[0] = 10
q = 1

stage[1]:
{rem[0][1:0], X[13:12]} - {0, q[7], 01}
1001 -
0101 = 
{0_0100} >= 0
rem[1] = 100
q = 11

stage[2]:
{rem[1][2:0], X[11:10]} - {0, q[7:6], 01}
10011 -
01101 = 
{0_0110} >= 0
rem[2] = 0110
q = 111

stage[3]:
{rem[2][3:0], X[9:8]} - {0, q[7:5], 01}
011001 -
011101 = 
{1_11100} < 0
rem[3] = 11001
q = 1110

stage[4]:
{rem[3][4:0], X[7:6]} - {0, q[7:4], 01}
1100101 -
0111001 = 
{0_101100} >= 0
rem[4] = 101100
q = 11101

stage[5]:
{rem[4][5:0], X[5:4]} - {0, q[7:3], 01}
10110000 -
01110101 = 
{0_0111011} >= 0
rem[5] = 0111011
q = 111011

stage[6]:
{rem[5][6:0], X[3:2]} - {0, q[7:2], 01}
011101111 -
011101101 = 
{0_00000010} >= 0
rem[6] = 00000010
q = 1110111

stage[7]:
{rem[6][7:0], X[1:0]} - {0, q[7:1], 01}
0000001010 -
0111011101 = 
{1_000101101} < 0
rem[7] = 0000001010
q = 11101110


// ---------------------------------------------------------------------------------------------------------------------------------------
由上述计算过程可以看出, stage[i]需要"(i + 3)-bit"的FA
