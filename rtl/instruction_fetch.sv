// ================================================================
// EM-8R CPU - PC + Instruction ROM Integration, version 0.1
// ================================================================
// Fetch-only hardware. There is no instruction register, decoder,
// execute stage, or assembler-defined ISA in this module yet.
//
// At any time, instruction reflects ROM[pc] (combinational read).
// The PC updates only on the rising edge of clk.
module instruction_fetch #(
    parameter INIT_FILE = "mem/program_demo.hex"
) (
    input  logic        clk,
    input  logic        reset,
    input  logic        load,
    input  logic        enable,
    input  logic [7:0]  jump_addr,
    output logic [7:0]  pc,
    output logic [15:0] instruction
);

    program_counter u_pc (
        .clk       (clk),
        .reset     (reset),
        .load      (load),
        .enable    (enable),
        .jump_addr (jump_addr),
        .pc        (pc)
    );

    instruction_memory #(
        .INIT_FILE(INIT_FILE)
    ) u_imem (
        .addr        (pc),
        .instruction (instruction)
    );

endmodule
