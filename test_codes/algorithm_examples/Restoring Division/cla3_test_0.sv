测试DW中使用的radix-8 restoring算法


// ---------------------------------------------------------------------------------------------------------------------------------------
X[WIDTH-1:0] = 11111101011111000110011011110011 = 4252788467
D[WIDTH-1:0] = 00000000000000000010011001001001 = 9801
Q[WIDTH-1:0] = X / D = 433913 = 00000000000001101001111011111001
REM[WIDTH-1:0] = 4252788467 - 9801 * 433913 = 7154 = 00000000000000000001101111110010

X[32-1:0] = 11111101011111000110011011110011
D[32-1:0] = 00000000000000000010011001001001
(3D)[34-1:0] =  0000000000000000000111001011011011
(5D)[35-1:0] = 00000000000000000001011111101101101
(7D)[35-1:0] = 00000000000000000010000101111111111

stage[0]:
force_q_to_zero[0] = |(D[31:1]) = 1
rem[0] = X[31] = 1
quo[0] = 0

stage[1].prev_q_0:
force_q_to_zero_prev_q_0[1] = |(D[31:2]) = 1
{rem_cout_prev_q_0[1], rem_sum_prev_q_0[1]} = 
  {1'b0, X[31:30]}
+ {1'b0, ~D[1:0]}
+ {2'b0, ~divisor_sign}
= {1, 10}
q_prev_q_0[1] = force_q_to_zero_prev_q_0[1] ? 1'b0 : rem_cout_prev_q_0[1] = 0
rem_prev_q_0[1] = q_prev_q_0[1] ? rem_sum_prev_q_0[1] : X[31:30] = 11

stage[1].prev_q_1:
force_q_to_zero_prev_q_1[1] = |(3D[33:2]) = 1
{rem_cout_prev_q_1[1], rem_sum_prev_q_1[1]} = 
  {1'b0, X[31:30]}
+ {1'b0, ~3D[1:0]}
+ {2'b0, ~divisor_sign}
= {1, 00}
q_prev_q_1[1] = force_q_to_zero_prev_q_1[1] ? 1'b0 : rem_cout_prev_q_1[1] = 0
rem_prev_q_1[1] = q_prev_q_1[1] ? rem_sum_prev_q_1[1] : {rem[0], X[30]} = 11

stage[2].prev_q_00:
force_q_to_zero_prev_q_00[2] = |(D[31:3]) = 1
{rem_cout_prev_q_00[2], rem_sum_prev_q_00[2][2:0]} = 
  {1'b0, X[31:29]}
+ {1'b0, ~D[2:0]}
+ {3'b0, ~divisor_sign}
= {1, 110}
q_prev_q_00[2] = force_q_to_zero_prev_q_00[2] ? 1'b0 : rem_cout_prev_q_00[2] = 0
rem_prev_q_00[2] = q_prev_q_00[2] ? rem_sum_prev_q_00[2] : X[31:29] = 111

stage[2].prev_q_01:
force_q_to_zero_prev_q_01[2] = |(3D[33:3]) = 1
{rem_cout_prev_q_01[2], rem_sum_prev_q_01[2]} = 
  {1'b0, X[31:29]}
+ {1'b0, ~3D[2:0]}
+ {3'b0, ~divisor_sign}
= {1, 100}
q_prev_q_01[2] = force_q_to_zero_prev_q_01[2] ? 1'b0 : rem_cout_prev_q_01[2] = 0
rem_prev_q_01[2] = q_prev_q_01[2] ? rem_sum_prev_q_01[2] : {rem_prev_q_0[1], X[29]} = 111

stage[2].prev_q_10:
force_q_to_zero_prev_q_10[2] = |(5D[34:3]) = 1
{rem_cout_prev_q_10[2], rem_sum_prev_q_10[2]} = 
  {1'b0, X[31:29]}
+ {1'b0, ~5D[2:0]}
+ {3'b0, ~divisor_sign}
= {1, 010}
q_prev_q_10[2] = force_q_to_zero_prev_q_10[2] ? 1'b0 : rem_cout_prev_q_10[2] = 0
rem_prev_q_10[2] = q_prev_q_10[2] ? rem_sum_prev_q_10[2] : {rem[0], X[30:29]} = 111

stage[2].prev_q_11:
force_q_to_zero_prev_q_11[2] = |(7D[34:3]) = 1
{rem_cout_prev_q_11[2], rem_sum_prev_q_11[2]} = 
  {1'b0, X[31:29]}
+ {1'b0, ~7D[2:0]}
+ {3'b0, ~divisor_sign}
= {1, 000}
q_prev_q_11[2] = force_q_to_zero_prev_q_11[2] ? 1'b0 : rem_cout_prev_q_11[2] = 0
rem_prev_q_11[2] = q_prev_q_11[2] ? rem_sum_prev_q_11[2] : {rem_prev_q_1[1], X[29]} = 111

rem[1] = quo[0] ? rem_prev_q_1[1] : rem_prev_q_0[1] = 11
quo[1] = quo[0] ? q_prev_q_1[1] : q_prev_q_0[1] = 0
quo[2] = 
  ({(1){{quo[0], quo[1]} == 2'b00}} & q_prev_q_00[2])
| ({(1){{quo[0], quo[1]} == 2'b01}} & q_prev_q_01[2])
| ({(1){{quo[0], quo[1]} == 2'b10}} & q_prev_q_10[2])
| ({(1){{quo[0], quo[1]} == 2'b11}} & q_prev_q_11[2])
= 0
rem[2] = 
  ({(3){{quo[0], quo[1]} == 2'b00}} & rem_prev_q_00[2])
| ({(3){{quo[0], quo[1]} == 2'b01}} & rem_prev_q_01[2])
| ({(3){{quo[0], quo[1]} == 2'b10}} & rem_prev_q_10[2])
| ({(3){{quo[0], quo[1]} == 2'b11}} & rem_prev_q_11[2])
= 111

Q = 000

// =====================================================================================================================
stage[3]:
force_q_to_zero[3] = |(D[31:4]) = 1
{rem_cout[3], rem_sum[3]} = 
  {1'b0, rem[2], X[28]}
+ {1'b0, ~D[3:0]}
+ {4'b0, ~divisor_sign}
= {1, 0110}
quo[3] = force_q_to_zero[3] ? 0 : rem_cout[3] = 0
rem[3] = quo[3] ? rem_sum[3] : {rem[2], X[28]} = 1111

X[32-1:0] = 11111101011111000110011011110011
D[32-1:0] = 00000000000000000010011001001001
(3D)[34-1:0] =  0000000000000000000111001011011011
(5D)[35-1:0] = 00000000000000000001011111101101101
(7D)[35-1:0] = 00000000000000000010000101111111111
stage[4].prev_q_0:
force_q_to_zero_prev_q_0[4] = |(D[31:5]) = 1
{rem_cout_prev_q_0[4], rem_sum_prev_q_0[4]} = 
  {1'b0, rem[2], X[28:27]}
+ {1'b0, ~D[4:0]}
+ {5'b0, ~divisor_sign}
= 11111 + 10110 + 1 = {1, 10110}
q_prev_q_0[4] = force_q_to_zero_prev_q_0[4] ? 1'b0 : rem_cout_prev_q_0[4] = 0
rem_prev_q_0[4] = q_prev_q_0[4] ? rem_sum_prev_q_0[4] : {rem[2], X[28:27]} = 11111

stage[4].prev_q_1:
force_q_to_zero_prev_q_1[4] = |(3D[33:5]) = 1
{rem_cout_prev_q_1[4], rem_sum_prev_q_1[4]} = 
  {1'b0, rem[2], X[28:27]}
+ {1'b0, ~3D[4:0]}
+ {5'b0, ~divisor_sign}
= 11111 + 00100 + 1 = {1, 00100}
q_prev_q_1[4] = force_q_to_zero_prev_q_1[4] ? 1'b0 : rem_cout_prev_q_1[4] = 0
rem_prev_q_1[4] = q_prev_q_1[4] ? rem_sum_prev_q_1[4] : {rem[3], X[27]} = 11111


stage[5].prev_q_00:
force_q_to_zero_prev_q_00[5] = |(D[31:6]) = 1
{rem_cout_prev_q_00[5], rem_sum_prev_q_00[5]} = 
  {1'b0, rem[2], X[28:26]}
+ {1'b0, ~D[5:0]}
+ {6'b0, ~divisor_sign}
= 111111 + 110110 + 1 = {1, 110110}
q_prev_q_00[5] = force_q_to_zero_prev_q_00[5] ? 1'b0 : rem_cout_prev_q_00[5] = 0
rem_prev_q_00[5] = q_prev_q_00[5] ? rem_sum_prev_q_00[5] : {rem[2], X[28:26]} = 111111

stage[5].prev_q_01:
force_q_to_zero_prev_q_01[5] = |(3D[33:6]) = 1
{rem_cout_prev_q_01[5], rem_sum_prev_q_01[5]} = 
  {1'b0, rem[2], X[28:26]}
+ {1'b0, ~3D[5:0]}
+ {6'b0, ~divisor_sign}
= 111111 + 100100 + 1 = {1, 100100}
q_prev_q_01[5] = force_q_to_zero_prev_q_01[5] ? 1'b0 : rem_cout_prev_q_01[5] = 0
rem_prev_q_01[5] = q_prev_q_01[5] ? rem_sum_prev_q_01[5] : {rem_prev_q_0[4], X[26]} = 111111

stage[5].prev_q_10:
force_q_to_zero_prev_q_10[5] = |(5D[34:6]) = 1
{rem_cout_prev_q_10[5], rem_sum_prev_q_10[5]} = 
  {1'b0, rem[2], X[28:26]}
+ {1'b0, ~5D[5:0]}
+ {6'b0, ~divisor_sign}
= 111111 + 010010 + 1 = {1, 010010}
q_prev_q_10[5] = force_q_to_zero_prev_q_10[5] ? 1'b0 : rem_cout_prev_q_10[5] = 0
rem_prev_q_10[5] = q_prev_q_10[5] ? rem_sum_prev_q_10[5] : {rem[3], X[27:26]} = 111111

stage[5].prev_q_11:
force_q_to_zero_prev_q_11[5] = |(7D[34:6]) = 1
{rem_cout_prev_q_11[5], rem_sum_prev_q_11[5]} = 
  {1'b0, rem[2], X[28:26]}
+ {1'b0, ~7D[5:0]}
+ {6'b0, ~divisor_sign}
= 111111 + 000000 + 1 = {1, 000000}
q_prev_q_11[5] = force_q_to_zero_prev_q_11[5] ? 1'b0 : rem_cout_prev_q_11[5] = 0
rem_prev_q_11[5] = q_prev_q_11[5] ? rem_sum_prev_q_11[5] : {rem_prev_q_1[4], X[26]} = 111111

rem[4] = quo[3] ? rem_prev_q_1[4] : rem_prev_q_0[4] = 11111
quo[4] = quo[3] ? q_prev_q_1[4] : q_prev_q_0[4] = 0
quo[5] = 
  ({(1){{quo[3], quo[4]} == 2'b00}} & q_prev_q_00[5])
| ({(1){{quo[3], quo[4]} == 2'b01}} & q_prev_q_01[5])
| ({(1){{quo[3], quo[4]} == 2'b10}} & q_prev_q_10[5])
| ({(1){{quo[3], quo[4]} == 2'b11}} & q_prev_q_11[5])
= 0
rem[5] = 
  ({(6){{quo[3], quo[4]} == 2'b00}} & rem_prev_q_00[5])
| ({(6){{quo[3], quo[4]} == 2'b01}} & rem_prev_q_01[5])
| ({(6){{quo[3], quo[4]} == 2'b10}} & rem_prev_q_10[5])
| ({(6){{quo[3], quo[4]} == 2'b11}} & rem_prev_q_11[5])
= 111111

Q = 000000

// =====================================================================================================================
stage[6]:
force_q_to_zero[6] = |(D[31:7]) = 1
{rem_cout[6], rem_sum[6]} = 
  {1'b0, rem[5], X[25]}
+ {1'b0, ~D[6:0]}
+ {7'b0, ~divisor_sign}
= 1111110 + 0110110 + 1 = {1, 0110101}
quo[6] = force_q_to_zero[6] ? 0 : rem_cout[6] = 0
rem[6] = quo[6] ? rem_sum[6] : {rem[5], X[25]} = 1111110

X[32-1:0] = 11111101011111000110011011110011
D[32-1:0] = 00000000000000000010011001001001
(3D)[34-1:0] =  0000000000000000000111001011011011
(5D)[35-1:0] = 00000000000000000001011111101101101
(7D)[35-1:0] = 00000000000000000010000101111111111
stage[7].prev_q_0:
force_q_to_zero_prev_q_0[7] = |(D[31:8]) = 1
{rem_cout_prev_q_0[7], rem_sum_prev_q_0[7]} = 
  {1'b0, rem[5], X[25:24]}
+ {1'b0, ~D[7:0]}
+ {8'b0, ~divisor_sign}
= 11111101 + 10110110 + 1 = {1, 10110100}
q_prev_q_0[7] = force_q_to_zero_prev_q_0[7] ? 1'b0 : rem_cout_prev_q_0[7] = 0
rem_prev_q_0[7] = q_prev_q_0[7] ? rem_sum_prev_q_0[7] : {rem[5], X[25:24]} = 11111101

stage[7].prev_q_1:
force_q_to_zero_prev_q_1[7] = |(3D[33:8]) = 1
{rem_cout_prev_q_1[7], rem_sum_prev_q_1[7]} = 
  {1'b0, rem[5], X[25:24]}
+ {1'b0, ~3D[7:0]}
+ {8'b0, ~divisor_sign}
= 11111101 + 00100100 + 1 = {1, 00100010}
q_prev_q_1[7] = force_q_to_zero_prev_q_1[7] ? 1'b0 : rem_cout_prev_q_1[7] = 0
rem_prev_q_1[7] = q_prev_q_1[7] ? rem_sum_prev_q_1[7] : {rem[6], X[24]} = 11111101


stage[8].prev_q_00:
force_q_to_zero_prev_q_00[8] = |(D[31:9]) = 1
{rem_cout_prev_q_00[8], rem_sum_prev_q_00[8]} = 
  {1'b0, rem[5], X[25:23]}
+ {1'b0, ~D[8:0]}
+ {9'b0, ~divisor_sign}
= 111111010 + 110110110 + 1 = {1, 110110001}
q_prev_q_00[8] = force_q_to_zero_prev_q_00[8] ? 1'b0 : rem_cout_prev_q_00[8] = 0
rem_prev_q_00[8] = q_prev_q_00[8] ? rem_sum_prev_q_00[8] : {rem[5], X[25:23]} = 111111010

stage[8].prev_q_01:
force_q_to_zero_prev_q_01[8] = |(3D[33:9]) = 1
{rem_cout_prev_q_01[8], rem_sum_prev_q_01[8]} = 
  {1'b0, rem[5], X[25:23]}
+ {1'b0, ~3D[8:0]}
+ {9'b0, ~divisor_sign}
= 111111010 + 100100100 + 1 = {1, 100011111}
q_prev_q_01[8] = force_q_to_zero_prev_q_01[8] ? 1'b0 : rem_cout_prev_q_01[8] = 0
rem_prev_q_01[8] = q_prev_q_01[8] ? rem_sum_prev_q_01[8] : {rem_prev_q_0[7], X[23]} = 111111010

stage[8].prev_q_10:
force_q_to_zero_prev_q_10[8] = |(5D[34:9]) = 1
{rem_cout_prev_q_10[8], rem_sum_prev_q_10[8]} = 
  {1'b0, rem[5], X[25:23]}
+ {1'b0, ~5D[8:0]}
+ {9'b0, ~divisor_sign}
= 111111010 + 010010010 + 1 = {1, 010001101}
q_prev_q_10[8] = force_q_to_zero_prev_q_10[8] ? 1'b0 : rem_cout_prev_q_10[8] = 0
rem_prev_q_10[8] = q_prev_q_10[8] ? rem_sum_prev_q_10[8] : {rem[6], X[24:23]} = 111111010

stage[8].prev_q_11:
force_q_to_zero_prev_q_11[8] = |(7D[34:9]) = 1
{rem_cout_prev_q_11[8], rem_sum_prev_q_11[8]} = 
  {1'b0, rem[5], X[25:23]}
+ {1'b0, ~7D[8:0]}
+ {9'b0, ~divisor_sign}
= 111111010 + 000000000 + 1 = {0, 111111011}
q_prev_q_11[8] = force_q_to_zero_prev_q_11[8] ? 1'b0 : rem_cout_prev_q_11[8] = 0
rem_prev_q_11[8] = q_prev_q_11[8] ? rem_sum_prev_q_11[8] : {rem_prev_q_1[7], X[23]} = 111111010

rem[7] = quo[6] ? rem_prev_q_1[7] : rem_prev_q_0[7] = 11111101
quo[7] = quo[6] ? q_prev_q_1[7] : q_prev_q_0[7] = 0
quo[8] = 
  ({(1){{quo[6], quo[7]} == 2'b00}} & q_prev_q_00[8])
| ({(1){{quo[6], quo[7]} == 2'b01}} & q_prev_q_01[8])
| ({(1){{quo[6], quo[7]} == 2'b10}} & q_prev_q_10[8])
| ({(1){{quo[6], quo[7]} == 2'b11}} & q_prev_q_11[8])
= 0
rem[8] = 
  ({(9){{quo[6], quo[7]} == 2'b00}} & rem_prev_q_00[8])
| ({(9){{quo[6], quo[7]} == 2'b01}} & rem_prev_q_01[8])
| ({(9){{quo[6], quo[7]} == 2'b10}} & rem_prev_q_10[8])
| ({(9){{quo[6], quo[7]} == 2'b11}} & rem_prev_q_11[8])
= 111111010

Q = 000000000

// =====================================================================================================================
stage[9]:
force_q_to_zero[9] = |(D[31:10]) = 1
{rem_cout[9], rem_sum[9]} = 
  {1'b0, rem[8], X[22]}
+ {1'b0, ~D[9:0]}
+ {10'b0, ~divisor_sign}
= 1111110101 + 0110110110 + 1 = {1, 0110101100}
quo[9] = force_q_to_zero[9] ? 0 : rem_cout[9] = 0
rem[9] = quo[9] ? rem_sum[9] : {rem[8], X[22]} = 1111110101

X[32-1:0] = 11111101011111000110011011110011
D[32-1:0] = 00000000000000000010011001001001
(3D)[34-1:0] =  0000000000000000000111001011011011
(5D)[35-1:0] = 00000000000000000001011111101101101
(7D)[35-1:0] = 00000000000000000010000101111111111
stage[10].prev_q_0:
force_q_to_zero_prev_q_0[10] = |(D[31:11]) = 1
{rem_cout_prev_q_0[10], rem_sum_prev_q_0[10]} = 
  {1'b0, rem[8], X[22:21]}
+ {1'b0, ~D[10:0]}
+ {11'b0, ~divisor_sign}
= 11111101011 + 00110110110 + 1 = {1, 00110100010}
q_prev_q_0[10] = force_q_to_zero_prev_q_0[10] ? 1'b0 : rem_cout_prev_q_0[10] = 0
rem_prev_q_0[10] = q_prev_q_0[10] ? rem_sum_prev_q_0[10] : {rem[8], X[22:21]} = 11111101011

stage[10].prev_q_1:
force_q_to_zero_prev_q_1[10] = |(3D[33:11]) = 1
{rem_cout_prev_q_1[10], rem_sum_prev_q_1[10]} = 
  {1'b0, rem[8], X[22:21]}
+ {1'b0, ~3D[10:0]}
+ {11'b0, ~divisor_sign}
= 11111101011 + 10100100100 + 1 = {1, 10100010000}
q_prev_q_1[10] = force_q_to_zero_prev_q_1[10] ? 1'b0 : rem_cout_prev_q_1[10] = 0
rem_prev_q_1[10] = q_prev_q_1[10] ? rem_sum_prev_q_1[10] : {rem[9], X[21]} = 11111101011


stage[11].prev_q_00:
force_q_to_zero_prev_q_00[11] = |(D[31:12]) = 1
{rem_cout_prev_q_00[11], rem_sum_prev_q_00[11]} = 
  {1'b0, rem[8], X[22:20]}
+ {1'b0, ~D[11:0]}
+ {12'b0, ~divisor_sign}
= 111111010111 + 100110110110 + 1 = {1, 100110001110}
q_prev_q_00[11] = force_q_to_zero_prev_q_00[11] ? 1'b0 : rem_cout_prev_q_00[11] = 0
rem_prev_q_00[11] = q_prev_q_00[11] ? rem_sum_prev_q_00[11] : {rem[8], X[22:20]} = 111111010111

stage[11].prev_q_01:
force_q_to_zero_prev_q_01[11] = |(3D[33:12]) = 1
{rem_cout_prev_q_01[11], rem_sum_prev_q_01[11]} = 
  {1'b0, rem[8], X[22:20]}
+ {1'b0, ~3D[11:0]}
+ {12'b0, ~divisor_sign}
= 111111010111 + 110100100100 + 1 = {1, 110011111011}
q_prev_q_01[11] = force_q_to_zero_prev_q_01[11] ? 1'b0 : rem_cout_prev_q_01[11] = 0
rem_prev_q_01[11] = q_prev_q_01[11] ? rem_sum_prev_q_01[11] : {rem_prev_q_0[10], X[20]} = 111111010111

stage[11].prev_q_10:
force_q_to_zero_prev_q_10[11] = |(5D[34:12]) = 1
{rem_cout_prev_q_10[11], rem_sum_prev_q_10[11]} = 
  {1'b0, rem[8], X[22:20]}
+ {1'b0, ~5D[11:0]}
+ {12'b0, ~divisor_sign}
= 111111010111 + 000010010010 + 1 = {1, 000001101010}
q_prev_q_10[11] = force_q_to_zero_prev_q_10[11] ? 1'b0 : rem_cout_prev_q_10[11] = 0
rem_prev_q_10[11] = q_prev_q_10[11] ? rem_sum_prev_q_10[11] : {rem[9], X[21:20]} = 111111010111

stage[11].prev_q_11:
force_q_to_zero_prev_q_11[11] = |(7D[34:12]) = 1
{rem_cout_prev_q_11[11], rem_sum_prev_q_11[11]} = 
  {1'b0, rem[8], X[22:20]}
+ {1'b0, ~7D[11:0]}
+ {12'b0, ~divisor_sign}
= 111111010111 + 010000000000 + 1 = {1, 001111011000}
q_prev_q_11[11] = force_q_to_zero_prev_q_11[11] ? 1'b0 : rem_cout_prev_q_11[11] = 0
rem_prev_q_11[11] = q_prev_q_11[11] ? rem_sum_prev_q_11[11] : {rem_prev_q_1[10], X[20]} = 111111010111

rem[10] = quo[9] ? rem_prev_q_1[10] : rem_prev_q_0[10] = 11111101011
quo[10] = quo[9] ? q_prev_q_1[10] : q_prev_q_0[10] = 0
quo[11] = 
  ({(1){{quo[9], quo[10]} == 2'b00}} & q_prev_q_00[11])
| ({(1){{quo[9], quo[10]} == 2'b01}} & q_prev_q_01[11])
| ({(1){{quo[9], quo[10]} == 2'b10}} & q_prev_q_10[11])
| ({(1){{quo[9], quo[10]} == 2'b11}} & q_prev_q_11[11])
= 0
rem[11] = 
  ({(12){{quo[9], quo[10]} == 2'b00}} & rem_prev_q_00[11])
| ({(12){{quo[9], quo[10]} == 2'b01}} & rem_prev_q_01[11])
| ({(12){{quo[9], quo[10]} == 2'b10}} & rem_prev_q_10[11])
| ({(12){{quo[9], quo[10]} == 2'b11}} & rem_prev_q_11[11])
= 111111010111

Q = 000000000000

// =====================================================================================================================
stage[12]:
force_q_to_zero[12] = |(D[31:13]) = 1
{rem_cout[12], rem_sum[12]} = 
  {1'b0, rem[11], X[19]}
+ {1'b0, ~D[12:0]}
+ {13'b0, ~divisor_sign}
= 1111110101111 + 1100110110110 + 1 = {1, 1100101100110}
quo[12] = force_q_to_zero[12] ? 0 : rem_cout[12] = 0
rem[12] = quo[12] ? rem_sum[12] : {rem[11], X[19]} = 1111110101111

X[32-1:0] = 11111101011111000110011011110011
D[32-1:0] = 00000000000000000010011001001001
(3D)[34-1:0] =  0000000000000000000111001011011011
(5D)[35-1:0] = 00000000000000000001011111101101101
(7D)[35-1:0] = 00000000000000000010000101111111111
stage[13].prev_q_0:
force_q_to_zero_prev_q_0[13] = |(D[31:14]) = 0
{rem_cout_prev_q_0[13], rem_sum_prev_q_0[13]} = 
  {1'b0, rem[11], X[19:18]}
+ {1'b0, ~D[13:0]}
+ {14'b0, ~divisor_sign}
= 11111101011111 + 01100110110110 + 1 = {1, 01100100010110}
q_prev_q_0[13] = force_q_to_zero_prev_q_0[13] ? 1'b0 : rem_cout_prev_q_0[13] = 1
rem_prev_q_0[13] = q_prev_q_0[13] ? rem_sum_prev_q_0[13] : {rem[11], X[19:18]} = 01100100010110

stage[13].prev_q_1:
force_q_to_zero_prev_q_1[13] = |(3D[33:14]) = 1
{rem_cout_prev_q_1[13], rem_sum_prev_q_1[13]} = 
  {1'b0, rem[11], X[19:18]}
+ {1'b0, ~3D[13:0]}
+ {14'b0, ~divisor_sign}
= 11111101011111 + 00110100100100 + 1 = {1, 00110010000100}
q_prev_q_1[13] = force_q_to_zero_prev_q_1[13] ? 1'b0 : rem_cout_prev_q_1[13] = 0
rem_prev_q_1[13] = q_prev_q_1[13] ? rem_sum_prev_q_1[13] : {rem[12], X[18]} = 11111101011111


stage[14].prev_q_00:
force_q_to_zero_prev_q_00[14] = |(D[31:15]) = 0
{rem_cout_prev_q_00[14], rem_sum_prev_q_00[14]} = 
  {1'b0, rem[11], X[19:17]}
+ {1'b0, ~D[14:0]}
+ {15'b0, ~divisor_sign}
= 111111010111110 + 101100110110110 + 1 = {1, 101100001110101}
q_prev_q_00[14] = force_q_to_zero_prev_q_00[14] ? 1'b0 : rem_cout_prev_q_00[14] = 1
rem_prev_q_00[14] = q_prev_q_00[14] ? rem_sum_prev_q_00[14] : {rem[11], X[19:17]} = 101100001110101

stage[14].prev_q_01:
force_q_to_zero_prev_q_01[14] = |(3D[33:15]) = 0
{rem_cout_prev_q_01[14], rem_sum_prev_q_01[14]} = 
  {1'b0, rem[11], X[19:17]}
+ {1'b0, ~3D[14:0]}
+ {15'b0, ~divisor_sign}
= 111111010111110 + 000110100100100 + 1 = {1, 000101111100011}
q_prev_q_01[14] = force_q_to_zero_prev_q_01[14] ? 1'b0 : rem_cout_prev_q_01[14] = 1
rem_prev_q_01[14] = q_prev_q_01[14] ? rem_sum_prev_q_01[14] : {rem_prev_q_0[13], X[17]} = 011001000101101

stage[14].prev_q_10:
force_q_to_zero_prev_q_10[14] = |(5D[34:15]) = 1
{rem_cout_prev_q_10[14], rem_sum_prev_q_10[14]} = 
  {1'b0, rem[11], X[19:17]}
+ {1'b0, ~5D[14:0]}
+ {15'b0, ~divisor_sign}
= 111111010111110 + 100000010010010 + 1 = {1, 011111101010001}
q_prev_q_10[14] = force_q_to_zero_prev_q_10[14] ? 1'b0 : rem_cout_prev_q_10[14] = 0
rem_prev_q_10[14] = q_prev_q_10[14] ? rem_sum_prev_q_10[14] : {rem[12], X[18:17]} = 111111010111110

stage[14].prev_q_11:
force_q_to_zero_prev_q_11[14] = |(7D[34:15]) = 1
{rem_cout_prev_q_11[14], rem_sum_prev_q_11[14]} = 
  {1'b0, rem[11], X[19:17]}
+ {1'b0, ~7D[14:0]}
+ {15'b0, ~divisor_sign}
= 111111010111110 + 111010000000000 + 1 = {1, 111001010111111}
q_prev_q_11[14] = force_q_to_zero_prev_q_11[14] ? 1'b0 : rem_cout_prev_q_11[14] = 0
rem_prev_q_11[14] = q_prev_q_11[14] ? rem_sum_prev_q_11[14] : {rem_prev_q_1[13], X[17]} = 111111010111110

rem[13] = quo[12] ? rem_prev_q_1[13] : rem_prev_q_0[13] = 01100100010110
quo[13] = quo[12] ? q_prev_q_1[13] : q_prev_q_0[13] = 1
quo[14] = 
  ({(1){{quo[12], quo[13]} == 2'b00}} & q_prev_q_00[14])
| ({(1){{quo[12], quo[13]} == 2'b01}} & q_prev_q_01[14])
| ({(1){{quo[12], quo[13]} == 2'b10}} & q_prev_q_10[14])
| ({(1){{quo[12], quo[13]} == 2'b11}} & q_prev_q_11[14])
= 1
rem[14] = 
  ({(15){{quo[12], quo[13]} == 2'b00}} & rem_prev_q_00[14])
| ({(15){{quo[12], quo[13]} == 2'b01}} & rem_prev_q_01[14])
| ({(15){{quo[12], quo[13]} == 2'b10}} & rem_prev_q_10[14])
| ({(15){{quo[12], quo[13]} == 2'b11}} & rem_prev_q_11[14])
= 000101111100011

Q = 000000000000011

// =====================================================================================================================
stage[15]:
force_q_to_zero[15] = |(D[31:16]) = 0
{rem_cout[15], rem_sum[15]} = 
  {1'b0, rem[14], X[16]}
+ {1'b0, ~D[15:0]}
+ {16'b0, ~divisor_sign}
= 0001011111000110 + 1101100110110110 + 1 = {0, 1111000101111101}
quo[15] = force_q_to_zero[15] ? 0 : rem_cout[15] = 0
rem[15] = quo[15] ? rem_sum[15] : {rem[14], X[16]} = 0001011111000110

X[32-1:0] = 11111101011111000110011011110011
D[32-1:0] = 00000000000000000010011001001001
(3D)[34-1:0] =  0000000000000000000111001011011011
(5D)[35-1:0] = 00000000000000000001011111101101101
(7D)[35-1:0] = 00000000000000000010000101111111111
stage[16].prev_q_0:
force_q_to_zero_prev_q_0[16] = |(D[31:17]) = 0
{rem_cout_prev_q_0[16], rem_sum_prev_q_0[16]} = 
  {1'b0, rem[14], X[16:15]}
+ {1'b0, ~D[16:0]}
+ {17'b0, ~divisor_sign}
= 00010111110001100 + 11101100110110110 + 1 = {1, 00000100101000011}
q_prev_q_0[16] = force_q_to_zero_prev_q_0[16] ? 1'b0 : rem_cout_prev_q_0[16] = 1
rem_prev_q_0[16] = q_prev_q_0[16] ? rem_sum_prev_q_0[16] : {rem[14], X[16:15]} = 00000100101000011

stage[16].prev_q_1:
force_q_to_zero_prev_q_1[16] = |(3D[33:17]) = 0
{rem_cout_prev_q_1[16], rem_sum_prev_q_1[16]} = 
  {1'b0, rem[14], X[16:15]}
+ {1'b0, ~3D[16:0]}
+ {17'b0, ~divisor_sign}
= 00010111110001100 + 11000110100100100 + 1 = {0, 11011110010110001}
q_prev_q_1[16] = force_q_to_zero_prev_q_1[16] ? 1'b0 : rem_cout_prev_q_1[16] = 0
rem_prev_q_1[16] = q_prev_q_1[16] ? rem_sum_prev_q_1[16] : {rem[15], X[15]} = 00010111110001100


stage[17].prev_q_00:
force_q_to_zero_prev_q_00[17] = |(D[31:18]) = 0
{rem_cout_prev_q_00[17], rem_sum_prev_q_00[17]} = 
  {1'b0, rem[14], X[16:14]}
+ {1'b0, ~D[17:0]}
+ {18'b0, ~divisor_sign}
= 000101111100011001 + 111101100110110110 + 1 = {1, 000011100011010000}
q_prev_q_00[17] = force_q_to_zero_prev_q_00[17] ? 1'b0 : rem_cout_prev_q_00[17] = 1
rem_prev_q_00[17] = q_prev_q_00[17] ? rem_sum_prev_q_00[17] : {rem[14], X[16:14]} = 000011100011010000

stage[17].prev_q_01:
force_q_to_zero_prev_q_01[17] = |(3D[33:18]) = 0
{rem_cout_prev_q_01[17], rem_sum_prev_q_01[17]} = 
  {1'b0, rem[14], X[16:14]}
+ {1'b0, ~3D[17:0]}
+ {18'b0, ~divisor_sign}
= 000101111100011001 + 111000110100100100 + 1 = {0, 111110110000111110}
q_prev_q_01[17] = force_q_to_zero_prev_q_01[17] ? 1'b0 : rem_cout_prev_q_01[17] = 0
rem_prev_q_01[17] = q_prev_q_01[17] ? rem_sum_prev_q_01[17] : {rem_prev_q_0[16], X[14]} = 000001001010000111

stage[17].prev_q_10:
force_q_to_zero_prev_q_10[17] = |(5D[34:18]) = 0
{rem_cout_prev_q_10[17], rem_sum_prev_q_10[17]} = 
  {1'b0, rem[14], X[16:14]}
+ {1'b0, ~5D[17:0]}
+ {18'b0, ~divisor_sign}
= 000101111100011001 + 110100000010010010 + 1 = {0, 111001111110101100}
q_prev_q_10[17] = force_q_to_zero_prev_q_10[17] ? 1'b0 : rem_cout_prev_q_10[17] = 0
rem_prev_q_10[17] = q_prev_q_10[17] ? rem_sum_prev_q_10[17] : {rem[15], X[15:14]} = 000101111100011001

stage[17].prev_q_11:
force_q_to_zero_prev_q_11[17] = |(7D[34:18]) = 1
{rem_cout_prev_q_11[17], rem_sum_prev_q_11[17]} = 
  {1'b0, rem[14], X[16:14]}
+ {1'b0, ~7D[17:0]}
+ {18'b0, ~divisor_sign}
= 000101111100011001 + 101111010000000000 + 1 = {0, 110101001100011010}
q_prev_q_11[17] = force_q_to_zero_prev_q_11[17] ? 1'b0 : rem_cout_prev_q_11[17] = 0
rem_prev_q_11[17] = q_prev_q_11[17] ? rem_sum_prev_q_11[17] : {rem_prev_q_1[16], X[14]} = 000101111100011001

rem[16] = quo[15] ? rem_prev_q_1[16] : rem_prev_q_0[16] = 00000100101000011
quo[16] = quo[15] ? q_prev_q_1[16] : q_prev_q_0[16] = 1
quo[17] = 
  ({(1){{quo[15], quo[16]} == 2'b00}} & q_prev_q_00[17])
| ({(1){{quo[15], quo[16]} == 2'b01}} & q_prev_q_01[17])
| ({(1){{quo[15], quo[16]} == 2'b10}} & q_prev_q_10[17])
| ({(1){{quo[15], quo[16]} == 2'b11}} & q_prev_q_11[17])
= 0
rem[17] = 
  ({(18){{quo[15], quo[16]} == 2'b00}} & rem_prev_q_00[17])
| ({(18){{quo[15], quo[16]} == 2'b01}} & rem_prev_q_01[17])
| ({(18){{quo[15], quo[16]} == 2'b10}} & rem_prev_q_10[17])
| ({(18){{quo[15], quo[16]} == 2'b11}} & rem_prev_q_11[17])
= 000001001010000111

Q = 000000000000011010

// =====================================================================================================================
stage[18]:
force_q_to_zero[18] = |(D[31:19]) = 0
{rem_cout[18], rem_sum[18]} = 
  {1'b0, rem[17], X[13]}
+ {1'b0, ~D[18:0]}
+ {19'b0, ~divisor_sign}
= 0000010010100001111 + 1111101100110110110 + 1 = {0, 1111111111011000110}
quo[18] = force_q_to_zero[18] ? 0 : rem_cout[18] = 0
rem[18] = quo[18] ? rem_sum[18] : {rem[17], X[13]} = 0000010010100001111

X[32-1:0] = 11111101011111000110011011110011
D[32-1:0] = 00000000000000000010011001001001
(3D)[34-1:0] =  0000000000000000000111001011011011
(5D)[35-1:0] = 00000000000000000001011111101101101
(7D)[35-1:0] = 00000000000000000010000101111111111
stage[19].prev_q_0:
force_q_to_zero_prev_q_0[19] = |(D[31:20]) = 0
{rem_cout_prev_q_0[19], rem_sum_prev_q_0[19]} = 
  {1'b0, rem[17], X[13:12]}
+ {1'b0, ~D[19:0]}
+ {20'b0, ~divisor_sign}
= 00000100101000011110 + 11111101100110110110 + 1 = {1, 00000010001111010101}
q_prev_q_0[19] = force_q_to_zero_prev_q_0[19] ? 1'b0 : rem_cout_prev_q_0[19] = 1
rem_prev_q_0[19] = q_prev_q_0[19] ? rem_sum_prev_q_0[19] : {rem[17], X[13:12]} = 00000010001111010101

stage[19].prev_q_1:
force_q_to_zero_prev_q_1[19] = |(3D[33:20]) = 0
{rem_cout_prev_q_1[19], rem_sum_prev_q_1[19]} = 
  {1'b0, rem[17], X[13:12]}
+ {1'b0, ~3D[19:0]}
+ {20'b0, ~divisor_sign}
= 00000100101000011110 + 11111000110100100100 + 1 = {0, 11111101011101000011}
q_prev_q_1[19] = force_q_to_zero_prev_q_1[19] ? 1'b0 : rem_cout_prev_q_1[19] = 0
rem_prev_q_1[19] = q_prev_q_1[19] ? rem_sum_prev_q_1[19] : {rem[18], X[12]} = 00000100101000011110


stage[20].prev_q_00:
force_q_to_zero_prev_q_00[20] = |(D[31:21]) = 0
{rem_cout_prev_q_00[20], rem_sum_prev_q_00[20]} = 
  {1'b0, rem[17], X[13:11]}
+ {1'b0, ~D[20:0]}
+ {21'b0, ~divisor_sign}
= 000001001010000111100 + 111111101100110110110 + 1 = {1, 000000110110111110011}
q_prev_q_00[20] = force_q_to_zero_prev_q_00[20] ? 1'b0 : rem_cout_prev_q_00[20] = 1
rem_prev_q_00[20] = q_prev_q_00[20] ? rem_sum_prev_q_00[20] : {rem[17], X[13:11]} = 000000110110111110011

stage[20].prev_q_01:
force_q_to_zero_prev_q_01[20] = |(3D[33:21]) = 0
{rem_cout_prev_q_01[20], rem_sum_prev_q_01[20]} = 
  {1'b0, rem[17], X[13:11]}
+ {1'b0, ~3D[20:0]}
+ {21'b0, ~divisor_sign}
= 000001001010000111100 + 111111000110100100100 + 1 = {1, 000000010000101100001}
q_prev_q_01[20] = force_q_to_zero_prev_q_01[20] ? 1'b0 : rem_cout_prev_q_01[20] = 1
rem_prev_q_01[20] = q_prev_q_01[20] ? rem_sum_prev_q_01[20] : {rem_prev_q_0[19], X[11]} = 000000010000101100001

stage[20].prev_q_10:
force_q_to_zero_prev_q_10[20] = |(5D[34:21]) = 0
{rem_cout_prev_q_10[20], rem_sum_prev_q_10[20]} = 
  {1'b0, rem[17], X[13:11]}
+ {1'b0, ~5D[20:0]}
+ {21'b0, ~divisor_sign}
= 000001001010000111100 + 111110100000010010010 + 1 = {0, 111111101010011001111}
q_prev_q_10[20] = force_q_to_zero_prev_q_10[20] ? 1'b0 : rem_cout_prev_q_10[20] = 0
rem_prev_q_10[20] = q_prev_q_10[20] ? rem_sum_prev_q_10[20] : {rem[18], X[12:11]} = 000001001010000111100

stage[20].prev_q_11:
force_q_to_zero_prev_q_11[20] = |(7D[34:21]) = 1
{rem_cout_prev_q_11[20], rem_sum_prev_q_11[20]} = 
  {1'b0, rem[17], X[13:11]}
+ {1'b0, ~7D[20:0]}
+ {21'b0, ~divisor_sign}
= 000001001010000111100 + 111101111010000000000 + 1 = {0, 111111000100000111101}
q_prev_q_11[20] = force_q_to_zero_prev_q_11[20] ? 1'b0 : rem_cout_prev_q_11[20] = 0
rem_prev_q_11[20] = q_prev_q_11[20] ? rem_sum_prev_q_11[20] : {rem_prev_q_1[19], X[11]} = 000001001010000111100

rem[19] = quo[18] ? rem_prev_q_1[19] : rem_prev_q_0[19] = 00000010001111010101
quo[19] = quo[18] ? q_prev_q_1[19] : q_prev_q_0[19] = 1
quo[20] = 
  ({(1){{quo[18], quo[19]} == 2'b00}} & q_prev_q_00[20])
| ({(1){{quo[18], quo[19]} == 2'b01}} & q_prev_q_01[20])
| ({(1){{quo[18], quo[19]} == 2'b10}} & q_prev_q_10[20])
| ({(1){{quo[18], quo[19]} == 2'b11}} & q_prev_q_11[20])
= 1
rem[20] = 
  ({(21){{quo[18], quo[19]} == 2'b00}} & rem_prev_q_00[20])
| ({(21){{quo[18], quo[19]} == 2'b01}} & rem_prev_q_01[20])
| ({(21){{quo[18], quo[19]} == 2'b10}} & rem_prev_q_10[20])
| ({(21){{quo[18], quo[19]} == 2'b11}} & rem_prev_q_11[20])
= 000000010000101100001

Q = 000000000000011010011

// =====================================================================================================================
stage[21]:
force_q_to_zero[21] = |(D[31:22]) = 0
{rem_cout[21], rem_sum[21]} = 
  {1'b0, rem[20], X[10]}
+ {1'b0, ~D[21:0]}
+ {22'b0, ~divisor_sign}
= 0000000100001011000011 + 1111111101100110110110 + 1 = {1, 0000000001110001111010}
quo[21] = force_q_to_zero[21] ? 0 : rem_cout[21] = 1
rem[21] = quo[21] ? rem_sum[21] : {rem[20], X[10]} = 0000000001110001111010

X[32-1:0] = 11111101011111000110011011110011
D[32-1:0] = 00000000000000000010011001001001
(3D)[34-1:0] =  0000000000000000000111001011011011
(5D)[35-1:0] = 00000000000000000001011111101101101
(7D)[35-1:0] = 00000000000000000010000101111111111
stage[22].prev_q_0:
force_q_to_zero_prev_q_0[22] = |(D[31:23]) = 0
{rem_cout_prev_q_0[22], rem_sum_prev_q_0[22]} = 
  {1'b0, rem[20], X[10:9]}
+ {1'b0, ~D[22:0]}
+ {23'b0, ~divisor_sign}
= 00000001000010110000111 + 11111111101100110110110 + 1 = {1, 00000000101111100111110}
q_prev_q_0[22] = force_q_to_zero_prev_q_0[22] ? 1'b0 : rem_cout_prev_q_0[22] = 1
rem_prev_q_0[22] = q_prev_q_0[22] ? rem_sum_prev_q_0[22] : {rem[20], X[10:9]} = 00000000101111100111110

stage[22].prev_q_1:
force_q_to_zero_prev_q_1[22] = |(3D[33:23]) = 0
{rem_cout_prev_q_1[22], rem_sum_prev_q_1[22]} = 
  {1'b0, rem[20], X[10:9]}
+ {1'b0, ~3D[22:0]}
+ {23'b0, ~divisor_sign}
= 00000001000010110000111 + 11111111000110100100100 + 1 = {1, 00000000001001010101100}
q_prev_q_1[22] = force_q_to_zero_prev_q_1[22] ? 1'b0 : rem_cout_prev_q_1[22] = 1
rem_prev_q_1[22] = q_prev_q_1[22] ? rem_sum_prev_q_1[22] : {rem[21], X[9]} = 00000000001001010101100


stage[23].prev_q_00:
force_q_to_zero_prev_q_00[23] = |(D[31:24]) = 0
{rem_cout_prev_q_00[23], rem_sum_prev_q_00[23]} = 
  {1'b0, rem[20], X[10:8]}
+ {1'b0, ~D[23:0]}
+ {24'b0, ~divisor_sign}
= 000000010000101100001110 + 111111111101100110110110 + 1 = {1, 000000001110010011000101}
q_prev_q_00[23] = force_q_to_zero_prev_q_00[23] ? 1'b0 : rem_cout_prev_q_00[23] = 1
rem_prev_q_00[23] = q_prev_q_00[23] ? rem_sum_prev_q_00[23] : {rem[20], X[10:8]} = 000000001110010011000101

stage[23].prev_q_01:
force_q_to_zero_prev_q_01[23] = |(3D[33:24]) = 0
{rem_cout_prev_q_01[23], rem_sum_prev_q_01[23]} = 
  {1'b0, rem[20], X[10:8]}
+ {1'b0, ~3D[23:0]}
+ {24'b0, ~divisor_sign}
= 000000010000101100001110 + 111111111000110100100100 + 1 = {1, 000000001001100000110011}
q_prev_q_01[23] = force_q_to_zero_prev_q_01[23] ? 1'b0 : rem_cout_prev_q_01[23] = 1
rem_prev_q_01[23] = q_prev_q_01[23] ? rem_sum_prev_q_01[23] : {rem_prev_q_0[22], X[8]} = 000000001011111001111100

stage[23].prev_q_10:
force_q_to_zero_prev_q_10[23] = |(5D[34:24]) = 0
{rem_cout_prev_q_10[23], rem_sum_prev_q_10[23]} = 
  {1'b0, rem[20], X[10:8]}
+ {1'b0, ~5D[23:0]}
+ {24'b0, ~divisor_sign}
= 000000010000101100001110 + 111111110100000010010010 + 1 = {1, 000000000100101110100001}
q_prev_q_10[23] = force_q_to_zero_prev_q_10[23] ? 1'b0 : rem_cout_prev_q_10[23] = 1
rem_prev_q_10[23] = q_prev_q_10[23] ? rem_sum_prev_q_10[23] : {rem[21], X[9:8]} = 000000000100101110100001

stage[23].prev_q_11:
force_q_to_zero_prev_q_11[23] = |(7D[34:24]) = 1
{rem_cout_prev_q_11[23], rem_sum_prev_q_11[23]} = 
  {1'b0, rem[20], X[10:8]}
+ {1'b0, ~7D[23:0]}
+ {24'b0, ~divisor_sign}
= 000000010000101100001110 + 111111101111010000000000 + 1 = {0, 111111111111111100001111}
q_prev_q_11[23] = force_q_to_zero_prev_q_11[23] ? 1'b0 : rem_cout_prev_q_11[23] = 0
rem_prev_q_11[23] = q_prev_q_11[23] ? rem_sum_prev_q_11[23] : {rem_prev_q_1[22], X[8]} = 000000000010010101011000

rem[22] = quo[21] ? rem_prev_q_1[22] : rem_prev_q_0[22] = 00000000001001010101100
quo[22] = quo[21] ? q_prev_q_1[22] : q_prev_q_0[22] = 1
quo[23] = 
  ({(1){{quo[21], quo[22]} == 2'b00}} & q_prev_q_00[23])
| ({(1){{quo[21], quo[22]} == 2'b01}} & q_prev_q_01[23])
| ({(1){{quo[21], quo[22]} == 2'b10}} & q_prev_q_10[23])
| ({(1){{quo[21], quo[22]} == 2'b11}} & q_prev_q_11[23])
= 0
rem[23] = 
  ({(24){{quo[21], quo[22]} == 2'b00}} & rem_prev_q_00[23])
| ({(24){{quo[21], quo[22]} == 2'b01}} & rem_prev_q_01[23])
| ({(24){{quo[21], quo[22]} == 2'b10}} & rem_prev_q_10[23])
| ({(24){{quo[21], quo[22]} == 2'b11}} & rem_prev_q_11[23])
= 000000000010010101011000

Q = 000000000000011010011110

// =====================================================================================================================
stage[24]:
force_q_to_zero[24] = |(D[31:25]) = 0
{rem_cout[24], rem_sum[24]} = 
  {1'b0, rem[23], X[7]}
+ {1'b0, ~D[24:0]}
+ {25'b0, ~divisor_sign}
= 0000000000100101010110001 + 1111111111101100110110110 + 1 = {1, 0000000000010010001101000}
quo[24] = force_q_to_zero[24] ? 0 : rem_cout[24] = 1
rem[24] = quo[24] ? rem_sum[24] : {rem[23], X[7]} = 0000000000010010001101000

X[32-1:0] = 11111101011111000110011011110011
D[32-1:0] = 00000000000000000010011001001001
(3D)[34-1:0] =  0000000000000000000111001011011011
(5D)[35-1:0] = 00000000000000000001011111101101101
(7D)[35-1:0] = 00000000000000000010000101111111111
stage[25].prev_q_0:
force_q_to_zero_prev_q_0[25] = |(D[31:26]) = 0
{rem_cout_prev_q_0[25], rem_sum_prev_q_0[25]} = 
  {1'b0, rem[23], X[7:6]}
+ {1'b0, ~D[25:0]}
+ {26'b0, ~divisor_sign}
= 00000000001001010101100011 + 11111111111101100110110110 + 1 = {1, 00000000000110111100011010}
q_prev_q_0[25] = force_q_to_zero_prev_q_0[25] ? 1'b0 : rem_cout_prev_q_0[25] = 1
rem_prev_q_0[25] = q_prev_q_0[25] ? rem_sum_prev_q_0[25] : {rem[23], X[7:6]} = 00000000000110111100011010

stage[25].prev_q_1:
force_q_to_zero_prev_q_1[25] = |(3D[33:26]) = 0
{rem_cout_prev_q_1[25], rem_sum_prev_q_1[25]} = 
  {1'b0, rem[23], X[7:6]}
+ {1'b0, ~3D[25:0]}
+ {26'b0, ~divisor_sign}
= 00000000001001010101100011 + 11111111111000110100100100 + 1 = {1, 00000000000010001010001000}
q_prev_q_1[25] = force_q_to_zero_prev_q_1[25] ? 1'b0 : rem_cout_prev_q_1[25] = 1
rem_prev_q_1[25] = q_prev_q_1[25] ? rem_sum_prev_q_1[25] : {rem[24], X[6]} = 00000000000010001010001000


stage[26].prev_q_00:
force_q_to_zero_prev_q_00[26] = |(D[31:27]) = 0
{rem_cout_prev_q_00[26], rem_sum_prev_q_00[26]} = 
  {1'b0, rem[23], X[7:5]}
+ {1'b0, ~D[26:0]}
+ {27'b0, ~divisor_sign}
= 000000000010010101011000111 + 111111111111101100110110110 + 1 = {1, 000000000010000010001111110}
q_prev_q_00[26] = force_q_to_zero_prev_q_00[26] ? 1'b0 : rem_cout_prev_q_00[26] = 1
rem_prev_q_00[26] = q_prev_q_00[26] ? rem_sum_prev_q_00[26] : {rem[23], X[7:5]} = 000000000010000010001111110

stage[26].prev_q_01:
force_q_to_zero_prev_q_01[26] = |(3D[33:27]) = 0
{rem_cout_prev_q_01[26], rem_sum_prev_q_01[26]} = 
  {1'b0, rem[23], X[7:5]}
+ {1'b0, ~3D[26:0]}
+ {27'b0, ~divisor_sign}
= 000000000010010101011000111 + 111111111111000110100100100 + 1 = {1, 000000000001011011111101100}
q_prev_q_01[26] = force_q_to_zero_prev_q_01[26] ? 1'b0 : rem_cout_prev_q_01[26] = 1
rem_prev_q_01[26] = q_prev_q_01[26] ? rem_sum_prev_q_01[26] : {rem_prev_q_0[25], X[5]} = 000000000001101111000110101

stage[26].prev_q_10:
force_q_to_zero_prev_q_10[26] = |(5D[34:27]) = 0
{rem_cout_prev_q_10[26], rem_sum_prev_q_10[26]} = 
  {1'b0, rem[23], X[7:5]}
+ {1'b0, ~5D[26:0]}
+ {27'b0, ~divisor_sign}
= 000000000010010101011000111 + 111111111110100000010010010 + 1 = {1, 000000000000110101101011010}
q_prev_q_10[26] = force_q_to_zero_prev_q_10[26] ? 1'b0 : rem_cout_prev_q_10[26] = 1
rem_prev_q_10[26] = q_prev_q_10[26] ? rem_sum_prev_q_10[26] : {rem[24], X[6:5]} = 000000000000110101101011010

stage[26].prev_q_11:
force_q_to_zero_prev_q_11[26] = |(7D[34:27]) = 1
{rem_cout_prev_q_11[26], rem_sum_prev_q_11[26]} = 
  {1'b0, rem[23], X[7:5]}
+ {1'b0, ~7D[26:0]}
+ {27'b0, ~divisor_sign}
= 000000000010010101011000111 + 111111111101111010000000000 + 1 = {1, 000000000000001111011001000}
q_prev_q_11[26] = force_q_to_zero_prev_q_11[26] ? 1'b0 : rem_cout_prev_q_11[26] = 0
rem_prev_q_11[26] = q_prev_q_11[26] ? rem_sum_prev_q_11[26] : {rem_prev_q_1[25], X[5]} = 000000000000001111011001000

rem[25] = quo[24] ? rem_prev_q_1[25] : rem_prev_q_0[25] = 00000000000010001010001000
quo[25] = quo[24] ? q_prev_q_1[25] : q_prev_q_0[25] = 1
quo[26] = 
  ({(1){{quo[24], quo[25]} == 2'b00}} & q_prev_q_00[26])
| ({(1){{quo[24], quo[25]} == 2'b01}} & q_prev_q_01[26])
| ({(1){{quo[24], quo[25]} == 2'b10}} & q_prev_q_10[26])
| ({(1){{quo[24], quo[25]} == 2'b11}} & q_prev_q_11[26])
= 1
rem[26] = 
  ({(27){{quo[24], quo[25]} == 2'b00}} & rem_prev_q_00[26])
| ({(27){{quo[24], quo[25]} == 2'b01}} & rem_prev_q_01[26])
| ({(27){{quo[24], quo[25]} == 2'b10}} & rem_prev_q_10[26])
| ({(27){{quo[24], quo[25]} == 2'b11}} & rem_prev_q_11[26])
= 000000000000001111011001000

Q = 000000000000011010011110111

// =====================================================================================================================
stage[27]:
force_q_to_zero[27] = |(D[31:28]) = 0
{rem_cout[27], rem_sum[27]} = 
  {1'b0, rem[26], X[4]}
+ {1'b0, ~D[27:0]}
+ {28'b0, ~divisor_sign}
= 0000000000000011110110010001 + 1111111111111101100110110110 + 1 = {1, 0000000000000001011101001000}
quo[27] = force_q_to_zero[27] ? 0 : rem_cout[27] = 1
rem[27] = quo[27] ? rem_sum[27] : {rem[26], X[4]} = 0000000000000001011101001000

X[32-1:0] = 11111101011111000110011011110011
D[32-1:0] = 00000000000000000010011001001001
(3D)[34-1:0] =  0000000000000000000111001011011011
(5D)[35-1:0] = 00000000000000000001011111101101101
(7D)[35-1:0] = 00000000000000000010000101111111111
stage[28].prev_q_0:
force_q_to_zero_prev_q_0[28] = |(D[31:29]) = 0
{rem_cout_prev_q_0[28], rem_sum_prev_q_0[28]} = 
  {1'b0, rem[26], X[4:3]}
+ {1'b0, ~D[28:0]}
+ {29'b0, ~divisor_sign}
= 00000000000000111101100100010 + 11111111111111101100110110110 + 1 = {1, 00000000000000101010011011001}
q_prev_q_0[28] = force_q_to_zero_prev_q_0[28] ? 1'b0 : rem_cout_prev_q_0[28] = 1
rem_prev_q_0[28] = q_prev_q_0[28] ? rem_sum_prev_q_0[28] : {rem[26], X[4:3]} = 00000000000000101010011011001

stage[28].prev_q_1:
force_q_to_zero_prev_q_1[28] = |(3D[33:29]) = 0
{rem_cout_prev_q_1[28], rem_sum_prev_q_1[28]} = 
  {1'b0, rem[26], X[4:3]}
+ {1'b0, ~3D[28:0]}
+ {29'b0, ~divisor_sign}
= 00000000000000111101100100010 + 11111111111111000110100100100 + 1 = {1, 00000000000000000100001000111}
q_prev_q_1[28] = force_q_to_zero_prev_q_1[28] ? 1'b0 : rem_cout_prev_q_1[28] = 1
rem_prev_q_1[28] = q_prev_q_1[28] ? rem_sum_prev_q_1[28] : {rem[27], X[3]} = 00000000000000000100001000111


stage[29].prev_q_00:
force_q_to_zero_prev_q_00[29] = |(D[31:30]) = 0
{rem_cout_prev_q_00[29], rem_sum_prev_q_00[29]} = 
  {1'b0, rem[26], X[4:2]}
+ {1'b0, ~D[29:0]}
+ {30'b0, ~divisor_sign}
= 000000000000001111011001000100 + 111111111111111101100110110110 + 1 = {1, 000000000000001100111111111011}
q_prev_q_00[29] = force_q_to_zero_prev_q_00[29] ? 1'b0 : rem_cout_prev_q_00[29] = 1
rem_prev_q_00[29] = q_prev_q_00[29] ? rem_sum_prev_q_00[29] : {rem[26], X[4:2]} = 000000000000001100111111111011

stage[29].prev_q_01:
force_q_to_zero_prev_q_01[29] = |(3D[33:30]) = 0
{rem_cout_prev_q_01[29], rem_sum_prev_q_01[29]} = 
  {1'b0, rem[26], X[4:2]}
+ {1'b0, ~3D[29:0]}
+ {30'b0, ~divisor_sign}
= 000000000000001111011001000100 + 111111111111111000110100100100 + 1 = {1, 000000000000001000001101101001}
q_prev_q_01[29] = force_q_to_zero_prev_q_01[29] ? 1'b0 : rem_cout_prev_q_01[29] = 1
rem_prev_q_01[29] = q_prev_q_01[29] ? rem_sum_prev_q_01[29] : {rem_prev_q_0[28], X[2]} = 000000000000001000001101101000

stage[29].prev_q_10:
force_q_to_zero_prev_q_10[29] = |(5D[34:30]) = 0
{rem_cout_prev_q_10[29], rem_sum_prev_q_10[29]} = 
  {1'b0, rem[26], X[4:2]}
+ {1'b0, ~5D[29:0]}
+ {30'b0, ~divisor_sign}
= 000000000000001111011001000100 + 111111111111110100000010010010 + 1 = {1, 000000000000000011011011010111}
q_prev_q_10[29] = force_q_to_zero_prev_q_10[29] ? 1'b0 : rem_cout_prev_q_10[29] = 1
rem_prev_q_10[29] = q_prev_q_10[29] ? rem_sum_prev_q_10[29] : {rem[27], X[3:2]} = 000000000000000011011011010111

stage[29].prev_q_11:
force_q_to_zero_prev_q_11[29] = |(7D[34:30]) = 1
{rem_cout_prev_q_11[29], rem_sum_prev_q_11[29]} = 
  {1'b0, rem[26], X[4:2]}
+ {1'b0, ~7D[29:0]}
+ {30'b0, ~divisor_sign}
= 000000000000001111011001000100 + 111111111111101111010000000000 + 1 = {0, 111111111111111110101001000101}
q_prev_q_11[29] = force_q_to_zero_prev_q_11[29] ? 1'b0 : rem_cout_prev_q_11[29] = 0
rem_prev_q_11[29] = q_prev_q_11[29] ? rem_sum_prev_q_11[29] : {rem_prev_q_1[28], X[2]} = 000000000000000001000010001110

rem[28] = quo[27] ? rem_prev_q_1[28] : rem_prev_q_0[28] = 00000000000000000100001000111
quo[28] = quo[27] ? q_prev_q_1[28] : q_prev_q_0[28] = 1
quo[29] = 
  ({(1){{quo[27], quo[28]} == 2'b00}} & q_prev_q_00[29])
| ({(1){{quo[27], quo[28]} == 2'b01}} & q_prev_q_01[29])
| ({(1){{quo[27], quo[28]} == 2'b10}} & q_prev_q_10[29])
| ({(1){{quo[27], quo[28]} == 2'b11}} & q_prev_q_11[29])
= 0
rem[29] = 
  ({(30){{quo[27], quo[28]} == 2'b00}} & rem_prev_q_00[29])
| ({(30){{quo[27], quo[28]} == 2'b01}} & rem_prev_q_01[29])
| ({(30){{quo[27], quo[28]} == 2'b10}} & rem_prev_q_10[29])
| ({(30){{quo[27], quo[28]} == 2'b11}} & rem_prev_q_11[29])
= 000000000000000001000010001110

Q = 000000000000011010011110111110

// =====================================================================================================================
stage[30]:
force_q_to_zero[30] = |(D[31:31]) = 0
{rem_cout[30], rem_sum[30]} = 
  {1'b0, rem[29], X[1]}
+ {1'b0, ~D[30:0]}
+ {31'b0, ~divisor_sign}
= 0000000000000000010000100011101 + 1111111111111111101100110110110 + 1 = {0, 1111111111111111111101011010100}
quo[30] = force_q_to_zero[30] ? 0 : rem_cout[30] = 0
rem[30] = quo[30] ? rem_sum[30] : {rem[29], X[1]} = 0000000000000000010000100011101

X[32-1:0] = 11111101011111000110011011110011
D[32-1:0] = 00000000000000000010011001001001
(3D)[34-1:0] =  0000000000000000000111001011011011
(5D)[35-1:0] = 00000000000000000001011111101101101
(7D)[35-1:0] = 00000000000000000010000101111111111
stage[31].prev_q_0:
force_q_to_zero_prev_q_0[31] = 0
{rem_cout_prev_q_0[31], rem_sum_prev_q_0[31]} = 
  {1'b0, rem[29], X[1:0]}
+ {1'b0, ~D[31:0]}
+ {32'b0, ~divisor_sign}
= 00000000000000000100001000111011 + 11111111111111111101100110110110 + 1 = {1, 00000000000000000001101111110010}
q_prev_q_0[31] = force_q_to_zero_prev_q_0[31] ? 1'b0 : rem_cout_prev_q_0[31] = 1
rem_prev_q_0[31] = q_prev_q_0[31] ? rem_sum_prev_q_0[31] : {rem[29], X[1:0]} = 00000000000000000001101111110010

stage[31].prev_q_1:
force_q_to_zero_prev_q_1[31] = 0
{rem_cout_prev_q_1[31], rem_sum_prev_q_1[31]} = 
  {1'b0, rem[29], X[1:0]}
+ {1'b0, ~3D[31:0]}
+ {32'b0, ~divisor_sign}
= 00000000000000000100001000111011 + 11111111111111111000110100100100 + 1 = {0, 11111111111111111100111101100000}
q_prev_q_1[31] = force_q_to_zero_prev_q_1[31] ? 1'b0 : rem_cout_prev_q_1[31] = 0
rem_prev_q_1[31] = q_prev_q_1[31] ? rem_sum_prev_q_1[31] : {rem[30], X[0]} = 00000000000000000100001000111011

rem[31] = quo[30] ? rem_prev_q_1[31] : rem_prev_q_0[31] = 00000000000000000001101111110010
quo[31] = quo[30] ? q_prev_q_1[31] : q_prev_q_0[31] = 1

FINAL_REM = 00000000000000000001101111110010
FINAL_Q = 00000000000001101001111011111001

Correct !!!






















