GUI:
    call draw_window        ; Draw standard window
    call draw_logo          ; Draw logo

    call main_menu_options  ; Print main menu options
    mov [.curr_cursor_pos], 1

.choose_loop:               ; Allow user to move throught menu
    mov ah, 10h              ; Get keyboard input
    int 16h

    cmp al, 13              ; User pressed Enter
    je .enter

    cmp ah, 48h             ; Wanna move up?
    je .up

    cmp ah, 50h             ; Or down?
    je .down

    jmp .choose_loop

.up:
    cmp [.curr_cursor_pos], 1     ; already at the top? then return
    je .choose_loop

    mov dh, 15                    ; redraw cursor (->) position
    mov dl, 29
    mov al, [.curr_cursor_pos]
    add dh, al
    dec al
    mov [.curr_cursor_pos], al
    ;call move_cursor
    int 43h
    mov si, .nocursor
    ;call print_string
    int 44h

    mov dh, 15
    add dh, [.curr_cursor_pos]
    mov dl, 29
    ;call move_cursor
    int 43h
    mov si, cursor
    ;call print_string
    int 44h

    mov dh, 26
    mov al, 0
    ;call move_cursor
    int 43h

    jmp .choose_loop

.down:
    cmp [.curr_cursor_pos], 3       ; already at the bottom? then return
    je .choose_loop

    mov dh, 15                      ; redraw cursor (->) position
    mov dl, 29
    mov al, [.curr_cursor_pos]
    add dh, al
    add al, 1
    mov [.curr_cursor_pos], al
    ;call move_cursor
    int 43h
    mov si, .nocursor
    ;call print_string
    int 44h

    mov dh, 15
    add dh, [.curr_cursor_pos]
    mov dl, 29
    ;call move_cursor
    int 43h
    mov si, cursor
    ;call print_string
    int 44h

    mov dh, 26
    mov al, 0
    ;call move_cursor
    int 43h


    jmp .choose_loop

.enter:                           ; Run choosed app
    cmp [.curr_cursor_pos], 3
    je shut_down

    cmp [.curr_cursor_pos], 2
    je change_colors

    ;cmp [.curr_cursor_pos], 1
    call FileManager

    cmp ax, 0                     ; User want to run an app?
    jne OpenApp                   ; Yeah

    jmp GUI                       ; No (he pressed Esc in the File Manager)





.nocursor   db "  ", 0
.curr_cursor_pos db 01h
cursor     db "->", 0


change_colors:
   mov ax, [.isNightMode]
   xor [.isNightMode], 1
   cmp ax, 0
   je .night
.day:
   mov [window_color], 0xF0
   mov [header_color], 0xCF
   mov [shadow_color], 0x00
   mov [background_color], 0x70
   jmp GUI
.night:
   mov [window_color], 0x82
   mov [header_color], 0x4F
   mov [shadow_color], 0x00
   mov [background_color], 0x90
   jmp GUI

.isNightMode dw 0
;======================================================
;
;
main_menu_options:
    mov dh, 14
    mov dl, 30
    ;call move_cursor
    int 43h
    mov si, .title
    ;call print_string
    int 44h

    mov dh, 16
    mov dl, 32
    int 43h
    mov si, .line1text
    int 44h

    mov dh, 17
    mov dl, 32
    int 43h
    mov si, .line2text
    int 44h

    mov dh, 18
    mov dl, 32
    int 43h
    mov si, .reboottext
    int 44h

    mov dh, 16
    mov dl, 29
    int 43h
    mov si, cursor
    int 44h

    mov dh, 26
    mov dl, 0
    int 43h

    ret


.title      db "Choose something...", 0
.line1text  db "File Manager", 0
.line2text  db "Change Colors", 0
.reboottext db "Shut down", 0


