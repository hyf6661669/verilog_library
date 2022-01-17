参考文章:
"Digit-Recurrence Dividers with Reduced Logical Depth". Elisardo Antelo.

按照定义, 要求:
1/2 <= X/D < 1
设小数点在"X[25]和X[24]"之间, 即"D[25]和D[24]"之间
X[26-1:0] = Dividend[26-1:0] = 0_1111101011011000011011001
D[26-1:0] = Divisor[26-1:0]  = 0_1010100111010000101001001
Q[25-1:0] = X / D = 32878809 / 22257993 = 1.4771686288157247600895552442666 = 
1_011110100010011110111001_001001110111000011010001110
Q_no_rup[25-1:0] 	= 1_011110100010011110111001
Q_rup[25-1:0] 		= 1_011110100010011110111001

根据D的值, 可得选择常数:
m[-1] = -16 = 111_0000
m[+0] = - 6 = 111_1001
m[+1] = + 4 = 000_0100
m[+2] = +15 = 000_1111

m[-1]_补码_trunc_5_5 = 00001_00000
m[-1]_补码_trunc_2_5 = 01_00000
m[+0]_补码_trunc_5_5 = 00000_01100
m[+0]_补码_trunc_3_4 = 000_0110
m[+1]_补码_trunc_5_5 = 11111_11000
m[+1]_补码_trunc_3_4 = 111_1100
m[+2]_补码_trunc_5_5 = 11111_00010
m[+2]_补码_trunc_2_5 = 11_00010


由参考文献可知, |w[i]| < 1, 因此需要使用1-bit符号位来表示w[i], 符号位右边的都是小数:
小数点在"w[27]和w[26]"之间.

可知"w_sum[i]和w_carry[i]"均为28-bit变量:
4 * w_sum[i][28-1:0] = yyy.yyyy...
4 * w_carry[i][28-1:0] = yyy.yyyy...

将"+2D, +D, -D, -2D"进行符号扩展至30-bit(即和"4 * w_sum"的宽度一样), 可得:
+ D = 000_101010011101000010100100100
+2D = 001_010100111010000101001001000
- D = 111_010101100010111101011011100
-2D = 110_101011000101111010110111000

4 * (+ D) = 00010_101001110100001010010010000
4 * (+2D) = 00101_010011101000010100100100000
4 * (- D) = 11101_010110001011110101101110000
4 * (-2D) = 11010_101100010111101011011100000

初始化:
w[0][28-1:0] = X / 4 = 0_001111101011011000011011001
w_sum[0] = 0_001111101011011000011011001
w_carry[0] = 0_000000000000000000000000000
q[0] = 0
截取至w[0]小数点后6位, w_trunc[0][7-1:0] = w[0][27:21] = 0_001111
(4 * w[0])_trunc_3_4 = 000_1111, "belongs to [m[2], +Inf)" -> q[1] = +2
q_pos = 10
q_neg = 00

ITER[0]:
post_process: 
1. 将"sum/carry"调整到区间"[-1, +1)"内 (ADJ)
1.1: 1 <= abs(sum) < 3, sum = sum - 2.
1.2: abs(sum) >= 3, sum = sum - 3.
1.3: -3 < abs(sum) <= -1, sum = sum + 2.
1.4: abs(sum) <= -3, sum = sum + 3.
第1个例子里这个"ADJ"步骤我操作错了，没考虑到绝对值超过3的情况(貌似也没出现 _??_)，但是还是确保了"w_sum[i] + w_carry[i] = w[i]"
carry的处理方法同sum.
2. 丢弃小数点左边的2个整数位, 保留符号位.
// Standard Method:
// carry-save:
w_sum[1] = csa_sum(4 * w_sum[0], 4 * w_carry[0], -q[1] * D)_post_process = 
1_010101101000011011011011100
w_carry[1] = csa_carry(4 * w_sum[0], 4 * w_carry[0], -q[1] * D)_post_process = 
0_010100001011000001001000000
(4 * w_sum[1])_trunc_3_4 + (4 * w_carry[1])_trunc_3_4 = 
101_0101 + 001_0100 = 110_1001, "belongs to [-Inf, m[-1])" -> q[2] = -2
// non-redundant:
4 * w[0] + (-q[1] * D) = 
000_111110101101100001101100100 + 
110_101011000101111010110111000 = 
111_101001110011011100100011100 -> 
w[1] = 1_101001110011011100100011100
4 * w[1] = 110_100111001101110010001110000
(4 * w[1])_trunc_3_4 = 110_1001, "belongs to [-Inf, m[-1])" -> q[2] = -2
// New Method
// Retimng + carry-save, full-width:
temp[1][0] = ((16 * w_sum[0])_trunc_5_5 + (16 * w_carry[0])_trunc_5_5 + m[-1]_补码_trunc_5_5)_trunc_5_5 = 
00011_11101 + 00000_00000 + 00001_00000 = 00100_11101
temp[1][1] = ((16 * w_sum[0])_trunc_5_5 + (16 * w_carry[0])_trunc_5_5 + m[+0]_补码_trunc_5_5)_trunc_5_5 = 
00011_11101 + 00000_00000 + 00000_01100 = 00100_01001
temp[1][2] = ((16 * w_sum[0])_trunc_5_5 + (16 * w_carry[0])_trunc_5_5 + m[+1]_补码_trunc_5_5)_trunc_5_5 = 
00011_11101 + 00000_00000 + 11111_11000 = 00011_10101
temp[1][3] = ((16 * w_sum[0])_trunc_5_5 + (16 * w_carry[0])_trunc_5_5 + m[+2]_补码_trunc_5_5)_trunc_5_5 = 
00011_11101 + 00000_00000 + 11111_00010 = 00010_11111
// 做保留3位整数操作的时候, 丢弃原始的5位整数中符号位右边的2-bit; 保留4位小数的时候，丢弃lsb的小数位.
(temp[1][0] + (-4 * q[1] * D)_trunc_5_5)_post_process_trunc_3_4 = (00100_11101 + 11010_10110)_post_process_trunc_3_4 = 
(11111_10011)_post_process_trunc_3_4 = 111_1001 < 0
(temp[1][1] + (-4 * q[1] * D)_trunc_5_5)_post_process_trunc_3_4 = (00100_01001 + 11010_10110)_post_process_trunc_3_4 = 
(11110_11111)_post_process_trunc_3_4 = 110_1111 < 0
(temp[1][2] + (-4 * q[1] * D)_trunc_5_5)_post_process_trunc_3_4 = (00011_10101 + 11010_10110)_post_process_trunc_3_4 = 
(11110_01011)_post_process_trunc_3_4 = 110_0101 < 0
(temp[1][3] + (-4 * q[1] * D)_trunc_5_5)_post_process_trunc_3_4 = (00010_11111 + 11010_10110)_post_process_trunc_3_4 = 
(11101_10101)_post_process_trunc_3_4 = 101_1010 < 0
根据比较结果(Sign Detection, SD)可得, "belongs to [-Inf, m[-1])" -> q[2] = -2
// Retimng + carry-save, reduced-width, early version:
(temp[1][0] + (-4 * q[1] * D)_trunc_5_5)_reduced_trunc_2_4 = 
11_1001 < 0
(temp[1][1] + (-4 * q[1] * D)_trunc_5_5)_reduced_trunc_3_3 = 
110_111 < 0
(temp[1][2] + (-4 * q[1] * D)_trunc_5_5)_reduced_trunc_3_3 = 
110_010 < 0
(temp[1][3] + (-4 * q[1] * D)_trunc_5_5)_reduced_trunc_2_4 = 
01_1010 >= 0, don't care.
根据比较结果(Sign Detection, SD)可得, "belongs to [-Inf, m[-1])" -> q[2] = -2
// Reduced-width, Method from the paper:
temp[1][0] = ((16 * w_sum[0])_reduced_2_5 + (16 * w_carry[0])_reduced_2_5 + m[-1]_补码_reduced_2_5)_reduced_2_5 = 
11_11101 + 00_00000 + 01_00000 = 00_11101
temp[1][1] = ((16 * w_sum[0])_reduced_3_4 + (16 * w_carry[0])_reduced_3_4 + m[+0]_补码_reduced_3_4)_reduced_3_4 = 
011_1110 + 000_0000 + 000_0110 = 100_0100
temp[1][2] = ((16 * w_sum[0])_reduced_3_4 + (16 * w_carry[0])_reduced_3_4 + m[+1]_补码_reduced_3_4)_reduced_3_4 = 
011_1110 + 000_0000 + 111_1100 = 011_1010
temp[1][3] = ((16 * w_sum[0])_reduced_2_5 + (16 * w_carry[0])_reduced_2_5 + m[+2]_补码_reduced_2_5)_reduced_2_5 = 
11_11101 + 00_00000 + 11_00010 = 10_11111
// reduced_2_4: 使用2-bit整数和4-bit小数表示"temp[x][y] + (-4 * q[x] * D)"的结果, 因此只需要将"(temp[x][y] + (-4 * q[x] * D))_sum_reduced_2_4"和
// "(temp[x][y] + (-4 * q[x] * D))_carry_reduced_2_4"输入到"SD"中即可
// reduced_3_3: 使用3-bit整数和3-bit小数表示"temp[x][y] + (-4 * q[x] * D)"的结果, 因此只需要将"(temp[x][y] + (-4 * q[x] * D))_sum_reduced_3_3"和
// "(temp[x][y] + (-4 * q[x] * D))_carry_reduced_3_3"输入到"SD"中即可
(temp[1][0] + (-4 * q[1] * D)_reduced_2_5)_reduced_2_4 = (00_11101 + 10_10110)_reduced_2_4 = 
(11_10011)_reduced_2_4 = 11_1001 < 0
(temp[1][1] + (-4 * q[1] * D)_reduced_3_4)_reduced_3_3 = (100_0100 + 010_1011)_reduced_3_3 = 
(110_1111)_reduced_3_3 = 110_111 < 0
(temp[1][2] + (-4 * q[1] * D)_reduced_3_4)_reduced_3_3 = (011_1010 + 010_1011)_reduced_3_3 = 
(110_0101)_reduced_3_3 = 110_010 < 0
(temp[1][3] + (-4 * q[1] * D)_reduced_2_5)_reduced_2_4 = (10_11111 + 10_10110)_reduced_2_4 = 
(01_10101)_reduced_2_4 = 01_1010 >= 0, don't care.
根据比较结果(Sign Detection, SD)可得, "belongs to [-Inf, m[-1])" -> q[2] = -2
q_pos = 1000
q_neg = 0010

ITER[1]:
// Standard Method
// carry-save:
w_sum[2] = csa_sum(4 * w_sum[1], 4 * w_carry[1], -q[2] * D)_post_process = 
1_010010110111101100000111000
w_carry[2] = csa_carry(4 * w_sum[1], 4 * w_carry[1], -q[2] * D)_post_process = 
0_101001010000001011010000000
(4 * w_sum[2])_trunc_3_4 + (4 * w_carry[2])_trunc_3_4 = 
101_0010 + 010_1001 = 111_1011, "belongs to [m[0], m[1])" -> q[3] = 0
// non-redundant:
4 * w[1] + (-q[2] * D) = 
110_100111001101110010001110000 + 
001_010100111010000101001001000 = 
111_111100000111110111010111000 -> 
w[2] = 1_111100000111110111010111000
4 * w[2] = 111_110000011111011101011100000
(4 * w[2])_trunc_3_4 = 111_1100, "belongs to [m[0], m[1])" -> q[3] = 0
// New Method
// Retimng + carry-save, full-width:
temp[2][0] = ((16 * w_sum[1])_trunc_5_5 + (16 * w_carry[1])_trunc_5_5 + m[-1]_补码_trunc_5_5)_trunc_5_5 = 
10101_01101 + 00101_00001 + 00001_00000 = 11011_01110
temp[2][1] = ((16 * w_sum[1])_trunc_5_5 + (16 * w_carry[1])_trunc_5_5 + m[+0]_补码_trunc_5_5)_trunc_5_5 = 
10101_01101 + 00101_00001 + 00000_01100 = 11010_11010
temp[2][2] = ((16 * w_sum[1])_trunc_5_5 + (16 * w_carry[1])_trunc_5_5 + m[+1]_补码_trunc_5_5)_trunc_5_5 = 
10101_01101 + 00101_00001 + 11111_11000 = 11010_00110
temp[2][3] = ((16 * w_sum[1])_trunc_5_5 + (16 * w_carry[1])_trunc_5_5 + m[+2]_补码_trunc_5_5)_trunc_5_5 = 
10101_01101 + 00101_00001 + 11111_00010 = 11001_10000
// 做保留3位整数操作的时候, 丢弃原始的5位整数中符号位右边的2-bit; 保留4位小数的时候，丢弃lsb的小数位.
(temp[2][0] + (-4 * q[2] * D)_trunc_5_5)_post_process_trunc_3_4 = (11011_01110 + 00101_01001)_post_process_trunc_3_4 = 
(00000_10111)_post_process_trunc_3_4 = 000_1011 >= 0
(temp[2][1] + (-4 * q[2] * D)_trunc_5_5)_post_process_trunc_3_4 = (11010_11010 + 00101_01001)_post_process_trunc_3_4 = 
(00000_00011)_post_process_trunc_3_4 = 000_0001 >= 0
(temp[2][2] + (-4 * q[2] * D)_trunc_5_5)_post_process_trunc_3_4 = (11010_00110 + 00101_01001)_post_process_trunc_3_4 = 
(11111_01111)_post_process_trunc_3_4 = 111_0111 < 0
(temp[2][3] + (-4 * q[2] * D)_trunc_5_5)_post_process_trunc_3_4 = (11001_10000 + 00101_01001)_post_process_trunc_3_4 = 
(11110_11001)_post_process_trunc_3_4 = 110_1100 < 0
根据比较结果(Sign Detection, SD)可得, "belongs to [m[0], m[1])" -> q[3] = 0
// Retimng + carry-save, reduced-width, early version:
(temp[2][0] + (-4 * q[2] * D)_trunc_5_5)_reduced_trunc_2_4 = 
00_1011 >= 0, don't care.
(temp[2][1] + (-4 * q[2] * D)_trunc_5_5)_reduced_trunc_3_3 = 
000_000 >= 0
(temp[2][2] + (-4 * q[2] * D)_trunc_5_5)_reduced_trunc_3_3 = 
111_011 < 0
(temp[2][3] + (-4 * q[2] * D)_trunc_5_5)_reduced_trunc_2_4 = 
10_1100 < 0, don't care.
根据比较结果(Sign Detection, SD)可得, "belongs to [m[0], m[1])" -> q[3] = 0
// Reduced-width, Method from the paper:
temp[2][0] = ((16 * w_sum[1])_reduced_2_5 + (16 * w_carry[1])_reduced_2_5 + m[-1]_补码_reduced_2_5)_reduced_2_5 = 
01_01101 + 01_00001 + 01_00000 = 11_01110
temp[2][1] = ((16 * w_sum[1])_reduced_3_4 + (16 * w_carry[1])_reduced_3_4 + m[+0]_补码_reduced_3_4)_reduced_3_4 = 
101_0110 + 101_0000 + 000_0110 = 010_1100
temp[2][2] = ((16 * w_sum[1])_reduced_3_4 + (16 * w_carry[1])_reduced_3_4 + m[+1]_补码_reduced_3_4)_reduced_3_4 = 
101_0110 + 101_0000 + 111_1100 = 010_0010
temp[2][3] = ((16 * w_sum[1])_reduced_2_5 + (16 * w_carry[1])_reduced_2_5 + m[+2]_补码_reduced_2_5)_reduced_2_5 = 
01_01101 + 01_00001 + 11_00010 = 01_10000
// reduced_2_4: 使用2-bit整数和4-bit小数表示"temp[x][y] + (-4 * q[x] * D)"的结果, 因此只需要将"(temp[x][y] + (-4 * q[x] * D))_sum_reduced_2_4"和
// "(temp[x][y] + (-4 * q[x] * D))_carry_reduced_2_4"输入到"SD"中即可
// reduced_3_3: 使用3-bit整数和3-bit小数表示"temp[x][y] + (-4 * q[x] * D)"的结果, 因此只需要将"(temp[x][y] + (-4 * q[x] * D))_sum_reduced_3_3"和
// "(temp[x][y] + (-4 * q[x] * D))_carry_reduced_3_3"输入到"SD"中即可
(temp[2][0] + (-4 * q[2] * D)_reduced_2_5)_reduced_2_4 = (11_01110 + 01_01001)_reduced_2_4 = 
(00_10111)_reduced_2_4 = 00_1011 >= 0, don't care.
(temp[2][1] + (-4 * q[2] * D)_reduced_3_4)_reduced_3_3 = (010_1100 + 101_0100)_reduced_3_3 = 
(000_0000)_reduced_3_3 = 000_000 >= 0
(temp[2][2] + (-4 * q[2] * D)_reduced_3_4)_reduced_3_3 = (010_0010 + 101_0100)_reduced_3_3 = 
(111_0110)_reduced_3_3 = 111_0110 < 0
(temp[2][3] + (-4 * q[2] * D)_reduced_2_5)_reduced_2_4 = (01_10000 + 01_01001)_reduced_2_4 = 
(10_11001)_reduced_2_4 = 10_1100 < 0, don't care.
根据比较结果(Sign Detection, SD)可得, "belongs to [m[0], m[1])" -> q[3] = 0
q_pos = 1000_00
q_neg = 0010_00

