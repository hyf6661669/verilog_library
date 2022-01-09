quit -sim

file mkdir ./lib
file mkdir ./lib/work
file mkdir ./log
file mkdir ./wave

vlib ./lib
vlib ./lib/work

vmap work ./lib/work

set RAND_SEED 900
set TEST_LEVEL 2
set MAX_ERROR_COUNT 10
set FP64_TEST_NUM [expr {int(pow(2, 22))}]
set FP32_TEST_NUM [expr {int(pow(2, 22))}]
set FP16_TEST_NUM [expr {int(pow(2, 22))}]

# Add this definition to chech error
#+TEST_SPECIAL_POINT

vlog -work work -incr \
+define+RAND_SEED=$RAND_SEED+TEST_LEVEL=$TEST_LEVEL+MAX_ERROR_COUNT=$MAX_ERROR_COUNT+FAST_INIT \
+define+FP64_TEST_NUM=$FP64_TEST_NUM+FP32_TEST_NUM=$FP32_TEST_NUM+FP16_TEST_NUM=$FP16_TEST_NUM \
+define+RANDOM_RM \
-f ../tb/tb.lst

vsim \
-sv_lib ../cmodel/lib/softfloat -sv_lib ../cmodel/lib/testfloat_gencases -sv_lib ../cmodel/lib/cmodel \
-c -l ./log/tb_top.log -wlf ./wave/tb_top.wlf -voptargs=+acc -sv_seed $RAND_SEED work.tb_top


# 0: full names
# 1: leaf names
configure wave -signalnamewidth 1
configure wave -timelineunits ns

# Display waves ??
#do wave.do
#do wave_fast_init.do

run -all

