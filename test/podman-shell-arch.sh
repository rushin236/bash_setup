shell_arch_amd64() { _shell_arch_logic "amd64"; }
shell_arch_arm64() { _shell_arch_logic "arm64"; }

_shell_arch_logic() {
  local arch=$1
  CNAME="test-shell-arch-$arch"
  podman rm -f $CNAME 2>/dev/null || true
  podman run --rm -it --platform "linux/$arch" -v "$PWD:/workspace:Z" --name $CNAME archlinux:latest bash -c "
    pacman -Sy --noconfirm --needed bash git curl wget tar gzip xz unzip zip bzip2 which \
    shadow sudo procps-ng make gcc grep sed gawk findutils coreutils base-devel libffi \
    libyaml openssl zlib readline gmp lua luarocks php openssl pkgconf fontconfig \
    freetype2 harfbuzz jq tmux imagemagick ghostscript pandoc sqlite bat btop ncdu 1>/dev/null

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
