BITS 16

KERNEL_START equ 1		; Disk sector where kernel starts
KERNEL_SIZE equ 1		; Kernel size in disk sectors
KERNEL_SEGMENT equ 1000h	; Segment where kernel will be loaded

;+------------------
;| Load kernel
;+------------------

	;------------------------------------------
	; https://en.wikipedia.org/wiki/INT_13H#INT_13h_AH=02h:_Read_Sectors_From_Drive
	;
	; INT 13h AH=02h: Read Sectors From Drive
	; Parameters
	; AH 02h
	; AL Sectors To Read Count
	; CH Cylinder
	; CL Sector
	; DH Head
	; DL Drive
	; ES:BX  Buffer Address Pointer
	;
	;-----------------
	; https://en.wikipedia.org/wiki/INT_13H#List_of_INT_13h_services
	;
	; Drive Table
	; DL = 00h 1st floppy disk ( "drive A:" )
	; DL = 01h 2nd floppy disk ( "drive B:" )
	; DL = 02h 3rd floppy disk ( "drive B:" )
	; ...
	; DL = 7Fh 128th floppy disk)
	; DL = 80h 1st hard disk
	; DL = 81h 2nd hard disk
	; DL = 82h 3rd hard disk
	; ...
	; DL = E0h CD/DVD[citation needed], or 97th hard disk
	; ...
	; DL = FFh 128th hard disk 
	;-----------------
	; Results
	; CF  Set On Error, Clear If No Error
	; AH  Return Code
	; AL  Actual Sectors Read Count
	;------------------------------------------

	; How many sectors to read from disk:
	; AH = 02h, AL = KERNEL_SIZE IN SECTORS
	mov ax, 200h + KERNEL_SIZE

	; Where to write what is read from disk:
	; ES:BX = KERNEL_SEGMENT:0
	push word KERNEL_SEGMENT
	pop es
	xor bx, bx

	; Where to read from:
	; CH = Cylinder, CL = Sector
	; CH = 0, CL = KERNEL_START + 1
	mov cx, KERNEL_START + 1

	; DH = Head, DL = Drive
	; DH = 0, DL = 80h
	mov dx, 80h

	; BIOS int call
	int 13h
jnc ok

;+------------------
;| On error
;+------------------
	;Set data segment
	mov ax, 07C0h
	mov ds, ax

	mov si, errorString
	call print_string

forever:
	call keypress
	call print_char
	jmp forever

;+------------------
;| Jump to kernel
;+------------------
ok:
jmp KERNEL_SEGMENT:0

;-----------------
; Wait for key press
; Changes: AX
; Returns: AL = ASCII character to write
;-----------------
keypress:
        ;push ax         ;(ah,al)

        ;BIOS - Keyboard services (wait for key press)
        mov ah, 00h     ;Service: read (wait for) key
        mov al, 00h     ;Mode: N/A
        int 16h         ;Call BIOS

        ;pop ax

        ret

;-----------------
; Print char
; Changes: AH
; Parameters:
; AL = ASCII character to write
;-----------------
print_char:
	;Write Text in Teletype Mode
	;AH = 0E, AL = ASCII character to write
	mov ah, 0Eh
	int 10h
	ret

;-----------------
; Print string
; Parameters:
; SI: string offset
;-----------------
print_string:
        push ax         ;(ah,al)
        push si

        ;Write Text in Teletype Mode
        ;AH = 0E, AL = ASCII character to write
        mov ah, 0Eh

        cld             ;Clears the DF flag in the EFLAGS register

.loop:
        lodsb           ;Load byte at address DS:SI into AL
                        ;and increment SI (DF flag == 0)

        cmp al, 0       ;Is char == 0
        je .finish      ;Jump on Equality
        int 10h
        jmp .loop       ;Unconditional jump

.finish:

        pop si
        pop ax

        ret
;-----------------

;Zero terminated string
errorString db "Error reading kernel!", 0


;
; Boot signature
;
times 510 - ($ - $$) db 0
db 55h
db 0aah
