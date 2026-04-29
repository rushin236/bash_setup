pkg_go() {
  local action="$1"
  local DIR="$HOME/.local/opt/go"
  local CHECK="$HOME/.local/share/bash_setup/checks/go.check"

  case "$action" in
    install | update)
      ensure_local_dirs
      local ARCH
      ARCH="$(detect_arch)"
      local DL_ARCH=""
      case "$ARCH" in
        amd64) DL_ARCH="amd64" ;;
        arm64) DL_ARCH="arm64" ;;
        *) return 1 ;;
      esac

      local NEEDS_INSTALL=0
      local LOCAL_VER=""
      local REMOTE_VER=""

      if [[ ! -x "$DIR/bin/go" ]]; then
        NEEDS_INSTALL=1
      elif [[ "$action" == "update" ]] || [[ ! -f "$CHECK" ]] || [[ -n "$(find "$CHECK" -mtime +7 2>/dev/null)" ]]; then
        LOCAL_VER="$("$DIR/bin/go" version | awk '{print $3}')"
        has_internet || {
          touch "$CHECK"
          return 0
        }

        REMOTE_VER="$(curl -fsSL "https://go.dev/VERSION?m=text" | head -n 1 | tr -d '\r')"

        if [[ -n "$REMOTE_VER" && "$LOCAL_VER" != "$REMOTE_VER" ]]; then
          NEEDS_INSTALL=1
          log "Go update available: $LOCAL_VER -> $REMOTE_VER"
        else
          touch "$CHECK"
        fi
      fi

      if [[ $NEEDS_INSTALL -eq 1 ]]; then
        has_internet || return 0
        [[ -z "$REMOTE_VER" ]] && REMOTE_VER="$(curl -fsSL "https://go.dev/VERSION?m=text" | head -n 1 | tr -d '\r')"

        if [[ -z "$REMOTE_VER" ]]; then
          log "Failed to fetch Go version. Skipping."
          return 1
        fi

        local FILE="${REMOTE_VER}.linux-${DL_ARCH}.tar.gz"
        local URL="https://go.dev/dl/$FILE"
        local TMP_DIR="/tmp/go_update_$RANDOM"

        mkdir -p "$TMP_DIR"

        if curl -fsSL "$URL" | tar -xzf - -C "$TMP_DIR" 2>/dev/null; then
          rm -rf "$DIR"
          mv "$TMP_DIR/go" "$DIR"

          touch "$CHECK"
          log "Go ready"
        else
          log "Failed to download Go."
        fi
        rm -rf "$TMP_DIR"
      fi
      ;;
    remove)
      log "Removing Go..."
      rm -rf "$DIR" "$CHECK"
      log "Go removed"
      ;;
  esac
}
