pkg_blesh() {
  local action="$1"
  local DIR="$HOME/.local/opt/blesh-src"
  local SHARE_DIR="$HOME/.local/share/blesh"
  local CHECK="$HOME/.local/share/bash_setup/checks/blesh.check"

  case "$action" in
    install | update)
      ensure_local_dirs
      need git || return 1
      need make || return 1

      local NEEDS_INSTALL=0
      local LOCAL_VER=""
      local REMOTE_VER=""

      if [[ ! -f "$SHARE_DIR/ble.sh" ]] || [[ ! -d "$DIR" ]]; then
        NEEDS_INSTALL=1
      elif [[ "$action" == "update" ]] || [[ ! -f "$CHECK" ]] || [[ -n "$(find "$CHECK" -mtime +7 2>/dev/null)" ]]; then
        LOCAL_VER="$(git -C "$DIR" rev-parse --short HEAD 2>/dev/null)"

        has_internet || {
          touch "$CHECK"
          return 0
        }

        # API Bypass: Fetch latest commit hash directly via git
        REMOTE_VER="$(git ls-remote https://github.com/akinomyoga/ble.sh.git HEAD | awk '{print substr($1,1,7)}')"

        if [[ -n "$REMOTE_VER" && "$LOCAL_VER" != "$REMOTE_VER" ]]; then
          NEEDS_INSTALL=1
          log "ble.sh update available"
        else
          touch "$CHECK"
        fi
      fi

      if [[ $NEEDS_INSTALL -eq 1 ]]; then
        has_internet || return 0
        log "Installing/Updating ble.sh..."

        if [[ ! -d "$DIR/.git" ]]; then
          rm -rf "$DIR"
          git clone --recursive --depth 1 https://github.com/akinomyoga/ble.sh.git "$DIR" >/dev/null 2>&1 || return 1
        else
          (cd "$DIR" && git pull --rebase && git submodule update --init --recursive) >/dev/null 2>&1 || return 1
        fi

        make -C "$DIR" install PREFIX="$HOME/.local" >/dev/null 2>&1 || return 1

        touch "$CHECK"
        log "ble.sh ready"
      fi
      ;;

    remove)
      log "Removing ble.sh..."
      rm -rf "$DIR" "$SHARE_DIR" "$CHECK"
      log "ble.sh removed"
      ;;
  esac
}
