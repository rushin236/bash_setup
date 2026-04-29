pkg_nvim() {
  local action="$1"
  local NVIM_DIR="$HOME/.local/opt/nvim"
  local BIN_DIR="$HOME/.local/bin"
  local CHECK_FILE="$HOME/.local/share/bash_setup/checks/nvim.check"

  case "$action" in
    install | update)
      ensure_local_dirs
      local ARCH
      ARCH="$(detect_arch)"
      local FILE=""

      case "$ARCH" in
        amd64) FILE="nvim-linux-x86_64.tar.gz" ;;
        arm64) FILE="nvim-linux-arm64.tar.gz" ;;
        *)
          die "Unsupported architecture: $ARCH"
          return 1
          ;;
      esac

      local NEEDS_INSTALL=0
      local LOCAL_VER=""
      local REMOTE_VER=""

      if [[ ! -x "$BIN_DIR/nvim" ]]; then
        NEEDS_INSTALL=1
        log "Neovim not installed"
      elif [[ "$action" == "update" ]] || [[ ! -f "$CHECK_FILE" ]] || [[ -n "$(find "$CHECK_FILE" -mtime +7 2>/dev/null)" ]]; then
        LOCAL_VER="$("$BIN_DIR/nvim" --version | head -n1 | awk '{print $2}')"

        has_internet || {
          log "No internet. Skipping Neovim version check."
          touch "$CHECK_FILE"
          return 0
        }

        # API Bypass
        REMOTE_VER="$(basename "$(curl -fsSLw "%{url_effective}" -o /dev/null "https://github.com/neovim/neovim/releases/latest")")"

        if [[ -n "$REMOTE_VER" && "$LOCAL_VER" != "$REMOTE_VER" ]]; then
          NEEDS_INSTALL=1
          log "Neovim update available: $LOCAL_VER -> $REMOTE_VER"
        else
          touch "$CHECK_FILE"
        fi
      fi

      if [[ $NEEDS_INSTALL -eq 1 ]]; then
        has_internet || {
          log "No internet. Cannot download Neovim."
          return 0
        }

        [[ -z "$REMOTE_VER" ]] && REMOTE_VER="$(basename "$(curl -fsSLw "%{url_effective}" -o /dev/null "https://github.com/neovim/neovim/releases/latest")")"

        local URL="https://github.com/neovim/neovim/releases/download/$REMOTE_VER/$FILE"
        local TMP_DIR="/tmp/nvim_update_$RANDOM"

        mkdir -p "$TMP_DIR"
        log "Downloading Neovim $REMOTE_VER..."

        if curl -fsSL "$URL" | tar -xzf - -C "$TMP_DIR" --strip-components=1 2>/dev/null; then
          rm -rf "$NVIM_DIR"
          mv "$TMP_DIR" "$NVIM_DIR"
          ln -sf "$NVIM_DIR/bin/nvim" "$BIN_DIR/nvim"

          touch "$CHECK_FILE"
          log "Neovim ready"
        else
          log "Failed to download Neovim. Current version retained."
          rm -rf "$TMP_DIR"
          return 1
        fi
      fi
      ;;

    remove)
      log "Removing Neovim..."
      rm -rf "$NVIM_DIR" "$BIN_DIR/nvim" "$CHECK_FILE"
      log "Neovim removed"
      ;;
  esac
}
