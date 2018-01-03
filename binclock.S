;
; binaryclock.asm
;
; Created: 12/22/2017 6:23:55 PM
; Author : tatuw_000
;
; chip: atmega328p

; pin assignments:
; external increment input PD2 (interrupt driven) high to trigger
; PC0,1,2,3,4,5 for the columns (0 is the leftmost column) led cathodes
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
.def button       = r24        ; btn status. this will increment every 10ms if pressed

.org 0x0000
    rjmp reset                 ; reset vector
.org OC1Aaddr
    rjmp tmr1_cmp_isr          ; timer1 compare handler

reset:
    ; set PC0-5 as outputs (columns)
    ldi temp,(1 << PC0)|(1 << PC1)|(1 << PC2)|(1 << PC3)|(1 << PC4)|(1 << PC5)
    out DDRC,temp

    ; set PD4-7 as outputs (rows)
    ; and PD2 as input with pull up
    ldi temp,(1 << PD4)|(1 << PD5)|(1 << PD6)|(1 << PD7)
    out DDRD,temp
    ; enable pull up on PD2
    ldi temp,(1 << PD2)
    out PORTD, temp

    ; set up our timer
    ldi temp,(1 << WGM12)|(1<<CS12)    ; CTC mode and /256 prescaler
    sts TCCR1B,temp
    ; load ctc match value
    ldi temp, 0x02             ; upper
    ldi temp2, 0x70            ; lower
    sts OCR1AH,temp            ; and set it
    sts OCR1AL,temp2           ; and set it

    ldi temp,(1 << OCIE1A)     ; enable timer1 compare interrupts
    sts TIMSK1, temp

    sei                        ; enable global interrupts

loop:
    ; main loop
    rcall checkbutton          ; check for button
    rcall tock                 ; advance minutes and hours etc as necessary
    rcall output               ; output the data to the leds
    rjmp loop                  ; rinse repeat

checkbutton:
    ; handle button presses. tmr1_cmp_isr will increment button every 10ms if it
    ; is pressed and zero it out if not.
    ; this will give us a nice debounce for short presses and also allows us to
    ; check when the button is pressed down longer

    ; short press
    cpi button, 0x08           ; if button is 0x08 (held down for at least 80ms)
    brne checkbutton_ret1
    inc minutes                ; increment minutes
    clr seconds                ; clear seconds
    inc button                 ; increment button by one so that we wont hit it again
checkbutton_ret1:

    ; long press
    cpi button, 0x64           ; if button is over a second down
    brlt checkbutton_ret2
    ldi temp, 0x05             ; increment minutes by 5
    add minutes, temp
    clr seconds                ; and clear seconds
    subi button, 0x05          ; and subtract five from button to get it to repeat after 50ms
checkbutton_ret2:
ret

tmr1_cmp_isr:                  ; called every 10ms
    push temp                  ; save our temp
    in temp, SREG              ; save sreg
    push temp

    ; increment our ms counter on every call
    inc mscnt                  ;
    cpi mscnt,0x64             ; check if we are on the 100th time  (1 sec)
    brlt tmr1_cmp_isr_not_sec  ; if not don't advance seconds
    clr mscnt                  ; clear the counter for the next time
    inc seconds                ; plus one second
tmr1_cmp_isr_not_sec:

    ; handle the button
    ; on every isr increment the button counter. if the button is not pressed
    ; clear the counter.
    sbic pind,(1<<PD2)         ; if the button is not pressed:
    clr button                 ; clear it

    cpi button, 0xff           ; do not allow button counter to roll over
    breq tmr1_cmp_usr_not_over
    inc button                 ; every time increment the button counter
tmr1_cmp_usr_not_over:

    pop temp                   ; restore sreg
    out sreg, temp
    pop temp                   ; restore temp
reti

bin2digits:
    ; separate number to its digits
    ; only for 2 digit numbers
    ; input in temp
    ; ouput tens in temp2 and ones in temp
    clr temp2                  ; clear temp2
bin2digits_loop:
    cpi temp,10                ; check if temp is over 10
    brlt bin2digits_done       ; if we are just return
    inc temp2                  ; increment temp2 (tens)
    subi temp,10               ; decrement temp by 10 (ones)
    rjmp bin2digits_loop       ; go again untill temp is under 10
bin2digits_done:
ret


tick:
    ; for every call here increment the seconds and check if we need to
    ; increment minutes or hours also. This should be called once every second
    inc seconds                ; always increment seconds
tock:
    ; advance minutes and hours as necessary, this can be called all the time
    cpi seconds,0x3c           ; check if seconds is 60
    brlt tock_check_min              ; if not check minutes
    clr seconds                ; clear seconds
    inc minutes                ; increment minutes
tock_check_min:
    cpi minutes,0x3c           ; check if minutes is 60
    brlt tock_check_hours      ; if not check hours
    clr seconds                ; clear seconds
    clr minutes                ; clear minutes
    inc hours                  ; increment hours
tock_check_hours:
    cpi hours,24               ; check if hours is 24
    brlt tock_ret              ; if not just return
    clr seconds                ; back to zero you go
    clr minutes
    clr hours
tock_ret:
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
    out portd, zero            ; first blank out
    out portc, col             ; set our column
    rcall bin2digits           ; separate the number to temp and temp2
    rcall outrow               ; display temp on the row in question
    rcall delay                ; keep it on for short a while
    out portd, zero            ; and off

    lsl col                    ; shift our column pattern
    sbr col, 1                 ; and set the first bit
    out portc, col             ; and out the column

    mov temp, temp2            ; get temp2 from bin2digits
    rcall outrow               ; display it
    rcall delay                ; keep it for a while
    out portd, zero            ; and off

    lsl col                    ; shift the pattern for the next one
    sbr col, 1                 ; and set the first bit
ret

output:
    ; loop through all the columns and write out the
    ; seconds minutes and hours (splitted to two separate columns)
    ldi col, 0b11111110        ; prefill coll with a nice pattern we can rotate for each number
    mov temp, seconds          ; get our full seconds
    rcall outnumber            ; and out them

    mov temp, minutes          ; get our full minutes
    rcall outnumber

    mov temp, hours            ; and hours
    rcall outnumber
ret

delay:
    ldi zero, 0x01             ; reuse our zero for the delay :)
delay_loop:
    dec zero
    brne delay_loop
ret
