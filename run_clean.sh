#!/bin/bash

export BINDIR=/home/vagrant/arm32-jit/otp/RELEASE/erts-15.0/bin
export EMU=beam.debug
export ROOTDIR=/home/vagrant/arm32-jit/otp/RELEASE

qemu-arm -L /usr/arm-linux-gnueabihf ./otp/RELEASE/erts-15.0/bin/beam.debug.smp -v -A 0 -S 1:1 -SDcpu 1:1 -SDio 1 -JDdump true -JMsingle true -- -root /home/vagrant/arm32-jit/otp/RELEASE -bindir $BINDIR /home/vagrant/arm32-jit/otp/RELEASE/erts-15.0/bin -progname erl -home /home/vagrant
