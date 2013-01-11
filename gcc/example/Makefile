#!/usr/bin/make -f

##################################################################
# Makefile for 68HC11 projects                                   #
# GNU copyright 2002-2003 by Aurelien Jarno <aurel32@debian.org> #
##################################################################

#
# Project files
#
PROG = test
ASMS = vectors.s
SRCS = main.c
INCLUDES = main.h ports.h 
OBJS = $(SRCS:.c=.o) $(ASMS:.s=.o)


#
# C flags used by default to compile a program
#
CFLAGS = -m68hc11 -mshort -Wall -Wmissing-prototypes -Os -g0 -msoft-reg-count=0 -fomit-frame-pointer -ffixed-z -fshort-enums 

LDFLAGS = -m68hc11 -mshort -Wl,-m,m68hc11elfb \
	  -Wl,-defsym,_io_ports=0x1000


#
# Options to creates the .s19 or .b files from the elf
#
OBJCOPY_FLAGS = --remove-section=page0 \
                --remove-section=.page0


####################################
# This part should not be modified #
####################################
#
# Programs location
#
DEVC_PREFIX=m68hc11-
CC=$(DEVC_PREFIX)gcc
CXX=$(DEVC_PREFIX)gcc
AS=$(DEVC_PREFIX)as
AR=$(DEVC_PREFIX)ar
SIZE=$(DEVC_PREFIX)size
OBJCOPY=$(DEVC_PREFIX)objcopy
OBJDUMP=$(DEVC_PREFIX)objdump
LD=$(DEVC_PREFIX)ld

#
# Main rules
#
all: 	$(PROG).elf $(PROG).s19 $(PROG).b

$(PROG).elf: $(OBJS) $(INCLUDES) memory.x
	$(CC) $(LDFLAGS) -o $@ $(OBJS) $(LIBADD)

clean:
	rm -f *.o *.elf *.s19 *.b *.a

#
# Some useful rules
#
dump:	$(PROG).elf
	$(OBJDUMP) -d $(PROG).elf

size:   $(PROG).s19
	$(SIZE) $(PROG).s19


#
# Implicit rules
#
# .elf is for the simulator and gdb
# .s19 is for some downloader and the simulator
# .b   is a binary dump
#
.SUFFIXES: .elf .s19 .b

.elf.s19:
	$(OBJCOPY) --output-target=srec $(OBJCOPY_FLAGS) $< $*.s19

.elf.b:
	$(OBJCOPY) --output-target=binary --gap-fill=255 \
                   $(OBJCOPY_FLAGS) $< $*.b
		   