;=========================================================
;
;
FileManager:
    pusha

    call draw_window        ; Draw standard window

    mov dl, 10              ; Show first line of help text...
    mov dh, 4
    ;call move_cursor
    int 43h
    mov si, .title_string_1
    ;call print_string
    int 44h

    inc dh                  ; ...and the second
    ;call move_cursor
    int 43h
    mov si, .title_string_2
    ;call print_string
    int 44h

    mov dl, 23              ; Get into position for file list text
    mov dh, 8
    ;call move_cursor
    int 43h

    mov ax, .buffer
    call get_file_list ; int 43h

    mov si, ax              ; SI = location of file list string

    mov word [.filename], 0 ; Terminate string in case leave without select
    mov bx, 0               ; Counter for total number of files

.next_name:
    mov cx, 0               ; Counter for dot in filename

.more:
    lodsb                   ; get next character in file name, increment pointer

    cmp al, 0               ; End of string?
    je .done_list

    cmp al, ','                     ; Next filename? (String is comma-separated)
    je .newline

    inc cx                          ; Valid character in name
    cmp cx, 9                       ; At dot position? (processed first 8 characters)
    jne .print_name
    cmp al, ' '                     ; No extension?
    je .more

    pusha
    mov al, '.'                     ; Print dot in filename
    mov ah, 0Eh
    int 10h
    popa

.print_name:
    cmp al, ' '                     ; Skip spaces
    je .more

    pusha                           ; Some BIOSes corrupt DX and BP
    mov ah, 0Eh                     ; Not a space, print it!
    int 10h
    popa
    jmp .more

.newline:
    mov dl, 23                      ; Go back to starting X position
    inc dh                          ; But jump down a line
    ;call move_cursor
    int 43h

    inc bx                          ; Update the number-of-files counter
    cmp bx, 14                      ; Limit to one page of names
    jl .next_name


.done_list:
    cmp bx, 0                       ; BX is our number-of-files counter
    jle .leave                      ; No files to process

    add bl, 8                       ; Last file -> line number (file 1 on line 7)

    mov dl, 20                      ; Set up starting position for selector
    mov dh, 8

.more_select:
    ;call move_cursor
    int 43h

    mov si, .position_string        ; Show '->' next to filename
    ;call print_string
    int 44h

    mov ch, 32
    mov ah, 1
    mov al, 3                       ; Must be video mode for buggy BIOSes!
    int 10h

.another_key:
    mov ah, 10h
    int 16h
    cmp ah, 48h                     ; Up pressed?
    je .go_up
    cmp ah, 50h                     ; Down pressed?
    je .go_down
    cmp al, 13                      ; Enter pressed?
    je .file_selected
    cmp al, 27                      ; Esc pressed?
    je .esc_pressed
    jmp .more_select                ; If not, wait for another key


.go_up:
    cmp dh, 8                       ; Already at top?
    jle .another_key

    mov dl, 20
    ;call move_cursor
    int 43h

    mov si, .position_string_blank  ; Otherwise overwrite '>>>>>'
    ;call print_string
    int 44h

    dec dh                          ; Row to select (increasing down)
    jmp .more_select


.go_down:                           ; Already at bottom?
    cmp dh, bl
    jae .another_key

    mov dl, 20
    ;call move_cursor
    int 43h

    mov si, .position_string_blank  ; Otherwise overwrite '>>>>>'
    ;call print_string
    int 44h

    inc dh
    jmp .more_select


.file_selected:
    sub dh, 8                       ; Started printing list at 7 chars
                                        ; down, so remove that to get the
                                        ; starting point of the file list

    mov ax, 12                      ; Then multiply that by 12 to get position
    mul dh                          ; in file list (filenames are 11 chars
                                        ; plus 1 for comma seperator in the list)

    mov si, .buffer                 ; Going to put selected filename into
    add si, ax                      ; The .filename string has appropriate spaces,
    mov cx, 11                      ; but does not include 0 terminator
    mov di, .filename
    rep movsb
    mov ax, 0
    stosw                           ; Shouldn't exceed .filename size with terminator

.leave:
    popa

    mov ax, .filename               ; Filename string location in AX
    ret


.esc_pressed:
    popa
    mov ax, 0

    ret


        .title_string_1 db 'Please select a file and press Enter', 0
        .title_string_2 db 'or Esc to return back to the main menu...', 0

        .position_string_blank  db '  ', 0
        .position_string        db '->', 0

        .buffer         rb 256 ;db "KERNEL  BIN,GAME    COM",0
        .filename       rb 15


