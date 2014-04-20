/*
 * Defines
 *
 *
 */
`default_nettype none

/* Sizes */
`define HUB_MAX_COGS 	4 // number of COGS supported by the HUB
`define MEM_WIDTH 		9 // WIDTH of the address field in COG
`define HUB_MEM_WIDTH  17 // WIDTH of the HUB address field

/* COG state machine states */
`define ST_FETCH 			2'h0
`define ST_DECODE 		2'h1
`define ST_READ			2'h2
`define ST_WBACK			3'h3
/* Bitfields in opcode */
`define OP_CCCC		21:18
`define OP_Z		25
`define OP_C		24
`define OP_R		23
`define OP_I		22

/* Opcodes */
`define R_PAR		9'h1f0
`define R_CNT		9'h1f1
`define R_INA		9'h1f2
`define R_INB		9'h1f3
`define R_DIRA		9'h1f4
`define R_DIRB		9'h1f5
`define R_OUTA		9'h1f6
`define R_OUTB		9'h1f7
`define R_CTRA		9'h1f8
`define R_CTRB		9'h1f9
`define R_FREQA		9'h1fa
`define R_FREQB		9'h1fb
`define R_PSHA		9'h1fc
`define R_PSHB		9'h1fd
`define R_VCFG		9'h1fe
`define R_VSCL		9'h1ff


`define I_RDBYTE	6'b000000
`define I_RDWORD	6'b000001
`define I_RDLONG	6'b000010
`define I_HUBOP		6'b000011
`define I_UNDEF0	6'b000100
`define I_UNDEF1	6'b000101
`define I_UNDEF2	6'b000110
`define I_UNDEF3	6'b000111
`define I_MUL       6'b000100
`define I_MULS      6'b000101

`define I_ROR		6'b001000
`define I_ROL		6'b001001
`define I_SHR		6'b001010
`define I_SHL		6'b001011
`define I_RCR		6'b001100
`define I_RCL		6'b001101
`define I_SAR		6'b001110
`define I_REV		6'b001111

`define I_MINS		6'b010000
`define I_MAXS		6'b010001
`define I_MIN		6'b010010
`define I_MAX		6'b010011
`define I_MOVS		6'b010100
`define I_MOVD		6'b010101
`define I_MOVI		6'b010110
`define I_JMPRET	6'b010111
`define I_JMP		6'b010111

`define I_AND		6'b011000
`define I_ANDN		6'b011001
`define I_OR		6'b011010
`define I_XOR		6'b011011
`define I_MUXC		6'b011100
`define I_MUXNC		6'b011101
`define I_MUXNZ		6'b011111
`define I_MUXZ		6'b011110

`define I_ADD		6'b100000
`define I_SUB		6'b100001
`define I_ADDABS	6'b100010
`define I_SUBABS	6'b100011
`define I_SUMC		6'b100100
`define I_SUMNC		6'b100101
`define I_SUMZ		6'b100110
`define I_SUMNZ		6'b100111

`define I_MOV		6'b101000
`define I_NEG		6'b101001
`define I_ABS		6'b101010
`define I_ABSNEG	6'b101011
`define I_NEGC		6'b101100
`define I_NEGZ		6'b101110
`define I_NEGNC		6'b101101
`define I_NEGNZ		6'b101111

`define I_CMPS		6'b110000
`define I_CMPSX		6'b110001
`define I_ADDX		6'b110010
`define I_SUBX		6'b110011
`define I_ADDS		6'b110100
`define I_SUBS		6'b110101
`define I_ADDSX		6'b110110
`define I_SUBSX		6'b110111

`define I_CMPSUB	6'b111000
`define I_DJNZ		6'b111001
`define I_TJNZ		6'b111010
`define I_TJZ		6'b111011
`define I_WAITPEQ	6'b111100
`define I_WAITPNE	6'b111101
`define I_WAITCNT	6'b111110
`define I_WAITVID	6'b111111

// to/from HUB sizes
`define SZ_BYTE		2'b00
`define SZ_WORD		2'b01
`define SZ_LONG		2'b10


