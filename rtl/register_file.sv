// EM-8R CPU - 4 x 8-bit register file, version 0.1
// Two asynchronous read ports and one synchronous write port.
// All four registers (R0-R3) are general purpose.
module register_file (
    input  logic       clk,
    input  logic       reset,
    input  logic       write_enable,
    input  logic [1:0] read_addr_a,
    input  logic [1:0] read_addr_b,
    input  logic [1:0] write_addr,
    input  logic [7:0] write_data,
    output logic [7:0] read_data_a,
    output logic [7:0] read_data_b
);
    logic [7:0] regs [0:3];

    // Writes happen on the rising edge of the CPU clock.
    // Synchronous reset takes priority over a write.
    always_ff @(posedge clk) begin
        if (reset) begin
            for (int i = 0; i < 4; i++) begin
                regs[i] <= 8'h00;
            end
        end else if (write_enable) begin
            regs[write_addr] <= write_data;
        end
    end

    // Independent combinational read ports.
    assign read_data_a = regs[read_addr_a];
    assign read_data_b = regs[read_addr_b];
endmodule
