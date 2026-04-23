install_or_update_markdown_toc() {
  export NVM_DIR="$HOME/.nvm"
  [[ -s "$NVM_DIR/nvm.sh" ]] && . "$NVM_DIR/nvm.sh"

  command -v npm >/dev/null 2>&1 || return 0

  if ! command -v markdown-toc >/dev/null 2>&1; then
    log "markdown-toc not installed / updating"
    npm install -g markdown-toc >/dev/null 2>&1 || return 1
  fi

  log "markdown-toc ready"
}
