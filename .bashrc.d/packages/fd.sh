pkg_fd() {
  local action="$1"
  local DIR="$HOME/.local/opt/fd"
  local BIN="$HOME/.local/bin/fd"
  local CHECK="$HOME/.local/share/bash_setup/checks/fd.check"

  case "$action" in
    install | update)
      ensure_local_dirs
      local ARCH
      ARCH="$(detect_arch)"
      local FILE=""

      case "$ARCH" in
        amd64) FILE="fd-v10.4.2-x86_64-unknown-linux-musl.tar.gz" ;;
        arm64) FILE="fd-v10.4.2-aarch64-unknown-linux-gnu.tar.gz" ;;
        *) return 1 ;;
      esac

      local NEEDS_INSTALL=0
      if [[ ! -x "$BIN" ]] || [[ "$action" == "update" ]] || [[ ! -f "$CHECK" ]] || [[ -n "$(find "$CHECK" -mtime +7 2>/dev/null)" ]]; then
        NEEDS_INSTALL=1
      fi

      if [[ $NEEDS_INSTALL -eq 1 ]]; then
        log "Checking for fd updates..."

        has_internet || {
          log "No internet. Keeping current fd version."
          return 0
        }

        local TMP_DIR="/tmp/fd_update_$RANDOM"
        mkdir -p "$TMP_DIR"

        if curl -fsSL "https://github.com/sharkdp/fd/releases/download/v10.4.2/$FILE" | tar -xzf - --strip-components=1 -C "$TMP_DIR" 2>/dev/null; then
          rm -rf "$DIR"
          mv "$TMP_DIR" "$DIR"
          ln -sf "$DIR/fd" "$BIN"

          touch "$CHECK"
          log "fd ready and updated"
        else
          log "Failed to download fd. Current version retained."
          rm -rf "$TMP_DIR"
          return 1
        fi
      fi
      ;;

    remove)
      log "Removing fd..."
      rm -rf "$DIR" "$BIN" "$CHECK"
      log "fd removed"
      ;;
  esac
}
