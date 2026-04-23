source_fzf() {
  has fzf || return 0
  source <(fzf --bash)
}
