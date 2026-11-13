# EM-8R CPU - interactive Questa simulation script
# In Questa's Transcript, start from the project root and run:
#   do sim/run_register_file.do
# No quit: GUI and waveforms remain visible.

if {![file isdirectory work]} {
    vlib work
}
vmap work work
vlog -sv rtl/register_file.sv tb/tb_register_file.sv
vsim -voptargs=+acc work.tb_register_file
view wave
add wave -r sim:/tb_register_file/*
run -all
wave zoom full
