run_alpine_amd64() { _run_alpine_container "amd64"; }
run_alpine_arm64() { _run_alpine_container "arm64"; }

_run_alpine_container() {
  local target_arch="${1:-amd64}"
  echo "Starting Alpine Linux container (${target_arch})..."

  podman run --rm -i \
    --arch "$target_arch" \
    --network=host \
    -v "$PWD":/host_cwd:z \
    docker.io/library/alpine:latest \
    /bin/sh -c '
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
