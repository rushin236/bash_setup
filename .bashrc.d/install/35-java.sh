install_or_update_java() {
  ensure_local_dirs

  local DIR="$HOME/.local/opt/java"
  local CHECK="$HOME/.local/share/bash_setup/checks/java.check"

  local ARCH="$(detect_arch)"
  local API_ARCH=""

  case "$ARCH" in
    amd64) API_ARCH="x64" ;;
    arm64) API_ARCH="aarch64" ;;
    *) return 1 ;;
  esac

  local URL="https://api.adoptium.net/v3/binary/latest/21/ga/linux/${API_ARCH}/jdk/hotspot/normal/eclipse"

  if [[ ! -x "$DIR/bin/java" ]] ||
    [[ ! -f "$CHECK" ]] ||
    [[ -n "$(find "$CHECK" -mtime +7 2>/dev/null)" ]]; then

    log "Java not installed / updating"

    rm -rf "$DIR"
    mkdir -p "$DIR"

    curl -fsSL "$URL" | tar -xzf - --strip-components=1 -C "$DIR" || return 1

    ln -sf "$DIR/bin/java" "$HOME/.local/bin/java"
    ln -sf "$DIR/bin/javac" "$HOME/.local/bin/javac"

    touch "$CHECK"
    log "Java ready"
  fi
}
