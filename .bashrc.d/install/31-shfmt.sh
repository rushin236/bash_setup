install_or_update_shfmt() {
  [[ -f "$HOME/.local/share/bash_setup/checks/go.check" ]] || return 0

  export PATH="$HOME/.local/opt/go/bin:$PATH"

  command -v go >/dev/null 2>&1 || return 0

  if ! command -v shfmt >/dev/null 2>&1; then
    log "shfmt not installed / updating"
    GOPATH="$HOME/.local/share/go" \
      go install mvdan.cc/sh/v3/cmd/shfmt@latest >/dev/null 2>&1 || return 1

    ln -sf "$HOME/.local/share/go/bin/shfmt" "$HOME/.local/bin/shfmt"
  fi

  log "shfmt ready"
}
