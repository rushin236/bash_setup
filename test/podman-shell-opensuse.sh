shell_opensuse_amd64() { _shell_opensuse_container "amd64"; }
shell_opensuse_arm64() { _shell_opensuse_container "arm64"; }

_shell_opensuse_container() {
  local target_arch="${1:-amd64}"
  echo "Starting Alpine Linux container (${target_arch})..."

  podman run --rm -it \
    --arch "$target_arch" \
    --network=host \
    -v "$PWD":/host_cwd:z \
    docker.io/library/opensuse/leap:latest \
    /bin/bash -c '
    # Update package database and install dependencies
    zypper --non-interactive refresh

    # 2. Install ONLY the exact required tools (no patterns, no dist-upgrade, no recommended bloat)
    zypper --non-interactive install --no-recommends --force-resolution \
      gcc gcc-c++ make autoconf automake libtool bison re2c pkgconf patch gawk \
      findutils git curl tar xz gzip bzip2 zlib-devel libopenssl-devel sqlite3 \
      sqlite3-devel readline-devel libxml2-devel libcurl-devel libzip-devel \
      oniguruma-devel libtirpc-devel glibc-devel linux-glibc-devel \
      ncurses-devel libicu-devel libpng-devel libjpeg-devel \
      libwebp-devel libsodium-devel gmp-devel ca-certificates

    # Create tester user
    useradd -m -s /bin/bash tester

    # Copy CWD contents to test user home and fix permissions
    cp -a /host_cwd/. /home/tester/
    chown -R tester:tester /home/tester

    echo -e "\nEnvironment ready. Handing over to user: tester"

    # Switch to test user and launch interactive shell
    cd /home/tester
    exec su - tester
    '
}
