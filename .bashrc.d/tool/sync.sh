#!/usr/bin/env bash

_install_pkg() {
  local act="$1"
  local name="$2"

  local file="$HOME/.bashrc.d/tool/pkg.sh"

  [[ -f "$file" ]] || {
    log "Package definition not found: $name"
    return 1
  }

  source "$file"

  tool_pkg "$act" "$name"
}

_ensure_tools() {
  local pkg

  for pkg in mise uv; do
    # 1. Check if the tool is missing
    if ! command -v "$pkg" >/dev/null 2>&1; then
      log "Installing $pkg..."
      _install_pkg install "$pkg" || return 1
      _refresh_shell_runtime
    fi

    # 2. Verify installation succeeded
    command -v "$pkg" >/dev/null 2>&1 && log "Tool $pkg installed" || {
      log "Failed to install $pkg"
      return 1
    }
  done
}

_sync_runtime() {
  _ensure_tools || return 1
  _ensure_mise_config || return 1

  local runtime="$1"
  local version=""

  source "$HOME/.bashrc.d/global_source.conf" 2>/dev/null

  case "$runtime" in
    node)
      version="${VERSION_NODE:-24}"
      ;;
    python)
      version="${VERSION_PYTHON:-3.12}"
      ;;
    java)
      version="${VERSION_JAVA:-21}"
      ;;
    ruby)
      version="${VERSION_RUBY:-3.3}"
      ;;
    php)
      version="${VERSION_PHP:-8}"
      ;;
    go)
      version="${VERSION_GO:-1.24}"
      ;;
    rust)
      version="${VERSION_RUST:-stable}"
      ;;
    *)
      log "Unknown runtime: $runtime"
      return 1
      ;;
  esac

  log "Syncing $runtime@$version"

  if mise use -g "${runtime}@${version}"; then
    _refresh_shell_runtime
    log "Sync done for $runtime@$version"
  else
    log "Failed to sync $runtime@$version"
    return 1
  fi
}

_sync_languages() {
  _sync_runtime python || return 1
  _sync_runtime rust || return 1
  _sync_runtime go || return 1
  _sync_runtime java || return 1
  _sync_runtime ruby || return 1
  _sync_runtime node || return 1
  _sync_runtime php || return 1
}

_sync_subpkgs() {
  source "$HOME/.bashrc.d/tool/subpkg.sh"

  tool_sub_pkg npm install all || return 1
  tool_sub_pkg cargo install all || return 1
  tool_sub_pkg go install all || return 1
  tool_sub_pkg rustup install all || return 1
  tool_sub_pkg mise install all || return 1
}

tool_sync() {
  local args=("$@")

  [[ ${#args[@]} -eq 0 ]] && args=("all")

  for item in "${args[@]}"; do
    case "$item" in
      all)
        _sync_languages || return 1
        _sync_subpkgs || return 1
        ;;

      runtimes | mise)
        _sync_languages || return 1
        ;;

      subpkgs)
        _sync_subpkgs || return 1
        ;;

      node | python | java | ruby | php | go | rust)
        _sync_runtime "$item" || return 1
        ;;

      *)
        log "Unknown sync target: $item"
        return 1
        ;;
    esac
  done
}
