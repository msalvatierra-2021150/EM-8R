`timescale 1ns/1ps
// Integration test: existing PC+ROM connected to the new decoder.
// NOTE: a branch *request* does not move the PC in this stage.
module tb_instruction_fetch_decode;
    import em8r_isa_pkg::*;

    logic clk = 1'b0;
    always #5 clk = ~clk;

    logic reset, load, enable;
    logic [7:0] jump_addr;
    logic [7:0] pc;
    logic [15:0] instruction;
    logic [3:0] opcode;
    logic [1:0] rd_addr, rs_addr;
    logic [7:0] immediate, branch_addr;
    logic valid, reg_write, flag_write;
    logic [2:0] alu_op, branch_type;
    logic [1:0] writeback_sel;
    integer passed = 0;

    instruction_fetch_decode #(.INIT_FILE("mem/program_isa.hex")) dut (
        .clk(clk), .reset(reset), .load(load), .enable(enable),
        .jump_addr(jump_addr), .pc(pc), .instruction(instruction),
        .opcode(opcode), .rd_addr(rd_addr), .rs_addr(rs_addr),
        .immediate(immediate), .branch_addr(branch_addr),
        .valid(valid), .reg_write(reg_write), .flag_write(flag_write),
        .alu_op(alu_op), .writeback_sel(writeback_sel),
        .branch_type(branch_type)
    );

    task automatic check_state(
        input string label_text,
        input logic [7:0] exp_pc,
        input logic [15:0] exp_word,
        input logic exp_valid,
        input logic exp_regwr,
        input logic exp_flagwr,
        input logic [2:0] exp_branch
    );
        if ({pc, instruction, opcode, rd_addr, rs_addr, immediate, branch_addr,
             valid, reg_write, flag_write, branch_type} !==
            {exp_pc, exp_word, exp_word[15:12], exp_word[11:10], exp_word[9:8],
             exp_word[7:0], exp_word[7:0],
             exp_valid, exp_regwr, exp_flagwr, exp_branch}) begin
            $display("FAIL: %s", label_text);
            $display("  GOT pc=%02h instruction=%04h valid=%b reg_wr=%b flag_wr=%b branch=%b",
                       pc,instruction,valid,reg_write,flag_write,branch_type);
            $display("  EXP pc=%02h instruction=%04h valid=%b reg_wr=%b flag_wr=%b branch=%b",
                       exp_pc,exp_word,exp_valid,exp_regwr,exp_flagwr,exp_branch);
            $fatal(1, "Fetch/decode integration mismatch");
        end
        passed++;
        $display("PASS %-36s PC=%02h instr=%04h",label_text,pc,instruction);
    endtask

    task automatic check_detail(
        input string label_text,
        input logic [2:0] exp_alu,
        input logic [1:0] exp_wb
    );
        if ({alu_op, writeback_sel} !== {exp_alu, exp_wb})
            $fatal(1,"FAIL %s: got alu=%b wb=%b, expected alu=%b wb=%b",
                   label_text,alu_op,writeback_sel,exp_alu,exp_wb);
        passed++;
        $display("PASS %-36s alu=%b wb=%b",label_text,alu_op,writeback_sel);
    endtask

    task automatic step(
        input string label_text,
        input logic rst, ld, en,
        input logic [7:0] target,
        input logic [7:0] exp_pc,
        input logic [15:0] exp_word,
        input logic exp_valid, exp_regwr, exp_flagwr,
        input logic [2:0] exp_branch
    );
        @(negedge clk);
        reset = rst;
        load = ld;
        enable = en;
        jump_addr = target;
        @(posedge clk);
        #1; // Wait for nonblocking PC update + combinational ROM/decoder.
        check_state(label_text,exp_pc,exp_word,exp_valid,exp_regwr,exp_flagwr,exp_branch);
    endtask

    initial begin
        reset=0; load=0; enable=0; jump_addr=0;
        step("reset -> MOVI R0,#05",    1,0,0,8'h00, 8'h00,16'h1005, 1,1,0,BR_NONE);
        check_detail("MOVI selects immediate", ALU_ADD,WB_IMM);
        step("PC 01 -> MOVI R1,#03",   0,0,1,8'h00, 8'h01,16'h1403, 1,1,0,BR_NONE);
        check_detail("MOVI R1 selects immediate",ALU_ADD,WB_IMM);
        step("PC 02 -> ADD R0,R1",     0,0,1,8'h00, 8'h02,16'h3100, 1,1,1,BR_NONE);
        check_detail("ADD selects ALU result", ALU_ADD,WB_ALU);
        step("PC 03 -> CMP R0,R1",     0,0,1,8'h00, 8'h03,16'h8100, 1,0,1,BR_NONE);
        check_detail("CMP only updates flags",ALU_SUB,WB_ALU);
        step("PC 04 -> JZ 08",         0,0,1,8'h00, 8'h04,16'hA008, 1,0,0,BR_Z);
        step("JZ does not auto-jump",  0,0,0,8'hA5, 8'h04,16'hA008, 1,0,0,BR_Z);
        step("external PC load -> SUB",0,1,0,8'h05, 8'h05,16'h4100, 1,1,1,BR_NONE);
        check_detail("SUB ALU selector",ALU_SUB,WB_ALU);
        step("jump -> AND",           0,1,0,8'h06, 8'h06,16'h5100, 1,1,1,BR_NONE);
        check_detail("AND ALU selector",ALU_AND,WB_ALU);
        step("jump -> XOR",           0,1,0,8'h07, 8'h07,16'h7100, 1,1,1,BR_NONE);
        check_detail("XOR ALU selector",ALU_XOR,WB_ALU);
        step("jump -> JMP 02",        0,1,0,8'h08, 8'h08,16'h9002, 1,0,0,BR_ALWAYS);
        step("JMP does not auto-jump", 0,0,0,8'h00, 8'h08,16'h9002, 1,0,0,BR_ALWAYS);
        step("jump -> MOV R2,R0",     0,1,0,8'h09, 8'h09,16'h2800, 1,1,0,BR_NONE);
        check_detail("MOV selects source register",ALU_ADD,WB_RS);
        step("jump -> JC",            0,1,0,8'h0A, 8'h0A,16'hC00C, 1,0,0,BR_C);
        step("jump -> JNC",           0,1,0,8'h0B, 8'h0B,16'hD00D, 1,0,0,BR_NC);
        step("jump -> JNZ",           0,1,0,8'h0C, 8'h0C,16'hB003, 1,0,0,BR_NZ);
        step("load beats increment",  0,1,1,8'h0D, 8'h0D,16'h6D00, 1,1,1,BR_NONE);
        check_detail("OR ALU selector",ALU_OR,WB_ALU);
        step("invalid opcode E",      0,1,0,8'h0E, 8'h0E,16'hE000, 0,0,0,BR_NONE);
        step("invalid ADD payload",   0,1,0,8'h0F, 8'h0F,16'h3101, 0,0,0,BR_NONE);
        step("NOP",                   0,1,0,8'h10, 8'h10,16'h0000, 1,0,0,BR_NONE);
        step("jump to FE",            0,1,0,8'hFE, 8'hFE,16'h0000, 1,0,0,BR_NONE);
        step("increment FE to FF",    0,0,1,8'h00, 8'hFF,16'h0000, 1,0,0,BR_NONE);
        step("wrap FF to 00",         0,0,1,8'h00, 8'h00,16'h1005, 1,1,0,BR_NONE);
        step("reset wins over load",  1,1,1,8'h0A, 8'h00,16'h1005, 1,1,0,BR_NONE);
        step("load 05 before sync reset",0,1,0,8'h05,8'h05,16'h4100,1,1,1,BR_NONE);

        @(negedge clk);
        reset = 1'b1;
        load = 1'b0;
        enable = 1'b0;
        #1;
        check_state("synchronous reset not immediate",8'h05,16'h4100,1,1,1,BR_NONE);
        @(posedge clk);
        #1;
        check_state("synchronous reset at edge",8'h00,16'h1005,1,1,0,BR_NONE);
        step("resume increment",0,0,1,8'h00,8'h01,16'h1403,1,1,0,BR_NONE);

        $display("ALL %0d INSTRUCTION FETCH+DECODE CHECKS PASSED",passed);
        $finish;
    end
endmodule
