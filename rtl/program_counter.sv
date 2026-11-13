
module program_counter (
    input  logic       clk,
    input  logic       reset,
    input  logic       load,
    input  logic       enable,
    input  logic [7:0] jump_addr,
    output logic [7:0] pc
);

    always_ff @(posedge clk) begin
        if (reset)
            pc <= 8'h00;
        else if (load)
            pc <= jump_addr;
        else if (enable)
            pc <= pc + 8'd1;
    end

endmodule
