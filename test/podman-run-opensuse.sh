run_opensuse_amd64() { _run_opensuse_container "amd64"; }
run_opensuse_arm64() { _run_opensuse_container "arm64"; }

_run_opensuse_container() {
  local target_arch="${1:-amd64}"
  echo "Starting Opensuse Linux container (${target_arch})..."

  podman run --rm -it \
    --arch "$target_arch" \
    --network=host \
    -v "$PWD":/host_cwd:z \
    registry.opensuse.org/opensuse/leap:latest \
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
