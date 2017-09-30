print_string:
	pusha
	mov ah, 0x0e
@@:
	lodsb
	cmp al, al
	je @f
	int 10h
	jmp @b
@@:
	popa
	ret