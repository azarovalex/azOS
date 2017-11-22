format binary as 'img'
use16

; BIOS will load this to 0x7C00
; Bootloader starts with FAT12 info
BS_jmpBoot:
                jmp     BootStart
                db      3 - $ dup($90)

BS_OEMName     db      "MSWIN5.0"
BPB_BytsPerSec dw      512
BPB_SecPerClus db      1
BPB_RsvdSecCnt dw      1
BPB_NumFATs    db      2
BPB_RootEntCnt dw      224
BPB_TotSec16   dw      2880
BPB_Media      db      0F0h
BPB_FATSz16    dw      9
BPB_SecPerTrk  dw      18
BPB_NumHeads   dw      2
BPB_HiddSec    dd      0
BPB_TotSec32   dd      0
BS_DrvNum      db      0
BS_Reserved1   db      0
BS_BootSig     db      029h
BS_VolID       dd      %t
BS_VolLab      db      "AZOS       "
BS_FilSysType  db      "FAT12   "

BootStart:
    mov ax, 07C0h       ; Compute the stack segment
    add ax, 544         ; 32 (bootloader size) + 512(buffer for File Alloc Table)
    cli
    mov ss, ax
    mov sp, 2048        ; Stack size
    sti

    mov ax, 07C0h
    mov ds, ax

    mov byte [bootdisk], dl   ; DL still have the boot disk number, store it

    mov ax, 42h               ; Add interrupt handler for adding other handlers
    mov dx, SetIntHandler     ; Here goes some magic to call interrupt that hasn't been added to IVT yet (tricking IRET)
    pushf                     ; Flags for IRET
    call 07C0h:SetIntHandler  ; Far call for IRET

    mov ax, 40h               ; Now we can set other interrupts with 42h
    mov dx, ReadFromDisk
    int 42h

LoadRootDir:
    mov bx, Buffer       ; ES:BX - buffer where root directory from disk will be loaded
    mov ax, ds
    mov es, ax
    mov ax, 19           ; Sector with root directory
    mov cx, 14           ; Root directory size in sectors

    int 40h              ; ReadFromDisk

SearchKernel:
    mov ax, ds          ; Set ES:DI to filename for cmpsb
    mov es, ax
    mov di, Buffer

    mov cx, 224         ; Repeat comparison for max of 224 files in root directory

NextFilename:
    xchg cx, ax         ; Cycle in cycle, so save cx

    mov si, kern_name
    mov cx, 11          ; Kernel filename length
    rep cmpsb           ; Compare next filename (ES:DI) with kern_name (DS:SI)
    je FoundKernel

    mov di, Buffer      ; Inc DI to the next filename
    add di, 32

    xchg ax, cx
    loop NextFilename

    mov si, file_not_found  ; There's no kernel on the floppy - print error msg
    call PrintString
    jmp Reboot

FoundKernel:
    mov ax, word [es:di + $0F]    ; Get first kernel cluster from root directory
    mov word [cluster], ax        ; Save first kernel cluster

    mov ax, 1         ; File Allocation Table is on sector 1 (0 - bootloader)
    mov cx, 9         ; FAT size
    mov bx, Buffer    ; Load FAT at 0x7E00

    int 40h

LoadFileSector:  ; Actually is a cycle
    mov ax, 50h                ; Kernel will be loaded to 0x0500 (0050:0000)
    mov es, ax
    mov bx, word [pointer]     ; Track the address we are writing to
    mov ax, word [cluster]     ; Track the cluster we are reading from
    add ax, 31
    mov cx, 1                  ; Read one cluster per time

    int 40h

CalculateNextCluster:
    mov ax, [cluster]
    mov dx, 0
    mov bx, 3
    mul bx
    mov bx, 2
    div bx
    mov si, Buffer
    add si, ax
    mov ax, word [ds:si]
    or dx, dx
    jz Even

Odd:                            ; FAT12 is comlicated to parse :(
    shr ax, 4
    jmp short NextClusterCont

Even:
    and ax, 0FFFh

NextClusterCont:
    mov word [cluster], ax

    cmp ax, 0FF8h               ; End of the file?
    jae BootEnd                 ; If it is then execute kernel

    add word [pointer], 512
    jmp LoadFileSector

BootEnd:
    pop ax
    mov dl, byte [bootdisk]

    mov ax, 50h
    mov ds, ax
    mov es, ax
    mov ss, ax
    jmp 50h:0h

;-------------------------------------------------------------------
;                     Bootloader routines
;-------------------------------------------------------------------
Reboot:
    xor ax, ax
    int 16h
    xor ax, ax
    int 19h


PrintString:
    pusha
    mov ah, 0Eh
.repeat:
    lodsb
    cmp al, 0
    je .done
    int 10h
    jmp .repeat
.done:
    popa
    ret

ResetFloppy:
    push ax
    push dx
    xor ax,ax
    mov dl, byte [bootdisk]
    int 13h
    pop dx
    pop ax
    ret

ReadFromDisk:
    push cx

    push ax
    xor dx, dx
    div word [BPB_SecPerTrk]
    add dl, 01h
    mov cl, dl

    pop ax
    xor dx, dx
    div word [BPB_SecPerTrk]
    xor dx, dx
    div word [BPB_NumHeads]
    mov dh, dl
    mov ch, al

    mov dl, byte [bootdisk]
    pop ax
    mov ah, 2

    pusha
.Retry:
    popa
    pusha

    int 13h
    jnc .Ok
    call ResetFloppy
    jnc .Retry
    jmp Reboot

.Ok:
    popa
    iret

SetIntHandler:     ; DS:ES - interrupt handler, AL - interrupt number
    xor bx, bx     ; Interupt address is at segment = 0, offset = intNum * 4
    mov es, bx     ; So we need 0 in ES
    shl ax, 2      ; Get interrupt address in IVT
    mov di, ax
    mov bx, ds
    cli
    xchg [es:di], dx    ; Offset
    xchg [es:di+2], bx  ; Segment
    sti
iret



; --------------------------------------------------

    kern_name       db "AZOSKERNBIN"   ; "AZOSKERN.BIN"
    file_not_found  db "AZOSKERN.BIN is not found!", 0

    bootdisk   db 0
    cluster    dw 0
    pointer    dw 0



    db      510 - $ dup($00)
    db      $55, $AA
;---------------------------------------------------
;           End of the bootloader segment
;---------------------------------------------------
Buffer:

FAT1:
    db      $F0, $FF, $FF
    db      9 * 512 - ($ - FAT1) dup ($00)

FAT2:      ; the same as the FAT1
    repeat 9 * 512
        load a byte from FAT1 + % - 1
        db a
    end repeat

RootDir:

                db 224 * 32 - ($ - RootDir) dup($00)
Files:
                db 2880 * 512 - $ dup($00)