;======================================================
;
;
shut_down:
    mov ax, 5307h
    mov cx, 3
    mov bx, 1
    int 15h

;=======================================================
;
;
draw_logo:
    pusha
    mov dh, [.x_pos]
    mov dl, [.y_pos]
    ;call move_cursor
    int 43h

    mov si, .logo
    mov ah, 0Eh
.next_char:
    lodsb
    cmp al, 13
    je .newline
    cmp al, 0
    je .end
    int 10h
    jmp .next_char
.newline:
    int 10h

    movzx cx, [.y_pos]
    mov al, ' '
    mov bh, 0
.newline_cycle:
    int 10h
    loop .newline_cycle

    jmp .next_char
.end:
    popa
    ret

.x_pos db 4
.y_pos db 15

.logo db \
"                       ,ad8888ba,    ad88888ba",  10, 13,\
"                      d8'     `'8b  d8'     '8b", 10, 13,\
"                     d8'        `8b Y8,",         10, 13,\
",adPPYYba, 888888888 88          88 `Y8aaaaa,",   10, 13,\
"''     `Y8      a8P' 88          88   `*****8b,", 10, 13,\
",adPPPPP88   ,d8P'   Y8,        ,8P         `8b", 10, 13,\
"88,    ,88 ,d8'       Y8a.    .a8P  Y8a     a8P", 10, 13,\
"`'8bbdP'Y8 888888888   `'Y8888Y''    'Y88888P'",  10, 13, 0


;=======================================================
;
;
draw_window:
    mov ax, .title
    mov cx, .bottom_title
    movzx bx, [background_color]
    call draw_background

    mov bl, [header_color]
    mov dl, 5          ; X start pos
    mov dh, 2          ; Y start pos
    mov si, 66         ; X finish pos
    mov di, 3          ; Y finish pos
    call draw_rectangle

    mov dh, 2                    ; Draw [x]
    mov dl, 68
    ;call move_cursor
    int 43h
    mov si, .close
    ;call print_string
    int 44h

    mov bl, [window_color]
    mov dl, 5         ; X start pos
    mov dh, 3         ; Y start pos
    mov si, 67        ; X finish pos
    mov di, 22         ; Y finish pos
    call draw_rectangle

    mov bl, [shadow_color]      ; Draw bottom shadow
    mov dl, 6
    mov dh, 22
    mov si, 66
    mov di, 23
    call draw_rectangle

    mov bl, [shadow_color]      ; Draw left shadow
    mov dl, 71
    mov dh, 3
    mov si, 1
    mov di, 23
    call draw_rectangle

    mov dh, 25
    mov dl, 0
    ;call move_cursor
    int 43h
    ret

.title         db 'azOS - 0.1a', 0
.bottom_title  db 'Choose something...', 0
.close         db '[x]', 0

; Standart GUI colors
window_color     db 0xF0
header_color     db 0xCF
shadow_color     db 0x00
background_color db 0x70

;===============================================
;
;
draw_background:
    pusha
    push cx
    push ax

    mov dh, 0
    mov dl, 0
    ;call move_cursor
    int 43h
    mov ah, 09h
    mov al, ' '
    mov bh, 0
    mov cx, 2000
    int 10h           ; Background color is already in BX

    mov dh, 0         ; Draw top string
    mov dl, 1
    ;call move_cursor
    int 43h
    pop ax
    mov si, ax
    ;call print_string
    int 44h

    pop ax

    popa
    ret

;===============================================
;  color, start_x, start_y, width, height
;  bl     dl       dh       si     di
draw_rectangle:
    pusha
.draw_line:
    ;call move_cursor   ; Position is in already in the registers
    int 43h

    mov ah, 09h        ; Color is already in the BL register
    mov al, ' '
    mov bh, 0
    mov cx, si
    int 10h

    inc dh
    movzx ax, dh
    cmp ax, di
    jne .draw_line

    popa
    ret