ITER[2]:
// Standard Method
// carry-save:
w_sum[3] = csa_sum(4 * w_sum[2], 4 * w_carry[2], -q[3] * D)_post_process = 
1_001011011110110000011100000
w_carry[3] = csa_carry(4 * w_sum[2], 4 * w_carry[2], -q[3] * D)_post_process = 
0_100101000000101101000000000
(4 * w_sum[3])_trunc_3_4 + (4 * w_carry[3])_trunc_3_4 = 
100_1011 + 010_0101 = 111_0000, "belongs to [m[-1], m[0])" -> q[4] = -1
// non-redundant:
4 * w[2] + (-q[3] * D) = 
111_110000011111011101011100000 + 
000_000000000000000000000000000 = 
111_000110000010011010110111100 -> 
w[3] = 1_110000011111011101011100000
4 * w[3] = 111_000001111101110101110000000
(4 * w[3])_trunc_3_4 = 111_0000, "belongs to [m[-1], m[0])" -> q[4] = -1
// New Method
// Retimng + carry-save, full-width:
temp[3][0] = ((16 * w_sum[2])_trunc_5_5 + (16 * w_carry[2])_trunc_5_5 + m[-1]_补码_trunc_5_5)_trunc_5_5 = 
10100_10110 + 01010_01010 + 00001_00000 = 00000_00000
temp[3][1] = ((16 * w_sum[2])_trunc_5_5 + (16 * w_carry[2])_trunc_5_5 + m[+0]_补码_trunc_5_5)_trunc_5_5 = 
10100_10110 + 01010_01010 + 00000_01100 = 11111_01100
temp[3][2] = ((16 * w_sum[2])_trunc_5_5 + (16 * w_carry[2])_trunc_5_5 + m[+1]_补码_trunc_5_5)_trunc_5_5 = 
10100_10110 + 01010_01010 + 11111_11000 = 11110_11000
temp[3][3] = ((16 * w_sum[2])_trunc_5_5 + (16 * w_carry[2])_trunc_5_5 + m[+2]_补码_trunc_5_5)_trunc_5_5 = 
10100_10110 + 01010_01010 + 11111_00010 = 11110_00010
// 做保留3位整数操作的时候, 丢弃原始的5位整数中符号位右边的2-bit; 保留4位小数的时候，丢弃lsb的小数位.
(temp[3][0] + (-4 * q[3] * D)_trunc_5_5)_post_process_trunc_3_4 = (00000_00000 + 00000_00000)_post_process_trunc_3_4 = 
(00000_00000)_post_process_trunc_3_4 = 000_0000 >= 0
(temp[3][1] + (-4 * q[3] * D)_trunc_5_5)_post_process_trunc_3_4 = (11111_01100 + 00000_00000)_post_process_trunc_3_4 = 
(11111_01100)_post_process_trunc_3_4 = 111_0110 < 0
(temp[3][2] + (-4 * q[3] * D)_trunc_5_5)_post_process_trunc_3_4 = (11110_11000 + 00000_00000)_post_process_trunc_3_4 = 
(11110_11000)_post_process_trunc_3_4 = 110_1100 < 0
(temp[3][3] + (-4 * q[3] * D)_trunc_5_5)_post_process_trunc_3_4 = (11110_00010 + 00000_00000)_post_process_trunc_3_4 = 
(11110_00010)_post_process_trunc_3_4 = 110_0001 < 0
根据比较结果(Sign Detection, SD)可得, "belongs to [m[-1], m[0])" -> q[4] = -1
// Retimng + carry-save, reduced-width, early version:
(temp[3][0] + (-4 * q[3] * D)_trunc_5_5)_reduced_trunc_2_4 = 
00_0000 >= 0
(temp[3][1] + (-4 * q[3] * D)_trunc_5_5)_reduced_trunc_3_3 = 
111_011 < 0
(temp[3][2] + (-4 * q[3] * D)_trunc_5_5)_reduced_trunc_3_3 = 
110_110 < 0
(temp[3][3] + (-4 * q[3] * D)_trunc_5_5)_reduced_trunc_2_4 = 
10_0001 < 0, don't care.
根据比较结果(Sign Detection, SD)可得, "belongs to [m[-1], m[0])" -> q[4] = -1
// Reduced-width, Method from the paper:
temp[3][0] = ((16 * w_sum[2])_reduced_2_5 + (16 * w_carry[2])_reduced_2_5 + m[-1]_补码_reduced_2_5)_reduced_2_5 = 
00_10110 + 10_01010 + 01_00000 = 00_00000
temp[3][1] = ((16 * w_sum[2])_reduced_3_4 + (16 * w_carry[2])_reduced_3_4 + m[+0]_补码_reduced_3_4)_reduced_3_4 = 
100_1011 + 010_0101 + 000_0110 = 111_0110
temp[3][2] = ((16 * w_sum[2])_reduced_3_4 + (16 * w_carry[2])_reduced_3_4 + m[+1]_补码_reduced_3_4)_reduced_3_4 = 
100_1011 + 010_0101 + 111_1100 = 110_1100
temp[3][3] = ((16 * w_sum[2])_reduced_2_5 + (16 * w_carry[2])_reduced_2_5 + m[+2]_补码_reduced_2_5)_reduced_2_5 = 
00_10110 + 10_01010 + 11_00010 = 10_00010
// reduced_2_4: 使用2-bit整数和4-bit小数表示"temp[x][y] + (-4 * q[x] * D)"的结果, 因此只需要将"(temp[x][y] + (-4 * q[x] * D))_sum_reduced_2_4"和
// "(temp[x][y] + (-4 * q[x] * D))_carry_reduced_2_4"输入到"SD"中即可
// reduced_3_3: 使用3-bit整数和3-bit小数表示"temp[x][y] + (-4 * q[x] * D)"的结果, 因此只需要将"(temp[x][y] + (-4 * q[x] * D))_sum_reduced_3_3"和
// "(temp[x][y] + (-4 * q[x] * D))_carry_reduced_3_3"输入到"SD"中即可
(temp[3][0] + (-4 * q[3] * D)_reduced_2_5)_reduced_2_4 = (00_00000 + 00_00000)_reduced_2_4 = 
(00_00000)_reduced_2_4 = 00_0000 >= 0
(temp[3][1] + (-4 * q[3] * D)_reduced_3_4)_reduced_3_3 = (111_0110 + 000_0000)_reduced_3_3 = 
(111_0110)_reduced_3_3 = 111_011 < 0
(temp[3][2] + (-4 * q[3] * D)_reduced_3_4)_reduced_3_3 = (110_1100 + 000_0000)_reduced_3_3 = 
(110_1100)_reduced_3_3 = 110_110 < 0
(temp[3][3] + (-4 * q[3] * D)_reduced_2_5)_reduced_2_4 = (10_00010 + 00_00000)_reduced_2_4 = 
(10_00010)_reduced_2_4 = 10_0001 < 0, don't care.
根据3较结果(Sign Detection, SD)可得, "belongs to [m[-1], m[0])" -> q[4] = -1
q_pos = 1000_0000
q_neg = 0010_0001

ITER[3]:
// Standard Method
// carry-save:
w_sum[4] = csa_sum(4 * w_sum[3], 4 * w_carry[3], -q[4] * D)_post_process = 
0_010011100100110111010100100
w_carry[4] = csa_carry(4 * w_sum[3], 4 * w_carry[3], -q[4] * D)_post_process = 
1_011000110110000001000000000
(4 * w_sum[4])_trunc_3_4 + (4 * w_carry[4])_trunc_3_4 = 
001_0011 + 101_1000 = 110_1011, "belongs to [-Inf, m[-1])" -> q[5] = -2
// non-redundant:
4 * w[3] + (-q[4] * D) = 
111_000001111101110101110000000 + 
000_101010011101000010100100100 = 
111_101100011010111000010100100 -> 
w[4] = 1_101100011010111000010100100
4 * w[4] = 110_110001101011100001010010000
(4 * w[4])_trunc_3_4 = 110_1100, "belongs to [-Inf, m[-1])" -> q[5] = -2
// New Method
// Retimng + carry-save, full-width:
temp[4][0] = ((16 * w_sum[3])_trunc_5_5 + (16 * w_carry[3])_trunc_5_5 + m[-1]_补码_trunc_5_5)_trunc_5_5 = 
10010_11011 + 01001_01000 + 00001_00000 = 11101_00011
temp[4][1] = ((16 * w_sum[3])_trunc_5_5 + (16 * w_carry[3])_trunc_5_5 + m[+0]_补码_trunc_5_5)_trunc_5_5 = 
10010_11011 + 01001_01000 + 00000_01100 = 11100_01111
temp[4][2] = ((16 * w_sum[3])_trunc_5_5 + (16 * w_carry[3])_trunc_5_5 + m[+1]_补码_trunc_5_5)_trunc_5_5 = 
10010_11011 + 01001_01000 + 11111_11000 = 11011_11011
temp[4][3] = ((16 * w_sum[3])_trunc_5_5 + (16 * w_carry[3])_trunc_5_5 + m[+2]_补码_trunc_5_5)_trunc_5_5 = 
10010_11011 + 01001_01000 + 11111_00010 = 11011_00101
// 做保留3位整数操作的时候, 丢弃原始的5位整数中符号位右边的2-bit; 保留4位小数的时候，丢弃lsb的小数位.
(temp[4][0] + (-4 * q[4] * D)_trunc_5_5)_post_process_trunc_3_4 = (11101_00011 + 00010_10100)_post_process_trunc_3_4 = 
(11111_10111)_post_process_trunc_3_4 = 111_1011 < 0
(temp[4][1] + (-4 * q[4] * D)_trunc_5_5)_post_process_trunc_3_4 = (11100_01111 + 00010_10100)_post_process_trunc_3_4 = 
(11111_00011)_post_process_trunc_3_4 = 111_0001 < 0
(temp[4][2] + (-4 * q[4] * D)_trunc_5_5)_post_process_trunc_3_4 = (11011_11011 + 00010_10100)_post_process_trunc_3_4 = 
(11110_01111)_post_process_trunc_3_4 = 110_0111 < 0
(temp[4][3] + (-4 * q[4] * D)_trunc_5_5)_post_process_trunc_3_4 = (11011_00101 + 00010_10100)_post_process_trunc_3_4 = 
(11101_11001)_post_process_trunc_3_4 = 101_1100 < 0
根据比较结果(Sign Detection, SD)可得, "belongs to [-Inf, m[-1])" -> q[5] = -2
// Retimng + carry-save, reduced-width, early version:
(temp[4][0] + (-4 * q[4] * D)_trunc_5_5)_reduced_trunc_2_4 = 
11_1011 < 0
(temp[4][1] + (-4 * q[4] * D)_trunc_5_5)_reduced_trunc_3_3 = 
111_000 < 0
(temp[4][2] + (-4 * q[4] * D)_trunc_5_5)_reduced_trunc_3_3 = 
110_011 < 0
(temp[4][3] + (-4 * q[4] * D)_trunc_5_5)_reduced_trunc_2_4 = 
01_1100 >= 0, don't care.
根据比较结果(Sign Detection, SD)可得, "belongs to [-Inf, m[-1])" -> q[5] = -2
// Reduced-width, Method from the paper:
temp[4][0] = ((16 * w_sum[3])_reduced_2_5 + (16 * w_carry[3])_reduced_2_5 + m[-1]_补码_reduced_2_5)_reduced_2_5 = 
10_11011 + 01_01000 + 01_00000 = 01_00011
temp[4][1] = ((16 * w_sum[3])_reduced_3_4 + (16 * w_carry[3])_reduced_3_4 + m[+0]_补码_reduced_3_4)_reduced_3_4 = 
010_1101 + 001_0100 + 000_0110 = 100_0111
temp[4][2] = ((16 * w_sum[3])_reduced_3_4 + (16 * w_carry[3])_reduced_3_4 + m[+1]_补码_reduced_3_4)_reduced_3_4 = 
010_1101 + 001_0100 + 111_1100 = 011_1101
temp[4][3] = ((16 * w_sum[3])_reduced_2_5 + (16 * w_carry[3])_reduced_2_5 + m[+2]_补码_reduced_2_5)_reduced_2_5 = 
10_11011 + 01_01000 + 11_00010 = 11_00101
// reduced_2_4: 使用2-bit整数和4-bit小数表示"temp[x][y] + (-4 * q[x] * D)"的结果, 因此只需要将"(temp[x][y] + (-4 * q[x] * D))_sum_reduced_2_4"和
// "(temp[x][y] + (-4 * q[x] * D))_carry_reduced_2_4"输入到"SD"中即可
// reduced_3_3: 使用3-bit整数和3-bit小数表示"temp[x][y] + (-4 * q[x] * D)"的结果, 因此只需要将"(temp[x][y] + (-4 * q[x] * D))_sum_reduced_3_3"和
// "(temp[x][y] + (-4 * q[x] * D))_carry_reduced_3_3"输入到"SD"中即可
(temp[4][0] + (-4 * q[4] * D)_reduced_2_5)_reduced_2_4 = (01_00011 + 10_10100)_reduced_2_4 = 
(11_10111)_reduced_2_4 = 11_1011 < 0
(temp[4][1] + (-4 * q[4] * D)_reduced_3_4)_reduced_3_3 = (100_0111 + 010_1010)_reduced_3_3 = 
(111_0001)_reduced_3_3 = 111_000 < 0
(temp[4][2] + (-4 * q[4] * D)_reduced_3_4)_reduced_3_3 = (011_1101 + 010_1010)_reduced_3_3 = 
(110_0111)_reduced_3_3 = 110_011 < 0
(temp[4][3] + (-4 * q[4] * D)_reduced_2_5)_reduced_2_4 = (11_00101 + 10_10100)_reduced_2_4 = 
(01_11001)_reduced_2_4 = 01_1100 >= 0, don't care.
根据3较结果(Sign Detection, SD)可得, "belongs to [-Inf, m[-1])" -> q[5] = -2
q_pos = 1000_0000_00
q_neg = 0010_0001_10

ITER[4]:
// Standard Method
// carry-save:
w_sum[5] = csa_sum(4 * w_sum[4], 4 * w_carry[4], -q[5] * D)_post_process = 
1_111001110001011100011011000
w_carry[5] = csa_carry(4 * w_sum[4], 4 * w_carry[4], -q[5] * D)_post_process = 
0_001100110100001010000000000
(4 * w_sum[5])_trunc_3_4 + (4 * w_carry[5])_trunc_3_4 = 
111_1001 + 000_1100 = 000_0101, "belongs to [m[1], m[2])" -> q[6] = +1
// non-redundant:
4 * w[4] + (-q[5] * D) = 
110_110001101011100001010010000 + 
001_010100111010000101001001000 = 
000_000110100101100110011011000 -> 
w[5] = 0_000110100101100110011011000
4 * w[5] = 000_011010010110011001101100000
(4 * w[5])_trunc_3_4 = 000_0110, "belongs to [m[1], m[2])" -> q[6] = +1
// New Method
// Retimng + carry-save, full-width:
temp[5][0] = ((16 * w_sum[4])_trunc_5_5 + (16 * w_carry[4])_trunc_5_5 + m[-1]_补码_trunc_5_5)_trunc_5_5 = 
00100_11100 + 10110_00110 + 00001_00000 = 11100_00010
temp[5][1] = ((16 * w_sum[4])_trunc_5_5 + (16 * w_carry[4])_trunc_5_5 + m[+0]_补码_trunc_5_5)_trunc_5_5 = 
00100_11100 + 10110_00110 + 00000_01100 = 11011_01110
temp[5][2] = ((16 * w_sum[4])_trunc_5_5 + (16 * w_carry[4])_trunc_5_5 + m[+1]_补码_trunc_5_5)_trunc_5_5 = 
00100_11100 + 10110_00110 + 11111_11000 = 11010_11010
temp[5][3] = ((16 * w_sum[4])_trunc_5_5 + (16 * w_carry[4])_trunc_5_5 + m[+2]_补码_trunc_5_5)_trunc_5_5 = 
00100_11100 + 10110_00110 + 11111_00010 = 11010_00100
// 做保留3位整数操作的时候, 丢弃原始的5位整数中符号位右边的2-bit; 保留4位小数的时候，丢弃lsb的小数位.
(temp[5][0] + (-4 * q[5] * D)_trunc_5_5)_post_process_trunc_3_4 = (11100_00010 + 00101_01001)_post_process_trunc_3_4 = 
(00001_01011)_post_process_trunc_3_4 = 001_0101 >= 0
(temp[5][1] + (-4 * q[5] * D)_trunc_5_5)_post_process_trunc_3_4 = (11011_01110 + 00101_01001)_post_process_trunc_3_4 = 
(00000_10111)_post_process_trunc_3_4 = 000_1011 >= 0
(temp[5][2] + (-4 * q[5] * D)_trunc_5_5)_post_process_trunc_3_4 = (11011_11011 + 00101_01001)_post_process_trunc_3_4 = 
(00001_00100)_post_process_trunc_3_4 = 001_0010 >= 0
(temp[5][3] + (-4 * q[5] * D)_trunc_5_5)_post_process_trunc_3_4 = (11010_00100 + 00101_01001)_post_process_trunc_3_4 = 
(11111_01101)_post_process_trunc_3_4 = 111_0110 < 0
根据比较结果(Sign Detection, SD)可得, "belongs to [m[1], m[2])" -> q[6] = +1
// Retimng + carry-save, reduced-width, early version:
(temp[5][0] + (-4 * q[5] * D)_trunc_5_5)_reduced_trunc_2_4 = 
01_0101 >= 0, don't care.
(temp[5][1] + (-4 * q[5] * D)_trunc_5_5)_reduced_trunc_3_3 = 
000_101 >= 0
(temp[5][2] + (-4 * q[5] * D)_trunc_5_5)_reduced_trunc_3_3 = 
001_001 >= 0
(temp[5][3] + (-4 * q[5] * D)_trunc_5_5)_reduced_trunc_2_4 = 
11_0110 < 0
根据比较结果(Sign Detection, SD)可得, "belongs to [m[1], m[2])" -> q[6] = +1
// Reduced-width, Method from the paper:
temp[5][0] = ((16 * w_sum[4])_reduced_2_5 + (16 * w_carry[4])_reduced_2_5 + m[-1]_补码_reduced_2_5)_reduced_2_5 = 
00_11100 + 10_00110 + 01_00000 = 00_00010
temp[5][1] = ((16 * w_sum[4])_reduced_3_4 + (16 * w_carry[4])_reduced_3_4 + m[+0]_补码_reduced_3_4)_reduced_3_4 = 
100_1110 + 110_0011 + 000_0110 = 011_0111
temp[5][2] = ((16 * w_sum[4])_reduced_3_4 + (16 * w_carry[4])_reduced_3_4 + m[+1]_补码_reduced_3_4)_reduced_3_4 = 
100_1110 + 110_0011 + 111_1100 = 010_1101
temp[5][3] = ((16 * w_sum[4])_reduced_2_5 + (16 * w_carry[4])_reduced_2_5 + m[+2]_补码_reduced_2_5)_reduced_2_5 = 
00_11100 + 10_00110 + 11_00010 = 10_00100
// reduced_2_4: 使用2-bit整数和4-bit小数表示"temp[x][y] + (-4 * q[x] * D)"的结果, 因此只需要将"(temp[x][y] + (-4 * q[x] * D))_sum_reduced_2_4"和
// "(temp[x][y] + (-4 * q[x] * D))_carry_reduced_2_4"输入到"SD"中即可
// reduced_3_3: 使用3-bit整数和3-bit小数表示"temp[x][y] + (-4 * q[x] * D)"的结果, 因此只需要将"(temp[x][y] + (-4 * q[x] * D))_sum_reduced_3_3"和
// "(temp[x][y] + (-4 * q[x] * D))_carry_reduced_3_3"输入到"SD"中即可
(temp[5][0] + (-4 * q[5] * D)_reduced_2_5)_reduced_2_4 = (00_00010 + 01_01001)_reduced_2_4 = 
(01_01011)_reduced_2_4 = 01_0101 >= 0, don't care.
(temp[5][1] + (-4 * q[5] * D)_reduced_3_4)_reduced_3_3 = (011_0111 + 101_0100)_reduced_3_3 = 
(000_1011)_reduced_3_3 = 000_101 >= 0
(temp[5][2] + (-4 * q[5] * D)_reduced_3_4)_reduced_3_3 = (010_1101 + 101_0100)_reduced_3_3 = 
(000_0001)_reduced_3_3 = 000_000 >= 0
(temp[5][3] + (-4 * q[5] * D)_reduced_2_5)_reduced_2_4 = (10_00100 + 01_01001)_reduced_2_4 = 
(11_01101)_reduced_2_4 = 11_0110 < 0
根据3较结果(Sign Detection, SD)可得, "belongs to [m[1], m[2])" -> q[6] = +1
q_pos = 1000_0000_0001
q_neg = 0010_0001_1000

