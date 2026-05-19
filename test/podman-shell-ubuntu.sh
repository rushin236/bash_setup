shell_ubuntu_amd64() { _shell_ubuntu_container "amd64"; }
shell_ubuntu_arm64() { _shell_ubuntu_container "arm64"; }

_shell_ubuntu_container() {
  local target_arch="${1:-amd64}"
  echo "Starting Debian Linux container (${target_arch})..."

  podman run --rm -it \
    --arch "$target_arch" \
    --network=host \
    -v "$PWD":/host_cwd:z \
    docker.io/library/ubuntu:latest \
    /bin/bash -c '
    # Update package database and install dependencies
    apt-get update && apt-get install -y build-essential git make curl \
      wget tar xz-utils libssl-dev zlib1g-dev libbz2-dev libreadline-dev \
      libsqlite3-dev libffi-dev pkg-config re2c bison autoconf \
      libxml2-dev libonig-dev libcurl4-openssl-dev libzip-dev gettext \
      libicu-dev libpng-dev libjpeg-dev libfreetype6-dev

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
