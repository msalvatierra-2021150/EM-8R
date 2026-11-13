# EM-8R Instruction Set Architecture (ISA) v0.1 — draft

This is the **first concrete encoding proposal** for our 8-bit, four-register CPU. It is designed to work with the 8-bit, word-addressed Program Counter and 256 × 16-bit instruction ROM already developed. Keep this document, the SystemVerilog decoder package, and the future Python assembler synchronized.

## General machine model

- Data: **8-bit** register values, R0–R3. Register codes: R0=`00`, R1=`01`, R2=`10`, R3=`11`.
- All instructions: **one 16-bit word**. ROM address `0x00` is the first instruction word, and `PC + 1` advances to the next 16-bit word.
- Instruction format: `[15:12] opcode | [11:10] Rd | [9:8] Rs | [7:0] imm8/absolute_address`.
- Literal immediates: unsigned 8-bit bit patterns, `0x00`–`0xFF`.
- Jump targets: **absolute 8-bit word addresses**, `0x00`–`0xFF`.
- R-type arithmetic: `Rd ← Rd op Rs`. The old Rd feeds ALU operand A and the old Rs feeds operand B. The result overwrites Rd.
- `CMP Rd, Rs` computes `Rd - Rs` to update flags, but does **not** write Rd.
- Flags `Z`, `C`, `N`: written by ADD, SUB, AND, OR, XOR, CMP; unchanged by NOP, MOVI, MOV, and jumps. Our existing ALU sets `C=1` on subtraction **when no borrow occurs**. (The decoder only asserts `flag_write`; a future flag register must latch actual ALU flags.)
- Current draft has **no signed-overflow V flag**, so signed comparisons are not fully covered.

## Opcode table

| Opcode | Assembly syntax | Meaning | Writes Rd? | Writes flags? | Branch request |
|---|---|---|---|---|---|
| `0` | `NOP` | No operation | No | No | None |
| `1` | `MOVI Rd, #imm8` | Load immediate to Rd | Yes | No | None |
| `2` | `MOV Rd, Rs` | Copy Rs to Rd | Yes | No | None |
| `3` | `ADD Rd, Rs` | Rd = Rd + Rs | Yes | Yes | None |
| `4` | `SUB Rd, Rs` | Rd = Rd - Rs | Yes | Yes | None |
| `5` | `AND Rd, Rs` | Rd = Rd & Rs | Yes | Yes | None |
| `6` | `OR Rd, Rs` | Rd = Rd \| Rs | Yes | Yes | None |
| `7` | `XOR Rd, Rs` | Rd = Rd ^ Rs | Yes | Yes | None |
| `8` | `CMP Rd, Rs` | Update flags as if Rd - Rs | No | Yes | None |
| `9` | `JMP addr` | Unconditional absolute jump | No | No | Always |
| `A` | `JZ addr` | Jump if saved Z=1 | No | No | Zero |
| `B` | `JNZ addr` | Jump if saved Z=0 | No | No | Nonzero |
| `C` | `JC addr` | Jump if saved C=1 | No | No | Carry |
| `D` | `JNC addr` | Jump if saved C=0 | No | No | No carry |
| `E`, `F` | — | Reserved/illegal | No | No | None |

## Canonical encoding rules (important)

- `NOP`: `[11:0] = 000`; therefore only `0000` is a legal NOP.
- `MOVI`: `Rs` bits `[9:8] = 00`, `imm8` holds the immediate.
- `MOV`, `ADD`, `SUB`, `AND`, `OR`, `XOR`, `CMP`: lower byte `[7:0] = 00` (register-register only).
- Jumps: all upper operand bits `[11:8] = 0000`, lower byte is the target address.
- Any instruction violating those constraints is `valid=0`. Decoder's side-effect controls are zero: `reg_write=0`, `flag_write=0`, `branch_type=BR_NONE`.
- `opcode`, `rd_addr`, `rs_addr`, `immediate` and `branch_addr` always display raw corresponding instruction bits, even for invalid words. These fields are only meaningful for instructions that use them.

## Example encodings

| Assembly | Binary (grouped 4–2–2–8) | Hex word |
|---|---|---|
| `NOP` | `0000 00 00 00000000` | `0000` |
| `MOVI R0, #0x05` | `0001 00 00 00000101` | `1005` |
| `MOVI R1, #0x03` | `0001 01 00 00000011` | `1403` |
| `ADD R0, R1` | `0011 00 01 00000000` | `3100` |
| `CMP R0, R1` | `1000 00 01 00000000` | `8100` |
| `JZ 0x08` | `1010 00 00 00001000` | `A008` |
| `JMP 0x02` | `1001 00 00 00000010` | `9002` |
| `MOV R2, R0` | `0010 10 00 00000000` | `2800` |
| `OR R3, R1` | `0110 11 01 00000000` | `6D00` |

## Important boundaries of this stage

The decoder has **no internal clock or state**. It does not read registers, execute ALU operations, choose whether a conditional branch is taken, or update the PC. It only exposes control signals.

- `branch_type=BR_Z` says this is a JZ instruction; it does **not** mean the jump has already been taken.
- Future control logic must use stored flag bits to decide whether to assert the PC's `load` input and select `branch_addr` as `jump_addr`.
- Future writeback logic selects ALU result, source-register B, or immediate based on `writeback_sel`, then asserts the register file's single write port on the correct edge.
- The sample ROM is designed for **fetch/decode tests**. Instructions in the file are NOT automatically executed in this stage.
- Later, if the FPGA uses synchronous block RAM instead of the current combinational ROM, we must adjust instruction timing and possibly add an instruction register/state machine.

## Safe integration order

1. Test `instruction_decoder` independently with 62 self-checks.
2. Test `instruction_fetch_decode` with the existing PC, memory and fetch modules (36 checks).
3. Connect Register File and ALU through operand/writeback multiplexers.
4. Add a stored flag register, branch condition logic, and the CPU control unit.
5. Implement assembler and complete CPU-level tests; revise ISA only deliberately.
