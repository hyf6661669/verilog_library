接"test_3.sv", 探究余数的计算方法.
WIDTH = 28;
4个"Radix-2"串联形成"Radix-16" -> N = 16;
// ---------------------------------------------------------------------------------------------------------------------------------------
几个关键寄存器:
1. Q[(WIDTH - log2(N)) - 1:0]: 记录前(M - 1)次大迭代产生的"non-redundant"的商, 举例:
WIDTH = 28, 那么至多进行"28 / 4 = 7"次大迭代, 所以在第7次大迭代中, 需要计算出前6次大迭代的商的非冗余形式, 因为是对无符号数进行除法操作, 所以前6次
大迭代的商的非冗余形式一定是正数, 因此需要"6 * 4 = 24-bit"的信号来记录结果。这样在第7次大迭代结束之后，在后处理过程中, 会将前6次大迭代产生的24-bit的商的非冗余形式
和第7次(最后一次)大迭代产生的4个商数字结合起来生成最终的28-bit的非冗余形式的商.

2. Q_temp[(log2(N) + 1)- 1:0]: 对于本次迭代生成的4个商来说, 对第"0, 1, 2"次小迭代产生的商数字使用全加器得到5-bit的"non-redundant"商数字.
需要5-bit是因为前3次小迭代产生的商数字的叠加值可能是"+8/-8".
不处理第"3"次小迭代产生的商数字, 而是用一个3-bit寄存器将其保存起来, 这样在最后一次小迭代完成的时候差不多马上就能把QDS的输出发送到迭代寄存器的输入端口。

3. q_temp[2:0]: 最后一次小迭代产生的商数字的3-bit补码形式, 表示集合{-2, -1, 0, +1, +2}中的某个元素, 意义参考上面。
// ---------------------------------------------------------------------------------------------------------------------------------------
有了上述3个寄存器之后，在每次大迭代开始的时候，计算:
Q[(WIDTH - log2(N)) - 1:0] <= {Q[0 +: (WIDTH - 2 * log2(N))], {(log2(N)){1'b0}}} + sign_ext({Q_temp, 1'b0}) + sign_ext(q_temp[2:0]);
上述"full adder"的计算是和多次小迭代并行进行的，不会对时序造成影响。


// ---------------------------------------------------------------------------------------------------------------------------------------
X[WIDTH-1:0] = 1111110000100111111000001100 = 264404492
D[WIDTH-1:0] = 0000000000000000000000001001 = 9
Q[WIDTH-1:0] = X / D = 29378276 = 0001110000000100011011100100
REM[WIDTH-1:0] = 264404492 - 9 * 29378276 = 8 = 0000000000000000000000001000

CLZ_X = 0
CLZ_D = 24
CLZ_DIFF = CLZ_D - CLZ_X = 24
r_shift_num = log2(N) - 1 - (CLZ_DIFF % log2(N)) = 3 - (24 % 4) = 3;
迭代次数
iter_num = ceil((CLZ_DIFF + 1) / log2(N)) = ceil(25 / 4) = 7;
规格化操作之后:
Dividend[WIDTH-1:0] 	= 1111110000100111111000001100
Divisor[WIDTH-1:0] 		= 1001000000000000000000000000

+ D[(WIDTH + 1 + log2(N))-1:0] = 001_001000000000000000000000000000
+2D[(WIDTH + 1 + log2(N))-1:0] = 010_010000000000000000000000000000
- D[(WIDTH + 1 + log2(N))-1:0] = 110_111000000000000000000000000000
-2D[(WIDTH + 1 + log2(N))-1:0] = 101_110000000000000000000000000000
// ---------------------------------------------------------------------------------------------------------------------------------------
// 根据迭代结果计算商和余数
// 最后一次迭代的余数
w[final] = w[28] = 010_000000000000000000000000000000 >= 0;
(w[final] / 2) + (-D) = 001_000000000000000000000000000000 + 110_111000000000000000000000000000 = 
111_111000000000000000000000000000 < 0 -> (w[final] / 2) "belongs to [0, +D)";
// 最后一次迭代的商
q_pos = 1000_0000_0000_0000_0000_0000_0000
q_neg = 0110_0011_1111_1011_1001_0001_1100
// 使用最后一次大迭代计算最终的商
// 第7次大迭代结束时
Q_temp[4:0] = Q_temp_stage_2[4:0] = 1011;
q_temp[2:0] = q[20] = 110;
Q[23:0] = 000111000000010001101111;
q_calculated_pre[WIDTH-1:0] = {Q[23:0], 4'b0} + sign_ext({Q_temp[4:0], 1'b0}) + sign_ext(q_temp[2:0]) = 
0001110000000100011011110000 + 
1111111111111111111111_11011_0 + 
1111111111111111111111111_110 = 
0001110000000100011011100100;

q_calculated_pre[WIDTH-1:0] = q_pos[WIDTH-1:0] - q_neg[WIDTH-1:0] = 0001110000000100011011100100;
(w[final] / 2) "belongs to [0, +D)" -> quotient_correction_coefficient = 0;
q_calculated[WIDTH-1:0] = q_calculated_pre[WIDTH-1:0] + quotient_correction_coefficient = 0001110000000100011011100100;

(w[final] / 2) "belongs to [0, +D)" -> remainder_correction_coefficient = 0;
remainder_calculated[WIDTH-1:0] = (((w[final] / 2) - remainder_correction_coefficient * D)[(log2(N) - 1) +: WIDTH]) >> CLZ_D = 
1000000000000000000000000000 >> 24 = 
0000000000000000000000001000
// 结果正确
// ---------------------------------------------------------------------------------------------------------------------------------------

