# EM-8R - PC + Instruction ROM simulation (Questa GUI)
# From the project root: do sim/run_instruction_fetch.do
# No 'quit' here, so Wave window stays open.

if {![file isdirectory work]} {
    vlib work
}
vmap work work

vlog -sv rtl/program_counter.sv rtl/instruction_memory.sv rtl/instruction_fetch.sv tb/tb_instruction_fetch.sv
vsim -voptargs=+acc work.tb_instruction_fetch

view wave
add wave sim:/tb_instruction_fetch/clk
add wave sim:/tb_instruction_fetch/reset
add wave sim:/tb_instruction_fetch/load
add wave sim:/tb_instruction_fetch/enable
add wave -radix hex sim:/tb_instruction_fetch/jump_addr
add wave -radix hex sim:/tb_instruction_fetch/pc
add wave -radix hex sim:/tb_instruction_fetch/instruction

run -all
wave zoom full
