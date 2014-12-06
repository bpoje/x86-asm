;---------------------------------------------------------------------------
; MBR - Initialize the 512 Bytes (1 sector) in memory and write them to disk
;
;It writes to Cylinder 0, head 0, sector 1 (location where this mbr is stored
;on disk). So executing mbr (loaded into memory) overwrites mbr that is stored
;on disk. The drive is the same from which the MBR was loaded into memory.
;---------------------------------------------------------------------------
;Emulator:
;	1. nasm -f bin -o writetosector.bin writetosector.asm
;	2. qemu-system-x86_64 writetosector.bin
;	3. hexdump -C writetosector.bin
;	#mbr (first sector) was overwriten with numbers 0 to 255
;	#emulator won't be able to boot from image anymore
;
;Write to usb key:
;	1. nasm -f bin -o writetosector.bin writetosector.asm
;	#You should be very cautious when using dd; it can destroy data.
;	#Make sure you replace sdb with the correct device node. You could
;	#accidentally overwrite the mbr on your internal hdd and your comp
;	#won't boot.
;	2. sudo dd if=writetosector.bin of=/dev/sdb bs=512 count=1
;	3. boot computer from usb key
;	4. a loaded mbr will overwrite first sector on the drive (the drive
;	mbr was loaded from)
;	5. reboot
;	6. system won't be able to boot from sdb anymore, you can open it in hex
;	editor to see that mbr (first sector) was overwriten with numbers 0 to 255.
;	sudo hexdump -C /dev/sdb
;
;---------------------------------------------------------------------------
;http://wiki.osdev.org/MBR_%28x86%29
;
;An MBR is loaded by the BIOS at physical address 0x7c00, with DL set to
;the "drive number" that the MBR was loaded from. The BIOS then jumps to the
;very beginning of the loaded MBR (0x7c00), because that part of the MBR
;contains the "bootstrap" executable code. 
;
;---------------------------------------------------------------------------
;http://wiki.osdev.org/Memory_Map_%28x86%29
;
;This article describes the contents of the computer's physical memory at
;the moment that the BIOS jumps to your bootloader code.
;
;When a typical x86 PC boots it will be in Real Mode, with an active BIOS.
;
;start		end
;0x00000500	0x00007BFF
;
;size: almost 30 KiB
;type: RAM (guaranteed free for use)
;description: Conventional memory
;---------------------------------------------------------------------------
;http://www.ousob.com/ng/asm/ng7a0ec.php
;
;INT 13h,  03h (3)        Write Sectors from Memory
;
;Writes one or more sectors from memory to a fixed or floppy disk.
;
;On entry:	AH	03h
;		AL	Number of sectors to write
;		CH	Cylinder number (10-bit value; upper 2 bits
;			in CL)
;		CL	Starting sector number
;		DH	Head number
;		DL	Drive number
;		ES:BX	Address of memory buffer
;
;Returns:	AH	Status of operation (See Service 01h)
;		AL	Number of sectors written
;		CF	(Carry Flag) Set if error, else cleared
;
;Writes the specified number of sectors from the buffer at ES:BX to the
;specified location (head, cylinder, and track) on the disk.
;
;Values in DL less than 80h specify floppy disks; values greater than 80h
;specify fixed disks. For example, 0 means the first floppy diskette, while
;80h means the first fixed disk.
;
;The value returned in AL (number of sectors read) may not give the correct
;number of sectors, even though no error has occurred. Use the results of the
;Carry flag and AH (status flag) to determine the status of the operation.
;
;The cylinder number is a ten-bit quantity (0 through 1023). Its most
;significant two bits are in bits 7 and 6 of CL; the remaining eight bits
;are in CH. The starting sector number fits in the low-order portion
;(lower 6 bits) of CL.
;---------------------------------------------------------------------------
;In CHS addressing the sector numbers always start at 1, there is no
;sector 0, which can lead to confusion since logical sector addressing
;schemes (e.g., with LBA, or with "absolute sector addressing" in DOS)
;typically start counting with 0.
;---------------------------------------------------------------------------
;The CHS addressing supported in IBM-PC compatible BIOSes code used eight
;bits for - theoretically up to 256 heads counted as head 0 up to 255 (FFh).
;However, a bug in all versions of Microsoft DOS/PC-DOS up to including 7.10
;will cause these operating systems to crash on boot when encountering volumes
;with 256 heads[2]. Therefore, all compatible BIOSes will use mappings with
;up to 255 heads (00h..FEh) only, including in virtual 255×63 geometries.
;
;This historical oddity can affect the maximum disk size in old BIOS INT 13h
;code as well as old PC DOS or similar operating systems.
;---------------------------------------------------------------------------

	;generate code designed to run on a processor operating in 16-bit mode
	BITS 16

