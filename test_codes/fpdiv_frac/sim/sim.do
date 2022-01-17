quit -sim

file mkdir ./lib
file mkdir ./lib/work
file mkdir ./log
file mkdir ./wave

vlib ./lib
vlib ./lib/work

vmap work ./lib/work

set RAND_SEED 55
set MAX_ERROR_COUNT 50

# Add this definition to chech error
#+TEST_SPECIAL_POINT

vlog -work work -incr \
+define+RAND_SEED=$RAND_SEED+MAX_ERROR_COUNT=$MAX_ERROR_COUNT \
-f ../tb/tb.lst +define+

vsim \
-c -l ./log/tb_top.log -wlf ./wave/tb_top.wlf -voptargs=+acc -sv_seed $RAND_SEED work.tb_top


# 0: full names
# 1: leaf names
configure wave -signalnamewidth 1
configure wave -timelineunits ns

# Display waves ??
#do wave.do
#do wave_v3.do

run -all

