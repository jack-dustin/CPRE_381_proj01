.data

.text
.globl main

main:

    # lui x5, 0x10010
    addi x1, x0, 0x1        # Load x1 with 0x000000001
    slli x1, x1, 12         # shift 1 left by 12 bits   -> 0x0000.1001
    addi x1, x1, 1          # Gets us 0x0000.1001
    slli x1, x1, 16         # Shift 0x1001 left by 16 bits -> 0x1001.0000
    addi x5, x1, x0         # Move Contents from x1 to x5

    # lui x6, 0x80000
    addi x1, x0, 0x1        
    slli x6, x1, 31 


	# Test 2: Edge case store - max positive and negative number
	#lui x5, 0x10010 # load base data memory address into x5
	#lui x6, 0x80000	# load max value into x6
	addi x6, x6, -1
	sw x6, 0(x5)	# store the value
	# expect 0x7fffffff at location 0x10010000
	

    # lui x6, 0x80000
    addi x1, x0, 0x1        
    slli x6, x1, 31 

	# lui x6, 0x80000	# load max negative value into x6
	sw x6, 4(x5)	# store the value
	# expect 0x80000000 at location 0x10001004
exit:
	
wfi