初始化:
Q[23:0] = 000000000000000000000000;
Q_temp[4:0] = 00000;
q_temp[2:0] = 000;
w[0][(WIDTH + 1 + log2(N))-1:0] =  000_001111110000100111111000001100
w_sum_translation[0] = w_sum[0] =  000_001111110000100111111000001100
w_carry_translation[0] = w_carry[0] = {(WIDTH + 1 + log2(N)){1'b0}} = 000_000000000000000000000000000000
// 第1次大迭代
// 计算上次大迭代得到的商数字的非冗余形式
Q[23:0] <= {Q[0 +: 20], 4'b0} + sign_ext({Q_temp[4:0], 1'b0}) + sign_ext(q_temp[2:0]) = 
000000000000000000000000 + 
000000000000000000_00000_0 + 
000000000000000000000_000 = 
000000000000000000000000;
{w_sum_translation[0][MSB-1:MSB-2], w_carry_translation[0][MSB-1:MSB-2]} = 00_00 -> q[1] = +1 = 00001
q_pos = 1
q_neg = 0
Q_temp_stage_0[4:0] = q[1] = 00001;

w_sum[1] = 2 * csa_sum(w_sum_translation[0], w_carry_translation[0], -q[1] * D) = 
000_011111100001001111110000011000
w_carry[1] = 2 * csa_carry(w_sum_translation[0], w_carry_translation[0], -q[1] * D) = 
101_110000000000000000000000000000
w_sum_translation[1] = 110_011111100001001111110000011000
w_carry_translation[1] = 111_110000000000000000000000000000
{w_sum_translation[1][MSB-1:MSB-2], w_carry_translation[1][MSB-1:MSB-2]} = 10_11 -> q[2] = -1 = 11111
w[1] = 2 * (w[0] - q[1] * D) = 2 * (
	000_001111110000100111111000001100 +
	110_111000000000000000000000000000
) = 2 * 111_000111110000100111111000001100 = 
110_001111100001001111110000011000
q_pos = 10
q_neg = 01
Q_temp_stage_1[4:0] = 2 * Q_temp_stage_0 + q[2] = 00010 + 11111 = 00001

w_sum[2] = 2 * csa_sum(w_sum_translation[1], w_carry_translation[1], -q[2] * D) = 
001_001111000010011111100000110000
w_carry[2] = 2 * csa_carry(w_sum_translation[1], w_carry_translation[1], -q[2] * D) = 
101_100000000000000000000000000000
w_sum_translation[2] = 111_001111000010011111100000110000
w_carry_translation[2] = 111_100000000000000000000000000000
{w_sum_translation[2][MSB-1:MSB-2], w_carry_translation[2][MSB-1:MSB-2]} = 11_11 -> q[3] = -1 = 11111
w[2] = 2 * (w[1] - q[2] * D) = 2 * (
	110_001111100001001111110000011000 +
	001_001000000000000000000000000000
) = 2 * 111_010111100001001111110000011000 = 
110_101111000010011111100000110000
q_pos = 100
q_neg = 011
Q_temp_stage_2[4:0] = 2 * Q_temp_stage_1 + q[3] = 00010 + 11111 = 00001

w_sum[3] = 2 * csa_sum(w_sum_translation[2], w_carry_translation[2], -q[3] * D) = 
011_001110000100111111000001100000
w_carry[3] = 2 * csa_carry(w_sum_translation[2], w_carry_translation[2], -q[3] * D) = 
100_100000000000000000000000000000
w_sum_translation[3] = 001_001110000100111111000001100000
w_carry_translation[3] = 110_100000000000000000000000000000
{w_sum_translation[3][MSB-1:MSB-2], w_carry_translation[3][MSB-1:MSB-2]} = 01_10 -> q[4] = 0 = 000
w[3] = 2 * (w[2] - q[3] * D) = 2 * (
	110_101111000010011111100000110000 +
	001_001000000000000000000000000000
) = 2 * 111_110111000010011111100000110000 = 
111_101110000100111111000001100000
q_pos = 1000
q_neg = 0110
// 第1次大迭代结束时
Q_temp[4:0] = Q_temp_stage_2[4:0] = 00001;
q_temp[2:0] = q[4] = 000;
Q[23:0] = 000000000000000000000000;


// 第2次大迭代
// 计算上次大迭代得到的商数字的非冗余形式
Q[23:0] <= {Q[0 +: 20], 4'b0} + sign_ext({Q_temp[4:0], 1'b0}) + sign_ext(q_temp[2:0]) = 
000000000000000000000000 + 
0000000000000000000_0001_0 + 
000000000000000000000_000 = 
000000000000000000000010;

w_sum[4] = 2 * csa_sum(w_sum_translation[3], w_carry_translation[3], -q[4] * D) = 
010_011100001001111110000011000000
w_carry[4] = 2 * csa_carry(w_sum_translation[3], w_carry_translation[3], -q[4] * D) = 
101_000000000000000000000000000000
w_sum_translation[4] = 000_011100001001111110000011000000
w_carry_translation[4] = 111_000000000000000000000000000000
{w_sum_translation[4][MSB-1:MSB-2], w_carry_translation[4][MSB-1:MSB-2]} = 00_11 -> q[5] = 0 = 0000
w[4] = 2 * (w[3] - q[4] * D) = 2 * (
	111_101110000100111111000001100000 +
	000_000000000000000000000000000000
) = 2 * 111_101110000100111111000001100000 = 
111_011100001001111110000011000000
q_pos = 1000_0
q_neg = 0110_0
Q_temp_stage_0[3:0] = q[5] = 0000;

w_sum[5] = 2 * csa_sum(w_sum_translation[4], w_carry_translation[4], -q[5] * D) = 
000_111000010011111100000110000000
w_carry[5] = 2 * csa_carry(w_sum_translation[4], w_carry_translation[4], -q[5] * D) = 
110_000000000000000000000000000000
w_sum_translation[5] = 000_111000010011111100000110000000
w_carry_translation[5] = 110_000000000000000000000000000000
{w_sum_translation[5][MSB-1:MSB-2], w_carry_translation[5][MSB-1:MSB-2]} = 00_10 -> q[6] = 0 = 0000
w[5] = 2 * (w[4] - q[5] * D) = 2 * (
	111_011100001001111110000011000000 +
	000_000000000000000000000000000000
) = 2 * 111_011100001001111110000011000000 = 
110_111000010011111100000110000000
q_pos = 1000_00
q_neg = 0110_00
Q_temp_stage_1[3:0] = 2 * Q_temp_stage_0 + q[6] = 0000 + 0000 = 0000

