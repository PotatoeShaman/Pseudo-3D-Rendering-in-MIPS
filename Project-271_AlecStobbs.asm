# Author:	Alec Stobbs
# Date:		Oct 7, 2022
# Description:	Psuedo-3D Project 

.include "Project-271_MacroLib_AlecStobbs.asm"
.include "Project-271_DisplayLib_AlecStobbs.asm"
.include "Project-271_TrigTables_AlecStobbs.asm"

#----------------------------------------------#

#---# 
.data
		.word 		0							# memory gap to offset cache index of pixelBuffer and Map
Map: 											# array of segments that define where to draw walls
		#.float 		40, 5, 40, 20				# single segment {x1,y1,x2,y2}
		#.float 		30, 5, 30, 26
		#.float 		40, 20, 65, 41
		#.float 		30, 26, 55, 47
		#.float			0,70,0,36
		.float			10,70,10,20 			# AB
		.float			10,10,70,10 			# CD
		.float			70,10,70,30 			# DE
		.float			70,30,30,30 			# EF
		.float			30,30,30,40 			# FG
		.float			30,40,100,40 			# GH
		.float			100,40,100,60 			# HI
		.float			100,70,60,70 			# JK
		.float			60,70,60,50 			# KL
		.float			70,60,70,50 			# MN
		.float			90,60,90,70 			# OP
		.float			90,50,100,50 			# QR
		.float			80,50,80,40 			# ST
		.float			30,60,20,60 			# UV
		.float			20,60,20,20 			# WZ
		.float			60,20,60,30 			# a1b1
		.float			40,40,40,70 			# c1d1
		.float			60,60,50,60 			# e1f1
		.float			60,80,20,80 			# g1h1
		.float			20,80,20,70 			# h1i1
		.float			30,70,30,80 			# j1k1
		.float			90,70,90,80 			# Pl1
		.float			90,80,60,80 			# l1g1
.eqv	MapSize			23						# 22 current lines
		
#Wall:											# temp array for a wall to be drawn. Did not use, used stack instead
#		.float 		0, 0, 0, 0
#		.float 		0, 0, 0, 0
#		.float		0, 0, 0, 0
#		.float		0, 0, 0, 0					
	
player: 										# 12 bytes for 3 floats, x,y,angle
		.float 		28.1 						# x
		.float 		24.1						# y
		.word  		4							# angle | incriment between 0-28 by adding 4 for 8 rotation states #increment by PI/4 to create 8 rotatoin states#	

.eqv	FLT_MIN     0x00800000	        		# min normalized positive float value

.eqv	HFOV		0x41a3d70a					# screenWidth / 6.25f	# adjustable horizontal FOV
.eqv	VFOV		0x3F000000					# 2.0f					# adjustable vertical FOV

.eqv	HSCALE		0x40c80000					# 6.25f					# fov value used to check for walls out of view

#.eqv	HFOV		0x414ccccd					# screenWidth / 10.0f	# adjustable horizontal FOV
#.eqv	VFOV		0x40cccccd					# screenHeight / 10.0f	# adjustable vertical FOV
#-

#---# start of instructions
.text

#----------------------------------------------#

#---# float register assignment
	# ($f0)			= 	0
	# ($f1-$f5)  	= 	temp
	# ($f6-%f12) 	= 	saved
	# ($f28-$f31)	= 	arguments
#-

#----------------------------------------------#

#---# Program Entry Point
Main:
	jal				resetBuffer
start_Main:
	StartTimer

	jal movePlayer

	l.s				$f12, player				# player.x
    print_f 		($f12)
    l.s				$f12, player+4				# player.y
    print_f 		($f12)
    lw				$a0, player+8				# player.a
    print 			($a0)
    li 				$v0, 11						# \n
    li 				$a0, 0xA
    syscall
	
	jal 			resetBuffer
	
	li				$a0, 0x0000FF
	jal 			renderMap
	
	#li				$a0, 0x000000
	#jal				renderMap
	
	StopTimer
	PrintFPS
	j 				start_Main
j done
#-

renderMap:
	addi			$sp, $sp, -4
	sw				$ra, 0($sp)					# save return

	li				$s1, 0						# counter = 0
	move			$s2,  $a0					# $s2 = color
while_RenderMap:
		move		$a0, $s1					# MapIndex = counter
		jal 		LoadMapLine					# returns ($f31 x.1, f30 y.1, f29 x.2, $f28 y.2)
		move		$a0,  $s2					# $a0 = color
		jal			relativeLine3D				
		
		#jal 		relativeLine2D				
	
	addi			$s1, $s1, 1					# ++counter
	blt				$s1, MapSize, while_RenderMap
	
	jal 			render
	
	lw				$ra, 0($sp)					# restore return
	addi			$sp, $sp, 4
jr $ra

