org 0x7C00

	mov ax, 0
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov sp, 0x7C00

	xor ax, ax          ; clear screen
    mov al, 3h
    int 10h

    mov si, welcome
    call print_string

boot:
	mov si, prompt
	call print_string

	mov di, buffer
	call get_string

	mov si, buffer
	cmp byte [si],0
	je boot

	mov si, buffer
	mov di, cmd_hi
	call strcmp
	jc .helloworld

	mov si, buffer
	mov di, cmd_help
	call strcmp
	jc .help

	mov si, badcommand
	call print_string
	jmp boot

.helloworld:
	mov si, msg_helloworld
	call print_string

	jmp boot

.help:
	mov si, msg_help
	call print_string

	jmp boot

welcome db 'Welcome to azOS!', 13, 10, 0
msg_helloworld db 'Hello, World!', 13, 10, 0
badcommand db 'Invalid command entered', 13, 10, 0
prompt db '>', 0
cmd_hi db 'hi', 0
cmd_help db 'help', 0
msg_help db 'azOS: Commands: hi, help', 0x0D, 0x0A, 0
buffer rb 64

print_string:
   lodsb        ; grab a byte from SI
 
   or al, al  ; logical or AL by itself
   jz .done   ; if the result is zero, get out
 
   mov ah, 0x0E
   int 0x10      ; otherwise, print out the character!
 
   jmp print_string
 
 .done:
   ret
 
 get_string:
   xor cl, cl
 
 .loop:
   mov ah, 0
   int 0x16   ; wait for keypress
 
   cmp al, 0x08    ; backspace pressed?
   je .backspace   ; yes, handle it
 
   cmp al, 0x0D  ; enter pressed?
   je .done      ; yes, we're done
 
   cmp cl, 0x3F  ; 63 chars inputted?
   je .loop      ; yes, only let in backspace and enter
 
   mov ah, 0x0E
   int 0x10      ; print out character
 
   stosb  ; put character in buffer
   inc cl
   jmp .loop
 
 .backspace:
   cmp cl, 0	; beginning of string?
   je .loop	; yes, ignore the key
 
   dec di
   mov byte [di], 0	; delete character
   dec cl		; decrement counter as well
 
   mov ah, 0x0E
   mov al, 0x08
   int 10h		; backspace on the screen
 
   mov al, ' '
   int 10h		; blank character out
 
   mov al, 0x08
   int 10h		; backspace again
 
   jmp .loop	; go to the main loop

.done:
   mov al, 0	; null terminator
   stosb
 
   mov ah, 0x0E
   mov al, 0x0D
   int 0x10
   mov al, 0x0A
   int 0x10		; newline
 
   ret
 
 strcmp:
 .loop:
   mov al, [si]   ; grab a byte from SI
   mov bl, [di]   ; grab a byte from DI
   cmp al, bl     ; are they equal?
   jne .notequal  ; nope, we're done.
 
   cmp al, 0  ; are both bytes (they were equal before) null?
   je .done   ; yes, we're done.
 
   inc di     ; increment DI
   inc si     ; increment SI
   jmp .loop  ; loop!
 
 .notequal:
   clc  ; not equal, clear the carry flag
   ret
 
 .done: 	
   stc  ; equal, set the carry flag
   ret
 
rb 510 - ($ - $$)
dw 0AA55h ; some BIOSes require this signature




















