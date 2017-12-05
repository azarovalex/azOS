; option_screen:
; Asks the User to choose which Interface (CLI/TUI) 
; Uses Joshua Beck's Mouse Library
option_screen:
        call os_clear_screen
        
        call win_set_up
        mov si,option1
        call win_print_string
        call win_new_line
        mov si,option2
        call win_print_string
        call win_new_line
        ; CLI
        ret
        ;call os_hide_cursor
        mov dh,19
        mov dl,61
        call os_move_cursor
        mov si,clistring
        call os_print_string
        mov dh,20
        mov dl,62
        call os_move_cursor
        mov si,next
        call os_print_string
        mov dh,20
        mov dl,7
        call os_move_cursor
        mov si,prev
        call os_print_string
        mov dh,19
        mov dl,6
        call os_move_cursor
        mov si,guistring
        call os_print_string
        ; Time to Check
        call mouse_init ; Initialize the Mouse Driver
        jmp .mouse_loop ; Get into a Loop
.mouse_loop:
        ;call scrn_update
        call mouselib_freemove ; Set the mouse to freely move around
        jc .key ; Key pressed? Then Exit
        call mouselib_anyclick ; Clicked? Then Let's see what's going around
        jc .check_1
        jmp .mouse_loop
.key:
        jmp .mouse_loop
.check_1:
        call mouselib_locate
        cmp cx,62
        je .check_1_y
        jmp .check_2_x
.check_1_y:
        cmp dx,20
        je .gotocli
        jmp .check_2_x
.check_2_x:
        call mouselib_locate
        cmp cx,7
        je .check_2_y
        jmp .mouse_loop
.check_2_y:
        cmp dx,20
        je .gui
        jmp .mouse_loop
.gui:
        call PCGUI
.gotocli:
        ; Switch Video Modes when in CLI
        mov ax,0x1112
        xor bl,bl
        int 0x10
        ret
        option1 db 'Welcome to POSNT 1.0.7.2',0
        option2 db ' Click the arrow below your interface. CLI Command Line, GUIGraphical',0
        next db 175,0
        prev db 174,0
        clistring db 'CLI',0
        guistring db 'GUI',0
; ------------------------------------------------------------------
; Some Data