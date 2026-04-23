#!/usr/bin/env bash

has() {
  command -v "$1" >/dev/null 2>&1
}

log() {
  printf '[INFO] %s\n' "$*"
}

warn() {
  printf '[WARN] %s\n' "$*" >&2
}

die() {
  printf '[ERROR] %s\n' "$*" >&2
  return 1
}

need() {
  has "$1" || die "Missing required tool: $1"
}

need_any() {
  for tool in "$@"; do
    has "$tool" && return 0
  done
  die "Need one of: $*"
}

detect_os() {
  uname -s | tr '[:upper:]' '[:lower:]'
}

detect_arch() {
  case "$(uname -m)" in
    x86_64) echo amd64 ;;
    aarch64) echo arm64 ;;
    armv7l) echo armv7 ;;
    *) uname -m ;;
  esac
}

makedirs() {
  mkdir -p "$@"
}

ensure_local_dirs() {
  makedirs \
    "$HOME/.local/bin" \
    "$HOME/.local/opt" \
    "$HOME/.local/share/bash_setup/checks" \
    "$HOME/.cache/bash_setup"
}

ensure_local_dirs
