pkg_julia() {
  local action="$1"
  local DIR="$HOME/.local/opt/julia"
  local BIN="$HOME/.local/bin/julia"
  local CHECK="$HOME/.local/share/bash_setup/checks/julia.check"

  case "$action" in
    install | update)
      ensure_local_dirs
      local ARCH="$(detect_arch)"
      local API_ARCH=""
      local DL_ARCH=""

      case "$ARCH" in
        amd64)
          API_ARCH="x64"
          DL_ARCH="x86_64"
          ;;
        arm64)
          API_ARCH="aarch64"
          DL_ARCH="aarch64"
          ;;
        *) return 1 ;;
      esac

      local NEEDS_INSTALL=0
      local LOCAL_VER=""
      local REMOTE_VER=""

      if [[ ! -x "$BIN" ]]; then
        NEEDS_INSTALL=1
      elif [[ "$action" == "update" ]] || [[ ! -f "$CHECK" ]] || [[ -n "$(find "$CHECK" -mtime +14 2>/dev/null)" ]]; then
        LOCAL_VER="$("$BIN" --version | awk '{print $3}')"

        has_internet || {
          touch "$CHECK"
          return 0
        }

        # API Bypass
        REMOTE_VER="$(basename "$(curl -fsSLw "%{url_effective}" -o /dev/null "https://github.com/JuliaLang/julia/releases/latest")" | sed 's/^v//')"

        if [[ -n "$REMOTE_VER" && "$LOCAL_VER" != "$REMOTE_VER" ]]; then
          NEEDS_INSTALL=1
          log "Julia update available: $LOCAL_VER -> $REMOTE_VER"
        else
          touch "$CHECK"
        fi
      fi

      if [[ $NEEDS_INSTALL -eq 1 ]]; then
        has_internet || return 0
        [[ -z "$REMOTE_VER" ]] && REMOTE_VER="$(basename "$(curl -fsSLw "%{url_effective}" -o /dev/null "https://github.com/JuliaLang/julia/releases/latest")" | sed 's/^v//')"

        if [[ -z "$REMOTE_VER" ]]; then
          log "Failed to fetch Julia version. Skipping update."
          return 1
        fi

        local MINOR_VER="${REMOTE_VER%.*}"
        local FILE="julia-${REMOTE_VER}-linux-${DL_ARCH}.tar.gz"
        local URL="https://julialang-s3.julialang.org/bin/linux/${API_ARCH}/${MINOR_VER}/$FILE"
        local TMP_DIR="/tmp/julia_update_$RANDOM"

        mkdir -p "$TMP_DIR"
        log "Downloading Julia $REMOTE_VER..."

        if curl -fsSL "$URL" | tar -xzf - -C "$TMP_DIR" --strip-components=1 2>/dev/null; then
          rm -rf "$DIR"
          mv "$TMP_DIR" "$DIR"
          ln -sf "$DIR/bin/julia" "$BIN"

          touch "$CHECK"
          log "Julia ready"
        else
          log "Failed to download Julia. Current version retained."
          rm -rf "$TMP_DIR"
          return 1
        fi
      fi
      ;;

    remove)
      log "Removing Julia..."
      rm -rf "$DIR" "$BIN" "$CHECK"
      log "Julia removed"
      ;;
  esac
}
