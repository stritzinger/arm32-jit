#!/usr/bin/env bash
set -euo pipefail


apt-get -q update
apt-get -q -y install \
    autoconf gcc make qemu qemu-user \
    qemu-user-static \
    binfmt-support \
    pkg-config \
    gcc-arm-linux-gnueabihf \
    g++-arm-linux-gnueabihf \
    binutils-arm-linux-gnueabihf \
    gdb-multiarch \
    ncurses-dev \
    clang

# qemu-user-static and qemu-user-binfmt conflict on Ubuntu.
if dpkg-query -W -f='${Status}' qemu-user-binfmt 2>/dev/null | grep -q "install ok installed"; then
    apt-get -q -y remove qemu-user-binfmt
fi

# Ensure ARM32 binaries can be executed directly via binfmt_misc.
cat >/usr/local/bin/qemu-arm-binfmt <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

# With binfmt 'P' preserve flag, kernel passes:
#   $1 = target path, $2 = original argv[0], $3.. = original argv[1..]
target="$1"
if [ "$#" -ge 2 ]; then
    argv0="$2"
    shift 2
    exec /usr/bin/qemu-arm -L /usr/arm-linux-gnueabihf -0 "$argv0" "$target" "$@"
else
    exec /usr/bin/qemu-arm -L /usr/arm-linux-gnueabihf "$target"
fi
EOF
chmod 755 /usr/local/bin/qemu-arm-binfmt

update-binfmts --disable qemu-arm >/dev/null 2>&1 || true
update-binfmts --remove qemu-arm /usr/local/bin/qemu-arm-binfmt >/dev/null 2>&1 || true

cat >/usr/share/binfmts/qemu-arm <<'EOF'
package qemu-user-static
interpreter /usr/local/bin/qemu-arm-binfmt
magic \x7f\x45\x4c\x46\x01\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x28\x00
offset 0
mask \xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff
fix_binary yes
preserve yes
EOF

update-binfmts --import qemu-arm
update-binfmts --enable qemu-arm
systemctl restart systemd-binfmt || true

apt-get -q -y autoremove
apt-get -q -y clean

wget https://ftp.gnu.org/gnu/autoconf/autoconf-2.72.tar.xz
tar -xf autoconf-2.72.tar.xz
cd autoconf-2.72/
./configure
make
make install
cd ..

mkdir -p bin
cd bin/
curl -O https://raw.githubusercontent.com/kerl/kerl/master/kerl
chmod a+x kerl
cd ..

export PATH="/home/vagrant/bin:$PATH"
kerl cleanup all
kerl build-install 27.0 27.0 /usr/local/lib/erlang/27.0
echo . /usr/local/lib/erlang/27.0/activate >> .bashrc
