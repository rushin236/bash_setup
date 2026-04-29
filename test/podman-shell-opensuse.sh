shell_opensuse_amd64() { _shell_opensuse_logic "amd64"; }
shell_opensuse_arm64() { _shell_opensuse_logic "arm64"; }

_shell_opensuse_logic() {
  local arch=$1
  CNAME="test-shell-opensuse-$arch"
  podman rm -f $CNAME 2>/dev/null || true
  podman run --rm -it --platform "linux/$arch" -v "$PWD:/workspace:Z" --name $CNAME opensuse/tumbleweed bash -c "
    zypper --non-interactive install \
    bash git curl wget tar gzip xz unzip zip bzip2 shadow sudo procps make gcc gcc-c++ grep sed \
    gawk findutils coreutils libffi-devel libyaml-devel libopenssl-devel zlib-devel \
    readline-devel gmp-devel lua54 lua54-devel lua54-luarocks php php-cli jq tmux ImageMagick \
    ghostscript pandoc sqlite3 bat btop ncdu pkgconf-pkg-config \
    fontconfig-devel freetype2-devel harfbuzz-devel sqlite3-devel \
    libicu-devel libcurl-devel libpng16-devel libgraphite2-devel 1>/dev/null

    useradd -m -s /bin/bash tester
    echo 'tester ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers
    cp -r /workspace /home/tester/project 
    cp /home/tester/project/.bashrc /home/tester/.bashrc
    cp /home/tester/project/.bash_profile /home/tester/.bash_profile
    cp /home/tester/project/.blerc /home/tester/.blerc
    cp -r /home/tester/project/.bashrc.d /home/tester/.bashrc.d
    chown -R tester:tester /home/tester
    exec su - tester"
}