ITER[5]:
// Standard Method
// carry-save:
w_sum[6] = csa_sum(4 * w_sum[5], 4 * w_carry[5], -q[6] * D)_post_process = 
0_000001110111100100110111100
w_carry[6] = csa_carry(4 * w_sum[5], 4 * w_carry[5], -q[6] * D)_post_process = 
1_101110000001110010010000000
(4 * w_sum[6])_trunc_3_4 + (4 * w_carry[6])_trunc_3_4 = 
000_0001 + 110_1110 = 110_1111, "belongs to [-Inf, m[-1])" -> q[7] = -2
// non-redundant:
4 * w[5] + (-q[6] * D) = 
000_011010010110011001101100000 + 
111_010101100010111101011011100 = 
111_101111111001010111000111100 -> 
w[6] = 1_101111111001010111000111100
4 * w[6] = 110_111111100101011100011110000
(4 * w[6])_trunc_3_4 = 110_1111, "belongs to [-Inf, m[-1])" -> q[7] = -2
// New Method
// Retimng + carry-save, full-width:
temp[6][0] = ((16 * w_sum[5])_trunc_5_5 + (16 * w_carry[5])_trunc_5_5 + m[-1]_补码_trunc_5_5)_trunc_5_5 = 
11110_01110 + 00011_00110 + 00001_00000 = 00010_10100
temp[6][1] = ((16 * w_sum[5])_trunc_5_5 + (16 * w_carry[5])_trunc_5_5 + m[+0]_补码_trunc_5_5)_trunc_5_5 = 
11110_01110 + 00011_00110 + 00000_01100 = 00010_00000
temp[6][2] = ((16 * w_sum[5])_trunc_5_5 + (16 * w_carry[5])_trunc_5_5 + m[+1]_补码_trunc_5_5)_trunc_5_5 = 
11110_01110 + 00011_00110 + 11111_11000 = 00001_01100
temp[6][3] = ((16 * w_sum[5])_trunc_5_5 + (16 * w_carry[5])_trunc_5_5 + m[+2]_补码_trunc_5_5)_trunc_5_5 = 
11110_01110 + 00011_00110 + 11111_00010 = 00000_10110
// 做保留3位整数操作的时候, 丢弃原始的5位整数中符号位右边的2-bit; 保留4位小数的时候，丢弃lsb的小数位.
(temp[6][0] + (-4 * q[6] * D)_trunc_5_5)_post_process_trunc_3_4 = (00010_10100 + 11101_01011)_post_process_trunc_3_4 = 
(11111_11111)_post_process_trunc_3_4 = 111_1111 < 0
(temp[6][1] + (-4 * q[6] * D)_trunc_5_5)_post_process_trunc_3_4 = (00010_00000 + 11101_01011)_post_process_trunc_3_4 = 
(11111_01011)_post_process_trunc_3_4 = 111_0101 < 0
(temp[6][2] + (-4 * q[6] * D)_trunc_5_5)_post_process_trunc_3_4 = (00001_01100 + 11101_01011)_post_process_trunc_3_4 = 
(11110_10111)_post_process_trunc_3_4 = 110_1011 < 0
(temp[6][3] + (-4 * q[6] * D)_trunc_5_5)_post_process_trunc_3_4 = (00000_10110 + 11101_01011)_post_process_trunc_3_4 = 
(11110_00001)_post_process_trunc_3_4 = 110_0000 < 0
根据比较结果(Sign Detection, SD)可得, "belongs to [-Inf, m[-1])" -> q[7] = -2
// Retimng + carry-save, reduced-width, early version:
(temp[6][0] + (-4 * q[6] * D)_trunc_5_5)_reduced_trunc_2_4 = 
11_1111 < 0
(temp[6][1] + (-4 * q[6] * D)_trunc_5_5)_reduced_trunc_3_3 = 
111_010 < 0
(temp[6][2] + (-4 * q[6] * D)_trunc_5_5)_reduced_trunc_3_3 = 
110_101 < 0
(temp[6][3] + (-4 * q[6] * D)_trunc_5_5)_reduced_trunc_2_4 = 
10_0000 < 0, don't care.
根据比较结果(Sign Detection, SD)可得, "belongs to [-Inf, m[-1])" -> q[7] = -2
// Reduced-width, Method from the paper:
temp[6][0] = ((16 * w_sum[5])_reduced_2_5 + (16 * w_carry[5])_reduced_2_5 + m[-1]_补码_reduced_2_5)_reduced_2_5 = 
10_01110 + 11_00110 + 01_00000 = 10_10100
temp[6][1] = ((16 * w_sum[5])_reduced_3_4 + (16 * w_carry[5])_reduced_3_4 + m[+0]_补码_reduced_3_4)_reduced_3_4 = 
110_0111 + 011_0011 + 000_0110 = 010_0000
temp[6][2] = ((16 * w_sum[5])_reduced_3_4 + (16 * w_carry[5])_reduced_3_4 + m[+1]_补码_reduced_3_4)_reduced_3_4 = 
110_0111 + 011_0011 + 111_1100 = 001_0110
temp[6][3] = ((16 * w_sum[5])_reduced_2_5 + (16 * w_carry[5])_reduced_2_5 + m[+2]_补码_reduced_2_5)_reduced_2_5 = 
10_01110 + 11_00110 + 11_00010 = 00_10110
// reduced_2_4: 使用2-bit整数和4-bit小数表示"temp[x][y] + (-4 * q[x] * D)"的结果, 因此只需要将"(temp[x][y] + (-4 * q[x] * D))_sum_reduced_2_4"和
// "(temp[x][y] + (-4 * q[x] * D))_carry_reduced_2_4"输入到"SD"中即可
// reduced_3_3: 使用3-bit整数和3-bit小数表示"temp[x][y] + (-4 * q[x] * D)"的结果, 因此只需要将"(temp[x][y] + (-4 * q[x] * D))_sum_reduced_3_3"和
// "(temp[x][y] + (-4 * q[x] * D))_carry_reduced_3_3"输入到"SD"中即可
(temp[6][0] + (-4 * q[6] * D)_reduced_2_5)_reduced_2_4 = (10_10100 + 01_01011)_reduced_2_4 = 
(11_11111)_reduced_2_4 = 11_1111 < 0
(temp[6][1] + (-4 * q[6] * D)_reduced_3_4)_reduced_3_3 = (010_0000 + 101_0101)_reduced_3_3 = 
(111_0101)_reduced_3_3 = 111_010 < 0
(temp[6][2] + (-4 * q[6] * D)_reduced_3_4)_reduced_3_3 = (001_0110 + 101_0101)_reduced_3_3 = 
(110_1011)_reduced_3_3 = 110_101 < 0
(temp[6][3] + (-4 * q[6] * D)_reduced_2_5)_reduced_2_4 = (00_10110 + 01_01011)_reduced_2_4 = 
(10_00001)_reduced_2_4 = 10_0000 < 0, don't care.
根据3较结果(Sign Detection, SD)可得, "belongs to [-Inf, m[-1])" -> q[7] = -2
q_pos = 1000_0000_0001_00
q_neg = 0010_0001_1000_10

ITER[6]:
// Standard Method
// carry-save:
w_sum[7] = csa_sum(4 * w_sum[6], 4 * w_carry[6], -q[7] * D)_post_process = 
1_101011100011011111010111000
w_carry[7] = csa_carry(4 * w_sum[6], 4 * w_carry[6], -q[7] * D)_post_process = 
0_101000111100000010010000000
(4 * w_sum[7])_trunc_3_4 + (4 * w_carry[7])_trunc_3_4 = 
110_1011 + 010_1000 = 001_0011, "belongs to [m[2], +Inf)" -> q[8] = +2
// non-redundant:
4 * w[6] + (-q[7] * D) = 
110_111111100101011100011110000 + 
001_010100111010000101001001000 = 
000_010100011111100001100111000 -> 
w[7] = 0_010100011111100001100111000
4 * w[7] = 001_010001111110000110011100000
(4 * w[7])_trunc_3_4 = 001_0100, "belongs to [m[2], +Inf)" -> q[8] = +2
// New Method
// Retimng + carry-save, full-width:
temp[7][0] = ((16 * w_sum[6])_trunc_5_5 + (16 * w_carry[6])_trunc_5_5 + m[-1]_补码_trunc_5_5)_trunc_5_5 = 
00000_01110 + 11011_10000 + 00001_00000 = 11100_11110
temp[7][1] = ((16 * w_sum[6])_trunc_5_5 + (16 * w_carry[6])_trunc_5_5 + m[+0]_补码_trunc_5_5)_trunc_5_5 = 
00000_01110 + 11011_10000 + 00000_01100 = 11100_01010
temp[7][2] = ((16 * w_sum[6])_trunc_5_5 + (16 * w_carry[6])_trunc_5_5 + m[+1]_补码_trunc_5_5)_trunc_5_5 = 
00000_01110 + 11011_10000 + 11111_11000 = 11011_10110
temp[7][3] = ((16 * w_sum[6])_trunc_5_5 + (16 * w_carry[6])_trunc_5_5 + m[+2]_补码_trunc_5_5)_trunc_5_5 = 
00000_01110 + 11011_10000 + 11111_00010 = 11011_00000
// 做保留3位整数操作的时候, 丢弃原始的5位整数中符号位右边的2-bit; 保留4位小数的时候，丢弃lsb的小数位.
(temp[7][0] + (-4 * q[7] * D)_trunc_5_5)_post_process_trunc_3_4 = (11100_11110 + 00101_01001)_post_process_trunc_3_4 = 
(00010_00111)_post_process_trunc_3_4 = 010_0011 >= 0
(temp[7][1] + (-4 * q[7] * D)_trunc_5_5)_post_process_trunc_3_4 = (11100_01010 + 00101_01001)_post_process_trunc_3_4 = 
(00001_10011)_post_process_trunc_3_4 = 001_1001 >= 0
(temp[7][2] + (-4 * q[7] * D)_trunc_5_5)_post_process_trunc_3_4 = (11011_10110 + 00101_01001)_post_process_trunc_3_4 = 
(00000_11111)_post_process_trunc_3_4 = 000_1111 >= 0
(temp[7][3] + (-4 * q[7] * D)_trunc_5_5)_post_process_trunc_3_4 = (11011_00000 + 00101_01001)_post_process_trunc_3_4 = 
(00000_01001)_post_process_trunc_3_4 = 000_0100 >= 0
根据比较结果(Sign Detection, SD)可得, "belongs to [m[2], +Inf)" -> q[8] = +2
// Retimng + carry-save, reduced-width, early version:
(temp[7][0] + (-4 * q[7] * D)_trunc_5_5)_reduced_trunc_2_4 = 
10_0011 < 0, don't care.
(temp[7][1] + (-4 * q[7] * D)_trunc_5_5)_reduced_trunc_3_3 = 
001_100 >= 0
(temp[7][2] + (-4 * q[7] * D)_trunc_5_5)_reduced_trunc_3_3 = 
000_111 >= 0
(temp[7][3] + (-4 * q[7] * D)_trunc_5_5)_reduced_trunc_2_4 = 
00_0100 >= 0
根据比较结果(Sign Detection, SD)可得, "belongs to [m[2], +Inf)" -> q[8] = +2
// Reduced-width, Method from the paper:
temp[7][0] = ((16 * w_sum[6])_reduced_2_5 + (16 * w_carry[6])_reduced_2_5 + m[-1]_补码_reduced_2_5)_reduced_2_5 = 
00_01110 + 11_10000 + 01_00000 = 00_11110
temp[7][1] = ((16 * w_sum[6])_reduced_3_4 + (16 * w_carry[6])_reduced_3_4 + m[+0]_补码_reduced_3_4)_reduced_3_4 = 
000_0111 + 011_1000 + 000_0110 = 100_0101
temp[7][2] = ((16 * w_sum[6])_reduced_3_4 + (16 * w_carry[6])_reduced_3_4 + m[+1]_补码_reduced_3_4)_reduced_3_4 = 
000_0111 + 011_1000 + 111_1100 = 011_1011
temp[7][3] = ((16 * w_sum[6])_reduced_2_5 + (16 * w_carry[6])_reduced_2_5 + m[+2]_补码_reduced_2_5)_reduced_2_5 = 
00_01110 + 11_10000 + 11_00010 = 11_00000
// reduced_2_4: 使用2-bit整数和4-bit小数表示"temp[x][y] + (-4 * q[x] * D)"的结果, 因此只需要将"(temp[x][y] + (-4 * q[x] * D))_sum_reduced_2_4"和
// "(temp[x][y] + (-4 * q[x] * D))_carry_reduced_2_4"输入到"SD"中即可
// reduced_3_3: 使用3-bit整数和3-bit小数表示"temp[x][y] + (-4 * q[x] * D)"的结果, 因此只需要将"(temp[x][y] + (-4 * q[x] * D))_sum_reduced_3_3"和
// "(temp[x][y] + (-4 * q[x] * D))_carry_reduced_3_3"输入到"SD"中即可
(temp[7][0] + (-4 * q[7] * D)_reduced_2_5)_reduced_2_4 = (00_11110 + 01_01001)_reduced_2_4 = 
(10_00111)_reduced_2_4 = 10_00111 < 0, don't care.
(temp[7][1] + (-4 * q[7] * D)_reduced_3_4)_reduced_3_3 = (100_0101 + 101_0100)_reduced_3_3 = 
(001_1001)_reduced_3_3 = 001_100 >= 0
(temp[7][2] + (-4 * q[7] * D)_reduced_3_4)_reduced_3_3 = (011_1011 + 101_0100)_reduced_3_3 = 
(000_1111)_reduced_3_3 = 000_111 >= 0
(temp[7][3] + (-4 * q[7] * D)_reduced_2_5)_reduced_2_4 = (11_00000 + 01_01001)_reduced_2_4 = 
(00_01001)_reduced_2_4 = 00_0100 >= 0
根据3较结果(Sign Detection, SD)可得, "belongs to [m[2], +Inf)" -> q[8] = +2
q_pos = 1000_0000_0001_0010
q_neg = 0010_0001_1000_1000

ITER[7]:
// Standard Method
// carry-save:
w_sum[8] = csa_sum(4 * w_sum[7], 4 * w_carry[7], -q[8] * D)_post_process = 
0_100110111000001110101011000
w_carry[8] = csa_carry(4 * w_sum[7], 4 * w_carry[7], -q[8] * D)_post_process = 
1_010110001011110010101000000
(4 * w_sum[8])_trunc_3_4 + (4 * w_carry[8])_trunc_3_4 = 
010_0110 + 101_0110 = 111_1100, "belongs to [m[0], m[1])" -> q[9] = 0
// non-redundant:
4 * w[7] + (-q[8] * D) = 
001_010001111110000110011100000 + 
110_101011000101111010110111000 = 
111_111101000100000001010011000 -> 
w[8] = 1_111101000100000001010011000
4 * w[8] = 111_110100010000000101001100000
(4 * w[8])_trunc_3_4 = 111_1101, "belongs to [m[0], m[1])" -> q[9] = 0
// New Method
// Retimng + carry-save, full-width:
temp[8][0] = ((16 * w_sum[7])_trunc_5_5 + (16 * w_carry[7])_trunc_5_5 + m[-1]_补码_trunc_5_5)_trunc_5_5 = 
11010_11100 + 01010_00111 + 00001_00000 = 00110_00011
temp[8][1] = ((16 * w_sum[7])_trunc_5_5 + (16 * w_carry[7])_trunc_5_5 + m[+0]_补码_trunc_5_5)_trunc_5_5 = 
11010_11100 + 01010_00111 + 00000_01100 = 00101_01111
temp[8][2] = ((16 * w_sum[7])_trunc_5_5 + (16 * w_carry[7])_trunc_5_5 + m[+1]_补码_trunc_5_5)_trunc_5_5 = 
11010_11100 + 01010_00111 + 11111_11000 = 00100_11011
temp[8][3] = ((16 * w_sum[7])_trunc_5_5 + (16 * w_carry[7])_trunc_5_5 + m[+2]_补码_trunc_5_5)_trunc_5_5 = 
11010_11100 + 01010_00111 + 11111_00010 = 00100_00101
// 做保留3位整数操作的时候, 丢弃原始的5位整数中符号位右边的2-bit; 保留4位小数的时候，丢弃lsb的小数位.
(temp[8][0] + (-4 * q[8] * D)_trunc_5_5)_post_process_trunc_3_4 = (00110_00011 + 11010_10110)_post_process_trunc_3_4 = 
(00000_11001)_post_process_trunc_3_4 = 000_1100 >= 0
(temp[8][1] + (-4 * q[8] * D)_trunc_5_5)_post_process_trunc_3_4 = (00101_01111 + 11010_10110)_post_process_trunc_3_4 = 
(00000_00101)_post_process_trunc_3_4 = 000_0010 >= 0
(temp[8][2] + (-4 * q[8] * D)_trunc_5_5)_post_process_trunc_3_4 = (00100_11011 + 11010_10110)_post_process_trunc_3_4 = 
(11111_10001)_post_process_trunc_3_4 = 111_1000 < 0
(temp[8][3] + (-4 * q[8] * D)_trunc_5_5)_post_process_trunc_3_4 = (00100_00101 + 11010_10110)_post_process_trunc_3_4 = 
(11110_11011)_post_process_trunc_3_4 = 110_1101 < 0
根据比较结果(Sign Detection, SD)可得, "belongs to [m[0], m[1])" -> q[9] = 0
// Retimng + carry-save, reduced-width, early version:
(temp[8][0] + (-4 * q[8] * D)_trunc_5_5)_reduced_trunc_2_4 = 
00_1100 >= 0
(temp[8][1] + (-4 * q[8] * D)_trunc_5_5)_reduced_trunc_3_3 = 
000_001 >= 0
(temp[8][2] + (-4 * q[8] * D)_trunc_5_5)_reduced_trunc_3_3 = 
111_100 < 0
(temp[8][3] + (-4 * q[8] * D)_trunc_5_5)_reduced_trunc_2_4 = 
10_1101 < 0, don't care.
根据比较结果(Sign Detection, SD)可得, "belongs to [m[0], m[1])" -> q[9] = 0
// Reduced-width, Method from the paper:
temp[8][0] = ((16 * w_sum[7])_reduced_2_5 + (16 * w_carry[7])_reduced_2_5 + m[-1]_补码_reduced_2_5)_reduced_2_5 = 
10_11100 + 10_00111 + 01_00000 = 10_00011
temp[8][1] = ((16 * w_sum[7])_reduced_3_4 + (16 * w_carry[7])_reduced_3_4 + m[+0]_补码_reduced_3_4)_reduced_3_4 = 
010_1110 + 010_0011 + 000_0110 = 101_0111
temp[8][2] = ((16 * w_sum[7])_reduced_3_4 + (16 * w_carry[7])_reduced_3_4 + m[+1]_补码_reduced_3_4)_reduced_3_4 = 
010_1110 + 010_0011 + 111_1100 = 100_1101
temp[8][3] = ((16 * w_sum[7])_reduced_2_5 + (16 * w_carry[7])_reduced_2_5 + m[+2]_补码_reduced_2_5)_reduced_2_5 = 
10_11100 + 10_00111 + 11_00010 = 00_00101
// reduced_2_4: 使用2-bit整数和4-bit小数表示"temp[x][y] + (-4 * q[x] * D)"的结果, 因此只需要将"(temp[x][y] + (-4 * q[x] * D))_sum_reduced_2_4"和
// "(temp[x][y] + (-4 * q[x] * D))_carry_reduced_2_4"输入到"SD"中即可
// reduced_3_3: 使用3-bit整数和3-bit小数表示"temp[x][y] + (-4 * q[x] * D)"的结果, 因此只需要将"(temp[x][y] + (-4 * q[x] * D))_sum_reduced_3_3"和
// "(temp[x][y] + (-4 * q[x] * D))_carry_reduced_3_3"输入到"SD"中即可
(temp[8][0] + (-4 * q[8] * D)_reduced_2_5)_reduced_2_4 = (10_00011 + 10_10110)_reduced_2_4 = 
(00_11001)_reduced_2_4 = 00_1100 >= 0, don't care.
(temp[8][1] + (-4 * q[8] * D)_reduced_3_4)_reduced_3_3 = (101_0111 + 010_1011)_reduced_3_3 = 
(000_0010)_reduced_3_3 = 000_001 >= 0
(temp[8][2] + (-4 * q[8] * D)_reduced_3_4)_reduced_3_3 = (100_1101 + 010_1011)_reduced_3_3 = 
(111_1000)_reduced_3_3 = 111_100 < 0
(temp[8][3] + (-4 * q[8] * D)_reduced_2_5)_reduced_2_4 = (00_00101 + 10_10110)_reduced_2_4 = 
(10_11011)_reduced_2_4 = 10_1101 <= 0, don't care.
根据3较结果(Sign Detection, SD)可得, "belongs to [m[0], m[1])" -> q[9] = 0
q_pos = 1000_0000_0001_0010_00
q_neg = 0010_0001_1000_1000_00

