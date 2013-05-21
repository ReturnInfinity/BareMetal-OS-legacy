@IF %1.==. GOTO NODISK

@echo Writing Master Boot Record
dd.exe if=bmfs_mbr.sys of=%1

@echo Writing Pure64+Software
copy /b pure64.sys + kernel64.sys software.sys
dd.exe if=software.sys of=%1 bs=512 seek=16
@GOTO END

:NODISK
@echo Error: Missing argument for disk to make bootable.

:END