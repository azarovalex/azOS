        org 100h

EntryPoint:
        xor     ax, ax
        mov     fs, ax

        mov     ax, cs
        mov     dx, ISR_80h
        pushf
        cli
        xchg    word [fs: 80h * 4], dx
        xchg    word [fs: 80h * 4 + 2], ax
        popf
        mov     word [OldISR_80h], dx
        mov     word [OldISR_80h + 2], ax

.ProgramLoop:
        xor     ah, ah
        int     16h
        cmp     al, 27  ; Escape
        je      .EndProgramLoop
        int     80h
        jmp     .ProgramLoop
.EndProgramLoop:

        mov     dx, word [OldISR_80h]
        mov     ax, word [OldISR_80h + 2]
        pushf
        cli
        mov     word [fs: 80h * 4], dx
        mov     word [fs: 80h * 4 + 2], ax
        popf

        int 20h

ISR_80h:
        push    ds
        pusha

        cld
        mov     ax, cs
        mov     ds, ax

        mov     cx, 6
        mov     si, strHello
        mov     bl, $07
.PrintLoop:
        lodsb
        mov     ah, $0E
        int     10h
        loop    .PrintLoop

        popa
        pop     ds
        iret

strHello        db      "Hello!"
OldISR_80h      dd      ?