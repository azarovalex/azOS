org 7C00h

start:
        sti           ; enable interrupts

        xor ax, ax
        mov al, 3h
        int 10h

        mov si, boot_msg
        call write_str

reboot:
        mov si, reboot_msg
        call write_str
        xor ah,ah
        int 0x16
        jmp 0xFFFF:0

write_str:
        push ax si
        mov ah, 0x0E
write_str_next_symbol:
        lodsb
        test al,al
        jz write_str_end
        int 0x10
        jmp write_str_next_symbol
write_str_end:
        pop si ax
        ret

boot_msg db "tOS boot loader. Version 0.04",10,13,0
reboot_msg db "Press any key to reboot...",10,13,0
rb 510 - ($ - $$)
db 0x55,0xAA



