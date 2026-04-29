pkg_ruby() {
  local action="$1"
  local RBENV="$HOME/.rbenv"
  local CHECK="$HOME/.local/share/bash_setup/checks/ruby.check"

  case "$action" in
    install | update)
      ensure_local_dirs
      need git || return 1

      if [[ ! -d "$RBENV" ]]; then
        has_internet || {
          log "No internet. Skipping rbenv."
          return 0
        }
        log "Installing rbenv..."
        git clone https://github.com/rbenv/rbenv.git "$RBENV" >/dev/null 2>&1 || return 1
        mkdir -p "$RBENV/plugins"
        git clone https://github.com/rbenv/ruby-build.git "$RBENV/plugins/ruby-build" >/dev/null 2>&1 || return 1

        (cd "$RBENV" && src/configure && make -C src) >/dev/null 2>&1 || true

        touch "$CHECK"
        log "rbenv ready (Ruby versions managed via config)"

      elif [[ "$action" == "update" ]] || [[ ! -f "$CHECK" ]] || [[ -n "$(find "$CHECK" -mtime +7 2>/dev/null)" ]]; then
        has_internet || {
          touch "$CHECK"
          return 0
        }
        log "Updating rbenv..."
        (cd "$RBENV" && git pull --rebase) >/dev/null 2>&1
        (cd "$RBENV/plugins/ruby-build" && git pull --rebase) >/dev/null 2>&1
        touch "$CHECK"
      fi
      ;;
    remove)
      log "Removing rbenv and managed Ruby versions..."
      rm -rf "$RBENV" "$CHECK"
      log "Ruby removed"
      ;;
  esac
}
