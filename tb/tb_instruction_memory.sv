`timescale 1ns/1ps

// ================================================================
// EM-8R CPU - Standalone Instruction ROM Testbench
// ================================================================
module tb_instruction_memory;
    logic [7:0]  addr;
    logic [15:0] instruction;
    integer passed = 0;

    instruction_memory #(
        .INIT_FILE("mem/program_demo.hex")
    ) dut (
        .addr        (addr),
        .instruction (instruction)
    );

    // This task drives the ROM address and checks its output.
    // It needs no clock: the ROM has a combinational read port.
    task automatic check_word(
        input string       test_name,
        input logic [7:0]  address_value,
        input logic [15:0] expected_word
    );
        addr = address_value;
        #1;  // Allow combinational output to settle.
        if (instruction !== expected_word) begin
            $display("FAIL: %s (address 0x%02h)", test_name, addr);
            $display("  Got 0x%04h, expected 0x%04h", instruction, expected_word);
            $fatal(1, "Instruction memory test failed");
        end
        passed++;
        $display("PASS: %-35s addr=0x%02h instruction=0x%04h",
                 test_name, addr, instruction);
    endtask

    initial begin
        addr = 8'h00;
        #1;  // ROM initialization happens at simulation time 0.

        check_word("ROM word 0",             8'h00, 16'h1205);
        check_word("ROM word 1",             8'h01, 16'h3403);
        check_word("ROM word 2",             8'h02, 16'h5601);
        check_word("ROM word 3",             8'h03, 16'h7801);
        check_word("ROM word 4",             8'h04, 16'hABCD);
        check_word("ROM word 10",            8'h0A, 16'hCAFE);
        check_word("ROM word 15",            8'h0F, 16'hF00D);
        check_word("ROM word 32",            8'h20, 16'hDEAD);
        check_word("ROM word 128",           8'h80, 16'h8001);
        check_word("ROM word 165",           8'hA5, 16'hBEEF);
        check_word("ROM word 254",           8'hFE, 16'h55AA);
        check_word("ROM word 255",           8'hFF, 16'hAA55);
        check_word("zero-filled unused address", 8'h81, 16'h0000);
        check_word("address switches back",  8'h00, 16'h1205);

        $display("ALL %0d INSTRUCTION MEMORY TESTS PASSED", passed);
        $finish;
    end
endmodule
