shell_arch_amd64() { _shell_arch_container "amd64"; }
shell_arch_arm64() { _shell_arch_container "arm64"; }

_shell_arch_container() {
  local target_arch="${1:-amd64}"
  echo "Starting Arch Linux container (${target_arch})..."

  podman run --rm -it \
    --arch "$target_arch" \
    --network=host \
    -v "$PWD":/host_cwd:z \
    docker.io/library/archlinux:latest \
    /bin/bash -c '
    # Update package database and install dependencies
    pacman -Syu --noconfirm base-devel git make curl wget tar xz \
      openssl zlib bzip2 readline sqlite libffi pkgconf re2c bison \
      libxml2 oniguruma libzip gettext icu libpng libjpeg-turbo freetype2

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
