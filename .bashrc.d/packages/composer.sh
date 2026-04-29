pkg_composer() {
  local action="$1"
  local BIN="$HOME/.local/bin/composer"
  local CHECK="$HOME/.local/share/bash_setup/checks/composer.check"

  case "$action" in
    install | update)
      ensure_local_dirs
      command -v php >/dev/null 2>&1 || {
        log "PHP required for Composer. Skipping."
        return 1
      }

      local NEEDS_INSTALL=0
      if [[ ! -x "$BIN" ]] || [[ "$action" == "update" ]] || [[ ! -f "$CHECK" ]] || [[ -n "$(find "$CHECK" -mtime +7 2>/dev/null)" ]]; then
        NEEDS_INSTALL=1
      fi

      if [[ $NEEDS_INSTALL -eq 1 ]]; then
        has_internet || {
          log "No internet. Skipping Composer."
          return 0
        }

        local TMP_BIN="/tmp/composer_$RANDOM.phar"
        log "Downloading Composer..."

        if curl -fsSL https://getcomposer.org/installer | php -- --install-dir="/tmp" --filename="$(basename "$TMP_BIN")" >/dev/null 2>&1; then
          mv "$TMP_BIN" "$BIN"
          chmod +x "$BIN"
          touch "$CHECK"
          log "Composer ready"
        else
          return 1
        fi
      fi
      ;;
    remove)
      log "Removing Composer..."
      rm -f "$BIN" "$CHECK"
      log "Composer removed"
      ;;
  esac
}
