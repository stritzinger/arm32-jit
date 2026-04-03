# Development Setup for ARM32 JIT Compilation

The ARM32 JIT is working.

You can try it yourself by following this guide.

## Usage of the Ubuntu VM

To build and run the ARM32 JIT on a 64-bit system, you need Linux and `qemu-user`.
We developed this on an Ubuntu 22.04 VM configured with Vagrant.
In this repo, you will find everything you need to set up the VM yourself.
If you already have a native Linux distro, you can try to reproduce our setup by looking at our Vagrant provisioning script.

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

```shell
vagrant up
```

Afterwards, connect to the VM:
```shell
vagrant ssh
vagrant@vagrant:~$ cd arm32-jit/
vagrant@vagrant:~/arm32-jit$ 
```

Shut down the VM:
```shell
vagrant halt
```

The VM will sync the current folder to `/home/vagrant/arm32-jit/` using
`rsync` and start `vagrant rsync-auto` in the background.

It will sync files only from the host to the guest machine, not the other way
around.
The advantage is that this does not slow down builds in the VM.
The idea behind this setup is to keep and edit files on the host system while
running scripts in the VM.

### Initialize the OTP submodule
```shell
git submodule update --init
```
You can use Vagrant with either a VMware desktop solution (Workspace, Fusion,
whatever else there might be...) or VirtualBox.

## Quick release build

Cross-build and install a release:

```shell
vagrant@vagrant:~/arm32-jit$ ./jit-arm-release-full-build.sh
```
The release is installed under `otp/RELEASE`:
```shell
vagrant@vagrant:~/arm32-jit$ ./otp/RELEASE/bin/erl
Erlang/OTP 27 [erts-15.0] [source-4ecd178167] [32-bit] [smp:10:10] [ds:10:10:10] [async-threads:1] [jit]

Eshell V15.0 (press Ctrl+G to abort, type help(). for help)
1> 
```
You are free to experiment with this Erlang release.

In this VM, we can call the `erl` script directly because we use `binfmt-support`
and an installed script that tells the OS to run ARM32 binaries with the
correct emulation layer.

### Run OTP test suites with the ARM32 JIT release

If you want to run test suites, we created a custom script to run OTP suites.

```shell
vagrant@vagrant:~/arm32-jit$ ./run_otp_lib_ct_jit.sh 
```

This script lets you choose an app, suite, and test case. Keep in mind that a
few tests may fail simply because they run through an emulation layer. Expect
timeout errors.

## Cross-compile OTP and Debug with GDB

There are multiple scripts that can be used to compile OTP and run GDB:
```shell
# Build with debug symbols and JIT checks
./jit-arm-debug-full-build.sh 
# Clean and optimized build
./jit-arm-release-full-build.sh 
```
These scripts follow the guidelines to cross-compile to the custom ARM Linux
setup we added under `xcomp`. Use them to refresh the configure scripts and
build the codebase with ARM32 JIT code.

If you modify code but do not change the build setup, you can run a faster
recompilation script that skips the early steps and reuses compiled artifacts.

```shell
## depending on which type of build you desire
./rebuild-debug.sh
./rebuild-release.sh
```
In early development, or when debugging early crashes, it is useful to work
with a debug build and the scripts below. They use `qemu-user` to run
`beam.debug.smp` with a GDB server. This way, qemu emulates the processor and
waits for GDB for step-by-step debugging.

```shell 
./run_debug.sh # run debug build and wait for GDB process to connect
./run_clean.sh # run debug build without GDB port listener
./gdb-debug.sh # Attach to a debug run that is waiting and debug with options
./debug.sh # shortcut for ./run_debug.sh and ./gdb-debug.sh
```

You can modify these scripts to target `beam.smp` instead of
`beam.debug.smp`, so they work for the release build. For convenience, there is
another script for GDB.

```shell
./gdb-release.sh
```

## Inspecting JITted code

We run OTP with `JDdump true`; this dumps all JITted assembly into `.asm` files.

For example, you can find JITted assembly for global functions
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
If you want to inspect the file comfortably on your host, you can copy any file
from the VM to the current host folder using the SCP plugin:

```shell
# Install the SCP plugin if you do not have it
vagrant plugin install vagrant-scp
# and then
vagrant scp default:/home/vagrant/arm32-jit/beam_asm_global.asm .
```

Or, more simply, output the file via SSH:

```shell
vagrant ssh -c "sudo cat /home/vagrant/arm32-jit/beam_asm_global.asm" > beam_asm_global.asm
```
## Preloaded module content

