install_or_update_nvm() {
  ensure_local_dirs

  local NVM_DIR="$HOME/.nvm"
  local CHECK_DIR="$HOME/.local/share/bash_setup/checks"
  local CHECK_FILE="$CHECK_DIR/nvm.check"

  local NEEDS_INSTALL=0
  local LOCAL_VER=""
  local REMOTE_TAG=""
  local REMOTE_VER=""

  need git || return 1
  need_any curl wget || return 1

  # 1. Version Check Phase
  if [[ ! -d "$NVM_DIR" ]]; then
    NEEDS_INSTALL=1
    log "NVM not installed"
  elif [[ ! -f "$CHECK_FILE" ]] || [[ -n "$(find "$CHECK_FILE" -mtime +7 2>/dev/null)" ]]; then

    # Safely source to check current version
    . "$NVM_DIR/nvm.sh"
    LOCAL_VER="$(nvm --version 2>/dev/null)"

    # Fetch latest tag from GitHub API
    REMOTE_TAG="$(curl -fsSL https://api.github.com/repos/nvm-sh/nvm/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')"
    REMOTE_VER="${REMOTE_TAG#v}"

    if [[ -n "$REMOTE_VER" && "$LOCAL_VER" != "$REMOTE_VER" ]]; then
      NEEDS_INSTALL=1
      log "NVM update available: $LOCAL_VER -> $REMOTE_VER"
    else
      # We checked, and it's up to date. Touch the file to sleep for another 7 days.
      touch "$CHECK_FILE"
      return 0
    fi
  else
    # Installed and checked recently. Exit early to keep shell startup fast.
    return 0
  fi

  # 2. Install / Update Phase
  if [[ $NEEDS_INSTALL -eq 1 ]]; then

    # Fetch tag if it wasn't fetched in the block above (e.g., during a fresh install)
    if [[ -z "$REMOTE_TAG" ]]; then
      REMOTE_TAG="$(curl -fsSL https://api.github.com/repos/nvm-sh/nvm/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')"
    fi

    log "Fetching NVM version $REMOTE_TAG..."

    if [[ ! -d "$NVM_DIR" ]]; then
      # Fresh install: Fast shallow clone of the exact tag
      git clone --depth 1 --branch "$REMOTE_TAG" https://github.com/nvm-sh/nvm.git "$NVM_DIR" >/dev/null 2>&1 || return 1
    else
      # In-place update: Fetch only the new script files, protecting your Node binaries
      (
        cd "$NVM_DIR" >/dev/null 2>&1 || exit 1
        git fetch origin tag "$REMOTE_TAG" --no-tags --depth 1 >/dev/null 2>&1 || exit 1
        git checkout "$REMOTE_TAG" -q >/dev/null 2>&1 || exit 1
      ) || return 1
    fi

    # Load the fresh environment
    export NVM_DIR="$NVM_DIR"
    . "$NVM_DIR/nvm.sh"

    # Ensure Node LTS is installed (This is safe to run even on updates)
    log "Ensuring Node LTS is installed..."
    nvm install --lts >/dev/null 2>&1 || return 1
    nvm use --lts >/dev/null 2>&1 || return 1

    touch "$CHECK_FILE"
    log "NVM ready"
  fi
}
