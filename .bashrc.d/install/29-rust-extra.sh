install_or_update_rust_extra() {
  [[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

  command -v rustup >/dev/null 2>&1 || return 0

  log "Rust extras not installed / updating"

  rustup component add rustfmt clippy >/dev/null 2>&1 || return 1

  log "Rust extras ready"
}
