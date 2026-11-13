// ================================================================
// EM-8R CPU - Instruction Memory (ROM), version 0.1
// ================================================================
// A simple 256 x 16-bit read-only instruction memory.
//   - addr selects ONE 16-bit word (word-addressed).
//   - Reading is combinational: no clock input is required.
//   - ROM contents are initialized from mem/program_demo.hex.
//
// The 16-bit word size is PROVISIONAL. The HEX words are example
// patterns for verifying instruction fetch, NOT a finalized ISA.
//
// For initial simulation, run Questa from the project root so the
// relative path in INIT_FILE resolves correctly.
// FPGA optimization note: a synchronous ROM interface may be needed
// later for efficient embedded block-RAM inference.
module instruction_memory #(
    parameter INIT_FILE = "mem/program_demo.hex"
) (
    input  logic [7:0]  addr,
    output logic [15:0] instruction
);

    // 2^8 = 256 addressable instruction words, 16 bits each.
    logic [15:0] rom [0:255];

    // Supported by Questa simulation; Quartus can use initialized
    // memories, but resource inference may vary with ROM read style.
    initial begin
        $readmemh(INIT_FILE, rom);
    end

    // Similar to a register file's combinational read selector.
    assign instruction = rom[addr];

endmodule
