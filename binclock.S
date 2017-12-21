	;; **************************************************
	;; Binary clock for attiny88
	;; Author: Tatu Wikman (@tswfi)
	;;
	;; **************************************************

	.nolist
	.include "tn84def.inc"
	.list

	;; ====================
	;; Declarations
	;;

	.def sec = r17 		; keep the value of seconds
	.def min = r18		; value of minutes
	.def hour = r19		; value of hours

	;;
	;; ====================

	;; ====================
	;; Reset and interrupts

	.org 0x0000
	rjmp MAIN ; Reset vector
	reti ; Int vector 1


	.org 0x0020
	rjmp tmr1overflow


	;; ====================

	;; ====================
	;; Main init
MAIN:

	ldi r16, 0x00000001
	;; ====================


	;; ====================
	;; Program loop

LOOP:
	nop
	nop
	rjmp LOOP

	;; ====================

tmr1overflow:
	nop
	ret