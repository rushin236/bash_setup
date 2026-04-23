install_or_update_starship() {

  ensure_local_dirs

  local BIN="$HOME/.local/bin/starship"
  local CHECK_DIR="$HOME/.local/share/bash_setup/checks"
  local CHECK_FILE="$CHECK_DIR/starship.check"

  local NEEDS_INSTALL=0
  local LOCAL_VER=""
  local REMOTE_VER=""

  ensure_local_dirs
  need_any curl wget || return 1

  if [[ ! -x "$BIN" ]]; then
    NEEDS_INSTALL=1
    log "Starship not installed"

  elif [[ ! -f "$CHECK_FILE" ]] || [[ -n "$(find "$CHECK_FILE" -mtime +7 2>/dev/null)" ]]; then
    LOCAL_VER="$("$BIN" --version | awk '{print $2}' | sed 's/^v//')"

    REMOTE_VER="$(curl -fsSL https://api.github.com/repos/starship/starship/releases/latest |
      grep -Po '"tag_name": "\K.*?(?=")' | sed 's/^v//')"

    if [[ -n "$REMOTE_VER" && "$LOCAL_VER" != "$REMOTE_VER" ]]; then
      NEEDS_INSTALL=1
      log "Starship update available: $LOCAL_VER -> $REMOTE_VER"
    fi

    touch "$CHECK_FILE"
  fi

  if [[ $NEEDS_INSTALL -eq 1 ]]; then
    curl -fsSL https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin" >/dev/null 2>&1

    # Generate preset BEFORE initializing if it's missing
    if [ ! -f ~/.config/starship.toml ]; then
      mkdir -p ~/.config
      starship preset plain-text-symbols -o ~/.config/starship.toml
    fi

    touch "$CHECK_FILE"
    log "Starship ready"
  fi
}
