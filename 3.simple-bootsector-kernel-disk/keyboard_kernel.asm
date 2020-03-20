;
; Set up segment registers
;
mov sp, STACK_SEGMENT
mov ss, sp
mov sp, STACK_SIZE
push cs
pop ds
push word SCREEN_SEGMENT
pop es

; Blank screen
call clearScreen

; Say hello
push word welcomeMessage_size
push word welcomeMessage
call printString
add sp, 4
call newline

; Install keyboard handler
push ds
push word 0
pop ds
cli
mov [4 * KEYBOARD_INTERRUPT], word keyboardHandler
mov [4 * KEYBOARD_INTERRUPT + 2], cs
sti
pop ds

; Hang
jmp $

;;;;;;;;;;;;;
; Functions ;
;;;;;;;;;;;;;

clearScreen:
; Clear screen and reset cursor position
; In: none
; Out: none
; Global:
;	color		The color to use
;	es		The screen segment
;	cursor_pos	Cursor position (modified)
mov ah, [cs:color]
mov al, 0
mov cx, SCREEN_COLS * SCREEN_ROWS
xor di, di
rep stosw
mov [cs:cursor_pos], word 0
ret

printString:
; Print string
; In:
; 	String offset (word)
;	String length (word)
; Out:
;	none
; Global:
;	color		The color to use
;	es		The screen segment
;	cursor_pos	The cursor position (modified)
push bp
mov bp, sp
mov si, [bp + 4]
mov cx, [bp + 6]
mov ah, [cs:color]
mov di, [cs:cursor_pos]
.loop0:
lodsb	; load byte from string
stosw	; store byte and color on screen
loop .loop0
mov [cs:cursor_pos], di
pop bp
ret

newline:
; Advance cursor to beginning of next line
; In: none
; Out: none
; Global:
;	cursor_pos	Cursor position (modified)

; Divide the cursor position by the number of bytes per row,
; add 1, then multiply by bytes per row
mov ax, [cs:cursor_pos]
xor dx, dx
mov cx, SCREEN_COLS * 2
div cx
inc ax
mul cx
mov [cs:cursor_pos], ax
ret

;;;;;;;;;;;;;;;;;;;;;;
; Interrupt Handlers ;
;;;;;;;;;;;;;;;;;;;;;;

keyboardHandler:
; save our registers!
pusha

; Read code
in al, 60h

; Ignore codes with high bit set
test al, 80h
jnz .end

; Read the ASCII code from the table
mov bl, al
xor bh, bh
mov al, [cs:bx + keymap]

; Print code
push di
mov di, [cs:cursor_pos]
push es
push word SCREEN_SEGMENT
pop es
mov [es:di], al
pop es
pop di
add word [cs:cursor_pos], 2

.end:
; Send EOI
mov al, 61h
out 20h, al
; return
popa
iret

;;;;;;;;
; Data ;
;;;;;;;;

welcomeMessage db "Simple Kernel"
welcomeMessage_size EQU $ - welcomeMessage
color db 7	; White on black
cursor_pos dw 0
keymap
%include "keymap.inc"

;;;;;;;;;;;;;
; Constants ;
;;;;;;;;;;;;;

STACK_SEGMENT EQU 09000h	; Top of conventional memory
STACK_SIZE EQU 0ffffh		; 64K - 1 bytes of stack
SCREEN_SEGMENT EQU 0b800h
SCREEN_COLS EQU 80
SCREEN_ROWS EQU 25

KEYBOARD_INTERRUPT EQU 9

