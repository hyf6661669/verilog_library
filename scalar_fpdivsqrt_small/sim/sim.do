quit -sim

file mkdir ./lib
file mkdir ./lib/work
file mkdir ./log
file mkdir ./wave

vlib ./lib
vlib ./lib/work

vmap work ./lib/work

#set RAND_SEED 35
set RAND_SEED [expr {int(rand() * 999999999)}]
set TEST_LEVEL 2
# set FP16_TEST_NUM [expr {int(pow(2, 19))}]
# set FP32_TEST_NUM [expr {int(pow(2, 19))}]
# set FP64_TEST_NUM [expr {int(pow(2, 19))}]
set FP16_TEST_NUM 0
set FP32_TEST_NUM 4000000
set FP64_TEST_NUM 4000000

# Add this definition, if you don't want to test all the 5 rounding modes for each stimulation
# +define+RANDOM_RM \

vlog -work work -incr -lint \
+define+RAND_SEED=$RAND_SEED+TEST_LEVEL=$TEST_LEVEL \
+define+FP64_TEST_NUM=$FP64_TEST_NUM+FP32_TEST_NUM=$FP32_TEST_NUM+FP16_TEST_NUM=$FP16_TEST_NUM \
+define+RANDOM_RM \
-f ../tb/tb.lst

vsim \
-sv_lib ../cmodel/lib/softfloat -sv_lib ../cmodel/lib/testfloat_gencases -sv_lib ../cmodel/lib/cmodel \
-c -l ./log/run_$RAND_SEED.log -wlf ./wave/run_$RAND_SEED.wlf -voptargs=+acc -sv_seed $RAND_SEED work.tb_top


# 0: full names
# 1: leaf names
configure wave -signalnamewidth 1
configure wave -timelineunits ns

# Display waves ??
#do fdiv_wave.do
#do fsqrt_wave.do

run -all