#----------------------------------------------#

#---# trasnform a line relative to player position and rotation
rotationTransform2D:							# params ($f31 x.1, f30 y.1, f29 x.2, $f28 y.2)
	l.s				$f1, player					# player.x
	l.s				$f2, player+4				# player.y
	lw 				$t3, player+8				# player.a
	la				$t1, Sine_Table
	la				$t2, Cosine_Table
	
	#add				$t1, $t1, $t3				# sine_table + player.a
	l.s				$f10, Sine_Table($t3)				# sin(player.a)
	#l.s				$f10, 0($t1)
	#add				$t2, $t2, $t3				# cosine_table + player.a
	l.s				$f11, Cosine_Table($t3)				# cos(player.a)
	#l.s				$f11, 0($t2)
	
												# tempLine($f6, $f7, $f8, $f9) # player position becomes new origin for segment
	sub.s			$f6, $f31, $f1				# temp.x1 = line.x1 - player.x
	sub.s			$f7, $f30, $f2				# temp.y1 = line.y1 - player.y
	sub.s			$f8, $f29, $f1				# temp.x2 = line.x2 - player.x
	sub.s			$f9, $f28, $f2				# temp.y2 = line.y2 - player.y
	
	#neg.s			$f1, $f1
	#neg.s			$f2, $f2
	
	#add.s			$f6, $f31, $f1				# temp.x1 = line.x1 - player.x
	#add.s			$f7, $f30, $f2				# temp.y1 = line.y1 - player.y
	#add.s			$f8, $f29, $f1				# temp.x2 = line.x2 - player.x
	#add.s			$f9, $f28, $f2				# temp.y2 = line.y2 - player.y
	
	mul.s			$f1, $f6, $f10				# (temp.x1 * vsin)
	mul.s			$f2, $f7, $f11				# (temp.y1 * vcos)
	add.s			$f1, $f1, $f2				# z1 = (temp.x1 * vsin) + (temp.y1 * vcos)

	mul.s			$f2, $f8, $f10				# (temp.x2 * vsin)
	mul.s			$f3, $f9, $f11				# (temp.y2 * vcos)
	add.s			$f2, $f2, $f3				# z2 = (temp.x2 * vsin) + (temp.y2 * vcos)
	
	mul.s			$f3, $f7, $f10				# (temp.y1 * vsin)
	mul.s			$f4, $f6, $f11				# (temp.x1 * vcos)
	sub.s			$f6, $f3, $f4				# temp.x1 = (temp.y1 * vsin) - (temp.x1 * vcos)
	
	mul.s			$f3, $f9, $f10				# (temp.y2 * vsin)
	mul.s			$f4, $f8, $f11				# (temp.x2 * vcos)
	sub.s			$f8, $f3, $f4				# temp.x2 = (temp.y2 * vsin) - (temp.x2 * vcos)
	
	mov.s			$f7, $f1					# temp.y1 = z1
	mov.s			$f9, $f2					# temp.y2 = z2
jr $ra											# return tempLine($f6 x.1, $f7 y.1, $f8 x.2, $f9 y.2)
#-

#----------------------------------------------#

#---# checks if a single float value is too close to zero and clamps it
div0Check:										# params ($f1 val)		
		abs.s 		$f2, $f1					# $f2 = |y1|
		li_f 		(0x3dcccccd, $f3)			# $f3 = 0.1f
		c.lt.s 		0, $f2, $f3
		bc1f 		0, BigEnough_Div0			# if (|y1| < 0.1f)
 		 c.lt.s 	0, $f1, $f0
 		 bc1f 		0, Pos_Div0					# if (y1 < 0)
 		  neg.s 	$f3, $f3					# $f3 = -0.1f
		  mov.s 	$f1, $f3					# y1 = -0.1f
 		  j 		BigEnough_Div0
Pos_Div0:
 		mov.s 		$f1, $f3					# y1 = 0.1f
BigEnough_Div0:

jr $ra											# return ($f1 valClamped)
#-

#----------------------------------------------#

#---#
checkFOV:										# params ($f6 x.1, f7 y.1, f8 x.2, $f9 y.2)
	#-- calc rise/run as y1/x1 to get slope from player to that vertex, if that slope is less than the slope of HFOV then its out of view
	#-- func: ((1/x1) * 6.25) < 2 = true if vertex is out of view 
	div.s			$f1, $f7, $f6				# slope = y1/x1
	div.s			$f2, $f9, $f8				# slope = y2/x2
	li_f			(HSCALE, $f3)				# 6.25f
	mul.s			$f1, $f1, $f3				# (y1/x1)*6.25f
	mul.s			$f2, $f2, $f3				# (y2/x2)*6.25f
	abs.s			$f1, $f1
	abs.s			$f2, $f2
	li_f			(0x40000000, $f3)			# 2.0f
	
	c.lt.s			0, $f1, $f3					# ((y1/x1)*6.25) < 2.0f
	c.lt.s			1, $f2, $f3					# ((y2/x2)*6.25) < 2.0f
	
	#bc1f			0, noSkip_Line3D			# if (vertex1 is out of view)
	#bc1t			1, end_Line3D				# && if (vertex2 is out of view)
