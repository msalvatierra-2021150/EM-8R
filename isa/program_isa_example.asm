; EM-8R ISA v0.1 DEMONSTRATION PROGRAM for fetch/decode only.
; Each line is one 16-bit word at the corresponding ROM address.
; The control unit is NOT connected yet, so branches in ROM won't execute.
; Address  Hex   Assembly / comment
; 00       1005
MOVI R0, #0x05
; 01       1403
MOVI R1, #0x03
; 02       3100
ADD  R0, R1
; 03       8100
CMP  R0, R1
; 04       A008
JZ   0x08
; 05       4100
SUB  R0, R1
; 06       5100
AND  R0, R1
; 07       7100
XOR  R0, R1
; 08       9002
JMP  0x02
; 09       2800
MOV  R2, R0
; 0A       C00C
JC   0x0C
; 0B       D00D
JNC  0x0D
; 0C       B003
JNZ  0x03
; 0D       6D00
OR   R3, R1
; 0E, 0F contain deliberately invalid test patterns in the HEX image.
; Remaining addresses default to NOP (0000).
