// ==============================================================
// EM-8R CPU -- 16-bit combinational Instruction Decoder (v0.1)
// ==============================================================
// This module TRANSLATES machine-code bits into control signals.
// It does not execute instructions, update registers or flags,
// evaluate branch conditions, or advance the program counter.
// Illegal encodings have valid=0 and no write/branch side effects.
module instruction_decoder (
    input  logic [15:0] instruction,

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
    import em8r_isa_pkg::*;

    // Fixed bit positions in EVERY 16-bit instruction.
    assign opcode      = instruction[15:12];
    assign rd_addr     = instruction[11:10];
    assign rs_addr     = instruction[9:8];
    assign immediate   = instruction[7:0];
    assign branch_addr = instruction[7:0];

    always_comb begin
        // Safe defaults avoid latches and unwanted hardware writes.
        valid         = 1'b0;
        reg_write     = 1'b0;
        flag_write    = 1'b0;
        alu_op        = ALU_ADD;
        writeback_sel = WB_ALU;
        branch_type   = BR_NONE;

        case (opcode)
            OP_NOP: begin
                // For NOP, every unused bit must be zero.
                if (instruction[11:0] == 12'h000)
                    valid = 1'b1;
            end

            OP_MOVI: begin
                // MOVI Rd, #imm8: Rs bits are unused and must be zero.
                if (instruction[9:8] == 2'b00) begin
                    valid         = 1'b1;
                    reg_write     = 1'b1;
                    writeback_sel = WB_IMM;
                end
            end

            OP_MOV: begin
                // MOV Rd, Rs: 8-bit immediate is unused.
                if (instruction[7:0] == 8'h00) begin
                    valid         = 1'b1;
                    reg_write     = 1'b1;
                    writeback_sel = WB_RS;
                end
            end

            OP_ADD, OP_SUB, OP_AND, OP_OR, OP_XOR, OP_CMP: begin
                // Register-register ALU operations: imm8 must be zero.
                if (instruction[7:0] == 8'h00) begin
                    valid      = 1'b1;
                    reg_write  = (opcode != OP_CMP);
                    flag_write = 1'b1;

                    case (opcode)
                        OP_ADD: alu_op = ALU_ADD;
                        OP_SUB: alu_op = ALU_SUB;
                        OP_AND: alu_op = ALU_AND;
                        OP_OR:  alu_op = ALU_OR;
                        OP_XOR: alu_op = ALU_XOR;
                        OP_CMP: alu_op = ALU_SUB; // subtract only to set flags
                        default: alu_op = ALU_ADD;
                    endcase
                end
            end

            OP_JMP, OP_JZ, OP_JNZ, OP_JC, OP_JNC: begin
                // Absolute 8-bit target; Rd/Rs bits must be zero.
                if (instruction[11:8] == 4'h0) begin
                    valid = 1'b1;
                    case (opcode)
                        OP_JMP: branch_type = BR_ALWAYS;
                        OP_JZ:  branch_type = BR_Z;
                        OP_JNZ: branch_type = BR_NZ;
                        OP_JC:  branch_type = BR_C;
                        OP_JNC: branch_type = BR_NC;
                        default: branch_type = BR_NONE;
                    endcase
                end
            end

            // E/F and any unknown opcode are invalid.
            default: ;
        endcase
    end
endmodule
