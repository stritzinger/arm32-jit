arm-linux-gnueabihf-as -g hello32.asm -o hello32.o
arm-linux-gnueabihf-gcc-11 hello32.o -o hello32.elf -nostdlib
qemu-arm -L /usr/arm-linux-gnueabihf -g 1234 ./hello32.elf &
gdb-multiarch -q --nh \
  -ex 'set architecture arm' \
  -ex 'set sysroot /usr/arm-linux-gnueabihf' \
  -ex 'file ./hello32.elf' \
  -ex 'target remote localhost:1234' \
  -ex 'break _start' \
  -ex 'layout regs' \
  -ex 'continue' \
;
rm hello32.o
rm hello32.elf
