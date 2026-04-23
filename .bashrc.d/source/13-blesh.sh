source_blesh() {
  # [[ $- == *i* ]] || return 0

  local BLE="$HOME/.local/share/blesh/ble.sh"
  local BLERC="$HOME/.blerc"

  [[ -f "$BLE" ]] || return 0

  source "$BLE" --noattach || return 0
  [[ ${BLE_VERSION-} ]] || return 0

  [[ -f "$BLERC" ]] && source "$BLERC"
}

attach_blesh() {
  # [[ $- == *i* ]] || return 0
  [[ ${BLE_VERSION-} ]] && ble-attach
}
