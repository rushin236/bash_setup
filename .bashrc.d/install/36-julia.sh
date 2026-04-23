install_or_update_julia() {
  ensure_local_dirs

  local DIR="$HOME/.local/opt/julia"
  local CHECK="$HOME/.local/share/bash_setup/checks/julia.check"

  local ARCH="$(detect_arch)"
  local FILE=""

  case "$ARCH" in
    amd64) FILE="julia-1.11.5-linux-x86_64.tar.gz" ;;
    arm64) FILE="julia-1.11.5-linux-aarch64.tar.gz" ;;
    *) return 1 ;;
  esac

  local URL="https://julialang-s3.julialang.org/bin/linux/$([ "$ARCH" = amd64 ] && echo x64 || echo aarch64)/1.11/$FILE"

  if [[ ! -x "$DIR/bin/julia" ]] ||
    [[ ! -f "$CHECK" ]] ||
    [[ -n "$(find "$CHECK" -mtime +14 2>/dev/null)" ]]; then

    log "Julia not installed / updating"

    rm -rf "$DIR"
    mkdir -p "$DIR"

    curl -fsSL "$URL" | tar -xzf - --strip-components=1 -C "$DIR" || return 1

    ln -sf "$DIR/bin/julia" "$HOME/.local/bin/julia"

    touch "$CHECK"
    log "Julia ready"
  fi
}
