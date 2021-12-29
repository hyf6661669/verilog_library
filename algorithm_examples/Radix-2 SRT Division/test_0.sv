参考论文:
"Radix-2 Division Algorithms with an Over-Redundant Digit Set", Jo Ebergen, Navaneeth Jamadagni.

function automatic logic [34:0] csa_sum (
	input logic [34:0] pp0,
	input logic [34:0] pp1,
	input logic [34:0] pp2
);
csa_sum = pp0 ^ pp1 ^ pp2;
endfunction

function automatic logic [34:0] csa_carry (
	input logic [34:0] pp0,
	input logic [34:0] pp1,
	input logic [34:0] pp2
);
csa_carry = {(pp0[33:0] & pp1[33:0]) | (pp1[33:0] & pp2[33:0]) | (pp2[33:0] & pp0[33:0]), 1'b0};
endfunction


选择函数来自于参考论文的"Fig. 6 (c)":
case(w_sum[i][MSB-1:MSB-2], w_carry[i][MSB-1:MSB-2])
	4'b00_00:	q[i+1] = +1;
	4'b00_01:	q[i+1] = +1;
	4'b00_10:	q[i+1] = +0;
	4'b00_11:	q[i+1] = +0;
	4'b01_00:	q[i+1] = +1;
	4'b01_01:	q[i+1] = +2;
	4'b01_10:	q[i+1] = +0;
	4'b01_11:	q[i+1] = +0;
	4'b10_00:	q[i+1] = -0;
	4'b10_01:	q[i+1] = -0;
	4'b10_10:	q[i+1] = -2;
	4'b10_11:	q[i+1] = -1;
	4'b11_00:	q[i+1] = -0;
	4'b11_01:	q[i+1] = -0;
	4'b11_10:	q[i+1] = -1;
	4'b11_11:	q[i+1] = -1;
endcase


先考察WIDTH = 33的情况.
设小数点在"X[WIDTH-1]和X[WIDTH-2]"之间, 即"D[WIDTH-1]和D[WIDTH-2]"之间
X[WIDTH-1:0] = Dividend[WIDTH-1:0] = 1_10010000101010100001111101111001
D[WIDTH-1:0] = Divisor[WIDTH-1:0]  = 1_11111111001000000101101000110000

D参加运算时，可能需要做乘2操作，所以需要在D前面增加2-bit, 1-bit作为符号扩展位, 1-bit用来记录乘2时的左移1位操作时向高位产生的进位.
于是可得:
+ D[(WIDTH + 2)-1:0] = 001_11111111001000000101101000110000
+2D[(WIDTH + 2)-1:0] = 011_11111110010000001011010001100000
- D[(WIDTH + 2)-1:0] = 110_00000000110111111010010111010000
-2D[(WIDTH + 2)-1:0] = 100_00000001101111110100101110100000

Q[WIDTH-1:0] = X / D = 6722035577 / 8575277616 = 0.78388547613407085291966132423345 = 
0_11001000101011001011011111110011_11001110
将Q规格化到区间"[1, 2)", 则可得:
Q_no_rup[WIDTH-1:0] 	= 1_10010001010110010110111111100111
Q_rup[WIDTH-1:0] 		= 1_10010001010110010110111111101000

为了和"+2D, +D, -D, -2D"的宽度保持一致, w_sum[i]/w_carry[i]的宽度也是"WIDTH + 2".
但是这两个变量的绝对值必须要小于2, 因此在每次迭代计算中做"Doubling And Translation"操作:
w_sum[i+1][(WIDTH + 2)-1:0] = 2 * csa_sum(w_sum_translation[i][(WIDTH + 2)-1:0], w_carry_translation[i][(WIDTH + 2)-1:0], -q[i+1] * D);
w_carry[i+1][(WIDTH + 2)-1:0] = 2 * csa_carry(w_sum_translation[i][(WIDTH + 2)-1:0], w_carry_translation[i][(WIDTH + 2)-1:0], -q[i+1] * D);
w_sum_translation[i+1][(WIDTH + 2)-1:0] = {~w_sum[i+1][WIDTH], ~w_sum[i+1][WIDTH], w_sum[i+1][WIDTH-1:0]};
w_carry_translation[i+1][(WIDTH + 2)-1:0] = {~w_carry[i+1][WIDTH], ~w_carry[i+1][WIDTH], w_carry[i+1][WIDTH-1:0]};
论文证明了"Doubling And Translation"操作有如下性质:
w_sum_translation[i+1][(WIDTH + 2)-1:0] + w_carry_translation[i+1][(WIDTH + 2)-1:0] == 
w_sum[i+1][(WIDTH + 2)-1:0] + w_carry[i+1][(WIDTH + 2)-1:0] == 
w[i+1][(WIDTH + 2)-1:0]


w[0][(WIDTH + 2)-1:0] = {2'b0, X[WIDTH-1:0]} = 001_10010000101010100001111101111001
w_sum_translation[0] = w_sum[0] = {2'b0, X[WIDTH-1:0]} = 001_10010000101010100001111101111001
w_carry_translation[0] = w_carry[0] = {(WIDTH + 2){1'b0}} = 000_00000000000000000000000000000000
{w_sum_translation[0][MSB-1:MSB-2], w_carry_translation[0][MSB-1:MSB-2]} = 01_00 -> q[1] = +1
q_pos_sum = 1
q_pos_carry = 0
q_neg_sum = 0
q_neg_carry = 0


w_sum[1] = csa_sum(w_sum_translation[0], w_carry_translation[0], -q[1] * D) * 2 = 
111_00100000111010110111010101010010
w_carry[1] = csa_carry(w_sum_translation[0], w_carry_translation[0], -q[1] * D) * 2 = 
000_00000010001010000001010101000000
w_sum_translation[1] = 001_00100000111010110111010101010010
w_carry_translation[1] = 110_00000010001010000001010101000000
{w_sum_translation[1][MSB-1:MSB-2], w_carry_translation[1][MSB-1:MSB-2]} = 01_10 -> q[2] = 0
q_pos_sum = 10
q_pos_carry = 00
q_neg_sum = 00
q_neg_carry = 00
w[1] = 2(w[0] - q[1] * D) = 2 * (
	001_10010000101010100001111101111001 +
	110_00000000110111111010010111010000
) = 2 * 111_10010001100010011100010101001001 = 
111_00100011000100111000101010010010


w_sum[2] = csa_sum(w_sum_translation[1], w_carry_translation[1], -q[2] * D) * 2 = 
010_01000001110101101110101010100100
w_carry[2] = csa_carry(w_sum_translation[1], w_carry_translation[1], -q[2] * D) * 2 = 
100_00000100010100000010101010000000
w_sum_translation[2] = 000_01000001110101101110101010100100
w_carry_translation[2] = 110_00000100010100000010101010000000
{w_sum_translation[2][MSB-1:MSB-2], w_carry_translation[2][MSB-1:MSB-2]} = 00_10 -> q[3] = 0
q_pos_sum = 100
q_pos_carry = 000
q_neg_sum = 000
q_neg_carry = 000
w[2] = 2(w[1] - q[2] * D) = 2 * (
	111_00100011000100111000101010010010 + 
	000_00000000000000000000000000000000
) = 2 * 111_00100011000100111000101010010010 = 
110_01000110001001110001010100100100


w_sum[3] = csa_sum(w_sum_translation[2], w_carry_translation[2], -q[3] * D) * 2 = 
000_10000011101011011101010101001000
w_carry[3] = csa_carry(w_sum_translation[2], w_carry_translation[2], -q[3] * D) * 2 = 
100_00001000101000000101010100000000
w_sum_translation[3] = 110_10000011101011011101010101001000
w_carry_translation[3] = 110_00001000101000000101010100000000
{w_sum_translation[3][MSB-1:MSB-2], w_carry_translation[3][MSB-1:MSB-2]} = 10_10 -> q[4] = -2
q_pos_sum = 1000
q_pos_carry = 0000
q_neg_sum = 0000
q_neg_carry = 0001
w[3] = 2(w[2] - q[3] * D) = 2 * 110_01000110001001110001010100100100 = 
100_10001100010011100010101001001000


w_sum[4] = csa_sum(w_sum_translation[3], w_carry_translation[3], -q[4] * D) * 2 = 
010_11101010100110100110100001010000
w_carry[4] = csa_carry(w_sum_translation[3], w_carry_translation[3], -q[4] * D) * 2 = 
110_00101010100000110101010100000000
w_sum_translation[4] = 000_11101010100110100110100001010000
w_carry_translation[4] = 000_00101010100000110101010100000000
{w_sum_translation[4][MSB-1:MSB-2], w_carry_translation[4][MSB-1:MSB-2]} = 00_00 -> q[5] = +1
q_pos_sum = 1000_1
q_pos_carry = 0000_0
q_neg_sum = 0000_0
q_neg_carry = 0001_0
w[4] = 2(w[3] - q[4] * D) = 2 * (
	100_10001100010011100010101001001000 + 
	011_11111110010000001011010001100000
) = 2 * 000_10001010100011101101111010101000 = 
001_00010101000111011011110101010000


w_sum[5] = csa_sum(w_sum_translation[4], w_carry_translation[4], -q[5] * D) * 2 = 
101_10000001100011010011000100000000
w_carry[5] = csa_carry(w_sum_translation[4], w_carry_translation[4], -q[5] * D) * 2 =
000_10101010011011011001010101000000
w_sum_translation[5] = 111_10000001100011010011000100000000
w_carry_translation[5] = 110_10101010011011011001010101000000
{w_sum_translation[5][MSB-1:MSB-2], w_carry_translation[5][MSB-1:MSB-2]} = 11_10 -> q[6] = -1
q_pos_sum = 1000_10
q_pos_carry = 0000_00
q_neg_sum = 0000_01
q_neg_carry = 0001_00
w[5] = 2(w[4] - q[5] * D) = 2 * (
	001_00010101000111011011110101010000 + 
	110_00000000110111111010010111010000
) = 2 * 111_00010101111111010110001100100000 = 
110_00101011111110101100011001000000


w_sum[6] = csa_sum(w_sum_translation[5], w_carry_translation[5], -q[6] * D) * 2 = 
001_10101001100000011111110011100000
w_carry[6] = csa_carry(w_sum_translation[5], w_carry_translation[5], -q[6] * D) * 2 =
110_10101100101101000100010000000000
// {w_sum[6], w_carry[6]}属于平面Q3, 实际上不需要变换，但是{w_sum_translation[6], w_carry_translation[6]}属于平面Q1, 所以实际上未引起错误
w_sum_translation[6] = 111_10101001100000011111110011100000
w_carry_translation[6] = 000_10101100101101000100010000000000
{w_sum_translation[6][MSB-1:MSB-2], w_carry_translation[6][MSB-1:MSB-2]} = 11_00 -> q[7] = 0
q_pos_sum = 1000_100
q_pos_carry = 0000_000
q_neg_sum = 0000_010
q_neg_carry = 0001_000
w[6] = 2(w[5] - q[6] * D) = 2 * (
	110_00101011111110101100011001000000 + 
	001_11111111001000000101101000110000
) = 2 * 000_00101011000110110010000001110000 = 
000_01010110001101100100000011100000


w_sum[7] = csa_sum(w_sum_translation[6], w_carry_translation[6], -q[7] * D) * 2 = 
011_01010011000000111111100111000000
w_carry[7] = csa_carry(w_sum_translation[6], w_carry_translation[6], -q[7] * D) * 2 =
101_01011001011010001000100000000000
w_sum_translation[7] = 001_01010011000000111111100111000000
w_carry_translation[7] = 111_01011001011010001000100000000000
{w_sum_translation[7][MSB-1:MSB-2], w_carry_translation[7][MSB-1:MSB-2]} = 01_11 -> q[8] = 0
q_pos_sum = 1000_1000
q_pos_carry = 0000_0000
q_neg_sum = 0000_0100
q_neg_carry = 0001_0000
w[7] = 2(w[6] - q[7] * D) = 2 * 000_01010110001101100100000011100000 = 
000_10101100011011001000000111000000


w_sum[8] = csa_sum(w_sum_translation[7], w_carry_translation[7], -q[8] * D) * 2 = 
010_10100110000001111111001110000000
w_carry[8] = csa_carry(w_sum_translation[7], w_carry_translation[7], -q[8] * D) * 2 =
110_10110010110100010001000000000000
w_sum_translation[8] = 000_10100110000001111111001110000000
w_carry_translation[8] = 000_10110010110100010001000000000000
{w_sum_translation[8][MSB-1:MSB-2], w_carry_translation[8][MSB-1:MSB-2]} = 00_00 -> q[9] = +1
q_pos_sum = 1000_1000_1
q_pos_carry = 0000_0000_0
q_neg_sum = 0000_0100_0
q_neg_carry = 0001_0000_0
w[8] = 2(w[7] - q[8] * D) = 2 * 000_10101100011011001000000111000000 = 
001_01011000110110010000001110000000

w_sum[9] = csa_sum(w_sum_translation[8], w_carry_translation[8], -q[9] * D) * 2 = 
100_00101000000100101000110010100000
w_carry[9] = csa_carry(w_sum_translation[8], w_carry_translation[8], -q[9] * D) * 2 =
010_10001011010111101100011000000000
w_sum_translation[9] = 110_00101000000100101000110010100000
w_carry_translation[9] = 000_10001011010111101100011000000000
{w_sum_translation[9][MSB-1:MSB-2], w_carry_translation[9][MSB-1:MSB-2]} = 10_00 -> q[10] = 0
q_pos_sum = 1000_1000_10
q_pos_carry = 0000_0000_00
q_neg_sum = 0000_0100_00
q_neg_carry = 0001_0000_00
w[9] = 2(w[8] - q[9] * D) = 2 * (
	001_01011000110110010000001110000000 + 
	110_00000000110111111010010111010000
) = 2 * 111_01011001101110001010100101010000 = 
110_10110011011100010101001010100000

w_sum[10] = csa_sum(w_sum_translation[9], w_carry_translation[9], -q[10] * D) * 2 = 
100_01010000001001010001100101000000
w_carry[10] = csa_carry(w_sum_translation[9], w_carry_translation[9], -q[10] * D) * 2 =
001_00010110101111011000110000000000
w_sum_translation[10] = 110_01010000001001010001100101000000
w_carry_translation[10] = 111_00010110101111011000110000000000
{w_sum_translation[10][MSB-1:MSB-2], w_carry_translation[10][MSB-1:MSB-2]} = 10_11 -> q[11] = -1
q_pos_sum = 1000_1000_100
q_pos_carry = 0000_0000_000
q_neg_sum = 0000_0100_001
q_neg_carry = 0001_0000_000
w[10] = 2(w[9] - q[10] * D) = 2 * 110_10110011011100010101001010100000 = 
101_01100110111000101010010101000000

w_sum[11] = csa_sum(w_sum_translation[10], w_carry_translation[10], -q[11] * D) * 2 = 
001_01110011011100011001111011100000
w_carry[11] = csa_carry(w_sum_translation[10], w_carry_translation[10], -q[11] * D) * 2 =
101_01011000100101000110000000000000
w_sum_translation[11] = 111_01110011011100011001111011100000
w_carry_translation[11] = 111_01011000100101000110000000000000
{w_sum_translation[11][MSB-1:MSB-2], w_carry_translation[11][MSB-1:MSB-2]} = 11_11 -> q[12] = -1
q_pos_sum = 1000_1000_1000
q_pos_carry = 0000_0000_0000
q_neg_sum = 0000_0100_0011
q_neg_carry = 0001_0000_0000
w[11] = 2(w[10] - q[11] * D) = 2 * (
	101_01100110111000101010010101000000 + 
	001_11111111001000000101101000110000
) = 2 * 111_01100110000000101111111101110000 = 
110_11001100000001011111111011100000


w_sum[12] = csa_sum(w_sum_translation[11], w_carry_translation[11], -q[12] * D) * 2 = 
011_10101001100010110100100110100000
w_carry[12] = csa_carry(w_sum_translation[11], w_carry_translation[11], -q[12] * D) * 2 =
101_11101100110000010110100010000000
w_sum_translation[12] = 001_10101001100010110100100110100000
w_carry_translation[12] = 111_11101100110000010110100010000000
{w_sum_translation[12][MSB-1:MSB-2], w_carry_translation[12][MSB-1:MSB-2]} = 01_11 -> q[13] = 0
q_pos_sum = 1000_1000_1000_0
q_pos_carry = 0000_0000_0000_0
q_neg_sum = 0000_0100_0011_0
q_neg_carry = 0001_0000_0000_0
w[12] = 2(w[11] - q[12] * D) = 2 * (
	110_11001100000001011111111011100000 + 
	001_11111111001000000101101000110000
) = 2 * 000_11001011001001100101100100010000 = 
001_10010110010011001011001000100000


w_sum[13] = csa_sum(w_sum_translation[12], w_carry_translation[12], -q[13] * D) * 2 = 
011_01010011000101101001001101000000
w_carry[13] = csa_carry(w_sum_translation[12], w_carry_translation[12], -q[13] * D) * 2 =
111_11011001100000101101000100000000
w_sum_translation[13] = 001_01010011000101101001001101000000
w_carry_translation[13] = 001_11011001100000101101000100000000
{w_sum_translation[13][MSB-1:MSB-2], w_carry_translation[13][MSB-1:MSB-2]} = 01_01 -> q[14] = +2
q_pos_sum = 1000_1000_1000_00
q_pos_carry = 0000_0000_0000_01
q_neg_sum = 0000_0100_0011_00
q_neg_carry = 0001_0000_0000_00
w[13] = 2(w[12] - q[13] * D) = 2 * 001_10010110010011001011001000100000 = 
011_00101100100110010110010001000000


w_sum[14] = csa_sum(w_sum_translation[13], w_carry_translation[13], -q[14] * D) * 2 = 
101_00010110010101100001001111000000
w_carry[14] = csa_carry(w_sum_translation[13], w_carry_translation[13], -q[14] * D) * 2 =
001_01000110010110110100110000000000
w_sum_translation[14] = 111_00010110010101100001001111000000
w_carry_translation[14] = 111_01000110010110110100110000000000
{w_sum_translation[14][MSB-1:MSB-2], w_carry_translation[14][MSB-1:MSB-2]} = 11_11 -> q[15] = -1
q_pos_sum = 1000_1000_1000_000
q_pos_carry = 0000_0000_0000_010
q_neg_sum = 0000_0100_0011_001
q_neg_carry = 0001_0000_0000_000
w[14] = 2(w[13] - q[14] * D) = 2 * (
	011_00101100100110010110010001000000 + 
	100_00000001101111110100101110100000
) = 2 * 111_00101110010110001010111111100000 = 
110_01011100101100010101111111000000


w_sum[15] = csa_sum(w_sum_translation[14], w_carry_translation[14], -q[15] * D) * 2 = 
011_01011110010110100000101111100000
w_carry[15] = csa_carry(w_sum_translation[14], w_carry_translation[14], -q[15] * D) * 2 =
101_01011001010010010110100000000000
w_sum_translation[15] = 001_01011110010110100000101111100000
w_carry_translation[15] = 111_01011001010010010110100000000000
{w_sum_translation[15][MSB-1:MSB-2], w_carry_translation[15][MSB-1:MSB-2]} = 01_11 -> q[16] = 0
q_pos_sum = 1000_1000_1000_0000
q_pos_carry = 0000_0000_0000_0100
q_neg_sum = 0000_0100_0011_0010
q_neg_carry = 0001_0000_0000_0000
w[15] = 2(w[14] - q[15] * D) = 2 * (
	110_01011100101100010101111111000000 + 
	001_11111111001000000101101000110000
) = 2 * 000_01011011110100011011100111110000 = 
000_10110111101000110111001111100000


w_sum[16] = csa_sum(w_sum_translation[15], w_carry_translation[15], -q[16] * D) * 2 = 
010_10111100101101000001011111000000
w_carry[16] = csa_carry(w_sum_translation[15], w_carry_translation[15], -q[16] * D) * 2 =
110_10110010100100101101000000000000
w_sum_translation[16] = 000_10111100101101000001011111000000
w_carry_translation[16] = 000_10110010100100101101000000000000
{w_sum_translation[16][MSB-1:MSB-2], w_carry_translation[16][MSB-1:MSB-2]} = 00_00 -> q[17] = +1
q_pos_sum = 1000_1000_1000_0000_1
q_pos_carry = 0000_0000_0000_0100_0
q_neg_sum = 0000_0100_0011_0010_0
q_neg_carry = 0001_0000_0000_0000_0
w[16] = 2(w[15] - q[16] * D) = 2 * 000_10110111101000110111001111100000 = 
001_01101111010001101110011111000000

w_sum[17] = csa_sum(w_sum_translation[16], w_carry_translation[16], -q[17] * D) * 2 = 
100_00011101111100101100010000100000
w_carry[17] = csa_carry(w_sum_translation[16], w_carry_translation[16], -q[17] * D) * 2 =
010_11000010010110100101011100000000
w_sum_translation[17] = 110_00011101111100101100010000100000
w_carry_translation[17] = 000_11000010010110100101011100000000
{w_sum_translation[17][MSB-1:MSB-2], w_carry_translation[17][MSB-1:MSB-2]} = 10_00 -> q[18] = 0
q_pos_sum = 1000_1000_1000_0000_10
q_pos_carry = 0000_0000_0000_0100_00
q_neg_sum = 0000_0100_0011_0010_00
q_neg_carry = 0001_0000_0000_0000_00
w[17] = 2(w[16] - q[17] * D) = 2 * (
	001_01101111010001101110011111000000 + 
	110_00000000110111111010010111010000
) = 2 * 111_01110000001001101000110110010000 = 
110_11100000010011010001101100100000


w_sum[18] = csa_sum(w_sum_translation[17], w_carry_translation[17], -q[18] * D) * 2 = 
100_00111011111001011000100001000000
w_carry[18] = csa_carry(w_sum_translation[17], w_carry_translation[17], -q[18] * D) * 2 =
001_10000100101101001010111000000000
w_sum_translation[18] = 110_00111011111001011000100001000000
w_carry_translation[18] = 111_10000100101101001010111000000000
{w_sum_translation[18][MSB-1:MSB-2], w_carry_translation[18][MSB-1:MSB-2]} = 10_11 -> q[19] = -1
q_pos_sum = 1000_1000_1000_0000_100
q_pos_carry = 0000_0000_0000_0100_000
q_neg_sum = 0000_0100_0011_0010_001
q_neg_carry = 0001_0000_0000_0000_000
w[18] = 2(w[17] - q[18] * D) = 2 * 110_11100000010011010001101100100000 = 
101_11000000100110100011011001000000


w_sum[19] = csa_sum(w_sum_translation[18], w_carry_translation[18], -q[19] * D) * 2 = 
000_10000000111000101111100011100000
w_carry[19] = csa_carry(w_sum_translation[18], w_carry_translation[18], -q[19] * D) * 2 =
110_11111110100100100010100000000000
// {w_sum[19], w_carry[19]}属于平面Q3, 实际不需要变换. 变换操作得到的{w_sum_translation[19], w_carry_translation[19]}属于平面Q1, 所以未引起问题。
w_sum_translation[19] = 110_10000000111000101111100011100000
w_carry_translation[19] = 000_11111110100100100010100000000000
{w_sum_translation[19][MSB-1:MSB-2], w_carry_translation[19][MSB-1:MSB-2]} = 10_00 -> q[20] = 0
q_pos_sum = 1000_1000_1000_0000_1000
q_pos_carry = 0000_0000_0000_0100_0000
q_neg_sum = 0000_0100_0011_0010_0010
q_neg_carry = 0001_0000_0000_0000_0000
w[19] = 2(w[18] - q[19] * D) = 2 * (
	101_11000000100110100011011001000000 +
	001_11111111001000000101101000110000
) = 2 * 111_10111111101110101001000001110000 = 
111_01111111011101010010000011100000


w_sum[20] = csa_sum(w_sum_translation[19], w_carry_translation[19], -q[20] * D) * 2 = 
101_00000001110001011111000111000000
w_carry[20] = csa_carry(w_sum_translation[19], w_carry_translation[19], -q[20] * D) * 2 =
001_11111101001001000101000000000000
w_sum_translation[20] = 111_00000001110001011111000111000000
w_carry_translation[20] = 111_11111101001001000101000000000000
{w_sum_translation[20][MSB-1:MSB-2], w_carry_translation[20][MSB-1:MSB-2]} = 11_11 -> q[21] = 0
q_pos_sum = 1000_1000_1000_0000_1000_0
q_pos_carry = 0000_0000_0000_0100_0000_0
q_neg_sum = 0000_0100_0011_0010_0010_0
q_neg_carry = 0001_0000_0000_0000_0000_0
w[20] = 2(w[19] - q[20] * D) = 2 * 111_01111111011101010010000011100000 = 
110_11111110111010100100000111000000

// *********************************************************************************************************************
// 从这里开始, 只有w_sum[i]/w_carry[i]不在区间[-2, 2)上时, 才有:
w_sum_translation[i+1][(WIDTH + 2)-1:0] = {~w_sum[i+1][WIDTH], ~w_sum[i+1][WIDTH], w_sum[i+1][WIDTH-1:0]};
w_carry_translation[i+1][(WIDTH + 2)-1:0] = {~w_carry[i+1][WIDTH], ~w_carry[i+1][WIDTH], w_carry[i+1][WIDTH-1:0]};
// 否则:
w_sum_translation[i+1][(WIDTH + 2)-1:0] = w_sum[i+1][(WIDTH + 2)-1:0];
w_carry_translation[i+1][(WIDTH + 2)-1:0] = w_carry[i+1][(WIDTH + 2)-1:0];
// 其实这里之前的做法有误，我没有检测w_sum[i]/w_carry[i]本身是否在区间[-2, 2)上而无脑对它们的高2位做了变换, 不过还好没引发错误。
// *********************************************************************************************************************

w_sum[21] = csa_sum(w_sum_translation[20], w_carry_translation[20], -q[21] * D) * 2 = 
110_00000011100010111110001110000000
w_carry[21] = csa_carry(w_sum_translation[20], w_carry_translation[20], -q[21] * D) * 2 =
111_11111010010010001010000000000000
w_sum_translation[21] = 110_00000011100010111110001110000000
w_carry_translation[21] = 111_11111010010010001010000000000000
{w_sum_translation[21][MSB-1:MSB-2], w_carry_translation[21][MSB-1:MSB-2]} = 10_11 -> q[22] = -1
q_pos_sum = 1000_1000_1000_0000_1000_00
q_pos_carry = 0000_0000_0000_0100_0000_00
q_neg_sum = 0000_0100_0011_0010_0010_01
q_neg_carry = 0001_0000_0000_0000_0000_00
w[21] = 2(w[20] - q[21] * D) = 2 * 110_11111110111010100100000111000000 = 
101_11111101110101001000001110000000


w_sum[22] = csa_sum(w_sum_translation[21], w_carry_translation[21], -q[22] * D) * 2 = 
000_00001101110001100011001101100000
w_carry[22] = csa_carry(w_sum_translation[21], w_carry_translation[21], -q[22] * D) * 2 =
111_11101100001000111000100000000000
w_sum_translation[22] = 000_00001101110001100011001101100000
w_carry_translation[22] = 111_11101100001000111000100000000000
{w_sum_translation[22][MSB-1:MSB-2], w_carry_translation[22][MSB-1:MSB-2]} = 00_11 -> q[23] = 0
q_pos_sum = 1000_1000_1000_0000_1000_000
q_pos_carry = 0000_0000_0000_0100_0000_000
q_neg_sum = 0000_0100_0011_0010_0010_010
q_neg_carry = 0001_0000_0000_0000_0000_000
w[22] = 2(w[21] - q[22] * D) = 2 * (
	101_11111101110101001000001110000000 + 
	001_11111111001000000101101000110000
) = 2 * 111_11111100111101001101110110110000 = 
111_11111001111010011011101101100000


w_sum[23] = csa_sum(w_sum_translation[22], w_carry_translation[22], -q[23] * D) * 2 = 
000_00011011100011000110011011000000
w_carry[23] = csa_carry(w_sum_translation[22], w_carry_translation[22], -q[23] * D) * 2 =
111_11011000010001110001000000000000
w_sum_translation[23] = 000_00011011100011000110011011000000
w_carry_translation[23] = 111_11011000010001110001000000000000
{w_sum_translation[23][MSB-1:MSB-2], w_carry_translation[23][MSB-1:MSB-2]} = 00_11 -> q[24] = 0
q_pos_sum = 1000_1000_1000_0000_1000_0000
q_pos_carry = 0000_0000_0000_0100_0000_0000
q_neg_sum = 0000_0100_0011_0010_0010_0100
q_neg_carry = 0001_0000_0000_0000_0000_0000
w[23] = 2(w[22] - q[23] * D) = 2 * 111_11111001111010011011101101100000 = 
111_11110011110100110111011011000000


w_sum[24] = csa_sum(w_sum_translation[23], w_carry_translation[23], -q[24] * D) * 2 = 
000_00110111000110001100110110000000
w_carry[24] = csa_carry(w_sum_translation[23], w_carry_translation[23], -q[24] * D) * 2 =
111_10110000100011100010000000000000
w_sum_translation[24] = 000_00110111000110001100110110000000
w_carry_translation[24] = 111_10110000100011100010000000000000
{w_sum_translation[24][MSB-1:MSB-2], w_carry_translation[24][MSB-1:MSB-2]} = 00_11 -> q[25] = 0
q_pos_sum = 1000_1000_1000_0000_1000_0000_0
q_pos_carry = 0000_0000_0000_0100_0000_0000_0
q_neg_sum = 0000_0100_0011_0010_0010_0100_0
q_neg_carry = 0001_0000_0000_0000_0000_0000_0
w[24] = 2(w[23] - q[24] * D) = 2 * 111_11110011110100110111011011000000 = 
111_11100111101001101110110110000000


w_sum[25] = csa_sum(w_sum_translation[24], w_carry_translation[24], -q[25] * D) * 2 = 
000_01101110001100011001101100000000
w_carry[25] = csa_carry(w_sum_translation[24], w_carry_translation[24], -q[25] * D) * 2 =
111_01100001000111000100000000000000
w_sum_translation[25] = 000_01101110001100011001101100000000
w_carry_translation[25] = 111_01100001000111000100000000000000
{w_sum_translation[25][MSB-1:MSB-2], w_carry_translation[25][MSB-1:MSB-2]} = 00_11 -> q[26] = 0
q_pos_sum = 1000_1000_1000_0000_1000_0000_00
q_pos_carry = 0000_0000_0000_0100_0000_0000_00
q_neg_sum = 0000_0100_0011_0010_0010_0100_00
q_neg_carry = 0001_0000_0000_0000_0000_0000_00
w[25] = 2(w[24] - q[25] * D) = 2 * 111_11100111101001101110110110000000 = 
111_11001111010011011101101100000000


w_sum[26] = csa_sum(w_sum_translation[25], w_carry_translation[25], -q[26] * D) * 2 = 
000_11011100011000110011011000000000
w_carry[26] = csa_carry(w_sum_translation[25], w_carry_translation[25], -q[26] * D) * 2 =
110_11000010001110001000000000000000
w_sum_translation[26] = 000_11011100011000110011011000000000
w_carry_translation[26] = 110_11000010001110001000000000000000
{w_sum_translation[26][MSB-1:MSB-2], w_carry_translation[26][MSB-1:MSB-2]} = 00_10 -> q[27] = 0
q_pos_sum = 1000_1000_1000_0000_1000_0000_000
q_pos_carry = 0000_0000_0000_0100_0000_0000_000
q_neg_sum = 0000_0100_0011_0010_0010_0100_000
q_neg_carry = 0001_0000_0000_0000_0000_0000_000
w[26] = 2(w[25] - q[26] * D) = 2 * 111_11001111010011011101101100000000 = 
111_10011110100110111011011000000000


w_sum[27] = csa_sum(w_sum_translation[26], w_carry_translation[26], -q[27] * D) * 2 = 
001_10111000110001100110110000000000
w_carry[27] = csa_carry(w_sum_translation[26], w_carry_translation[26], -q[27] * D) * 2 =
101_10000100011100010000000000000000
w_sum_translation[27] = 111_10111000110001100110110000000000
w_carry_translation[27] = 111_10000100011100010000000000000000
{w_sum_translation[27][MSB-1:MSB-2], w_carry_translation[27][MSB-1:MSB-2]} = 11_11 -> q[28] = -1
q_pos_sum = 1000_1000_1000_0000_1000_0000_0000
q_pos_carry = 0000_0000_0000_0100_0000_0000_0000
q_neg_sum = 0000_0100_0011_0010_0010_0100_0001
q_neg_carry = 0001_0000_0000_0000_0000_0000_0000
w[27] = 2(w[26] - q[27] * D) = 2 * 111_10011110100110111011011000000000 = 
111_00111101001101110110110000000000


w_sum[28] = csa_sum(w_sum_translation[27], w_carry_translation[27], -q[28] * D) * 2 = 
011_10000111001011100110110001100000
w_carry[28] = csa_carry(w_sum_translation[27], w_carry_translation[27], -q[28] * D) * 2 =
110_11110001100000010010000000000000
w_sum_translation[28] = 001_10000111001011100110110001100000
w_carry_translation[28] = 000_11110001100000010010000000000000
{w_sum_translation[28][MSB-1:MSB-2], w_carry_translation[28][MSB-1:MSB-2]} = 01_00 -> q[29] = +1
q_pos_sum = 1000_1000_1000_0000_1000_0000_0000_1
q_pos_carry = 0000_0000_0000_0100_0000_0000_0000_0
q_neg_sum = 0000_0100_0011_0010_0010_0100_0001_0
q_neg_carry = 0001_0000_0000_0000_0000_0000_0000_0
w[28] = 2(w[27] - q[28] * D) = 2 * (
	111_00111101001101110110110000000000 + 
	001_11111111001000000101101000110000
) = 2 * 001_00111100010101111100011000110000 = 
010_01111000101011111000110001100000


w_sum[29] = csa_sum(w_sum_translation[28], w_carry_translation[28], -q[29] * D) * 2 = 
110_11101100111000011101001101100000
w_carry[29] = csa_carry(w_sum_translation[28], w_carry_translation[28], -q[29] * D) * 2 =
010_00000110001111001001000100000000
w_sum_translation[29] = 000_11101100111000011101001101100000
w_carry_translation[29] = 000_00000110001111001001000100000000
{w_sum_translation[29][MSB-1:MSB-2], w_carry_translation[29][MSB-1:MSB-2]} = 00_00 -> q[30] = +1
q_pos_sum = 1000_1000_1000_0000_1000_0000_0000_11
q_pos_carry = 0000_0000_0000_0100_0000_0000_0000_00
q_neg_sum = 0000_0100_0011_0010_0010_0100_0001_00
q_neg_carry = 0001_0000_0000_0000_0000_0000_0000_00
w[29] = 2(w[28] - q[29] * D) = 2 * (
	010_01111000101011111000110001100000 + 
	110_00000000110111111010010111010000
) 2 * 000_01111001100011110011001000110000 = 
000_11110011000111100110010001100000


w_sum[30] = csa_sum(w_sum_translation[29], w_carry_translation[29], -q[30] * D) * 2 = 
101_11010100000001011100111101100000
w_carry[30] = csa_carry(w_sum_translation[29], w_carry_translation[29], -q[30] * D) * 2 =
000_00010011111101100100010100000000
w_sum_translation[30] = 111_11010100000001011100111101100000
w_carry_translation[30] = 110_00010011111101100100010100000000
{w_sum_translation[30][MSB-1:MSB-2], w_carry_translation[30][MSB-1:MSB-2]} = 11_10 -> q[31] = -1
q_pos_sum = 1000_1000_1000_0000_1000_0000_0000_110
q_pos_carry = 0000_0000_0000_0100_0000_0000_0000_000
q_neg_sum = 0000_0100_0011_0010_0010_0100_0001_001
q_neg_carry = 0001_0000_0000_0000_0000_0000_0000_000
w[30] = 2(w[29] - q[30] * D) = 2 * (
	000_11110011000111100110010001100000 + 
	110_00000000110111111010010111010000
) = 2 * 110_11110011111111100000101000110000 = 
101_11100111111111000001010001100000


w_sum[31] = csa_sum(w_sum_translation[30], w_carry_translation[30], -q[31] * D) * 2 = 
000_01110001101001111010000010100000
w_carry[31] = csa_carry(w_sum_translation[30], w_carry_translation[30], -q[31] * D) * 2 =
111_01011100100100010011110010000000
w_sum_translation[31] = 000_01110001101001111010000010100000
w_carry_translation[31] = 111_01011100100100010011110010000000
{w_sum_translation[31][MSB-1:MSB-2], w_carry_translation[31][MSB-1:MSB-2]} = 00_11 -> q[32] = 0
q_pos_sum = 1000_1000_1000_0000_1000_0000_0000_1100
q_pos_carry = 0000_0000_0000_0100_0000_0000_0000_0000
q_neg_sum = 0000_0100_0011_0010_0010_0100_0001_0010
q_neg_carry = 0001_0000_0000_0000_0000_0000_0000_0000
w[31] = 2(w[30] - q[31] * D) = 2 * (
	101_11100111111111000001010001100000 + 
	001_11111111001000000101101000110000
) = 2 * 111_11100111000111000110111010010000 = 
111_11001110001110001101110100100000


w_sum[32] = csa_sum(w_sum_translation[31], w_carry_translation[31], -q[32] * D) * 2 = 
000_11100011010011110100000101000000
w_carry[32] = csa_carry(w_sum_translation[31], w_carry_translation[31], -q[32] * D) * 2 =
110_10111001001000100111100100000000
w_sum_translation[32] = 000_11100011010011110100000101000000
w_carry_translation[32] = 110_10111001001000100111100100000000
{w_sum_translation[32][MSB-1:MSB-2], w_carry_translation[32][MSB-1:MSB-2]} = 00_10 -> q[33] = 0
q_pos_sum = 1000_1000_1000_0000_1000_0000_0000_1100_0
q_pos_carry = 0000_0000_0000_0100_0000_0000_0000_0000_0
q_neg_sum = 0000_0100_0011_0010_0010_0100_0001_0010_0
q_neg_carry = 0001_0000_0000_0000_0000_0000_0000_0000_0
w[32] = 2(w[31] - q[32] * D) = 2 * 111_11001110001110001101110100100000 = 
111_10011100011100011011101001000000



w_sum[33] = csa_sum(w_sum_translation[32], w_carry_translation[32], -q[33] * D) * 2 = 
001_11000110100111101000001010000000
w_carry[33] = csa_carry(w_sum_translation[32], w_carry_translation[32], -q[33] * D) * 2 =
101_01110010010001001111001000000000
w_sum_translation[33] = 111_11000110100111101000001010000000
w_carry_translation[33] = 111_01110010010001001111001000000000
{w_sum_translation[33][MSB-1:MSB-2], w_carry_translation[33][MSB-1:MSB-2]} = 11_11 -> q[34] = -1
q_pos_sum = 1000_1000_1000_0000_1000_0000_0000_1100_00
q_pos_carry = 0000_0000_0000_0100_0000_0000_0000_0000_00
q_neg_sum = 0000_0100_0011_0010_0010_0100_0001_0010_01
q_neg_carry = 0001_0000_0000_0000_0000_0000_0000_0000_00
w[33] = 2(w[32] - q[33] * D) = 2 * 111_10011100011100011011101001000000 = 
111_00111000111000110111010010000000


w_sum[34] = csa_sum(w_sum_translation[33], w_carry_translation[33], -q[34] * D) * 2 = 
010_10010111111101000101010101100000
w_carry[34] = csa_carry(w_sum_translation[33], w_carry_translation[33], -q[34] * D) * 2 =
111_11011000000100110100100000000000
w_sum_translation[34] = 000_10010111111101000101010101100000
w_carry_translation[34] = 001_11011000000100110100100000000000
{w_sum_translation[34][MSB-1:MSB-2], w_carry_translation[34][MSB-1:MSB-2]} = 00_01 -> q[35] = +1
q_pos_sum = 1000_1000_1000_0000_1000_0000_0000_1100_001
q_pos_carry = 0000_0000_0000_0100_0000_0000_0000_0000_000
q_neg_sum = 0000_0100_0011_0010_0010_0100_0001_0010_010
q_neg_carry = 0001_0000_0000_0000_0000_0000_0000_0000_000
w[34] = 2(w[33] - q[34] * D) = 2 * (
	111_00111000111000110111010010000000 + 
	001_11111111001000000101101000110000
) = 2 * 001_00111000000000111100111010110000 = 
010_01110000000001111001110101100000




q_pos_sum[34-1:0] = 1000_1000_1000_0000_1000_0000_0000_1100_00
q_pos_carry[34-1:0] = 0000_0000_0000_0100_0000_0000_0000_0000_00
q_neg_sum[34-1:0] = 0000_0100_0011_0010_0010_0100_0001_0010_01
q_neg_carry[34-1:0] = 0001_0000_0000_0000_0000_0000_0000_0000_00
q_pos_sum + (q_pos_carry * 2) - q_neg_sum - (q_neg_carry * 2) = 
1000_1000_1000_0000_1000_0000_0000_1100_00 + 
000_0000_0000_0100_0000_0000_0000_0000_000 - 
0000_0100_0011_0010_0010_0100_0001_0010_01 - 
001_0000_0000_0000_0000_0000_0000_0000_000 = 
0_110010001010110010110111111100111
规格化可得:
1_100100010101100101101111111001110

q_pos_sum[(WIDTH + 2)-1:0] = 1000_1000_1000_0000_1000_0000_0000_1100_001
q_pos_carry[(WIDTH + 2)-1:0] = 0000_0000_0000_0100_0000_0000_0000_0000_000
q_neg_sum[(WIDTH + 2)-1:0] = 0000_0100_0011_0010_0010_0100_0001_0010_010
q_neg_carry[(WIDTH + 2)-1:0] = 0001_0000_0000_0000_0000_0000_0000_0000_000
q_pos_sum + (q_pos_carry * 2) - q_neg_sum - (q_neg_carry * 2) = 
1000_1000_1000_0000_1000_0000_0000_1100_001 + 
000_0000_0000_0100_0000_0000_0000_0000_0000 - 
0000_0100_0011_0010_0010_0100_0001_0010_010 - 
001_0000_0000_0000_0000_0000_0000_0000_0000
01100100010101100101101111111001111
规格化可得:
1_100100010101100101101111111001111

保留32位小数可得:
no_rup = 1_10010001010110010110111111100111
rup = 1_10010001010110010110111111100111 + 0_00000000000000000000000000000001 = 
1_10010001010110010110111111101000

Q_no_rup[33-1:0] 	= 1_10010001010110010110111111100111
Q_rup[33-1:0] 		= 1_10010001010110010110111111101000