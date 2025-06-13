# Developement Setup for ARM32 JIT compiler

## Usage of the Ubuntu VM

### Set up Vagrant

#### Set up Vagrant for VMware
1. Get a VMware installation and a license.
    - The free-for-personal-use license won't work and we don't know any
workarounds (there might be though).
2. https://developer.hashicorp.com/vagrant/downloads
3. https://developer.hashicorp.com/vagrant/install/vmware
    - Note that the CLI installation instructions are wrong.
      You want to install `vagrant-vmware-utility`, not `vagrant` itself again.
4. `vagrant plugin install vagrant-vmware-desktop`

#### Set up Vagrant for VirtualBox
1. https://www.virtualbox.org/wiki/Downloads
2. https://developer.hashicorp.com/vagrant/downloads

### Start the VM

Note that Vagrant will first try to start the VM via the VMware provider,
and then it'll fall back to VirtualBox.
You can set the default provider as described
[here](https://developer.hashicorp.com/vagrant/docs/providers/default).

```bash
vagrant up
```

Afterwards, connect to the VM:
```bash
vagrant ssh
```

Shut down the VM:
```bash
vagrant halt
```

The VM will sync the the current folder to `/home/vagrant/arm32-jit/` using
rsync and start `vagrant rsync-auto` in the back.

It will only sync the files from the host to the guest machine and not the other
way around.
The advantage of it is that it will not slow down building in the VM.
The idea of the setup was to keep and edit the files on the host system and
running the scripts in the VM.

## Assembly Sandbox

There are two hello world assembly implementations:

* `hello32.asm` for ARM 32 assembly
* `hello64.asm` for ARM 64 assembly

They can be assembled and run (inside the Ubuntu VM) with GDB using the scripts
`run_arm32_sandbox.sh` or `run_arm64_sandbox.sh` respectively.

They are meant as a basis setup that can be used for experiments with assembly
instructions or registers during developement to gain better and deeper
understanding.

### Initialize the OTP submodule

    git submodule update --init

You can use Vagrant with either a VMware desktop solution (Workspace, Fusion,
whatever else there might be...) or VirtualBox.


## Cross compile OTP and run GDB

There are three scripts that can be used to compile OTP and run GDB:

    ./jit-arm-build.sh

Follows guidelines to CROSS compile to a custom arm linux setup we added under
xcomp. Use this to refresh the configure scripts and build the codebase. This
will use arm32 Jit code.

    ./run_debug.sh

Uses qemu-user to run beam.smp with gdb-server. In this way qemu emulates the
processor and waits GDB for step-by-step debuggging.

    ./gdb.sh

Starts a GDB client and sets few example breakpoints. Code execution is
controlled from the GDB client.

## Inspecting jitted code

We run OTP with `JDdump true`, this dumps all jitted assembly into .asm files.

For example, you can find jitted assembly of global functions
in the current working directory.

The global assembler output is written to `beam_asm_global.asm` in the working directory inside the VM.

```shell
vagrant@vagrant:~/arm32-jit$ cat beam_asm_global.asm
global::apply_fun_shared:
    eor r2, r2, r2
    ldr r3, [r4, 64]
    ldr r1, [r4, 68]
    mov r0, r1
L100:
    cmp r0, 59
    b.eq L99
    tst r0, 1
    b.ne L101
    ldr r12, [r0, -1]
    ldr r0, [r0, 3]
    str r12, [r4, r2 lsl 2]
    movw r12, 1023
    add r2, r2, 1
    cmp r2, r12
    b.lo L100
    movw r0, 15440
    b L102
L101:
    movw r0, 3152
L102:
    str r3, [r4, 64]
    str r1, [r4, 68]
    str r0, [r8, 56]
    movw r3, 53184
    movt r3, 16459
    b global::raise_exception
L99:
    lsl r2, r2, 8
    add r2, r2, 20
    bx lr
```
If you want to comfortably inspect the file on you host, you can copy any file from the VM to the current host folder using the SCP plugin

```shell
    # Install scp plugin if you do not have it
    vagrant plugin install vagrant-scp
    # and then
    vagrant scp default:/home/vagrant/arm32-jit/beam_asm_global.asm .
```

Or more simply cat the file via ssh

```shell
    vagrant ssh -c "sudo cat /home/vagrant/arm32-jit/beam_asm_global.asm" > beam_asm_global.asm
```
