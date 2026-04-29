pkg_shellcheck() {
  local action="$1"
  local DIR="$HOME/.local/opt/shellcheck"
  local BIN="$HOME/.local/bin/shellcheck"
  local CHECK="$HOME/.local/share/bash_setup/checks/shellcheck.check"

  case "$action" in
    install | update)
      ensure_local_dirs
      local ARCH="$(detect_arch)"
      local DL_ARCH=""
      case "$ARCH" in
        amd64) DL_ARCH="x86_64" ;;
        arm64) DL_ARCH="aarch64" ;;
        *) return 1 ;;
      esac

      local NEEDS_INSTALL=0
      local LOCAL_VER=""
      local REMOTE_VER=""

      if [[ ! -x "$BIN" ]]; then
        NEEDS_INSTALL=1
      elif [[ "$action" == "update" ]] || [[ ! -f "$CHECK" ]] || [[ -n "$(find "$CHECK" -mtime +7 2>/dev/null)" ]]; then
        LOCAL_VER="$("$BIN" --version | grep 'version:' | awk '{print $2}')"
        has_internet || {
          touch "$CHECK"
          return 0
        }

        # API Bypass
        REMOTE_VER="$(basename "$(curl -fsSLw "%{url_effective}" -o /dev/null "https://github.com/koalaman/shellcheck/releases/latest")")"

        if [[ -n "$REMOTE_VER" && "v${LOCAL_VER#v}" != "$REMOTE_VER" ]]; then
          NEEDS_INSTALL=1
          log "Shellcheck update available: $LOCAL_VER -> $REMOTE_VER"
        else
          touch "$CHECK"
        fi
      fi

      if [[ $NEEDS_INSTALL -eq 1 ]]; then
        has_internet || return 0
        [[ -z "$REMOTE_VER" ]] && REMOTE_VER="$(basename "$(curl -fsSLw "%{url_effective}" -o /dev/null "https://github.com/koalaman/shellcheck/releases/latest")")"

        if [[ -z "$REMOTE_VER" ]]; then
          log "Failed to fetch Shellcheck version. Skipping update."
          return 1
        fi

        local FILE="shellcheck-${REMOTE_VER}.linux.${DL_ARCH}.tar.xz"
        local URL="https://github.com/koalaman/shellcheck/releases/download/${REMOTE_VER}/$FILE"
        local TMP_DIR="/tmp/shellcheck_update_$RANDOM"

        mkdir -p "$TMP_DIR"

        if curl -fsSL "$URL" | tar -xJf - --strip-components=1 -C "$TMP_DIR" 2>/dev/null; then
          rm -rf "$DIR"
          mv "$TMP_DIR" "$DIR"
          ln -sf "$DIR/shellcheck" "$BIN"

          touch "$CHECK"
          log "Shellcheck ready"
        else
          log "Failed to download Shellcheck."
        fi
        rm -rf "$TMP_DIR"
      fi
      ;;
    remove)
      log "Removing Shellcheck..."
      rm -rf "$DIR" "$BIN" "$CHECK"
      log "Shellcheck removed"
      ;;
  esac
}
