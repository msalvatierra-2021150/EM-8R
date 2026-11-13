`timescale 1ns/1ps
// Standalone combinational decoder test: no clock required.
module tb_instruction_decoder;
    import em8r_isa_pkg::*;

    logic [15:0] instruction;
    logic [3:0] opcode;
    logic [1:0] rd_addr, rs_addr;
    logic [7:0] immediate, branch_addr;
    logic valid, reg_write, flag_write;
    logic [2:0] alu_op, branch_type;
    logic [1:0] writeback_sel;
    integer passed = 0;

    instruction_decoder dut (
        .instruction(instruction), .opcode(opcode),
        .rd_addr(rd_addr), .rs_addr(rs_addr),
        .immediate(immediate), .branch_addr(branch_addr),
        .valid(valid), .reg_write(reg_write),
        .flag_write(flag_write), .alu_op(alu_op),
        .writeback_sel(writeback_sel), .branch_type(branch_type)
    );

    // Check every decoder output, including raw fields and safety controls.
    task automatic expect_decode(
        input string label_text,
        input logic [15:0] word,
        input logic exp_valid,
        input logic exp_reg_write,
        input logic exp_flag_write,
        input logic [2:0] exp_alu,
        input logic [1:0] exp_wb,
        input logic [2:0] exp_branch
    );
        instruction = word;
        #1; // Allow combinational logic to settle.

        if ({opcode, rd_addr, rs_addr, immediate, branch_addr} !==
            {word[15:12], word[11:10], word[9:8], word[7:0], word[7:0]} ||
            {valid, reg_write, flag_write, alu_op, writeback_sel, branch_type} !==
            {exp_valid, exp_reg_write, exp_flag_write, exp_alu, exp_wb, exp_branch}) begin
            $display("FAIL %-36s instruction=%04h", label_text, word);
            $display("  raw: opcode=%h rd=%0d rs=%0d imm=%02h target=%02h",
                     opcode, rd_addr, rs_addr, immediate, branch_addr);
            $display("  control GOT: valid=%b reg_wr=%b flag_wr=%b alu=%b wb=%b branch=%b",
                     valid, reg_write, flag_write, alu_op, writeback_sel, branch_type);
            $display("  control EXP: valid=%b reg_wr=%b flag_wr=%b alu=%b wb=%b branch=%b",
                     exp_valid, exp_reg_write, exp_flag_write, exp_alu, exp_wb, exp_branch);
            $fatal(1, "Decoder mismatch");
        end
        passed++;
        $display("PASS %-36s word=%04h", label_text, word);
    endtask

    initial begin
        // Legal ISA encodings. All numbers are hexadecimal.
        expect_decode("NOP",             16'h0000, 1,0,0, ALU_ADD,WB_ALU,BR_NONE);
        expect_decode("MOVI R0, #05",    16'h1005, 1,1,0, ALU_ADD,WB_IMM,BR_NONE);
        expect_decode("MOVI R1, #03",    16'h1403, 1,1,0, ALU_ADD,WB_IMM,BR_NONE);
        expect_decode("MOVI R2, #80",    16'h1880, 1,1,0, ALU_ADD,WB_IMM,BR_NONE);
        expect_decode("MOVI R3, #FF",    16'h1CFF, 1,1,0, ALU_ADD,WB_IMM,BR_NONE);
        expect_decode("MOV R0, R1",      16'h2100, 1,1,0, ALU_ADD,WB_RS, BR_NONE);
        expect_decode("MOV R2, R3",      16'h2B00, 1,1,0, ALU_ADD,WB_RS, BR_NONE);
        expect_decode("ADD R0, R1",      16'h3100, 1,1,1, ALU_ADD,WB_ALU,BR_NONE);
        expect_decode("SUB R0, R1",      16'h4100, 1,1,1, ALU_SUB,WB_ALU,BR_NONE);
        expect_decode("AND R0, R1",      16'h5100, 1,1,1, ALU_AND,WB_ALU,BR_NONE);
        expect_decode("OR R3, R1",       16'h6D00, 1,1,1, ALU_OR, WB_ALU,BR_NONE);
        expect_decode("XOR R0, R1",      16'h7100, 1,1,1, ALU_XOR,WB_ALU,BR_NONE);
        expect_decode("CMP R0, R1",      16'h8100, 1,0,1, ALU_SUB,WB_ALU,BR_NONE);
        expect_decode("JMP 02",          16'h9002, 1,0,0, ALU_ADD,WB_ALU,BR_ALWAYS);
        expect_decode("JZ 08",           16'hA008, 1,0,0, ALU_ADD,WB_ALU,BR_Z);
        expect_decode("JNZ 03",          16'hB003, 1,0,0, ALU_ADD,WB_ALU,BR_NZ);
        expect_decode("JC 0C",           16'hC00C, 1,0,0, ALU_ADD,WB_ALU,BR_C);
        expect_decode("JNC 0D",          16'hD00D, 1,0,0, ALU_ADD,WB_ALU,BR_NC);

        // Invalid/unused bits must not produce any writes or branch requests.
        expect_decode("Invalid NOP payload",   16'h0001, 0,0,0, ALU_ADD,WB_ALU,BR_NONE);
        expect_decode("Invalid MOVI Rs bits",  16'h1105, 0,0,0, ALU_ADD,WB_ALU,BR_NONE);
        expect_decode("Invalid MOV immediate", 16'h2101, 0,0,0, ALU_ADD,WB_ALU,BR_NONE);
        expect_decode("Invalid ADD immediate", 16'h3101, 0,0,0, ALU_ADD,WB_ALU,BR_NONE);
        expect_decode("Invalid CMP immediate", 16'h8101, 0,0,0, ALU_ADD,WB_ALU,BR_NONE);
        expect_decode("Invalid JMP Rd/Rs bits",16'h9102, 0,0,0, ALU_ADD,WB_ALU,BR_NONE);
        expect_decode("Invalid JZ Rd/Rs bits", 16'hA108, 0,0,0, ALU_ADD,WB_ALU,BR_NONE);
        expect_decode("Invalid JNZ fields",    16'hB103, 0,0,0, ALU_ADD,WB_ALU,BR_NONE);
        expect_decode("Invalid JC fields",     16'hC10C, 0,0,0, ALU_ADD,WB_ALU,BR_NONE);
        expect_decode("Invalid JNC fields",    16'hD10D, 0,0,0, ALU_ADD,WB_ALU,BR_NONE);
        expect_decode("Reserved opcode E",     16'hE000, 0,0,0, ALU_ADD,WB_ALU,BR_NONE);
        expect_decode("Reserved opcode F",     16'hF000, 0,0,0, ALU_ADD,WB_ALU,BR_NONE);

        // Exhaustively test the 4 x 4 register selections for two R-type ops.
        for (int rd=0; rd<4; rd++) begin
            for (int rs=0; rs<4; rs++) begin
                expect_decode($sformatf("ADD Rd=%0d Rs=%0d",rd,rs),
                    16'h3000 | (rd << 10) | (rs << 8),
                    1,1,1, ALU_ADD,WB_ALU,BR_NONE);
                expect_decode($sformatf("CMP Rd=%0d Rs=%0d",rd,rs),
                    16'h8000 | (rd << 10) | (rs << 8),
                    1,0,1, ALU_SUB,WB_ALU,BR_NONE);
            end
        end

        $display("ALL %0d INSTRUCTION DECODER TESTS PASSED", passed);
        $finish;
    end
endmodule
