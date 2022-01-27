quit -sim

file mkdir ./lib
file mkdir ./lib/work
file mkdir ./log
file mkdir ./wave

vlib ./lib
vlib ./lib/work

vmap work ./lib/work

# set RAND_SEED 642273601
set RAND_SEED [expr {int(rand() * 999999999)}]
set TEST_LEVEL 1
set MAX_ERROR_COUNT 10
set FP64_TEST_NUM [expr {int(pow(2, 25))}]
set FP32_TEST_NUM [expr {int(pow(2, 25))}]
set FP16_TEST_NUM [expr {int(pow(2, 0))}]


vlog -work work -incr -lint \
+define+RAND_SEED=$RAND_SEED+MAX_ERROR_COUNT=$MAX_ERROR_COUNT \
+define+FP64_TEST_NUM=$FP64_TEST_NUM+FP32_TEST_NUM=$FP32_TEST_NUM+FP16_TEST_NUM=$FP16_TEST_NUM \
-f ../tb/tb.lst

vsim \
-sv_lib ../cmodel/lib/softfloat -sv_lib ../cmodel/lib/cmodel \
-c -l ./log/tb_top.log -wlf ./wave/tb_top.wlf -voptargs=+acc -sv_seed $RAND_SEED work.tb_top


# 0: full names
# 1: leaf names
configure wave -signalnamewidth 1
configure wave -timelineunits ns

# Display waves ??
# do wave.do

run -all

