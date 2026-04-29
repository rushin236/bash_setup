#!/usr/bin/env bash

# interactive shell only
[[ $- == *i* ]] || return 0

# must have real terminal
[[ -t 0 && -t 1 ]] || return 0

BLESH_SCRIPT="$HOME/.local/share/blesh/ble.sh"

[[ -f "$BLESH_SCRIPT" ]] && source "$BLESH_SCRIPT" --noattach
