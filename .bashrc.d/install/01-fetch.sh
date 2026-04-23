#!/usr/bin/env bash

fetch() {
  url="$1"
  out="$2"

  need_any curl wget || return 1

  if has curl; then
    curl -fL --retry 3 -o "$out" "$url"
  else
    wget -O "$out" "$url"
  fi
}

extract() {
  file="$1"
  dest="$2"

  mkdir -p "$dest"

  case "$file" in
    *.tar.gz | *.tgz) tar -xzf "$file" -C "$dest" ;;
    *.tar.xz) tar -xJf "$file" -C "$dest" ;;
    *.tar.bz2) tar -xjf "$file" -C "$dest" ;;
    *.zip) unzip -q "$file" -d "$dest" ;;
    *)
      die "Unsupported archive: $file"
      ;;
  esac
}
