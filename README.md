# x86-asm

## Master boot record
* hellombr: Fill screen with colours and print string at boot
  
  ![Alt text](/1.hellombr/preview/preview.jpg "Screenshot")

* writetosectormbr: Initialize the 512 Bytes (1 sector) in memory and write them to disk
  
  Disk values:
  - Before:
  ```
  00000000  b8 c0 07 8e d8 e8 0b 00  e8 27 00 be 7f 00 e8 4b  |.........'.....K|
  00000010  00 eb fe 50 06 53 51 b8  00 00 8e c0 bb 00 50 b9  |...P.SQ.......P.|
  00000020  00 02 b0 00 26 88 07 fe  c0 43 49 75 f7 59 5b 07  |....&....CIu.Y[.|
  00000030  58 c3 06 53 51 52 56 b8  00 00 8e c0 bb 00 50 b9  |X..SQRV.......P.|
  00000040  01 00 b6 00 b8 01 03 cd  13 72 05 be 6d 00 eb 03  |.........r..m...|
  00000050  be 76 00 e8 06 00 5e 5a  59 5b 07 c3 50 56 b4 0e  |.v....^ZY[..PV..|
  00000060  fc ac 3c 00 74 04 cd 10  eb f7 5e 58 c3 53 75 63  |..<.t.....^X.Suc|
  00000070  63 65 73 73 2e 00 46 61  69 6c 75 72 65 2e 00 20  |cess..Failure.. |
  00000080  52 65 62 6f 6f 74 20 6d  65 2e 00 00 00 00 00 00  |Reboot me.......|
  00000090  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
  *
  000001f0  00 00 00 00 00 00 00 00  00 00 00 00 00 00 55 aa  |..............U.|
  00000200
  ```
  
  - After:
  ```
  00000000  00 01 02 03 04 05 06 07  08 09 0a 0b 0c 0d 0e 0f  |................|
  00000010  10 11 12 13 14 15 16 17  18 19 1a 1b 1c 1d 1e 1f  |................|
  00000020  20 21 22 23 24 25 26 27  28 29 2a 2b 2c 2d 2e 2f  | !"#$%&'()*+,-./|
  00000030  30 31 32 33 34 35 36 37  38 39 3a 3b 3c 3d 3e 3f  |0123456789:;<=>?|
  00000040  40 41 42 43 44 45 46 47  48 49 4a 4b 4c 4d 4e 4f  |@ABCDEFGHIJKLMNO|
  00000050  50 51 52 53 54 55 56 57  58 59 5a 5b 5c 5d 5e 5f  |PQRSTUVWXYZ[\]^_|
  00000060  60 61 62 63 64 65 66 67  68 69 6a 6b 6c 6d 6e 6f  |`abcdefghijklmno|
  00000070  70 71 72 73 74 75 76 77  78 79 7a 7b 7c 7d 7e 7f  |pqrstuvwxyz{|}~.|
  00000080  80 81 82 83 84 85 86 87  88 89 8a 8b 8c 8d 8e 8f  |................|
  00000090  90 91 92 93 94 95 96 97  98 99 9a 9b 9c 9d 9e 9f  |................|
  000000a0  a0 a1 a2 a3 a4 a5 a6 a7  a8 a9 aa ab ac ad ae af  |................|
  000000b0  b0 b1 b2 b3 b4 b5 b6 b7  b8 b9 ba bb bc bd be bf  |................|
  000000c0  c0 c1 c2 c3 c4 c5 c6 c7  c8 c9 ca cb cc cd ce cf  |................|
  000000d0  d0 d1 d2 d3 d4 d5 d6 d7  d8 d9 da db dc dd de df  |................|
  000000e0  e0 e1 e2 e3 e4 e5 e6 e7  e8 e9 ea eb ec ed ee ef  |................|
  000000f0  f0 f1 f2 f3 f4 f5 f6 f7  f8 f9 fa fb fc fd fe ff  |................|
  00000100  00 01 02 03 04 05 06 07  08 09 0a 0b 0c 0d 0e 0f  |................|
  00000110  10 11 12 13 14 15 16 17  18 19 1a 1b 1c 1d 1e 1f  |................|
  00000120  20 21 22 23 24 25 26 27  28 29 2a 2b 2c 2d 2e 2f  | !"#$%&'()*+,-./|
  00000130  30 31 32 33 34 35 36 37  38 39 3a 3b 3c 3d 3e 3f  |0123456789:;<=>?|
  00000140  40 41 42 43 44 45 46 47  48 49 4a 4b 4c 4d 4e 4f  |@ABCDEFGHIJKLMNO|
  00000150  50 51 52 53 54 55 56 57  58 59 5a 5b 5c 5d 5e 5f  |PQRSTUVWXYZ[\]^_|
  00000160  60 61 62 63 64 65 66 67  68 69 6a 6b 6c 6d 6e 6f  |`abcdefghijklmno|
  00000170  70 71 72 73 74 75 76 77  78 79 7a 7b 7c 7d 7e 7f  |pqrstuvwxyz{|}~.|
  00000180  80 81 82 83 84 85 86 87  88 89 8a 8b 8c 8d 8e 8f  |................|
  00000190  90 91 92 93 94 95 96 97  98 99 9a 9b 9c 9d 9e 9f  |................|
  000001a0  a0 a1 a2 a3 a4 a5 a6 a7  a8 a9 aa ab ac ad ae af  |................|
  000001b0  b0 b1 b2 b3 b4 b5 b6 b7  b8 b9 ba bb bc bd be bf  |................|
  000001c0  c0 c1 c2 c3 c4 c5 c6 c7  c8 c9 ca cb cc cd ce cf  |................|
  000001d0  d0 d1 d2 d3 d4 d5 d6 d7  d8 d9 da db dc dd de df  |................|
  000001e0  e0 e1 e2 e3 e4 e5 e6 e7  e8 e9 ea eb ec ed ee ef  |................|
  000001f0  f0 f1 f2 f3 f4 f5 f6 f7  f8 f9 fa fb fc fd fe ff  |................|
  00000200
  ```

## Simple bootsector and kernel in disk image

I tried to learn, experiment and use gdb with the code from sources:
http://inglorion.net/documents/tutorials/x86ostut/getting_started/
https://arjunsreedharan.org/post/82710718100/kernels-101-lets-write-a-kernel
https://wiki.osdev.org/Memory_Map_(x86


Create raw disk in file, add bootloader and kernel:
```
make
```

Run disk in qemu (package qemu-system-x86 on fedora) and try to type something on keyboard:
```
make run 
```

Clean build files
```
make clean
```

![Alt text](/3.simple-bootsector-kernel-disk/preview/preview.png "Screenshot")

To debug:
In first terminal execute command (ctrl+alt+g to release mouse):
```
qemu-system-x86_64 -m 64 -drive file=disk.raw,format=raw,index=0,media=disk -boot c -gdb tcp::1235 -S
```

In second terminal:
```
$ cgdb
(gdb) set disassembly-flavor intel
(gdb) display/i $cs*16+$pc
(gdb) break *0x7c00
(gdb) target remote localhost:1235
(gdb) c
     Breakpoint 1, 0x0000000000007c00 in ?? ()
     1: x/i $cs*16+$pc
     => 0x7c00:      mov    eax,0x680201
(gdb) nexti
    0x0000000000007c03 in ?? ()
    1: x/i $cs*16+$pc
    => 0x7c03:      push   0x31071000
(gdb) nexti
...
```