;RAM is between 0x00000500 and 0x00007BFF
;(We'll start using it at 0x00005000)
RAM_ADDRESS_HIGH	EQU 0
RAM_ADDRESS_LOW		EQU 5000h

;-----------------
;Main program part
;-----------------
	;An MBR is loaded by the BIOS at physical address 0x7c00
	;Set data segment
	mov ax, 07C0h
	mov ds, ax

	call write_to_mem	;1. Create data in memory

	;DL is already set to the "drive number" that the MBR was loaded
	;from (by the BIOS)
	call write_to_hdd	;2. Write data from memory to disk

	mov si, stringReboot	;Done, print string to notify user
	call print_string
forever:
	jmp forever	;Loop forever

;-----------------------------------------------------
; 1. Create data in memory
; Initialize the 512 Bytes in memory (RAM). Values are
; taken from 8-bit counter.
;-----------------------------------------------------
write_to_mem:
	push ax		;(ah,al)
	push es
	push bx
	push cx

	;Set segment for memory access
	;Register couple [es:bx]
	mov ax, RAM_ADDRESS_HIGH
	mov es, ax		;Set es (segment)

	mov bx, RAM_ADDRESS_LOW ;Set bx (offset within segment)

	mov cx, 512		;Field length is 512 Bytes (1 sector)
	mov al, 0		;8-bit value counter
loop_wtm:
	mov [es:bx], al		;mem[es:bx] <= al
	inc al			;al = al + 1
	inc bx			;bx = bx + 1

	dec cx			;cx = cx - 1
	jnz loop_wtm		;jump if cx not zero

	pop cx
	pop bx
	pop es
	pop ax

	ret			;return from subroutine

;-----------------------------------------------------
; 2. Write 512 Bytes (from memory) to disk
;Parameters:
;		DL: drive number
;
;Returns:	AH	Status of operation (See Service 01h)
;		AL	Number of sectors written
;		CF	(Carry Flag) Set if error, else cleared
;
;!!Value returned in AL (number of sectors read) may not
;give the correct number of sectors, even though no error has
;occurred. Use the results of the Carry flag and AH (status flag)
;to determine the status of the operation.!!
;-----------------------------------------------------
write_to_hdd:
	push es
	push bx
	push cx
	push dx
	push si

	;WRITE SECTORS FROM MEMORY
	;We will be transfering 512 Bytes (1 sector) from ram to disk
	;Register couple [es:bx] describes address of memory buffer
	mov ax, RAM_ADDRESS_HIGH
	mov es, ax    		;Set es (segment)
	mov bx, RAM_ADDRESS_LOW ;Set bx (offset within segment)
	;Memory data source is now set

	;CH         Cylinder number (0 through 1023)(10-bit value;
	;	    msb in upper 2 bits in CL, remaining bits in CH)
	;
	;CL         Starting sector number (lower 6 bits of CL)
	;
	;In CHS addressing the sector numbers always start at 1,
	;there is no sector 0, which can lead to confusion since
	;logical sector addressing schemes (e.g., with LBA, or with
	;"absolute sector addressing" in DOS) typically start counting
	;with 0.

	mov cx, 1     ; cylinder 0, sector 1

	;Override dl (drive number) with 0 (the first floppy diskette)
	;mov dl, 00h ; DL = drive = 00h (floppy)
	;
	;Override dl (drive number) with 80 (the first fixed disk)
	;!!can overwrite the mbr on your internal hdd and your comp. won't boot!!
	;mov dl, 80h ; DL = drive = 80h (0th hard disk)

	mov dh, 0h ; DH = 00h (head)
	
	mov ax, 0301h ; AH = 03 (disk write), AL = 01 (number of sectors to write)

	;All parameters set, trigger interrupt
	int 13h

	;CF (Carry Flag) is set if error, else cleared
	jc fail_wth	; jump if carry

	mov si, stringOk	;Done, print string to notify user
	jmp end_wth
fail_wth:
	mov si, stringFail
end_wth:
	call print_string

	pop si
	pop dx
	pop cx
	pop bx
	pop es

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
	stringOk db "Success.", 0
	stringFail db "Failure.", 0
	stringReboot db " Reboot me.", 0

	;TIMES directive will insert exactly enough zero bytes into the
	;output to move the assembly point up to 510.
	times 510-($-$$) db 0

	;last two bytes of sector must be 0xAA55
	dw 0AA55h

