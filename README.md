# Binary clock with attiny in assembler

While in school I implemented a binary clock with a pic16f874 assembler and after playing a while with arduinos I wanted to replicate it with arduino.

# Getting started

Finding information about avr assembler is not that easy so I decided to write down my journey of this project. The decision to start doing this came yesterday night 20.12.2017 and this might take a while :)

After quite a lot of googling I settled on Avra and avrdude combination

* http://avra.sourceforge.net/
* http://www.nongnu.org/avrdude/

to my surprise '''dnf install avra avrdude''' on fedora worked nicely.

For editor I've been using vscode for a while, so somekind of asm higlight would be nice. Didn't find anything good yet. Simulator would also be nice but it seems there arent that many options outside Atmel Studio, just found http://savannah.nongnu.org/projects/simulavr which might be worth looking into.

Found the include file for attiny88 from this repo: https://github.com/DarkSector/AVR/blob/bb279327a4b5240401fee3b5f772716d9a2d2e4f/asm/include/tn88def.inc Thanks https://github.com/DarkSector

# Day1

Started this repo, found out that attiny88 is not supported by avra, switched to attiny85 (might need to add a shift register into the mix...)

Added makefile and asm file that does nothing and got it "working"

# Day2 (and 3)

After fumbling around I decided to try atmel studio and switch to atmega328p (as I had those laying around). And after reading the datasheet too many times and trying various things I finally have a working prototype.

# Day4 (and 5)

Debouncing a button with interrupts is a pita. switched to another debouncing scheme.

Also noticed that I didn't save the sreg in the isr which caused random things to happen :)

But now its more or less ready :)

# Day something

Cleaned up the code and commented it a bit more.

Also fixed avra builds and the makefile.

The clock has been running on my bench for few days and it seems to keep time quite well.

# Final thoughs

After all of this what did I learn?

* Select a tool that is well supported (and a chip you already have in stock :)
* Thinking in bits takes a while to get used to again (its been a while)
* Simulator is really nice when learning

The code is still kind of a mess and I bet it needs more documentation (wont probably understand it after few months)

# more to read

* A MORON'S GUIDE TO STARTING IN AVR ASSEMBLER v1.3 https://sites.google.com/site/avrasmintro/home
* Attiny88 datasheet: http://ww1.microchip.com/downloads/en/DeviceDoc/doc8008.pdf
* AVR Assembler http://ww1.microchip.com/downloads/en/DeviceDoc/40001917A.pdf
* AVR Instruction Set Manual http://ww1.microchip.com/downloads/en/devicedoc/atmel-0856-avr-instruction-set-manual.pdf
* Beginners Introduction to the Assembly Language of ATMEL AVR Microprocessors www.avr-asm-download.de/beginner_en.pdf
