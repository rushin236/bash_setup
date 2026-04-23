install_or_update_stylua() {
  [[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

  command -v cargo >/dev/null 2>&1 || return 0

  if ! command -v stylua >/dev/null 2>&1; then
    log "stylua not installed / updating"
    cargo install stylua >/dev/null 2>&1 || return 1
    log "stylua ready"
  fi
}
