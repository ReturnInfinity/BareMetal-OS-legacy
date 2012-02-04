; =============================================================================
; BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2008-2012 Return Infinity -- see LICENSE.TXT
;
; ACHI Driver
; =============================================================================

align 16
db 'DEBUG: ACHI   '
align 16


; -----------------------------------------------------------------------------
; achiread -- Read data from a SATA hard drive
; IN:	RAX = starting sector # to read
;	RCX = number of sectors to read
;	RDX = disk #
;	RDI = memory location to store sectors
; OUT:	RAX = RAX + number of sectors that were read
;	RCX = number of sectors that were read (0 on error)
;	RDI = RDI + (number of sectors read * 512)
;	All other registers preserved
achiread:

ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; achiwrite -- Write data tp a SATA hard drive
; IN:	RAX = starting block # to write
;	RCX = number of sectors to write
;	RDX = disk #
;	RSI = memory location of sectors
; OUT:	RAX = RAX + number of sectors that were written
;	RCX = number of sectors that were written (0 on error)
;	RSI = RSI + (number of sectors written * 512)
;	All other registers preserved
achiwrite:

ret
; -----------------------------------------------------------------------------


; =============================================================================
; EOF
