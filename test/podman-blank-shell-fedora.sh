blank_shell_fedora_amd64() { _run_blank_shell_fedora_container "amd64"; }
blank_shell_fedora_arm64() { _run_blank_shell_fedora_container "arm64"; }

_run_blank_shell_fedora_container() {
  local target_arch="${1:-amd64}"
  echo "Starting Fedora Linux container (${target_arch})..."

  podman run --rm -it \
    --arch "$target_arch" \
    --network=host \
    -v "$PWD":/host_cwd:z \
    docker.io/library/fedora:latest \
    /bin/bash -c '
            # Install dependencies
            dnf install -y git make curl wget tar xz

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
