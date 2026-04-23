install_or_update_nvim() {

  ensure_local_dirs

  local NVIM_DIR="$HOME/.local/opt/nvim"
  local BIN_DIR="$HOME/.local/bin"
  local CHECK_DIR="$HOME/.local/share/bash_setup/checks"
  local CHECK_FILE="$CHECK_DIR/nvim.check"

  local ARCH=""
  local FILE=""
  local URL=""
  local TMP_DIR=""

  local NEEDS_INSTALL=0
  local LOCAL_VER=""
  local REMOTE_VER=""

  need tar || return 1
  need_any curl wget || return 1

  ARCH="$(detect_arch)"

  case "$ARCH" in
    amd64) FILE="nvim-linux-x86_64.tar.gz" ;;
    arm64) FILE="nvim-linux-arm64.tar.gz" ;;
    *)
      die "Unsupported architecture: $ARCH"
      return 1
      ;;
  esac

  if [[ ! -x "$BIN_DIR/nvim" ]]; then
    NEEDS_INSTALL=1
    log "Neovim not installed"

  elif [[ ! -f "$CHECK_FILE" ]] || [[ -n "$(find "$CHECK_FILE" -mtime +7 2>/dev/null)" ]]; then
    LOCAL_VER="$("$BIN_DIR/nvim" --version | head -n1 | awk '{print $2}')"

    REMOTE_VER="$(curl -fsSL https://api.github.com/repos/neovim/neovim/releases/latest |
      grep -Po '"tag_name": "\K.*?(?=")')"

    if [[ -n "$REMOTE_VER" && "$LOCAL_VER" != "$REMOTE_VER" ]]; then
      NEEDS_INSTALL=1
      log "Neovim update available: $LOCAL_VER -> $REMOTE_VER"
    fi

    touch "$CHECK_FILE"
  fi

  if [[ $NEEDS_INSTALL -eq 1 ]]; then
    [[ -z "$REMOTE_VER" ]] && REMOTE_VER="$(curl -fsSL https://api.github.com/repos/neovim/neovim/releases/latest |
      grep -Po '"tag_name": "\K.*?(?=")')"

    URL="https://github.com/neovim/neovim/releases/download/$REMOTE_VER/$FILE"
    TMP_DIR="/tmp/nvim-$RANDOM"

    rm -rf "$TMP_DIR"
    mkdir -p "$TMP_DIR"

    if curl -fsSL "$URL" | tar -xzf - -C "$TMP_DIR" --strip-components=1; then
      rm -rf "$NVIM_DIR"
      mv "$TMP_DIR" "$NVIM_DIR"

      ln -sf "$NVIM_DIR/bin/nvim" "$BIN_DIR/nvim"
      touch "$CHECK_FILE"

      log "Neovim ready"
    else
      die "Neovim install failed"
      rm -rf "$TMP_DIR"
      return 1
    fi
  fi
}
