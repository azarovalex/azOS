Int20h:
    mov ah, 0
    int 21h
    iret

Int21h:
    cmp ah, 0
    je .func00

    cmp ah, 4Ch
    je .func00
    iret

.func00:

    iret

ShowMenu:
    mov ah, 0
    mov al, 3
    int 10h


    mov ah, 09h
    mov al, ' '
    mov bh, 0
    mov bl, 90h ;
    mov cx, 80
    int 10h

    ret
TopString   db "Welcome to azOS!", 0
BottomString db "Version 0.1 alpha", 0