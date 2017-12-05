; MikeOS/POSx86 Mouse Library for WINLIB written by Joshua Beck!
; Created by Joshua Beck
; Based on the TachyonOS Mouse Driver/API
; This driver was written by a MikeOS Expert named Joshua Beck,
; His apps are pretty cool, you can see some of them here:
; https://code.google.com/p/mikebasic-applications/downloads/list
; -----------------------------------------------------
; mouse_check_close
; Checks whether the mouse is at 67,2 (Position of the [X] button)
; IN : NOTHING
; OUT DX = 0x1F34 if the X button was clicked
; To use this you must call the mouselib_anyclick
; and use a JC to jump to this function
; like :
; call mouselib_anyclick
; jc mouse_check_close
; cmp dx,0x1F34
; je .program_end
; jmp .mouse_retry
mouse_check_close:
        jmp .checkx ; Check the X Position
.checkx:
        call mouselib_locate
        cmp cx,67 ; X = 67? Ok. So let's check the Y co-ordinate
        je .checky
        jmp .ok
.checky:
        cmp dx,2 ; Y = 2 That's where our X Button is!
        je .end
        jmp .ok
.end:
        xor dx,dx ; Empty DX
        mov dx,0
        mov dx,0x1F34 ; Set DX to a signature
        ret
.ok:
        ret
; mouse_init
; Initializes the Mouse Driver
mouse_init:
                call mouselib_install_driver
                mov ax, 0
                mov bx, 0
                mov cx, 79
                mov dx, 24
                call mouselib_range
                mov dh, 3
                mov dl, 2
                call mouselib_scale
                ;call os_hide_cursor
; mouselib_install_driver --- setup the mouse driver
; IN/OUT: none
mouselib_install_driver:
        pusha
        cli
        
        ; Enable the auxiliary mouse device
        call mouselib_int_wait_1
        mov al, 0xA8
        out 0x64, al
        
        ; Enable the interrupts
        call mouselib_int_wait_1
        mov al, 0x20
        out 0x64, al
        call mouselib_int_wait_0
        in al, 0x60
        or al, 0x02
        mov bl, al
        call mouselib_int_wait_1
        mov al, 0x60
        out 0x64, al
        call mouselib_int_wait_1
        mov al, bl
        out 0x60, al
        
        ; Tell the mouse to use default settings
        mov ah, 0xF6
        call mouselib_int_write
        call mouselib_int_read          ; Acknowledge
        
        ; Enable the mouse
        mov ah, 0xF4
        call mouselib_int_write
        call mouselib_int_read          ; Acknowledge
        
        ; Setup the mouse handler
        cli
        push es
        mov ax, 0x0000
        mov es, ax
        
        mov ax, [es:0x01D0]
        mov [mouselib_int_originalhandler], ax
        mov ax, [es:0x01D2]
        mov [mouselib_int_originalseg], ax
        
        mov word [es:0x01D0], mouselib_int_handler
        mov word [es:0x01D2], 0x2000
        pop es
        sti
        
        popa
        ret
        
; ---------------------------------

mouselib_int_wait_0:
        mov cx, 65000
        mov dx, 0x64
.wait:
        in al, dx
        bt ax, 0
        jc .okay
        loop .wait
.okay:
        ret
        
; ---------------------------------

mouselib_int_wait_1:
        mov cx, 65000
        mov dx, 0x64
.wait:
        in al, dx
        bt ax, 1
        jnc .okay
        loop .wait
.okay:
        ret

; -----------------------------------------------------
; mouselib_int_write --- write a value to the mouse controller
; IN: AH = byte to send

mouselib_int_write:
        ; Wait to be able to send a command
        call mouselib_int_wait_1
        ; Tell the mouse we are sending a command
        mov al, 0xD4
        out 0x64, al
        ; Wait for the final part
        call mouselib_int_wait_1
        ; Finally write
        mov al, ah
        out 0x60, al
        ret
        
; -----------------------------------------------------
; mouselib_int_read --- read a value from the mouse controller
; OUT: AL = value

mouselib_int_read:
        ; Get the response from the mouse
        call mouselib_int_wait_0
        in al, 0x60
        ret


        
; ----------------------------------------
; TachyonOS Mouse Driver
        
mouselib_int_handler:
        cli
        
        pusha
        push ds
        mov ax, 0x2000
        mov ds, ax
        
        ; Check which byte number this is 
        cmp byte [.number], 0
        je .data_byte
        
        cmp byte [.number], 1
        je .x_byte
        
        cmp byte [.number], 2
        je .y_byte

