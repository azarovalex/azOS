; MikeOS -- The Mike Operating System kernel
; Copyright (C) 2006 - 2013 MikeOS Developers
;==================================================================
;MikeOS -- License
;==================================================================


;Copyright (C) 2006 - 2013 MikeOS Developers -- http://mikeos.berlios.de

;All rights reserved.

;Redistribution and use in source and binary forms, with or without
;modification, are permitted provided that the following conditions are met:

;    * Redistributions of source code must retain the above copyright
;      notice, this list of conditions and the following disclaimer.

;    * Redistributions in binary form must reproduce the above copyright
;      notice, this list of conditions and the following disclaimer in the
;     documentation and/or other materials provided with the distribution.

;    * Neither the name MikeOS nor the names of any MikeOS contributors
;      may be used to endorse or promote products derived from this software
;      without specific prior written permission.

;THIS SOFTWARE IS PROVIDED BY MIKEOS DEVELOPERS AND CONTRIBUTORS "AS IS"
;AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
;IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
;ARE DISCLAIMED. IN NO EVENT SHALL MIKEOS DEVELOPERS BE LIABLE FOR ANY
;DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
;(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
;SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
;CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
;OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
;USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


;==================================================================

os_draw_block:
        pusha

.more:
        call os_move_cursor             ; Move to block starting position

        mov ah, 09h                     ; Draw colour section
        mov bh, 0
        mov cx, si
        mov al, ' '
        int 10h

        inc dh                          ; Get ready for next line

        mov ax, 0
        mov al, dh                      ; Get current Y position into DL
        cmp ax, di                      ; Reached finishing point (DI)?
        jne .more                       ; If not, keep drawing

        popa
        ret
        
os_move_cursor:
        pusha

        mov bh, 0
        mov ah, 2
        int 10h                         ; BIOS interrupt to move cursor

        popa
        ret
        
os_get_cursor_pos:
        pusha

        mov bh, 0
        mov ah, 3
        int 10h                         ; BIOS interrupt to get cursor position

        mov [.tmp], dx
        popa
        mov dx, [.tmp]
        ret


        .tmp dw 0
        
os_clear_screen:
        pusha
        mov dx, 0                       ; Position cursor at top-left
        call os_move_cursor

        mov ah, 6                       ; Scroll full-screen
        mov al, 0                       ; Normal white on black
        mov bh, 7                       ;
        mov cx, 0                       ; Top-left
        mov dh, 49                      ; Bottom-right
        mov dl, 79
        int 10h
        ;call loadfont
        popa
        ret
        
os_draw_background:
        pusha

        push ax                         ; Store params to pop out later
        push bx
        push cx

        mov dl, 0
        mov dh, 0
        call os_move_cursor

        mov ah, 09h                     ; Draw white bar at top
        mov bh, 0
        mov cx, 80
        mov bl, 01110000b
        mov al, ' '
        int 10h

        ;mov dh, 1
        ;mov dl, 0
        ;call os_move_cursor

        mov ah, 09h                     ; Draw colour section
        mov cx, 1840
        pop bx                          ; Get colour param (originally in CX)
        mov bh, 0
        mov al, ' '
        int 10h

        mov dh, 24
        mov dl, 0
        call os_move_cursor

        mov ah, 09h                     ; Draw white bar at bottom
        mov bh, 0
        mov cx, 80
        mov bl, 01110000b
        mov al, ' '
        int 10h

        mov dh, 24
        mov dl, 1
        call os_move_cursor
        pop bx                          ; Get bottom string param
        mov si, bx
        call os_print_string

        mov dh, 0
        mov dl, 1
        call os_move_cursor
        pop ax                          ; Get top string param
        mov si, ax
        call os_print_string

        mov dh, 1                       ; Ready for app text
        mov dl, 0
        call os_move_cursor

        popa
        ret
os_print_string:
        mov ah,0x0E
        jmp .printloop
.printloop:
        lodsb
        cmp al,0
        je .done
        int 0x10
        jmp .printloop
.done:
        ret
