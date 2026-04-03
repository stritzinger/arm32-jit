gdb-multiarch -q --nh \
  -ex 'set architecture arm' \
  -ex 'set sysroot /usr/arm-linux-gnueabihf' \
  -ex 'file ./otp/RELEASE/erts-15.0/bin/beam.smp' \
  -ex 'dir ./otp/erts/emulator/armv7hl-unknown-linux-gnueabi/opt/jit' \
  -ex 'dir ./otp/erts/emulator/armv7hl-unknown-linux-gnueabi/opt/jit/asmjit' \
  -ex 'dir ./otp/erts/emulator/armv7hl-unknown-linux-gnueabi/opt/jit/asmjit/core' \
  -ex 'dir ./otp/erts/emulator/armv7hl-unknown-linux-gnueabi/opt/jit/asmjit/arm' \
  -ex 'dir ./otp/erts/emulator/beam' \
  -ex 'dir ./otp/erts/emulator/beam/jit' \
  -ex 'dir ./otp/erts/emulator/beam/jit/arm/32' \
  -ex 'target remote localhost:1234' \
  -ex 'continue' \
;
# b apply
# break emit_i_apply_only
# break emit_int_code_end
# break bind_veneer_target
# -ex 'break beam/jit/arm/32/process_main.cpp:49' \
# -ex 'break *0x39400cdc' <- address after returning from apply
# -ex 'break *0x39400af0' <- address of the branch to the erlang process
# -ex 'break *0x39400d74' <- address of the breakpoint_trampoline fragment
# -ex 'break *0x39400dcc' <- address of the first instruction after test_yield
#  -ex 'break beam/jit/beam_jit_metadata.cpp:235' \
#  -ex 'break beamasm_insert_gdb_info' \
#  -ex 'break erts/emulator/beam/erl_init.c:527' \
# -ex 'break erts/emulator/beam/erl_init.c:532' \
# -ex 'break load_code' \
# -ex 'break beam_load_emit_op' \
# -ex 'break beamasm_emit' \
# -ex 'break erts/emulator/beam/jit/arm/32/beam_asm_module.cpp:136' \


# print text in gdb
# print 0x405ef394
# x/s 0x405ef394 emit_i_apply_only
# x/s 0x405e50c0 emit_aligned_label
# x/s 0x405e50a4 emit_enter_runtime
# emit_i_apply_only

# Address of the apply function!!!
# From erts_beamasm.asm
# L21:
#     movw r12, 19368
#     movt r12, 16413
#     blx r12
# looks like the veneer is under label 21
# x/s 0x401D4BA8


# x/6i 0x39400650

# info shared
# x/s 0x405ed7fc

# i_move
# x/s 0x405f862c



# emit_i_apply_only -> apply_variable_shared -> apply
# then back to emit_i_apply_only -> branch
# brekpoint_trampoline -> test_yield
# i_call(erlang_call) -> assert_redzone_unused (0xbeef) -> aligned_call -> 

# In case of halt bif call:
# blx into label addr: 0x39400edc
# export_trampoline -> 
# first instruction: b *0x394004b0
# then call_error_handler routine
# emit_call_light_bif
# emit_deallocate
# emit_return

# In case of call to erlang function:

# x/s 0x4061b0e0

# x/s 0x401ef464

# LR at the point of crash
# x/i 0x39417d14
# Instruction preceeding LR
# x/i 0x39417d10
# previous code section
# x/i 0x39417ca0
# previous LR:
# x/i √
# code preceeding the previous LR:
# x/i 0x39417ce0
# Looks like we came from a blx in:
# x/i 0x39417d04

# branch after call in call_light_bif_shared
# b *0x39400420




# x/s 0x400fa5e8

#garbage moved into 
# x/s 0x406154a4


#  runtime_call<5>(beam_jit_call_bif);
# returns with the suspicious 0x4b value in r0
# the return is at addr 0x39400338
# 
# we then go into emit_bif_nif_epilogue
# and reach the branch to LR, at line 0x39400370
# LR is 0x39417d08#



# get the address of the initial_sp field in the ErtsSchedulerRegisters structure
#p/x (unsigned long)&((ErtsSchedulerRegisters*)0)->initial_sp

#set $off = (unsigned long)&((ErtsSchedulerRegisters*)0)->initial_sp
#set $slot = (UWord**)($r4 + $off)
#p/x $off
#p/x $slot
#p/x *$slot

# watch *$slot
