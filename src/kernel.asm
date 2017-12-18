format binary as 'BIN'
use16

Kernel:
    call InitOS        ; Set up enviroment for kernel
    jmp GUI

InitOS:
    mov ax, 1003h   ; Disable blinking
    xor bl, bl
    int 10h

    ; Stack is already setted up properly in the bootloader

    mov al, 20h
    mov dx, Int20h
    int 42h

    mov al, 43h
    mov dx, move_cursor
    int 42h

    mov al, 44h
    mov dx, print_string
    int 42h

    ret
;
; ax - buffer for filenames
;
get_file_list:
    pusha

    mov word [.fileListAdr], ax   ; Store string location

    xor ax, ax                    ; Reset floppy
    mov dl, 0
    stc
    int 13h
    jnc .floppy_ok                 ; Did the floppy reset OK?
                                    ; If not,then
    jmp $                           ; Crash :)


.floppy_ok:

     mov bx, 0x90                  ; Load root directory to buffer
     mov es, bx
     mov bx, KernelBuffer
     mov ax, 19
     mov cx, 14
     int 40h

     xor ax, ax
     mov si, KernelBuffer               ; Data reader from start of filenames

     mov word di, [.fileListAdr]   ; Name destination buffer


.start_entry:
     mov al, [si+11]                 ; File attributes for entry
     test al, 10h                    ; Is this a directory entry?
     jnz .skip                       ; Yes, ignore it

     mov al, [si]
     cmp al, 229                     ; If we read 229 = deleted filename
     je .skip

     cmp al, 0                       ; 1st byte = entry never used
     je .done


     mov cx, 1                       ; Set char counter
     mov dx, si                      ; Beginning of possible entry

.testdirentry:
     inc si
     mov al, [si]                    ; Test for most unusable characters
     cmp al, ' '                     ; Windows sometimes puts 0 (UTF-8) or 0FFh
     jl .nxtdirentry
     cmp al, '~'
     ja .nxtdirentry

     inc cx
     cmp cx, 11                      ; Done 11 char filename?
     je .gotfilename
     jmp .testdirentry


.gotfilename:                           ; Got a filename that passes testing
     mov si, dx                      ; DX = where getting string
     mov cx, 11
     rep movsb
     mov ax, ','                     ; Use comma to separate for next file
     stosb

.nxtdirentry:
     mov si, dx                      ; Start of entry, pretend to skip to next

.skip:
     add si, 32                      ; Shift to next 32 bytes (next filename)
     jmp .start_entry


.done:
    dec di                          ; Zero-terminate string
    mov ax, 0                       ; Don't want to keep last comma!
    stosb

    popa
    ret


    .fileListAdr  dw 0

; ax - filename
;
OpenApp:
    mov si, ax       ; Load app to RAM
    mov ax, 0x1010
    mov gs, ax
    int 41h

    mov bl, 0Fh            ; Clear screen with black
    mov dl, 0
    mov dh, 0
    mov si, 80
    mov di, 25
    call draw_rectangle

    mov dh, 0              ; Move cursor to the left top of the screen
    mov dl, 0
    int 43h

    mov ax, 1000h    ; Set up registers
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov sp, 0xFFFE
    push 0               ; 0x0000 for ret
    mov ax, 0x20CD       ; Opcode for int 20h
    mov [es:0], ax  ; ret in app will jump here
    jmp 1000h:100h

; Interrupt for leaving the app
Int20h:
    mov ax, 90h
    mov ds, ax
    mov fs, ax
    mov gs, ax
    mov es, ax
    xor ax, ax
    mov ss, ax
    mov sp, 0x7bfe

    jmp Kernel


move_cursor:
    pusha
    mov bh, 0
    mov ah, 2
    int 10h
    popa
    iret


print_string:
    pusha
    mov ah, 0Eh
.next_char:
    lodsb
    cmp al, 0
    je .end
    int 10h
    jmp .next_char
.end:
    popa
    iret

include "gui.asm"

KernelBuffer:












