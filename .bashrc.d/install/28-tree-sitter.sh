install_or_update_tree_sitter() {
  export NVM_DIR="$HOME/.nvm"

  [[ -s "$NVM_DIR/nvm.sh" ]] && . "$NVM_DIR/nvm.sh"

  command -v npm >/dev/null 2>&1 || return 0

  if ! command -v tree-sitter >/dev/null 2>&1; then
    log "tree-sitter not installed / updating"
    npm install -g tree-sitter-cli >/dev/null 2>&1 || return 1
    log "tree-sitter ready"
  fi
}
