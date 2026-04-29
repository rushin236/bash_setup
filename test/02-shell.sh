shell() {
  distro="$1"
  arch="$2"

  case "$arch" in
    amd64 | arm64)
      (
        [[ -f "./test/podman-shell-${distro}.sh" ]] && . "./test/podman-shell-${distro}.sh"
        target_fun="shell_${distro}_${arch}"
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
