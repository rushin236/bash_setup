tool() {
  local cmd="$1"
  shift

  case "$cmd" in
    pkg)
      (
        source ~/.bashrc.d/tool/pkg.sh
        tool_pkg "$@"
      )
      ;;
    sub-pkg)
      (
        source ~/.bashrc.d/tool/sub-pkg.sh
        tool_sub_pkg "$@"
      )
      ;;
    sync)
      (
        source ~/.bashrc.d/tool/sync.sh
        tool_sync "$@"
      )
      ;;
    sys)
      (
        source ~/.bashrc.d/tool/sys.sh
        tool_sys "$@"
      )
      ;;
    list | "")
      (
        source ~/.bashrc.d/tool/list.sh
        tool_list
      )
      ;;
  esac

  source "${HOME}/.bashrc"
}
