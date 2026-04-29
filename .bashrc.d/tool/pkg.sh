#!/usr/bin/env bash

tool_pkg() {
  local action="$1"
  shift # Remove 'install/update/remove' from the argument list

  # local pkg_dir="$HOME/.bashrc.d/packages"

  # Check if at least one target was provided
  if [[ $# -eq 0 ]]; then
    echo "Usage: tool pkg {install|update|remove} <name1> [name2...] [all]"
    return 1
  fi

  # Check if 'all' is among the arguments
  local run_all=0
  for arg in "$@"; do
    if [[ "$arg" == "all" ]]; then
      run_all=1
      break
    fi
  done

  if [[ $run_all -eq 1 ]]; then
    log "Starting global '$action' for all tools..."
    local ordered_pkgs=("nvm" "uv" "rust" "go" "java" "julia" "php" "micromamba" "ruby" "fzf" "starship" "carapace" "blesh" "nvim" "ripgrep" "fd" "shellcheck" "composer")
    for pkg in "${ordered_pkgs[@]}"; do
      _exec_pkg "$pkg" "$action"
    done
  else
    # Process every package name passed in the command line
    for target in "$@"; do
      _exec_pkg "$target" "$action"
    done
  fi
}

_exec_pkg() {
  local name="$1"
  local act="$2"
  local file="$HOME/.bashrc.d/packages/${name}.sh"

  if [[ -f "$file" ]]; then
    (
      # Sourcing is safe here as tool.sh already created the subshell
      source "$file"
      "pkg_${name//-/_}" "$act"
    )
  else
    echo "Error: Package '$name' not found in $HOME/.bashrc.d/packages/"
  fi
}
