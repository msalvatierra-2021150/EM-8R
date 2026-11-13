// ===============================================================
// EM-8R CPU -- Fetch + Decoder Integration, version 0.1
// ===============================================================
// Reuses EXISTING instruction_fetch (which contains PC + ROM).
// Control inputs for PC are still driven externally in this stage.
// Branch requests are NOT automatically taken. That requires a
// control unit and a saved flag register (future stages).
module instruction_fetch_decode #(
    parameter INIT_FILE = "mem/program_isa.hex"
) (
    input  logic        clk,
    input  logic        reset,
    input  logic        load,
    input  logic        enable,
    input  logic [7:0]  jump_addr,

    output logic [7:0]  pc,
    output logic [15:0] instruction,
    output logic [3:0]  opcode,
    output logic [1:0]  rd_addr,
    output logic [1:0]  rs_addr,
    output logic [7:0]  immediate,
    output logic [7:0]  branch_addr,
    output logic        valid,
    output logic        reg_write,
    output logic        flag_write,
    output logic [2:0]  alu_op,
    output logic [1:0]  writeback_sel,
    output logic [2:0]  branch_type
);
    instruction_fetch #(
        .INIT_FILE(INIT_FILE)
    ) u_fetch (
        .clk        (clk),
        .reset      (reset),
        .load       (load),
        .enable     (enable),
        .jump_addr  (jump_addr),
        .pc         (pc),
        .instruction(instruction)
    );

    instruction_decoder u_decode (
        .instruction  (instruction),
        .opcode       (opcode),
        .rd_addr      (rd_addr),
        .rs_addr      (rs_addr),
        .immediate    (immediate),
        .branch_addr  (branch_addr),
        .valid        (valid),
        .reg_write    (reg_write),
        .flag_write   (flag_write),
        .alu_op       (alu_op),
        .writeback_sel(writeback_sel),
        .branch_type  (branch_type)
    );
endmodule
