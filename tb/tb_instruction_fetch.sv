`timescale 1ns/1ps

// ================================================================
// EM-8R CPU - PC + Instruction ROM Self-Checking Testbench
// ================================================================
module tb_instruction_fetch;
    logic clk = 1'b0;
    logic reset;
    logic load;
    logic enable;
    logic [7:0] jump_addr;
    logic [7:0] pc;
    logic [15:0] instruction;
    integer passed = 0;

    // Rising edges at 5, 15, 25, ... ns.
    always #5 clk = ~clk;

    instruction_fetch #(
        .INIT_FILE("mem/program_demo.hex")
    ) dut (
        .clk         (clk),
        .reset       (reset),
        .load        (load),
        .enable      (enable),
        .jump_addr   (jump_addr),
        .pc          (pc),
        .instruction (instruction)
    );

    // The PC and ROM word must match in the same observation.
    task automatic check_fetch(
        input string       test_name,
        input logic [7:0]  expected_pc,
        input logic [15:0] expected_instruction
    );
        if (pc !== expected_pc || instruction !== expected_instruction) begin
            $display("FAIL: %s", test_name);
            $display("  PC:          got 0x%02h, expected 0x%02h", pc, expected_pc);
            $display("  Instruction: got 0x%04h, expected 0x%04h",
                     instruction, expected_instruction);
            $fatal(1, "Instruction fetch test failed");
        end
        passed++;
        $display("PASS: %-43s PC=0x%02h instruction=0x%04h",
                 test_name, pc, instruction);
    endtask

    // Set controls BEFORE the active rising edge, then verify both
    // the sequential PC and the combinational memory output.
    task automatic step(
        input string       test_name,
        input logic        rst,
        input logic        ld,
        input logic        en,
        input logic [7:0]  target,
        input logic [7:0]  expected_pc,
        input logic [15:0] expected_instruction
    );
        @(negedge clk);
        reset     = rst;
        load      = ld;
        enable    = en;
        jump_addr = target;

        @(posedge clk);
        #1;  // Wait for PC's <= update and ROM propagation.
        check_fetch(test_name, expected_pc, expected_instruction);
    endtask

    initial begin
        reset     = 1'b0;
        load      = 1'b0;
        enable    = 1'b0;
        jump_addr = 8'h00;

        // 1. PC reset makes ROM address 0 visible at instruction.
        step("reset fetches word at 00",       1,0,0,8'h00, 8'h00,16'h1205);

        // 2-4. Sequential changes select consecutive ROM words.
        step("increment fetches 01",         0,0,1,8'h00, 8'h01,16'h3403);
        step("increment fetches 02",         0,0,1,8'h00, 8'h02,16'h5601);
        step("increment fetches 03",         0,0,1,8'h00, 8'h03,16'h7801);

        // 5-7. Holding freezes the PC and its selected ROM word.
        step("hold address 03",              0,0,0,8'h00, 8'h03,16'h7801);
        step("load 0A fetches CAFE",         0,1,0,8'h0A, 8'h0A,16'hCAFE);
        step("target changes, load=0",       0,0,0,8'h80, 8'h0A,16'hCAFE);

        // 8-10. Jump selects a distant word; next address may be 0.
        step("load 80 fetches 8001",         0,1,0,8'h80, 8'h80,16'h8001);
        step("increment fetches unused 81",  0,0,1,8'h00, 8'h81,16'h0000);
        step("load A5 fetches BEEF",         0,1,0,8'hA5, 8'hA5,16'hBEEF);

        // 11-13. PC control-signal priority still applies.
        step("load wins over enable",        0,1,1,8'h0F, 8'h0F,16'hF00D);
        step("increment from 0F to 10",      0,0,1,8'h00, 8'h10,16'h0000);
        step("reset wins over load+enable",  1,1,1,8'hFF, 8'h00,16'h1205);

        // 14-17. 8-bit PC wraps from FF to 00.
        step("load FE fetches 55AA",         0,1,0,8'hFE, 8'hFE,16'h55AA);
        step("increment FF fetches AA55",    0,0,1,8'h00, 8'hFF,16'hAA55);
        step("wrap FF to 00",                0,0,1,8'h00, 8'h00,16'h1205);
        step("hold after wrap",              0,0,0,8'h00, 8'h00,16'h1205);

        // 18-20. Another jump and an unassigned (zero-filled) word.
        step("load 20 fetches DEAD",         0,1,0,8'h20, 8'h20,16'hDEAD);
        step("hold address 20",              0,0,0,8'h00, 8'h20,16'hDEAD);
        step("increment 21 fetches zero",    0,0,1,8'h00, 8'h21,16'h0000);

        // 21-22. Synchronous reset must NOT change the PC until
        // the next rising edge, so the ROM word must remain the same.
        @(negedge clk);
        reset     = 1'b1;
        load      = 1'b0;
        enable    = 1'b0;
        jump_addr = 8'hA5;  // ignored because load=0
        #1;
        check_fetch("reset before edge keeps 21", 8'h21,16'h0000);

        @(posedge clk);
        #1;
        check_fetch("reset edge fetches 00", 8'h00,16'h1205);

        // 23. Resume ordinary sequential fetch.
        step("resume after reset",           0,0,1,8'h00, 8'h01,16'h3403);

        $display("ALL %0d INSTRUCTION FETCH TESTS PASSED", passed);
        $finish;
    end
endmodule
