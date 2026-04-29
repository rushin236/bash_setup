pkg_starship() {
  local action="$1"
  local DIR="$HOME/.local/opt/starship"
  local BIN="$HOME/.local/bin/starship"
  local CHECK="$HOME/.local/share/bash_setup/checks/starship.check"

  case "$action" in
    install | update)
      ensure_local_dirs
      local ARCH="$(detect_arch)"
      local DL_ARCH=""
      case "$ARCH" in
        amd64) DL_ARCH="x86_64-unknown-linux-musl" ;;
        arm64) DL_ARCH="aarch64-unknown-linux-musl" ;;
        *) return 1 ;;
      esac

      local NEEDS_INSTALL=0
      local LOCAL_VER=""
      local REMOTE_VER=""

      if [[ ! -x "$BIN" ]]; then
        NEEDS_INSTALL=1
      elif [[ "$action" == "update" ]] || [[ ! -f "$CHECK" ]] || [[ -n "$(find "$CHECK" -mtime +7 2>/dev/null)" ]]; then
        LOCAL_VER="$("$BIN" --version | awk '{print $2}' | sed 's/^v//')"
        has_internet || {
          log "No internet. Skipping Starship check."
          touch "$CHECK"
          return 0
        }

        # API Bypass
        REMOTE_VER="$(basename "$(curl -fsSLw "%{url_effective}" -o /dev/null "https://github.com/starship/starship/releases/latest")" | sed 's/^v//')"

        if [[ -n "$REMOTE_VER" && "$LOCAL_VER" != "$REMOTE_VER" ]]; then
          NEEDS_INSTALL=1
          log "Starship update available: $LOCAL_VER -> $REMOTE_VER"
        else
          touch "$CHECK"
        fi
      fi

      if [[ $NEEDS_INSTALL -eq 1 ]]; then
        has_internet || {
          log "No internet. Cannot download Starship."
          return 0
        }
        [[ -z "$REMOTE_VER" ]] && REMOTE_VER="$(basename "$(curl -fsSLw "%{url_effective}" -o /dev/null "https://github.com/starship/starship/releases/latest")" | sed 's/^v//')"

        if [[ -z "$REMOTE_VER" ]]; then
          log "Failed to fetch Starship version. Skipping update."
          return 1
        fi

        local FILE="starship-${DL_ARCH}.tar.gz"
        local URL="https://github.com/starship/starship/releases/download/v${REMOTE_VER}/$FILE"
        local TMP_DIR="/tmp/starship_update_$RANDOM"

        mkdir -p "$TMP_DIR"

        if curl -fsSL "$URL" | tar -xzf - -C "$TMP_DIR" 2>/dev/null; then
          rm -rf "$DIR"
          mkdir -p "$DIR"
          mv "$TMP_DIR/starship" "$DIR/starship"
          ln -sf "$DIR/starship" "$BIN"

          if [ ! -f "$HOME/.config/starship.toml" ]; then
            mkdir -p "$HOME/.config"
            "$BIN" preset plain-text-symbols -o "$HOME/.config/starship.toml"
          fi

          touch "$CHECK"
          log "Starship ready"
        fi
        rm -rf "$TMP_DIR"
      fi
      ;;
    remove)
      log "Removing Starship..."
      rm -rf "$DIR" "$BIN" "$CHECK"
      log "Starship removed"
      ;;
  esac
}
