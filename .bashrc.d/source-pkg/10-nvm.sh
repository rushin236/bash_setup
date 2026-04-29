#!/usr/bin/env bash

export NVM_DIR="$HOME/.nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] || return 0

# Alpine musl builds
[[ -f /etc/alpine-release ]] &&
  export NVM_NODEJS_ORG_MIRROR="https://unofficial-builds.nodejs.org/download/release"

source "$NVM_DIR/nvm.sh"

nvm use default >/dev/null 2>&1
