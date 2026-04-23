install_or_update_go() {
  ensure_local_dirs

  local DIR="$HOME/.local/opt/go"
  local CHECK="$HOME/.local/share/bash_setup/checks/go.check"

  local ARCH="$(detect_arch)"
  local FILE=""

  case "$ARCH" in
    amd64) FILE="go1.24.2.linux-amd64.tar.gz" ;;
    arm64) FILE="go1.24.2.linux-arm64.tar.gz" ;;
    *) return 1 ;;
  esac

  if [[ ! -x "$DIR/bin/go" ]] || [[ ! -f "$CHECK" ]] || [[ -n "$(find "$CHECK" -mtime +7 2>/dev/null)" ]]; then
    log "Go not installed / updating"
    rm -rf "$DIR"
    makedirs "$HOME/.local/opt"

    curl -fsSL "https://go.dev/dl/$FILE" | tar -xzf - -C "$HOME/.local/opt" >/dev/null 2>&1 || return 1
    # mv "$HOME/.local/opt/go" "$DIR"

    touch "$CHECK"
    log "Go ready"
  fi
}
