install_or_update_fd() {
  ensure_local_dirs

  local DIR="$HOME/.local/opt/fd"
  local CHECK="$HOME/.local/share/bash_setup/checks/fd.check"
  local ARCH="$(detect_arch)"
  local FILE=""

  case "$ARCH" in
    amd64) FILE="fd-v10.2.0-x86_64-unknown-linux-musl.tar.gz" ;;
    arm64) FILE="fd-v10.2.0-aarch64-unknown-linux-gnu.tar.gz" ;;
    *) return 1 ;;
  esac

  if [[ ! -x "$DIR/fd" ]] || [[ ! -f "$CHECK" ]] || [[ -n "$(find "$CHECK" -mtime +7 2>/dev/null)" ]]; then
    log "fd not installed / updating"

    rm -rf "$DIR"
    mkdir -p "$DIR"

    curl -fsSL "https://github.com/sharkdp/fd/releases/download/v10.2.0/$FILE" |
      tar -xzf - --strip-components=1 -C "$DIR" || return 1

    ln -sf "$DIR/fd" "$HOME/.local/bin/fd"

    touch "$CHECK"
    log "fd ready"
  fi
}