.data_byte:
        ; Collect data byte - contains buttons, overflow flags, alignment bit and negative delta flags
        in al, 0x60
        mov [mouselib_int_data], al
        
;       bt ax, 3
;       jc .alignment
        
        ; The next byte will be X-delta
        mov byte [.number], 1
        jmp .finish
        
.alignment:
        mov byte [.number], 0
        jmp .finish
        
.x_byte:
        ; Collect X-delta byte - contains left-right mouse movement
        in al, 0x60
        mov [mouselib_int_delta_x], al
        ; The next byte will be Y-delta
        mov byte [.number], 2
        jmp .finish
        
.y_byte:
        ; Collect Y-delta byte - contains up-down mouse movement
        in al, 0x60
        mov [mouselib_int_delta_y], al
        ; The next byte will byte the data byte
        mov byte [.number], 0

; Now we have the entire packet it is time to process its data.
; We want to figure out the new X and Y co-ordinents and which buttons are pressed.
        
.process_packet:
        mov ax, 0
        mov bx, 0
        mov bl, [mouselib_int_data]
        test bx, 0x00C0                 ; If x-overflow or y-overflow is set ignore packet
        jnz .finish

        mov byte [mouselib_int_changed], 1      ; Mark there has been a mouse update for functions awaiting mouse input
        
        ; Get the movement values
        mov cx, 0
        mov cl, [mouselib_int_delta_x]
        mov dx, 0
        mov dl, [mouselib_int_delta_y]
        
        ; Check data byte for the X sign flag
        bt bx, 4
        jc .negative_delta_x

        ; Right Movement - Add the X-delta to the raw X position
        add [mouselib_int_x_raw], cx
        jmp .scale_x
        
.negative_delta_x:
        ; Left movement - Invert the X-delta and subtract it from the raw X position
        xor cl, 0xFF
        inc cl

        ; Verify that the number to be subtract is greater than the total to avoid an underflow.
        cmp cx, [mouselib_int_x_raw]
        jg .zero_x
        
        sub [mouselib_int_x_raw], cx
        
.scale_x:
        ; We have the new 'raw' position
        ; Now shift it according to the mouse scale factor to find the 'scaled' position
        ; The mouse position is based of the raw position but functions read the scaled position
        mov cx, [mouselib_int_x_raw]
        
        mov ax, cx
        mov cl, [mouselib_int_x_scale]
        shr ax, cl
        mov cx, ax
        mov [mouselib_int_x_position], cx
        
.check_x_boundries:
        ; Make sure the new scaled position does not exceed the boundries set by the operating system
        cmp cx, [mouselib_int_x_minimum]
        jl .fix_x_minimum
        
        cmp cx, [mouselib_int_x_limit]
        jg .fix_x_limit
        
.find_y_position:
        ; Now do everything again to process the Y-delta
        bt bx, 5                        ; Check data byte for the Y sign flag
        jc .negative_delta_y
        
        cmp dx, [mouselib_int_y_raw]
        jg .zero_y
        
        ; Upward movememnt, take Y-delta from the raw Y position
        sub [mouselib_int_y_raw], dx
        jmp .scale_y
        
.negative_delta_y:
        ; Downward movement, invert Y-delta and add it to the raw Y position
        xor dl, 0xFF
        inc dl
                
        add [mouselib_int_y_raw], dx
        
.scale_y:
        mov dx, [mouselib_int_y_raw]
        
        mov cl, [mouselib_int_y_scale]
        shr dx, cl
        mov [mouselib_int_y_position], dx
        
.check_y_boundries:
        cmp dx, [mouselib_int_y_minimum]
        jl .fix_y_minimum
        
        cmp dx, [mouselib_int_y_limit]
        jg .fix_y_limit
        
.check_buttons:
        ; Movement is complete, now to update the button press status
        ; These can be taken from the lower bits of data byte
        ; Bit 0 = Left Mouse
        ; Bit 1 = Right Mouse
        ; Bit 2 = Middle Mouse
        
        bt bx, 0
        jc .left_mouse_pressed
        
        mov byte [mouselib_int_button_left], 0          ; If a button is not pressed, set it's status to zero
        
        bt bx, 2
        jc .middle_mouse_pressed
        
        mov byte [mouselib_int_button_middle], 0
        
        bt bx, 1
        jc .right_mouse_pressed
        
        mov byte [mouselib_int_button_right], 0
        
