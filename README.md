# Developement Setup for ARM32 JIT compiler

## Initialize the OTP submodule

    git submodule --init

## Start the VM using Vagrant and VMware

*Works on MacOS with ARM processors, not tested on Intel.*

```bash
vagrant up
vagrant ssh
```

The VM will sync the OTP folder to /home/vagrant/otp using rsync and start 
vagrant rsync-auto in the back. 
It will only sync the files from the host to the guest machine and not the other 
way around. 
The advantage of it is that it will not slow down building in the VM. 
The idea of the setup was to keep and edit the files on the host system and 
running the scripts in the VM.

## Cross compile OTP and run GDB

Go into the `otp` folder inside the VM:

    cd otp

There are three scripts that can be used to compile OTP and run GDB:

    ./jit-arm-build.sh 

Follows guidelines to CROSS compile to a custom arm linux setup we added under xcomp. Use this to refresh the configure scripts and build the codebase. This will use arm32 Jit code.

    ./run_debug.sh 

Uses qemu-user to run beam.smp with gdb-server. In this way qemu emulates the processor and waits GDB for step-by-step debuggging.

    ./gdb.sh

Starts a GDB client and sets few example breakpoints. Code execution is controlled from the GDB client.
