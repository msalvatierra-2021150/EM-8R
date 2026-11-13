# EM-8R integrated PC + ROM + decoder, Questa GUI.
# Depends on previously completed rtl/program_counter.sv,
# rtl/instruction_memory.sv, and rtl/instruction_fetch.sv.
# Run from the project root (containing rtl/, tb/, sim/ and mem/).
if {![file isdirectory work]} { vlib work }
vmap work work
vlog -sv rtl/em8r_isa_pkg.sv rtl/program_counter.sv rtl/instruction_memory.sv rtl/instruction_fetch.sv rtl/instruction_decoder.sv rtl/instruction_fetch_decode.sv tb/tb_instruction_fetch_decode.sv
vsim -voptargs=+acc work.tb_instruction_fetch_decode
view wave
add wave sim:/tb_instruction_fetch_decode/clk
add wave sim:/tb_instruction_fetch_decode/reset
add wave sim:/tb_instruction_fetch_decode/load
add wave sim:/tb_instruction_fetch_decode/enable
add wave -radix hex sim:/tb_instruction_fetch_decode/jump_addr
add wave -radix hex sim:/tb_instruction_fetch_decode/pc
add wave -radix hex sim:/tb_instruction_fetch_decode/instruction
add wave -radix hex sim:/tb_instruction_fetch_decode/opcode
add wave -radix unsigned sim:/tb_instruction_fetch_decode/rd_addr
add wave -radix unsigned sim:/tb_instruction_fetch_decode/rs_addr
add wave -radix hex sim:/tb_instruction_fetch_decode/immediate
add wave sim:/tb_instruction_fetch_decode/valid
add wave sim:/tb_instruction_fetch_decode/reg_write
add wave sim:/tb_instruction_fetch_decode/flag_write
add wave -radix binary sim:/tb_instruction_fetch_decode/alu_op
add wave -radix binary sim:/tb_instruction_fetch_decode/writeback_sel
add wave -radix binary sim:/tb_instruction_fetch_decode/branch_type
add wave -radix hex sim:/tb_instruction_fetch_decode/branch_addr
run -all
wave zoom full
# No quit: leave Questa's GUI open.
