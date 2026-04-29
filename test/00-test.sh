test() {
  echo "$@"
  cmd="$1"
  shift

  case "$cmd" in
    run)
      # Wrap the entire execution in a subshell
      (
        source ./test/01-run.sh
        run "$@"
      )
      ;;
    shell)
      # Wrap the entire execution in a subshell
      (
        source ./test/02-shell.sh
        shell "$@"
      )
      ;;
    *)
      echo "Invalid command: $cmd"
      echo "Usage: test run {distro arch|all} or Usage: test shell {distro cpu-arch}"
      ;;
  esac
}
