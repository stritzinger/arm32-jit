#!/bin/bash

# Set the BINDIR environment variable to point to the Erlang binaries

export BINDIR=/home/vagrant/arm32-jit/otp/RELEASE/erts-15.0/bin

qemu-arm -L /usr/arm-linux-gnueabihf -g 1234 ./otp/RELEASE/erts-15.0/bin/beam.debug.smp -v -A 0 -S 1:1 -SDcpu 1:1 -SDio 1 -JDdump true -JMsingle true -- -root /home/vagrant/arm32-jit/otp/RELEASE -progname erl -home /home/vagrant
