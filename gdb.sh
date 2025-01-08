gdb-multiarch -q --nh \
  -ex 'set architecture arm' \
  -ex 'set sysroot /usr/arm-linux-gnueabihf' \
  -ex 'file ./otp/RELEASE/erts-15.0/bin/beam.smp' \
  -ex 'dir ./otp/erts/emulator/armv7hl-unknown-linux-gnueabi/opt/jit' \
  -ex 'dir ./otp/erts/emulator/armv7hl-unknown-linux-gnueabi/opt/jit/asmjit' \
  -ex 'dir ./otp/erts/emulator/armv7hl-unknown-linux-gnueabi/opt/jit/asmjit/core' \
  -ex 'dir ./otp/erts/emulator/armv7hl-unknown-linux-gnueabi/opt/jit/asmjit/arm' \
  -ex 'target remote localhost:1234' \
  -ex 'break main' \
  -ex continue \
;

# dir /home/ziopio/Desktop/otp/erts/emulator/asmjit/core/
# break /home/ziopio/Desktop/otp/erts/emulator/armv7hl-unknown-linux-gnueabi/opt/jit/asmjit/core/codeholder.h:998
