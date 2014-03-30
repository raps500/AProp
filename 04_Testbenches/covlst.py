f = open("pbcdmath12.pasm.lst", "r")
hex = [ '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f']
for line in f:
	s = line.split()
	if len(s) > 2:
		if len(s[1]) == 8:
			print s[1]