# ARM Assembly Sandbox
# Hello World example based on
# https://peterdn.com/post/2020/08/22/hello-world-in-arm64-assembly/

.global _start
.section .text

_start:
    /* syscall write(int fd, const void *buf, size_t count) */
    mov     x0, #1      /* fd := STDOUT_FILENO */
    ldr     x1, =message
    mov     x2, #14     /* message length */
    mov     w8, #64     /* write is syscall #64 */
    svc     #0          /* invoke syscall */

    /* syscall exit(int status) */
    mov     x0, #0      /* status := 0 */
    mov     w8, #93     /* exit is syscall #93 */
    svc     #0          /* invoke syscall */

.data
    message:
    .ascii "Hello, World!\n"
