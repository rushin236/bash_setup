shell_alpine_amd64() { _shell_alpine_container "amd64"; }
shell_alpine_arm64() { _shell_alpine_container "arm64"; }

_shell_alpine_container() {
  local target_arch="${1:-amd64}"
  echo "Starting Alpine Linux container (${target_arch})..."

  podman run --rm -it \
    --arch "$target_arch" \
    --network=host \
    docker.io/library/alpine:latest \
    /bin/bash -c '
    # Update package database and install dependencies
    apk update && apk add --no-cache bash build-base git make curl wget tar xz \
        coreutils shadow openssl-dev zlib-dev bzip2-dev readline-dev \
        sqlite-dev libffi-dev pkgconf re2c bison autoconf linux-headers \
        libxml2-dev oniguruma-dev curl-dev libzip-dev gettext-dev icu-dev \
        libpng-dev libjpeg-turbo-dev freetype-dev \
        gcompat libc6-compat

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
