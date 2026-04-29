pkg_fzf() {
  local action="$1"
  local DIR="$HOME/.local/opt/fzf"
  local BIN="$HOME/.local/bin/fzf"
  local CHECK="$HOME/.local/share/bash_setup/checks/fzf.check"

  case "$action" in
    install | update)
      ensure_local_dirs
      need git || return 1

      local NEEDS_INSTALL=0
      local LOCAL_VER=""
      local REMOTE_VER=""

      if [[ ! -x "$BIN" ]] || [[ ! -d "$DIR" ]]; then
        NEEDS_INSTALL=1
      elif [[ "$action" == "update" ]] || [[ ! -f "$CHECK" ]] || [[ -n "$(find "$CHECK" -mtime +7 2>/dev/null)" ]]; then
        LOCAL_VER="$("$BIN" --version | awk '{print $1}')"
        has_internet || {
          touch "$CHECK"
          return 0
        }

        # API Bypass
        REMOTE_VER="$(basename "$(curl -fsSLw "%{url_effective}" -o /dev/null "https://github.com/junegunn/fzf/releases/latest")" | sed 's/^v//')"

        if [[ -n "$REMOTE_VER" && "$LOCAL_VER" != "$REMOTE_VER" ]]; then
          NEEDS_INSTALL=1
          log "fzf update available: $LOCAL_VER -> $REMOTE_VER"
        else
          touch "$CHECK"
        fi
      fi

      if [[ $NEEDS_INSTALL -eq 1 ]]; then
        has_internet || return 0
        log "Installing/Updating fzf..."

        if [[ ! -d "$DIR/.git" ]]; then
          rm -rf "$DIR"
          git clone --depth 1 https://github.com/junegunn/fzf.git "$DIR" >/dev/null 2>&1 || return 1
        else
          (cd "$DIR" && git pull --rebase) >/dev/null 2>&1 || return 1
        fi

        "$DIR/install" --bin --no-update-rc >/dev/null 2>&1 || return 1
        ln -sf "$DIR/bin/fzf" "$BIN"

        touch "$CHECK"
        log "fzf ready"
      fi
      ;;
    remove)
      log "Removing fzf..."
      rm -rf "$DIR" "$BIN" "$CHECK"
      log "fzf removed"
      ;;
  esac
}
