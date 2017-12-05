; WINLIB/IO/STDIO.ASM 
; This file contains the Standard Input Output Functions
; for a simple Window.
; Function : win_new_line
; What it does?
; Gets the cursor position,
; DH = Y Axis
; DL = X Axis
; DL is set to 5 the start point of the Window.
; DH is incremented and the cursor is moved By Parameters
; DH = 5
; DL = [PREDL] + 1 (Where PREDL was the DL returned by the OS_GET_CURSOR_POS
win_new_line:
        call os_get_cursor_pos
        mov dl,5
        inc dh
        call os_move_cursor
        ret

; Function win_print_string
; Prints string in a Window.
; If the Y Position of the String is > 5
; then it prints a newline
win_print_string:
        mov ah,0x0e
        lodsb
        cmp al,0
        je .done
        call os_get_cursor_pos ; Get the cursor position
        cmp dh,22
        je .redraw 
        cmp dl,65
        je .next_line
        jmp .print
.next_line:
        mov dl,6
        inc dh
        call os_move_cursor
        jmp .print
.print:
        int 0x10
        jmp win_print_string
.redraw:
        call win_set_up
        jmp win_print_string
.done:
        ret
; Function : win_set_up
; Sets up the Window.
win_set_up:
        mov ax, .title
        mov bx, .footer
        mov cx, 0x9F    ; Color
        call os_draw_background
        call check_for_background
        mov bl, 0x1F    
        mov dl, 5               
        mov dh, 2               
        mov si, 61              
        mov di, 3               
        call os_draw_block
        mov dh,2
        mov dl,5
        call os_move_cursor
        ;mov si,.prog_head
        ;call os_print_string
        mov dh,2
        mov dl,63
        call os_move_cursor
        mov si,close
        call os_print_string
        mov bl, 0x70    ; White on red
        mov dl, 5               ; Start X position
        mov dh, 3               ; Start Y position
        mov si, 61              ; Width
        mov di, 22              ; Finish Y position
        call os_draw_block
        ; Bottom Shadow
        mov bl,0x0F
        mov dl,6
        mov dh,22
        mov si,61
        mov di,23
        call os_draw_block
        ; Side Shadow
        mov bl,0x0F
        mov dl,66
        mov dh,3
        mov si,1
        mov di,23
        call os_draw_block
        ; Left Border
        mov bl,0x1F
        mov dl,65
        mov dh,3
        mov si,1
        mov di,22
        call os_draw_block
        ; Right Border
        mov bl,0x1F
        mov dl,5
        mov dh,3
        mov si,1
        mov di,22
        call os_draw_block
        ; Bottom Border
        mov bl, 0x1F    
        mov dl, 5               
        mov dh, 21              
        mov si, 61              
        mov di, 22              
        call os_draw_block
        ; Move the cursor to the default position
        mov dh,3
        mov dl,6
    call os_move_cursor
    ret
    .head db 'PCGUI2',0
    .title      db 'azOS - 0.01a', 0
    .footer     db 'Choose an option...', 0
    close db '[x]',0