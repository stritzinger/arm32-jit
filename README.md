# Developement Setup for ARM32 JIT compiler

## Initialize the OTP submodule

    git submodule update --init

You can use Vagrant with either a VMware desktop solution (Workspace, Fusion, whatever else there might be...) or VirtualBox.

## Set up Vagrant for VMware
1. Get a VMware installation and a license.
    - The free-for-personal-use license won't work and we don't know any workarounds (there might be though).
2. https://developer.hashicorp.com/vagrant/downloads
3. https://developer.hashicorp.com/vagrant/install/vmware
    - Note that the CLI installation instructions are wrong.
      You want to install `vagrant-vmware-utility`, not `vagrant` itself again.
4. `vagrant plugin install vagrant-vmware-desktop`

## Set up Vagrant for VirtualBox
1. https://www.virtualbox.org/wiki/Downloads
2. https://developer.hashicorp.com/vagrant/downloads

## Start the VM

Vagrant will first try to start the VM via the VMware provider,
and then it'll fall back to VirtualBox:

```bash
vagrant up
```

You can also explicitly specify the provider by using one of the targets from `./Makefile`:

```bash
make vuw  # VMware
make vub  # VirtualBox
```

Afterwards, connect to the VM:
```bash
vagrant ssh
```

Shut down the VM:
```bash
vagrant halt
```

The VM will sync the OTP folder to `/home/vagrant/otp/` using rsync and start
`vagrant rsync-auto` in the back.

It will only sync the files from the host to the guest machine and not the other
way around.
The advantage of it is that it will not slow down building in the VM.
The idea of the setup was to keep and edit the files on the host system and
running the scripts in the VM.


## Cross compile OTP and run GDB

Go into the `otp` folder inside the VM:

    cd arm32-jit/otp

There are three scripts that can be used to compile OTP and run GDB:

    ./jit-arm-build.sh

Follows guidelines to CROSS compile to a custom arm linux setup we added under xcomp. Use this to refresh the configure scripts and build the codebase. This will use arm32 Jit code.

    ./run_debug.sh

Uses qemu-user to run beam.smp with gdb-server. In this way qemu emulates the processor and waits GDB for step-by-step debuggging.

    ./gdb.sh

Starts a GDB client and sets few example breakpoints. Code execution is controlled from the GDB client.
