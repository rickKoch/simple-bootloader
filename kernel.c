// When you take a look back into our mbr.asm, you will notice that we still
// need to call the main function written in C. To do that, we are going to
// create a small assembly program that will be placed at the KERNEL_OFFSET
// location, in front of the compiled C kernel when creating the boot image.

void main() {
  char *video_memory = (char *)0xb8000;
  *video_memory = 'X';
}
