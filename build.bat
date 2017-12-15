@ echo Check for fasm.exe...
@ if not exist C:\fasmw17164\fasm.exe (
    echo FAIL: Plz, specify path to FASM compier!
    @ pause
    exit
)

@ echo Building bootloader...
@ cd src
@ C:\fasmw17164\fasm.exe boot.asm
@ move boot.img ..\build\azOS.img

@ echo Building kernel
@ C:\fasmw17164\fasm.exe kernel.asm
@ move kernel.bin ..\build\AZOSKERN.BIN
@ pause