ITER[8]:
// Standard Method
// carry-save:
w_sum[9] = csa_sum(4 * w_sum[8], 4 * w_carry[8], -q[9] * D)_post_process = 
0_011011100000111010101100000
w_carry[9] = csa_carry(4 * w_sum[8], 4 * w_carry[8], -q[9] * D)_post_process = 
1_011000101111001010100000000
(4 * w_sum[9])_trunc_3_4 + (4 * w_carry[9])_trunc_3_4 = 
001_1011 + 101_1000 = 111_0011, "belongs to [m[-1], m[0])" -> q[10] = -1
// non-redundant:
4 * w[8] + (-q[9] * D) = 
111_110100010000000101001100000 + 
000_000000000000000000000000000 = 
111_110100010000000101001100000 -> 
w[9] = 1_110100010000000101001100000
4 * w[9] = 111_010001000000010100110000000
(4 * w[9])_trunc_3_4 = 111_0100, "belongs to [m[-1], m[0])" -> q[10] = -1
// New Method
// Retimng + carry-save, full-width:
temp[9][0] = ((16 * w_sum[8])_trunc_5_5 + (16 * w_carry[8])_trunc_5_5 + m[-1]_补码_trunc_5_5)_trunc_5_5 = 
01001_10111 + 10101_10001 + 00001_00000 = 00000_01000
temp[9][1] = ((16 * w_sum[8])_trunc_5_5 + (16 * w_carry[8])_trunc_5_5 + m[+0]_补码_trunc_5_5)_trunc_5_5 = 
01001_10111 + 10101_10001 + 00000_01100 = 11111_10100
temp[9][2] = ((16 * w_sum[8])_trunc_5_5 + (16 * w_carry[8])_trunc_5_5 + m[+1]_补码_trunc_5_5)_trunc_5_5 = 
01001_10111 + 10101_10001 + 11111_11000 = 11111_00000
temp[9][3] = ((16 * w_sum[8])_trunc_5_5 + (16 * w_carry[8])_trunc_5_5 + m[+2]_补码_trunc_5_5)_trunc_5_5 = 
01001_10111 + 10101_10001 + 11111_00010 = 11110_01010
// 做保留3位整数操作的时候, 丢弃原始的5位整数中符号位右边的2-bit; 保留4位小数的时候，丢弃lsb的小数位.
(temp[9][0] + (-4 * q[9] * D)_trunc_5_5)_post_process_trunc_3_4 = (00000_01000 + 00000_00000)_post_process_trunc_3_4 = 
(00000_01000)_post_process_trunc_3_4 = 000_0100 >= 0
(temp[9][1] + (-4 * q[9] * D)_trunc_5_5)_post_process_trunc_3_4 = (11111_10100 + 00000_00000)_post_process_trunc_3_4 = 
(11111_10100)_post_process_trunc_3_4 = 111_1010 < 0
(temp[9][2] + (-4 * q[9] * D)_trunc_5_5)_post_process_trunc_3_4 = (11111_00000 + 00000_00000)_post_process_trunc_3_4 = 
(11111_00000)_post_process_trunc_3_4 = 111_0000 < 0
(temp[9][3] + (-4 * q[9] * D)_trunc_5_5)_post_process_trunc_3_4 = (11110_01010 + 00000_00000)_post_process_trunc_3_4 = 
(11110_01010)_post_process_trunc_3_4 = 110_0101 < 0
根据比较结果(Sign Detection, SD)可得, "belongs to [m[-1], m[0])" -> q[10] = -1
// Retimng + carry-save, reduced-width, early version:
(temp[9][0] + (-4 * q[9] * D)_trunc_5_5)_reduced_trunc_2_4 = 
00_0100 >= 0
(temp[9][1] + (-4 * q[9] * D)_trunc_5_5)_reduced_trunc_3_3 = 
111_101 < 0
(temp[9][2] + (-4 * q[9] * D)_trunc_5_5)_reduced_trunc_3_3 = 
111_000 < 0
(temp[9][3] + (-4 * q[9] * D)_trunc_5_5)_reduced_trunc_2_4 = 
10_0101 < 0, don't care.
根据比较结果(Sign Detection, SD)可得, "belongs to [m[-1], m[0])" -> q[10] = -1
// Reduced-width, Method from the paper:
temp[9][0] = ((16 * w_sum[8])_reduced_2_5 + (16 * w_carry[8])_reduced_2_5 + m[-1]_补码_reduced_2_5)_reduced_2_5 = 
01_10111 + 01_10001 + 01_00000 = 00_01000
temp[9][1] = ((16 * w_sum[8])_reduced_3_4 + (16 * w_carry[8])_reduced_3_4 + m[+0]_补码_reduced_3_4)_reduced_3_4 = 
001_1011 + 101_1000 + 000_0110 = 111_1001
temp[9][2] = ((16 * w_sum[8])_reduced_3_4 + (16 * w_carry[8])_reduced_3_4 + m[+1]_补码_reduced_3_4)_reduced_3_4 = 
001_1011 + 101_1000 + 111_1100 = 110_1111
temp[9][3] = ((16 * w_sum[8])_reduced_2_5 + (16 * w_carry[8])_reduced_2_5 + m[+2]_补码_reduced_2_5)_reduced_2_5 = 
01_10111 + 01_10001 + 11_00010 = 10_01010
// reduced_2_4: 使用2-bit整数和4-bit小数表示"temp[x][y] + (-4 * q[x] * D)"的结果, 因此只需要将"(temp[x][y] + (-4 * q[x] * D))_sum_reduced_2_4"和
// "(temp[x][y] + (-4 * q[x] * D))_carry_reduced_2_4"输入到"SD"中即可
// reduced_3_3: 使用3-bit整数和3-bit小数表示"temp[x][y] + (-4 * q[x] * D)"的结果, 因此只需要将"(temp[x][y] + (-4 * q[x] * D))_sum_reduced_3_3"和
// "(temp[x][y] + (-4 * q[x] * D))_carry_reduced_3_3"输入到"SD"中即可
(temp[9][0] + (-4 * q[9] * D)_reduced_2_5)_reduced_2_4 = (00_01000 + 00_00000)_reduced_2_4 = 
(00_01000)_reduced_2_4 = 00_0100 >= 0
(temp[9][1] + (-4 * q[9] * D)_reduced_3_4)_reduced_3_3 = (111_1001 + 000_0000)_reduced_3_3 = 
(111_1001)_reduced_3_3 = 111_100 < 0
(temp[9][2] + (-4 * q[9] * D)_reduced_3_4)_reduced_3_3 = (110_1111 + 000_0000)_reduced_3_3 = 
(110_1111)_reduced_3_3 = 110_111 < 0
(temp[9][3] + (-4 * q[9] * D)_reduced_2_5)_reduced_2_4 = (10_01010 + 00_00000)_reduced_2_4 = 
(10_01010)_reduced_2_4 = 10_0101 < 0, don't care.
根据3较结果(Sign Detection, SD)可得, "belongs to [m[-1], m[0])" -> q[10] = -1
q_pos = 1000_0000_0001_0010_0000
q_neg = 0010_0001_1000_1000_0001

ITER[9]:
// Standard Method
// carry-save:
w_sum[10] = csa_sum(4 * w_sum[9], 4 * w_carry[9], -q[10] * D)_post_process = 
1_100110100010000010010100100
w_carry[10] = csa_carry(4 * w_sum[9], 4 * w_carry[9], -q[10] * D)_post_process = 
0_010100111011010101000000000
(4 * w_sum[10])_trunc_3_4 + (4 * w_carry[10])_trunc_3_4 = 
110_0110 + 001_0100 = 111_1010, "belongs to [m[0], m[1])" -> q[11] = 0
// non-redundant:
4 * w[9] + (-q[10] * D) = 
111_010001000000010100110000000 + 
000_101010011101000010100100100 = 
111_111011011101010111010100100 -> 
w[10] = 1_111011011101010111010100100
4 * w[10] = 111_101101110101011101010010000
(4 * w[10])_trunc_3_4 = 111_1011, "belongs to [m[0], m[1])" -> q[11] = 0
// New Method
// Retimng + carry-save, full-width:
temp[10][0] = ((16 * w_sum[9])_trunc_5_5 + (16 * w_carry[9])_trunc_5_5 + m[-1]_补码_trunc_5_5)_trunc_5_5 = 
00110_11100 + 10110_00101 + 00001_00000 = 11110_00001
temp[10][1] = ((16 * w_sum[9])_trunc_5_5 + (16 * w_carry[9])_trunc_5_5 + m[+0]_补码_trunc_5_5)_trunc_5_5 = 
00110_11100 + 10110_00101 + 00000_01100 = 11101_01101
temp[10][2] = ((16 * w_sum[9])_trunc_5_5 + (16 * w_carry[9])_trunc_5_5 + m[+1]_补码_trunc_5_5)_trunc_5_5 = 
00110_11100 + 10110_00101 + 11111_11000 = 11100_11001
temp[10][3] = ((16 * w_sum[9])_trunc_5_5 + (16 * w_carry[9])_trunc_5_5 + m[+2]_补码_trunc_5_5)_trunc_5_5 = 
00110_11100 + 10110_00101 + 11111_00010 = 11100_00011
// 做保留3位整数操作的时候, 丢弃原始的5位整数中符号位右边的2-bit; 保留4位小数的时候，丢弃lsb的小数位.
(temp[10][0] + (-4 * q[9] * D)_trunc_5_5)_post_process_trunc_3_4 = (11110_00001 + 00010_10100)_post_process_trunc_3_4 = 
(00000_10101)_post_process_trunc_3_4 = 000_1010 >= 0
(temp[10][1] + (-4 * q[9] * D)_trunc_5_5)_post_process_trunc_3_4 = (11101_01101 + 00010_10100)_post_process_trunc_3_4 = 
(00000_00001)_post_process_trunc_3_4 = 000_0000 >= 0
(temp[10][2] + (-4 * q[9] * D)_trunc_5_5)_post_process_trunc_3_4 = (11100_11001 + 00010_10100)_post_process_trunc_3_4 = 
(11111_01101)_post_process_trunc_3_4 = 111_0110 < 0
(temp[10][3] + (-4 * q[9] * D)_trunc_5_5)_post_process_trunc_3_4 = (11100_00011 + 00010_10100)_post_process_trunc_3_4 = 
(11110_10111)_post_process_trunc_3_4 = 110_1011 < 0
根据比较结果(Sign Detection, SD)可得, "belongs to [m[0], m[1])" -> q[11] = 0
// Retimng + carry-save, reduced-width, early version:
(temp[10][0] + (-4 * q[10] * D)_trunc_5_5)_reduced_trunc_2_4 = 
00_1010 >= 0, don't care.
(temp[10][1] + (-4 * q[10] * D)_trunc_5_5)_reduced_trunc_3_3 = 
000_000 >= 0
(temp[10][2] + (-4 * q[10] * D)_trunc_5_5)_reduced_trunc_3_3 = 
111_011 < 0
(temp[10][3] + (-4 * q[10] * D)_trunc_5_5)_reduced_trunc_2_4 = 
10_1011 < 0, don't care.
根据比较结果(Sign Detection, SD)可得, "belongs to [m[0], m[1])" -> q[11] = 0
// Reduced-width, Method from the paper:
temp[10][0] = ((16 * w_sum[9])_reduced_2_5 + (16 * w_carry[9])_reduced_2_5 + m[-1]_补码_reduced_2_5)_reduced_2_5 = 
10_11100 + 10_00101 + 01_00000 = 10_00001
temp[10][1] = ((16 * w_sum[9])_reduced_3_4 + (16 * w_carry[9])_reduced_3_4 + m[+0]_补码_reduced_3_4)_reduced_3_4 = 
110_1110 + 110_0010 + 000_0110 = 101_0110
temp[10][2] = ((16 * w_sum[9])_reduced_3_4 + (16 * w_carry[9])_reduced_3_4 + m[+1]_补码_reduced_3_4)_reduced_3_4 = 
110_1110 + 110_0010 + 111_1100 = 100_1100
temp[10][3] = ((16 * w_sum[9])_reduced_2_5 + (16 * w_carry[9])_reduced_2_5 + m[+2]_补码_reduced_2_5)_reduced_2_5 = 
10_11100 + 10_00101 + 11_00010 = 00_00011
// reduced_2_4: 使用2-bit整数和4-bit小数表示"temp[x][y] + (-4 * q[x] * D)"的结果, 因此只需要将"(temp[x][y] + (-4 * q[x] * D))_sum_reduced_2_4"和
// "(temp[x][y] + (-4 * q[x] * D))_carry_reduced_2_4"输入到"SD"中即可
// reduced_3_3: 使用3-bit整数和3-bit小数表示"temp[x][y] + (-4 * q[x] * D)"的结果, 因此只需要将"(temp[x][y] + (-4 * q[x] * D))_sum_reduced_3_3"和
// "(temp[x][y] + (-4 * q[x] * D))_carry_reduced_3_3"输入到"SD"中即可
(temp[10][0] + (-4 * q[10] * D)_reduced_2_5)_reduced_2_4 = (10_00001 + 10_10100)_reduced_2_4 = 
(00_10101)_reduced_2_4 = 00_1010 >= 0, don't care.
(temp[10][1] + (-4 * q[10] * D)_reduced_3_4)_reduced_3_3 = (101_0110 + 010_1010)_reduced_3_3 = 
(000_0000)_reduced_3_3 = 000_000 >= 0
(temp[10][2] + (-4 * q[10] * D)_reduced_3_4)_reduced_3_3 = (100_1100 + 010_1010)_reduced_3_3 = 
(111_0110)_reduced_3_3 = 111_011 < 0
(temp[10][3] + (-4 * q[10] * D)_reduced_2_5)_reduced_2_4 = (00_00011 + 10_10100)_reduced_2_4 = 
(10_10111)_reduced_2_4 = 10_1011 < 0, don't care.
根据3较结果(Sign Detection, SD)可得, "belongs to [m[0], m[1])" -> q[11] = 0
q_pos = 1000_0000_0001_0010_0000_00
q_neg = 0010_0001_1000_1000_0001_00

ITER[10]:
// Standard Method
// carry-save:
w_sum[11] = csa_sum(4 * w_sum[10], 4 * w_carry[10], -q[11] * D)_post_process = 
0_011010001000001001010010000
w_carry[11] = csa_carry(4 * w_sum[10], 4 * w_carry[10], -q[11] * D)_post_process = 
1_010011101101010100000000000
(4 * w_sum[11])_trunc_3_4 + (4 * w_carry[11])_trunc_3_4 = 
001_1010 + 101_0011 = 110_1101, "belongs to [-Inf, m[-1])" -> q[12] = -2
// non-redundant:
4 * w[10] + (-q[11] * D) = 
111_101101110101011101010010000 + 
000_101010011101000010100100100 = 
111_101101110101011101010010000 -> 
w[11] = 1_101101110101011101010010000
4 * w[11] = 110_110111010101110101001000000
(4 * w[11])_trunc_3_4 = 110_1101, "belongs to [-Inf, m[-1])" -> q[12] = -2
// New Method
// Retimng + carry-save, full-width:
temp[11][0] = ((16 * w_sum[10])_trunc_5_5 + (16 * w_carry[10])_trunc_5_5 + m[-1]_补码_trunc_5_5)_trunc_5_5 = 
11001_10100 + 00101_00111 + 00001_00000 = 11111_11011
temp[11][1] = ((16 * w_sum[10])_trunc_5_5 + (16 * w_carry[10])_trunc_5_5 + m[+0]_补码_trunc_5_5)_trunc_5_5 = 
11001_10100 + 00101_00111 + 00000_01100 = 11111_00111
temp[11][2] = ((16 * w_sum[10])_trunc_5_5 + (16 * w_carry[10])_trunc_5_5 + m[+1]_补码_trunc_5_5)_trunc_5_5 = 
11001_10100 + 00101_00111 + 11111_11000 = 11110_10011
temp[11][3] = ((16 * w_sum[10])_trunc_5_5 + (16 * w_carry[10])_trunc_5_5 + m[+2]_补码_trunc_5_5)_trunc_5_5 = 
11001_10100 + 00101_00111 + 11111_00010 = 11101_11101
// 做保留3位整数操作的时候, 丢弃原始的5位整数中符号位右边的2-bit; 保留4位小数的时候，丢弃lsb的小数位.
(temp[11][0] + (-4 * q[9] * D)_trunc_5_5)_post_process_trunc_3_4 = (11111_11011 + 00000_00000)_post_process_trunc_3_4 = 
(11111_11011)_post_process_trunc_3_4 = 111_1101 < 0
(temp[11][1] + (-4 * q[9] * D)_trunc_5_5)_post_process_trunc_3_4 = (11111_00111 + 00000_00000)_post_process_trunc_3_4 = 
(11111_00111)_post_process_trunc_3_4 = 111_0011 < 0
(temp[11][2] + (-4 * q[9] * D)_trunc_5_5)_post_process_trunc_3_4 = (11110_10011 + 00000_00000)_post_process_trunc_3_4 = 
(11110_10011)_post_process_trunc_3_4 = 110_1001 < 0
(temp[11][3] + (-4 * q[9] * D)_trunc_5_5)_post_process_trunc_3_4 = (11101_11101 + 00000_00000)_post_process_trunc_3_4 = 
(11101_11101)_post_process_trunc_3_4 = 101_1110 < 0
根据比较结果(Sign Detection, SD)可得, "belongs to [-Inf, m[-1])" -> q[12] = -2
// Retimng + carry-save, reduced-width, early version:
(temp[11][0] + (-4 * q[11] * D)_trunc_5_5)_reduced_trunc_2_4 = 
11_1101 < 0
(temp[11][1] + (-4 * q[11] * D)_trunc_5_5)_reduced_trunc_3_3 = 
111_001 < 0
(temp[11][2] + (-4 * q[11] * D)_trunc_5_5)_reduced_trunc_3_3 = 
110_100 < 0
(temp[11][3] + (-4 * q[11] * D)_trunc_5_5)_reduced_trunc_2_4 = 
01_1110 >= 0, don't care.
根据比较结果(Sign Detection, SD)可得, "belongs to [-Inf, m[-1])" -> q[12] = -2
// Reduced-width, Method from the paper:
temp[11][0] = ((16 * w_sum[10])_reduced_2_5 + (16 * w_carry[10])_reduced_2_5 + m[-1]_补码_reduced_2_5)_reduced_2_5 = 
01_10100 + 01_00111 + 01_00000 = 11_11011
temp[11][1] = ((16 * w_sum[10])_reduced_3_4 + (16 * w_carry[10])_reduced_3_4 + m[+0]_补码_reduced_3_4)_reduced_3_4 = 
001_1010 + 101_0011 + 000_0110 = 111_0011
temp[11][2] = ((16 * w_sum[10])_reduced_3_4 + (16 * w_carry[10])_reduced_3_4 + m[+1]_补码_reduced_3_4)_reduced_3_4 = 
001_1010 + 101_0011 + 111_1100 = 110_1001
temp[11][3] = ((16 * w_sum[10])_reduced_2_5 + (16 * w_carry[10])_reduced_2_5 + m[+2]_补码_reduced_2_5)_reduced_2_5 = 
01_10100 + 01_00111 + 11_00010 = 01_11101
// reduced_2_4: 使用2-bit整数和4-bit小数表示"temp[x][y] + (-4 * q[x] * D)"的结果, 因此只需要将"(temp[x][y] + (-4 * q[x] * D))_sum_reduced_2_4"和
// "(temp[x][y] + (-4 * q[x] * D))_carry_reduced_2_4"输入到"SD"中即可
// reduced_3_3: 使用3-bit整数和3-bit小数表示"temp[x][y] + (-4 * q[x] * D)"的结果, 因此只需要将"(temp[x][y] + (-4 * q[x] * D))_sum_reduced_3_3"和
// "(temp[x][y] + (-4 * q[x] * D))_carry_reduced_3_3"输入到"SD"中即可
(temp[11][0] + (-4 * q[11] * D)_reduced_2_5)_reduced_2_4 = (11_11011 + 00_00000)_reduced_2_4 = 
(11_11011)_reduced_2_4 = 11_1101 < 0
(temp[11][1] + (-4 * q[11] * D)_reduced_3_4)_reduced_3_3 = (111_0011 + 000_0000)_reduced_3_3 = 
(111_0011)_reduced_3_3 = 111_001 < 0
(temp[11][2] + (-4 * q[11] * D)_reduced_3_4)_reduced_3_3 = (110_1001 + 000_0000)_reduced_3_3 = 
(110_1001)_reduced_3_3 = 110_100 < 0
(temp[11][3] + (-4 * q[11] * D)_reduced_2_5)_reduced_2_4 = (01_11101 + 00_00000)_reduced_2_4 = 
(01_11101)_reduced_2_4 = 01_1110 >= 0, don't care.
根据3较结果(Sign Detection, SD)可得, "belongs to [-Inf, m[-1])" -> q[12] = -2
q_pos = 1000_0000_0001_0010_0000_0000
q_neg = 0010_0001_1000_1000_0001_0010

