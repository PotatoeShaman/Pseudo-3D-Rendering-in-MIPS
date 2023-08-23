# Author:	Alec Stobbs
# Date:		Oct 20, 2022
# Description:	Psuedo-3D Project
# File Purpose:	Macro Library

#----------------------------------------------#

#---# Quit program safely
.macro  done							# params (void)
        li 			$v0, 10
        syscall
.end_macro
#-

#----------------------------------------------#

#---# print new line
.macro newLine							# params (void)
	li 				$v0, 11				# \n
    li 				$a0, 0xA
    syscall
.end_macro								# returns (void)

#---# print float number
.macro print_f		(%reg_f)			# params (%reg_f val)
	mov.s			$f12, %reg_f
	li 				$v0, 2				# print float
    syscall
        
	newLine
.end_macro								# returns (void)
#-

#---# print integer number
.macro print		(%reg)				# params (%reg val)
	move 			$a0, %reg
	li 				$v0, 1				# print float
    syscall
        
    newLine
.end_macro								# returns (void)
#-

#----------------------------------------------#

#---# returns current system time to $v0
.macro GetSysTime						# params (void)
	sw 				$a0, -8($sp)		# save registers
	sw 				$a1, -4($sp)
	li 				$v0, 30
    syscall								# get systime
    move 			$v0, $a0			# place output in $v0
    lw 				$a1, -4($sp)		# restore registers
    lw 				$a0, -8($sp)
.end_macro								# returns ($v0 sysTime)
#-

#---# set start of timer to $s6
.macro StartTimer 						# params (void)
	GetSysTime 
	move 			$s6, $v0
.end_macro								# returns ($s6 startTime)
#-

#---# set end of timer to $s7
.macro StopTimer						# params (void)
	GetSysTime
	move 			$s7, $v0
.end_macro								# returns ($s7 stopTime)
#-

#---# print difference between start and end of timer
.macro PrintTimeDelta					# params ($s6 startTime, $s7 stopTime)
	sw 				$a0, -4($sp)		# save register
	subu 			$s7, $s7, $s6		# calc delta
	move 			$a0, $s7
	li 				$v0, 1				# print delta
    syscall
        
    li 				$v0, 11				# \n
    li 				$a0, 0xA
    syscall
        
    lw 				$a0, -4($sp)		# restore register
.end_macro 								# returns (void)
#-

#---# print Frames per second from start and stop time
.macro PrintFPS					# params ($s6 startTime, $s7 stopTime)
	sw 				$a0, -4($sp)		# save register
	subu 			$a0, $s7, $s6		# calc delta
	mtc1			$a0, $f1
	cvt.s.w			$f1, $f1
	li_f			(0x3f800000, $f2)	# $f2 = 1.0f
	div.s			$f1, $f2, $f1		# period = 1 / delta
	li_f			(0x447a0000, $f2)	# $f2 = 1000.0f
	mul.s			$f12, $f1, $f2		# FPS = period(ms) * 1000
	
	#move 			$a0, $s7
	li 				$v0, 2				# print FPS
    syscall
        
    li 				$v0, 11				# \n
    li 				$a0, 0xA
    syscall
        
    lw 				$a0, -4($sp)		# restore register
.end_macro 								# returns (void)
#-

#----------------------------------------------#

#---# load float immediate into given register
.macro li_f 		(%val, %reg_f)		# params (%val hexFloat, %reg_f floatReg)
	li 				$t1, %val 
	mtc1 			$t1, %reg_f			# %reg_f = %val	
.end_macro								# returns ($%reg_f immediateFloat)
#-

#----------------------------------------------#

#---# swaps the value of two registers
.macro Swap 		(%reg1, %reg2, %temp)	# params (%reg1 val1, %reg2 val2, %temp tempReg)
	move 			%temp, %reg1			# temp = reg1
	move 			%reg1, %reg2			# reg1 = reg2
	move 			%reg2, %temp			# reg2 = temp
.end_macro
#-

#---# swaps the value of two registers. Float Varient
.macro Swap_f 		(%reg1_f, %reg2_f, %temp_f)	# params (%reg1_f float1, %reg2_f float2, %temp_f tempFloat)
	mov.s 			%temp_f, %reg1_f			# temp = reg1
	mov.s 			%reg1_f, %reg2_f			# reg1 = reg2
	mov.s 			%reg2_f, %temp_f			# reg2 = temp
.end_macro										# returns (%reg1_f float2, %reg2_f float1)
#-

#----------------------------------------------#

#---# returns the address of a single memeber of a 2d array into $v0
.macro ArrayGet 	(%arr, %row, %col, %ncol)	# params (%arr arrAddr, %row rowIdx, %col colIdx, %ncol arrWidth)
	mul 			$t1, %ncol, %row 			# ncolumns * row
	add 			$t1, $t1, %col				# (ncolumn * row) + col
	sll 			$t1, $t1, 2	 				# ((ncolumn * row) + col) * byte size (left shift 2 == * 4)
	add 			$v0, %arr, $t1	 			# (((ncolumn * row) + col) * byte size) + arrayBaseAddress
.end_macro										# returns ($v0 idxAddr)
#-

#---# returns the address of a single memeber of a 2d array to $v0. Float Varient
.macro ArrayGet_f 	(%arr, %row_f, %col_f, %ncol_f)	# params (%arr arrAddr, %row_f rowIdx, %col_f colIdx, %ncol_f arrWidth)
	cvt.w.s 		$f1, %row_f
	mfc1 			$t1, $f1					# $t1 = (int)%row
	cvt.w.s			$f1, %col_f
	mfc1 			$t2, $f1					# $t2 = (int)%col
	cvt.w.s 		$f1, %ncol_f
	mfc1 			$t3, $f1					# $t3 = (int)%ncol
	
	mul 			$t1, $t1, $t3	 			# ncolumns * row
	add 			$t1, $t1, $t2				# (ncolumn * row) + col
	sll 			$t1, $t1, 2	 				# ((ncolumn * row) + col) * byte size (left shift 2 == * 4)
	add 			$v0, %arr, $t1	 			# (((ncolumn * row) + col) * byte size) + arrayBaseAddress
.end_macro										# returns ($v0 idxAddr)
#-

#----------------------------------------------#

			#-- Not Used. Made as function --#
#---# loads a line from the Map array
#.macro LoadMapLine 	(%num, %color)		# params (%num index, %color hexColor)
#	addi 			$t0, $0, 16		
#	mulu 			$t0, $t0, %num			# 16 * %num to move to next line
#	la 				$t0, Map($t0)
#	l.s 			$f31, 0($t0)			# x.1
#	l.s 			$f30, 4($t0)			# y.1
#	l.s 			$f29, 8($t0)			# x.2
#	l.s 			$f28, 12($t0)			# y.2
#	li 				$a0, %color
#.end_macro									# returns ($f31 x.1, f30 y.1, f29 x.2, $f28 y.2, $a0 color)
#-

			#-- Not Used --#
#---# Loads a line from the given array
#.macro LoadAnyLine 	(%reg)					# params (%reg arrAddr)
#	l.s 			$f31, 0(%reg)			# x.1
#	l.s 			$f30, 4(%reg)			# y.1
#	l.s 			$f29, 8(%reg)			# x.2
#	l.s 			$f28, 12(%reg)			# y.2
#.end_macro									# returns ($f31 x.1, f30 y.1, f29 x.2, $f28 y.2)
#-

#----------------------------------------------#