w_sum[6] = 2 * csa_sum(w_sum_translation[5], w_carry_translation[5], -q[6] * D) = 
001_110000100111111000001100000000
w_carry[6] = 2 * csa_carry(w_sum_translation[5], w_carry_translation[5], -q[6] * D) = 
100_000000000000000000000000000000
w_sum_translation[6] = 111_110000100111111000001100000000
w_carry_translation[6] = 110_000000000000000000000000000000
{w_sum_translation[6][MSB-1:MSB-2], w_carry_translation[6][MSB-1:MSB-2]} = 11_10 -> q[7] = -1 = 1111
w[6] = 2 * (w[5] - q[6] * D) = 2 * (
	110_111000010011111100000110000000 +
	000_000000000000000000000000000000
) = 2 * 110_111000010011111100000110000000 = 
101_110000100111111000001100000000
q_pos = 1000_000
q_neg = 0110_001
Q_temp_stage_2[3:0] = 2 * Q_temp_stage_1 + q[7] = 0000 + 1111 = 1111

w_sum[7] = 2 * csa_sum(w_sum_translation[6], w_carry_translation[6], -q[7] * D) = 
001_110001001111110000011000000000
w_carry[7] = 2 * csa_carry(w_sum_translation[6], w_carry_translation[6], -q[7] * D) = 
100_000000000000000000000000000000
w_sum_translation[7] = 111_110001001111110000011000000000
w_carry_translation[7] = 110_000000000000000000000000000000
{w_sum_translation[7][MSB-1:MSB-2], w_carry_translation[7][MSB-1:MSB-2]} = 11_10 -> q[8] = -1 = 111
w[7] = 2 * (w[6] - q[7] * D) = 2 * (
	101_110000100111111000001100000000 +
	001_001000000000000000000000000000
) = 2 * 110_111000100111111000001100000000 = 
101_110001001111110000011000000000
q_pos = 1000_0000
q_neg = 0110_0011

// 第2次大迭代结束时
Q_temp[3:0] = Q_temp_stage_2[3:0] = 1111;
q_temp[2:0] = q[8] = 111;
Q[23:0] = 000000000000000000000010;

// 第3次大迭代
// 计算上次大迭代得到的商数字的非冗余形式
Q[23:0] <= {Q[0 +: 20], 4'b0} + sign_ext({Q_temp[3:0], 1'b0}) + sign_ext(q_temp[2:0]) = 
000000000000000000100000 + 
1111111111111111111_1111_0 + 
111111111111111111111_111 = 
000000000000000000011101;

w_sum[8] = 2 * csa_sum(w_sum_translation[7], w_carry_translation[7], -q[8] * D) = 
001_110010011111100000110000000000
w_carry[8] = 2 * csa_carry(w_sum_translation[7], w_carry_translation[7], -q[8] * D) = 
100_000000000000000000000000000000
w_sum_translation[8] = 111_110010011111100000110000000000
w_carry_translation[8] = 110_000000000000000000000000000000
{w_sum_translation[8][MSB-1:MSB-2], w_carry_translation[8][MSB-1:MSB-2]} = 11_10 -> q[9] = -1 = 1111
w[8] = 2 * (w[7] - q[8] * D) = 2 * (
	101_110001001111110000011000000000 +
	001_001000000000000000000000000000
) = 2 * 110_111001001111110000011000000000 = 
101_110010011111100000110000000000
q_pos = 1000_0000_0
q_neg = 0110_0011_1
Q_temp_stage_0[3:0] = q[9] = 1111;

w_sum[9] = 2 * csa_sum(w_sum_translation[8], w_carry_translation[8], -q[9] * D) = 
001_110100111111000001100000000000
w_carry[9] = 2 * csa_carry(w_sum_translation[8], w_carry_translation[8], -q[9] * D) = 
100_000000000000000000000000000000
w_sum_translation[9] = 111_110100111111000001100000000000
w_carry_translation[9] = 110_000000000000000000000000000000
{w_sum_translation[9][MSB-1:MSB-2], w_carry_translation[9][MSB-1:MSB-2]} = 11_10 -> q[10] = -1 = 1111
w[9] = 2 * (w[8] - q[9] * D) = 2 * (
	101_110010011111100000110000000000 +
	001_001000000000000000000000000000
) = 2 * 110_111010011111100000110000000000 = 
101_110100111111000001100000000000
q_pos = 1000_0000_00
q_neg = 0110_0011_11
Q_temp_stage_1[3:0] = 2 * Q_temp_stage_0 + q[10] = 1110 + 1111 = 1101


w_sum[10] = 2 * csa_sum(w_sum_translation[9], w_carry_translation[9], -q[10] * D) = 
001_111001111110000011000000000000
w_carry[10] = 2 * csa_carry(w_sum_translation[9], w_carry_translation[9], -q[10] * D) = 
100_000000000000000000000000000000
w_sum_translation[10] = 111_111001111110000011000000000000
w_carry_translation[10] = 110_000000000000000000000000000000
{w_sum_translation[10][MSB-1:MSB-2], w_carry_translation[10][MSB-1:MSB-2]} = 11_10 -> q[11] = -1 = 1111
w[10] = 2 * (w[9] - q[10] * D) = 2 * (
	101_110100111111000001100000000000 +
	001_001000000000000000000000000000
) = 2 * 110_111100111111000001100000000000 = 
101_111001111110000011000000000000
q_pos = 1000_0000_000
q_neg = 0110_0011_111
Q_temp_stage_2[3:0] = 2 * Q_temp_stage_1 + q[11] = 1010 + 1111 = 1001

w_sum[11] = 2 * csa_sum(w_sum_translation[10], w_carry_translation[10], -q[11] * D) = 
001_100011111100000110000000000000
w_carry[11] = 2 * csa_carry(w_sum_translation[10], w_carry_translation[10], -q[11] * D) = 
100_100000000000000000000000000000
w_sum_translation[11] = 111_100011111100000110000000000000
w_carry_translation[11] = 110_100000000000000000000000000000
{w_sum_translation[11][MSB-1:MSB-2], w_carry_translation[11][MSB-1:MSB-2]} = 11_10 -> q[12] = -1 = 111
w[11] = 2 * (w[10] - q[11] * D) = 2 * (
	101_111001111110000011000000000000 +
	001_001000000000000000000000000000
) = 2 * 111_000001111110000011000000000000 = 
110_000011111100000110000000000000
q_pos = 1000_0000_0000
q_neg = 0110_0011_1111

// 第3次大迭代结束时
Q_temp[3:0] = Q_temp_stage_2[3:0] = 1001;
q_temp[2:0] = q[12] = 111;
Q[23:0] = 000000000000000000011101;


// 第4次大迭代
// 计算上次大迭代得到的商数字的非冗余形式
Q[23:0] <= {Q[0 +: 20], 4'b0} + sign_ext({Q_temp[3:0], 1'b0}) + sign_ext(q_temp[2:0]) = 
000000000000000111010000 + 
1111111111111111111_1001_0 + 
111111111111111111111_111 = 
000000000000000111000001;

w_sum[12] = 2 * csa_sum(w_sum_translation[11], w_carry_translation[11], -q[12] * D) = 
000_010111111000001100000000000000
w_carry[12] = 2 * csa_carry(w_sum_translation[11], w_carry_translation[11], -q[12] * D) = 
110_000000000000000000000000000000
w_sum_translation[12] = 000_010111111000001100000000000000
w_carry_translation[12] = 110_000000000000000000000000000000
{w_sum_translation[12][MSB-1:MSB-2], w_carry_translation[12][MSB-1:MSB-2]} = 00_10 -> q[13] = 0 = 0000
w[12] = 2 * (w[11] - q[12] * D) = 2 * (
	110_000011111100000110000000000000 +
	001_001000000000000000000000000000
) = 2 * 111_001011111100000110000000000000 = 
110_010111111000001100000000000000
q_pos = 1000_0000_0000_0
q_neg = 0110_0011_1111_0
Q_temp_stage_0[3:0] = q[13] = 0000;

w_sum[13] = 2 * csa_sum(w_sum_translation[12], w_carry_translation[12], -q[13] * D) = 
000_101111110000011000000000000000
w_carry[13] = 2 * csa_carry(w_sum_translation[12], w_carry_translation[12], -q[13] * D) = 
100_000000000000000000000000000000
w_sum_translation[13] = 110_101111110000011000000000000000
w_carry_translation[13] = 110_000000000000000000000000000000
{w_sum_translation[13][MSB-1:MSB-2], w_carry_translation[13][MSB-1:MSB-2]} = 10_10 -> q[14] = -2 = 1110
w[13] = 2 * (w[12] - q[13] * D) = 2 * (
	110_010111111000001100000000000000 +
	000_000000000000000000000000000000
) = 2 * 110_010111111000001100000000000000 = 
100_101111110000011000000000000000
q_pos = 1000_0000_0000_00
q_neg = 0110_0011_1111_10
Q_temp_stage_1[3:0] = 2 * Q_temp_stage_0 + q[14] = 0000 + 1110 = 1110

w_sum[14] = 2 * csa_sum(w_sum_translation[13], w_carry_translation[13], -q[14] * D) = 
001_111111100000110000000000000000
w_carry[14] = 2 * csa_carry(w_sum_translation[13], w_carry_translation[13], -q[14] * D) = 
100_000000000000000000000000000000
w_sum_translation[14] = 111_111111100000110000000000000000
w_carry_translation[14] = 110_000000000000000000000000000000
{w_sum_translation[14][MSB-1:MSB-2], w_carry_translation[14][MSB-1:MSB-2]} = 11_10 -> q[15] = -1 = 1111
w[14] = 2 * (w[13] - q[14] * D) = 2 * (
	100_101111110000011000000000000000 +
	010_010000000000000000000000000000
) = 2 * 110_111111110000011000000000000000 = 
101_111111100000110000000000000000
q_pos = 1000_0000_0000_000
q_neg = 0110_0011_1111_101
Q_temp_stage_2[3:0] = 2 * Q_temp_stage_1 + q[15] = 1100 + 1111 = 1011

w_sum[15] = 2 * csa_sum(w_sum_translation[14], w_carry_translation[14], -q[15] * D) = 
001_101111000001100000000000000000
w_carry[15] = 2 * csa_carry(w_sum_translation[14], w_carry_translation[14], -q[15] * D) = 
100_100000000000000000000000000000
w_sum_translation[15] = 111_101111000001100000000000000000
w_carry_translation[15] = 110_100000000000000000000000000000
{w_sum_translation[15][MSB-1:MSB-2], w_carry_translation[15][MSB-1:MSB-2]} = 11_10 -> q[16] = -1 = 111
w[15] = 2 * (w[14] - q[15] * D) = 2 * (
	101_111111100000110000000000000000 +
	001_001000000000000000000000000000
) = 2 * 111_000111100000110000000000000000 = 
110_001111000001100000000000000000
q_pos = 1000_0000_0000_0000
q_neg = 0110_0011_1111_1011

// 第4次大迭代结束时
Q_temp[3:0] = Q_temp_stage_2[3:0] = 1011;
q_temp[2:0] = q[16] = 111;
Q[23:0] = 000000000000000111000001;

// 第5次大迭代
// 计算上次大迭代得到的商数字的非冗余形式
Q[23:0] <= {Q[0 +: 20], 4'b0} + sign_ext({Q_temp[3:0], 1'b0}) + sign_ext(q_temp[2:0]) = 
000000000001110000010000 + 
1111111111111111111_1011_0 + 
111111111111111111111_111 = 
000000000001110000000101;

w_sum[16] = 2 * csa_sum(w_sum_translation[15], w_carry_translation[15], -q[16] * D) = 
000_001110000011000000000000000000
w_carry[16] = 2 * csa_carry(w_sum_translation[15], w_carry_translation[15], -q[16] * D) = 
110_100000000000000000000000000000
w_sum_translation[16] = 000_001110000011000000000000000000
w_carry_translation[16] = 110_100000000000000000000000000000
{w_sum_translation[16][MSB-1:MSB-2], w_carry_translation[16][MSB-1:MSB-2]} = 00_10 -> q[17] = 0 = 0000
w[16] = 2 * (w[15] - q[16] * D) = 2 * (
	110_001111000001100000000000000000 +
	001_001000000000000000000000000000
) = 2 * 111_010111000001100000000000000000 = 
110_101110000011000000000000000000
q_pos = 1000_0000_0000_0000_0
q_neg = 0110_0011_1111_1011_0
Q_temp_stage_0[3:0] = q[17] = 0000;

