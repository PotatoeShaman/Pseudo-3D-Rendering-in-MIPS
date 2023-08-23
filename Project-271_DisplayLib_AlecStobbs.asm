# Author:	Alec Stobbs
# Date:		Oct 20, 2022
# Description:	Psuedo-3D Project
# File Purpose:	Display Functions

#---#
.data
#				.space 			0x080000 			# 512 x 256 by 4 bytes reserved for the display
				.space 			0x08000 			# 128 x 64 by 4 bytes reserved for the display
displayAddress:	.word			0x10010000 			# base address of the display

# # # # # # # # # # # # # # # # # # # # #
#	Putting displayAddress between		#
#	the display and pixelBuffer memory 	#
#	arrays offsets their index by 1,	#
#	reducing cache misses when they		#
#	are accessed sequentially.			#
# # # # # # # # # # # # # # # # # # # # #

#pixelBuffer: 	.space 		0x080000 			# 512 by 256 by 4 bytes reserved for the buffer
pixelBuffer: 	.space 		0x08000 			# 128 by 64 by 4 bytes reserved for the buffer
.eqv			screenWidth		128				# #define screenWidth 128
.eqv			screenHeight	64				# #define screenHeight 64
.eqv			screenSize		8192			# 128*64


#.eqv			screenWidth		512			# screenWidth  in pixels
#.eqv			screenHeight	256				# screenHeight in pixels
#.eqv			screenSize		131072			# 1024*512
#-

#---
.text

#---# Skip Functions
j 				SkipDisplay
#-

#----------------------------------------------#

#---# Reset display to designated color(s). Probably wont be needed later
clearScreen:
	addi 			$t0, $0, 0					# count						
	li 				$t1, screenWidth
	mul  			$t1, $t1, screenHeight		# W*H loop limit
	
	lw 				$t2, displayAddress			# initial display address
	li 				$t3, 0xFFFFFF				# load WHITE
	
	#StartTimer
	
draw:											# one for loop
	#----------#		
		sw 			$t3, 0($t2)					# send color to display
		
		addi 		$t2, $t2, 4					# incriment display address by one
		addi 		$t0, $t0, 1					# incriment count by 1
	#-----------#
	blt 			$t0, $t1, draw				# loop pixels
	
	#StopTimer
	#PrintTimeDelta
	
jr $ra
#-

#----------------------------------------------#

#---#
resetBuffer:
	#addi 			$t0, $0, 0					# count	
	addi 			$t2, $0, 0					# count					
	li 				$t1, screenWidth
	mul 			$t1, $t1, screenHeight		# W*H loop limit
	#sll				$t1, $t1, 2					# W*H * 4 (in bytes)
	mul				$t1, $t1, 4
	
	#la 				$t2, pixelBuffer			# initial buffer address
	li 				$t3, 0x000000				# load BLACK 
	
	#StartTimer
	
drawBuff:										# one for loop
	#----------#
		#sw 			$t3, 0($t2)					# send color to buffer
		sw 				$t3, pixelBuffer($t2)
		
		addi 		$t2, $t2, 4					# incriment display address by one
		#addi 		$t0, $t0, 1					# incriment count by 1
	#-----------#
	blt 			$t2, $t1, drawBuff			# loop pixels
	
	#StopTimer
	#PrintTimeDelta
	
jr $ra

#//sets the pixelBuffer array to initial state
#void resetBuffer(char floor, char sky)
#
#	const int midx = XRES / 2, midy = YRES / 2;
#
#	for (int y = 0; y < YRES; ++y)
#	{
#		for (int x = 0; x < XRES; ++x)
#		{
#			if (y < midy) { pixelBuffer[y][x] = sky; } //set sky top half of screen
#			else { pixelBuffer[y][x] = floor; } //set floor bottom half of screen
#
#			//draw border
#			if (x == XRES - 1 || x == 0 || y == YRES - 1 || y== 0)
#			{
#				pixelBuffer[y][x] = '.';
#			}
#		}
#	}
#}
#-

#----------------------------------------------#

#---# Draw buffer using ++ index with single for loop
render:
	addi 			$t0, $0, 0						# count
	li 				$t1, screenWidth
	mul  			$t1, $t1, screenHeight			# W*H loop limit
	
	lw 				$s0, displayAddress				# initial display address
	la 				$s1, pixelBuffer				# initial buffer address
	li 				$t5, 0x00FF00					# load GREEN
	#StartTimer
	
drawLoopBuffer:										# one for loop
	#----------#
		lw 			$v0, 0($s1)						# load color from buffer
		sw 			$v0, 0($s0)						# send color to display
		
		addi		$t4, $t1, screenWidth			# (W*H) + W
		srl			$t4, $t4, 1						# ((W*H) + W)/2		# trick to get bottom right biased center of even screen size
		bne			$t0, $t4, centerScreen
			sw 			$t5, 0($s0)					# dot in center of screen
centerScreen:
		
		addi 		$s1, $s1, 4						# incriment buffer address by one
		addi 		$s0, $s0, 4						# incriment display address by one
		addi 		$t0, $t0, 1						# incriment count by 1
	#-----------#
	blt 			$t0, $t1, drawLoopBuffer		# loop pixels
	
	#StopTimer
	#PrintTimeDelta
jr $ra

#void render(void)
#{
#	/* console command to set the cursor back to top left and
#	*  overwrite each line instead of clearing entire screen.
#	*  Prevents flickering and makes motion smoother.
#	*  Make sure window and font are sized properly and text-wrapping is turned off. */
#	//printf("\x1B[H");
#
#	//optimized rendering by printing each array row as a string
#	for (int i = 0; i < YRES; ++i)
#	{
#		printf("%.*s\n",XRES , &pixelBuffer[i][0]);
#	}
#}
#-

#----------------------------------------------#

#---# Skip File
SkipDisplay:
#-
