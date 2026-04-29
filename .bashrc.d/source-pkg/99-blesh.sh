#!/usr/bin/env bash

[[ $- == *i* ]] || return 0
[[ -t 0 && -t 1 ]] || return 0

[[ ${BLE_VERSION-} ]] && ble-attach