jr	$ra											# returns (code0: v1 outOfBounds, code1: v2 outOfBounds)
#-

#----------------------------------------------#

#---# draw a transformed line as a perspective wall
relativeLine3D:									# params ($f31 x.1, f30 y.1, f29 x.2, $f28 y.2)
	addi			$sp, $sp, -4
	sw				$ra, 0($sp)					# save return
	
	jal				rotationTransform2D			# trasform line. returns tempLine($f6 x.1, $f7 y.1, $f8 x.2, $f9 y.2)
												
												# dont render line if its behind the player (not on screen)
												# if (y1 < 0 && y2 < 0) { return; } 
	c.lt.s 			0, $f7, $f0					# code0: y1 < 0
	c.lt.s 			1, $f9, $f0					# code1: y2 < 0
	bc1f			0, doneCheck_Line3D		# if (y1 < 0)
	bc1t			1, end_Line3D				# && if (y2 < 0)
doneCheck_Line3D:
	#jal				checkFOV					# returns code0 & code1 for if (x1,y1) and (x2,y2) are out of view
	
	#bc1f			0, noSkip_Line3D			# if (vertex1 is out of view)
	#bc1t			1, end_Line3D				# && if (vertex2 is out of view)
	
	
noSkip_Line3D:
												# crop line to players view if partially behind player to prevent rendering errors. Uses X intercept formula
	bc1f			0, altCrop_Line3D			# if (y1 < 0) # crop line to player view
		sub.s		$f1, $f8, $f6				# x2 - x1
		sub.s		$f2, $f9, $f7				# y2 - y1
		div.s		$f1, $f1, $f2				# m = (float)(x2 - x1) / (float)(y2 - y1)
		mul.s		$f1, $f1, $f7				# m*y1
		sub.s		$f6, $f6, $f1				# x1 = x1 - (m*y1)
		li_f		(0x3dcccccd, $f7)			# y1 = 0.1f
		j 			doneCrop_Line3D						
altCrop_Line3D:
	bc1f			1, doneCrop_Line3D			# else if (y2 < 0) # crop line to player view. Uses X intercept formula
		sub.s		$f1, $f8, $f6				# x2 - x1
		sub.s		$f2, $f9, $f7				# y2 - y1
		div.s		$f1, $f1, $f2				# m = (float)(x2 - x1) / (float)(y2 - y1)
		mul.s		$f1, $f1, $f7				# m*y1
		sub.s		$f8, $f6, $f1				# x2 = x1 - (m*y1)
		li_f		(0x3dcccccd, $f9)			# y2 = 0.1f
