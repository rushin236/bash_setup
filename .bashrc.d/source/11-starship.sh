source_starship() {
  has starship || return 0

  local CACHE="$HOME/.cache/bash_setup/starship.bash"

  mkdir -p "$HOME/.cache/bash_setup"

  if [[ ! -s "$CACHE" ]] || [[ "$(command -v starship)" -nt "$CACHE" ]]; then
    starship init bash >"$CACHE"
  fi

  source "$CACHE"
}
