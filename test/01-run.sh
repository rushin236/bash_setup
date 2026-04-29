run() {
  distro="$1"
  arch="$2"

  case "$arch" in
    amd64 | arm64)
      (
        # Source and run in a subshell for auto-cleanup
        [[ -f "./test/podman-run-${distro}.sh" ]] && . "./test/podman-run-${distro}.sh"
        target_fun="run_${distro}_${arch}"
        if declare -f "$target_fun" >/dev/null; then
          "$target_fun"
        else
          echo "Error: Function $target_fun not found."
        fi
      )
      ;;
    all)
      for each in amd64 arm64; do
        (
          [[ -f "./test/podman-run-${distro}.sh" ]] && . "./test/podman-run-${distro}.sh"
          target_fun="run_${distro}_${each}"
          declare -f "$target_fun" >/dev/null && "$target_fun"
        )
      done
      ;;
    *)
      echo "Usage: test run {distro amd64|arm64|all}"
      ;;
  esac
}
