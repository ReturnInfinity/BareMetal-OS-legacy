; =============================================================================
; BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2008-2016 Return Infinity -- see LICENSE.TXT
;
; Driver Includes
; =============================================================================

align 16
db 'DEBUG: DRIVERS  '
align 16


%include "drivers/pci.asm"

%include "drivers/pic.asm"

%include "drivers/storage/ahci.asm"

%include "drivers/filesystems/bmfs.asm"

%include "drivers/net/rtl8169.asm"
%include "drivers/net/i8254x.asm"


NIC_DeviceVendor_ID:			; The supported list of NICs
; The ID's are Device/Vendor

; Realtek 816x/811x Gigabit Ethernet
dd 0x8169FFFF
dd 0x816710EC		; 8110SC/8169SC
dd 0x816810EC		; 8111/8168B
dd 0x816910EC		; 8169

; Intel 8254x Gigabit Ethernet
dd 0x8254FFFF
dd 0x10008086		; 82542 (Fiber)
dd 0x10018086		; 82543GC (Fiber)
dd 0x10048086		; 82543GC (Copper)
dd 0x10088086		; 82544EI (Copper)
dd 0x10098086		; 82544EI (Fiber)
dd 0x100A8086		; 82540EM
dd 0x100C8086		; 82544GC (Copper)
dd 0x100D8086		; 82544GC (LOM)
dd 0x100E8086		; 82540EM
dd 0x100F8086		; 82545EM (Copper)
dd 0x10108086		; 82546EB (Copper)
dd 0x10118086		; 82545EM (Fiber)
dd 0x10128086		; 82546EB (Fiber)
dd 0x10138086		; 82541EI
dd 0x10148086		; 82541ER
dd 0x10158086		; 82540EM (LOM)
dd 0x10168086		; 82540EP (Mobile)
dd 0x10178086		; 82540EP
dd 0x10188086		; 82541EI
dd 0x10198086		; 82547EI
dd 0x101a8086		; 82547EI (Mobile)
dd 0x101d8086		; 82546EB
dd 0x101e8086		; 82540EP (Mobile)
dd 0x10268086		; 82545GM
dd 0x10278086		; 82545GM
dd 0x10288086		; 82545GM
dd 0x105b8086		; 82546GB (Copper)
dd 0x10758086		; 82547GI
dd 0x10768086		; 82541GI
dd 0x10778086		; 82541GI
dd 0x10788086		; 82541ER
dd 0x10798086		; 82546GB
dd 0x107a8086		; 82546GB
dd 0x107b8086		; 82546GB
dd 0x107c8086		; 82541PI
dd 0x10b58086		; 82546GB (Copper)
dd 0x11078086		; 82544EI
dd 0x11128086		; 82544GC

dq 0x0000000000000000	; End of list


; =============================================================================
; EOF
