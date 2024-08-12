; In order to switch to 32 bit protected mode so that we can hand over control 
; to our 32 bit kernel, we have to perform the following steps:
; 1. Disable interrupts using the cli instruction.
;    https://c9x.me/x86/html/file_module_x86_id_31.html
; 2. Load the GDT descriptor into the GDT register using the lgdt instruction.
;    https://c9x.me/x86/html/file_module_x86_id_156.html
; 3. Enable protected mode in the control register cr0.
;    https://wiki.osdev.org/CPU_Registers_x86#CR0
; 4. Far jump into our code segment using jmp. This needs to be a far jump so 
;    it flushes the CPU pipeline, getting rid of any prefetched 16 bit 
;    instructions left in there.
;    https://c9x.me/x86/html/file_module_x86_id_147.html
; 5. Setup all segment registers (ds, ss, es, fs, gs) to point to our single 
;    4 GB data segment.
;    http://www.c-jump.com/CIS77/ASM/Memory/lecture.html#M77_0120_reg_names
; 6. Setup a new stack by setting the 32 bit bottom pointer (ebp) and stack 
;    pointer (esp).
; 7. Jump back to mbr.asm and give control to the kernel by calling our 32 bit 
;    kernel entry procedure.

[bits 16]
switch_to_32bit:
    cli                     ; 1. disable interrupts
    lgdt [gdt_descriptor]   ; 2. load GDT descriptor
    mov eax, cr0
    or eax, 0x1             ; 3. enable protected mode
    mov cr0, eax
    jmp CODE_SEG:init_32bit ; 4. far jump

[bits 32]
init_32bit:
    mov ax, DATA_SEG        ; 5. update segment registers
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    mov ebp, 0x90000        ; 6. setup stack
    mov esp, ebp

    call BEGIN_32BIT        ; 7. move back to mbr.asm
