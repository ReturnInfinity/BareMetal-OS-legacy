; =============================================================================
; BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2008-2016 Return Infinity -- see LICENSE.TXT
;
; INIT HDD
; =============================================================================

align 16
db 'DEBUG: INIT_HDD '
align 16


init_hdd:
	call init_ahci
	call init_bmfs
	ret


; =============================================================================
; EOF
