// EM-8R CPU — ALU, version 0.1
// Purely combinational: no clock and no registers here.
// Input a and b are unsigned 8-bit bit patterns.
// Subtraction wraps to 8 bits; carry = 1 means NO borrow.
// Zero flag = 1 when the result is zero or carry = 1

module alu (
    input  logic [7:0] a,
    input  logic [7:0] b,
    input  logic [2:0] alu_op,
    output logic [7:0] result,
    output logic       zero,
    output logic       carry,
    output logic       negative
);

    // These are *internal ALU control codes*, not the ISA opcodes.
    localparam logic [2:0] ALU_ADD = 3'b000;
    localparam logic [2:0] ALU_SUB = 3'b001;
    localparam logic [2:0] ALU_AND = 3'b010;
    localparam logic [2:0] ALU_OR  = 3'b011;
    localparam logic [2:0] ALU_XOR = 3'b100;

    logic [8:0] sum9;  // Nine bits preserve the carry-out from addition.

    always_comb begin
        // Default values avoid inferred latches.
        sum9   = 9'd0;
        result = 8'd0;
        carry  = 1'b0;

        case (alu_op)
            ALU_ADD: begin
                sum9   = {1'b0, a} + {1'b0, b};
                result = sum9[7:0];
                carry  = sum9[8];
            end

            ALU_SUB: begin
                result = a - b;      // 8-bit wraparound
                carry  = (a >= b);  // No-borrow convention
            end

            ALU_AND: result = a & b;
            ALU_OR:  result = a | b;
            ALU_XOR: result = a ^ b;

            // 3'b101, 110, 111 are currently reserved.
            // The CPU decoder will reject invalid instructions separately.
            default: result = 8'd0;
        endcase

        // Derived from the completed 8-bit result.
        zero     = (result == 8'd0);
        negative = result[7];
    end

endmodule
