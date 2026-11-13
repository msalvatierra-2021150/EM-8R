# EM-8R CPU - Interactive Questa program-counter simulation
# Run in Questa Transcript from the project root:
#   do sim/run_program_counter.do
# Or start the GUI with:
#   vsim -do sim/run_program_counter.do
# Do NOT use -c for interactive waveforms; do NOT add 'quit'.

# cd C:/FPGA/alu_cpu
# do sim/run_program_counter.do

if {![file isdirectory work]} {
    vlib work
}
vmap work work

vlog -sv rtl/program_counter.sv tb/tb_program_counter.sv
vsim -voptargs=+acc work.tb_program_counter

view wave
add wave -r sim:/tb_program_counter/*

run -all
wave zoom full
