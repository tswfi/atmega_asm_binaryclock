;
; binaryclock.asm
;
; Created: 12/22/2017 6:23:55 PM
; Author : tatuw_000
;
; chip: atmega328p

; pin assignments:
; external increment input PD2 (interrupt driven) high to trigger
; PC0,1,2,3,4,5 for the column (0 is the leftmost column) led cathodes
; PD4,5,6,7 for the row led anodes
; and pb3, pb4, pb5 and pc6 is reset, miso, mosi, sck (programming)
; pb6 pb7 crystal (16mhz)

.nolist
.include "m328pdef.inc"
.list

; memory map
.def temp         = r16        ; general purpose temp
.def temp2        = r17        ; another general purpose temp
.def seconds      = r18        ; seconds
.def minutes      = r19        ; minutes
.def hours        = r20        ; hours
.def mscnt        = r21        ; millisecond loop counter, tmp1_cmp_isr will increment this every 10ms and clear every second
.def col          = r22        ; used when outputting values
.def zero         = r23        ; quick zero

.org 0x0000
    rjmp reset                 ; reset vector
.org INT0addr
    rjmp int0_isr              ; handle int0 
.org OC1Aaddr 
    rjmp tmr1_cmp_isr          ; timer1 compare handler

reset:
    ; set PC0-5 as outputs (columns)
    ldi temp,0b00111111
    out DDRC,temp

    ; set PD5-7 as outputs (rows)
	; and PD2 as input with pull up
    ldi temp,0b11110000         ; pd2=0 p5-7=1
    out DDRD,temp
	ldi temp,(1 << PD2)         ; to enable the pull up set the pin up
	out PORTD, temp            

    ; set up our timer
    ldi temp,(1 << WGM12)|(1<<CS12)    ; CTC mode and /256 prescaler
    sts TCCR1B,temp

    ldi temp, 0x18             ; upper 
    ldi temp2, 0x69            ; lower
    sts OCR1AH,temp            ; and set it
    sts OCR1AL,temp2           ; and set it

    ldi temp,(1 << OCIE1A)     ; enable timer1 compare interrupts
    sts TIMSK1, temp    

	; set up our button interrupt
	ldi temp, (1 << ISC01)     ; trigger on falling edge
	sts EICRA, temp
	ldi temp, (1 << INT0)      ; enable int0 interrupts
	out EIMSK, temp

    sei                        ; enable global interrupts

loop:
    ; just output our data into our matrix all the time
    rcall output
    rjmp loop

int0_isr:                      ; handle int0
	ldi seconds, 59            ; set seconds to 60 and call increment to get minutes incremented
	rcall tick                 ; call tick, it will advance minutes and clear seconds to 0
reti

tmr1_cmp_isr:                  ; called every 100ms
    push temp                  ; save our temp
    inc mscnt                  ;  
    cpi mscnt,0x0A             ; check if we are on the tenth time  (1 sec)
    brlt PC+3                  ; if not go back
    rcall tick                 ; call tick
    clr mscnt                  ; clear the counter for the next time
    pop temp                   ; restore temp
reti

bin2digits:
    clr temp2                  ; clear temp2
bin2digits_loop:
    ; separate number to its digits
    ; only for 2 digit numbers
    ; input in temp
    ; ouput tens in temp2 and ones in temp
    cpi temp,10                ; check if we are over 10
    brlt PC+4                  ; if we are just return
    inc temp2                  ; increment temp2
    subi temp,10               ; decrement temp by 10
    rjmp bin2digits_loop       ; go again untill we are under 10
ret


tick:
    ; for every call here increment the seconds and check if we need to increment
    ; minutes or hours also. This should be called once every second
    inc seconds                ; always increment seconds
    cpi seconds,0x3c           ; check if seconds is 60
    brne PC+3                  ; if it was not jump forward
    clr seconds                ; clear seconds
    inc minutes                ; increment minutes
    cpi minutes,0x3c           ; check if minutes is 60
    brne PC+4                  ; if it was not jump over
    clr seconds                ; clear seconds
    clr minutes                ; clear minutes
    inc hours                  ; increment hours
    cpi hours,24               ; check if hours is 24
    brne PC+4                  ; if not jump over
    clr seconds                ; back to zero you go
    clr minutes
    clr hours
ret

outrow:
    ; temp will contain our number to be shown
    ; will just shift the value to correct place in portd and
    ; output it
    lsl temp
    lsl temp
    lsl temp
    lsl temp
	; keep our input pin set (pd2)
	sbr temp, (1<<PD2)
    out portd,temp
ret

outnumber:
	; temp contains the full value of the number to show
	; col contains the column to use
	out portd, zero             ; first blank out
	out portc, col              ; set our column
	rcall bin2digits            ; separate the number to temp and temp2
	rcall outrow				; display temp on the row in question
	rcall delay                 ; keep it for a while
	out portd, zero				; and off

	lsl col						; shift our column pattern
	sbr col, 1					; and set the first bit
	out portc, col              ; and out the column

	mov temp, temp2				; get temp2 from bin2digits
	rcall outrow				; display it
    rcall delay                 ; keep it for a while
	out portd, zero				; and off

	lsl col						; shift the pattern for the next one
	sbr col, 1					; and set the first bit
ret

output:
    ; loop through all the columns and write out the 
    ; seconds minutes and hours (splitted to two separate columns)
    ldi col, 0b1111_1110        ; prefill coll with a nice pattern we can rotate for each number
    mov temp, seconds           ; get our full seconds
	rcall outnumber				; and out them

    mov temp, minutes           ; get our full seconds
	rcall outnumber

	mov temp, hours
	rcall outnumber
ret

delay:
    dec zero                    ; reuse our zero for the delay :)
	brne delay
ret