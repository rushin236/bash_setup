shell_debian_amd64() { _shell_debian_logic "amd64"; }
shell_debian_arm64() { _shell_debian_logic "arm64"; }

_shell_debian_logic() {
  local arch=$1
  CNAME="test-shell-debian-$arch"
  podman rm -f $CNAME 2>/dev/null || true
  podman run --rm -it --platform "linux/$arch" -v "$PWD:/workspace:Z" --name $CNAME debian:stable bash -c "
    export DEBIAN_FRONTEND=noninteractive

    apt-get update >/dev/null
    apt-get install -y bash git curl wget tar gzip xz-utils unzip zip bzip2 passwd sudo \
    procps make gcc g++ grep sed gawk findutils coreutils libffi-dev libyaml-dev libssl-dev \
    zlib1g-dev libreadline-dev libgmp-dev lua5.4 liblua5.4-dev luarocks php-cli jq tmux \
    imagemagick ghostscript pandoc sqlite3 bat btop ncdu pkg-config \
    libfontconfig1-dev libfreetype6-dev libharfbuzz-dev libsqlite3-dev \
    libicu-dev libcurl4-openssl-dev libpng-dev libgraphite2-dev 1>/dev/null

    # Fix the Debian 'bat' naming conflict so validation passes
    ln -sf /usr/bin/batcat /usr/local/bin/bat
    
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
