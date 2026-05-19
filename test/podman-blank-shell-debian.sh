blank_shell_debian_amd64() { _run_blank_shell_debian_container "amd64"; }
blank_shell_debian_arm64() { _run_blank_shell_debian_container "arm64"; }

_run_blank_shell_debian_container() {
  local target_arch="${1:-amd64}"
  echo "Starting Debian Linux container (${target_arch})..."

  podman run --rm -it \
    --arch "$target_arch" \
    --network=host \
    -v "$PWD":/host_cwd:z \
    docker.io/library/debian:latest \
    /bin/bash -c '
            # Prevent apt from prompting for timezone/keyboard configurations
            export DEBIAN_FRONTEND=noninteractive

            # Update package database and install dependencies
            apt-get update
            apt-get install -y git make curl wget tar xz-utils

            # Create test user
            useradd -m -s /bin/bash test

            # Copy CWD contents to test user home and fix permissions
            cp -a /host_cwd/. /home/test/
            chown -R test:test /home/test

            echo -e "\nEnvironment ready. Handing over to user: test"
            
            # Switch to test user and launch interactive shell
            cd /home/test
            exec su - test
        '
}
