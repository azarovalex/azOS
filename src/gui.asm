GUI:
    call draw_window
    mov dh, 4
    mov dl, 15
    call move_cursor
    call draw_logo

    mov dh, 14
    mov dl, 30
    call move_cursor
    mov si, .title
    call print_string

    mov dh, 16
    mov dl, 32
    call move_cursor
    mov si, .line1text
    call print_string

    mov dh, 17
    mov dl, 32
    call move_cursor
    mov si, .line2text
    call print_string

    mov dh, 18
    mov dl, 32
    call move_cursor
    mov si, .line3text
    call print_string

    mov dh, 19
    mov dl, 32
    call move_cursor
    mov si, .line4text
    call print_string

    mov dh, 20
    mov dl, 32
    call move_cursor
    mov si, .reboottext
    call print_string

    mov dh, 16
    mov dl, 29
    call move_cursor
    mov si, .cursor
    call print_string

    mov dh, 26
    mov dl, 0
    call move_cursor

.choose_loop:
    mov ah, 0h
    int 16h

    cmp al, 13
    je .enter

    cmp al, 'w'
    je .up

    cmp al, 's'
    je .down

    jmp .choose_loop

.up:
    cmp [.curr_cursor_pos], 1
    je .choose_loop

    mov dh, 15
    mov dl, 29
    mov al, [.curr_cursor_pos]
    add dh, al
    dec al
    mov [.curr_cursor_pos], al
    call move_cursor
    mov si, .nocursor
    call print_string

    mov dh, 15
    add dh, [.curr_cursor_pos]
    mov dl, 29
    call move_cursor
    mov si, .cursor
    call print_string

    mov dh, 26
    mov al, 0
    call move_cursor

    jmp .choose_loop

.down:
    cmp [.curr_cursor_pos], 5
    je .choose_loop

    mov dh, 15
    mov dl, 29
    mov al, [.curr_cursor_pos]
    add dh, al
    add al, 1
    mov [.curr_cursor_pos], al
    call move_cursor
    mov si, .nocursor
    call print_string

    mov dh, 15
    add dh, [.curr_cursor_pos]
    mov dl, 29
    call move_cursor
    mov si, .cursor
    call print_string

    mov dh, 26
    mov al, 0
    call move_cursor

    jmp .choose_loop

.enter:
    cmp [.curr_cursor_pos], 1
    ;je filemanager

    cmp [.curr_cursor_pos], 2
    ;je paratrooper

    cmp [.curr_cursor_pos], 3
    ;je textedit

    cmp [.curr_cursor_pos], 4
    ;je changecolors

    cmp [.curr_cursor_pos], 5
    je reboot
    jmp $

.title      db "Choose something...", 0
.line1text  db "File Manager", 0
.line2text  db "Paratrooper", 0
.line3text  db "Text Edit", 0
.line4text  db "Change Colors", 0
.reboottext db "Reboot", 0
.cursor     db "->", 0
.nocursor   db "  ", 0

.curr_cursor_pos db 01h


;======================================================
;
;
reboot:
    mov ax, 5307h
    mov cx, 3
    mov bx, 1
    int 15h


;======================================================
;
;
paratrooper:
    ;mov

;=======================================================
;
;
draw_logo:
    pusha
    mov si, .logo
    mov ah, 0Eh
.next_char:
    lodsb
    cmp al, 0
    je .end
    int 10h
    jmp .next_char
.end:
    popa
    ret

.logo db \
"                       ,ad8888ba,    ad88888ba   ",  10, 13, 15 dup (20h),\
"                      d8'     `'8b  d8'     '8b  ",  10, 13, 15 dup (20h),\
"                     d8'        `8b Y8,          ",  10, 13, 15 dup (20h),\
",adPPYYba, 888888888 88          88 `Y8aaaaa,    ",  10, 13, 15 dup (20h),\
"''     `Y8      a8P' 88          88   `*****8b,  ",  10, 13, 15 dup (20h),\
",adPPPPP88   ,d8P'   Y8,        ,8P         `8b  ",  10, 13, 15 dup (20h),\
"88,    ,88 ,d8'       Y8a.    .a8P  Y8a     a8P  ",  10, 13, 15 dup (20h),\
"`'8bbdP'Y8 888888888   `'Y8888Y''    'Y88888P'   ",  10, 13, 0


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
    call move_cursor
    mov si, .close
    call print_string

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
    call move_cursor
    ret

.title         db 'azOS - 0.1a', 0
.bottom_title  db 'Choose something...', 0
.close         db '[x]', 0

; Standart GUI colors
window_color     db 0xF0    ;
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
    call move_cursor
    mov ah, 09h
    mov al, ' '
    mov bh, 0
    mov cx, 2000
    int 10h           ; Background color is already in BX

    mov dh, 0         ; Draw top string
    mov dl, 1
    call move_cursor
    pop ax
    mov si, ax
    call print_string

;    mov dh, 24        ; Draw bottom string
;    mov dl, 1
;    call move_cursor
    pop ax
;    mov si, ax
;    call print_string

    popa
    ret

;===============================================
;  color, start_x, start_y, width, height
;  bl     dl       dh       si     di
draw_rectangle:
    pusha
.draw_line:
    call move_cursor   ; Position is in already in the registers

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



;===============================================
;
;
move_cursor:
    pusha
    mov bh, 0
    mov ah, 2
    int 10h
    popa
    ret


;==============================================
;
;
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
    ret