doneCrop_Line3D:

		mov.s		$f1, $f7
		jal			div0Check					# protect from div/0 in y1
		mov.s		$f7, $f1
		
		mov.s		$f1, $f9
		jal			div0Check					# protect from div/0 in y2
		mov.s		$f9, $f1
		
		li			$t1, screenWidth
		srl			$t1, $t1, 1					# screenWidth / 2
		mtc1		$t1, $f10
		cvt.s.w		$f10, $f10					# $f10 = (float)midx
		
		li			$t1, screenHeight
		srl			$t1, $t1, 1					# screenHeight / 2
		mtc1		$t1, $f11
		cvt.s.w		$f11, $f11					# $f11 = (float)midy
		
		addi 		$sp, $sp -24				# reserve 6 words on stack for wall vertexes
		
		li_f		(HFOV, $f12)				# $f12 = hfov
		li_f		(VFOV, $f13)				# $f13 = vfov
		
		div.s		$f1, $f12, $f7				# hfov / y1
		neg.s		$f2, $f6					# -x1
		mul.s		$f1, $f2, $f1				# -x1 * (hfov/y1)
		add.s		$f1, $f10, $f1				# midx + (x1 * (hfov/y1))
		s.s			$f1, 0($sp)					# 0($sp) = LeftX
		
		div.s		$f1, $f13, $f7				# vfov / y1
		mul.s		$f2, $f11, $f1				# midy * (vfov/y1)
		sub.s		$f1, $f11, $f2				# midy - (midy * (vfov/y1))
		s.s			$f1, 4($sp)					# 4($sp) = topLeftY
		
		add.s		$f1, $f11, $f2				# midy + (midy * (vfov/y1))
		s.s			$f1, 8($sp)					# 8($sp) = bottomLeftY
		
		
		div.s		$f1, $f12, $f9				# hfov / y2
		neg.s		$f2, $f8					# -x2
		mul.s		$f1, $f2, $f1				# -x2 * (hfov/y2)
		add.s		$f1, $f10, $f1				# midx + (x2 * (hfov/y2))
		s.s			$f1, 12($sp)				# 12($sp) = rightX
		
		div.s		$f1, $f13, $f9				# vfov / y2
		mul.s		$f2, $f11, $f1				# midy * (vfov/y2)
		sub.s		$f1, $f11, $f2				# midy - (midy * (vfov/y2))
		s.s			$f1, 16($sp)				# 16($sp) = topRightY
		
		add.s		$f1, $f11, $f2				# midy + (midy * (vfov/y1))
		s.s			$f1, 20($sp)				# 20($sp) = bottomRightY
		
		#--- Make drawWall function ---#
		mov.s		$f15, $f7					# save y1 for later use
		mov.s		$f16, $f9					# save y2 for later use
		
												# load top line and draw
		l.s			$f31, 0($sp)				# x.1 = leftX
		l.s			$f30, 4($sp)				# y.1 = topLeftY
		l.s			$f29, 12($sp)				# x.2 = rightX
		l.s			$f28, 16($sp)				# y.2 = topRightY
		jal			drawLine
		
												# load bottom line and draw
		l.s			$f31, 0($sp)				# x.1 = leftX
		l.s			$f30, 8($sp)				# y.1 = bottomLeftY
		l.s			$f29, 12($sp)				# x.2 = rightX
		l.s			$f28, 20($sp)				# y.2 = bottomRightY
		jal			drawLine
		
		c.lt.s		0, $f0, $f15				# if left line is behind player, dont draw
		bc1f		0, leftSkip_Line3D			# if (0 < y1)
												# load left line and draw
			l.s		$f31, 0($sp)				# x.1 = leftX
			l.s		$f30, 4($sp)				# y.1 = topLeftY
			l.s		$f29, 0($sp)				# x.2 = leftX
			l.s		$f28, 8($sp)				# y.2 = bottomLeftY
			jal 	drawLine
leftSkip_Line3D:

		c.lt.s		0, $f0, $f16				# if right line is behind player, dont draw
		bc1f		0, rightSkip_Line3D			# if (0 < y2)
												# load right line and draw
			l.s		$f31, 12($sp)				# x.1 = rightX
			l.s		$f30, 16($sp)				# y.1 = topRightY
			l.s		$f29, 12($sp)				# x.2 = rightX
			l.s		$f28, 20($sp)				# y.2 = bottomrightY
			jal		drawLine
rightSkip_Line3D:

		addi		$sp, $sp, 24				# release 6 words from stack

end_Line3D:
	lw				$ra, 0($sp)					# restore return
	addi			$sp, $sp, 4
jr $ra											# returns (void)			

#//if wall is completely behind player dont render
#	if (z1 < 0 && z2 < 0) { return; }
#
#	if (z1 < 0)
#	{
#		s1.x1 = xIntercept(s1); 
#					//trim input segment to fit within player view, finds intersect with 
#					//float m = (float)(seg.x2 - seg.x1) / (float)(seg.y2 - seg.y1);
#					//float x = seg.x1 - (m * seg.y1);
#					//return x;
#		s1.y1 = 0.1f;
#	}
#	else if (z2 < 0)
#	{
#		s1.x2 = xIntercept(s1);
#					//trim input segment to fit within player view, finds intersect with 
#					//float m = (float)(seg.x2 - seg.x1) / (float)(seg.y2 - seg.y1);
#					//float x = seg.x1 - (m * seg.y1);
#					//return x;
#		s1.y2 = 0.1f;
#	}
#
#	//prevent div/0
#	s1.y1 = (s1.y1 < 0.1f && s1.y1 >= 0) ? 0.1f : s1.y1;
#	s1.y1 = (s1.y1 <= 0 && s1.y1 > -0.1f) ? -0.1f : s1.y1;
#	s1.y2 = (s1.y2 < 0.1f && s1.y2 >= 0) ? 0.1f : s1.y2;
#	s1.y2 = (s1.y2 <= 0 && s1.y2 > -0.1f) ? -0.1f : s1.y2;
#
#
#	//horizontal field of view scaler. smaller = wide. larger = narrow.
#	const int hfov = XRES / 6.25;
#	//vertical field of view scaler. smaller = taller walls. larger = shorter walls.
#	const int vfov = 2;
#
#	//new points for wall projection, 4 lines total
#	float r1, r2, t1a, t2a, t1b, t2b;
#
#
#	//--divide by distance(y) to scale wall height--//
#	//top/bottom left x
#	r1 = midx + (float)(-s1.x1 * hfov / s1.y1);
#	//top left y
#	t1a = midy - (float)(midy * vfov / s1.y1);
#	//bottom left y
#	t1b = midy + (float)(midy * vfov / s1.y1);
#
#	//top/bottom right x
#	r2 = midx + (float)(-s1.x2 * hfov / s1.y2);
#	//top right y
#	t2a = midy - (float)(midy * vfov / s1.y2);
#	//bottom right y
#	t2b = midy + (float)(midy * vfov / s1.y2);
#
#	
#	segment2 top = { r1,  t1a, r2, t2a };
#	drawLine(top, '#', 1);
#
#	segment2 bottom = { r1, t1b, r2, t2b };
#	drawLine(bottom, '#', -1);
#
#	//if wall edge is behind player, dont draw
#	if (z1 >= 0)
#	{
#		segment2 left = { r1, t1a, r1, t1b };
#		drawLine(left, '#', -1);
#	}
#
#	//if wall edge is behind player, dont draw
#	if (z2 >= 0)
#	{
#		segment2 right = { r2, t2a, r2, t2b };
#		drawLine(right, '#', -1);
#	}
#}
#-

