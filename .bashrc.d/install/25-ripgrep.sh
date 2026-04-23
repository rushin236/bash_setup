install_or_update_ripgrep() {
  ensure_local_dirs

  local DIR="$HOME/.local/opt/rg"
  local CHECK="$HOME/.local/share/bash_setup/checks/ripgrep.check"
  local ARCH="$(detect_arch)"
  local FILE=""

  case "$ARCH" in
    amd64) FILE="ripgrep-14.1.1-x86_64-unknown-linux-musl.tar.gz" ;;
    arm64) FILE="ripgrep-14.1.1-aarch64-unknown-linux-gnu.tar.gz" ;;
    *) return 1 ;;
  esac

  if [[ ! -x "$DIR/rg" ]] || [[ ! -f "$CHECK" ]] || [[ -n "$(find "$CHECK" -mtime +7 2>/dev/null)" ]]; then
    log "ripgrep not installed / updating"

    rm -rf "$DIR"
    mkdir -p "$DIR"

    curl -fsSL "https://github.com/BurntSushi/ripgrep/releases/download/14.1.1/$FILE" |
      tar -xzf - --strip-components=1 -C "$DIR" || return 1

    ln -sf "$DIR/rg" "$HOME/.local/bin/rg"

    touch "$CHECK"
    log "ripgrep ready"
  fi
}
