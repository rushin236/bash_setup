install_or_update_rust() {
  ensure_local_dirs

  local CHECK="$HOME/.local/share/bash_setup/checks/rust.check"
  local NEEDS_INSTALL=0

  need_any curl wget || return 1

  if [[ ! -x "$HOME/.cargo/bin/rustc" ]]; then
    NEEDS_INSTALL=1
    log "Rust not installed"
  elif [[ ! -f "$CHECK" ]] || [[ -n "$(find "$CHECK" -mtime +7 2>/dev/null)" ]]; then
    NEEDS_INSTALL=1
  fi

  if [[ $NEEDS_INSTALL -eq 1 ]]; then
    curl -fsSL https://sh.rustup.rs | sh -s -- -y >/dev/null 2>&1 || return 1
    "$HOME/.cargo/bin/rustup" update >/dev/null 2>&1 || true
    touch "$CHECK"
    log "Rust ready"
  fi
}
