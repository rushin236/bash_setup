pkg_uv() {
  local action="$1"
  local BIN="$HOME/.local/bin/uv"
  local CHECK="$HOME/.local/share/bash_setup/checks/uv.check"

  case "$action" in
    install | update)
      ensure_local_dirs
      local ARCH="$(detect_arch)"
      local DL_ARCH=""
      case "$ARCH" in
        amd64) DL_ARCH="x86_64-unknown-linux-gnu" ;;
        arm64) DL_ARCH="aarch64-unknown-linux-gnu" ;;
        *) return 1 ;;
      esac

      local NEEDS_INSTALL=0
      local LOCAL_VER=""
      local REMOTE_VER=""

      if [[ ! -x "$BIN" ]]; then
        NEEDS_INSTALL=1
      elif [[ "$action" == "update" ]] || [[ ! -f "$CHECK" ]] || [[ -n "$(find "$CHECK" -mtime +7 2>/dev/null)" ]]; then
        LOCAL_VER="$("$BIN" --version | awk '{print $2}')"
        has_internet || {
          touch "$CHECK"
          return 0
        }

        # API Bypass
        REMOTE_VER="$(basename "$(curl -fsSLw "%{url_effective}" -o /dev/null "https://github.com/astral-sh/uv/releases/latest")" | sed 's/^v//')"

        if [[ -n "$REMOTE_VER" && "$LOCAL_VER" != "$REMOTE_VER" ]]; then
          NEEDS_INSTALL=1
          log "uv update available: $LOCAL_VER -> $REMOTE_VER"
        else
          touch "$CHECK"
        fi
      fi

      if [[ $NEEDS_INSTALL -eq 1 ]]; then
        has_internet || return 0
        [[ -z "$REMOTE_VER" ]] && REMOTE_VER="$(basename "$(curl -fsSLw "%{url_effective}" -o /dev/null "https://github.com/astral-sh/uv/releases/latest")" | sed 's/^v//')"

        if [[ -z "$REMOTE_VER" ]]; then
          log "Failed to fetch uv version. Skipping update."
          return 1
        fi

        local FILE="uv-${DL_ARCH}.tar.gz"
        local URL="https://github.com/astral-sh/uv/releases/download/${REMOTE_VER}/$FILE"
        local TMP_DIR="/tmp/uv_$RANDOM"

        mkdir -p "$TMP_DIR"
        if curl -fsSL "$URL" | tar -xzf - -C "$TMP_DIR" --strip-components=1 2>/dev/null; then
          mv "$TMP_DIR/uv" "$BIN"
          mv "$TMP_DIR/uvx" "$HOME/.local/bin/uvx" 2>/dev/null || true
          touch "$CHECK"
          log "uv ready"
        else
          log "Failed to download uv."
        fi
        rm -rf "$TMP_DIR"
      fi
      ;;
    remove)
      log "Removing uv..."
      rm -f "$BIN" "$HOME/.local/bin/uvx" "$CHECK"
      log "uv removed. (Environments in ~/.local/share/uv retained)"
      ;;
  esac
}
