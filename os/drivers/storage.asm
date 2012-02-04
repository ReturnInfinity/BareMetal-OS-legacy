; =============================================================================
; BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2008-2012 Return Infinity -- see LICENSE.TXT
;
; Disk Storage Functions
; =============================================================================

align 16
db 'DEBUG: STORAGE'
align 16


; -----------------------------------------------------------------------------
; readblocks -- Read blocks on the hard drive
; IN:	RAX = starting block # to read
;	RCX = number of blocks to read
;	RDX = disk #
;	RDI = memory location to store blocks (Ideally 2MiB alligned)
; OUT:	RAX = RAX + number of blocks that were read
;	RCX = number of blocks that were read (0 on error)
;	RDI = RDI + (number of blocks read * 2097152)
;	All other registers preserved
readblocks:

ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; writeblocks -- Write blocks on the hard drive
; IN:	RAX = starting block # to write
;	RCX = number of blocks to write
;	RDX = disk #
;	RSI = memory location of blocks (Ideally 2MiB alligned)
; OUT:	RAX = RAX + number of blocks that were written
;	RCX = number of blocks that were written (0 on error)
;	RSI = RSI + (number of blocks written * 2097152)
;	All other registers preserved
writeblocks:

ret
; -----------------------------------------------------------------------------


; =============================================================================
; EOF
