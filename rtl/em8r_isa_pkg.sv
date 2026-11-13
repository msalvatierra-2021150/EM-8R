// EM-8R ISA v0.1: shared symbolic codes for the instruction decoder.
// Instruction bits: [15:12] opcode, [11:10] Rd, [9:8] Rs, [7:0] imm/target.
// Register operations require [7:0] = 0; MOVI requires [9:8] = 0;
// branches require [11:8] = 0; NOP requires [11:0] = 0.
package em8r_isa_pkg;
    localparam logic [3:0] OP_NOP  = 4'h0;
    localparam logic [3:0] OP_MOVI = 4'h1;
    localparam logic [3:0] OP_MOV  = 4'h2;
    localparam logic [3:0] OP_ADD  = 4'h3;
    localparam logic [3:0] OP_SUB  = 4'h4;
    localparam logic [3:0] OP_AND  = 4'h5;
    localparam logic [3:0] OP_OR   = 4'h6;
    localparam logic [3:0] OP_XOR  = 4'h7;
    localparam logic [3:0] OP_CMP  = 4'h8;
    localparam logic [3:0] OP_JMP  = 4'h9;
    localparam logic [3:0] OP_JZ   = 4'hA;
    localparam logic [3:0] OP_JNZ  = 4'hB;
    localparam logic [3:0] OP_JC   = 4'hC;
    localparam logic [3:0] OP_JNC  = 4'hD;
    // E and F are reserved/illegal.

    // These MUST match existing rtl/alu.sv internal 3-bit selector codes.
    localparam logic [2:0] ALU_ADD = 3'b000;
    localparam logic [2:0] ALU_SUB = 3'b001;
    localparam logic [2:0] ALU_AND = 3'b010;
    localparam logic [2:0] ALU_OR  = 3'b011;
    localparam logic [2:0] ALU_XOR = 3'b100;

    // Select what data will eventually be written back to Rd.
    localparam logic [1:0] WB_ALU = 2'b00;
    localparam logic [1:0] WB_RS  = 2'b01;
    localparam logic [1:0] WB_IMM = 2'b10;

    // Branch request type, NOT a branch decision. Requires saved CPU flags.
    localparam logic [2:0] BR_NONE   = 3'b000;
    localparam logic [2:0] BR_ALWAYS = 3'b001;
    localparam logic [2:0] BR_Z      = 3'b010;
    localparam logic [2:0] BR_NZ     = 3'b011;
    localparam logic [2:0] BR_C      = 3'b100;
    localparam logic [2:0] BR_NC     = 3'b101;
endpackage
