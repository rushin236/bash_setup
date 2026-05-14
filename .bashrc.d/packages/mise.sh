#!/usr/bin/env bash

pkg_mise() {
  local action="$1"

  local BIN="$HOME/.local/bin/mise"
  local DATA_DIR="$HOME/.local/share/mise"
  local CONFIG_DIR="$HOME/.config/mise"
  local CHECK="$HOME/.local/share/bash_setup/checks/mise.check"

  case "$action" in
    install | update)
      ensure_local_dirs
      need_any curl wget || return 1

      local NEEDS_INSTALL=0
      local LOCAL_VER=""
      local REMOTE_VER=""

      if [[ ! -x "$BIN" ]]; then
        NEEDS_INSTALL=1

      elif [[ "$action" == "update" ]] ||
        [[ ! -f "$CHECK" ]] ||
        [[ -n "$(find "$CHECK" -mtime +7 2>/dev/null)" ]]; then

        LOCAL_VER="$("$BIN" --version 2>/dev/null | awk '{print $2}')"

        has_internet || {
          touch "$CHECK"
          return 0
        }

        REMOTE_VER="$(
          basename "$(
            curl -fsSLw "%{url_effective}" \
              -o /dev/null \
              "https://github.com/jdx/mise/releases/latest"
          )" | sed 's/^v//'
        )"

        if [[ -n "$REMOTE_VER" && "$LOCAL_VER" != "$REMOTE_VER" ]]; then
          NEEDS_INSTALL=1
          log "mise update available: $LOCAL_VER -> $REMOTE_VER"
        else
          touch "$CHECK"
        fi
      fi

      if [[ $NEEDS_INSTALL -eq 1 ]]; then
        has_internet || {
          log "No internet. Cannot install mise."
          return 0
        }

        log "Installing/Updating mise..."

        if curl -fsSL https://mise.run | sh >/dev/null 2>&1; then
          touch "$CHECK"
          log "mise ready"
        else
          log "Failed to install mise."
          return 1
        fi
      fi
      ;;

    remove)
      log "Removing mise..."

      rm -f "$BIN"
      rm -rf "$DATA_DIR"
      rm -rf "$CONFIG_DIR"
      rm -f "$CHECK"

      log "mise removed"
      ;;

    *)
      echo "Usage: tool pkg {install|update|remove} mise"
      return 1
      ;;
  esac
}
