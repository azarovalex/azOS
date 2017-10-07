org 0x7C00

start:
	cli

	mov ax, 17 * 32 + 4000 + 256
	mov ss, ax
	mov sp, 256 * 16

	sti

	mov ax, 07C0h
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax

	mov ax, 0
	int 13h
	jc disk_reset_error

	push es				; save es

	mov ax, 07E0h		; destination location (address of _start)
	mov es, ax			; destination location
	mov bx, 0			; index 0

	mov ah, 2			; read sectors function
	mov al, 1		; number of sectors
	mov ch, 0			; cylinder number
	mov dh, 0			; head number
	mov cl, 2			; starting sector number
	int 13h				; call BIOS interrupt

	jc disk_read_error

	pop es

	mov si, boot_msg
	call _puts

	jmp word 07E00000h

disk_reset_error:
	mov si, disk_reset_error_msg
	jmp fatal

disk_read_error:
	mov si, disk_read_error_msg

fatal:
	call _puts

	mov ax, 0
	int 16h

	mov ax, 0
	int 19h

; void _puts(char*)
; accepts a pointer to a string in si
_puts:
	lodsb

	cmp al, 0
	je .end

	mov ah, 0Eh
	int 10h

	jmp _puts

.end:
	ret

disk_reset_error_msg db 'Could not reset disk', 0
disk_read_error_msg  db 'Could not read disk', 0
boot_msg db 'Booting azOS...'

times 510 - ($ - $$) db 0
dw 0xAA55

_start:
	mov si, hello_msg
	call _puts
	
	jmp $

hello_msg db 'azOS bootloader works!', 0

times 17 * 512 - ($ - $$) db 0 ; pad to IMAGE_SIZE	









