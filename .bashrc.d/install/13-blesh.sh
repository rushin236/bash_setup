install_or_update_blesh() {
  ensure_local_dirs

  local DIR="$HOME/.local/opt/blesh-src"
  local CHECK_DIR="$HOME/.local/share/bash_setup/checks"
  local CHECK_FILE="$CHECK_DIR/blesh.check"

  local NEEDS_INSTALL=0
  local LOCAL_VER=""
  local REMOTE_VER=""

  need git || return 1
  need make || return 1

  if [[ ! -f "$HOME/.local/share/blesh/ble.sh" ]]; then
    NEEDS_INSTALL=1
    log "ble.sh not installed"

  elif [[ ! -f "$CHECK_FILE" ]] || [[ -n "$(find "$CHECK_FILE" -mtime +7 2>/dev/null)" ]]; then
    LOCAL_VER="$(git -C "$DIR" rev-parse --short HEAD 2>/dev/null)"

    REMOTE_VER="$(
      curl -fsSL https://api.github.com/repos/akinomyoga/ble.sh/commits/master |
        grep -Po '"sha": "\K[0-9a-f]+' |
        head -n1 |
        cut -c1-7
    )"

    if [[ -n "$REMOTE_VER" && "$LOCAL_VER" != "$REMOTE_VER" ]]; then
      NEEDS_INSTALL=1
      log "ble.sh update available"
    fi

    touch "$CHECK_FILE"
  fi

  if [[ $NEEDS_INSTALL -eq 1 ]]; then
    rm -rf "$DIR"

    git clone --recursive --depth 1 \
      https://github.com/akinomyoga/ble.sh.git "$DIR" \
      >/dev/null 2>&1 || return 1

    make -C "$DIR" install PREFIX="$HOME/.local" \
      >/dev/null 2>&1 || return 1

    touch "$CHECK_FILE"

    log "ble.sh ready"
  fi
}
