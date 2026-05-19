run_fedora_amd64() { _run_fedora_container "amd64"; }
run_fedora_arm64() { _run_fedora_container "arm64"; }

_run_fedora_container() {
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
    chown -R tester:tester /home/tester

    echo -e "\nEnvironment ready. Handing over to user: tester"
    cd /home/tester

    # Execute everything else dynamically as the tester user
    # Using a heredoc (EOF) entirely avoids the SC2026 single-quote nesting issue
    su - tester << "EOF"
        source ~/.bash_profile

        echo "=== Running Installation Tools ==="
        tool pkg install all
        MISE_VERBOSE=1 PHP_VERBOSE=1 tool sync all

        echo -e "\n=== Verifying Installed Programs ===\n"

        # A clean, space-separated list of your tools
        tools="fzf nvim starship carapace uv python pip node npm rustc cargo \
               rustfmt clippy-driver go shellcheck shfmt ruby gem markdown-toc \
               php composer java javac julia lua luarocks jq yq tmux magick \
               gs lazygit delta pandoc sqlite3 bat eza zoxide btop ncdu tectonic"

        for bin in $tools; do
            # Dynamically determine the correct version flag
            case "$bin" in
                go)   flag="version" ;;
                lua)  flag="-v" ;;
                tmux) flag="-V" ;;
                *)    flag="--version" ;;
            esac

            echo -n "[CHECK] $bin $flag -> "
            
            # Check if the command exists before executing to prevent ugly not found shell errors
            if command -v "$bin" >/dev/null 2>&1; then
                "$bin" $flag 2>&1 | head -n 1
            else
                echo "❌ FAILED / NOT INSTALLED"
            fi
            echo "----------------------------------------"
        done

        echo -e "\n=== Tests Complete. Exiting Container. ==="
EOF
    '
}