w_sum[17] = 2 * csa_sum(w_sum_translation[16], w_carry_translation[16], -q[17] * D) = 
000_011100000110000000000000000000
w_carry[17] = 2 * csa_carry(w_sum_translation[16], w_carry_translation[16], -q[17] * D) = 
101_000000000000000000000000000000
w_sum_translation[17] = 110_011100000110000000000000000000
w_carry_translation[17] = 111_000000000000000000000000000000
{w_sum_translation[17][MSB-1:MSB-2], w_carry_translation[17][MSB-1:MSB-2]} = 10_11 -> q[18] = -1 = 1111
w[17] = 2 * (w[16] - q[17] * D) = 2 * (
	110_101110000011000000000000000000 +
	000_000000000000000000000000000000
) = 2 * 110_101110000011000000000000000000 = 
101_011100000110000000000000000000
q_pos = 1000_0000_0000_0000_00
q_neg = 0110_0011_1111_1011_01
Q_temp_stage_1[3:0] = 2 * Q_temp_stage_0 + q[14] = 0000 + 1111 = 1111

w_sum[18] = 2 * csa_sum(w_sum_translation[17], w_carry_translation[17], -q[18] * D) = 
000_101000001100000000000000000000
w_carry[18] = 2 * csa_carry(w_sum_translation[17], w_carry_translation[17], -q[18] * D) = 
100_100000000000000000000000000000
w_sum_translation[18] = 110_101000001100000000000000000000
w_carry_translation[18] = 110_100000000000000000000000000000
{w_sum_translation[18][MSB-1:MSB-2], w_carry_translation[18][MSB-1:MSB-2]} = 10_10 -> q[19] = -2 = 1110
w[18] = 2 * (w[17] - q[18] * D) = 2 * (
	101_011100000110000000000000000000 +
	001_001000000000000000000000000000
) = 2 * 110_100100000110000000000000000000 = 
101_001000001100000000000000000000
q_pos = 1000_0000_0000_0000_000
q_neg = 0110_0011_1111_1011_100
Q_temp_stage_2[3:0] = 2 * Q_temp_stage_1 + q[15] = 1110 + 1110 = 1100

w_sum[19] = 2 * csa_sum(w_sum_translation[18], w_carry_translation[18], -q[19] * D) = 
000_110000011000000000000000000000
w_carry[19] = 2 * csa_carry(w_sum_translation[18], w_carry_translation[18], -q[19] * D) = 
110_000000000000000000000000000000
w_sum_translation[19] = 000_110000011000000000000000000000
w_carry_translation[19] = 110_000000000000000000000000000000
{w_sum_translation[19][MSB-1:MSB-2], w_carry_translation[19][MSB-1:MSB-2]} = 00_10 -> q[20] = 0 = 000
w[19] = 2 * (w[18] - q[19] * D) = 2 * (
	101_001000001100000000000000000000 +
	010_010000000000000000000000000000
) = 2 * 111_011000001100000000000000000000 = 
110_110000011000000000000000000000
q_pos = 1000_0000_0000_0000_0000
q_neg = 0110_0011_1111_1011_1000

// 第5次大迭代结束时
Q_temp[3:0] = Q_temp_stage_2[3:0] = 1100;
q_temp[2:0] = q[20] = 000;
Q[23:0] = 000000000001110000000101;

// 第6次大迭代
// 计算上次大迭代得到的商数字的非冗余形式
Q[23:0] <= {Q[0 +: 20], 4'b0} + sign_ext({Q_temp[3:0], 1'b0}) + sign_ext(q_temp[2:0]) = 
000000011100000001010000 + 
1111111111111111111_1100_0 + 
000000000000000000000_000 = 
000000011100000001001000;

w_sum[20] = 2 * csa_sum(w_sum_translation[19], w_carry_translation[19], -q[20] * D) = 
001_100000110000000000000000000000
w_carry[20] = 2 * csa_carry(w_sum_translation[19], w_carry_translation[19], -q[20] * D) = 
100_000000000000000000000000000000
w_sum_translation[20] = 111_100000110000000000000000000000
w_carry_translation[20] = 110_000000000000000000000000000000
{w_sum_translation[20][MSB-1:MSB-2], w_carry_translation[20][MSB-1:MSB-2]} = 11_10 -> q[21] = -1 = 1111
w[20] = 2 * (w[19] - q[20] * D) = 2 * (
	110_110000011000000000000000000000 +
	000_000000000000000000000000000000
) = 2 * 110_110000011000000000000000000000 = 
101_100000110000000000000000000000
q_pos = 1000_0000_0000_0000_0000_0
q_neg = 0110_0011_1111_1011_1000_1
Q_temp_stage_0[3:0] = q[21] = 1111;

w_sum[21] = 2 * csa_sum(w_sum_translation[20], w_carry_translation[20], -q[21] * D) = 
001_010001100000000000000000000000
w_carry[21] = 2 * csa_carry(w_sum_translation[20], w_carry_translation[20], -q[21] * D) = 
100_000000000000000000000000000000
w_sum_translation[21] = 111_010001100000000000000000000000
w_carry_translation[21] = 110_000000000000000000000000000000
{w_sum_translation[21][MSB-1:MSB-2], w_carry_translation[21][MSB-1:MSB-2]} = 11_10 -> q[22] = -1 = 1111
w[21] = 2 * (w[20] - q[21] * D) = 2 * (
	101_100000110000000000000000000000 +
	001_001000000000000000000000000000
) = 2 * 110_101000110000000000000000000000 = 
101_010001100000000000000000000000
q_pos = 1000_0000_0000_0000_0000_00
q_neg = 0110_0011_1111_1011_1000_11
Q_temp_stage_1[3:0] = 2 * Q_temp_stage_0 + q[14] = 1110 + 1111 = 1101

