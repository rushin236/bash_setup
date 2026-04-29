#!/usr/bin/env bash

tool_sub_pkg() {
  local manager="$1"
  local action="$2"
  local target="$3"
  local conf_file="$HOME/.bashrc.d/global_tools.conf"

  [[ -z "$manager" || -z "$action" || -z "$target" ]] && {
    echo "Usage: tool sub-pkg {npm|cargo|rustup|go} {install|update|remove} <name|all>"
    return 1
  }

  # Guard: Check if manager exists
  if ! command -v "$manager" >/dev/null 2>&1; then
    log "Error: '$manager' not found on system."
    return 1
  fi

  local pkgs_to_process=""

  if [[ "$target" == "all" ]]; then
    [[ ! -f "$conf_file" ]] && {
      echo "No config file found."
      return 1
    }
    pkgs_to_process="$(
      awk -v mgr="$manager" '
        BEGIN { in_section=0 }

        {
          line = $0

          # remove leading/trailing whitespace
          gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)

          # skip empty lines
          if (line == "") next

          # skip full-line comments
          if (line ~ /^#/) next

          # section headers
          if (line ~ /^\[.*\]$/) {
            in_section = (line == "[" mgr "]")
            next
          }

          # inside section: strip inline comments
          if (in_section) {
            sub(/[[:space:]]+#.*$/, "", line)
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)

            if (line != "")
              print line
          }
        }
      ' "$conf_file"
    )"
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
      [[ "$action" == "remove" ]] && npm uninstall -g $pkgs_to_process || npm install -g $pkgs_to_process
      ;;
    cargo)
      [[ "$action" == "remove" ]] && cargo uninstall $pkgs_to_process || cargo install $pkgs_to_process
      ;;
    rustup)
      [[ "$action" == "remove" ]] && rustup component remove $pkgs_to_process || rustup component add $pkgs_to_process
      ;;
    go)
      for p in $pkgs_to_process; do
        if [[ "$action" == "remove" ]]; then
          rm -f "$HOME/.local/share/go/bin/$(basename "$p" | cut -d@ -f1)"
        else
          GOPATH="$HOME/.local/share/go" go install "$p" >/dev/null 2>&1
        fi
      done
      ;;
  esac
}
