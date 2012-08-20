; =============================================================================
; BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2008-2012 Return Infinity -- see LICENSE.TXT
;
; Driver Includes
; =============================================================================

align 16
db 'DEBUG: DRIVERS  '
align 16

%ifidn HDD,PIO
%include "drivers/storage/pio.asm"
%else
%include "drivers/storage/ahci.asm"
%endif

%ifidn FS,FAT16
%include "drivers/filesystems/fat16.asm"
%else
%include "drivers/filesystems/bmfs.asm"
%endif

%include "drivers/pci.asm"

%ifndef DISABLE_RTL8169
%include "drivers/net/rtl8169.asm"
%endif

%ifndef DISABLE_I8254X
%include "drivers/net/i8254x.asm"
%endif
;%include "drivers/net/bcm57xx.asm"


NIC_DeviceVendor_ID:			; The supported list of NICs
; The ID's are Device/Vendor

%ifndef DISABLE_RTL8169
; Realtek 816x/811x Gigabit Ethernet
dd 0x8169FFFF
dd 0x816710EC		; 8110SC/8169SC
dd 0x816810EC		; 8111/8168B
dd 0x816910EC		; 8169
%endif

%ifndef DISABLE_I8254X
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
%endif

%ifndef DISABLE_BCM57XX
; Broadcom BCM57xx Gigabit Ethernet
dd 0x5700FFFF
dd 0x000312AE		; 5700, Broadcom
dd 0x164514E4		; 5701
dd 0x16A614E4		; 5702
dd 0x16A714E4		; 5703C, 5703S
dd 0x164814E4		; 5704C
dd 0x164914E4		; 5704S
dd 0x165D14E4		; 5705M
dd 0x165314E4		; 5705
dd 0x03ED173B		; 5788
dd 0x167714E4		; 5721, 5751
dd 0x167D14E4		; 5751M
dd 0x160014E4		; 5752
dd 0x160114E4		; 5752M
dd 0x166814E4		; 5714C
dd 0x166914E4		; 5714S
dd 0x167814E4		; 5715C
dd 0x167914E4		; 5715S
%endif

dq 0x0000000000000000	; End of list

; =============================================================================
; EOF