w_sum[22] = 2 * csa_sum(w_sum_translation[21], w_carry_translation[21], -q[22] * D) = 
000_110011000000000000000000000000
w_carry[22] = 2 * csa_carry(w_sum_translation[21], w_carry_translation[21], -q[22] * D) = 
100_000000000000000000000000000000
w_sum_translation[22] = 110_110011000000000000000000000000
w_carry_translation[22] = 110_000000000000000000000000000000
{w_sum_translation[22][MSB-1:MSB-2], w_carry_translation[22][MSB-1:MSB-2]} = 10_10 -> q[23] = -2 = 1110
w[22] = 2 * (w[21] - q[22] * D) = 2 * (
	101_010001100000000000000000000000 +
	001_001000000000000000000000000000
) = 2 * 110_011001100000000000000000000000 = 
100_110011000000000000000000000000
q_pos = 1000_0000_0000_0000_0000_000
q_neg = 0110_0011_1111_1011_1001_000
Q_temp_stage_2[3:0] = 2 * Q_temp_stage_1 + q[15] = 1010 + 1110 = 1000

w_sum[23] = 2 * csa_sum(w_sum_translation[22], w_carry_translation[22], -q[23] * D) = 
001_000110000000000000000000000000
w_carry[23] = 2 * csa_carry(w_sum_translation[22], w_carry_translation[22], -q[23] * D) = 
101_000000000000000000000000000000
w_sum_translation[23] = 111_000110000000000000000000000000
w_carry_translation[23] = 111_000000000000000000000000000000
{w_sum_translation[23][MSB-1:MSB-2], w_carry_translation[23][MSB-1:MSB-2]} = 11_11 -> q[24] = -1 = 111
w[23] = 2 * (w[22] - q[23] * D) = 2 * (
	100_110011000000000000000000000000 +
	010_010000000000000000000000000000
) = 2 * 111_000011000000000000000000000000 = 
110_000110000000000000000000000000
q_pos = 1000_0000_0000_0000_0000_0000
q_neg = 0110_0011_1111_1011_1001_0001

// 第6次大迭代结束时
Q_temp[3:0] = Q_temp_stage_2[3:0] = 1000;
q_temp[2:0] = q[20] = 111;
Q[23:0] = 000000000001110000000101;

// 第7次大迭代
// 计算上次大迭代得到的商数字的非冗余形式
Q[23:0] <= {Q[0 +: 20], 4'b0} + sign_ext({Q_temp[3:0], 1'b0}) + sign_ext(q_temp[2:0]) = 
000111000000010010000000 + 
1111111111111111111_1000_0 + 
111111111111111111111_111 = 
000111000000010001101111;

w_sum[24] = 2 * csa_sum(w_sum_translation[23], w_carry_translation[23], -q[24] * D) = 
010_011100000000000000000000000000
w_carry[24] = 2 * csa_carry(w_sum_translation[23], w_carry_translation[23], -q[24] * D) = 
100_000000000000000000000000000000
w_sum_translation[24] = 000_011100000000000000000000000000
w_carry_translation[24] = 110_000000000000000000000000000000
{w_sum_translation[24][MSB-1:MSB-2], w_carry_translation[24][MSB-1:MSB-2]} = 00_10 -> q[25] = 0 = 0000
w[24] = 2 * (w[23] - q[24] * D) = 2 * (
	110_000110000000000000000000000000 +
	001_001000000000000000000000000000
) = 2 * 111_001110000000000000000000000000 = 
110_011100000000000000000000000000
q_pos = 1000_0000_0000_0000_0000_0000_0
q_neg = 0110_0011_1111_1011_1001_0001_0
Q_temp_stage_0[3:0] = q[25] = 0000;

w_sum[25] = 2 * csa_sum(w_sum_translation[24], w_carry_translation[24], -q[25] * D) = 
000_111000000000000000000000000000
w_carry[25] = 2 * csa_carry(w_sum_translation[24], w_carry_translation[24], -q[25] * D) = 
100_000000000000000000000000000000
w_sum_translation[25] = 110_111000000000000000000000000000
w_carry_translation[25] = 110_000000000000000000000000000000
{w_sum_translation[25][MSB-1:MSB-2], w_carry_translation[25][MSB-1:MSB-2]} = 10_10 -> q[26] = -2 = 1110
w[25] = 2 * (w[24] - q[25] * D) = 2 * (
	110_011100000000000000000000000000 +
	001_001000000000000000000000000000
) = 2 * 110_011100000000000000000000000000 = 
100_111000000000000000000000000000
q_pos = 1000_0000_0000_0000_0000_0000_00
q_neg = 0110_0011_1111_1011_1001_0001_10
Q_temp_stage_1[3:0] = 2 * Q_temp_stage_0 + q[14] = 0000 + 1110 = 1110

w_sum[26] = 2 * csa_sum(w_sum_translation[25], w_carry_translation[25], -q[26] * D) = 
001_010000000000000000000000000000
w_carry[26] = 2 * csa_carry(w_sum_translation[25], w_carry_translation[25], -q[26] * D) = 
101_000000000000000000000000000000
w_sum_translation[26] = 111_010000000000000000000000000000
w_carry_translation[26] = 111_000000000000000000000000000000
{w_sum_translation[26][MSB-1:MSB-2], w_carry_translation[26][MSB-1:MSB-2]} = 11_11 -> q[27] = -1 = 1111
w[26] = 2 * (w[25] - q[26] * D) = 2 * (
	100_111000000000000000000000000000 +
	010_010000000000000000000000000000
) = 2 * 111_001000000000000000000000000000 = 
110_010000000000000000000000000000
q_pos = 1000_0000_0000_0000_0000_0000_000
q_neg = 0110_0011_1111_1011_1001_0001_101
Q_temp_stage_2[3:0] = 2 * Q_temp_stage_1 + q[15] = 1100 + 1111 = 1011

w_sum[27] = 2 * csa_sum(w_sum_translation[26], w_carry_translation[26], -q[27] * D) = 
010_110000000000000000000000000000
w_carry[27] = 2 * csa_carry(w_sum_translation[26], w_carry_translation[26], -q[27] * D) = 
100_000000000000000000000000000000
w_sum_translation[27] = 110_110000000000000000000000000000
w_carry_translation[27] = 110_000000000000000000000000000000
{w_sum_translation[27][MSB-1:MSB-2], w_carry_translation[27][MSB-1:MSB-2]} = 10_10 -> q[28] = -2 = 110
w[27] = 2 * (w[26] - q[27] * D) = 2 * (
	110_010000000000000000000000000000 +
	001_001000000000000000000000000000
) = 2 * 111_011000000000000000000000000000 = 
110_110000000000000000000000000000
q_pos = 1000_0000_0000_0000_0000_0000_0000
q_neg = 0110_0011_1111_1011_1001_0001_1100

