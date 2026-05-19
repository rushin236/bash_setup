blank_shell() {
  distro="$1"
  arch="$2"

  case "$arch" in
    amd64 | arm64)
      (
        [[ -f "./test/podman-blank-shell-${distro}.sh" ]] && . "./test/podman-blank-shell-${distro}.sh"
        target_fun="blank_shell_${distro}_${arch}"
        if declare -f "$target_fun" >/dev/null; then
          "$target_fun"
        else
          echo "Error: Function $target_fun not found."
        fi
      )
      ;;
    *)
      echo "Usage: test shell {distro amd64|arm64}"
      ;;
  esac
}
