/* M68HC11 Interrupt vectors table
   Copyright (C) 1999 Free Software Foundation, Inc.
   Written by Stephane Carrez (stcarrez@worldnet.fr)	

This file is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 2, or (at your option) any
later version.

In addition to the permissions in the GNU General Public License, the
Free Software Foundation gives you unlimited permission to link the
compiled version of this file with other programs, and to distribute
those programs without any restriction coming from the use of this
file.  (The General Public License restrictions do apply in other
respects; for example, they cover modification of the file, and
distribution when not linked into another program.)

This file is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; see the file COPYING.  If not, write to
the Free Software Foundation, 59 Temple Place - Suite 330,
Boston, MA 02111-1307, USA.  */

	.sect .text
	.globl _start

;; Default interrupt handler.
	.sect .text
def:
	rti

	.globl _debug_user_vectors
_debug_user_vectors = 0

;; 
;; Interrupt vectors are in a specific section that is
;; mapped at 0xffc0. For the example program, the reset handler
;; points to the generic crt0 entry point.
;;
	.sect .vectors
	.globl vectors
vectors:
	.word def		; ffc0
	.word def		; ffc2
	.word def		; ffc4
	.word def		; ffc6
	.word def		; ffc8
	.word def		; ffca
	.word def		; ffcc
	.word def		; ffce
	.word def		; ffd0
	.word def		; ffd2
	.word def		; ffd4

	;; SCI
	.word def		; ffd6

	;; SPI
	.word def		; ffd8
	.word def		; ffda (PAII)
	.word def		; ffdc (PAOVI)
	.word def		; ffde (TOI)

	;; Timer Output Compare
	.word def          	; ffe0
	.word def	 	; ffe2
	.word def		; ffe4
	.word def		; ffe6
	.word def		; ffe8

	;; Timer Input compare
	.word def		; ffea
	.word def		; ffec
	.word def		; ffee

	;;  Misc
	.word def	 	; fff0 (RTII)
	.word IRQ_interrupt	; fff2 (IRQ)
	.word def		; fff4 (XIRQ)
	.word def		; fff6 (SWI)
	.word def		; fff8 (ILL)
	.word def		; fffa (COP Failure)
	.word def		; fffc (COP Clock monitor)
	.word _start		; fffe (reset)

