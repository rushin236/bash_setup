#!/usr/bin/env bash

add_path "$HOME/.rbenv/bin"
add_path "$HOME/.rbenv/shims"

command -v rbenv >/dev/null 2>&1 || return 0

eval "$(rbenv init - bash)"