#----------------------------------------------#

#---# draw a transformed line on screen
relativeLine2D:									# params ($f31 x.1, f30 y.1, f29 x.2, $f28 y.2)
	addi			$sp, $sp, -4
	sw				$ra, 0($sp)					# save return
	
	jal				rotationTransform2D			# trasform line. returns tempLine($f6 x.1, $f7 y.1, $f8 x.2, $f9 y.2)
	
	li				$t0, screenWidth
	srl				$t0, $t0, 1					# (XRES / 2)
	mtc1 			$t0, $f3					
	cvt.s.w			$f3, $f3					# float cast
	sub.s			$f6, $f3, $f6				# temp.x1 = (XRES / 2) - temp.x1
	sub.s			$f8, $f3, $f8				# temp.x2 = (XRES / 2) - temp.x2
	
	li				$t0, screenHeight
	srl				$t0, $t0, 1					# (YRES / 2)
	mtc1 			$t0, $f3					
	cvt.s.w			$f3, $f3					# float cast
	sub.s			$f7, $f3, $f7				# temp.y1 = (YRES / 2) - z1
	sub.s			$f9, $f3, $f9				# temp.y2 = (YRES / 2) - z2
	
	mov.s			$f31, $f6					# x.1 = temp.x1
	mov.s			$f30, $f7					# y.1 = temp.y1
	mov.s			$f29, $f8					# x.2 = temp.x2
	mov.s			$f28, $f9					# y.2 = temp.y2
	
	jal 			drawLine
	lw				$ra, 0($sp)					# restore return
	addi			$sp, $sp, 4
jr $ra											# returns (void)

#//rotates a line segment relative to the players position
#void relativeTransform(segment2* s1, const vector2* p0)
#{ 
#	segment2 temp; //s1 reference not used currently, will be when 3D projection function is implemented
#	
#	//player position becomes new origin for segment
#	temp.x1 = s1->x1 - p0->x;
#	temp.x2 = s1->x2 - p0->x;
#	temp.y1 = s1->y1 - p0->y;
#	temp.y2 = s1->y2 - p0->y;
#	
#	//temp y values during calc
#	float z1, z2;
#	float vcos = cos(p0->a), vsin = sin(p0->a);
#
#	//rotate segment around origin
#	//z is parallel distance to a point relative to player angle (center of screen)
#	z1 = (temp.x1 * vsin) + (temp.y1 * vcos); //some errors can occur here.
#	z2 = (temp.x2 * vsin) + (temp.y2 * vcos); //can give very large or small z values that will be an issue later.
#
#	temp.x1 = (temp.y1 * vsin) - (temp.x1 * vcos);
#	temp.x2 = (temp.y2 * vsin) - (temp.x2 * vcos);
#
#	//shift relative to center of screen
#	temp.x1 = (XRES / 2) - temp.x1;
#	temp.y1 = (YRES / 2) - z1;
#	temp.x2 = (XRES / 2) - temp.x2;
#	temp.y2 = (YRES / 2) - z2;
#
#	drawLine(temp, '.', -1); //remove when project3D is implemented
#}
#-

#----------------------------------------------#

#---# 
movePlayer:										# params (void)
	lw 				$t0, 0xffff0000				# get MMIO ready bit
    andi 			$t0, $t0, 1
    beq 			$t0, $zero, noKey
	lw				$t0, 0xffff0004				# get MMIO data
	
	l.s				$f6, player					# player.x
	l.s				$f7, player+4				# player.y
	lw 				$s0, player+8				# player.a
	la				$t1, Sine_Table
	la				$t2, Cosine_Table
	
	add				$t3, $s0, $t1				# sine_table + player.a
	l.s				$f1, ($t3)					# sin(player.a)
	add				$t2, $s0, $t2				# cosine_table + player.a
	l.s				$f2, ($t2)					# cos(player.a)
	
	bne				$t0, 0x77, a_read			# if w
		add.s 		$f6, $f6, $f1				# x += sin(a)
		add.s 		$f7, $f7, $f2				# y += cos(a)
