pkill -9 -f 'dyn_erl --realpath' || true
pkill -9 -f qemu-arm || true
ss -ltnp | grep :1234 || true
