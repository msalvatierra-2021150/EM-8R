# EM-8R - Standalone ROM simulation (Questa GUI)
# From the project root: do sim/run_instruction_memory.do
# No 'quit' here, so Wave window stays open.

if {![file isdirectory work]} {
    vlib work
}
vmap work work

vlog -sv rtl/instruction_memory.sv tb/tb_instruction_memory.sv
vsim -voptargs=+acc work.tb_instruction_memory

view wave
add wave -radix hex sim:/tb_instruction_memory/addr
add wave -radix hex sim:/tb_instruction_memory/instruction

run -all
wave zoom full
