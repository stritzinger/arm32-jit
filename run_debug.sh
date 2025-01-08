#qemu-arm -L /usr/arm-linux-gnueabihf -g 1234 ./RELEASE/erts-14.1/bin/erlexec
qemu-arm -L /usr/arm-linux-gnueabihf -g 1234 ./otp/RELEASE/erts-15.0/bin/beam.smp -- -root ./otp/RELEASE -bindir ./otp/RELEASE/erts-15.0/bin -progname erl -home /home/vagrant
