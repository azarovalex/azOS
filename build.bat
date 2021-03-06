@echo off
echo Check for fasm.exe...
if not exist C:\fasmw17164\fasm.exe (
    echo FAIL: Plz, specify path to FASM compier!
    pause
    exit
)

echo Building bootloader...
cd src
C:\fasmw17164\fasm.exe boot.asm
move boot.img ..\build\azOS.img

echo Building kernel...
C:\fasmw17164\fasm.exe kernel.asm
move kernel.bin ..\build\AZOSKERN.BIN
cd ..

echo Copying the kernel and apps to the disk image...
imdisk -a -f build\azOS.img -s 1440K -m B:
copy build\AZOSKERN.BIN b:\
copy build\games\*.COM b:\
copy build\*.COM b:\
imdisk -D -m B:

echo BUILD OK!
pause
