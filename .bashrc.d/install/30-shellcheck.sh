install_or_update_shellcheck() {
  ensure_local_dirs

  local DIR="$HOME/.local/opt/shellcheck"
  local CHECK="$HOME/.local/share/bash_setup/checks/shellcheck.check"
  local ARCH="$(detect_arch)"
  local FILE=""

  case "$ARCH" in
    amd64) FILE="shellcheck-v0.10.0.linux.x86_64.tar.xz" ;;
    arm64) FILE="shellcheck-v0.10.0.linux.aarch64.tar.xz" ;;
    *) return 1 ;;
  esac

  if [[ ! -x "$DIR/shellcheck" ]] ||
    [[ ! -f "$CHECK" ]] ||
    [[ -n "$(find "$CHECK" -mtime +7 2>/dev/null)" ]]; then
    log "shellcheck not installed / updating"

    rm -rf "$DIR"
    mkdir -p "$DIR"

    curl -fsSL \
      "https://github.com/koalaman/shellcheck/releases/download/v0.10.0/$FILE" |
      tar -xJf - --strip-components=1 -C "$DIR" || return 1

    ln -sf "$DIR/shellcheck" "$HOME/.local/bin/shellcheck"

    touch "$CHECK"
    log "shellcheck ready"
  fi
}
