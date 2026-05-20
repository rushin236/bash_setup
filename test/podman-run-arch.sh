run_arch_amd64() { _run_arch_container "amd64"; }
run_arch_arm64() { _run_arch_container "arm64"; }

_run_arch_container() {
  local target_arch="${1:-amd64}"
  echo "Starting Arch Linux container (${target_arch})..."

  podman run --rm -i \
    --arch "$target_arch" \
    --network=host \
    -v "$PWD":/host_cwd:z \
    localhost/my-amd64-archlinux-tester:latest \
    /bin/bash -c '
    # Update package database and install dependencies
    # pacman -Syu --noconfirm base-devel git make curl wget tar \
    #     xz gawk unzip openssl zlib bzip2 readline sqlite libffi \
    #     pkgconf re2c bison libxml2 oniguruma libzip gettext \
    #     harfbuzz harfbuzz-icu graphite2 fontconfig icu libpng \
    #     libjpeg-turbo freetype2 gd pcre2 >/dev/null

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
