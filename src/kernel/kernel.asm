format binary as 'BIN'
use16

my_loop:
        mov ax, 1003h   ; Disable blinking
        xor bl, bl
        int 10h

        call PCGUI
        jmp my_loop

include "mouse.asm"
include "bck.asm"
include "osfunctions.asm"
include "pcgui.asm"
include "pcguiw.asm"
include "winlib.asm"





EntryPoint:
    mov ax, 50h     ; Initialize stack
    cli
    mov ss, ax
    mov sp, 1024    ; 1kb stack
    sti

    mov ax, 1003h   ; Disable blinking
    xor bl, bl
    int 10h

    mov ax, 21h     ; First we need to add INT 21h for DOS compatibility
    mov dx, Int21h
    int 42h

    mov ax, 20h
    mov dx, Int20h
    int 42h

    mov ax, 41h
    mov dx, ShowMenu
    int 42h

    call ShowMenu
    jmp $

include 'interrupts.asm'


logo db \
"              ____    _____",  10, 13, \
"             / __ \  / ____|", 10, 13, \
"  __ _  ____| |  | || (",      10, 13, \
" / _` ||_  /| |  | | \___ \",  10, 13, \
"| (_| | / / | |__| | ____) |", 10, 13, \
" \__,_|/___| \ ____/ |_____/",  10, 13, \
"      version 0.1 alpha",      10, 13, 0

bsuir db 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, \
" ______        _______  __    __   __   ______      ", 10, 13, \
"|   _  \      /       ||  |  |  | |  | |   _  \     ", 10, 13, \
"|  |_)  |    |   (----`|  |  |  | |  | |  |_)  |    ", 10, 13, \
"|   _  <      \   \    |  |  |  | |  | |      /     ", 10, 13, \
"|  |_)  | .----)   |   |  `--'  | |  | |  |\  \----.", 10, 13, \
"|______/  |_______/     \______/  |__| | _| `._____|", 10, 13, 0