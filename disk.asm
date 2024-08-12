; Reading from disk is rather easy when working in 16 bit mode, as we can 
; utilize BIOS functionality by sending interrupts. Without the help of 
; the BIOS we would have to interface with the I/O devices such as hard 
; disks or floppy drives directly, making our boot loader way more complex.
;
; In order to read data from disk, we need to specify where to start reading, 
; how much to read, and where to store the data in memory. We can then send 
; an interrupt signal (int 0x13) and the BIOS will do its work, reading the 
; following parameters from the respective registers:
; https://en.wikipedia.org/wiki/INT_13H#INT_13h_AH=02h:_Read_Sectors_From_Drive
;
; ah	Mode (0x02 = read from disk)
; al	Number of sectors to read
; ch	Cylinder
; cl	Sector
; dh	Head
; dl	Drive
; es:bx	Memory address to load into (buffer address pointer)

; If there are disk errors, BIOS will set the carry bit. In that case we should 
; usually show an error message to the user but since we did not cover how to 
; print strings and we are not going to in this post, we will simply loop 
; indefinitely.

; Recall the input parameters we set in mbr.asm:
; 1. The memory location to place the read data into (bx)
; 2. The number of sectors to read (dh)
; 3. The disk to read from (dl)

disk_load:
    ; First thing every procedure should do is to push all general purpose 
    ; registers (ax, bx, cx, dx) to the stack using pusha so we can pop them 
    ; back before returning in order to avoid side effects of the procedure.
    pusha
    push dx

    ; Now we can set all required input parameters in the respective registers 
    ; and send the interrupt. Keep in mind that bx and dl are already set 
    ; correctly by the caller. As the goal is to read the next sector on disk, 
    ; right after the boot sector, we will read from the boot drive starting 
    ; at sector 2, cylinder 0, head 0
    mov ah, 0x02 ; read mode
    mov al, dh   ; read dh number of sectors
    mov cl, 0x02 ; start from sector 2
                 ; (as sector 1 is our boot sector)
    mov ch, 0x00 ; cylinder 0
    mov dh, 0x00 ; head 0

    ; dl = drive number is set as input to disk_load
    ; es:bx = buffer pointer is set as input as well

    ; After the int 0x13 has been executed, our kernel should be loaded into 
    ; memory. To make sure there were no problems, we should check two things: 
    ; First, whether there was a disk error (indicated by the carry bit) using 
    ; a conditional jump based on the carry bit jc disk_error. Second, whether 
    ; the number of sectors read (set as a return value of the interrupt in al) 
    ; matches the number of sectors we attempted to read (popped from stack into 
    ; dh) using a comparison instruction cmp al, dh and a conditional jump in 
    ; case they are not equal jne sectors_error.
    int 0x13      ; BIOS interrupt
    jc disk_error ; check carry bit for error

    pop dx     ; get back original number of sectors to read
    cmp al, dh ; BIOS sets 'al' to the # of sectors actually read
               ; compare it to 'dh' and error out if they are !=
    jne sectors_error
    popa
    ret

; In case something went wrong we will run into an infinite loop. If everything 
; went fine, we are returning from the procedure back to the main function. 

disk_error:
    jmp disk_loop

sectors_error:
    jmp disk_loop

disk_loop:
    jmp $
