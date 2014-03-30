#!/usr/bin/python
f = open("pbcdmath12.pasm.lst", "r")
fhex2 = open("cog_mem.mem", "wt")
#fhex2.write
for line in f:
	s = line.split()
	try:
		try:
			addr = int(s[0], 16) / 4
			ss = s[1][6] + s[1][7] + s[1][4] + s[1][5] + s[1][2] + s[1][3] + s[1][0] + s[1][1]
			opcode = int(ss, 16)
			
			print '\t\tmem[9\'h{0:03x}] = 32\'b{1:06b}_{2:04b}_{3:04b}_{4:09b}_{5:09b}; // {6:s}'.format(addr, opcode >> 26, \
			       (opcode >> 22) & 15, (opcode >> 18) & 15, (opcode >> 9) & 511, opcode & 511, line.rstrip())
			fhex2.write('{0:03x}:{1:08x}\n'.format(addr, opcode))
		except ValueError:
			# ignore
			#print s[0]
			addr = 0
	except IndexError:
		addr = 0
f.close()
fhex2.close()
