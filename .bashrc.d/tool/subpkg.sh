#!/usr/bin/env bash

_sync_runtime_tool() {
  source "$HOME/.bashrc.d/tool/sync.sh"

  _sync_runtime "$1" || return 1

  _refresh_shell_runtime
}

_ensure_manager() {
  local manager="$1"

  case "$manager" in
    npm)
      command -v npm >/dev/null 2>&1 && return 0

      log "'npm' missing. Installing required runtime..."
      _sync_runtime_tool node || return 1
      ;;

    cargo | rustup)
      command -v cargo >/dev/null 2>&1 && return 0

      log "'cargo/rustup' missing. Installing required runtime..."
      _sync_runtime_tool rust || return 1
      ;;

    go)
      command -v go >/dev/null 2>&1 && return 0

      log "'go' missing. Installing required runtime..."
      _sync_runtime_tool go || return 1
      ;;

    mise)
      command -v mise >/dev/null 2>&1 && return 0

      log "'mise' missing. Installing required runtime tools..."
      source "$HOME/.bashrc.d/tool/sync.sh"

      _ensure_tools || return 1
      ;;

    *)
      log "Unsupported manager: $manager"
      return 1
      ;;
  esac

  _refresh_shell_runtime

  case "$manager" in
    npm)
      command -v npm >/dev/null 2>&1
      ;;
    cargo | rustup)
      command -v cargo >/dev/null 2>&1
      ;;
    go)
      command -v go >/dev/null 2>&1
      ;;
    mise)
      command -v mise >/dev/null 2>&1
      ;;
  esac || {
    log "Failed to provision '$manager'"
    return 1
  }
}

_get_packages() {
  local manager="$1"
  local conf_file="$HOME/.bashrc.d/global_tools.conf"

  [[ -f "$conf_file" ]] || {
    log "No config file found."
    return 1
  }

  awk -v mgr="$manager" '
    BEGIN { in_section=0 }

    {
      line = $0

      gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)

      if (line == "") next
      if (line ~ /^#/) next

      if (line ~ /^\[.*\]$/) {
        in_section = (line == "[" mgr "]")
        next
      }

      if (in_section) {
        sub(/[[:space:]]+#.*$/, "", line)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)

        if (line != "")
          print line
      }
    }
  ' "$conf_file"
}

tool_sub_pkg() {
  local manager="$1"
  local action="$2"
  local target="$3"

  [[ -z "$manager" || -z "$action" || -z "$target" ]] && {
    echo "Usage: tool subpkg {npm|cargo|rustup|go|mise} {install|remove} <name|all>"
    return 1
  }

  _ensure_manager "$manager" || return 1

  local pkgs_to_process=""

  if [[ "$target" == "all" ]]; then
    pkgs_to_process="$(_get_packages "$manager")"
  else
    pkgs_to_process="$target"
  fi

  [[ -z "${pkgs_to_process// /}" ]] && {
    log "No packages defined for $manager."
    return 0
  }

  log "$action-ing $manager sub-packages: $pkgs_to_process"

  case "$manager" in
    npm)
      if [[ "$action" == "remove" ]]; then
        npm uninstall -g $pkgs_to_process
      else
        npm install -g $pkgs_to_process
      fi
      ;;

    cargo)
      if [[ "$action" == "remove" ]]; then
        cargo uninstall $pkgs_to_process
      else
        cargo install $pkgs_to_process
      fi
      ;;

    rustup)
      if [[ "$action" == "remove" ]]; then
        rustup component remove $pkgs_to_process
      else
        rustup component add $pkgs_to_process
      fi
      ;;

    go)
      for p in $pkgs_to_process; do
        if [[ "$action" == "remove" ]]; then
          rm -f "$HOME/.local/share/go/bin/$(basename "$p" | cut -d@ -f1)"
        else
          GOPATH="$HOME/.local/share/go" go install "$p"
        fi
      done
      ;;

    mise)
      for p in $pkgs_to_process; do
        if [[ "$action" == "remove" ]]; then
          mise uninstall "$p"
        else
          mise use -g "$p"
        fi

        _refresh_shell_runtime
      done
      ;;
  esac

  _refresh_shell_runtime
}
