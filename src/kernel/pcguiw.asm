; PCGUI : GUI 
PCGUI:
                        call win_set_up
                        mov si,winman
                        call win_print_string
; Notepad Icon
                        mov bl, 0x1F    ; White on red
                        mov dl, 7               ; Start X position
                        mov dh, 5               ; Start Y position
                        mov si, 11              ; Width
                        mov di, 8               ; Finish Y position
                        call os_draw_block
                        mov dl,8
                        mov dh,6
                        call os_move_cursor
                        mov si,notepad
                        call os_print_string
                        ; Notepad Location
                        ; Y = 6 (DH) (DX)
                        ; X = 16 (DL) (CX)
                        mov dl,16
                        mov dh,6
                        call os_move_cursor
                        mov si,next
                        call os_print_string
; Memory Editor Icon
                        mov bl, 0x7F    ; White on red
                        mov dl, 7               ; Start X position
                        mov dh, 8               ; Start Y position
                        mov si, 11              ; Width
                        mov di, 11              ; Finish Y position
                        call os_draw_block
                        mov dl,8
                        mov dh,9
                        call os_move_cursor
                        mov si,memedit
                        call os_print_string
                        ; Memedit Location
                        ; Y = 9 (DH)
                        ; X = 16 (DL)
                        mov dl,16
                        mov dh,9
                        call os_move_cursor
                        mov si,next
                        call os_print_string
; Calculator Icon
                        mov bl, 0x8F    ; White on red
                        mov dl, 7               ; Start X position
                        mov dh, 11              ; Start Y position
                        mov si, 11              ; Width
                        mov di, 14              ; Finish Y position
                        call os_draw_block
                        mov dl,8
                        mov dh,12
                        call os_move_cursor
                        mov si,calc
                        call os_print_string
                        ; Calc Location
                        ; Y = 12 (DH)
                        ; X = 16 (DL)
                        mov dl,16
                        mov dh,12
                        call os_move_cursor
                        mov si,next
                        call os_print_string
; Music Keyboard Icon
                        mov bl, 0xCF    ; White on red
                        mov dl, 7               ; Start X position
                        mov dh, 14              ; Start Y position
                        mov si, 11              ; Width
                        mov di, 17              ; Finish Y position
                        call os_draw_block
                        mov dl,8
                        mov dh,15
                        call os_move_cursor
                        mov si,Music
                        call os_print_string
                        ; Piano Location
                        ; Y = 15 (DH)
                        ; X = 16 (DL)
                        mov dl,16
                        mov dh,15
                        call os_move_cursor
                        mov si,next
                        call os_print_string
; Viewer Icon
                        mov bl, 0x4F    ; White on red
                        mov dl, 7               ; Start X position
                        mov dh, 17              ; Start Y position
                        mov si, 11              ; Width
                        mov di, 20              ; Finish Y position
                        call os_draw_block
                        mov dl,8
                        mov dh,18
                        call os_move_cursor
                        mov si,view
                        call os_print_string
                        ; Piano Location
                        ; Y = 15 (DH)
                        ; X = 16 (DL)
                        mov dl,16
                        mov dh,18
                        call os_move_cursor
                        mov si,next
                        call os_print_string
; Reboot Icon
                        mov dl,13
                        mov dh,20
                        call os_move_cursor
                        mov si,reboots
                        call os_print_string
                        mov dl,16
                        mov dh,20
                        call os_move_cursor
                        mov si,next
                        call os_print_string
; Okay so we have a list of useful programs, now let's enter a
; mouse loop and see what the user has chosen
        call mouse_init ; Initialize Mouse Driver
.mouse_loop:
        ;call scrn_update
        call mouselib_freemove ; Set the mouse to freely move around
        jc .key ; Key pressed? Then Continue
        call mouselib_anyclick ; Clicked? Then Let's see what's going around
        jc .check_1
        jmp .mouse_loop ; Jump back
.key:
        jmp option_screen
.check_1: ; Check whether notepad was selected X = CX,Y = DX
        call mouselib_locate ; Locate the Mouse Cursor, X = CX, Y = CX
        ; Now we will check the position of the mouse cursor
        cmp cx,16
        je .check_1_y
        jmp .check_2_x
.check_1_y:
        cmp dx,6
        je .run_npd
        jmp .check_2_x
.run_npd:
        mov si,npdfname
        call run_gui_prog
.check_2_x:
        call mouselib_locate
        cmp cx,16
        je .check_2_y
        jmp .check_3_x
.check_2_y:
        cmp dx,9
        je .runmemedit
        jmp .check_3_x
.runmemedit:
        mov si,basic2
        mov di,memf
        call run_basic
.check_3_x:
        call mouselib_locate
        cmp cx,16
        je .check_3_y
        jmp .check_4_x
.check_3_y:
        cmp dx,12
        je .runcalc
        jmp .check_4_x
.check_4_x:
        call mouselib_locate
        cmp cx,16
        je .check_4_y
        jmp .check_5_x
.check_4_y:
        cmp dx,15
        je .run_piano
        jmp .check_5_x
.check_5_x:
        call mouselib_locate
        cmp cx,16
        je .check_5_y
        jmp .check_rboot1
.check_5_y:
        cmp dx,15
        je .runview
        jmp .check_rboot1
.check_rboot1:
        call mouselib_locate
        cmp cx,16
        je .check_rboot2
        jmp .mouse_loop
.check_rboot2:
        cmp dx,20
        je .reboot
        jmp .mouse_loop
.reboot:
        mov al,0xFE
        out 0x64,al
.runview:
        mov si,viewf
        call run_gui_prog
.run_piano:
        mov si,piano
        call run_gui_prog
.runcalc:
        mov si,basic2
        mov di,calcf
        call run_basic
                view db 'Viewer',0
                Music db 'Piano',0
                memedit db 'Memedit',0
                calc db 'Calc',0
                basic2 db 'BASIC2.COM',0
                notepad db 'Notepad',0
                winman db 'Click the >> Beside a Program to Start it. Any Key to goto the Option Screen',0
                npdfname db 'EDIT.COM',0
                memf db 'MEMEDIT.BAS',0
                calcf db 'CALC.BAS',0
                piano db 'PIANO.COM',0
                viewf db 'VIEWER.COM',0
                reboots db 'Reboot',0
; THIS IS OS SPECIFIC
; YOU MAY USE THIS IN YOUR OS OR DON'T 
; INCLUDE THESE!
; OS Specific Functions
run_gui_prog:
        ret
        call mouselib_remove_driver
        mov ax,si
        mov bx,0
        mov cx,32768
        ;call os_load_file
        mov si,0
        mov di,0
        mov dh,0
        mov dl,0
        call 32768
        jmp PCGUI
run_basic:
        mov ax,si
        mov bx,0
        mov cx,32768
        mov word [prog],di
        ;call os_load_file
        ;mov word si,[prog]
        call 32768
        jmp PCGUI
        prog rb 11