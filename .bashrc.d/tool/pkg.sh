#!/usr/bin/env bash

tool_pkg() {
  local action="$1"
  local arg pkg target run_all=0 # <-- THE FIX: Declare all loop iterators locally here

  shift # Remove 'install/update/remove' from the argument list

  # Check if at least one target was provided
  if [[ $# -eq 0 ]]; then
    echo "Usage: tool pkg {install|update|remove} <name1> [name2...] [all]"
    return 1
  fi

  # Check if 'all' is among the arguments
  for arg in "$@"; do
    if [[ "$arg" == "all" ]]; then
      run_all=1
      break
    fi
  done

  if [[ $run_all -eq 1 ]]; then
    log "Starting global '$action' for all tools..."
    local ordered_pkgs=("mise" "uv" "julia" "fzf" "starship" "carapace" "blesh" "nvim" "ripgrep" "fd")

    for pkg in "${ordered_pkgs[@]}"; do
      _exec_pkg "$pkg" "$action" || return 1
    done
  else
    # Process every package name passed in the command line
    for target in "$@"; do
      _exec_pkg "$target" "$action" || return 1
    done
  fi
}

_exec_pkg() {
  local name="$1"
  local act="$2"
  local file="$HOME/.bashrc.d/packages/${name}.sh"

  if [[ -f "$file" ]]; then
    # Sourcing is safe here as tool.sh already created the subshell
    source "$file"
    "pkg_${name//-/_}" "$act"
  else
    echo "Error: Package '$name' not found in $HOME/.bashrc.d/packages/"
    return 1
  fi
}