// 第7次大迭代结束时
Q_temp[3:0] = Q_temp_stage_2[3:0] = 1011;
q_temp[2:0] = q[20] = 110;
Q[23:0] = 000111000000010001101111;


w[28] = 2 * (w[27] - q[28] * D) = 2 * (
	110_110000000000000000000000000000 +
	010_010000000000000000000000000000
) = 2 * 001_000000000000000000000000000000 = 
010_000000000000000000000000000000



// ---------------------------------------------------------------------------------------------------------------------------------------
本例来自于"test_6.sv"
X[WIDTH-1:0] = 0111111111100010111011110011 = 134098675
D[WIDTH-1:0] = 0000000011110001000101000011 = 987459
Q[WIDTH-1:0] = X / D = 135 = 0000000000000000000010000111
REM[WIDTH-1:0] = 134098675 - 987459 * 135 = 791710 = 0000000011000001010010011110
// ---------------------------------------------------------------------------------------------------------------------------------------

初始化:
Q[23:0] = 000000000000000000000000;
Q_temp[3:0] = 0000;
q_temp[2:0] = 000;
// 第1次大迭代
// 计算上次大迭代得到的商数字的非冗余形式
Q[23:0] <= {Q[0 +: 20], 4'b0} + sign_ext({Q_temp[3:0], 1'b0}) + sign_ext(q_temp[2:0]) = 
000000000000000000000000 + 
0000000000000000000_0000_0 + 
000000000000000000000_000 = 
000000000000000000000000;
q[1] = +1 = 0001;
Q_temp_stage_0[3:0] = q[1] = 0001;
q[2] = 0 = 0000;
Q_temp_stage_1[3:0] = 2 * Q_temp_stage_0 + q[2] = 0010 + 0000 = 0010;
q[3] = 0 = 0000;
Q_temp_stage_2[3:0] = 2 * Q_temp_stage_1 + q[3] = 0100 + 0000 = 0100;
q[4] = 0 = 000;
// 第1次大迭代结束时
Q_temp[3:0] = Q_temp_stage_2[3:0] = 0100;
q_temp[2:0] = q[4] = 000;
Q[23:0] = 000000000000000000000000;

// 第2次大迭代
// 计算上次大迭代得到的商数字的非冗余形式
Q[23:0] <= {Q[0 +: 20], 4'b0} + sign_ext({Q_temp[3:0], 1'b0}) + sign_ext(q_temp[2:0]) = 
000000000000000000000000 + 
0000000000000000000_0100_0 + 
000000000000000000000_000 = 
000000000000000000001000;
q[5] = 0 = 0000;
Q_temp_stage_0[3:0] = q[5] = 0000;
q[6] = +2 = 0010;
Q_temp_stage_1[3:0] = 2 * Q_temp_stage_0 + q[6] = 0000 + 0010 = 0010;
q[7] = 0 = 0000;
Q_temp_stage_2[3:0] = 2 * Q_temp_stage_1 + q[7] = 0100 + 0000 = 0100;
q[8] = -1 = 111;
// 第2次大迭代结束时
Q_temp[3:0] = Q_temp_stage_2[3:0] = 0100;
q_temp[2:0] = q[8] = 111;
Q[23:0] = 000000000000000000001000;

// 最后计算出商的非冗余形式
Q[23:0] <= {Q[0 +: 20], 4'b0} + sign_ext({Q_temp[3:0], 1'b0}) + sign_ext(q_temp[2:0]) = 
000000000000000010000000 + 
0000000000000000000_0100_0 + 
111111111111111111111_111 = 
000000000000000010000111;
// 结果正确


// ---------------------------------------------------------------------------------------------------------------------------------------
本例来自于"test_6.sv"
X[WIDTH-1:0] = 1111111111100010111011110011 = 268316403
D[WIDTH-1:0] = 0000000000111111000101001111 = 258383
Q[WIDTH-1:0] = X / D = 1038 = 0000000000000000010000001110
REM[WIDTH-1:0] = 268316403 - 258383 * 1038 = 114849 = 0000000000011100000010100001
// ---------------------------------------------------------------------------------------------------------------------------------------

初始化:
Q[23:0] = 000000000000000000000000;
Q_temp[3:0] = 0000;
q_temp[2:0] = 000;
// 第1次大迭代
// 计算上次大迭代得到的商数字的非冗余形式
Q[23:0] <= {Q[0 +: 20], 4'b0} + sign_ext({Q_temp[3:0], 1'b0}) + sign_ext(q_temp[2:0]) = 
000000000000000000000000 + 
0000000000000000000_0000_0 + 
000000000000000000000_000 = 
000000000000000000000000;
q[1] = +1 = 0001;
Q_temp_stage_0[3:0] = q[1] = 0001;
q[2] = -1 = 1111;
Q_temp_stage_1[3:0] = 2 * Q_temp_stage_0 + q[2] = 0010 + 1111 = 0001;
q[3] = 0 = 0000;
Q_temp_stage_2[3:0] = 2 * Q_temp_stage_1 + q[3] = 0010 + 0000 = 0010;
q[4] = 0 = 000;
// 第1次大迭代结束时
Q_temp[3:0] = Q_temp_stage_2[3:0] = 0010;
q_temp[2:0] = q[4] = 000;
Q[23:0] = 000000000000000000000000;

