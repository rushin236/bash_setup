shell_fedora_amd64() { _shell_fedora_container "amd64"; }
shell_fedora_arm64() { _shell_fedora_container "arm64"; }

_shell_fedora_container() {
  local target_arch="${1:-amd64}"
  echo "Starting Fedora Linux container (${target_arch})..."

  podman run --rm -it \
    --arch "$target_arch" \
    --network=host \
    -v "$PWD":/host_cwd:z \
    docker.io/library/fedora:latest \
    /bin/bash -c '
    # Update package database and install dependencies
    dnf install -y @development-tools util-linux git make curl wget tar xz \
      openssl-devel zlib-devel bzip2-devel readline-devel sqlite-devel libffi-devel \
      pkgconfig re2c bison autoconf libxml2-devel oniguruma-devel libcurl-devel \
      libzip-devel gettext-devel libicu-devel libpng-devel libjpeg-turbo-devel \
      freetype-devel gdbm-devel libwebp-devel libXpm-devel gcc-c++ automake libtool

    # Create tester user
    useradd -m -s /bin/bash tester

    # Copy CWD contents to test user home and fix permissions
    cp -a /host_cwd/. /home/tester/
    chown -R test:test /home/tester

    echo -e "\nEnvironment ready. Handing over to user: test"

    # Switch to test user and launch interactive shell
    cd /home/test
    exec su - test
    '
}
