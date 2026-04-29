#!/usr/bin/env bash

command -v micromamba >/dev/null 2>&1 || return 0

export MAMBA_ROOT_PREFIX="${MAMBA_ROOT_PREFIX:-$HOME/micromamba}"

eval "$(micromamba shell hook -s bash)"

if micromamba env list 2>/dev/null | awk '{print $1}' | grep -qx user; then
  micromamba activate user >/dev/null 2>&1
fi
