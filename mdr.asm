; mbr.asm is the main file defining the master boot record (512 byte boot 
; sector)
;
; The main assembly file for the boot loader contains the definition of the 
; master boot record, as well as include statements for all relevant helper 
; modules.

; The first thing to notice is that we are going to switch between 16 bit real 
; mode and 32 bit protected mode so we need to tell the assembler whether it 
; should generate 16 bit or 32 bit instructions. This can be done by using the 
; [bits 16] and [bits 32] directives, respectively. We are starting off with 
; 16 bit instructions as the BIOS jumps to the boot loader while the CPU is 
; still in 16 bit mode.
; https://www.nasm.us/xdoc/2.10.09/html/nasmdoc6.html
[bits 16]
; In NASM, the [org 0x7c00] directive sets the assembler location counter. We 
; specify the memory address where the BIOS is placing the boot loader. This 
; is important when using labels as they will have to be translated to memory 
; addresses when we generate machine code and those addresses need to have the 
; correct offset.
; https://wiki.osdev.org/Memory_Map_(x86)
[org 0x7c00]

; where to load the kernel to
; The KERNEL_OFFSET equ 0x1000 statement defines an assembler constant called 
; KERNEL_OFFSET with the value 0x1000 which we will use later on when loading 
; the kernel into memory and jumping to its entry point.
KERNEL_OFFSET equ 0x1000

; BIOS sets boot drive in 'dl'; store for later use
; Preceding the boot loader invocation, the BIOS stores the selected boot drive 
; in the dl register. We are storing this information in memory inside the 
; BOOT_DRIVE variable so we can use the dl register for something else without 
; the risk of overwriting this information.
mov [BOOT_DRIVE], dl

; setup stack
; Before we can call the kernel loading procedure, we need to setup the stack 
; by setting the stack pointer registers sp (top of stack, grows downwards) 
; and bp (bottom of stack). We will place the bottom of the stack in 0x9000 
; to make sure we are far away enough from our other boot loader related memory 
; to avoid collisions. The stack will be used, e.g., by the call and ret statements 
; to keep track of memory addresses when executing assembly procedures.
mov bp, 0x9000
mov sp, bp

; Now the time has come to do some work! We will first call the load_kernel 
; procedure to instruct the BIOS to load the kernel from disk into memory at 
; the KERNEL_OFFSET address. load_kernel makes use of our disk_load procedure
call load_kernel
call switch_to_32bit

jmp $

%include "disk.asm"
%include "gdt.asm"
%include "switch-to-32bit.asm"

[bits 16]
load_kernel:
    ; This procedure takes three input parameters:
    ; 1. The memory location to place the read data into (bx)
    ; 2. The number of sectors to read (dh)
    ; 3. The disk to read from (dl)
    mov bx, KERNEL_OFFSET ; bx -> destination
    mov dh, 2             ; dh -> num sectors
    mov dl, [BOOT_DRIVE]  ; dl -> disk
    call disk_load
    ret

[bits 32]
BEGIN_32BIT:
    call KERNEL_OFFSET ; give control to the kernel
    jmp $ ; loop in case kernel returns

; boot drive variable
BOOT_DRIVE db 0

; padding
; In order to generate a valid master boot record, we need to include some 
; padding by filling up the remaining space with 
; 0 bytes times 510 - ($-$$) db 0 and the magic number dw 0xaa55.
times 510 - ($-$$) db 0

; magic number
dw 0xaa55
