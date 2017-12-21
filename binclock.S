	;; **************************************************
	;; Binary clock for attiny88
	;; Author: Tatu Wikman (@tswfi)
	;;
	;; **************************************************

	.nolist
	.include "tn85def.inc"
	.list

	;; ====================
	;; Declarations
	;;

	;;
	;; ====================

	;; ====================
	;; Reset and interrupts

	.org 0x0000
	rjmp MAIN ; Reset vector
	reti ; Int vector 1

	;; ====================

	;; ====================
	;; Main init
MAIN:

	;; ====================


	;; ====================
	;; Program loop

LOOP:
	nop
	nop
	rjmp LOOP

	;; ====================
