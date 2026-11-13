`timescale 1ns/1ps

// ================================================================
// EM-8R CPU - Self-checking program-counter testbench
// ================================================================
module tb_program_counter;
    logic clk = 1'b0;
    logic reset;
    logic load;
    logic enable;
    logic [7:0] jump_addr;
    logic [7:0] pc;
    integer passed = 0;

    // 10-ns clock period: positive edges at 5, 15, 25, ... ns.
    always #5 clk = ~clk;

    program_counter dut (
        .clk(clk),
        .reset(reset),
        .load(load),
        .enable(enable),
        .jump_addr(jump_addr),
        .pc(pc)
    );

    // Check the output only. This task does NOT change the PC.
    task automatic check_pc(
        input string label_text,
        input logic [7:0] expected_pc
    );
        if (pc !== expected_pc) begin
            $display("FAIL: %s", label_text);
            $display("  Actual PC = 0x%02h, expected = 0x%02h", pc, expected_pc);
            $fatal(1, "Program counter test failed");
        end
        passed++;
        $display("PASS: %-49s PC = 0x%02h", label_text, pc);
    endtask

    // Drive inputs on a falling edge and verify the state after the
    // NEXT rising edge. #1 avoids a race with the nonblocking <= update.
    task automatic step(
        input string label_text,
        input logic reset_value,
        input logic load_value,
        input logic enable_value,
        input logic [7:0] address_value,
        input logic [7:0] expected_pc
    );
        @(negedge clk);
        reset     = reset_value;
        load      = load_value;
        enable    = enable_value;
        jump_addr = address_value;

        @(posedge clk);
        #1;
        check_pc(label_text, expected_pc);
    endtask

    initial begin
        reset     = 1'b0;
        load      = 1'b0;
        enable    = 1'b0;
        jump_addr = 8'h00;

        // 1. Synchronous reset starts the PC at address 0.
        step("reset clears PC",              1, 0, 0, 8'h00, 8'h00);

        // 2-3. Sequential instruction fetch: PC increments by 1.
        step("increment 00 to 01",           0, 0, 1, 8'h00, 8'h01);
        step("increment 01 to 02",           0, 0, 1, 8'h00, 8'h02);

        // 4-5. When enable=0 and load=0, the current address is held.
        step("hold when enable is low",     0, 0, 0, 8'h00, 8'h02);
        step("hold ignores jump_addr",      0, 0, 0, 8'hE0, 8'h02);

        // 6-7. A jump loads the given address; then normal fetch resumes.
        step("load jump address A5",        0, 1, 0, 8'hA5, 8'hA5);
        step("increment after jump",        0, 0, 1, 8'h00, 8'hA6);

        // 8-9. load has higher priority than enable.
        step("load wins over increment",    0, 1, 1, 8'h33, 8'h33);
        step("hold after jump",             0, 0, 0, 8'h00, 8'h33);

        // 10. reset has higher priority than load or increment.
        step("reset wins over load/enable", 1, 1, 1, 8'hFE, 8'h00);

        // 11-14. Check rollover at 8'hFF (8-bit modular arithmetic).
        step("jump to FE",                 0, 1, 0, 8'hFE, 8'hFE);
        step("increment FE to FF",          0, 0, 1, 8'h00, 8'hFF);
        step("wrap around FF to 00",        0, 0, 1, 8'h00, 8'h00);
        step("hold at zero after wrap",     0, 0, 0, 8'h00, 8'h00);

        // 15. Set a nonzero PC to demonstrate synchronous reset.
        step("load 5A before timing test",  0, 1, 0, 8'h5A, 8'h5A);

        // 16. Asserting reset between edges must NOT immediately clear PC.
        @(negedge clk);
        reset     = 1'b1;
        load      = 1'b0;
        enable    = 1'b0;
        jump_addr = 8'h00;
        #1;
        check_pc("sync reset unchanged before rising edge", 8'h5A);

        // 17. PC resets only when the clock reaches the next rising edge.
        @(posedge clk);
        #1;
        check_pc("sync reset takes effect on rising edge", 8'h00);

        // 18. PC returns to normal operation after reset is released.
        step("increment after releasing reset", 0, 0, 1, 8'h00, 8'h01);

        $display("ALL %0d PROGRAM COUNTER TESTS PASSED", passed);
        $finish;
    end
endmodule