// 第2次大迭代
// 计算上次大迭代得到的商数字的非冗余形式
Q[23:0] <= {Q[0 +: 20], 4'b0} + sign_ext({Q_temp[3:0], 1'b0}) + sign_ext(q_temp[2:0]) = 
000000000000000000000000 + 
0000000000000000000_0010_0 + 
000000000000000000000_000 = 
000000000000000000000100;
q[5] = 0 = 0000;
Q_temp_stage_0[3:0] = q[5] = 0000;
q[6] = 0 = 0000;
Q_temp_stage_1[3:0] = 2 * Q_temp_stage_0 + q[6] = 0000 + 0000 = 0000;
q[7] = 0 = 0000;
Q_temp_stage_2[3:0] = 2 * Q_temp_stage_1 + q[7] = 0000 + 0000 = 0000;
q[8] = +1 = 001;
// 第2次大迭代结束时
Q_temp[3:0] = Q_temp_stage_2[3:0] = 0000;
q_temp[2:0] = q[8] = 001;
Q[23:0] = 000000000000000000000100;

// 第3次大迭代
// 计算上次大迭代得到的商数字的非冗余形式
Q[23:0] <= {Q[0 +: 20], 4'b0} + sign_ext({Q_temp[3:0], 1'b0}) + sign_ext(q_temp[2:0]) = 
000000000000000001000000 + 
0000000000000000000_0000_0 + 
000000000000000000000_001 = 
000000000000000001000001;
q[9] = 0 = 0000;
Q_temp_stage_0[3:0] = q[9] = 0000;
q[10] = 0 = 0000;
Q_temp_stage_1[3:0] = 2 * Q_temp_stage_0 + q[10] = 0000 + 0000 = 0000;
q[11] = -1 = 1111;
Q_temp_stage_2[3:0] = 2 * Q_temp_stage_1 + q[11] = 0000 + 1111 = 1111;
q[12] = 0 = 000;
// 第2次大迭代结束时
Q_temp[3:0] = Q_temp_stage_2[3:0] = 1111;
q_temp[2:0] = q[12] = 000;
Q[23:0] = 000000000000000001000001;

// 最后计算出商的非冗余形式
Q[23:0] <= {Q[0 +: 20], 4'b0} + sign_ext({Q_temp[3:0], 1'b0}) + sign_ext(q_temp[2:0]) = 
000000000000010000010000 + 
1111111111111111111_1111_0 + 
000000000000000000000_000 = 
000000000000010000001110;
// 结果正确


// ---------------------------------------------------------------------------------------------------------------------------------------
本例来自于"test_6.sv"
X[WIDTH-1:0] = 1000001000100010111111111100 = 136458236
D[WIDTH-1:0] = 0000000001100001000101001000 = 397640
Q[WIDTH-1:0] = X / D = 343 = 0000000000000000000101010111
REM[WIDTH-1:0] = 136458236 - 397640 * 343 = 67716 = 0000000000010000100010000100
// ---------------------------------------------------------------------------------------------------------------------------------------

初始化:
Q[23:0] = 000000000000000000000000;
Q_temp[3:0] = 0000;
q_temp[2:0] = 000;
// 第1次大迭代
// 计算上次大迭代得到的商数字的非冗余形式
Q[23:0] <= {Q[0 +: 20], 4'b0} + sign_ext({Q_temp[3:0], 1'b0}) + sign_ext(q_temp[2:0]) = 
000000000000000000000000 + 
0000000000000000000_0000_0 + 
000000000000000000000_000 = 
000000000000000000000000;
q[1] = +1 = 0001;
Q_temp_stage_0[3:0] = q[1] = 0001;
q[2] = -2 = 1110;
Q_temp_stage_1[3:0] = 2 * Q_temp_stage_0 + q[2] = 0010 + 1110 = 0000;
q[3] = +1 = 0001;
Q_temp_stage_2[3:0] = 2 * Q_temp_stage_1 + q[3] = 0000 + 0001 = 0001;
q[4] = -1 = 111;
// 第1次大迭代结束时
Q_temp[3:0] = Q_temp_stage_2[3:0] = 0001;
q_temp[2:0] = q[4] = 111;
Q[23:0] = 000000000000000000000000;

// 第2次大迭代
// 计算上次大迭代得到的商数字的非冗余形式
Q[23:0] <= {Q[0 +: 20], 4'b0} + sign_ext({Q_temp[3:0], 1'b0}) + sign_ext(q_temp[2:0]) = 
000000000000000000000000 + 
0000000000000000000_0001_0 + 
111111111111111111111_111 = 
000000000000000000000001;
q[5] = +1 = 0001;
Q_temp_stage_0[3:0] = q[5] = 0001;
q[6] = -1 = 1111;
Q_temp_stage_1[3:0] = 2 * Q_temp_stage_0 + q[6] = 0010 + 1111 = 0001;
q[7] = +1 = 0001;
Q_temp_stage_2[3:0] = 2 * Q_temp_stage_1 + q[7] = 0010 + 0001 = 0011;
q[8] = -1 = 111;
// 第2次大迭代结束时
Q_temp[3:0] = Q_temp_stage_2[3:0] = 0011;
q_temp[2:0] = q[8] = 111;
Q[23:0] = 000000000000000000000001;

// 第3次大迭代
// 计算上次大迭代得到的商数字的非冗余形式
Q[23:0] <= {Q[0 +: 20], 4'b0} + sign_ext({Q_temp[3:0], 1'b0}) + sign_ext(q_temp[2:0]) = 
000000000000000000010000 + 
0000000000000000000_0011_0 + 
111111111111111111111_111 = 
000000000000000000010101;
q[9] = +1 = 0001;
Q_temp_stage_0[3:0] = q[9] = 0001;
q[10] = 0 = 0000;
Q_temp_stage_1[3:0] = 2 * Q_temp_stage_0 + q[10] = 0010 + 0000 = 0010;
q[11] = -1 = 1111;
Q_temp_stage_2[3:0] = 2 * Q_temp_stage_1 + q[11] = 0100 + 1111 = 0011;
q[12] = +1 = 001;
// 第2次大迭代结束时
Q_temp[3:0] = Q_temp_stage_2[3:0] = 0011;
q_temp[2:0] = q[12] = 001;
Q[23:0] = 000000000000000000010101;

// 最后计算出商的非冗余形式
Q[23:0] <= {Q[0 +: 20], 4'b0} + sign_ext({Q_temp[3:0], 1'b0}) + sign_ext(q_temp[2:0]) = 
000000000000000101010000 + 
0000000000000000000_0011_0 + 
000000000000000000000_001 = 
000101010111;
// 结果正确
