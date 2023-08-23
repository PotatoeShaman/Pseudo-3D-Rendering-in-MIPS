# Author:	Alec Stobbs
# Date:		Oct 25, 2022
# Description:	Psuedo-3D Project
# File Purpose:	Trig Tables

.data

Sine_Table:
	.word	0x00000000	#sin(0.000000) = 0.000000
	.word	0x3f3504f3	#sin(0.785398) = 0.707107
	.word	0x3f800000	#sin(1.570796) = 1.000000
	.word	0x3f3504f3	#sin(2.356194) = 0.707107
	.word	0xb3bbbd2e	#sin(3.141593) = -0.000000
	.word	0xbf3504f5	#sin(3.926991) = -0.707107
	.word	0xbf800000	#sin(4.712389) = -1.000000
	.word	0xbf3504f5	#sin(5.497787) = -0.707107

Cosine_Table:
	.word	0x3f800000	#cos(0.000000) = 1.000000
	.word	0x3f3504f3	#cos(0.785398) = 0.707107
	.word	0xb33bbd2e	#cos(1.570796) = -0.000000
	.word	0xbf3504f3	#cos(2.356194) = -0.707107
	.word	0xbf800000	#cos(3.141593) = -1.000000
	.word	0xbf3504f1	#cos(3.926991) = -0.707107
	.word	0x324cde2e	#cos(4.712389) = 0.000000
	.word	0x3f3504f2	#cos(5.497787) = 0.707107

#.eqv PI4 0.785398163397448309616	# PI/4 | Used for 8 rotations states of player
