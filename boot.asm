org 0x7C00
    jmp boot

    label disk_id byte at $$
    boot_msg db "PeaceOS boot loader. Version 0.04",13,10,0
    reboot_msg db "Press any key to reboot...",13,10,0

write_str:
        push ax si
        mov ah, 0x0E
 @:
        lodsb
        test al, al
        jz @1
        int 0x10
        jmp @
 @1:
        pop si ax
        ret

error:
        pop si
        call write_str

reboot:
        mov si, reboot_msg
        call write_str
        xor ah, ah
        int 0x16
        jmp 0xFFFF:0

boot:

        jmp 0:@2
 @2:
        mov ax, cs
        mov ds, ax
        mov es, ax

        mov ss, ax
        mov sp, $$

        sti
        xor ax,ax
        mov al,3h
        int 10h

        mov [disk_id], dl

        mov si, boot_msg
        call write_str

        jmp reboot

rb 510 - ($ - $$)
db 0x55,0xAA