#!/usr/bin/env bash
set -euo pipefail

AUTOCONF_VERSION=2.72
ERLANG_VERSION=27.3.4.14
ERLANG_BUILD_NAME="otp-${ERLANG_VERSION}"
ERLANG_INSTALL_DIR="/usr/local/lib/erlang/${ERLANG_VERSION}"
ELIXIR_VERSION=1.20.2
ELIXIR_INSTALL_DIR="/usr/local/lib/elixir/${ELIXIR_VERSION}"
VAGRANT_BASHRC=/home/vagrant/.bashrc
VAGRANT_BIN_DIR=/home/vagrant/bin

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
    clang \
    unzip

# qemu-user-static and qemu-user-binfmt conflict on Ubuntu.
if dpkg-query -W -f='${Status}' qemu-user-binfmt 2>/dev/null | grep -q "install ok installed"; then
    apt-get -q -y remove qemu-user-binfmt
fi

# Ensure ARM32 binaries can be executed directly via binfmt_misc.
update-binfmts --disable qemu-arm >/dev/null 2>&1 || true
update-binfmts --remove qemu-arm /usr/local/bin/qemu-arm-binfmt >/dev/null 2>&1 || true

qemu_arm_binfmt_tmp="$(mktemp /usr/local/bin/qemu-arm-binfmt.XXXXXX)"
cat >"${qemu_arm_binfmt_tmp}" <<'EOF'
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
chmod 755 "${qemu_arm_binfmt_tmp}"
mv "${qemu_arm_binfmt_tmp}" /usr/local/bin/qemu-arm-binfmt

cat >/usr/share/binfmts/qemu-arm <<'EOF'
package qemu-user-static
interpreter /usr/local/bin/qemu-arm-binfmt
magic \x7f\x45\x4c\x46\x01\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x28\x00
offset 0
mask \xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff
fix_binary yes
preserve yes
EOF

systemctl restart systemd-binfmt || true
update-binfmts --import qemu-arm
update-binfmts --enable qemu-arm

apt-get -q -y autoremove
apt-get -q -y clean

if ! command -v autoconf >/dev/null 2>&1 || ! autoconf --version | grep -Fq "autoconf (GNU Autoconf) ${AUTOCONF_VERSION}"; then
    AUTOCONF_TARBALL="/tmp/autoconf-${AUTOCONF_VERSION}.tar.xz"
    AUTOCONF_SRC_DIR="/tmp/autoconf-${AUTOCONF_VERSION}"
    curl -fsSL -o "${AUTOCONF_TARBALL}" \
        "https://ftp.gnu.org/gnu/autoconf/autoconf-${AUTOCONF_VERSION}.tar.xz"
    rm -rf "${AUTOCONF_SRC_DIR}"
    tar -xf "${AUTOCONF_TARBALL}" -C /tmp
    (
        cd "${AUTOCONF_SRC_DIR}"
        ./configure
        make
        make install
    )
fi

mkdir -p "${VAGRANT_BIN_DIR}"
curl -fsSL -o "${VAGRANT_BIN_DIR}/kerl" https://raw.githubusercontent.com/kerl/kerl/master/kerl
chmod 755 "${VAGRANT_BIN_DIR}/kerl"
chown vagrant:vagrant "${VAGRANT_BIN_DIR}/kerl"

export PATH="${VAGRANT_BIN_DIR}:$PATH"
if [ ! -x "${ERLANG_INSTALL_DIR}/bin/erl" ]; then
    if ! kerl list builds 2>/dev/null | grep -Fq "${ERLANG_BUILD_NAME}"; then
        kerl build "${ERLANG_VERSION}" "${ERLANG_BUILD_NAME}"
    fi
    if [ -e "${ERLANG_INSTALL_DIR}" ] && [ ! -x "${ERLANG_INSTALL_DIR}/bin/erl" ]; then
        rm -rf "${ERLANG_INSTALL_DIR}"
    fi
    kerl install "${ERLANG_BUILD_NAME}" "${ERLANG_INSTALL_DIR}"
    kerl cleanup all
fi

ERLANG_ACTIVATE_LINE=". ${ERLANG_INSTALL_DIR}/activate"
grep -Fqx "${ERLANG_ACTIVATE_LINE}" "${VAGRANT_BASHRC}" || echo "${ERLANG_ACTIVATE_LINE}" >> "${VAGRANT_BASHRC}"

# Older kerl-generated activate scripts are not nounset-safe.
set +u
. "${ERLANG_INSTALL_DIR}/activate"
set -u

if [ ! -x "${ELIXIR_INSTALL_DIR}/bin/elixir" ]; then
    curl -fsSL -o /tmp/elixir-otp-27.zip \
        "https://github.com/elixir-lang/elixir/releases/download/v${ELIXIR_VERSION}/elixir-otp-27.zip"
    rm -rf "${ELIXIR_INSTALL_DIR}"
    mkdir -p "${ELIXIR_INSTALL_DIR}"
    unzip -q /tmp/elixir-otp-27.zip -d "${ELIXIR_INSTALL_DIR}"
    rm -f /tmp/elixir-otp-27.zip
fi

ln -sf "${ELIXIR_INSTALL_DIR}/bin/elixir" /usr/local/bin/elixir
ln -sf "${ELIXIR_INSTALL_DIR}/bin/elixirc" /usr/local/bin/elixirc
ln -sf "${ELIXIR_INSTALL_DIR}/bin/iex" /usr/local/bin/iex
ln -sf "${ELIXIR_INSTALL_DIR}/bin/mix" /usr/local/bin/mix
