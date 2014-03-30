f1 = open("alu_results.txt", "rt")
f2 = open("prop_alu_results_p2.txt", "rt")

opcodeName = [
'RDBYTE', 'RDWORD','RDLONG','HUBOP','UNDEF0','UNDEF1','UNDEF2','UNDEF3',
'ROR','ROL','SHR','SHL','RCR','RCL','SAR','REV',
'MINS',	'MAXS',	'MIN','MAX','MOVS','MOVD',	'MOVI','JMPRET',
'AND','ANDN','OR','XOR','MUXC','MUXNC','MUXNZ','MUXZ',
'ADD','SUB','ADDABS','SUBABS','SUMC','SUMNC','SUMZ','SUMNZ',
'MOV','NEG','ABS','ABSNEG','NEGC','NEGZ','NEGNC','NEGNZ',
'CMPS','CMPSX','ADDX','SUBX','ADDS','SUBS','ADDSX','SUBSX',
'CMPSUB','DJNZ','TJNZ','TJZ','WAITPEQ','WAITPNE','WAITCNT','WAITVID' ]


def loadOps(file):
	tests = []
	optest = []
	opcode = ''
	for line in file:
		split = line.split()
		if split[0] in opcodeName:
			if len(optest) > 0:
				tests.append([ opcode, optest ])
			opcode = split[0]
			optest = [] # initialize for next opcode 
		else:
			if len(split) >= 5:
				optest.append([ split[0], split[1], split[2], split[4], split[5]] )
			else:
				print 'short line: ' + line
	if len(optest) > 0:
		tests.append([ opcode, optest ])
	return tests

def compareOpcode(opcode, veri_test, real_test):
	veri = None
	real = None
	for j in range(len(veri_test)):
		if opcode == veri_test[j][0]:
			#print veri_test[j]
			veri = veri_test[j][1]
	for j in range(len(real_test)):
		if opcode == real_test[j][0]:
			real = real_test[j][1]
			#print real_test[j]
	
	if (veri == None) or (real == None):
		print 'Opcode ' + opcode + ' not found on both tests'
	else:
		for j in range(len(veri)):
			if (veri[j][3] != real[j][3]) or (veri[j][4] != real[j][4]):
				print opcode, veri[j][0], veri[j][1], veri[j][2], veri[j][3], real[j][3], veri[j][4], real[j][4]
				#print '{0:%8s} {1:%8s} {2:%8s} {3:%2s} = {2:%8s} {3:%2s} != {4:%8s} {5:%2s}'.format( opcode, veri[j][0], veri[j][1], veri[j][2], veri[j][3], veri[j][4], real[j][3], real[j][4])
		
verilog_tests = loadOps(f1)
real_tests = loadOps(f2)
for i in range(len(opcodeName)):
	compareOpcode(opcodeName[i], verilog_tests, real_tests)
