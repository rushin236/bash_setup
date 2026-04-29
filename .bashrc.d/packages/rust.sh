pkg_rust() {
  local action="$1"
  local CHECK="$HOME/.local/share/bash_setup/checks/rust.check"

  case "$action" in
    install | update)
      ensure_local_dirs
      local NEEDS_INSTALL=0

      if [[ ! -x "$HOME/.cargo/bin/rustc" ]]; then
        NEEDS_INSTALL=1
      elif [[ "$action" == "update" ]] || [[ ! -f "$CHECK" ]] || [[ -n "$(find "$CHECK" -mtime +7 2>/dev/null)" ]]; then
        has_internet || {
          touch "$CHECK"
          return 0
        }
        log "Checking for Rust toolchain updates..."
        "$HOME/.cargo/bin/rustup" update >/dev/null 2>&1 || true
        touch "$CHECK"
      fi

      if [[ $NEEDS_INSTALL -eq 1 ]]; then
        has_internet || {
          log "No internet. Skipping Rust."
          return 0
        }
        log "Installing Rustup..."

        curl -fsSL https://sh.rustup.rs -o /tmp/rustup.sh || {
          log "Failed to connect to Rustup servers."
          return 1
        }

        sh /tmp/rustup.sh -y --no-modify-path >/dev/null 2>&1 || return 1
        rm -f /tmp/rustup.sh

        touch "$CHECK"
        log "Rust ready"
      fi
      ;;
    remove)
      log "Removing Rust toolchain..."
      if command -v rustup >/dev/null 2>&1; then
        rustup self uninstall -y >/dev/null 2>&1
      fi
      rm -rf "$HOME/.cargo" "$HOME/.rustup" "$CHECK"
      log "Rust removed"
      ;;
  esac
}
