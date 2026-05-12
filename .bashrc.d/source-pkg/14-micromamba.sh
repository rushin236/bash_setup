#!/usr/bin/env bash

command -v micromamba >/dev/null 2>&1 || return 0

export MAMBA_ROOT_PREFIX="${MAMBA_ROOT_PREFIX:-$HOME/micromamba}"

eval "$(micromamba shell hook -s bash)"

if [[ -d "$HOME/micromamba/envs/user" ]]; then
  micromamba activate user >/dev/null 2>&1
fi