a_read:
	bne				$t0, 0x61, s_read			# if a
		sub.s 		$f6, $f6, $f2				# x -= cos(a)
		add.s 		$f7, $f7, $f1				# y += sin(a)
s_read:
	bne				$t0, 0x73, d_read			# if s
		sub.s 		$f6, $f6, $f1				# x -= sin(a)
		sub.s 		$f7, $f7, $f2				# y -= cos(a)
d_read:
	bne				$t0, 0x64, q_read			# if d
		add.s 		$f6, $f6, $f2				# x += cos(a)
		sub.s 		$f7, $f7, $f1				# y -= sin(a)
q_read:
	bne				$t0, 0x71, e_read			# if q
		bne			$s0, $0, q_sub				# if (a == 0)
			li		$s0, 28						# a = 28
			j		e_read
q_sub:
		sub 		$s0, $s0, 4					# a -= 4
e_read:
	bne				$t0, 0x65, save_movePlayer	# if e
		bne			$s0, 28, e_add				# if (a == 28)
			li		$s0, 0						# a = 0
			j 		save_movePlayer
e_add:
		add 		$s0, $s0, 4					# a += 4
save_movePlayer:
		s.s		$f6, player						# player.x
		s.s		$f7, player+4					# player.y
		sb 		$s0, player+8					# player.a
noKey:
jr $ra											# returns (void)

#void movePLayer(vector2* player) 
#{//add some kind of wall collision and sliding
#
#	if (GetKeyState('W') < 0)
#	{
#		player->x += sin(player->a);
#		player->y += cos(player->a);
#	}
#	if (GetKeyState('S') < 0)
#	{
#		player->x -= sin(player->a);
#		player->y -= cos(player->a);
#	}
#	if (GetKeyState('A') < 0)
#	{
#		player->x -= cos(player->a);
#		player->y += sin(player->a);
#	}
#	if (GetKeyState('D') < 0)
#	{
#		player->x += cos(player->a);
#	}
#	if (GetKeyState('Q') < 0)
#	{
#		player->a -= PI / 32;
#	}
#	if (GetKeyState('E') < 0)
#	{
#		player->a += PI / 32;
#	}
#}
#-

#----------------------------------------------#

#---# iterates between two points to draw a line of color using standard mx + b
drawLine: 										# params ($f31 x.1, f30 y.1, f29 x.2, $f28 y.2, $a0 color)
	#StartTimer
	
	
	addi 			$sp, $sp, -4				
	sw 				$ra, 0($sp)					# save return
	
	mov.s 			$f6, $f0					# m = 0.0f
	
	c.eq.s 			0, $f31, $f29				# code0: (seg.x1 != seg.x2)
	bc1t 			0, Div0_drawLine			# if (seg.x1 != seg.x2)
		sub.s 		$f1, $f28, $f30				# (seg.y2 - seg.y1)	
		sub.s 		$f2, $f29, $f31				# (seg.x2 - seg.x1)
		li_f		(FLT_MIN, $f3)				
		add.s		$f2, $f2, $f3
		div.s 		$f6, $f1, $f2				# m = (float)(seg.y2 - seg.y1) / (float)(seg.x2 - seg.x1);
Div0_drawLine:
	
	li_f			(0x3f800000, $f1)			# $f1 = 1.0f
	c.le.s 			1, $f6, $f1					# code1: m <= 1.0f
	neg.s 			$f1, $f1					# $f1 = -1.0f
	c.lt.s 			2, $f1, $f6					# code2: -1.0f < m
	
												# if (seg.x1 != seg.x2 && (m <= 1.0f && m >= -1.0f))
	bc1t 			0, doLineY					# if (seg.x1 != seg.x2)
	bc1f 			1, doLineY					# && if (m <= 1.0f)
	bc1f 			2, doLineY					# && if (-1.0f < m)
		jal 		LineByX
		j 			end_drawLine		
doLineY:										# else
	jal 			LineByY
		
end_drawLine:
	lw 				$ra, 0($sp)					# restore return
	addi 			$sp, $sp, 4
	
	#StopTimer
	#PrintTimeDelta
jr $ra											# returns (void)
#-

#----------------------------------------------#

#---#
LineByX: 											# params ($f31 x.1, f30 y.1, f29 x.2, $f28 y.2, $a0 color, $f6 m)
	
	c.le.s 			0, $f31, $f29					# code0: x.1 <= x.2
	bc1t			0, noSwap_LineByX				# branch if true
		Swap_f 		($f31, $f29, $f1)
		Swap_f 		($f30, $f28, $f1)
