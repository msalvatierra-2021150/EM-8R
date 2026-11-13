`timescale 1ns/1ps

// EM-8R CPU - self-checking register file testbench.
module tb_register_file;
    logic clk = 1'b0;
    logic reset;
    logic write_enable;
    logic [1:0] read_addr_a, read_addr_b, write_addr;
    logic [7:0] write_data;
    logic [7:0] read_data_a, read_data_b;
    integer passed = 0;

    // 10 ns clock period.
    always #5 clk = ~clk;

    register_file dut (
        .clk(clk),
        .reset(reset),
        .write_enable(write_enable),
        .read_addr_a(read_addr_a),
        .read_addr_b(read_addr_b),
        .write_addr(write_addr),
        .write_data(write_data),
        .read_data_a(read_data_a),
        .read_data_b(read_data_b)
    );

    task automatic check_pair(
        input string label_text,
        input logic [1:0] addr_a,
        input logic [1:0] addr_b,
        input logic [7:0] expected_a,
        input logic [7:0] expected_b
    );
        read_addr_a = addr_a;
        read_addr_b = addr_b;
        #1;  // Let asynchronous read outputs settle.
        if ({read_data_a, read_data_b} !== {expected_a, expected_b}) begin
            $display("FAIL: %s", label_text);
            $display("  read R%0d=%h (expected %h), R%0d=%h (expected %h)",
                     addr_a, read_data_a, expected_a,
                     addr_b, read_data_b, expected_b);
            $fatal(1, "Register file test failed");
        end
        passed++;
        $display("PASS: %s", label_text);
    endtask

    task automatic write_reg(
        input logic [1:0] addr,
        input logic [7:0] data_value
    );
        @(negedge clk);
        write_enable = 1'b1;
        write_addr = addr;
        write_data = data_value;
        @(posedge clk);
        #1;
        write_enable = 1'b0;
    endtask

    initial begin
        reset = 1'b1;
        write_enable = 1'b0;
        read_addr_a = 2'd0;
        read_addr_b = 2'd0;
        write_addr = 2'd0;
        write_data = 8'd0;

        // 1. A synchronous reset clears each of the four registers.
        @(posedge clk);
        #1;
        reset = 1'b0;
        check_pair("reset clears R0 and R1", 0, 1, 8'h00, 8'h00);
        check_pair("reset clears R2 and R3", 2, 3, 8'h00, 8'h00);

        // 2. Each of the four addresses is writable and readable.
        write_reg(0, 8'h12);
        check_pair("write R0", 0, 1, 8'h12, 8'h00);
        write_reg(1, 8'h34);
        check_pair("write R1", 1, 0, 8'h34, 8'h12);
        write_reg(2, 8'h56);
        check_pair("write R2", 2, 1, 8'h56, 8'h34);
        write_reg(3, 8'h78);
        check_pair("write R3", 3, 2, 8'h78, 8'h56);

        // 3. Both read ports can access different registers at once.
        check_pair("two independent read ports", 0, 3, 8'h12, 8'h78);

        // 4. With write_enable low, no write may occur.
        @(negedge clk);
        write_enable = 1'b0;
        write_addr = 2'd2;
        write_data = 8'hFF;
        @(posedge clk);
        #1;
        check_pair("write disabled: R2 unchanged", 2, 3, 8'h56, 8'h78);

        // 5. On a write to an address being read, the old value is
        //    visible before the rising edge, the new value after it.
        @(negedge clk);
        write_enable = 1'b1;
        write_addr = 2'd1;
        write_data = 8'hA5;
        check_pair("before edge: R1 still old", 1, 2, 8'h34, 8'h56);
        @(posedge clk);
        #1;
        write_enable = 1'b0;
        check_pair("after edge: R1 updated", 1, 2, 8'hA5, 8'h56);

        // 6. Reset has priority over writing.
        @(negedge clk);
        reset = 1'b1;
        write_enable = 1'b1;
        write_addr = 2'd2;
        write_data = 8'hEE;
        @(posedge clk);
        #1;
        reset = 1'b0;
        write_enable = 1'b0;
        check_pair("reset priority R0/R1", 0, 1, 8'h00, 8'h00);
        check_pair("reset priority R2/R3", 2, 3, 8'h00, 8'h00);

        $display("ALL %0d REGISTER FILE TESTS PASSED", passed);
        $finish;
    end
endmodule
