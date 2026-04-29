pkg_micromamba() {
  local action="$1"
  local BIN="$HOME/.local/bin/micromamba"
  local CHECK="$HOME/.local/share/bash_setup/checks/micromamba.check"

  case "$action" in
    install | update)
      ensure_local_dirs
      need tar || return 1
      need bzip2 || {
        log "bzip2 required for micromamba. Skipping."
        return 1
      }

      local ARCH="$(detect_arch)"
      local DL_ARCH=""
      case "$ARCH" in
        amd64) DL_ARCH="linux-64" ;;
        arm64) DL_ARCH="linux-aarch64" ;;
        *) return 1 ;;
      esac

      local NEEDS_INSTALL=0
      local LOCAL_VER=""
      local REMOTE_VER=""

      if [[ ! -x "$BIN" ]]; then
        NEEDS_INSTALL=1
      elif [[ "$action" == "update" ]] || [[ ! -f "$CHECK" ]] || [[ -n "$(find "$CHECK" -mtime +7 2>/dev/null)" ]]; then
        LOCAL_VER="$("$BIN" --version 2>/dev/null)"
        has_internet || {
          touch "$CHECK"
          return 0
        }

        # Fixed for Alpine: Swapped grep -Po for basic grep + sed -E
        REMOTE_VER="$(curl -fsSL "https://api.anaconda.org/package/conda-forge/micromamba" | grep -m 1 '"latest_version"' | sed -E 's/.*"latest_version":[[:space:]]*"([^"]+)".*/\1/')"

        if [[ -n "$REMOTE_VER" && "$LOCAL_VER" != "$REMOTE_VER" ]]; then
          NEEDS_INSTALL=1
          log "Micromamba update available: $LOCAL_VER -> $REMOTE_VER"
        else
          touch "$CHECK"
        fi
      fi

      if [[ $NEEDS_INSTALL -eq 1 ]]; then
        has_internet || return 0
        local URL="https://micro.mamba.pm/api/micromamba/${DL_ARCH}/latest"
        local TMP_DIR="/tmp/mamba_$RANDOM"
        mkdir -p "$TMP_DIR"

        log "Downloading Micromamba..."
        if curl -fsSL "$URL" | tar -xvj -C "$TMP_DIR" "bin/micromamba" >/dev/null 2>&1; then
          mv "$TMP_DIR/bin/micromamba" "$BIN"
          chmod +x "$BIN"
          touch "$CHECK"
          log "Micromamba ready"
        fi
        rm -rf "$TMP_DIR"
      fi
      ;;
    remove)
      log "Removing Micromamba executable..."
      rm -f "$BIN" "$CHECK"
      log "Micromamba removed. (Environments in ~/micromamba retained)"
      ;;
  esac
}