noSwap_LineByX:
	
	mul.s 			$f1, $f6, $f31					# m * x.1
	sub.s 			$f9, $f30, $f1					# b = y.1 - (m * x.1)
	
	la 				$s0, pixelBuffer				# $s0 = pixelBuffer base address
	li_f			(screenWidth, $f7)				# $f7 = screenWidth
	li_f			(screenHeight, $f8)				# $f8 = screenHeight
	cvt.s.w 		$f7, $f7
	cvt.s.w 		$f8, $f8
	
	li_f		(0x3f800000, $f4)					# $f4 = 1.0f
	mov.s 			$f2, $f31						# x = x.1
for_LineByX:
	c.lt.s 			0, $f29, $f2					# code0: x.2 < x
	bc1t 			0, forBreak_LineByX				# branch if true
	
		c.le.s 		4, $f7, $f2						# code4: (XRES <= x)
		bc1t 		4, forBreak_LineByX				# if (XRES < x) break
	
		c.lt.s 		1, $f2, $f0						# code1: (x < 0)
		bc1f		1, skipX0_LineByX				# if (x < 0)
			mov.s	$f2, $f0						# x = 0
		skipX0_LineByX:
		
		mul.s 		$f3, $f6, $f2					# (m * x)
		add.s 		$f3, $f3, $f9					# y = (m * x) + b
		
		#c.lt.s 		1, $f2, $f0						# code1: (x < 0)
		c.lt.s 		2, $f3, $f0						# code2: (y < 0)
		c.lt.s 		3, $f8, $f3						# code3: (YRES < y)
		
		
		#bc1t 		1, forCont_LineByX 				# if (x < 0) continue
		bc1t 		2, forCont_LineByX				# || if (y < 0) continue
		bc1t 		3, forCont_LineByX				# || if (YRES < y) continue
		
		ArrayGet_f	($s0, $f3, $f2, $f7)			# $v0 = pixelBuffer[y][x] address # (%arr, %row, %col, %ncol)
		sw 			$a0, 0($v0)						# pixelBuffer[y][x] = color
		
		#-- pause if address out of bounds --#
		li			$t1, screenSize					# total pixles in buffer
		sll			$t1, $t1, 2						# byte size of buffer
		add			$t1, $s0, $t1					# bufferLastAddr = bufferBaseAddr + totalSize
		ble			$v0, $t1, forCont_LineByX
			move	$t2, $v0
			li		$v0, 10
			syscall
			
forCont_LineByX:
	add.s 			$f2, $f2, $f4					# ++x						
	j 				for_LineByX							
forBreak_LineByX:
jr $ra												# returns (void)

#//must render leht
#if (seg.x1 > seg.x2)
#{
#	float temp = seg.x1;
#	seg.x1 = seg.x2;
#	seg.x2 = temp;
#
#	temp = seg.y1;
#	seg.y1 = seg.y2;
#	seg.y2 = temp;
#}
#
#float b = seg.y1 - (m * seg.x1);
#
#for (int x = seg.x1; x <= seg.x2; ++x)
#{
#	int y = (m * x) + b;
#
#	if (surface == 1)
#	{
#		segment2 vert = { x, y + 1, x, (YRES - 2) - y };
#		drawLine(vert, '.', -1);
#	}
#
#	//prevent buffer overrun from out of bounds points, but maintain line slope
#	if (x < 0 || y < 0 || y >= YRES) continue;
#	if (x >= XRES) break;
#
#	pixelBuffer[y][x] = c;
#}
#-

#----------------------------------------------#

#---#
LineByY: 											# params ($f31 x.1, f30 y.1, f29 x.2, $f28 y.2, $a0 color, $f6 m)
	
	c.le.s 			0, $f30, $f28					# code0: y.1 <= y.2
	bc1t 			0, noSwap_LineByY				# branch if true
		Swap_f 		($f31, $f29, $f1)				#(%reg1, %reg2, %temp)
		Swap_f 		($f30, $f28, $f1)				#(%reg1, %reg2, %temp)
noSwap_LineByY:
	
	sub.s 			$f7, $f28, $f30					# (seg.y2 - seg.y1)	
	sub.s 			$f8, $f29, $f31					# (seg.x2 - seg.x1)
	div.s 			$f6, $f8, $f7					# m = (float)(seg.x2 - seg.x1) / (float)(seg.y2 - seg.y1)
	
	mul.s 			$f1, $f6, $f30					# m * y.1
	sub.s 			$f9, $f31, $f1					# b = x.1 - (m * y.1)
	
	la 				$s0, pixelBuffer				# $s0 = pixelBuffer base address
	li_f			(screenWidth, $f7)				# $f7 = screenWidth
	li_f			(screenHeight, $f8)				# $f8 = screenHeight
	cvt.s.w 		$f7, $f7
	cvt.s.w 		$f8, $f8
	
	li_f			(0x3f800000, $f4)				# $f4 = 1.0f
	mov.s 			$f2, $f30						# y = y.1
