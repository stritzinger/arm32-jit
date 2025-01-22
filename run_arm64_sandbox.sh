as -g hello64.asm -o hello64.o
gcc-11 hello64.o -o hello64.elf -nostdlib
gdb ./hello64.elf -q \
  -ex 'break _start' \
  -ex 'layout regs' \
  -ex 'run' \
;
rm hello64.o
rm hello64.elf
