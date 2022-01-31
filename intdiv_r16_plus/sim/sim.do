quit -sim

file mkdir ./lib
file mkdir ./lib/work
file mkdir ./log
file mkdir ./wave

vlib ./lib
vlib ./lib/work

vmap work ./lib/work

# set RAND_SEED 558340228
set RAND_SEED [expr {int(rand() * 999999999)}]
set MAX_ERROR_COUNT 10
set SDIV_TEST_NUM [expr {int(pow(2, 22))}]
set UDIV_TEST_NUM [expr {int(pow(2, 22))}]
set NEG_POWER_OF_2_TEST_NUM [expr {int(pow(2, 19))}]
# Add this option for particular operands, if needed
# +define+TEST_NEG_POWER_OF_2

vlog -work work -incr -lint \
+define+RAND_SEED=$RAND_SEED+MAX_ERROR_COUNT=$MAX_ERROR_COUNT \
+define+SDIV_TEST_NUM=$SDIV_TEST_NUM+UDIV_TEST_NUM=$UDIV_TEST_NUM+NEG_POWER_OF_2_TEST_NUM=$NEG_POWER_OF_2_TEST_NUM \
+define+DUT_WIDTH_64 \
-f ../tb/tb.lst

vsim -c -l ./log/tb_$RAND_SEED.log -wlf ./wave/tb_top.wlf -voptargs=+acc -sv_seed $RAND_SEED work.tb_top


# 0: full names
# 1: leaf names
configure wave -signalnamewidth 1
configure wave -timelineunits ns

# Display waves ???
# do wave.do

run -all
