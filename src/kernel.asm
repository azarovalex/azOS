format binary as 'BIN'
use16
rb 100h
file 'ptrooper.com'

EntryPoint:
    mov ax,3                    ; set VGA mode (text)
        int 0x10

        mov dx,0xB800                   ; beginning of display memory
        mov es,dx               

        mov si,TextHelloWorld           ; point si at the string 

        mov cx,0
        ForEachChar:                    ; begin loop

                lodsb                   ; load al with [si], increment si
                cmp al,0x00             ; if char is null...
                je EndForEachChar       ; .. then break out of the loop

                mov di,cx               ; offset of current character

                mov [es:di],al          ; write the character to memory

                inc cx                  ; there are two bytes per character
                inc cx                  ; so increment cx twice

        jmp ForEachChar                 ; jump back to beginning of loop
        EndForEachChar:                 ; end of the loop

        ret                             ; quit the program

        ; data to display
        TextHelloWorld: db 'Hello, world!',0


logo db \
"              ____    _____",  10, 13, \
"             / __ \  / ____|", 10, 13, \
"  __ _  ____| |  | || (",      10, 13, \
" / _` ||_  /| |  | | \___ \",  10, 13, \
"| (_| | / / | |__| | ____) |", 10, 13, \
" \__,_|/___| \ ____/ |_____/",  10, 13, \
"      version 0.1 alpha",      10, 13, 0

bsuir db 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, \
" ______        _______  __    __   __   ______      ", 10, 13, \
"|   _  \      /       ||  |  |  | |  | |   _  \     ", 10, 13, \
"|  |_)  |    |   (----`|  |  |  | |  | |  |_)  |    ", 10, 13, \
"|   _  <      \   \    |  |  |  | |  | |      /     ", 10, 13, \
"|  |_)  | .----)   |   |  `--'  | |  | |  |\  \----.", 10, 13, \
"|______/  |_______/     \______/  |__| | _| `._____|", 10, 13, 0