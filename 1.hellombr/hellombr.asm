;---------------------------------------------------------------------------
; MBR - Fill screen with colours and print string at boot
;---------------------------------------------------------------------------
;Emulator:
;	1. nasm -f bin -o hellombr.bin hellombr.asm
;	2. qemu-system-x86_64 hellombr.bin
;
;Write to usb key:
;	1. nasm -f bin -o hellombr.bin hellombr.asm
;	#You should be very cautious when using dd; it can destroy data.
;	#Make sure you replace sdb with the correct device node. You could
;	#accidentally overwrite the mbr on your internal hdd and your comp
;	#won't boot.
;	2. sudo dd if=hellombr.bin of=/dev/sdb bs=512 count=1
;	3. boot computer from usb key
;---------------------------------------------------------------------------
;http://en.wikibooks.org/wiki/X86_Assembly/Bootloaders
;
;1. The first sector of a drive contains its boot loader.
;
;2. One sector is 512 bytes — the last two bytes of which must be 0xAA55
;   (i.e. 0x55 followed by 0xAA), or else the BIOS will treat the drive
;   as unbootable.
;
;3. If everything is in order, said first sector will be placed at RAM
;   address 0000:7C00 (through 0x7DFF), and the BIOS's role is over as
;   it transfers control to 0000:7C00 (that is, it JMPs to that address).
;
;4. The DL register will contain the drive number that is being booted from,
;   useful if you want to read more data from elsewhere on the drive.
;
;5. The BIOS leaves behind a lot of code, both to handle hardware interrupts
;   (such as a keypress) and to provide services to the bootloader and OS
;   (such as keyboard input, disk read, and writing to the screen). You must
;   understand the purpose of the Interrupt Vector Table (IVT), and be careful
;   not to interfere with the parts of the BIOS that you depend on. Most
;   operating systems replace the BIOS code with their own code, but the boot
;   loader can't use anything but its own code and what the BIOS provides.
;   Useful BIOS serve include int 10h (for displaying text/graphics), int 13h
;   (disk functions) and int 16h (keyboard input).
;
;6. This means that any code or data that the boot loader needs must either be
;   included in the first sector (be careful not to accidentally execute data)
;   or manually loaded from another sector of the disk to somewhere in RAM.
;   Because the OS is not running yet, most of the RAM will be unused. However,
;   you must take care not to interfere with the RAM that is required by the BIOS
;   interrupt handlers and services mentioned above.
;
;7. The OS code itself (or the next bootloader) will need to be loaded into RAM
;   as well.
;
;8. The BIOS places the stack pointer 512 bytes beyond the end of the boot sector,
;   meaning that the stack cannot exceed 512 bytes. It may be necessary to move
;   the stack to a larger area.
;
;9. There are some conventions that need to be respected if the disk is to be
;   readable under mainstream operating systems. For instance you may wish to
;   include a BIOS Parameter Block on a floppy disk to render the disk readable
;   under most PC operating systems.
;
;---------------------------------------------------------------------------
;http://en.wikipedia.org/wiki/X86_memory_segmentation
;
;In real mode or V86 mode, a segment is always 65,536 bytes in size (using 16-bit
;   offsets).
;
;The 16-bit segment selector in the segment register is interpreted as the most
;significant 16 bits of a linear 20-bit address, called a segment address, of
;which the remaining four least significant bits are all zeros. The segment address
;is always added to a 16-bit offset in the instruction to yield a linear address,
;which is the same as physical address in this mode.
;
;Each segment begins at a multiple of 16 bytes, called a paragraph, from the
;beginning of the linear (flat) address space. That is, at 16 byte intervals.
;Since all segments are 64 KB long, this explains how overlap can occur between
;segments and why any location in the linear memory address space can be accessed
;with many segment:offset pairs.
;
;address = segment_16bit * 16 + offset_16bit
;address = segment_16bit_h * 10h + offset_16bit_h
;
; x * 10h => four least significant bits are all zeros
;
;---------------------------------------------------------------------------
; Graphics:
;    http://www.brackeen.com/vga/basics.html
;    http://atrevida.comprenica.com/atrtut07.html
; BIOS: http://www.ousob.com/ng/asm/ng6f862.php
;    O mbr: http://susam.in/articles/boot-sector-code/
;---------------------------------------------------------------------------
	;generate code designed to run on a processor operating in 16-bit mode
	BITS 16

	;Set data segment
	mov ax, 07C0h
	mov ds, ax

	mov si, mystring

forever:
	call graphics
	call print_string
	call keypress

	jmp forever	;Loop forever

;----------------------------------------------------
; Fill screen with colours and wait for a key press
;----------------------------------------------------
graphics:
	push ax		;(ah,al)
	push ds
	push bx

	;BIOS - SET VIDEO MODE
	mov ah, 0h	;Service: 0h = video mode set
	mov al, 13h	;mode 0x13: 256 colors, graphics res. 320x200
	int 10h

	mov ax, 0a000h	;Video memory offset
	mov ds, ax	;Set data segment to 0xA000

	mov al, 0	;8bit colour counter
	mov bx, 0	;offset within segment

zanka1:	;Fill entire screen
	mov [ds:bx], al	;mem[ds:bx] = al; ds is segment, bx is offset within segment
	inc al
	inc bx
	cmp bx, 63999	; 320 x 200 = 64000
	jnz zanka1	;Jump if not zero 

	;BIOS - Keyboard services (wait for key press)
	;mov ah, 00h	;Service: read (wait for) key
	;mov al, 00h	;Mode: N/A
	;int 16h		;Call BIOS

	call keypress

	;BIOS - Return to text mode
	mov ah, 0h
	mov al, 3h
	int 10h

	pop bx
	pop ds
	pop ax

	ret

;-----------------
; Wait for key press
;-----------------
keypress:
	push ax		;(ah,al)

	;BIOS - Keyboard services (wait for key press)
	mov ah, 00h	;Service: read (wait for) key
	mov al, 00h	;Mode: N/A
	int 16h		;Call BIOS
	
	pop ax

	ret

;-----------------
; Print string
; Parameters:
; SI: string offset
;-----------------
print_string:
	push ax		;(ah,al)
	push si

	;Write Text in Teletype Mode
	;AH = 0E, AL = ASCII character to write
	mov ah, 0Eh

	cld		;Clears the DF flag in the EFLAGS register

.loop:
	lodsb		;Load byte at address DS:SI into AL
			;and increment SI (DF flag == 0)

	cmp al, 0	;Is char == 0
	je .finish	;Jump on Equality
	int 10h
	jmp .loop	;Unconditional jump

.finish:

	pop si	
	pop ax

	ret
;-----------------

	;Zero terminated string
	mystring db "Hello lalalalalalala!", 0

	;TIMES directive will insert exactly enough zero bytes into the
	;output to move the assembly point up to 510.
	times 510-($-$$) db 0

	;last two bytes of sector must be 0xAA55
	dw 0AA55h

