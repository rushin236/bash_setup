pkg_nvm() {
  local action="$1"
  local NVM_DIR="$HOME/.nvm"
  local CHECK="$HOME/.local/share/bash_setup/checks/nvm.check"

  case "$action" in
    install | update)
      ensure_local_dirs
      need git || return 1
      need_any curl wget || return 1

      local NEEDS_INSTALL=0
      local LOCAL_VER=""
      local REMOTE_TAG=""
      local REMOTE_VER=""

      if [[ ! -d "$NVM_DIR" ]]; then
        NEEDS_INSTALL=1
      elif [[ "$action" == "update" ]] || [[ ! -f "$CHECK" ]] || [[ -n "$(find "$CHECK" -mtime +7 2>/dev/null)" ]]; then
        . "$NVM_DIR/nvm.sh"
        LOCAL_VER="$(nvm --version 2>/dev/null)"

        has_internet || {
          touch "$CHECK"
          return 0
        }

        # API Bypass
        REMOTE_TAG="$(basename "$(curl -fsSLw "%{url_effective}" -o /dev/null "https://github.com/nvm-sh/nvm/releases/latest")")"
        REMOTE_VER="${REMOTE_TAG#v}"

        if [[ -n "$REMOTE_VER" && "$LOCAL_VER" != "$REMOTE_VER" ]]; then
          NEEDS_INSTALL=1
          log "NVM update available: $LOCAL_VER -> $REMOTE_VER"
        else
          touch "$CHECK"
        fi
      fi

      if [[ $NEEDS_INSTALL -eq 1 ]]; then
        has_internet || return 0
        [[ -z "$REMOTE_TAG" ]] && REMOTE_TAG="$(basename "$(curl -fsSLw "%{url_effective}" -o /dev/null "https://github.com/nvm-sh/nvm/releases/latest")")"

        if [[ -z "$REMOTE_TAG" ]]; then
          log "Failed to fetch NVM version. Skipping NVM update."
          return 1
        fi

        log "Fetching NVM version $REMOTE_TAG..."

        if [[ ! -d "$NVM_DIR" ]]; then
          git clone --depth 1 --branch "$REMOTE_TAG" https://github.com/nvm-sh/nvm.git "$NVM_DIR" >/dev/null 2>&1 || return 1
        else
          (
            cd "$NVM_DIR" || exit 1
            git fetch origin tag "$REMOTE_TAG" --no-tags --depth 1 >/dev/null 2>&1 || exit 1
            git checkout "$REMOTE_TAG" -q >/dev/null 2>&1 || exit 1
          ) || return 1
        fi

        touch "$CHECK"
        log "NVM ready"
      fi
      ;;

    remove)
      log "Removing NVM and all installed Node versions..."
      rm -rf "$NVM_DIR" "$CHECK"
      log "NVM removed"
      ;;
  esac
}