Preloaded modules are updated by running
```shell
./otp_build update_preloaded --no-commit
```
During the build, the BEAM binaries of preloaded modules end up in a generated
C file that is included in the build. To include `hello` as an extra module,
you need to:

1. Place `hello.erl` in `otp/erts/preloaded/src`.
2. Add `hello` to `PRE_LOADED_ERL_MODULES` in `erts/preloaded/src/Makefile`.
3. Put `hello.beam` at the top of `erts/emulator/Makefile.in` (to load it first).
4. Add the `hello` atom to `erts/emulator/beam/atom.names`.
5. Make sure to update and rerun `configure`.
6. (Optional) Swap `init` with `hello` in `erl_init.c` to make BEAM boot into
   `hello` instead of the normal Erlang initialization.
7. Build again.

You can check the content of the `pre_loaded` vector by reading this file:

    erts/emulator/armv7hl-unknown-linux-gnueabi/opt/jit/preload.c 

By placing `hello` first in the list in `Makefile.in`, we ensure it is loaded
first. If we comment out everything else, we get the smallest module possible.
```c
erts/emulator/armv7hl-unknown-linux-gnueabi/opt/jit/preload.c 
/*
 * Do *not* edit this file. It was automatically generated by
 * `make_preload'.
 */
const unsigned preloaded_size_hello = 232;
const unsigned char preloaded_hello[] = {
0x46,0x4f,0x52,0x31,0x00,0x00,0x00,0xe0, /* FOR1.... */
  0x42,0x45,0x41,0x4d,0x41,0x74,0x55,0x38, /* BEAMAtU8 */
  0x00,0x00,0x00,0x2d,0x00,0x00,0x00,0x04, /* ...-.... */
  0x05,0x68,0x65,0x6c,0x6c,0x6f,0x0b,0x6d, /* .hello.m */
  0x6f,0x64,0x75,0x6c,0x65,0x5f,0x69,0x6e, /* odule_in */
  0x66,0x6f,0x06,0x65,0x72,0x6c,0x61,0x6e, /* fo.erlan */
  0x67,0x0f,0x67,0x65,0x74,0x5f,0x6d,0x6f, /* g.get_mo */
  0x64,0x75,0x6c,0x65,0x5f,0x69,0x6e,0x66, /* dule_inf */
  0x6f,0x00,0x00,0x00,0x43,0x6f,0x64,0x65, /* o...Code */
  0x00,0x00,0x00,0x38,0x00,0x00,0x00,0x10, /* ...8.... */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xab, /* ........ */
  0x00,0x00,0x00,0x05,0x00,0x00,0x00,0x02, /* ........ */
  0x01,0x10,0x99,0x00,0x02,0x12,0x22,0x00, /* ......". */
  0x01,0x20,0x40,0x12,0x03,0x4e,0x10,0x00, /* . @..N.. */
  0x01,0x30,0x99,0x00,0x02,0x12,0x22,0x10, /* .0....". */
  0x01,0x40,0x40,0x03,0x13,0x40,0x12,0x03, /* .@@..@.. */
  0x4e,0x20,0x10,0x03,0x45,0x78,0x70,0x54, /* N ..ExpT */
  0x00,0x00,0x00,0x1c,0x00,0x00,0x00,0x02, /* ........ */
  0x00,0x00,0x00,0x02,0x00,0x00,0x00,0x01, /* ........ */
  0x00,0x00,0x00,0x04,0x00,0x00,0x00,0x02, /* ........ */
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x02, /* ........ */
  0x49,0x6d,0x70,0x54,0x00,0x00,0x00,0x1c, /* ImpT.... */
  0x00,0x00,0x00,0x02,0x00,0x00,0x00,0x03, /* ........ */
  0x00,0x00,0x00,0x04,0x00,0x00,0x00,0x01, /* ........ */
  0x00,0x00,0x00,0x03,0x00,0x00,0x00,0x04, /* ........ */
  0x00,0x00,0x00,0x02,0x53,0x74,0x72,0x54, /* ....StrT */
  0x00,0x00,0x00,0x00,0x54,0x79,0x70,0x65, /* ....Type */
  0x00,0x00,0x00,0x0a,0x00,0x00,0x00,0x03, /* ........ */
  0x00,0x00,0x00,0x01,0x0f,0xff,0x00,0x00,                       
                  /* ........ */
};
...
const struct {
   char* name;
   int size;
   const unsigned char* code;
} pre_loaded[] = {
  {"hello", 232, preloaded_hello},
  {"erts_code_purger", 5432, preloaded_erts_code_purger},
  {"erl_init", 1148, preloaded_erl_init},
  {"init", 25752, preloaded_init},
  ...

```
