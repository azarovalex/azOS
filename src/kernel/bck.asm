; PCGUI
; This was borrowed from TachyonOS
; Thanks to Robert Looney and Joshua Beck!
check_for_background:
        mov ax, background_file_name    ; Check if the file exists
        ;call os_file_exists             ; otherwise ignore and resume boot
        stc
        jc .no_file                     ; errors after this will present a message
 
        mov ax, background_file_name    ; Check the file is not too big for buffer
        ;call os_get_file_size
        cmp bx, 3500
        jg .invalid_file
       
        mov ax, background_file_name    ; Load the file
        mov cx, aap_file
        ;call os_load_file
       
        mov si, aap_file                ; Check the file identifier
        mov di, aap_identifier
        ;call os_string_compare
        jnc .invalid_file
       
        add si, 4                       ; Check the subtype
        lodsw
        cmp ax, 0101h
        jne .invalid_file
       
        add si, 2                       ; Check the dimentions
        lodsb
        cmp al, 76
        jne .invalid_file
       
        lodsb
        cmp al, 21
        jne .invalid_file
       
        mov byte [user_background], 1   ; If everything is okay, make it the background
        call draw_user_background
       
.invalid_file:
        ret
.no_file:      
        ret
       
.msg_invalid                                            db 'Invalid Background file', 0
 
 
draw_user_background:
        mov si, aap_file                                ; Find the start of the file data
        mov word ax, [si + 6]
        add si, ax
       
        mov ah, 09h                                     ; Setup registers for VideoBIOS
        mov bh, 0
        mov cx, 1
       
        mov dh, 2                                       ; Move cursor to starting position
        mov dl, 2
        ;call os_move_cursor
 
        mov byte [bg_rows_remaining], 21                ; Set number of rows
       
.draw_row:
        mov byte [bg_columns_remaining], 76
       
.draw_char:
        lodsb                                           ; Load a colour...
        mov bl, al
        lodsb                                           ; then a character...
        int 10h                                         ; Now display
       
        inc dl                                          ; Move cursor forward
        ;call os_move_cursor
       
        dec byte [bg_columns_remaining]
        cmp byte [bg_columns_remaining], 0
        jne .draw_char
       
        inc dh                                          ; Next line
        mov dl, 2
        ;call os_move_cursor
               
        dec byte [bg_rows_remaining]
        cmp byte [bg_rows_remaining], 0
        jne .draw_row
       
        ret
                user_background         db 0
        bg_columns_remaining    db 0
        bg_rows_remaining       db 0
        aap_identifier          db 'AAP', 0
        aap_file                rb 3600
                 background_file_name    db 'BACKGRND.AAP', 0