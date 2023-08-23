# Author:	Alec Stobbs
# Date:		Oct 20, 2022
# Description:	Psuedo-3D Project
# File Purpose:	Test Functions



#-------------------------------#
#	TEST FUNCTIONS		#
#-------------------------------#

#---------------------------------------------------------------#
# Slim1d and Slim2d have theoreticaly the same render time.	#
# Fat2d has a terrible render time, ~3x. Not ideal for realtime.#
# 2d indexing will only be used for setting individual pixles. 	#
#---------------------------------------------------------------#


.text

j skipTest

#---# Draw buffer using ++ index with single for loop
drawBufferSlim1d:
	addi $t0, $0, 0			# counter
	li $t1, screenWidth
	mul  $t1, $t1, screenHeight	# W*H loop limit
	#la $t1, pixelCount		# loop limit
	
	lw $s0, displayAddress		# initial display address
	la $s1, pixelBuffer		# initial buffer address
	
	StartTimer
	
	drawLoop:			# one for loop
	#----------#
		lw $v0, 0($s1)		# load color from buffer
				
		li $v0, 0xFFFFFFFF	# TEST load color TEST
		sw $v0, 0($s0)		# send color to display
		
		addi $s1, $s1, 4	# incriment buffer address by one
		addi $s0, $s0, 4	# incriment display address by one
		addi $t0, $t0, 1	# incriment count by 1
	#-----------#
	blt $t0, $t1, drawLoop		# loop pixels
	
	StopTimer
	PrintTimeDelta
	
jr $ra
#-


#---# Draw buffer using ++ index with double for loop
drawBufferSlim2d:
	addi $a1, $0, 0		# row
	addi $a2, $0, 0		# col
	
	addiu $sp, $0, -4		# save $ra to stack
	sw $ra, 0($sp)
	
	lw $s0, displayAddress	# initial display address
	la $s1, pixelBuffer	# initial buffer address
	
	StartTimer
	
	drawLoopRow:				# two nested for loops
	#----------#
		drawLoopCol:
			lw $v0, 0($s1)		# load color from buffer
		
			li $v0, 0xFFFFFFFF	# load yellow color TEST
			sw $v0, 0($s0)		# send val to display
			
			addi $s1, $s1, 4	# incriment buffer address by one
			addi $s0, $s0, 4	# incriment display address by one
			addi $a2, $a2, 1	# icriment col by 1
		blt $a2, screenWidth, drawLoopCol	# loop columns
	#-----------#
	addi $a1, $a1, 1			# incriment row by 1
	addi $a2, $0, 0				# reset col to 0
	blt $a1, screenHeight, drawLoopRow	# loop rows
	
	lw $ra, 0($sp)
	addiu $sp, $sp, 4			#restore $ra from stack
	
	StopTimer
	PrintTimeDelta
	
jr $ra
#-


#---# Draw buffer using the 2d array indexing with double for loop
drawBufferFat2d:
	addi $a1, $0, 0		# row
	addi $a2, $0, 0		# col
	#addi $a3, $0, 512	# ncol
	li $a3, screenWidth	# ncol
	#li $s1, screenHeight	# loop limit
	
	addiu $sp, $sp, -12	# prepare 2 words for arrays, and 1 word for $ra
				# 8 = $ra # 4 = pixelBuffer # 0 = displayAddress
	la $t0, pixelBuffer
	lw $t1, displayAddress
	sw $ra, 8($sp)
	sw $t0, 4($sp)
	sw $t1, 0($sp)
	
	StartTimer
	
	drawLoopRow2d:				# two nested for loops
	#----------#
		drawLoopCol2d:
			lw $a0, 4($sp)		# load pixelBuffer
			jal arrayGet		# get color from pixelBuffer
			lw $s0, 0($v0)		# save color to $s0
			li $s0, 0xFFFFFFFF	# TEST CODE load yellow color TEST CODE
			
			lw $a0, 0($sp)		# load displayAddress
			jal arrayGet		# get pixel address in $v0
			
			sw $s0, 0($v0)		# send val($s0) to pixel($v0)
			
			addi $a2, $a2, 1	# increment col by 1
		blt $a2, screenWidth, drawLoopCol2d	# loop columns
	#-----------#
	addi $a1, $a1, 1			# incriment row by 1
	addi $a2, $0, 0				# reset col to 0
	blt $a1, screenHeight, drawLoopRow2d		# loop rows
	
	lw $ra, 8($sp)
	addi $sp, $sp, 12			# restore $ra from stack and clear temp values
	
	StopTimer
	PrintTimeDelta
	
	
jr $ra
#-

skipTest:
