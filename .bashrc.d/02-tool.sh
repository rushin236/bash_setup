tool() {
  local cmd="$1"
  shift

  case "$cmd" in
    pkg)
      source "$HOME/.bashrc.d/tool/pkg.sh"
      tool_pkg "$@"
      _refresh_shell_runtime
      ;;
    subpkg)
      source "$HOME/.bashrc.d/tool/subpkg.sh"
      tool_sub_pkg "$@"
      _refresh_shell_runtime
      ;;
    sync)
      source "$HOME/.bashrc.d/tool/sync.sh"
      tool_sync "$@"
      _refresh_shell_runtime
      ;;
    sys)
      source "$HOME/.bashrc.d/tool/sys.sh"
      tool_sys "$@"
      _refresh_shell_runtime
      ;;
    list | "")
      source "$HOME/.bashrc.d/tool/list.sh"
      tool_list
      ;;
  esac
}
