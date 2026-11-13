`timescale 1ns/1ps

// EM-8R CPU — self-checking ALU unit testbench.
// This is simulation-only code; it is not synthesized onto the FPGA.

//cd C:/FPGA/alu_cpu
//do sim/run_alu.do

module tb_alu;
    logic [7:0] a, b;
    logic [2:0] alu_op;
    logic [7:0] result;
    logic zero, carry, negative;
    integer passed = 0;

    localparam logic [2:0] ALU_ADD = 3'b000;
    localparam logic [2:0] ALU_SUB = 3'b001;
    localparam logic [2:0] ALU_AND = 3'b010;
    localparam logic [2:0] ALU_OR  = 3'b011;
    localparam logic [2:0] ALU_XOR = 3'b100;

    alu dut (
        .a(a), .b(b), .alu_op(alu_op),
        .result(result), .zero(zero),
        .carry(carry), .negative(negative)
    );

    task automatic check(
        input string label_text,
        input logic [2:0] op,
        input logic [7:0] left_value,
        input logic [7:0] right_value,
        input logic [7:0] expected_result,
        input logic expected_zero,
        input logic expected_carry,
        input logic expected_negative
    );
        begin
            a = left_value;
            b = right_value;
            alu_op = op;
            #1; // Wait for combinational signals to settle in simulation.

            if ({result, zero, carry, negative} !==
                {expected_result, expected_zero,
                 expected_carry, expected_negative}) begin
                $display("FAIL: %s", label_text);
                $display("  inputs: op=%b a=%h b=%h", op, a, b);
                $display("  expected: result=%h Z=%b C=%b N=%b",
                         expected_result, expected_zero,
                         expected_carry, expected_negative);
                $display("  observed: result=%h Z=%b C=%b N=%b",
                         result, zero, carry, negative);
                $fatal(1, "ALU test failed");
            end

            passed = passed + 1;
            $display("PASS: %s", label_text);
        end
    endtask

    initial begin
        //                 name                 op       a      b     result Z C N
        check("5 + 3 = 8",                  ALU_ADD, 8'd5,  8'd3,  8'd8,  0,0,0);
        check("255 + 1 wraps, carries",     ALU_ADD, 8'hFF, 8'h01, 8'h00, 1,1,0);
        check("127 + 1 sets negative bit", ALU_ADD, 8'h7F, 8'h01, 8'h80, 0,0,1);
        check("128 + 128 wraps, carries",  ALU_ADD, 8'h80, 8'h80, 8'h00, 1,1,0);

        check("9 - 3 = 6, no borrow",       ALU_SUB, 8'd9,  8'd3,  8'd6,  0,1,0);
        check("3 - 5 wraps, borrows",      ALU_SUB, 8'd3,  8'd5,  8'hFE, 0,0,1);
        check("3 - 3 = 0, no borrow",      ALU_SUB, 8'd3,  8'd3,  8'd0,  1,1,0);
        check("0 - 1 = 255, borrows",       ALU_SUB, 8'd0,  8'd1,  8'hFF, 0,0,1);

        check("AND can produce zero",      ALU_AND, 8'hF0, 8'h0F, 8'h00, 1,0,0);
        check("AND can set negative",      ALU_AND, 8'hF0, 8'h80, 8'h80, 0,0,1);
        check("OR combines bits",          ALU_OR,  8'h80, 8'h01, 8'h81, 0,0,1);
        check("XOR same inputs is zero",   ALU_XOR, 8'hFF, 8'hFF, 8'h00, 1,0,0);
        check("XOR different patterns",    ALU_XOR, 8'hAA, 8'h0F, 8'hA5, 0,0,1);

        $display("ALL %0d ALU TESTS PASSED", passed);
        $finish;
    end
endmodule
