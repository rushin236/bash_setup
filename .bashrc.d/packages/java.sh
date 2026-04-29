pkg_java() {
  local action="$1"
  local SDK_DIR="$HOME/.sdkman"
  local CHECK="$HOME/.local/share/bash_setup/checks/java.check"

  case "$action" in
    install | update)
      ensure_local_dirs
      need_any curl wget || return 1
      need unzip || return 1
      need zip || return 1

      local NEEDS_INSTALL=0

      if [[ ! -s "$SDK_DIR/bin/sdkman-init.sh" ]]; then
        NEEDS_INSTALL=1
        log "SDKMAN! not installed"
      elif [[ "$action" == "update" ]] || [[ ! -f "$CHECK" ]] || [[ -n "$(find "$CHECK" -mtime +7 2>/dev/null)" ]]; then
        has_internet || {
          touch "$CHECK"
          return 0
        }

        export SDKMAN_DIR="$SDK_DIR"
        source "$SDK_DIR/bin/sdkman-init.sh"

        log "Checking for SDKMAN! updates..."
        sdk selfupdate force >/dev/null 2>&1
        touch "$CHECK"
      fi

      if [[ $NEEDS_INSTALL -eq 1 ]]; then
        has_internet || {
          log "No internet. Cannot install SDKMAN!."
          return 0
        }
        log "Installing SDKMAN!..."

        export SDKMAN_DIR="$SDK_DIR"
        curl -s "https://get.sdkman.io?rcupdate=false" | bash >/dev/null 2>&1 || return 1

        touch "$CHECK"
        log "SDKMAN! ready (Java versions will be managed via config)"
      fi
      ;;

    remove)
      log "Removing SDKMAN! and all managed Java versions..."
      rm -rf "$SDK_DIR" "$CHECK"
      log "SDKMAN! removed"
      ;;
  esac
}
