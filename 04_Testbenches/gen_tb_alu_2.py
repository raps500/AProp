#!/usr/bin/python

header = '''/*
 * Testbench for the alu
 *
 */

`include "acog_alu.v"
module tb_alu();

reg clk, C, Z;
reg [31:0] S, D;
reg [8:0] pc_plus_1;
reg [5:0] opcode;
wire [31:0] alu_q;
wire alu_c;
wire alu_z;


acog_alu alu(
	.clk_in(clk),
	.opcode_in({opcode, 26'h0 }),
	.flag_c_in(C),
	.flag_z_in(Z),
	.s_in(S),
	.d_in(D),
	.pc_plus_1_in(pc_plus_1),
	.flag_c_o(alu_c),
	.flag_z_o(alu_z),
	.q_o(alu_q)
	);
	
initial
	begin
	$dumpfile("tb_alu.vcd");
	$dumpvars(0, tb_alu);
'''
	
ending = '    end\nendmodule\n'
opcodeList = [
'`I_RDBYTE','`I_RDWORD','`I_RDLONG','`I_HUBOP','`I_UNDEF0','`I_UNDEF1','`I_UNDEF2','`I_UNDEF3',
'`I_ROR','`I_ROL','`I_SHR','`I_SHL','`I_RCR','`I_RCL','`I_SAR','`I_REV',
'`I_MINS','`I_MAXS','`I_MIN	','`I_MAX','`I_MOVS','`I_MOVD','`I_MOVI','`I_JMPRET',
'`I_AND','`I_ANDN','`I_OR','`I_XOR','`I_MUXC','`I_MUXNC','`I_MUXNZ','`I_MUXZ',
'`I_ADD','`I_SUB','`I_ADDABS','`I_SUBABS','`I_SUMC','`I_SUMNC','`I_SUMZ','`I_SUMNZ',
'`I_MOV','`I_NEG','`I_ABS','`I_ABSNEG','`I_NEGC','`I_NEGZ','`I_NEGNC','`I_NEGNZ',
'`I_CMPS','`I_CMPSX','`I_ADDX','`I_SUBX','`I_ADDS','`I_SUBS','`I_ADDSX','`I_SUBSX',

'`I_CMPSUB','`I_DJNZ','`I_TJNZ','`I_TJZ','`I_WAITPEQ','`I_WAITPNE','`I_WAITCNT','`I_WAITVID' ]

opcodeName = [
'RDBYTE', 'RDWORD','RDLONG','HUBOP','UNDEF0','UNDEF1','UNDEF2','UNDEF3',
'ROR','ROL','SHR','SHL','RCR','RCL','SAR','REV',
'MINS',	'MAXS',	'MIN','MAX','MOVS','MOVD',	'MOVI','JMPRET',
'AND','ANDN','OR','XOR','MUXC','MUXNC','MUXNZ','MUXZ',
'ADD','SUB','ADDABS','SUBABS','SUMC','SUMNC','SUMZ','SUMNZ',
'MOV','NEG','ABS','ABSNEG','NEGC','NEGZ','NEGNC','NEGNZ',
'CMPS','CMPSX','ADDX','SUBX','ADDS','SUBS','ADDSX','SUBSX',
'CMPSUB','DJNZ','TJNZ','TJZ','WAITPEQ','WAITPNE','WAITCNT','WAITVID' ]

test_values = [ 0, 1, 2, 0x7fffffff, 0x80000000, 0x80000001, 0xfffffffe, 0xffffffff ]

def writeTest(opcode):
	fo.write('	$display("{0:6s}---Q---- CZ");\n'.format(opcodeName[opcode]))
	fo.write('\n	#1\n    opcode = {0:s};\n'.format(opcodeList[opcode]))
	test = 0
	for s in range(len(test_values)):
		for d in range(len(test_values)):
			fo.write('	S = 32\'h{0:08x};\n'.format(test_values[s]))
			fo.write('	D = 32\'h{0:08x};\n'.format(test_values[d]))
			fo.write('	C = 1\'b0;\n')
			fo.write('	Z = 1\'b0;\n')
			fo.write('	#1 $display("{0:02x} %02x %08x %1x%1x", opcode, alu_q, alu_c, alu_z);\n'.format(test))
			test += 1
			fo.write('	#1\n')
			fo.write('	C = 1\'b1;\n')
			fo.write('	Z = 1\'b0;\n')
			fo.write('	#1 $display("{0:02x} %02x %08x %1x%1x", opcode, alu_q, alu_c, alu_z);\n'.format(test))
			test += 1
			fo.write('	#1\n')
			fo.write('	C = 1\'b0;\n')
			fo.write('	Z = 1\'b1;\n')
			fo.write('	#1 $display("{0:02x} %02x %08x %1x%1x", opcode, alu_q, alu_c, alu_z);\n'.format(test))
			test += 1
			fo.write('	#1\n')
			fo.write('	C = 1\'b1;\n')
			fo.write('	Z = 1\'b1;\n')
			fo.write('	#1 $display("{0:02x} %02x %08x %1x%1x", opcode, alu_q, alu_c, alu_z);\n'.format(test))
			test += 1
fo = open("tb_alu_2.v", "wt")
fo.write(header)
for j in range(8, len(	opcodeList)):
	writeTest(j)
fo.write(ending)