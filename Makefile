#
# Simple Makefile for programming Atmel AVR MCUs using avra and avrdude
#
# Assemble with 'make', flash hexfile to microcontroller with 'make flash'.
#
# Configuration:
#
# MCU     -> name of microcontroller to program (see 'avrdude -p ?' for a list)
# TARGET  -> target board/programmer to use (see 'avrdude -c ?' for a list)
# DEVICE  -> linux device file refering to the interface your programmer is plugged in to
# INCPATH -> path to the AVR include files
# SRCFILE -> single assembler file that contains the source
#

MCU = atmega328p
TARGET = usbtiny
INCPATH = /usr/share/avra/
SRCFILE = binclock.S

$(SRCFILE).hex: $(SRCFILE)
	avra -l $(SRCFILE).lst -I $(INCPATH) $(SRCFILE)

flash: $(SRCFILE).hex
	avrdude -c $(TARGET) -p $(MCU) -U flash:w:$(SRCFILE).hex:i

showfuses:
	avrdude -c $(TARGET) -p $(MCU) -v 2>&1 |  grep "fuse reads" | tail -n2

clean:
	rm -f $(SRCFILE).hex $(SRCFILE).eep.hex $(SRCFILE).lst $(SRCFILE).obj $(SRCFILE).cof
