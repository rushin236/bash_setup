pkg_ripgrep() {
  local action="$1"
  local DIR="$HOME/.local/opt/rg"
  local BIN="$HOME/.local/bin/rg"
  local CHECK="$HOME/.local/share/bash_setup/checks/ripgrep.check"

  case "$action" in
    install | update)
      ensure_local_dirs
      local ARCH="$(detect_arch)"
      local DL_ARCH=""

      case "$ARCH" in
        amd64) DL_ARCH="x86_64-unknown-linux-musl" ;;
        arm64) DL_ARCH="aarch64-unknown-linux-gnu" ;;
        *) return 1 ;;
      esac

      local NEEDS_INSTALL=0
      local LOCAL_VER=""
      local REMOTE_VER=""

      if [[ ! -x "$BIN" ]]; then
        NEEDS_INSTALL=1
      elif [[ "$action" == "update" ]] || [[ ! -f "$CHECK" ]] || [[ -n "$(find "$CHECK" -mtime +7 2>/dev/null)" ]]; then
        LOCAL_VER="$("$BIN" --version | head -n 1 | awk '{print $2}')"

        has_internet || {
          log "No internet. Skipping ripgrep version check."
          touch "$CHECK"
          return 0
        }

        # API Bypass
        REMOTE_VER="$(basename "$(curl -fsSLw "%{url_effective}" -o /dev/null "https://github.com/BurntSushi/ripgrep/releases/latest")")"

        if [[ -n "$REMOTE_VER" && "$LOCAL_VER" != "${REMOTE_VER}" ]]; then
          NEEDS_INSTALL=1
          log "ripgrep update available: $LOCAL_VER -> $REMOTE_VER"
        else
          touch "$CHECK"
        fi
      fi

      if [[ $NEEDS_INSTALL -eq 1 ]]; then
        has_internet || {
          log "No internet. Cannot download ripgrep."
          return 0
        }

        [[ -z "$REMOTE_VER" ]] && REMOTE_VER="$(basename "$(curl -fsSLw "%{url_effective}" -o /dev/null "https://github.com/BurntSushi/ripgrep/releases/latest")")"

        if [[ -z "$REMOTE_VER" ]]; then
          log "Failed to fetch ripgrep version. Skipping update."
          return 1
        fi

        local FILE="ripgrep-${REMOTE_VER}-${DL_ARCH}.tar.gz"
        local URL="https://github.com/BurntSushi/ripgrep/releases/download/${REMOTE_VER}/$FILE"
        local TMP_DIR="/tmp/rg_update_$RANDOM"

        mkdir -p "$TMP_DIR"
        log "Downloading ripgrep $REMOTE_VER..."

        if curl -fsSL "$URL" | tar -xzf - --strip-components=1 -C "$TMP_DIR" 2>/dev/null; then
          rm -rf "$DIR"
          mv "$TMP_DIR" "$DIR"
          ln -sf "$DIR/rg" "$BIN"

          touch "$CHECK"
          log "ripgrep ready"
        else
          log "Failed to download ripgrep. Current version retained."
          rm -rf "$TMP_DIR"
          return 1
        fi
      fi
      ;;

    remove)
      log "Removing ripgrep..."
      rm -rf "$DIR" "$BIN" "$CHECK"
      log "ripgrep removed"
      ;;
  esac
}
