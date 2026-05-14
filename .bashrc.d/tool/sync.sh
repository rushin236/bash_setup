#!/usr/bin/env bash

_run_pkg() {
  local name="$1"
  local act="$2"

  local file="$HOME/.bashrc.d/packages/${name}.sh"

  [[ -f "$file" ]] || {
    log "Package definition not found: $name"
    return 1
  }

  source "$file"

  "pkg_${name//-/_}" "$act"
}

_ensure_tools() {
  if ! command -v mise >/dev/null 2>&1; then
    log "Installing mise..."
    _run_pkg mise install || return 1
    _refresh_shell_runtime
  fi

  if ! command -v uv >/dev/null 2>&1; then
    log "Installing uv..."
    _run_pkg uv install || return 1
    _refresh_shell_runtime
  fi

  command -v mise >/dev/null 2>&1 || {
    log "Failed to install mise"
    return 1
  }

  command -v uv >/dev/null 2>&1 || {
    log "Failed to install uv"
    return 1
  }
}

_ensure_mise_settings() {
  local ruby_compile

  ruby_compile="$(mise settings get ruby.compile 2>/dev/null)"

  if [[ "$ruby_compile" != "false" ]]; then
    mise settings set ruby.compile false
  fi

  if ! mise plugin ls 2>/dev/null | grep -qx php; then
    mise plugin install php https://github.com/verzly/mise-php#latest
  fi
}

_sync_runtime() {
  _ensure_tools || return 1
  _ensure_mise_settings || return 1

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
