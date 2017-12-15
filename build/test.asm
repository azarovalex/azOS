org 100h

mov si, stri
                   
PrintString:
    mov ah, 0Eh    
.Repeat:           
    lodsb          
    cmp al, 0      
    je  .Done      
    int 10h        
    jmp .Repeat    
.Done:
    xor ah, ah
    int 16h
    int 20h

stri db "Hello, World", 0