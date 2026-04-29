pkg_carapace() {
  local action="$1"
  local DIR="$HOME/.local/opt/carapace"
  local BIN="$HOME/.local/bin/carapace"
  local CHECK="$HOME/.local/share/bash_setup/checks/carapace.check"

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

      if [[ ! -x "$BIN" ]]; then
        NEEDS_INSTALL=1

      elif [[ "$action" == "update" ]] ||
        [[ ! -f "$CHECK" ]] ||
        [[ -n "$(find "$CHECK" -mtime +7 2>/dev/null)" ]]; then

        LOCAL_VER="$("$BIN" --version 2>/dev/null | awk '{print $2}')"

        has_internet || {
          touch "$CHECK"
          return 0
        }

        REMOTE_VER="$(
          basename "$(
            curl -fsSLw "%{url_effective}" \
              -o /dev/null \
              "https://github.com/carapace-sh/carapace-bin/releases/latest"
          )"
        )"

        if [[ -n "$REMOTE_VER" && "v${LOCAL_VER#v}" != "$REMOTE_VER" ]]; then
          NEEDS_INSTALL=1
          log "Carapace update available: $LOCAL_VER -> $REMOTE_VER"
        else
          touch "$CHECK"
        fi
      fi

      if [[ $NEEDS_INSTALL -eq 1 ]]; then
        has_internet || return 0

        [[ -z "$REMOTE_VER" ]] && REMOTE_VER="$(
          basename "$(
            curl -fsSLw "%{url_effective}" \
              -o /dev/null \
              "https://github.com/carapace-sh/carapace-bin/releases/latest"
          )"
        )"

        [[ -z "$REMOTE_VER" ]] && {
          log "Failed to fetch Carapace version."
          return 1
        }

        local URL="https://github.com/carapace-sh/carapace-bin/releases/download/${REMOTE_VER}/carapace-bin_${REMOTE_VER#v}_linux_${DL_ARCH}.tar.gz"

        local TMP_DIR="/tmp/carapace_update_$RANDOM"
        mkdir -p "$TMP_DIR"

        if curl -fsSL "$URL" | tar -xzf - -C "$TMP_DIR" carapace 2>/dev/null; then
          rm -rf "$DIR"
          mkdir -p "$DIR"

          mv "$TMP_DIR/carapace" "$DIR/carapace"
          chmod +x "$DIR/carapace"

          ln -sf "$DIR/carapace" "$BIN"

          touch "$CHECK"
          log "Carapace ready"
        else
          log "Failed to download Carapace."
        fi

        rm -rf "$TMP_DIR"
      fi
      ;;
    remove)
      log "Removing Carapace..."
      rm -rf "$DIR" "$BIN" "$CHECK"
      log "Carapace removed"
      ;;
  esac
}
