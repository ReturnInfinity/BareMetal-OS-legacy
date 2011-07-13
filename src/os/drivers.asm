; =============================================================================
; BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2008-2011 Return Infinity -- see LICENSE.TXT
;
; Driver Includes
; =============================================================================

align 16
db 'DEBUG: DRIVERS  '
align 16


%include "drivers/hdd.asm"
%include "drivers/fat16.asm"
%include "drivers/pci.asm"
%include "drivers/net/rtl8169.asm"
%include "drivers/net/i8254x.asm"
;%include "drivers/net/bcm57xx.asm"


NIC_DeviceVendor_ID:			; The supported list of NICs
; Realtek 816x/811x Gigabit Ethernet
dd 0x816710EC, 0x00008169		; 8110SC/8169SC
dd 0x816810EC, 0x00008169		; 8111/8168B
dd 0x816910EC, 0x00008169		; 8169

; Intel 8254x Gigabit Ethernet
dd 0x10008086, 0x00008254		; 82542 (Fiber)
dd 0x10018086, 0x00008254		; 82543GC (Fiber)
dd 0x10048086, 0x00008254		; 82543GC (Copper)
dd 0x10088086, 0x00008254		; 82544EI (Copper)
dd 0x10098086, 0x00008254		; 82544EI (Fiber)
dd 0x100A8086, 0x00008254		; 82540EM
dd 0x100C8086, 0x00008254		; 82544GC (Copper)
dd 0x100D8086, 0x00008254		; 82544GC (LOM)
dd 0x100E8086, 0x00008254		; 82540EM
dd 0x100F8086, 0x00008254		; 82545EM (Copper)
dd 0x10108086, 0x00008254		; 82546EB (Copper)
dd 0x10118086, 0x00008254		; 82545EM (Fiber)
dd 0x10128086, 0x00008254		; 82546EB (Fiber)
dd 0x10138086, 0x00008254		; 82541EI
dd 0x10148086, 0x00008254		; 82541ER
dd 0x10158086, 0x00008254		; 82540EM (LOM)
dd 0x10168086, 0x00008254		; 82540EP (Mobile)
dd 0x10178086, 0x00008254		; 82540EP
dd 0x10188086, 0x00008254		; 82541EI
dd 0x10198086, 0x00008254		; 82547EI
dd 0x101a8086, 0x00008254		; 82547EI (Mobile)
dd 0x101d8086, 0x00008254		; 82546EB
dd 0x101e8086, 0x00008254		; 82540EP (Mobile)
dd 0x10268086, 0x00008254		; 82545GM
dd 0x10278086, 0x00008254		; 82545GM
dd 0x10288086, 0x00008254		; 82545GM
dd 0x105b8086, 0x00008254		; 82546GB (Copper)
dd 0x10758086, 0x00008254		; 82547GI
dd 0x10768086, 0x00008254		; 82541GI
dd 0x10778086, 0x00008254		; 82541GI
dd 0x10788086, 0x00008254		; 82541ER
dd 0x10798086, 0x00008254		; 82546GB
dd 0x107a8086, 0x00008254		; 82546GB
dd 0x107b8086, 0x00008254		; 82546GB
dd 0x107c8086, 0x00008254		; 82541PI
dd 0x10b58086, 0x00008254		; 82546GB (Copper)
dd 0x11078086, 0x00008254		; 82544EI
dd 0x11128086, 0x00008254		; 82544GC

; Broadcom BCM57xx Gigabit Ethernet
dd 0x000312AE, 0x00005700		; 5700, Broadcom
dd 0x164514E4, 0x00005700		; 5701
dd 0x16A614E4, 0x00005700		; 5702
dd 0x16A714E4, 0x00005700		; 5703C, 5703S
dd 0x164814E4, 0x00005700		; 5704C
dd 0x164914E4, 0x00005700		; 5704S
dd 0x165D14E4, 0x00005700		; 5705M
dd 0x165314E4, 0x00005700		; 5705
dd 0x03ED173B, 0x00005700		; 5788
dd 0x167714E4, 0x00005700		; 5721, 5751
dd 0x167D14E4, 0x00005700		; 5751M
dd 0x160014E4, 0x00005700		; 5752
dd 0x160114E4, 0x00005700		; 5752M
dd 0x166814E4, 0x00005700		; 5714C
dd 0x166914E4, 0x00005700		; 5714S
dd 0x167814E4, 0x00005700		; 5715C
dd 0x167914E4, 0x00005700		; 5715S

dd 0x00000000, 0x00000000		; End of list


; =============================================================================
; EOF
