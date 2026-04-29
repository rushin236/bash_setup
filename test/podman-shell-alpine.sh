shell_alpine_amd64() { _shell_alpine_logic "amd64"; }
shell_alpine_arm64() { _shell_alpine_logic "arm64"; }

_shell_alpine_logic() {
  local arch=$1
  CNAME="test-shell-alpine-$arch"
  podman rm -f $CNAME 2>/dev/null || true
  podman run --rm -it --platform "linux/$arch" -v "$PWD:/workspace:Z" --name $CNAME alpine:latest sh -c "
    apk add --no-cache \
    bash git curl wget tar gzip xz unzip zip bzip2 shadow sudo build-base linux-headers \
    musl-dev gcompat pkgconf procps grep sed gawk findutils coreutils libffi-dev yaml-dev \
    openssl-dev zlib-dev readline-dev gmp-dev lua luarocks php php-cli php-curl php-mbstring \
    jq tmux imagemagick ghostscript pandoc sqlite bat btop ncdu 1>/dev/null

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
