pkg_php() {
  local action="$1"
  local BIN="$HOME/.local/bin/phpbrew"
  local PHPBREW_ROOT="$HOME/.phpbrew"
  local CHECK="$HOME/.local/share/bash_setup/checks/phpbrew.check"

  case "$action" in
    install | update)
      ensure_local_dirs
      need_any curl wget || return 1

      command -v php >/dev/null 2>&1 || {
        log "System PHP required to bootstrap phpbrew. Skipping."
        return 1
      }

      local NEEDS_INSTALL=0

      if [[ ! -x "$BIN" ]] || [[ ! -d "$PHPBREW_ROOT" ]]; then
        NEEDS_INSTALL=1
      elif [[ "$action" == "update" ]] || [[ ! -f "$CHECK" ]] || [[ -n "$(find "$CHECK" -mtime +7 2>/dev/null)" ]]; then
        has_internet || {
          touch "$CHECK"
          return 0
        }

        log "Checking for phpbrew updates..."
        "$BIN" self-update >/dev/null 2>&1 || true
        touch "$CHECK"
      fi

      if [[ $NEEDS_INSTALL -eq 1 ]]; then
        has_internet || {
          log "No internet. Cannot install phpbrew."
          return 0
        }
        log "Installing phpbrew..."

        local TMP_BIN="/tmp/phpbrew_$RANDOM.phar"
        local URL="https://github.com/phpbrew/phpbrew/releases/latest/download/phpbrew.phar"

        if curl -fsSL "$URL" -o "$TMP_BIN" 2>/dev/null; then
          mv "$TMP_BIN" "$BIN"
          chmod +x "$BIN"

          export PHPBREW_ROOT="$PHPBREW_ROOT"
          "$BIN" init >/dev/null 2>&1

          touch "$CHECK"
          log "phpbrew ready (PHP versions managed via config)"
        else
          log "Failed to download phpbrew."
          rm -f "$TMP_BIN"
          return 1
        fi
      fi
      ;;

    remove)
      log "Removing phpbrew and managed PHP versions..."
      rm -rf "$PHPBREW_ROOT" "$BIN" "$CHECK"
      log "phpbrew removed"
      ;;
  esac
}