for_LineByY:
	c.le.s 			0, $f2, $f28					# code0: y <= y.2
	bc1f 			0, forBreak_LineByY				# branch if true
		
		c.le.s 		4, $f8, $f2						# code4: (YRES <= y)
		bc1t 		4, forBreak_LineByY				# if (YRES < y) break
		
		c.lt.s 		1, $f2, $f0						# code1: (y < 0)
		bc1f		1, skipY0_LineByY				# if (y < 0)
			mov.s	$f2, $f0						# y = 0
skipY0_LineByY:
		
		
		mul.s		$f3, $f6, $f2					# (m * y)
		add.s 		$f3, $f3, $f9					# x = (m * y) + b
		
		#c.lt.s 		1, $f2, $f0						# code1: (y < 0)
		c.lt.s 		2, $f3, $f0						# code2: (x < 0)
		c.lt.s 		3, $f7, $f3						# code3: (XRES < x)
		
		
		#bc1t 		1, forCont_LineByY 				# if (y < 0) continue
		bc1t 		2, forCont_LineByY				# || if (x < 0) continue
		bc1t 		3, forCont_LineByY				# || if (XRES < x) continue
		
		ArrayGet_f	($s0, $f2, $f3, $f7)			# $v0 = pixelBuffer[y][x] address # (%arr, %row, %col, %ncol) 
		sw 			$a0, 0($v0)						# pixelBuffer[y][x] = color
		
				#-- pause if address out of bounds --#
		li			$t1, screenSize					# total pixles in buffer
		sll			$t1, $t1, 2						# byte size of buffer
		add			$t1, $s0, $t1					# bufferLastAddr = bufferBaseAddr + totalSize
		ble			$v0, $t1, forCont_LineByY		# if $v0 larger tahn buffer
			move	$t2, $v0
			li		$v0, 10							# pause program
			syscall
			
forCont_LineByY:
	add.s 			$f2, $f2, $f4					# ++y
	j 				for_LineByY
forBreak_LineByY:
jr $ra												# returns (void)

#//must render top to bottom
#if (seg.y1 > seg.y2)
#{
#	float temp = seg.x1;
#	seg.x1 = seg.x2;
#	seg.x2 = temp;
#
#	temp = seg.y1;
#	seg.y1 = seg.y2;
#	seg.y2 = temp;
#}
#
#m = (float)(seg.x2 - seg.x1) / (float)(seg.y2 - seg.y1);
#float b = seg.x1 - (m * seg.y1);
#
#for (int y = seg.y1; y <= seg.y2; ++y)
#{
#	int x = (m * y) + b;
#
#
#	if (surface == 1)
#	{
#		segment2 vert = { x, y + 1, x, (YRES - 2) - y };
#		drawLine(vert, '.', -1);
#	}
#
#	if (x < 0 || y < 0 || x >= XRES) continue;
#	if (y >= YRES) break;
#
#	pixelBuffer[y][x] = c;
#}
#-

#----------------------------------------------#

		#-- Not Used. Made as macro --#
#---# Get data in array func
#arrayGet: 									# params ( 0($sp) arr, 4($sp) row, 8($sp) col, 12($sp) ncol )
#	lw				$a0, 0($sp)
#	lw				$a1, 4($sp)
#	lw				$a2, 8($sp)
#	lw				$a3, 12($sp)
#	
#	mul 			$t1, $a3, $a1	 		# ncolumns * row
#	add 			$t1, $t1, $a2		 	# (ncolumn * row) + col
#	sll 			$t1, $t1, 2	 			# ((ncolumn * row) + col) * byte size (left shift 2 == * 4)
#	add 			$v0, $a0, $t1	 		# (((ncolumn * row) + col) * byte size) + arrayBaseAddress
#jr $ra										# returns ($v0 IdxAddr)
#-

#----------------------------------------------#

#---# loads a line from the Map array
LoadMapLine: 								# params ($a0 idx)
	addi 			$t0, $0, 16		
	mulu 			$t0, $t0, $a0			# 16 * %num to move to next line
	la 				$t0, Map($t0)
	l.s 			$f31, 0($t0)			# x.1
	l.s 			$f30, 4($t0)			# y.1
	l.s 			$f29, 8($t0)			# x.2
	l.s 			$f28, 12($t0)			# y.2
jr $ra										# returns ($f31 x.1, f30 y.1, f29 x.2, $f28 y.2)
#-

#----------------------------------------------#

#---
done: 
	done
#-
