`timescale 1ns/1ps
// EM-8R: self-checking execution/writeback datapath testbench.
// The instruction and execute_enable are driven on falling edges, then the
// testbench checks combinational data BEFORE the rising writeback edge.
// This is essential: after the edge, ALU inputs may change due to writeback.
module tb_execution_datapath;
    import em8r_isa_pkg::*;

    logic clk = 1'b0;
    always #5 clk = ~clk;

    logic reset = 1'b1;
    logic execute_enable = 1'b0;
    logic [15:0] instruction = 16'h0000;

    logic [1:0] rd_addr, rs_addr;
    logic [7:0] read_data_a, read_data_b;
    logic [7:0] alu_result, writeback_data;
    logic alu_zero, alu_carry, alu_negative;
    logic valid, reg_write, flag_write;
    logic [2:0] alu_op, branch_type;
    logic [1:0] writeback_sel;
    logic [7:0] branch_addr;
    integer passed = 0;

    execution_datapath dut (
        .clk(clk), .reset(reset), .execute_enable(execute_enable),
        .instruction(instruction),
        .rd_addr(rd_addr), .rs_addr(rs_addr),
        .read_data_a(read_data_a), .read_data_b(read_data_b),
        .alu_result(alu_result), .writeback_data(writeback_data),
        .alu_zero(alu_zero), .alu_carry(alu_carry),
        .alu_negative(alu_negative),
        .valid(valid), .reg_write(reg_write), .flag_write(flag_write),
        .alu_op(alu_op), .writeback_sel(writeback_sel),
        .branch_type(branch_type), .branch_addr(branch_addr)
    );

    // Probe two registers without writing. Use an ADD instruction only to
    // select Rd/Rs read ports; execute_enable=0 prevents its writeback.
    task automatic peek_pair(
        input string label_text,
        input logic [1:0] a_addr,
        input logic [1:0] b_addr,
        input logic [7:0] expected_a,
        input logic [7:0] expected_b
    );
        @(negedge clk);
        execute_enable = 1'b0;
        instruction = {OP_ADD, a_addr, b_addr, 8'h00};
        #1;
        if ({read_data_a, read_data_b, reg_write, flag_write} !==
            {expected_a, expected_b, 1'b0, 1'b0}) begin
            $display("FAIL %-38s R%0d=%02h (expected %02h), R%0d=%02h (expected %02h)",
                     label_text, a_addr, read_data_a, expected_a,
                     b_addr, read_data_b, expected_b);
            $fatal(1, "Register read / hold mismatch");
        end
        passed++;
        $display("PASS %-38s R%0d=%02h R%0d=%02h", label_text,
                 a_addr, read_data_a, b_addr, read_data_b);
    endtask

    // Commit one instruction and verify requested write, pre-edge ALU flags,
    // and the destination register value AFTER the clock edge.
    task automatic issue_and_check(
        input string label_text,
        input logic [15:0] word,
        input logic exp_valid,
        input logic exp_reg_write,
        input logic exp_flag_write,
        input logic [7:0] exp_rd_after,
        input bit verify_wb,
        input logic [7:0] exp_wb,
        input bit verify_flags,
        input logic [2:0] exp_flags // {Z,C,N}, sampled BEFORE writeback
    );
        @(negedge clk);
        instruction = word;
        execute_enable = 1'b1;
        reset = 1'b0;
        #1;

        if ({valid, reg_write, flag_write} !==
            {exp_valid, exp_reg_write, exp_flag_write}) begin
            $display("FAIL %s: control got %b%b%b expected %b%b%b",
                label_text, valid, reg_write, flag_write,
                exp_valid, exp_reg_write, exp_flag_write);
            $fatal(1, "Control mismatch");
        end
        if (verify_wb && writeback_data !== exp_wb) begin
            $display("FAIL %s: writeback got %02h expected %02h",
                     label_text, writeback_data, exp_wb);
            $fatal(1, "Writeback mux mismatch");
        end
        if (verify_flags && {alu_zero, alu_carry, alu_negative} !== exp_flags) begin
            $display("FAIL %s: ALU ZCN got %b%b%b expected %b",
                     label_text, alu_zero, alu_carry, alu_negative, exp_flags);
            $fatal(1, "Pre-edge flags mismatch");
        end

        @(posedge clk);
        #1;  // Allow nonblocking register write and read-bus update to settle.
        if (read_data_a !== exp_rd_after) begin
            $display("FAIL %s: R%0d after edge got %02h expected %02h",
                     label_text, rd_addr, read_data_a, exp_rd_after);
            $fatal(1, "Register writeback mismatch");
        end
        execute_enable = 1'b0; // Prevent another write on the next edge.
        passed++;
        $display("PASS %-38s word=%04h Rd=R%0d after=%02h",
                 label_text, word, rd_addr, read_data_a);
    endtask

    // An instruction can be visible on the input bus without being committed.
    task automatic skip_and_check(
        input string label_text,
        input logic [15:0] word,
        input logic [7:0] expected_rd
    );
        @(negedge clk);
        instruction = word;
        execute_enable = 1'b0;
        #1;
        if (reg_write !== 1'b0 || flag_write !== 1'b0)
            $fatal(1, "Disabled instruction requested a write");
        @(posedge clk);
        #1;
        if (read_data_a !== expected_rd)
            $fatal(1, "Disabled instruction modified its Rd");
        passed++;
        $display("PASS %-38s word=%04h", label_text, word);
    endtask

    initial begin
        // Initially reset the complete register file. Reset is synchronous.
        @(posedge clk);
        #1;
        reset = 1'b0;
        peek_pair("reset R0 and R1", 2'd0, 2'd1, 8'h00, 8'h00);
        peek_pair("reset R2 and R3", 2'd2, 2'd3, 8'h00, 8'h00);

        // MOVI/MOV: writeback MUX picks immediate or Rs, no flags written.
        issue_and_check("MOVI R0,#05", 16'h1005, 1,1,0, 8'h05, 1,8'h05, 0,3'b000);
        issue_and_check("MOVI R1,#03", 16'h1403, 1,1,0, 8'h03, 1,8'h03, 0,3'b000);
        peek_pair("independent R0/R1 values", 0,1, 8'h05,8'h03);

        // Arithmetic: A = old Rd, B = old Rs.
        issue_and_check("ADD R0,R1 05+03=08", 16'h3100, 1,1,1, 8'h08, 1,8'h08, 1,3'b000);
        issue_and_check("SUB R0,R1 08-03=05", 16'h4100, 1,1,1, 8'h05, 1,8'h05, 1,3'b010);
        peek_pair("SUB does not modify R1", 0,1, 8'h05,8'h03);

        // MOV R2,R0 must select source B, rather than the ALU result.
        issue_and_check("MOV R2,R0 copies 05", 16'h2800, 1,1,0, 8'h05, 1,8'h05, 0,3'b000);
        issue_and_check("AND R2,R1 05&03=01", 16'h5900, 1,1,1, 8'h01, 1,8'h01, 1,3'b000);
        issue_and_check("OR R2,R0 01|05=05",  16'h6800, 1,1,1, 8'h05, 1,8'h05, 1,3'b000);
        issue_and_check("XOR R2,R0 05^05=00", 16'h7800, 1,1,1, 8'h00, 1,8'h00, 1,3'b100);
        peek_pair("logical ops preserve R0/R1", 0,1, 8'h05,8'h03);

        // CMP changes combinational flag outputs, NOT any register.
        issue_and_check("CMP R0,R1 no borrow", 16'h8100, 1,0,1, 8'h05, 1,8'h02, 1,3'b010);
        issue_and_check("CMP R1,R0 borrow",    16'h8400, 1,0,1, 8'h03, 1,8'hFE, 1,3'b001);
        peek_pair("CMP left values untouched", 0,1, 8'h05,8'h03);

        // Carry, zero and negative: flags are inspected BEFORE the write edge.
        issue_and_check("MOVI R3,#FF", 16'h1CFF, 1,1,0, 8'hFF, 1,8'hFF, 0,3'b000);
        issue_and_check("MOVI R0,#01", 16'h1001, 1,1,0, 8'h01, 1,8'h01, 0,3'b000);
        issue_and_check("ADD FF+01 wraps to 00", 16'h3C00, 1,1,1, 8'h00, 1,8'h00, 1,3'b110);
        issue_and_check("MOVI R3,#80", 16'h1C80, 1,1,0, 8'h80, 1,8'h80, 0,3'b000);
        peek_pair("same register on A and B", 3,3, 8'h80,8'h80);
        issue_and_check("ADD R3,R3 80+80=00", 16'h3F00, 1,1,1, 8'h00, 1,8'h00, 1,3'b110);
        issue_and_check("MOVI R3,#80 again", 16'h1C80, 1,1,0, 8'h80, 1,8'h80, 0,3'b000);
        issue_and_check("OR R3,R0 80|01=81", 16'h6C00, 1,1,1, 8'h81, 1,8'h81, 1,3'b001);
        issue_and_check("MOVI R0,#00", 16'h1000, 1,1,0, 8'h00, 1,8'h00, 0,3'b000);
        issue_and_check("SUB R0,R1 00-03=FD", 16'h4100, 1,1,1, 8'hFD, 1,8'hFD, 1,3'b001);

        // Committing is explicit. Disabled instructions must not modify state.
        issue_and_check("MOVI R0,#09", 16'h1009, 1,1,0, 8'h09, 1,8'h09, 0,3'b000);
        issue_and_check("MOVI R1,#03 again", 16'h1403, 1,1,0, 8'h03, 1,8'h03, 0,3'b000);
        skip_and_check("disabled MOVI R1,#EE", 16'h14EE, 8'h03);
        skip_and_check("disabled CMP R0,R1",  16'h8100, 8'h09);
        peek_pair("disabled instructions do nothing", 0,1, 8'h09,8'h03);

        // Invalid words and branch instructions must not write registers/flags.
        issue_and_check("invalid ADD immediate", 16'h3101, 0,0,0, 8'h09, 0,8'h00, 0,3'b000);
        issue_and_check("invalid opcode E", 16'hE400, 0,0,0, 8'h03, 0,8'h00, 0,3'b000);
        issue_and_check("NOP preserves R0", 16'h0000, 1,0,0, 8'h09, 0,8'h00, 0,3'b000);
        issue_and_check("JMP decodes without writing", 16'h9002, 1,0,0, 8'h09, 0,8'h00, 0,3'b000);
        if (branch_type !== BR_ALWAYS || branch_addr !== 8'h02)
            $fatal(1, "JMP branch request not decoded correctly");
        passed++;
        $display("PASS JMP branch type/target request");
        issue_and_check("JZ decodes without writing", 16'hA008, 1,0,0, 8'h09, 0,8'h00, 0,3'b000);
        if (branch_type !== BR_Z || branch_addr !== 8'h08)
            $fatal(1, "JZ branch request not decoded correctly");
        passed++;
        $display("PASS JZ branch type/target request");
        peek_pair("invalid/branches preserved R0/R1", 0,1, 8'h09,8'h03);
        peek_pair("invalid/branches preserved R2/R3", 2,3, 8'h00,8'h81);

        // Reset overrides a would-be enabled MOVI write at the same edge.
        @(negedge clk);
        instruction = 16'h10FF; // MOVI R0,#FF
        execute_enable = 1'b1;
        reset = 1'b1;
        #1;
        if (reg_write !== 1'b0 || flag_write !== 1'b0)
            $fatal(1, "Reset failed to mask writes");
        @(posedge clk);
        #1;
        if (read_data_a !== 8'h00)
            $fatal(1, "Reset failed to clear R0");
        execute_enable = 1'b0;
        reset = 1'b0;
        passed++;
        $display("PASS synchronous reset priority over MOVI");
        peek_pair("final reset R0/R1", 0,1, 8'h00,8'h00);
        peek_pair("final reset R2/R3", 2,3, 8'h00,8'h00);

        $display("ALL %0d EXECUTION DATAPATH CHECKS PASSED", passed);
        $finish;
    end
endmodule
