run_debian_amd64() { _run_debian_container "amd64"; }
run_debian_arm64() { _run_debian_container "arm64"; }

_run_debian_container() {
  local target_arch="${1:-amd64}"
  echo "Starting Debian Linux container (${target_arch})..."

  podman run --rm -it \
    --arch "$target_arch" \
    --network=host \
    -v "$PWD":/host_cwd:z \
    localhost/my-amd64-debian-tester:latest \
    /bin/bash -c '
    # Prevent apt from prompting for timezone/keyboard configurations
    # export DEBIAN_FRONTEND=noninteractive

    # Update package database and install dependencies
    # apt-get update && apt-get install -y --no-install-recommends \
    #     build-essential autoconf bison re2c pkg-config ca-certificates \
    #     git curl wget make tar xz-utils gzip gawk unzip \
    #     libxml2-dev libssl-dev libicu-dev libzip-dev libonig-dev \
    #     libcurl4-openssl-dev libpng-dev libjpeg-dev libfreetype-dev \
    #     libreadline-dev libbz2-dev libsqlite3-dev libgd-dev libpcre2-dev \
    #     libharfbuzz-dev libgraphite2-dev >/dev/null

    # Create tester user
    # useradd -m -s /bin/bash tester

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
        tool sync all
        # tool subpkg npm install all
        # tool subpkg go install all
        # tool subpkg cargo install all
        # tool subpkg rustup install all
        cat ~/.config/mise/config.toml
        # tool sync php

        echo -e "\n=== Verifying Installed Programs ===\n"

        # A clean, space-separated list of your tools
        tools="fzf nvim starship carapace uv python pip node npm rustc cargo \
               rustfmt clippy-driver go shellcheck shfmt ruby gem markdown-toc \
               php composer java javac julia lua luarocks yq lazygit delta \
               eza zoxide tectonic"

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
                "$bin" $flag 2>&1
            else
                echo "❌ FAILED / NOT INSTALLED"
            fi
            echo "----------------------------------------"
        done

        echo -e "\n=== Tests Complete. Exiting Container. ==="
EOF
    '
}
