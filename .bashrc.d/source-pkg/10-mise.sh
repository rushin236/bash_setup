#!/usr/bin/env bash

command -v mise >/dev/null 2>&1 || return 0

eval "$(mise activate bash)"
