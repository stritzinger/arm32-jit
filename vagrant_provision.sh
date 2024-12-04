#!/usr/bin/env bash
set -euo pipefail


apt-get -q update
apt-get -q -y install \
    autoconf gcc make qemu qemu-user \
    pkg-config \
    gcc-arm-linux-gnueabihf \
    g++-arm-linux-gnueabihf \
    binutils-arm-linux-gnueabihf \
    gdb-multiarch \
    ncurses-dev \
    clang
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