.finish:
        ; For IRQ 8-15 we MUST send and End Of Interrupt command to both the master and slave PIC
        ; Otherwise we will not get any more interrupts and lockup our mouse and keyboard
        mov al, 0x20                            ; End Of Interrupt (EOI) command
        out 0x20, al                            ; Send EOI to master PIC
        out 0xa0, al                            ; Send EOI to slave PIC
        
        ; And that's all for now
        pop ds
        popa
        sti
        iret
        
        .number                         db 0
        
.zero_x:
        ; If the value we want to take is greater to the total, just set the position as zero and continue
        mov word [mouselib_int_x_raw], 0
        jmp .scale_x
        
.fix_x_minimum:
        ; If the scale position is less than the minimum, set it to the minimum
        mov cx, [mouselib_int_x_minimum]
        mov [mouselib_int_x_position], cx
        
        ; Now reverse the shift to find the corrosponding raw position, because that is the the one that gets updated
        mov ax, cx
        mov cl, [mouselib_int_x_scale]
        shl ax, cl
        mov [mouselib_int_x_raw], ax

        jmp .find_y_position
        
.fix_x_limit:
        ; If the scale postion is greater than the limit just set it to the limit
        mov cx, [mouselib_int_x_limit]
        mov [mouselib_int_x_position], cx
        
        mov ax, cx
        mov cl, [mouselib_int_x_scale]
        shl ax, cl
        mov [mouselib_int_x_raw], ax
        
        jmp .find_y_position
        
.zero_y:
        mov word [mouselib_int_y_raw], 0
        jmp .scale_y
        
.fix_y_minimum:
        mov dx, [mouselib_int_y_minimum]
        mov [mouselib_int_y_position], dx
        
        mov cl, [mouselib_int_y_scale]
        shl dx, cl
        mov [mouselib_int_y_raw], dx
        
        jmp .check_buttons
        
.fix_y_limit:
        mov dx, [mouselib_int_y_limit]
        mov [mouselib_int_y_position], dx
        
        mov cl, [mouselib_int_y_scale]
        shl dx, cl
        mov [mouselib_int_y_raw], dx
        
        jmp .check_buttons
        
.left_mouse_pressed:
        ; When a button is pressed, set a marker to make it easy for the API
        mov byte [mouselib_int_button_left], 1
        
        ; Check for other buttons - all must be updated
        bt bx, 2
        jc .middle_mouse_pressed
        
        mov byte [mouselib_int_button_middle], 0
        
        bt bx, 1
        jc .right_mouse_pressed
        
        mov byte [mouselib_int_button_right], 0
        
        jmp .finish
        
.middle_mouse_pressed:
        mov byte [mouselib_int_button_middle], 1
        
        bt bx, 1
        jc .right_mouse_pressed
        
        mov byte [mouselib_int_button_right], 0
        
        jmp .finish
        
.right_mouse_pressed:
        mov byte [mouselib_int_button_right], 1
        
        jmp .finish
        
        
; --------------------------------------------------
; mouselib_locate -- return the mouse co-ordinents
; IN: none
; OUT: CX = Mouse X, DX = Mouse Y
        
mouselib_locate:
        ; Move the scale mouse positions into the registers
        mov cx, [mouselib_int_x_position]
        mov dx, [mouselib_int_y_position]
        
        ret

        
; --------------------------------------------------
; mouselib_move -- set the mouse co-ordinents
; IN: CX = Mouse X, DX = Mouse Y
; OUT: none

mouselib_move:
        pusha
        
        ; Set the scale mouse position
        mov ax, cx
        mov [mouselib_int_x_position], ax
        mov [mouselib_int_y_position], dx
        
        ; To move the mouse we must set the raw position
        ; If we don't the next mouse update will simple overwrite our scale position
        ; So shift the mouse position by the scale factor
        mov cl, [mouselib_int_x_scale]
        shl ax, cl
        mov [mouselib_int_x_raw], ax
        
        mov cl, [mouselib_int_y_scale]
        shl dx, cl
        mov [mouselib_int_y_raw], dx
        
        popa
        ret


; --------------------------------------------------
; mouselib_show -- shows the cursor at current position
; IN: none
; OUT: none

