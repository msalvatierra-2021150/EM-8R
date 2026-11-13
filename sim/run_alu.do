
# ====================================
# EM-8R CPU - ALU Simulation
# ====================================
# Run from the project root

# 1. Create the work library
if {![file isdirectory work]} {
    vlib work
}

vmap work work

# 2. Compile SystemVerilog files
vlog -sv rtl/alu.sv tb/tb_alu.sv

# 3. Load the testbench
vsim -voptargs=+acc work.tb_alu

# 4. Open waveform viewer
view wave

# 5. Add all testbench signals
add wave -r sim:/tb_alu/*

# 6. Run simulation
run -all

# 7. Fit all waveforms to the window
wave zoom full

# Keep Questa GUI open
# Do NOT add quit or a second vsim