ITER[11]:
// Standard Method
// carry-save:
w_sum[12] = csa_sum(4 * w_sum[11], 4 * w_carry[11], -q[12] * D)_post_process = 
1_110010101111110000000001000
w_carry[12] = csa_carry(4 * w_sum[11], 4 * w_carry[11], -q[12] * D)_post_process = 
0_011001100000001010010000000
(4 * w_sum[12])_trunc_3_4 + (4 * w_carry[12])_trunc_3_4 = 
111_0010 + 001_1001 = 000_1011, "belongs to [m[1], m[2])" -> q[13] = +1
// non-redundant:
4 * w[11] + (-q[12] * D) = 
110_110111010101110101001000000 + 
001_010100111010000101001001000 = 
000_001100001111111010010001000 -> 
w[12] = 0_001100001111111010010001000
4 * w[12] = 000_110000111111101001000100000
(4 * w[12])_trunc_3_4 = 000_1100, "belongs to [m[1], m[2])" -> q[13] = +1
// New Method
// Retimng + carry-save, full-width:
temp[12][0] = ((16 * w_sum[11])_trunc_5_5 + (16 * w_carry[11])_trunc_5_5 + m[-1]_补码_trunc_5_5)_trunc_5_5 = 
00110_10001 + 10100_11101 + 00001_00000 = 11100_01110
temp[12][1] = ((16 * w_sum[11])_trunc_5_5 + (16 * w_carry[11])_trunc_5_5 + m[+0]_补码_trunc_5_5)_trunc_5_5 = 
00110_10001 + 10100_11101 + 00000_01100 = 11011_11010
temp[12][2] = ((16 * w_sum[11])_trunc_5_5 + (16 * w_carry[11])_trunc_5_5 + m[+1]_补码_trunc_5_5)_trunc_5_5 = 
00110_10001 + 10100_11101 + 11111_11000 = 11011_00110
temp[12][3] = ((16 * w_sum[11])_trunc_5_5 + (16 * w_carry[11])_trunc_5_5 + m[+2]_补码_trunc_5_5)_trunc_5_5 = 
00110_10001 + 10100_11101 + 11111_00010 = 11010_10000
// 做保留3位整数操作的时候, 丢弃原始的5位整数中符号位右边的2-bit; 保留4位小数的时候，丢弃lsb的小数位.
(temp[12][0] + (-4 * q[9] * D)_trunc_5_5)_post_process_trunc_3_4 = (11100_01110 + 00101_01001)_post_process_trunc_3_4 = 
(00001_10111)_post_process_trunc_3_4 = 001_1011 >= 0
(temp[12][1] + (-4 * q[9] * D)_trunc_5_5)_post_process_trunc_3_4 = (11011_11010 + 00101_01001)_post_process_trunc_3_4 = 
(00001_00011)_post_process_trunc_3_4 = 001_0001 >= 0
(temp[12][2] + (-4 * q[9] * D)_trunc_5_5)_post_process_trunc_3_4 = (11011_00110 + 00101_01001)_post_process_trunc_3_4 = 
(00000_01111)_post_process_trunc_3_4 = 000_0111 >= 0
(temp[12][3] + (-4 * q[9] * D)_trunc_5_5)_post_process_trunc_3_4 = (11010_10000 + 00101_01001)_post_process_trunc_3_4 = 
(11111_11001)_post_process_trunc_3_4 = 111_1100 < 0
根据比较结果(Sign Detection, SD)可得, "belongs to [m[1], m[2])" -> q[13] = +1
// Retimng + carry-save, reduced-width, early version:
(temp[12][0] + (-4 * q[12] * D)_trunc_5_5)_reduced_trunc_2_4 = 
01_1011 >= 0, don't care.
(temp[12][1] + (-4 * q[12] * D)_trunc_5_5)_reduced_trunc_3_3 = 
001_000 >= 0
(temp[12][2] + (-4 * q[12] * D)_trunc_5_5)_reduced_trunc_3_3 = 
000_011 >= 0
(temp[12][3] + (-4 * q[12] * D)_trunc_5_5)_reduced_trunc_2_4 = 
11_1100 < 0
根据比较结果(Sign Detection, SD)可得, "belongs to [m[1], m[2])" -> q[13] = +1
// Reduced-width, Method from the paper:
temp[12][0] = ((16 * w_sum[11])_reduced_2_5 + (16 * w_carry[11])_reduced_2_5 + m[-1]_补码_reduced_2_5)_reduced_2_5 = 
10_10001 + 00_11101 + 01_00000 = 00_01110
temp[12][1] = ((16 * w_sum[11])_reduced_3_4 + (16 * w_carry[11])_reduced_3_4 + m[+0]_补码_reduced_3_4)_reduced_3_4 = 
110_1000 + 100_1110 + 000_0110 = 011_1100
temp[12][2] = ((16 * w_sum[11])_reduced_3_4 + (16 * w_carry[11])_reduced_3_4 + m[+1]_补码_reduced_3_4)_reduced_3_4 = 
110_1000 + 100_1110 + 111_1100 = 011_0010
temp[12][3] = ((16 * w_sum[11])_reduced_2_5 + (16 * w_carry[11])_reduced_2_5 + m[+2]_补码_reduced_2_5)_reduced_2_5 = 
10_10001 + 00_11101 + 11_00010 = 10_10000
// reduced_2_4: 使用2-bit整数和4-bit小数表示"temp[x][y] + (-4 * q[x] * D)"的结果, 因此只需要将"(temp[x][y] + (-4 * q[x] * D))_sum_reduced_2_4"和
// "(temp[x][y] + (-4 * q[x] * D))_carry_reduced_2_4"输入到"SD"中即可
// reduced_3_3: 使用3-bit整数和3-bit小数表示"temp[x][y] + (-4 * q[x] * D)"的结果, 因此只需要将"(temp[x][y] + (-4 * q[x] * D))_sum_reduced_3_3"和
// "(temp[x][y] + (-4 * q[x] * D))_carry_reduced_3_3"输入到"SD"中即可
(temp[12][0] + (-4 * q[12] * D)_reduced_2_5)_reduced_2_4 = (00_01110 + 01_01001)_reduced_2_4 = 
(01_10111)_reduced_2_4 = 01_1011 >= 0, don't care.
(temp[12][1] + (-4 * q[12] * D)_reduced_3_4)_reduced_3_3 = (011_1100 + 101_0100)_reduced_3_3 = 
(001_0000)_reduced_3_3 = 001_000 >= 0
(temp[12][2] + (-4 * q[12] * D)_reduced_3_4)_reduced_3_3 = (011_0010 + 101_0100)_reduced_3_3 = 
(000_0110)_reduced_3_3 = 000_011 >= 0
(temp[12][3] + (-4 * q[12] * D)_reduced_2_5)_reduced_2_4 = (10_10000 + 01_01001)_reduced_2_4 = 
(11_11001)_reduced_2_4 = 11_1100 < 0
根据3较结果(Sign Detection, SD)可得, "belongs to [m[1], m[2])" -> q[13] = +1
q_pos = 1000_0000_0001_0010_0000_0000_01
q_neg = 0010_0001_1000_1000_0001_0010_00

ITER[12]:
// Standard Method
// carry-save:
w_sum[13] = csa_sum(4 * w_sum[12], 4 * w_carry[12], -q[13] * D)_post_process = 
1_111001011101010100011111100
w_carry[13] = csa_carry(4 * w_sum[12], 4 * w_carry[12], -q[13] * D)_post_process = 
0_001101000101010010000000000
(4 * w_sum[13])_trunc_3_4 + (4 * w_carry[13])_trunc_3_4 = 
111_1001 + 000_1101 = 000_0110, "belongs to [m[1], m[2])" -> q[14] = +1
// non-redundant:
4 * w[12] + (-q[13] * D) = 
000_110000111111101001000100000 + 
111_010101100010111101011011100 = 
000_000110100010100110011111100 ->
w[13] = 0_000110100010100110011111100
4 * w[13] = 000_011010001010011001111110000
(4 * w[13])_trunc_3_4 = 000_0110, "belongs to [m[1], m[2])" -> q[14] = +1
// New Method
// Retimng + carry-save, full-width:
temp[13][0] = ((16 * w_sum[12])_trunc_5_5 + (16 * w_carry[12])_trunc_5_5 + m[-1]_补码_trunc_5_5)_trunc_5_5 = 
11100_10101 + 00110_01100 + 00001_00000 = 00100_00001
temp[13][1] = ((16 * w_sum[12])_trunc_5_5 + (16 * w_carry[12])_trunc_5_5 + m[+0]_补码_trunc_5_5)_trunc_5_5 = 
11100_10101 + 00110_01100 + 00000_01100 = 00011_01101
temp[13][2] = ((16 * w_sum[12])_trunc_5_5 + (16 * w_carry[12])_trunc_5_5 + m[+1]_补码_trunc_5_5)_trunc_5_5 = 
11100_10101 + 00110_01100 + 11111_11000 = 00010_11001
temp[13][3] = ((16 * w_sum[12])_trunc_5_5 + (16 * w_carry[12])_trunc_5_5 + m[+2]_补码_trunc_5_5)_trunc_5_5 = 
11100_10101 + 00110_01100 + 11111_00010 = 00010_00011
// 做保留3位整数操作的时候, 丢弃原始的5位整数中符号位右边的2-bit; 保留4位小数的时候，丢弃lsb的小数位.
(temp[13][0] + (-4 * q[9] * D)_trunc_5_5)_post_process_trunc_3_4 = (00100_00001 + 11101_01011)_post_process_trunc_3_4 = 
(00001_01100)_post_process_trunc_3_4 = 001_0110 >= 0
(temp[13][1] + (-4 * q[9] * D)_trunc_5_5)_post_process_trunc_3_4 = (00011_01101 + 11101_01011)_post_process_trunc_3_4 = 
(00000_11000)_post_process_trunc_3_4 = 000_1100 >= 0
(temp[13][2] + (-4 * q[9] * D)_trunc_5_5)_post_process_trunc_3_4 = (00010_11001 + 11101_01011)_post_process_trunc_3_4 = 
(00000_00100)_post_process_trunc_3_4 = 000_0010 >= 0
(temp[13][3] + (-4 * q[9] * D)_trunc_5_5)_post_process_trunc_3_4 = (00010_00011 + 11101_01011)_post_process_trunc_3_4 = 
(11111_01110)_post_process_trunc_3_4 = 111_0111 < 0
根据比较结果(Sign Detection, SD)可得, "belongs to [m[1], m[2])" -> q[14] = +1
// Retimng + carry-save, reduced-width, early version:
(temp[13][0] + (-4 * q[13] * D)_trunc_5_5)_reduced_trunc_2_4 = 
01_0110 >= 0, don't care.
(temp[13][1] + (-4 * q[13] * D)_trunc_5_5)_reduced_trunc_3_3 = 
000_110 >= 0
(temp[13][2] + (-4 * q[13] * D)_trunc_5_5)_reduced_trunc_3_3 = 
000_001 >= 0
(temp[13][3] + (-4 * q[13] * D)_trunc_5_5)_reduced_trunc_2_4 = 
11_0111 < 0
根据比较结果(Sign Detection, SD)可得, "belongs to [m[1], m[2])" -> q[14] = +1
// Reduced-width, Method from the paper:
temp[13][0] = ((16 * w_sum[12])_reduced_2_5 + (16 * w_carry[12])_reduced_2_5 + m[-1]_补码_reduced_2_5)_reduced_2_5 = 
00_10101 + 10_01100 + 01_00000 = 00_00001
temp[13][1] = ((16 * w_sum[12])_reduced_3_4 + (16 * w_carry[12])_reduced_3_4 + m[+0]_补码_reduced_3_4)_reduced_3_4 = 
100_1010 + 110_0110 + 000_0110 = 011_0110
temp[13][2] = ((16 * w_sum[12])_reduced_3_4 + (16 * w_carry[12])_reduced_3_4 + m[+1]_补码_reduced_3_4)_reduced_3_4 = 
100_1010 + 110_0110 + 111_1100 = 010_1100
temp[13][3] = ((16 * w_sum[12])_reduced_2_5 + (16 * w_carry[12])_reduced_2_5 + m[+2]_补码_reduced_2_5)_reduced_2_5 = 
00_10101 + 10_01100 + 11_00010 = 10_00011
// reduced_2_4: 使用2-bit整数和4-bit小数表示"temp[x][y] + (-4 * q[x] * D)"的结果, 因此只需要将"(temp[x][y] + (-4 * q[x] * D))_sum_reduced_2_4"和
// "(temp[x][y] + (-4 * q[x] * D))_carry_reduced_2_4"输入到"SD"中即可
// reduced_3_3: 使用3-bit整数和3-bit小数表示"temp[x][y] + (-4 * q[x] * D)"的结果, 因此只需要将"(temp[x][y] + (-4 * q[x] * D))_sum_reduced_3_3"和
// "(temp[x][y] + (-4 * q[x] * D))_carry_reduced_3_3"输入到"SD"中即可
(temp[13][0] + (-4 * q[13] * D)_reduced_2_5)_reduced_2_4 = (00_00001 + 01_01011)_reduced_2_4 = 
(01_01100)_reduced_2_4 = 01_0110 >= 0, don't care.
(temp[13][1] + (-4 * q[13] * D)_reduced_3_4)_reduced_3_3 = (011_0110 + 101_0101)_reduced_3_3 = 
(000_1011)_reduced_3_3 = 000_101 >= 0
(temp[13][2] + (-4 * q[13] * D)_reduced_3_4)_reduced_3_3 = (010_1100 + 101_0101)_reduced_3_3 = 
(000_0001)_reduced_3_3 = 000_000 >= 0
(temp[13][3] + (-4 * q[13] * D)_reduced_2_5)_reduced_2_4 = (10_00011 + 01_01011)_reduced_2_4 = 
(11_01110)_reduced_2_4 = 11_0111 < 0
根据3较结果(Sign Detection, SD)可得, "belongs to [m[1], m[2])" -> q[14] = +1
q_pos = 1000_0000_0001_0010_0000_0000_0101
q_neg = 0010_0001_1000_1000_0001_0010_0000

ITER[13]:
// Standard Method
// carry-save:
w_sum[14] = csa_sum(4 * w_sum[13], 4 * w_carry[13], -q[14] * D)_post_process = 
0_000100000010100100100101100
w_carry[14] = csa_carry(4 * w_sum[13], 4 * w_carry[13], -q[14] * D)_post_process = 
1_101011101010110010110100000
(4 * w_sum[14])_trunc_3_4 + (4 * w_carry[14])_trunc_3_4 = 
000_0100 + 110_1011 = 110_1111, "belongs to [-Inf, m[-1])" -> q[15] = -2
// non-redundant:
4 * w[13] + (-q[14] * D) = 
000_011010001010011001111110000 + 
111_010101100010111101011011100 = 
111_101111101101010111011001100 ->
w[14] = 1_101111101101010111011001100
4 * w[14] = 110_111110110101011101100110000
(4 * w[14])_trunc_3_4 = 110_1111, "belongs to [-Inf, m[-1])" -> q[15] = -2
// New Method
// Retimng + carry-save, full-width:
temp[14][0] = ((16 * w_sum[13])_trunc_5_5 + (16 * w_carry[13])_trunc_5_5 + m[-1]_补码_trunc_5_5)_trunc_5_5 = 
11110_01011 + 00011_01000 + 00001_00000 = 00010_10011
temp[14][1] = ((16 * w_sum[13])_trunc_5_5 + (16 * w_carry[13])_trunc_5_5 + m[+0]_补码_trunc_5_5)_trunc_5_5 = 
11110_01011 + 00011_01000 + 00000_01100 = 00001_11111
temp[14][2] = ((16 * w_sum[13])_trunc_5_5 + (16 * w_carry[13])_trunc_5_5 + m[+1]_补码_trunc_5_5)_trunc_5_5 = 
11110_01011 + 00011_01000 + 11111_11000 = 00001_01011
temp[14][3] = ((16 * w_sum[13])_trunc_5_5 + (16 * w_carry[13])_trunc_5_5 + m[+2]_补码_trunc_5_5)_trunc_5_5 = 
11110_01011 + 00011_01000 + 11111_00010 = 00000_10101
// 做保留3位整数操作的时候, 丢弃原始的5位整数中符号位右边的2-bit; 保留4位小数的时候，丢弃lsb的小数位.
(temp[14][0] + (-4 * q[9] * D)_trunc_5_5)_post_process_trunc_3_4 = (00010_10011 + 11101_01011)_post_process_trunc_3_4 = 
(11111_11110)_post_process_trunc_3_4 = 111_1111 < 0
(temp[14][1] + (-4 * q[9] * D)_trunc_5_5)_post_process_trunc_3_4 = (00001_11111 + 11101_01011)_post_process_trunc_3_4 = 
(11111_01010)_post_process_trunc_3_4 = 111_0101 < 0
(temp[14][2] + (-4 * q[9] * D)_trunc_5_5)_post_process_trunc_3_4 = (00001_01011 + 11101_01011)_post_process_trunc_3_4 = 
(11110_10110)_post_process_trunc_3_4 = 110_1011 < 0
(temp[14][3] + (-4 * q[9] * D)_trunc_5_5)_post_process_trunc_3_4 = (00000_10101 + 11101_01011)_post_process_trunc_3_4 = 
(11110_00000)_post_process_trunc_3_4 = 110_0000 < 0
根据比较结果(Sign Detection, SD)可得, "belongs to [-Inf, m[-1])" -> q[15] = -2
// Retimng + carry-save, reduced-width, early version:
(temp[14][0] + (-4 * q[14] * D)_trunc_5_5)_reduced_trunc_2_4 = 
11_1111 < 0
(temp[14][1] + (-4 * q[14] * D)_trunc_5_5)_reduced_trunc_3_3 = 
111_010 < 0
(temp[14][2] + (-4 * q[14] * D)_trunc_5_5)_reduced_trunc_3_3 = 
110_101 < 0
(temp[14][3] + (-4 * q[14] * D)_trunc_5_5)_reduced_trunc_2_4 = 
10_0000 < 0, don't care.
根据比较结果(Sign Detection, SD)可得, "belongs to [-Inf, m[-1])" -> q[15] = -2
q_pos = 1000_0000_0001_0010_0000_0000_0101_00
q_neg = 0010_0001_1000_1000_0001_0010_0000_10