mouselib_show:
        ; THIS DOES NOT WORK IN GRAPHICS MODE!
        push ax
        
        ; Basically show and hide just invert the current character
        ; We use mouselib_int_cursor_x so that we can remember where we put the cursor
        ; just in case it changes before we can hide it
        cmp byte [mouselib_int_cursor_on], 1
        je .already_on
        
        mov ax, [mouselib_int_x_position]
        mov [mouselib_int_cursor_x], ax
        
        mov ax, [mouselib_int_y_position]
        mov [mouselib_int_cursor_y], ax
        
        call mouselib_int_toggle
        
        mov byte [mouselib_int_cursor_on], 1
        
        pop ax
        
.already_on:
        ret
        

; --------------------------------------------------
; mouselib_hide -- hides the cursor
; IN: none
; OUT: none
        
mouselib_hide:
        cmp byte [mouselib_int_cursor_on], 0
        je .already_off
        
        call mouselib_int_toggle
        
        mov byte [mouselib_int_cursor_on], 0
        
.already_off:
        ret
        

mouselib_int_toggle:
        pusha
        
        ; Move the cursor into mouse position
        mov ah, 02h
        mov bh, 0
        mov dx, [mouselib_int_cursor_y]
        mov dx, [mouselib_int_cursor_x]
        int 10h
        
        ; Find the colour of the character
        mov ah, 08h
        mov bh, 0
        int 10h
        
        ; Invert it to get its opposite
        not ah
        
        ; Display new character
        mov bl, ah
        mov ah, 09h
        mov bh, 0
        mov cx, 1
        int 10h
        
        popa
        ret

; --------------------------------------------------
; mouselib_range -- sets the range maximum and 
;       minimum positions for mouse movement
; IN: AX = min X, BX = min Y, CX = max X, DX = max Y
; OUT: none

mouselib_range:
        ; Just activate the range registers, the driver will handler the rest
        mov [mouselib_int_x_minimum], ax
        mov [mouselib_int_y_minimum], bx
        mov [mouselib_int_x_limit], cx
        mov [mouselib_int_y_limit], dx
        
        ret
        
        
; --------------------------------------------------
; mouselib_wait -- waits for a mouse event
; IN: none
; OUT: none

mouselib_wait:
        ; The driver set the mouselib_int_changed flag every time there is a mouse update
        ; So we can wait for an update by setting it to zero and waiting for it to change
        mov byte [mouselib_int_changed], 0
        
.wait:
        ; This is a good opertunity to save power while nothing is happening.
        hlt
        cmp byte [mouselib_int_changed], 1
        je .done
        
        jmp .wait

.done:
        ret

        
; --------------------------------------------------
; mouselib_anyclick -- check if any mouse button is pressed
; IN: none
; OUT: none

mouselib_anyclick:
        cmp byte [mouselib_int_button_left], 1
        je .click
        
        cmp byte [mouselib_int_button_middle], 1
        je .click
        
        cmp byte [mouselib_int_button_right], 1
        je .click
        
        clc
        ret
        
.click:
        stc
        ret
        

; --------------------------------------------------
; mouselib_leftclick -- checks if the left mouse button is pressed
; IN: none
; OUT: CF = set if pressed, otherwise clear

mouselib_leftclick:
        cmp byte [mouselib_int_button_left], 1
        je .pressed
        
        clc
        ret
        
.pressed:
        stc
        ret


; --------------------------------------------------
; mouselib_middleclick -- checks if the middle mouse button is pressed
; IN: none
; OUT: CF = set if pressed, otherwise clear

mouselib_middleclick:
        cmp byte [mouselib_int_button_middle], 1
        je .pressed
        
        clc
        ret
        
.pressed:
        stc
        ret
        
        
; --------------------------------------------------
; mouselib_rightclick -- checks if the right mouse button is pressed
; IN: none
; OUT: CF = set if pressed, otherwise clear

mouselib_rightclick:
        cmp byte [mouselib_int_button_right], 1
        je .pressed
        
        clc
        ret
        
.pressed:
        stc
        ret
        
        
; ------------------------------------------------------------------
; mouselib_input_wait -- waits for mouse or keyboard input
; IN: none
; OUT: CF = set if keyboard, clear if mouse

mouselib_input_wait:
        push ax
        
        ; Clear the mouse update flag so we can tell when the driver had updated it
        mov byte [mouselib_int_changed], 0
        
