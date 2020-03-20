DISK_FILE=disk.raw

disk: simple_bootsect.o keyboard_kernel.o
	#Create disk file full of zero
	dd if=/dev/zero of=$(DISK_FILE) bs=1k count=32k

	#Copy simple_bootsect.bin to disk file (to first sector if sector size is 512 bytes)
	dd if=simple_bootsect.o of=$(DISK_FILE) conv=notrunc

	#Copy simple_kernel.bin to disk file (to second sector if sector size is 512 bytes)
	dd if=keyboard_kernel.o of=$(DISK_FILE) conv=notrunc bs=512 seek=1

simple_bootsect.o: simple_bootsect.asm
	nasm simple_bootsect.asm -o simple_bootsect.o

keyboard_kernel.o: keyboard_kernel.asm keymap.inc
	nasm keyboard_kernel.asm -o keyboard_kernel.o

keymap.inc:
	cp us_keymap.inc keymap.inc

run: disk
	#Run disk in qemu (package qemu-system-x86 on fedora)
	qemu-system-x86_64 -m 64 -drive file=$(DISK_FILE),index=0,media=disk,format=raw

clean:
	rm *.o keymap.inc $(DISK_FILE)
