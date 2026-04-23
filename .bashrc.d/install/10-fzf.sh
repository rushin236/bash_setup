install_or_update_fzf() {

  ensure_local_dirs

  local FZF_DIR="$HOME/.local/opt/fzf"
  local BIN_DIR="$HOME/.local/bin"
  local CHECK_DIR="$HOME/.local/share/bash_setup/checks"
  local CHECK_FILE="$CHECK_DIR/fzf.check"

  local NEEDS_INSTALL=0
  local LOCAL_VER=""
  local REMOTE_TAG=""
  local REMOTE_VER=""

  ensure_local_dirs
  need git || return 1
  need_any curl wget || return 1

  if [[ ! -x "$BIN_DIR/fzf" ]]; then
    NEEDS_INSTALL=1
    log "fzf not installed"
  elif [[ ! -f "$CHECK_FILE" ]] || [[ -n "$(find "$CHECK_FILE" -mtime +7 2>/dev/null)" ]]; then
    LOCAL_VER="$("$BIN_DIR/fzf" --version | awk '{print $1}')"

    REMOTE_TAG="$(curl -fsSL https://api.github.com/repos/junegunn/fzf/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')"
    REMOTE_VER="${REMOTE_TAG#v}"

    if [[ -n "$REMOTE_VER" && "$LOCAL_VER" != "$REMOTE_VER" ]]; then
      NEEDS_INSTALL=1
      log "fzf update available"
    fi

    touch "$CHECK_FILE"
  fi

  if [[ $NEEDS_INSTALL -eq 1 ]]; then
    rm -rf "$FZF_DIR"

    git clone --depth 1 https://github.com/junegunn/fzf.git "$FZF_DIR" >/dev/null 2>&1 || return 1
    "$FZF_DIR/install" --bin --no-update-rc >/dev/null 2>&1 || return 1

    ln -sf "$FZF_DIR/bin/fzf" "$BIN_DIR/fzf"
    touch "$CHECK_FILE"

    log "fzf ready"
  fi
}