q_pos = 1000_0000_0001_0010_0000_0000_0101
q_neg = 0010_0001_1000_1000_0001_0010_0000
使用ITER[12]得到的"q_pos/q_neg"来计算结果:
q_pos - q_neg = 
1000_0000_0001_0010_0000_0000_0101 - 
0010_0001_1000_1000_0001_0010_0000 = 
0101111010001001111011100101, Normalization可得:
1_01111010001001111011100101
w[14] < 0:
Q_calculated[25-1:0] = 1_011110100010011110111001
G = 0
sticky_bit = 1

Q_no_rup[25-1:0] 	= 1_011110100010011110111001
Q_rup[25-1:0] 		= 1_011110100010011110111001

// ---------------------------------------------------------------------------------------------------------------------------------------

设小数点在"X[25]和X[24]"之间, 即"D[25]和D[24]"之间
X[26-1:0] = Dividend[26-1:0] = 0_1_0010_0000_0111_1001_1011_1111 = 0_1001000000111100110111111
D[26-1:0] = Divisor[26-1:0]  = 0_1_1110_1111_1111_0000_0101_1011 = 0_1111011111111000001011011

Q[25-1:0] = X / D = 18905535 / 32501851 = 0.5816756405658250048589540331103 = 
0_1001010011101000101100011_101110100011100001011011
Q_no_rup[25-1:0] 	= 1_001010011101000101100011
Q_rup[25-1:0] 		= 1_001010011101000101100100

将"+2D, +D, -D, -2D"进行符号扩展至30-bit(即和"4 * w_sum"的宽度一样), 可得:
D = 000_111101111111100000101101100
4 * D = 00011_110111111110000010110110000
2D = 001_111011111111000001011011000
4 * 2D = 00111_101111111100000101101100000
-D_补码 = 111_000010000000011111010010100
4 * -D_补码 = 11100_001000000001111101001010000
-2D_补码 = 110_000100000000111110100101000
4 * -2D_补码 = 11000_010000000011111010010100000

根据D的值, 可得选择常数:
m[-1] = -24 = 110_1000
m[+0] = - 8 = 111_1000
m[+1] = + 8	= 000_1000
m[+2] = +24 = 001_1000

m[-1]_补码_trunc_5_5 = 00001_10000
m[-1]_补码_trunc_2_5 = 01_10000
m[+0]_补码_trunc_5_5 = 00000_10000
m[+0]_补码_trunc_3_4 = 000_1000
m[+1]_补码_trunc_5_5 = 11111_10000
m[+1]_补码_trunc_3_4 = 111_1000
m[+2]_补码_trunc_5_5 = 11110_10000
m[+2]_补码_trunc_2_5 = 10_10000


初始化:
w[0][28-1:0] = X / 4 = 0_001001000000111100110111111
w_sum[0] = 0_001001000000111100110111111
w_carry[0] = 0_000000000000000000000000000
q[0] = 0
截取至w[0]小数点后6位, w_trunc[0][7-1:0] = w[0][27:21] = 0_001001
(4 * w[0])_trunc_3_4 = 000_1001, "belongs to [m[1], m[2])" -> q[1] = +1
q_pos = 01
q_neg = 00

ITER[0]:
// Standard Method:
// carry-save:
w_sum[1] = csa_sum(4 * w_sum[0], 4 * w_carry[0], -q[1] * D)_post_process = 
1_100110000011101100001101000
w_carry[1] = csa_carry(4 * w_sum[0], 4 * w_carry[0], -q[1] * D)_post_process = 
0_000000000000100110100101000
(4 * w_sum[1])_trunc_3_4 + (4 * w_carry[1])_trunc_3_4 = 
110_0110 + 000_0000 = 110_0110, "belongs to [-Inf, m[-1])" -> q[2] = -2
// non-redundant:
4 * w[0] + (-q[1] * D) = 
000_100100000011110011011111100 + 
111_000010000000011111010010100 = 
111_100110000100010010110010000 -> 
w[1] = 1_100110000100010010110010000
4 * w[1] = 110_011000010001001011001000000
(4 * w[1])_trunc_3_4 = 110_0110, "belongs to [-Inf, m[-1])" -> q[2] = -2
// New Method
// Retimng + carry-save, full-width:
temp[1][0] = ((16 * w_sum[0])_trunc_5_5 + (16 * w_carry[0])_trunc_5_5 + m[-1]_补码_trunc_5_5)_trunc_5_5 = 
00010_01000 + 00000_00000 + 00001_10000 = 00011_11000
temp[1][1] = ((16 * w_sum[0])_trunc_5_5 + (16 * w_carry[0])_trunc_5_5 + m[+0]_补码_trunc_5_5)_trunc_5_5 = 
00010_01000 + 00000_00000 + 00000_10000 = 00010_11000
temp[1][2] = ((16 * w_sum[0])_trunc_5_5 + (16 * w_carry[0])_trunc_5_5 + m[+1]_补码_trunc_5_5)_trunc_5_5 = 
00010_01000 + 00000_00000 + 11111_10000 = 00001_11000
temp[1][3] = ((16 * w_sum[0])_trunc_5_5 + (16 * w_carry[0])_trunc_5_5 + m[+2]_补码_trunc_5_5)_trunc_5_5 = 
00010_01000 + 00000_00000 + 11110_10000 = 00000_11000
// reduced_2_4: 使用2-bit整数和4-bit小数表示"temp[x][y] + (-4 * q[x] * D)"的结果, 因此只需要将"(temp[x][y] + (-4 * q[x] * D))_sum_reduced_2_4"和
// "(temp[x][y] + (-4 * q[x] * D))_carry_reduced_2_4"输入到"SD"中即可
// reduced_3_3: 使用3-bit整数和3-bit小数表示"temp[x][y] + (-4 * q[x] * D)"的结果, 因此只需要将"(temp[x][y] + (-4 * q[x] * D))_sum_reduced_3_3"和
// "(temp[x][y] + (-4 * q[x] * D))_carry_reduced_3_3"输入到"SD"中即可
(temp[1][0] + (-4 * q[1] * D)_trunc_5_5)_post_process_trunc_3_4 = (00011_11000 + 11100_00100)_post_process_trunc_3_4 = 
(11111_11100)_post_process_trunc_3_4 = 111_1110 < 0
(temp[1][1] + (-4 * q[1] * D)_trunc_5_4)_post_process_trunc_3_4 = (00010_11000 + 11100_00100)_post_process_trunc_3_4 = 
(11110_11100)_post_process_trunc_3_4 = 110_1110 < 0
(temp[1][2] + (-4 * q[1] * D)_trunc_5_5)_post_process_trunc_3_4 = (00001_11000 + 11100_00100)_post_process_trunc_3_4 = 
(11101_11100)_post_process_trunc_3_4 = 101_1110 < 0
(temp[1][3] + (-4 * q[1] * D)_trunc_5_5)_post_process_trunc_3_4 = (00000_11000 + 11100_00100)_post_process_trunc_3_4 = 
(11100_11100)_post_process_trunc_3_4 = 100_1110 < 0, don't care.
根据比较结果(Sign Detection, SD)可得, "belongs to [-Inf, m[-1])" -> q[2] = -2
// Reduced-width, Method from the paper:
temp[1][0] = ((16 * w_sum[0])_reduced_2_5 + (16 * w_carry[0])_reduced_2_5 + m[-1]_补码_reduced_2_5)_reduced_2_5 = 
10_01000 + 00_00000 + 01_10000 = 11_11000
temp[1][1] = ((16 * w_sum[0])_reduced_3_4 + (16 * w_carry[0])_reduced_3_4 + m[+0]_补码_reduced_3_4)_reduced_3_4 = 
010_0100 + 000_0000 + 000_1000 = 010_1100
temp[1][2] = ((16 * w_sum[0])_reduced_3_4 + (16 * w_carry[0])_reduced_3_4 + m[+1]_补码_reduced_3_4)_reduced_3_4 = 
010_0100 + 000_0000 + 111_1000 = 001_1100
temp[1][3] = ((16 * w_sum[0])_reduced_2_5 + (16 * w_carry[0])_reduced_2_5 + m[+2]_补码_reduced_2_5)_reduced_2_5 = 
10_01000 + 00_00000 + 10_10000 = 00_11000
// reduced_2_4: 使用2-bit整数和4-bit小数表示"temp[x][y] + (-4 * q[x] * D)"的结果, 因此只需要将"(temp[x][y] + (-4 * q[x] * D))_sum_reduced_2_4"和
// "(temp[x][y] + (-4 * q[x] * D))_carry_reduced_2_4"输入到"SD"中即可
// reduced_3_3: 使用3-bit整数和3-bit小数表示"temp[x][y] + (-4 * q[x] * D)"的结果, 因此只需要将"(temp[x][y] + (-4 * q[x] * D))_sum_reduced_3_3"和
// "(temp[x][y] + (-4 * q[x] * D))_carry_reduced_3_3"输入到"SD"中即可
(temp[1][0] + (-4 * q[1] * D)_reduced_2_5)_reduced_2_4 = (11_11000 + 00_00100)_reduced_2_4 = 
(11_11100)_reduced_2_4 = 11_1110 < 0
(temp[1][1] + (-4 * q[1] * D)_reduced_3_4)_reduced_3_3 = (010_1100 + 100_0010)_reduced_3_3 = 
(110_1110)_reduced_3_3 = 110_111 < 0
(temp[1][2] + (-4 * q[1] * D)_reduced_3_4)_reduced_3_3 = (001_1100 + 100_0010)_reduced_3_3 = 
(101_1110)_reduced_3_3 = 101_111 < 0
(temp[1][3] + (-4 * q[1] * D)_reduced_2_5)_reduced_2_4 = (00_11000 + 00_00100)_reduced_2_4 = 
(00_11100)_reduced_2_4 = 00_1110 >= 0, don't care.
根据比较结果(Sign Detection, SD)可得, "belongs to [-Inf, m[-1])" -> q[2] = -2
q_pos = 0100
q_neg = 0010

ITER[1]:
// Standard Method:
// carry-save:
w_sum[2] = csa_sum(4 * w_sum[1], 4 * w_carry[1], -q[2] * D)_post_process = 
1_100011110011101011111011000
w_carry[2] = csa_carry(4 * w_sum[1], 4 * w_carry[1], -q[2] * D)_post_process = 
0_110000011100100000101000000
(4 * w_sum[2])_trunc_3_4 + (4 * w_carry[2])_trunc_3_4 = 
110_0011 + 011_0000 = 001_0011, "belongs to [m[1], m[2])" -> q[3] = +1
// non-redundant:
4 * w[1] + (-q[2] * D) = 
110_011000010001001011001000000 + 
001_111011111111000001011011000 = 
000_010100010000001100100011000 -> 
w[2] = 0_010100010000001100100011000
4 * w[2] = 001_010001000000110010001100000
(4 * w[2])_trunc_3_4 = 001_0100, "belongs to [m[1], m[2])" -> q[3] = +1
// Reduced-width, Method from the paper:
temp[2][0] = ((16 * w_sum[1])_reduced_2_5 + (16 * w_carry[1])_reduced_2_5 + m[-1]_补码_reduced_2_5)_reduced_2_5 = 
01_10000 + 00_00000 + 01_10000 = 11_00000
temp[2][1] = ((16 * w_sum[1])_reduced_3_4 + (16 * w_carry[1])_reduced_3_4 + m[+0]_补码_reduced_3_4)_reduced_3_4 = 
001_1000 + 000_0000 + 000_1000 = 010_0000
temp[2][2] = ((16 * w_sum[1])_reduced_3_4 + (16 * w_carry[1])_reduced_3_4 + m[+1]_补码_reduced_3_4)_reduced_3_4 = 
001_1000 + 000_0000 + 111_1000 = 001_0000
temp[2][3] = ((16 * w_sum[1])_reduced_2_5 + (16 * w_carry[1])_reduced_2_5 + m[+2]_补码_reduced_2_5)_reduced_2_5 = 
01_10000 + 00_00000 + 10_10000 = 00_00000
// reduced_2_4: 使用2-bit整数和4-bit小数表示"temp[x][y] + (-4 * q[x] * D)"的结果, 因此只需要将"(temp[x][y] + (-4 * q[x] * D))_sum_reduced_2_4"和
// "(temp[x][y] + (-4 * q[x] * D))_carry_reduced_2_4"输入到"SD"中即可
// reduced_3_3: 使用3-bit整数和3-bit小数表示"temp[x][y] + (-4 * q[x] * D)"的结果, 因此只需要将"(temp[x][y] + (-4 * q[x] * D))_sum_reduced_3_3"和
// "(temp[x][y] + (-4 * q[x] * D))_carry_reduced_3_3"输入到"SD"中即可
(temp[2][0] + (-4 * q[2] * D)_reduced_2_5)_reduced_2_4 = (11_00000 + 11_10111)_reduced_2_4 = 
(10_10111)_reduced_2_4 = 10_1011 < 0, don't care.
(temp[2][1] + (-4 * q[2] * D)_reduced_3_4)_reduced_3_3 = (010_0000 + 111_1011)_reduced_3_3 = 
(001_1011)_reduced_3_3 = 001_101 >= 0
(temp[2][2] + (-4 * q[2] * D)_reduced_3_4)_reduced_3_3 = (001_0000 + 111_1011)_reduced_3_3 = 
(000_1011)_reduced_3_3 = 000_101 >= 0
(temp[2][3] + (-4 * q[2] * D)_reduced_2_5)_reduced_2_4 = (00_00000 + 11_10111)_reduced_2_4 = 
(11_10111)_reduced_2_4 = 11_1011 < 0
根据比较结果(Sign Detection, SD)可得, "belongs to [m[1], m[2])" -> q[3] = +1
q_pos = 0100_01
q_neg = 0010_00

ITER[2]:
// Standard Method:
// carry-save:
w_sum[3] = csa_sum(4 * w_sum[2], 4 * w_carry[2], -q[3] * D)_post_process = 
0_001100111100110010011110100
w_carry[3] = csa_carry(4 * w_sum[2], 4 * w_carry[2], -q[3] * D)_post_process = 
0_000110000100011111000000000
(4 * w_sum[3])_trunc_3_4 + (4 * w_carry[3])_trunc_3_4 = 
000_1100 + 000_0110 = 001_0010, "belongs to [m[1], m[2])" -> q[4] = +1
// non-redundant:
4 * w[2] + (-q[3] * D) = 
001_010001000000110010001100000 + 
111_000010000000011111010010100 = 
000_010011000001010001011110100 -> 
w[3] = 0_010011000001010001011110100
4 * w[3] = 001_001100000101000101111010000
(4 * w[3])_trunc_3_4 = 001_0011, "belongs to [m[1], m[2])" -> q[4] = +1
// Reduced-width, Method from the paper:
temp[3][0] = ((16 * w_sum[2])_reduced_2_5 + (16 * w_carry[2])_reduced_2_5 + m[-1]_补码_reduced_2_5)_reduced_2_5 = 
00_11110 + 00_00011 + 01_10000 = 10_10001
temp[3][1] = ((16 * w_sum[2])_reduced_3_4 + (16 * w_carry[2])_reduced_3_4 + m[+0]_补码_reduced_3_4)_reduced_3_4 = 
000_1111 + 100_0001 + 000_1000 = 101_1000
temp[3][2] = ((16 * w_sum[2])_reduced_3_4 + (16 * w_carry[2])_reduced_3_4 + m[+1]_补码_reduced_3_4)_reduced_3_4 = 
000_1111 + 100_0001 + 111_1000 = 100_1000
temp[3][3] = ((16 * w_sum[2])_reduced_2_5 + (16 * w_carry[2])_reduced_2_5 + m[+2]_补码_reduced_2_5)_reduced_2_5 = 
00_11110 + 00_00011 + 10_10000 = 11_10001
// reduced_2_4: 使用2-bit整数和4-bit小数表示"temp[x][y] + (-4 * q[x] * D)"的结果, 因此只需要将"(temp[x][y] + (-4 * q[x] * D))_sum_reduced_2_4"和
// "(temp[x][y] + (-4 * q[x] * D))_carry_reduced_2_4"输入到"SD"中即可
// reduced_3_3: 使用3-bit整数和3-bit小数表示"temp[x][y] + (-4 * q[x] * D)"的结果, 因此只需要将"(temp[x][y] + (-4 * q[x] * D))_sum_reduced_3_3"和
// "(temp[x][y] + (-4 * q[x] * D))_carry_reduced_3_3"输入到"SD"中即可
(temp[3][0] + (-4 * q[3] * D)_reduced_2_5)_reduced_2_4 = (10_10001 + 00_00100)_reduced_2_4 = 
(10_10101)_reduced_2_4 = 10_1010 < 0, don't care.
(temp[3][1] + (-4 * q[3] * D)_reduced_3_4)_reduced_3_3 = (101_1000 + 100_0010)_reduced_3_3 = 
(001_1010)_reduced_3_3 = 001_101 >= 0
(temp[3][2] + (-4 * q[3] * D)_reduced_3_4)_reduced_3_3 = (100_1000 + 100_0010)_reduced_3_3 = 
(000_1010)_reduced_3_3 = 000_101 >= 0
(temp[3][3] + (-4 * q[3] * D)_reduced_2_5)_reduced_2_4 = (11_10001 + 00_00100)_reduced_2_4 = 
(11_10101)_reduced_2_4 = 11_1010 < 0
根据比较结果(Sign Detection, SD)可得, "belongs to [m[1], m[2])" -> q[4] = +1
q_pos = 0100_0101
q_neg = 0010_0000

ITER[3]:
// Standard Method:
// carry-save:
w_sum[4] = csa_sum(4 * w_sum[3], 4 * w_carry[3], -q[4] * D)_post_process = 
1_101001100010101010101000100
w_carry[4] = csa_carry(4 * w_sum[3], 4 * w_carry[3], -q[4] * D)_post_process = 
0_100100100010111010100100000
(4 * w_sum[4])_trunc_3_4 + (4 * w_carry[4])_trunc_3_4 = 
110_1001 + 010_0100 = 000_1101, "belongs to [m[1], m[2])" -> q[5] = +1
// non-redundant:
4 * w[3] + (-q[4] * D) = 
001_001100000101000101111010000 + 
111_000010000000011111010010100 = 
000_001110000101100101001100100 -> 
w[4] = 0_001110000101100101001100100
4 * w[4] = 000_111000010110010100110010000
(4 * w[4])_trunc_3_4 = 000_1110, "belongs to [m[1], m[2])" -> q[5] = +1
// Reduced-width, Method from the paper:
temp[4][0] = ((16 * w_sum[3])_reduced_2_5 + (16 * w_carry[3])_reduced_2_5 + m[-1]_补码_reduced_2_5)_reduced_2_5 = 
11_00111 + 01_10000 + 01_10000 = 10_00111
temp[4][1] = ((16 * w_sum[3])_reduced_3_4 + (16 * w_carry[3])_reduced_3_4 + m[+0]_补码_reduced_3_4)_reduced_3_4 = 
011_0011 + 001_1000 + 000_1000 = 101_0011
temp[4][2] = ((16 * w_sum[3])_reduced_3_4 + (16 * w_carry[3])_reduced_3_4 + m[+1]_补码_reduced_3_4)_reduced_3_4 = 
011_0011 + 001_1000 + 111_1000 = 100_0011
temp[4][3] = ((16 * w_sum[3])_reduced_2_5 + (16 * w_carry[3])_reduced_2_5 + m[+2]_补码_reduced_2_5)_reduced_2_5 = 
11_00111 + 01_10000 + 10_10000 = 11_00111
// reduced_2_4: 使用2-bit整数和4-bit小数表示"temp[x][y] + (-4 * q[x] * D)"的结果, 因此只需要将"(temp[x][y] + (-4 * q[x] * D))_sum_reduced_2_4"和
// "(temp[x][y] + (-4 * q[x] * D))_carry_reduced_2_4"输入到"SD"中即可
// reduced_3_3: 使用3-bit整数和3-bit小数表示"temp[x][y] + (-4 * q[x] * D)"的结果, 因此只需要将"(temp[x][y] + (-4 * q[x] * D))_sum_reduced_3_3"和
// "(temp[x][y] + (-4 * q[x] * D))_carry_reduced_3_3"输入到"SD"中即可
(temp[4][0] + (-4 * q[4] * D)_reduced_2_5)_reduced_2_4 = (10_00111 + 11_11011)_reduced_2_4 = 
(10_00010)_reduced_2_4 = 10_0001 < 0, don't care.
(temp[4][1] + (-4 * q[4] * D)_reduced_3_4)_reduced_3_3 = (101_0011 + 011_1101)_reduced_3_3 = 
(001_0000)_reduced_3_3 = 001_000 >= 0
(temp[4][2] + (-4 * q[4] * D)_reduced_3_4)_reduced_3_3 = (100_0011 + 011_1101)_reduced_3_3 = 
(000_0000)_reduced_3_3 = 000_000 >= 0
(temp[4][3] + (-4 * q[4] * D)_reduced_2_5)_reduced_2_4 = (11_00111 + 11_11011)_reduced_2_4 = 
(11_00010)_reduced_2_4 = 11_0001 < 0
根据比较结果(Sign Detection, SD)可得, "belongs to [m[1], m[2])" -> q[5] = +1
q_pos = 0100_0101_01
q_neg = 0010_0000_00

