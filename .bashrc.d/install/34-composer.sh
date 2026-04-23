install_or_update_composer() {
  command -v php >/dev/null 2>&1 || return 0

  if ! command -v composer >/dev/null 2>&1; then
    log "Composer not installed / updating"

    curl -fsSL https://getcomposer.org/installer |
      php -- --install-dir="$HOME/.local/bin" --filename=composer \
        >/dev/null 2>&1 || return 1
  fi

  log "Composer ready"
}
