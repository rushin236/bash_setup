install_or_update_carapace() {

  ensure_local_dirs

  local BIN_DIR="$HOME/.local/bin"
  local CHECK_DIR="$HOME/.local/share/bash_setup/checks"
  local CHECK_FILE="$CHECK_DIR/carapace.check"

  local ARCH=""
  local DL_ARCH=""
  local URL=""
  local TMP_DIR=""

  local NEEDS_INSTALL=0
  local LOCAL_VER=""
  local REMOTE_VER=""

  need tar || return 1
  need_any curl wget || return 1

  ARCH="$(detect_arch)"

  # Mapping based on carapace-bin release naming
  case "$ARCH" in
    amd64) DL_ARCH="amd64" ;;
    arm64) DL_ARCH="arm64" ;;
    *)
      die "Unsupported architecture: $ARCH"
      return 1
      ;;
  esac

  if [[ ! -x "$BIN_DIR/carapace" ]]; then
    NEEDS_INSTALL=1
    log "Carapace not installed"

  elif [[ ! -f "$CHECK_FILE" ]] || [[ -n "$(find "$CHECK_FILE" -mtime +7 2>/dev/null)" ]]; then
    LOCAL_VER="$("$BIN_DIR/carapace" --version | awk '{print $2}')"

    REMOTE_VER="$(curl -fsSL https://api.github.com/repos/carapace-sh/carapace-bin/releases/latest |
      grep -Po '"tag_name": "\K.*?(?=")')"

    if [[ -n "$REMOTE_VER" && "v${LOCAL_VER#v}" != "$REMOTE_VER" ]]; then
      NEEDS_INSTALL=1
      log "Carapace update available: $LOCAL_VER -> $REMOTE_VER"
    fi

    touch "$CHECK_FILE"
  fi

  if [[ $NEEDS_INSTALL -eq 1 ]]; then
    [[ -z "$REMOTE_VER" ]] && REMOTE_VER="$(curl -fsSL https://api.github.com/repos/carapace-sh/carapace-bin/releases/latest |
      grep -Po '"tag_name": "\K.*?(?=")')"

    # Use working logic from old config to find the exact asset URL
    URL="$(curl -fsSL "https://api.github.com/repos/carapace-sh/carapace-bin/releases/tags/$REMOTE_VER" |
      grep "browser_download_url" | grep "linux_${DL_ARCH}.tar.gz" | head -n 1 | cut -d '"' -f 4)"

    if [[ -z "$URL" ]]; then
      die "Failed to find Carapace release for linux_$DL_ARCH"
      return 1
    fi

    TMP_DIR="/tmp/carapace-$RANDOM"
    rm -rf "$TMP_DIR"
    mkdir -p "$TMP_DIR"

    log "Downloading Carapace $REMOTE_VER..."
    # Extract only the carapace binary into the temp directory
    if curl -fsSL "$URL" | tar -xz -C "$TMP_DIR" carapace 2>/dev/null; then
      # Move the binary to the local bin
      mv "$TMP_DIR/carapace" "$BIN_DIR/carapace"
      chmod +x "$BIN_DIR/carapace"

      touch "$CHECK_FILE"
      log "Carapace ready"
      rm -rf "$TMP_DIR"
    else
      die "Carapace install failed"
      rm -rf "$TMP_DIR"
      return 1
    fi
  fi
}
