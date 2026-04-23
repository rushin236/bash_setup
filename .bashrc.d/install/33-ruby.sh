install_or_update_ruby() {
  ensure_local_dirs

  local RBENV="$HOME/.rbenv"
  local CHECK="$HOME/.local/share/bash_setup/checks/ruby.check"

  need git || return 1
  need make || return 1
  need gcc || return 1

  export PATH="$RBENV/bin:$PATH"

  if [[ ! -d "$RBENV" ]]; then
    git clone https://github.com/rbenv/rbenv.git "$RBENV" >/dev/null 2>&1 || return 1
    mkdir -p "$RBENV/plugins"

    git clone https://github.com/rbenv/ruby-build.git \
      "$RBENV/plugins/ruby-build" >/dev/null 2>&1 || return 1
  fi

  eval "$("$RBENV/bin/rbenv" init - bash)"

  if ! command -v ruby >/dev/null 2>&1; then
    log "Ruby not installed / updating"
    RUBY_CFLAGS="-O3" rbenv install -s 3.3.6 >/dev/null 2>&1 || return 1
    rbenv global 3.3.6
    rbenv rehash
  fi

  touch "$CHECK"
  log "Ruby ready"
}
