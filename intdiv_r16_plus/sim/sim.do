quit -sim

file mkdir ./lib
file mkdir ./lib/work
file mkdir ./log
file mkdir ./wave

vlib ./lib
vlib ./lib/work

vmap work ./lib/work

# set RAND_SEED 88
set RAND_SEED [expr {int(rand() * 999999999)}]
set MAX_ERROR_COUNT 10
set SDIV_TEST_NUM [expr {int(pow(2, 15))}]
set UDIV_TEST_NUM [expr {int(pow(2, 15))}]
set DUT_WIDTH 32

vlog -work work -incr -lint \
+define+RAND_SEED=$RAND_SEED+MAX_ERROR_COUNT=$MAX_ERROR_COUNT \
+define+SDIV_TEST_NUM=$SDIV_TEST_NUM+UDIV_TEST_NUM=$UDIV_TEST_NUM \
+define+DUT_WIDTH_32 \
-f ../tb/tb.lst

vsim -c -l ./log/tb_top.log -wlf ./wave/tb_top.wlf -voptargs=+acc -sv_seed $RAND_SEED work.tb_top


# 0: full names
# 1: leaf names
configure wave -signalnamewidth 1
configure wave -timelineunits ns

# wave files for WIDTH = 64
# do wave_64.do

# wave files for WIDTH = 32
# do wave_32.do

# wave files for WIDTH = 16
#do wave_16.do

run -all
