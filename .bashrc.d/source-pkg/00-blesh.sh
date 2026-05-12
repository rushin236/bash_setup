#!/usr/bin/env bash

# Inline the path and check existence directly before sourcing
[[ -f "$HOME/.local/share/blesh/ble.sh" ]] && source "$HOME/.local/share/blesh/ble.sh" --noattach
