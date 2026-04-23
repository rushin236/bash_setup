source_carapace() {
  has carapace || return 0
  source <(carapace _carapace)
}
