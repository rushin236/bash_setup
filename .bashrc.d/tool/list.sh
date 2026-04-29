#!/usr/bin/env bash

tool_list() {
  local pkg_dir="$HOME/.bashrc.d/packages"

  echo "Available Primary Packages:"

  # Check if directory exists and has files
  if [[ -d "$pkg_dir" ]]; then
    for pkg in "$pkg_dir"/*.sh; do
      [[ -f "$pkg" ]] || continue
      # Print the filename without the .sh extension
      basename "$pkg" .sh | awk '{print "  - " $0}'
    done
  else
    echo "  (No packages directory found)"
  fi

  echo ""
  echo "To install sub-packages (formatters/linters), edit:"
  echo "  ~/.bashrc.d/global_tools.conf"
}
