; As soon as we leave 16 bit real mode, memory segmentation works a bit 
; differently. In protected mode, memory segments are defined by segment 
; descriptors, which are part of the GDT.
; https://en.wikipedia.org/wiki/Global_Descriptor_Table

; For our boot loader we will setup the simplest possible GDT, which resembles 
; a flat memory model. The code and the data segment are fully overlapping and 
; spanning the complete 4 GB of addressable memory. Our GDT is structured as 
; follows:
; 1. A null segment descriptor (eight 0-bytes). This is required as a safety 
;    mechanism to catch errors where our code forgets to select a memory 
;    segment, thus yielding an invalid segment as the default one.
; 2. The 4 GB code segment descriptor.
; 3. The 4 GB data segment descriptor.

; https://en.wikipedia.org/wiki/Segment_descriptor
; A segment descriptor is a data structure containing the following information:
; - Base address: 32 bit starting memory address of the segment. This will be 
;   0x0 for both our segments.
; - Segment limit: 20 bit length of the segment. This will be 0xfffff for both 
;   our segments.
; - G (granularity): If set, the segment limit is counted as 4096-byte pages. 
;   This will be 1 for both of our segments, transforming the limit of 0xfffff 
;   pages into 0xfffff000 bytes = 4 GB.
; - D (default operand size) / B (big): If set, this is a 32 bit segment, 
;   otherwise 16 bit. 1 for both of our segments.
; - L (long): If set, this is a 64-bit segment (and D must be 0). 0 in our case, 
;   since we are writing a 32 bit kernel.
; - AVL (available): Can be used for whatever we like (e.g. debugging) but we 
;   are just going to set it to 0.
; - P (present): A 0 here basically disables the segment, preventing anyone 
;   from referencing it. Will be 1 for both of our segments obviously.
; - DPL (descriptor privilege level): Privilege level on the protection ring 
;   required to access this descriptor. Will be 0 in both our segments, as the 
;   kernel is going to access those. 
;   https://en.wikipedia.org/wiki/Protection_ring
; - Type: If 1, this is a code segment descriptor. Set to 0 means it is a data 
;   segment. This is the only flag that differs between our code and data 
;   segment descriptors. For data segments, D is replaced by B, C is replaced 
;    by E and R is replaced by W.
; - C (conforming): Code in this segment may be called from less-privileged 
;   levels. We are setting this to 0 to protect our kernel memory.
; - E (expand down): Whether the data segment expands from the limit down to 
;   the base. Only relevant for stack segments and set to 0 in our case.
; - R (readable): Set if the code segment may be read from. Otherwise it can 
;   only be executed. Set to 1 in our case.
; - W (writable): Set if the data segment may be written to. Otherwise it can 
;   only be read. Set to 1 in our case.
; - A (accessed): This flag is set by the hardware when the segment is 
;   accessed, which can be useful for debugging.
; Unfortunately the segment descriptor does not contain these values in a 
; linear fashion but instead they are scattered across the data structure. This 
; makes it a bit tedious to define the GDT in assembly. Please consult the 
; diagram below for a visual representation of the data structure.
; https://res.cloudinary.com/practicaldev/image/fetch/s--DsK87XYd--/c_limit%2Cf_auto%2Cfl_progressive%2Cq_auto%2Cw_880/https://dev-to-uploads.s3.amazonaws.com/i/cuhqckaray7l80qb7ywm.png

; In addition to the GDT itself we also need to setup a GDT descriptor. The 
; descriptor contains both the GDT location (memory address) as well as its 
; size.

;;; gdt_start and gdt_end labels are used to compute size

; null segment descriptor
gdt_start:
    dq 0x0

; code segment descriptor
gdt_code:
    dw 0xffff    ; segment length, bits 0-15
    dw 0x0       ; segment base, bits 0-15
    db 0x0       ; segment base, bits 16-23
    db 10011010b ; flags (8 bits)
    db 11001111b ; flags (4 bits) + segment length, bits 16-19
    db 0x0       ; segment base, bits 24-31

; data segment descriptor
gdt_data:
    dw 0xffff    ; segment length, bits 0-15
    dw 0x0       ; segment base, bits 0-15
    db 0x0       ; segment base, bits 16-23
    db 10010010b ; flags (8 bits)
    db 11001111b ; flags (4 bits) + segment length, bits 16-19
    db 0x0       ; segment base, bits 24-31

gdt_end:

; GDT descriptor
gdt_descriptor:
    dw gdt_end - gdt_start - 1 ; size (16 bit)
    dd gdt_start ; address (32 bit)

CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start