ITER[4]:
// Standard Method:
// carry-save:
w_sum[5] = csa_sum(4 * w_sum[4], 4 * w_carry[4], -q[5] * D)_post_process = 
0_110110000001011111100000100
w_carry[5] = csa_carry(4 * w_sum[4], 4 * w_carry[4], -q[5] * D)_post_process = 
1_000100010101010100100100000
(4 * w_sum[5])_trunc_3_4 + (4 * w_carry[5])_trunc_3_4 = 
011_0110 + 100_0100 = 111_1010, "belongs to [m[0], m[1])" -> q[6] = +0
// non-redundant:
4 * w[4] + (-q[5] * D) = 
000_111000010110010100110010000 + 
111_000010000000011111010010100 = 
111_111010010110110100000100100 -> 
w[5] = 1_111010010110110100000100100
4 * w[5] = 111_101001011011010000010010000
(4 * w[5])_trunc_3_4 = 111_1010, "belongs to [m[0], m[1])" -> q[6] = +0
// Reduced-width, Method from the paper:
temp[5][0] = ((16 * w_sum[4])_reduced_2_5 + (16 * w_carry[4])_reduced_2_5 + m[-1]_补码_reduced_2_5)_reduced_2_5 = 
10_01100 + 01_00100 + 01_10000 = 01_00000
temp[5][1] = ((16 * w_sum[4])_reduced_3_4 + (16 * w_carry[4])_reduced_3_4 + m[+0]_补码_reduced_3_4)_reduced_3_4 = 
010_0110 + 001_0010 + 000_1000 = 100_0000
temp[5][2] = ((16 * w_sum[4])_reduced_3_4 + (16 * w_carry[4])_reduced_3_4 + m[+1]_补码_reduced_3_4)_reduced_3_4 = 
010_0110 + 001_0010 + 111_1000 = 011_0000
temp[5][3] = ((16 * w_sum[4])_reduced_2_5 + (16 * w_carry[4])_reduced_2_5 + m[+2]_补码_reduced_2_5)_reduced_2_5 = 
10_01100 + 01_00100 + 10_10000 = 10_00000
// reduced_2_4: 使用2-bit整数和4-bit小数表示"temp[x][y] + (-4 * q[x] * D)"的结果, 因此只需要将"(temp[x][y] + (-4 * q[x] * D))_sum_reduced_2_4"和
// "(temp[x][y] + (-4 * q[x] * D))_carry_reduced_2_4"输入到"SD"中即可
// reduced_3_3: 使用3-bit整数和3-bit小数表示"temp[x][y] + (-4 * q[x] * D)"的结果, 因此只需要将"(temp[x][y] + (-4 * q[x] * D))_sum_reduced_3_3"和
// "(temp[x][y] + (-4 * q[x] * D))_carry_reduced_3_3"输入到"SD"中即可
(temp[5][0] + (-4 * q[5] * D)_reduced_2_5)_reduced_2_4 = (01_00000 + 00_00100)_reduced_2_4 = 
(01_00100)_reduced_2_4 = 01_0010 >= 0, don't care.
(temp[5][1] + (-4 * q[5] * D)_reduced_3_4)_reduced_3_3 = (100_0000 + 100_0010)_reduced_3_3 = 
(000_0010)_reduced_3_3 = 000_001 >= 0
(temp[5][2] + (-4 * q[5] * D)_reduced_3_4)_reduced_3_3 = (011_0000 + 100_0010)_reduced_3_3 = 
(111_0010)_reduced_3_3 = 111_001 < 0
(temp[5][3] + (-4 * q[5] * D)_reduced_2_5)_reduced_2_4 = (10_00000 + 00_00100)_reduced_2_4 = 
(10_00100)_reduced_2_4 = 10_0010 < 0, don't care.
根据比较结果(Sign Detection, SD)可得, "belongs to [m[0], m[1])" -> q[6] = +0
q_pos = 0100_0101_0100
q_neg = 0010_0000_0000

ITER[5]:
// Standard Method:
// carry-save:
w_sum[6] = csa_sum(4 * w_sum[5], 4 * w_carry[5], -q[6] * D)_post_process = 
0_011000000101111110000010000
w_carry[6] = csa_carry(4 * w_sum[5], 4 * w_carry[5], -q[6] * D)_post_process = 
1_010001010101010010010000000
(4 * w_sum[6])_trunc_3_4 + (4 * w_carry[6])_trunc_3_4 = 
001_1000 + 101_0001 = 110_1001, "belongs to [m[-1], m[0])" -> q[7] = -1
// non-redundant:
4 * w[5] + (-q[6] * D) = 
111_101001011011010000010010000 + 
000_000000000000000000000000000 = 
111_101001011011010000010010000 -> 
w[6] = 1_101001011011010000010010000
4 * w[6] = 110_100101101101000001001000000
(4 * w[6])_trunc_3_4 = 110_1001, "belongs to [m[-1], m[0])" -> q[7] = -1
// Reduced-width, Method from the paper:
temp[6][0] = ((16 * w_sum[5])_reduced_2_5 + (16 * w_carry[5])_reduced_2_5 + m[-1]_补码_reduced_2_5)_reduced_2_5 = 
01_10000 + 01_00010 + 01_10000 = 00_00010
temp[6][1] = ((16 * w_sum[5])_reduced_3_4 + (16 * w_carry[5])_reduced_3_4 + m[+0]_补码_reduced_3_4)_reduced_3_4 = 
101_1000 + 001_0001 + 000_1000 = 111_0001
temp[6][2] = ((16 * w_sum[5])_reduced_3_4 + (16 * w_carry[5])_reduced_3_4 + m[+1]_补码_reduced_3_4)_reduced_3_4 = 
101_1000 + 001_0001 + 111_1000 = 110_0001
temp[6][3] = ((16 * w_sum[5])_reduced_2_5 + (16 * w_carry[5])_reduced_2_5 + m[+2]_补码_reduced_2_5)_reduced_2_5 = 
01_10000 + 01_00010 + 10_10000 = 01_00010
// reduced_2_4: 使用2-bit整数和4-bit小数表示"temp[x][y] + (-4 * q[x] * D)"的结果, 因此只需要将"(temp[x][y] + (-4 * q[x] * D))_sum_reduced_2_4"和
// "(temp[x][y] + (-4 * q[x] * D))_carry_reduced_2_4"输入到"SD"中即可
// reduced_3_3: 使用3-bit整数和3-bit小数表示"temp[x][y] + (-4 * q[x] * D)"的结果, 因此只需要将"(temp[x][y] + (-4 * q[x] * D))_sum_reduced_3_3"和
// "(temp[x][y] + (-4 * q[x] * D))_carry_reduced_3_3"输入到"SD"中即可
(temp[6][0] + (-4 * q[6] * D)_reduced_2_5)_reduced_2_4 = (00_00010 + 00_00000)_reduced_2_4 = 
(00_00010)_reduced_2_4 = 00_0001 >= 0
(temp[6][1] + (-4 * q[6] * D)_reduced_3_4)_reduced_3_3 = (111_0001 + 000_0000)_reduced_3_3 = 
(111_0001)_reduced_3_3 = 111_000 < 0
(temp[6][2] + (-4 * q[6] * D)_reduced_3_4)_reduced_3_3 = (110_0001 + 000_0000)_reduced_3_3 = 
(110_0001)_reduced_3_3 = 110_000 < 0
(temp[6][3] + (-4 * q[6] * D)_reduced_2_5)_reduced_2_4 = (01_00010 + 00_00000)_reduced_2_4 = 
(01_00010)_reduced_2_4 = 01_0001 >= 0, don't care.
根据比较结果(Sign Detection, SD)可得, "belongs to [m[-1], m[0])" -> q[7] = -1
q_pos = 0100_0101_0100_00
q_neg = 0010_0000_0000_01

ITER[6]:
// Standard Method:
// carry-save:
w_sum[7] = csa_sum(4 * w_sum[6], 4 * w_carry[6], -q[7] * D)_post_process = 
1_011000111101010001100101100
w_carry[7] = csa_carry(4 * w_sum[6], 4 * w_carry[6], -q[7] * D)_post_process = 
0_001010101111010000010000000
(4 * w_sum[7])_trunc_3_4 + (4 * w_carry[7])_trunc_3_4 = 
101_1000 + 000_1010 = 110_0010, "belongs to [-Inf, m[-1])" -> q[8] = -2
// non-redundant:
4 * w[6] + (-q[7] * D) = 
110_100101101101000001001000000 + 
000_111101111111100000101101100 = 
111_100011101100100001110101100 -> 
w[7] = 1_100011101100100001110101100
4 * w[7] = 110_001110110010000111010110000
(4 * w[7])_trunc_3_4 = 110_0011, "belongs to [-Inf, m[-1])" -> q[8] = -2
// Reduced-width, Method from the paper:
temp[7][0] = ((16 * w_sum[6])_reduced_2_5 + (16 * w_carry[6])_reduced_2_5 + m[-1]_补码_reduced_2_5)_reduced_2_5 = 
10_00000 + 00_01010 + 01_10000 = 11_11010
temp[7][1] = ((16 * w_sum[6])_reduced_3_4 + (16 * w_carry[6])_reduced_3_4 + m[+0]_补码_reduced_3_4)_reduced_3_4 = 
110_0000 + 100_0101 + 000_1000 = 010_1101
temp[7][2] = ((16 * w_sum[6])_reduced_3_4 + (16 * w_carry[6])_reduced_3_4 + m[+1]_补码_reduced_3_4)_reduced_3_4 = 
110_0000 + 100_0101 + 111_1000 = 001_1101
temp[7][3] = ((16 * w_sum[6])_reduced_2_5 + (16 * w_carry[6])_reduced_2_5 + m[+2]_补码_reduced_2_5)_reduced_2_5 = 
10_00000 + 00_01010 + 10_10000 = 00_11010
// reduced_2_4: 使用2-bit整数和4-bit小数表示"temp[x][y] + (-4 * q[x] * D)"的结果, 因此只需要将"(temp[x][y] + (-4 * q[x] * D))_sum_reduced_2_4"和
// "(temp[x][y] + (-4 * q[x] * D))_carry_reduced_2_4"输入到"SD"中即可
// reduced_3_3: 使用3-bit整数和3-bit小数表示"temp[x][y] + (-4 * q[x] * D)"的结果, 因此只需要将"(temp[x][y] + (-4 * q[x] * D))_sum_reduced_3_3"和
// "(temp[x][y] + (-4 * q[x] * D))_carry_reduced_3_3"输入到"SD"中即可
(temp[7][0] + (-4 * q[7] * D)_reduced_2_5)_reduced_2_4 = (11_11010 + 11_11011)_reduced_2_4 = 
(11_10101)_reduced_2_4 = 11_1010 < 0
(temp[7][1] + (-4 * q[7] * D)_reduced_3_4)_reduced_3_3 = (010_1101 + 011_1101)_reduced_3_3 = 
(110_1010)_reduced_3_3 = 110_101 < 0
(temp[7][2] + (-4 * q[7] * D)_reduced_3_4)_reduced_3_3 = (001_1101 + 011_1101)_reduced_3_3 = 
(101_1010)_reduced_3_3 = 101_101 < 0
(temp[7][3] + (-4 * q[7] * D)_reduced_2_5)_reduced_2_4 = (00_11010 + 11_11011)_reduced_2_4 = 
(00_10101)_reduced_2_4 = 00_1010 >= 0, don't care.
根据比较结果(Sign Detection, SD)可得, "belongs to [-Inf, m[-1])" -> q[8] = -2
q_pos = 0100_0101_0100_0000
q_neg = 0010_0000_0000_0110

ITER[7]:
// Standard Method:
// carry-save:
w_sum[8] = csa_sum(4 * w_sum[7], 4 * w_carry[7], -q[8] * D)_post_process = 
1_110010110111000110001101000
w_carry[8] = csa_carry(4 * w_sum[7], 4 * w_carry[7], -q[8] * D)_post_process = 
0_010111111010000010100100000
(4 * w_sum[8])_trunc_3_4 + (4 * w_carry[8])_trunc_3_4 = 
111_0010 + 001_0111 = 000_1001, "belongs to [m[1], m[2])" -> q[9] = +1
// non-redundant:
4 * w[7] + (-q[8] * D) = 
110_001110110010000111010110000 + 
001_111011111111000001011011000 = 
000_001010110001001000110001000 -> 
w[8] = 0_001010110001001000110001000
4 * w[8] = 000_101011000100100011000100000
(4 * w[8])_trunc_3_4 = 000_1010, "belongs to [m[1], m[2])" -> q[9] = +1
// Reduced-width, Method from the paper:
temp[8][0] = ((16 * w_sum[7])_reduced_2_5 + (16 * w_carry[7])_reduced_2_5 + m[-1]_补码_reduced_2_5)_reduced_2_5 = 
10_00111 + 10_10101 + 01_10000 = 10_01100
temp[8][1] = ((16 * w_sum[7])_reduced_3_4 + (16 * w_carry[7])_reduced_3_4 + m[+0]_补码_reduced_3_4)_reduced_3_4 = 
110_0011 + 010_1010 + 000_1000 = 001_0101
temp[8][2] = ((16 * w_sum[7])_reduced_3_4 + (16 * w_carry[7])_reduced_3_4 + m[+1]_补码_reduced_3_4)_reduced_3_4 = 
110_0011 + 010_1010 + 111_1000 = 000_0101
temp[8][3] = ((16 * w_sum[7])_reduced_2_5 + (16 * w_carry[7])_reduced_2_5 + m[+2]_补码_reduced_2_5)_reduced_2_5 = 
10_00111 + 10_10101 + 10_10000 = 11_01100
// reduced_2_4: 使用2-bit整数和4-bit小数表示"temp[x][y] + (-4 * q[x] * D)"的结果, 因此只需要将"(temp[x][y] + (-4 * q[x] * D))_sum_reduced_2_4"和
// "(temp[x][y] + (-4 * q[x] * D))_carry_reduced_2_4"输入到"SD"中即可
// reduced_3_3: 使用3-bit整数和3-bit小数表示"temp[x][y] + (-4 * q[x] * D)"的结果, 因此只需要将"(temp[x][y] + (-4 * q[x] * D))_sum_reduced_3_3"和
// "(temp[x][y] + (-4 * q[x] * D))_carry_reduced_3_3"输入到"SD"中即可
(temp[8][0] + (-4 * q[8] * D)_reduced_2_5)_reduced_2_4 = (10_01100 + 11_10111)_reduced_2_4 = 
(10_00011)_reduced_2_4 = 10_0001 < 0, don't care.
(temp[8][1] + (-4 * q[8] * D)_reduced_3_4)_reduced_3_3 = (001_0101 + 111_1011)_reduced_3_3 = 
(001_0000)_reduced_3_3 = 001_000 >= 0
(temp[8][2] + (-4 * q[8] * D)_reduced_3_4)_reduced_3_3 = (000_0101 + 111_1011)_reduced_3_3 = 
(000_0000)_reduced_3_3 = 000_000 >= 0
(temp[8][3] + (-4 * q[8] * D)_reduced_2_5)_reduced_2_4 = (11_01100 + 11_10111)_reduced_2_4 = 
(11_00011)_reduced_2_4 = 11_0001 < 0
根据比较结果(Sign Detection, SD)可得, "belongs to [m[1], m[2])" -> q[9] = +1
q_pos = 0100_0101_0100_0000_01
q_neg = 0010_0000_0000_0110_00

ITER[8]:
// Standard Method:
// carry-save:
w_sum[9] = csa_sum(4 * w_sum[8], 4 * w_carry[8], -q[9] * D)_post_process = 
1_010110110100001101110110100
w_carry[9] = csa_carry(4 * w_sum[8], 4 * w_carry[8], -q[9] * D)_post_process = 
0_010110010000110100100000000
(4 * w_sum[9])_trunc_3_4 + (4 * w_carry[9])_trunc_3_4 = 
101_0110 + 001_0110 = 110_1100, "belongs to [m[-1], m[0])" -> q[10] = -1
// non-redundant:
4 * w[8] + (-q[9] * D) = 
000_101011000100100011000100000 + 
111_000010000000011111010010100 = 
111_101101000101000010010110100 -> 
w[9] = 1_101101000101000010010110100
4 * w[9] = 110_110100010100001001011010000
(4 * w[9])_trunc_3_4 = 110_1101, "belongs to [m[-1], m[0])" -> q[10] = -1
// Reduced-width, Method from the paper:
temp[9][0] = ((16 * w_sum[8])_reduced_2_5 + (16 * w_carry[8])_reduced_2_5 + m[-1]_补码_reduced_2_5)_reduced_2_5 = 
00_10110 + 01_11111 + 01_10000 = 00_00101
temp[9][1] = ((16 * w_sum[8])_reduced_3_4 + (16 * w_carry[8])_reduced_3_4 + m[+0]_补码_reduced_3_4)_reduced_3_4 = 
100_1011 + 101_1111 + 000_1000 = 011_0010
temp[9][2] = ((16 * w_sum[8])_reduced_3_4 + (16 * w_carry[8])_reduced_3_4 + m[+1]_补码_reduced_3_4)_reduced_3_4 = 
100_1011 + 101_1111 + 111_1000 = 010_0010
temp[9][3] = ((16 * w_sum[8])_reduced_2_5 + (16 * w_carry[8])_reduced_2_5 + m[+2]_补码_reduced_2_5)_reduced_2_5 = 
00_10110 + 01_11111 + 10_10000 = 01_00101
// reduced_2_4: 使用2-bit整数和4-bit小数表示"temp[x][y] + (-4 * q[x] * D)"的结果, 因此只需要将"(temp[x][y] + (-4 * q[x] * D))_sum_reduced_2_4"和
// "(temp[x][y] + (-4 * q[x] * D))_carry_reduced_2_4"输入到"SD"中即可
// reduced_3_3: 使用3-bit整数和3-bit小数表示"temp[x][y] + (-4 * q[x] * D)"的结果, 因此只需要将"(temp[x][y] + (-4 * q[x] * D))_sum_reduced_3_3"和
// "(temp[x][y] + (-4 * q[x] * D))_carry_reduced_3_3"输入到"SD"中即可
(temp[9][0] + (-4 * q[9] * D)_reduced_2_5)_reduced_2_4 = (00_00101 + 00_00100)_reduced_2_4 = 
(00_01001)_reduced_2_4 = 00_0100 >= 0
(temp[9][1] + (-4 * q[9] * D)_reduced_3_4)_reduced_3_3 = (011_0010 + 100_0010)_reduced_3_3 = 
(111_0100)_reduced_3_3 = 111_010 < 0
(temp[9][2] + (-4 * q[9] * D)_reduced_3_4)_reduced_3_3 = (010_0010 + 100_0010)_reduced_3_3 = 
(110_0100)_reduced_3_3 = 110_010 < 0
(temp[9][3] + (-4 * q[9] * D)_reduced_2_5)_reduced_2_4 = (01_00101 + 00_00100)_reduced_2_4 = 
(01_01001)_reduced_2_4 = 01_0100 >= 0, don't care.
根据比较结果(Sign Detection, SD)可得, "belongs to [m[-1], m[0])" -> q[10] = -1
q_pos = 0100_0101_0100_0000_0100
q_neg = 0010_0000_0000_0110_0001

