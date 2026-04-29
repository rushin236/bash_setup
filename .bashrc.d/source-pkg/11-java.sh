#!/usr/bin/env bash

export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] || return 0

source "$SDKMAN_DIR/bin/sdkman-init.sh"
