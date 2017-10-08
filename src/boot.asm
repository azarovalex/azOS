use16 
org 7C00h 

jmp 0x0000:boot
nop

boot:
	xor ax, ax
	mov ds, ax
    mov es, ax
	cli
	mov ss, ax
	mov sp, 0x7C00
	sti

	mov al, 1
	mov bx, 0x7E00
	mov cx, 0x0002
	xor  dh, dh
	call read_sectors_16
	jmp 0000:7E00h


; read_sectors_16
;
; Reads sectors from disk into memory using BIOS services
;
; input:    dl      = drive
;           ch      = cylinder[7:0]
;           cl[7:6] = cylinder[9:8]
;           dh      = head
;           cl[5:0] = sector (1-63)
;           es:bx  -> destination
;           al      = number of sectors
;
; output:   cf (0 = success, 1 = failure)

read_sectors_16:
    pusha
    mov si, 0x02    ; maximum attempts - 1
.top:
    mov ah, 0x02    ; read sectors into memory (int 0x13, ah = 0x02)
    int 0x13
    jnc .end        ; exit if read succeeded
    dec si          ; decrement remaining attempts
    jc  .end        ; exit if maximum attempts exceeded
    xor ah, ah      ; reset disk system (int 0x13, ah = 0x00)
    int 0x13
    jnc .top        ; retry if reset succeeded, otherwise exit
.end:
    popa
    retn


times 510-($-$$) db 0 
dw 0AA55h

org 7E00h
_start:
	mov si, hello_msg
	call _puts
	jmp $

_puts:
	lodsb

	cmp al, 0
	je .end

	mov ah, 0Eh
	int 10h

	jmp _puts

.end:
	ret

hello_msg db 'azOS bootloader works!', 0
times 512-($-$$) db 0