ITER[9]:
// Standard Method:
// carry-save:
w_sum[10] = csa_sum(4 * w_sum[9], 4 * w_carry[9], -q[10] * D)_post_process = 
1_111111101100000101110111100
w_carry[10] = csa_carry(4 * w_sum[9], 4 * w_carry[9], -q[10] * D)_post_process = 
1_110010100111100100010000000
(4 * w_sum[10])_trunc_3_4 + (4 * w_carry[10])_trunc_3_4 = 
111_1111 + 111_0010 = 111_0001, "belongs to [m[-1], m[0])" -> q[11] = -1
// non-redundant:
4 * w[9] + (-q[10] * D) = 
110_110100010100001001011010000 + 
000_111101111111100000101101100 = 
111_110010010011101010000111100 -> 
w[10] = 1_110010010011101010000111100
4 * w[10] = 111_001001001110101000011110000
(4 * w[10])_trunc_3_4 = 111_0010, "belongs to [m[-1], m[0])" -> q[11] = -1
// Reduced-width, Method from the paper:
temp[10][0] = ((16 * w_sum[9])_reduced_2_5 + (16 * w_carry[9])_reduced_2_5 + m[-1]_补码_reduced_2_5)_reduced_2_5 = 
01_10110 + 01_10010 + 01_10000 = 00_11000
temp[10][1] = ((16 * w_sum[9])_reduced_3_4 + (16 * w_carry[9])_reduced_3_4 + m[+0]_补码_reduced_3_4)_reduced_3_4 = 
101_1011 + 101_1001 + 000_1000 = 011_1100
temp[10][2] = ((16 * w_sum[9])_reduced_3_4 + (16 * w_carry[9])_reduced_3_4 + m[+1]_补码_reduced_3_4)_reduced_3_4 = 
101_1011 + 101_1001 + 111_1000 = 010_1100
temp[10][3] = ((16 * w_sum[9])_reduced_2_5 + (16 * w_carry[9])_reduced_2_5 + m[+2]_补码_reduced_2_5)_reduced_2_5 = 
01_10110 + 01_10010 + 10_10000 = 01_11000
// reduced_2_4: 使用2-bit整数和4-bit小数表示"temp[x][y] + (-4 * q[x] * D)"的结果, 因此只需要将"(temp[x][y] + (-4 * q[x] * D))_sum_reduced_2_4"和
// "(temp[x][y] + (-4 * q[x] * D))_carry_reduced_2_4"输入到"SD"中即可
// reduced_3_3: 使用3-bit整数和3-bit小数表示"temp[x][y] + (-4 * q[x] * D)"的结果, 因此只需要将"(temp[x][y] + (-4 * q[x] * D))_sum_reduced_3_3"和
// "(temp[x][y] + (-4 * q[x] * D))_carry_reduced_3_3"输入到"SD"中即可
(temp[10][0] + (-4 * q[10] * D)_reduced_2_5)_reduced_2_4 = (00_11000 + 11_11011)_reduced_2_4 = 
(00_10011)_reduced_2_4 = 00_1001 >= 0
(temp[10][1] + (-4 * q[10] * D)_reduced_3_4)_reduced_3_3 = (011_1100 + 011_1101)_reduced_3_3 = 
(111_1001)_reduced_3_3 = 111_100 < 0
(temp[10][2] + (-4 * q[10] * D)_reduced_3_4)_reduced_3_3 = (010_1100 + 011_1101)_reduced_3_3 = 
(110_1001)_reduced_3_3 = 110_100 < 0
(temp[10][3] + (-4 * q[10] * D)_reduced_2_5)_reduced_2_4 = (01_11000 + 11_11011)_reduced_2_4 = 
(01_10011)_reduced_2_4 = 01_1001 >= 0, don't care.
根据比较结果(Sign Detection, SD)可得, "belongs to [m[-1], m[0])" -> q[11] = -1
q_pos = 0100_0101_0100_0000_0100_00
q_neg = 0010_0000_0000_0110_0001_01

ITER[10]:
// Standard Method:
// carry-save:
w_sum[11] = csa_sum(4 * w_sum[10], 4 * w_carry[10], -q[11] * D)_post_process = 
0_001001010001100110110011100
w_carry[11] = csa_carry(4 * w_sum[10], 4 * w_carry[10], -q[11] * D)_post_process = 
1_111101111100100010011000000
(4 * w_sum[11])_trunc_3_4 + (4 * w_carry[11])_trunc_3_4 = 
000_1001 + 111_1101 = 000_0110, "belongs to [m[0], m[1])" -> q[12] = +0
// non-redundant:
4 * w[10] + (-q[11] * D) = 
111_001001001110101000011110000 + 
000_111101111111100000101101100 = 
000_000111001110001001001011100 -> 
w[11] = 0_000111001110001001001011100
4 * w[11] = 000_011100111000100100101110000
(4 * w[11])_trunc_3_4 = 000_0111, "belongs to [m[0], m[1])" -> q[12] = +0
// Reduced-width, Method from the paper:
temp[11][0] = ((16 * w_sum[10])_reduced_2_5 + (16 * w_carry[10])_reduced_2_5 + m[-1]_补码_reduced_2_5)_reduced_2_5 = 
11_11101 + 00_10100 + 01_10000 = 10_00001
temp[11][1] = ((16 * w_sum[10])_reduced_3_4 + (16 * w_carry[10])_reduced_3_4 + m[+0]_补码_reduced_3_4)_reduced_3_4 = 
111_1110 + 100_1010 + 000_1000 = 101_0000
temp[11][2] = ((16 * w_sum[10])_reduced_3_4 + (16 * w_carry[10])_reduced_3_4 + m[+1]_补码_reduced_3_4)_reduced_3_4 = 
111_1110 + 100_1010 + 111_1000 = 100_0000
temp[11][3] = ((16 * w_sum[10])_reduced_2_5 + (16 * w_carry[10])_reduced_2_5 + m[+2]_补码_reduced_2_5)_reduced_2_5 = 
11_11101 + 00_10100 + 10_10000 = 11_00001
// reduced_2_4: 使用2-bit整数和4-bit小数表示"temp[x][y] + (-4 * q[x] * D)"的结果, 因此只需要将"(temp[x][y] + (-4 * q[x] * D))_sum_reduced_2_4"和
// "(temp[x][y] + (-4 * q[x] * D))_carry_reduced_2_4"输入到"SD"中即可
// reduced_3_3: 使用3-bit整数和3-bit小数表示"temp[x][y] + (-4 * q[x] * D)"的结果, 因此只需要将"(temp[x][y] + (-4 * q[x] * D))_sum_reduced_3_3"和
// "(temp[x][y] + (-4 * q[x] * D))_carry_reduced_3_3"输入到"SD"中即可
(temp[11][0] + (-4 * q[11] * D)_reduced_2_5)_reduced_2_4 = (10_00001 + 11_11011)_reduced_2_4 = 
(01_11100)_reduced_2_4 = 01_1110 >= 0, don't care.
(temp[11][1] + (-4 * q[11] * D)_reduced_3_4)_reduced_3_3 = (101_0000 + 011_1101)_reduced_3_3 = 
(000_1101)_reduced_3_3 = 000_110 >= 0
(temp[11][2] + (-4 * q[11] * D)_reduced_3_4)_reduced_3_3 = (100_0000 + 011_1101)_reduced_3_3 = 
(111_1101)_reduced_3_3 = 111_110 < 0
(temp[11][3] + (-4 * q[11] * D)_reduced_2_5)_reduced_2_4 = (11_00001 + 11_11011)_reduced_2_4 = 
(10_11100)_reduced_2_4 = 10_1110 < 0, don't care.
根据比较结果(Sign Detection, SD)可得, "belongs to [m[0], m[1])" -> q[12] = +0
q_pos = 0100_0101_0100_0000_0100_0000
q_neg = 0010_0000_0000_0110_0001_0100

ITER[11]:
// Standard Method:
// carry-save:
w_sum[12] = csa_sum(4 * w_sum[11], 4 * w_carry[11], -q[12] * D)_post_process = 
0_100101000110011011001110000
w_carry[12] = csa_carry(4 * w_sum[11], 4 * w_carry[11], -q[12] * D)_post_process = 
1_110111110010001001100000000
(4 * w_sum[12])_trunc_3_4 + (4 * w_carry[12])_trunc_3_4 = 
010_0101 + 111_0111 = 001_1100, "belongs to [m[2], +Inf)" -> q[13] = +2
// non-redundant:
4 * w[11] + (-q[12] * D) = 
000_011100111000100100101110000 + 
000_000000000000000000000000000 = 
000_011100111000100100101110000 -> 
w[12] = 0_011100111000100100101110000
4 * w[12] = 001_110011100010010010111000000
(4 * w[12])_trunc_3_4 = 001_1100, "belongs to [m[2], +Inf)" -> q[13] = +2
// Reduced-width, Method from the paper:
temp[12][0] = ((16 * w_sum[11])_reduced_2_5 + (16 * w_carry[11])_reduced_2_5 + m[-1]_补码_reduced_2_5)_reduced_2_5 = 
10_01010 + 11_01111 + 01_10000 = 11_01001
temp[12][1] = ((16 * w_sum[11])_reduced_3_4 + (16 * w_carry[11])_reduced_3_4 + m[+0]_补码_reduced_3_4)_reduced_3_4 = 
010_0101 + 111_0111 + 000_1000 = 010_0100
temp[12][2] = ((16 * w_sum[11])_reduced_3_4 + (16 * w_carry[11])_reduced_3_4 + m[+1]_补码_reduced_3_4)_reduced_3_4 = 
010_0101 + 111_0111 + 111_1000 = 001_0100
temp[12][3] = ((16 * w_sum[11])_reduced_2_5 + (16 * w_carry[11])_reduced_2_5 + m[+2]_补码_reduced_2_5)_reduced_2_5 = 
10_01010 + 11_01111 + 10_10000 = 00_01001
// reduced_2_4: 使用2-bit整数和4-bit小数表示"temp[x][y] + (-4 * q[x] * D)"的结果, 因此只需要将"(temp[x][y] + (-4 * q[x] * D))_sum_reduced_2_4"和
// "(temp[x][y] + (-4 * q[x] * D))_carry_reduced_2_4"输入到"SD"中即可
// reduced_3_3: 使用3-bit整数和3-bit小数表示"temp[x][y] + (-4 * q[x] * D)"的结果, 因此只需要将"(temp[x][y] + (-4 * q[x] * D))_sum_reduced_3_3"和
// "(temp[x][y] + (-4 * q[x] * D))_carry_reduced_3_3"输入到"SD"中即可
(temp[12][0] + (-4 * q[12] * D)_reduced_2_5)_reduced_2_4 = (11_01001 + 00_00000)_reduced_2_4 = 
(11_01001)_reduced_2_4 = 11_0100 < 0, don't care.
(temp[12][1] + (-4 * q[12] * D)_reduced_3_4)_reduced_3_3 = (010_0100 + 000_0000)_reduced_3_3 = 
(010_0100)_reduced_3_3 = 010_010 >= 0
(temp[12][2] + (-4 * q[12] * D)_reduced_3_4)_reduced_3_3 = (001_0100 + 000_0000)_reduced_3_3 = 
(001_0100)_reduced_3_3 = 001_010 >= 0
(temp[12][3] + (-4 * q[12] * D)_reduced_2_5)_reduced_2_4 = (00_01001 + 00_00000)_reduced_2_4 = 
(00_01001)_reduced_2_4 = 00_0100 >= 0
根据比较结果(Sign Detection, SD)可得, "belongs to [m[2], +Inf)" -> q[13] = +2
q_pos = 0100_0101_0100_0000_0100_0000_10
q_neg = 0010_0000_0000_0110_0001_0100_00

ITER[12]:
// Standard Method:
// carry-save:
w_sum[13] = csa_sum(4 * w_sum[12], 4 * w_carry[12], -q[13] * D)_post_process = 
0_001111010001110100011101000
w_carry[13] = csa_carry(4 * w_sum[12], 4 * w_carry[12], -q[13] * D)_post_process = 
1_101000010001011101000000000
(4 * w_sum[13])_trunc_3_4 + (4 * w_carry[13])_trunc_3_4 = 
000_1111 + 110_1000 = 111_0111, "belongs to [m[-1], m[0])" -> q[14] = -1
// non-redundant:
4 * w[12] + (-q[13] * D) = 
001_110011100010010010111000000 + 
110_000100000000111110100101000 = 
111_110111100011010001011101000 -> 
w[13] = 1_110111100011010001011101000
4 * w[13] = 111_011110001101000101110100000
(4 * w[13])_trunc_3_4 = 111_0111, "belongs to [m[-1], m[0])" -> q[14] = -1
// Reduced-width, Method from the paper:
temp[13][0] = ((16 * w_sum[12])_reduced_2_5 + (16 * w_carry[12])_reduced_2_5 + m[-1]_补码_reduced_2_5)_reduced_2_5 = 
01_01000 + 01_11110 + 01_10000 = 00_10110
temp[13][1] = ((16 * w_sum[12])_reduced_3_4 + (16 * w_carry[12])_reduced_3_4 + m[+0]_补码_reduced_3_4)_reduced_3_4 = 
001_0100 + 101_1111 + 000_1000 = 111_1011
temp[13][2] = ((16 * w_sum[12])_reduced_3_4 + (16 * w_carry[12])_reduced_3_4 + m[+1]_补码_reduced_3_4)_reduced_3_4 = 
001_0100 + 101_1111 + 111_1000 = 110_1011
temp[13][3] = ((16 * w_sum[12])_reduced_2_5 + (16 * w_carry[12])_reduced_2_5 + m[+2]_补码_reduced_2_5)_reduced_2_5 = 
01_01000 + 01_11110 + 10_10000 = 01_10110
// reduced_2_4: 使用2-bit整数和4-bit小数表示"temp[x][y] + (-4 * q[x] * D)"的结果, 因此只需要将"(temp[x][y] + (-4 * q[x] * D))_sum_reduced_2_4"和
// "(temp[x][y] + (-4 * q[x] * D))_carry_reduced_2_4"输入到"SD"中即可
// reduced_3_3: 使用3-bit整数和3-bit小数表示"temp[x][y] + (-4 * q[x] * D)"的结果, 因此只需要将"(temp[x][y] + (-4 * q[x] * D))_sum_reduced_3_3"和
// "(temp[x][y] + (-4 * q[x] * D))_carry_reduced_3_3"输入到"SD"中即可
(temp[13][0] + (-4 * q[13] * D)_reduced_2_5)_reduced_2_4 = (00_10110 + 00_01000)_reduced_2_4 = 
(00_11110)_reduced_2_4 = 00_1111 >= 0
(temp[13][1] + (-4 * q[13] * D)_reduced_3_4)_reduced_3_3 = (111_1011 + 000_0100)_reduced_3_3 = 
(111_1111)_reduced_3_3 = 111_111 < 0
(temp[13][2] + (-4 * q[13] * D)_reduced_3_4)_reduced_3_3 = (110_1011 + 000_0100)_reduced_3_3 = 
(110_1111)_reduced_3_3 = 110_111 < 0
(temp[13][3] + (-4 * q[13] * D)_reduced_2_5)_reduced_2_4 = (01_10110 + 00_01000)_reduced_2_4 = 
(01_11110)_reduced_2_4 = 01_1111 >= 0, don't care.
根据比较结果(Sign Detection, SD)可得, "belongs to [m[-1], m[0])" -> q[14] = -1
q_pos = 0100_0101_0100_0000_0100_0000_1000
q_neg = 0010_0000_0000_0110_0001_0100_0001

ITER[13]:
// Standard Method:
// carry-save:
w_sum[14] = csa_sum(4 * w_sum[13], 4 * w_carry[13], -q[14] * D)_post_process = 
0_100001111101000101011001100
w_carry[14] = csa_carry(4 * w_sum[13], 4 * w_carry[13], -q[14] * D)_post_process = 
1_111010001111100001001000000
(4 * w_sum[14])_trunc_3_4 + (4 * w_carry[14])_trunc_3_4 = 
010_0001 + 111_1010 = 001_1011, "belongs to [m[2], +Inf)" -> q[15] = +2
// non-redundant:
4 * w[13] + (-q[14] * D) = 
111_011110001101000101110100000 + 
000_111101111111100000101101100 = 
000_011100001100100110100001100 -> 
w[14] = 0_011100001100100110100001100
4 * w[14] = 001_110000110010011010000110000
(4 * w[14])_trunc_3_4 = 001_1100, "belongs to [m[2], +Inf)" -> q[15] = +2
q_pos = 0100_0101_0100_0000_0100_0000_1000_10
q_neg = 0010_0000_0000_0110_0001_0100_0001_00


使用ITER[12]得到的"q_pos/q_neg"来计算结果:
q_pos - q_neg = 
0100_0101_0100_0000_0100_0000_1000 - 
0010_0000_0000_0110_0001_0100_0001 = 
0010010100111010001011000111, Normalization可得:
1_0010100111010001011000111
w[14] = 0_011100001100100110100001100 > 0:
Q_calculated[25-1:0] = 1_001010011101000101100011, 
G = 1
sticky_bit = 1
结果正确
Q_no_rup[25-1:0] 	= 1_001010011101000101100011
Q_rup[25-1:0] 		= 1_001010011101000101100100

Q_calculated[25-1：0] * Divisor[26-1:0] = 10010000001111001101111100100101110011111000110001
Dividend[50-1:0] = 10010000001111001101111110000000000000000000000000
Sub_result = 1011010001100000111001111

综上所述, 对于FP32除法, 尾数除法的结果应当为1-bit整数和23-bit小数, 再加上1-bit的G, 即一共需要计算25-bit的商
X小于D时, 需要再将Q左移1位形成规格化的形式, 因此总共需要计算26-bit的商, 即迭代13次, 按照这个文档中给出的例子, 需要迭代到ITER[12],
计算出q[14], 即可停止迭代. 
但是为了得到正确的舍入结果, 还需要知道w[14]的符号和绝对值:
if(w[14] < 0)
begin
	Q_calculated[WIDTH-1:0] = Q_calculated[WIDTH-1:0] - 1'b1;
	sticky_bit = 1'b1;
end
else if(w[14] > 0)
begin
	sticky_bit = 1'b1;
end
else
begin
	sticky_bit = 1'b0;
end

看起来舍入的逻辑比较复杂，可能需要2个周期才能完成舍入操作.
