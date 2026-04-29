#!/usr/bin/env bash

tool_sync() {
  local args=("$@")

  [[ ${#args[@]} -eq 0 ]] && args=("all")

  for item in "${args[@]}"; do
    case "$item" in
      all)
        _sync_pkg_managers
        _sync_languages
        _sync_sub_packages
        ;;
      node | nvm)
        _sync_node
        ;;
      python | micromamba)
        _sync_python
        ;;
      java)
        _sync_java
        ;;
      ruby)
        _sync_ruby
        ;;
      php)
        _sync_php
        ;;
      go)
        _sync_go
        ;;
      rust)
        _sync_rust
        ;;
      *)
        echo "Unknown sync target: $item"
        ;;
    esac
  done
}

_sync_pkg_managers() {
  tool pkg install nvm micromamba java ruby php rust go
}

_sync_languages() {
  _sync_node
  _sync_python
  _sync_java
  _sync_ruby
  _sync_php
}

_sync_sub_packages() {
  tool sub-pkg npm install all
  tool sub-pkg rustup install all
  tool sub-pkg cargo install all
  tool sub-pkg go install all
}

_sync_node() {
  export NVM_DIR="$HOME/.nvm"
  [[ -s "$NVM_DIR/nvm.sh" ]] || return 0

  [[ -f /etc/alpine-release ]] &&
    export NVM_NODEJS_ORG_MIRROR="https://unofficial-builds.nodejs.org/download/release"

  source "$NVM_DIR/nvm.sh"

  source "$HOME/.bashrc.d/global_source.conf" 2>/dev/null

  local ver="${VERSION_NVM:-22}"

  log "Syncing Node $ver"
  nvm install "$ver"
  nvm alias default "$ver"
}

_sync_python() {
  command -v micromamba >/dev/null 2>&1 || return 0

  source "$HOME/.bashrc.d/global_source.conf" 2>/dev/null

  local ver="${VERSION_PYTHON:-3.12}"
  local root="$HOME/micromamba"

  log "Syncing Python $ver in env user"

  micromamba create -y -n user -c conda-forge "python=$ver" -r "$root" >/dev/null 2>&1 ||
    micromamba install -y -n user -c conda-forge "python=$ver" -r "$root"
}

_sync_java() {
  export SDKMAN_DIR="$HOME/.sdkman"
  [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] || return 0

  source "$SDKMAN_DIR/bin/sdkman-init.sh"
  source "$HOME/.bashrc.d/global_source.conf" 2>/dev/null

  local ver="${VERSION_JAVA:-21}"

  log "Syncing Java $ver"
  sdk install java "$ver"
  sdk default java "$ver"
}

_sync_ruby() {
  add_path "$HOME/.rbenv/bin"

  command -v rbenv >/dev/null 2>&1 || return 0
  eval "$(rbenv init - bash)"

  source "$HOME/.bashrc.d/global_source.conf" 2>/dev/null

  local ver="${VERSION_RUBY:-3.3.6}"

  log "Syncing Ruby $ver"
  rbenv install -s "$ver"
  rbenv global "$ver"
}

_sync_php() {
  [[ -s "$HOME/.phpbrew/bashrc" ]] || return 0

  source "$HOME/.phpbrew/bashrc"
  source "$HOME/.bashrc.d/global_source.conf" 2>/dev/null

  local ver="${VERSION_PHP:-8.3.4}"

  log "Syncing PHP $ver"
  phpbrew install "$ver" +default
  phpbrew switch "$ver"
}

_sync_go() {
  tool pkg install go
  tool sub-pkg go install all
}

_sync_rust() {
  tool pkg install rust
  tool sub-pkg rustup install all
  tool sub-pkg cargo install all
}
