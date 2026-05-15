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
  mkdir -p "$@" >/dev/null
}

ensure_local_dirs() {
  makedirs \
    "$HOME/.local/bin" \
    "$HOME/.local/opt" \
    "$HOME/.local/share/bash_setup/checks" \
    "$HOME/.cache/bash_setup"
}

ensure_local_dirs

_refresh_shell_runtime() {
  # 1. Clear Bash's command cache
  hash -r

  if command -v mise >/dev/null 2>&1; then
    # 2. Tell OS to generate shims for newly downloaded tools
    mise reshim >/dev/null 2>&1 || true

    # 3. The Smart Router (Using your PROMPT_COMMAND check)
    if [[ "${PROMPT_COMMAND[*]:-}" == *"_mise_hook"* ]]; then
      # ALREADY ACTIVATED: Just do a fast, stateless PATH update for the subshell
      eval "$(mise env)"
    else
      # NOT ACTIVATED YET: Run the full startup sequence
      if [[ -f "$HOME/.bashrc.d/source-pkg/10-mise.sh" ]]; then
        source "$HOME/.bashrc.d/source-pkg/10-mise.sh"
      else
        # Fallback if 10-mise.sh doesn't exist yet
        eval "$(mise activate bash)"
        # complete -r mise 2>/dev/null || true
      fi
    fi

    # 4. Clear cache again so Bash immediately sees the new shims
    hash -r
  fi
}

_ensure_mise_config() {
  # Fast exit if mise isn't installed yet
  command -v mise >/dev/null 2>&1 || return 0

  local config_file="$HOME/.config/mise/config.toml"

  # 1. Check and Set Ruby Settings
  if [[ "$(mise settings get ruby.compile 2>/dev/null)" != "false" ]]; then
    mise settings set ruby.compile false 2>/dev/null || true
  fi

  # 2. Check and Set Global Environment Variables
  if ! grep -q "^MISE_PYTHON_GITHUB_ATTESTATIONS" "$config_file" 2>/dev/null; then
    mise config set env.MISE_PYTHON_GITHUB_ATTESTATIONS false
  fi

  if ! grep -q "^PHP_SKIP_DEPS" "$config_file" 2>/dev/null; then
    mise config set env.PHP_SKIP_DEPS '"1"'
  fi

  if ! grep -q "^PHP_CONFIGURE_OPTIONS" "$config_file" 2>/dev/null; then
    mise config set env.PHP_CONFIGURE_OPTIONS -- "--enable-bcmath --enable-calendar --enable-dba --enable-exif --enable-fpm --enable-ftp --enable-gd --enable-intl --enable-mbregex --enable-mbstring --enable-mysqlnd --enable-pcntl --enable-shmop --enable-soap --enable-sockets --enable-sysvmsg --enable-sysvsem --enable-sysvshm --with-curl --with-mhash --with-openssl --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-zlib --without-pcre-jit --with-readline --with-gettext --with-zip"
  fi

  # 3. Check and Set Custom Plugins
  if ! mise plugin ls 2>/dev/null | grep -qx php; then
    log "Adding custom PHP plugin..."
    mise plugin install php https://github.com/verzly/mise-php#latest
  fi
}
