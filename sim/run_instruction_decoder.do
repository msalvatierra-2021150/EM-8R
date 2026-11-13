# EM-8R standalone instruction decoder, Questa GUI.
# Run from the project root (containing rtl/, tb/, sim/ and mem/).
if {![file isdirectory work]} { vlib work }
vmap work work
vlog -sv rtl/em8r_isa_pkg.sv rtl/instruction_decoder.sv tb/tb_instruction_decoder.sv
vsim -voptargs=+acc work.tb_instruction_decoder
view wave
add wave -radix hex sim:/tb_instruction_decoder/instruction
add wave -radix hex sim:/tb_instruction_decoder/opcode
add wave -radix unsigned sim:/tb_instruction_decoder/rd_addr
add wave -radix unsigned sim:/tb_instruction_decoder/rs_addr
add wave -radix hex sim:/tb_instruction_decoder/immediate
add wave sim:/tb_instruction_decoder/valid
add wave sim:/tb_instruction_decoder/reg_write
add wave sim:/tb_instruction_decoder/flag_write
add wave -radix binary sim:/tb_instruction_decoder/alu_op
add wave -radix binary sim:/tb_instruction_decoder/writeback_sel
add wave -radix binary sim:/tb_instruction_decoder/branch_type
add wave -radix hex sim:/tb_instruction_decoder/branch_addr
run -all
wave zoom full
# No quit: leave Questa's GUI open to inspect the waveforms.