.input_wait:
        ; Check with BIOS if there is a keyboard key available - but don't collect the key
        mov ah, 11h
        int 16h
        jnz .keyboard_input
        
        
        ; Check if the mouse driver had recieved anything
        cmp byte [mouselib_int_changed], 1
        je .mouselib_int_input
        
        hlt
        
        jmp .input_wait
        
.keyboard_input:
        pop ax
        stc
        ret
        
.mouselib_int_input:
        pop ax
        clc
        ret
        
        
; ------------------------------------------------------------------
; mouselib_scale -- scale mouse movment speed as 1:2^X
; IN: DL = mouse X scale, DH = mouse Y scale

mouselib_scale:
        ; Set the scale factor and let the driver handle the rest
        mov [mouselib_int_x_scale], dl
        mov [mouselib_int_y_scale], dh
        ret

        
; ------------------------------------------------------------------
; mouselib_remove_driver --- restores the original mouse handler
; IN: nothing
; OUT: nothing

mouselib_remove_driver:
        push ax
        push es
        cli
        
        ; Restore the old handler on the interrupt vector table
        mov ax, 0x0000
        mov es, ax
        
        mov ax, [mouselib_int_originalhandler]
        mov [es:0x01D0], ax
        mov ax, [mouselib_int_originalseg]
        mov [es:0x01D2], ax

        pop es

        ; Disable the mouse
        mov ah, 0xF5
        call mouselib_int_write
        call mouselib_int_read          ; Acknowledge

        ; Edit the PS/2 configureation to disable mouse interrupts
        call mouselib_int_wait_1
        mov al, 0x20
        out 0x64, al
        call mouselib_int_wait_0
        in al, 0x60
        and al, 0xFD
        mov bl, al
        call mouselib_int_wait_1
        mov al, 0x60
        out 0x64, al
        call mouselib_int_wait_1
        mov al, bl
        out 0x60, al
        
        ; Disable the mouse device
        call mouselib_int_wait_1
        mov al, 0xA7
        out 0x64, al
        
        sti
        pop ax
        ret
        
; ------------------------------------------------------------------
; mouselib_freemove --- allows the user to move the mouse around the screen
;                       stops when a mouse click or keyboard event occurs
; IN: none
; OUT:  AX = key pressed or zero if mouse click
;       CX = mouse x, DX = mouse y, CF = set if key press, clear if mouse click

mouselib_freemove:
        call mouselib_show
        call mouselib_input_wait
        jc .keypress
        call mouselib_hide
        
        call mouselib_anyclick
        jc .mouseclick
;        call os_get_time_string
        mov dl,72
        mov dh,0
        call os_move_cursor
        mov si,bx 
        call os_print_string
        mov dl,61
        mov dh,0
        call os_move_cursor
       ; mov bx, tmp_string
;        mov si, bx
        call os_print_string
        jmp mouselib_freemove
        
.keypress:
        call mouselib_hide
        
        call mouselib_check_for_extkey
        
        cmp ax, 0
        je mouselib_freemove
        
        call mouselib_locate
        stc
        ret
        
.mouseclick:
        mov ax, 0
        call mouselib_locate
        clc
        ret
        
; ------------------------------------------------------------------
; mouselib_check_for_extkey --- checks for an extended keypress
; IN: nothing
; OUT: AX = key value (zero if no key pressed)

mouselib_check_for_extkey:
        mov ah, 11h
        int 16h
        jz .no_key
        
        mov ax, 10h
        int 16h
        ret
        
.no_key:
        mov ax, 0
        ret
        
        

; All the data needed by the mouse driver and API
mouselib_int_data                               db 0
mouselib_int_delta_x                            db 0
mouselib_int_delta_y                            db 0
mouselib_int_x_raw                              dw 0
mouselib_int_y_raw                              dw 0
mouselib_int_x_scale                            db 0
mouselib_int_y_scale                            db 0
mouselib_int_x_position                         dw 0
mouselib_int_y_position                         dw 0
mouselib_int_x_minimum                          dw 0
mouselib_int_x_limit                            dw 0
mouselib_int_y_minimum                          dw 0
mouselib_int_y_limit                            dw 0
mouselib_int_button_left                        db 0
mouselib_int_button_middle                      db 0
mouselib_int_button_right                       db 0
mouselib_int_cursor_on                          db 0
mouselib_int_cursor_x                           dw 0
mouselib_int_cursor_y                           dw 0
mouselib_int_changed                            db 0
mouselib_int_originalhandler                    dw 0
mouselib_int_originalseg                        dw 0