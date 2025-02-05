# ARM Assembly Sandbox
# Hello World example from https://youtu.be/FV6P5eRmMh8?feature=shared

.global _start
.section .text

_start:
    mov r7, #0x4
    mov r0, #1
    ldr r1, =message
    mov r2, #14     /* message length */
    swi 0

    mov r7, #0x1
    mov r0, #0
    swi 0

.section .data
    message:
    .ascii "Hello, World!\n"
