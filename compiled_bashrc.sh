# ==========================================
# File: ./.bashrc
# ==========================================
# ~/.bashrc

# 1. Foundation
if [[ -f "$HOME/.bashrc.d/00-foundation.sh" ]]; then
  source "$HOME/.bashrc.d/00-foundation.sh"
fi

if [[ -f "$HOME/.bashrc.d/01-fetch.sh" ]]; then
  source "$HOME/.bashrc.d/01-fetch.sh"
fi

# 2. Tool CLI Engine
if [[ -f "$HOME/.bashrc.d/02-tool.sh" ]]; then
  source "$HOME/.bashrc.d/02-tool.sh"
fi

# 3. Core Environment
if [[ -d "$HOME/.bashrc.d/source" ]]; then
  for file in "$HOME/.bashrc.d/source"/*.sh; do
    [[ -f "$file" ]] && source "$file"
  done
fi

# 4. Package Initializers & Environment Sync
if [[ -d "$HOME/.bashrc.d/source-pkg" ]]; then
  # Because of the numbers, 00-blesh-init runs first, and 99-blesh-attach runs last!
  for file in "$HOME/.bashrc.d/source-pkg"/*.sh; do
    [[ -f "$file" ]] && source "$file"
  done
fi


# ==========================================
# File: ./.bashrc.d/00-foundation.sh
# ==========================================
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


# ==========================================
# File: ./.bashrc.d/01-fetch.sh
# ==========================================
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


# ==========================================
# File: ./.bashrc.d/02-tool.sh
# ==========================================
tool() {
  local cmd="$1"
  shift

  case "$cmd" in
    pkg)
      (
        source ~/.bashrc.d/tool/pkg.sh
        tool_pkg "$@"
      )
      ;;
    sub-pkg)
      (
        source ~/.bashrc.d/tool/sub-pkg.sh
        tool_sub_pkg "$@"
      )
      ;;
    sync)
      (
        source ~/.bashrc.d/tool/sync.sh
        tool_sync "$@"
      )
      ;;
    sys)
      (
        source ~/.bashrc.d/tool/sys.sh
        tool_sys "$@"
      )
      ;;
    list | "")
      (
        source ~/.bashrc.d/tool/list.sh
        tool_list
      )
      ;;
  esac

  source "${HOME}/.bashrc"
}


# ==========================================
# File: ./.bashrc.d/global_source.conf
# ==========================================
# ~/.bashrc.d/global_source.conf
# Global desired versions for user-space environments.
# If left blank, the manager will install the latest stable/LTS version 
# and automatically write the exact version number back to this file.

VERSION_NVM="22"
VERSION_JAVA="21.0.2-tem"
VERSION_RUBY="3.3.6"
VERSION_PHP="8.3.4"
VERSION_PYTHON="3.12"


# ==========================================
# File: ./.bashrc.d/global_tools.conf
# ==========================================
[cargo]
stylua
git-delta
eza
zoxide
tectonic
bacon
cargo-watch

[npm]
tree-sitter-cli
markdown-toc
neovim
prettier
markdownlint-cli2
bash-language-server
pyright
typescript
typescript-language-server
@mermaid-js/mermaid-cli

[rustup]
rustfmt
clippy
rust-analyzer

[go]
mvdan.cc/sh/v3/cmd/shfmt@latest
github.com/mikefarah/yq/v4@latest
github.com/jesseduffield/lazygit@latest
golang.org/x/tools/gopls@latest
github.com/golangci/golangci-lint/cmd/golangci-lint@latest


# ==========================================
# File: ./.bashrc.d/packages/blesh.sh
# ==========================================
pkg_blesh() {
  local action="$1"
  local DIR="$HOME/.local/opt/blesh-src"
  local SHARE_DIR="$HOME/.local/share/blesh"
  local CHECK="$HOME/.local/share/bash_setup/checks/blesh.check"

  case "$action" in
    install | update)
      ensure_local_dirs
      need git || return 1
      need make || return 1

      local NEEDS_INSTALL=0
      local LOCAL_VER=""
      local REMOTE_VER=""

      if [[ ! -f "$SHARE_DIR/ble.sh" ]] || [[ ! -d "$DIR" ]]; then
        NEEDS_INSTALL=1
      elif [[ "$action" == "update" ]] || [[ ! -f "$CHECK" ]] || [[ -n "$(find "$CHECK" -mtime +7 2>/dev/null)" ]]; then
        LOCAL_VER="$(git -C "$DIR" rev-parse --short HEAD 2>/dev/null)"

        has_internet || {
          touch "$CHECK"
          return 0
        }

        # API Bypass: Fetch latest commit hash directly via git
        REMOTE_VER="$(git ls-remote https://github.com/akinomyoga/ble.sh.git HEAD | awk '{print substr($1,1,7)}')"

        if [[ -n "$REMOTE_VER" && "$LOCAL_VER" != "$REMOTE_VER" ]]; then
          NEEDS_INSTALL=1
          log "ble.sh update available"
        else
          touch "$CHECK"
        fi
      fi

      if [[ $NEEDS_INSTALL -eq 1 ]]; then
        has_internet || return 0
        log "Installing/Updating ble.sh..."

        if [[ ! -d "$DIR/.git" ]]; then
          rm -rf "$DIR" >/dev/null 2>&1
          git clone --recursive --depth 1 https://github.com/akinomyoga/ble.sh.git "$DIR" >/dev/null 2>&1 || return 1
        else
          (cd "$DIR" && git pull --rebase && git submodule update --init --recursive) >/dev/null 2>&1 || return 1
        fi

        make -C "$DIR" install PREFIX="$HOME/.local" >/dev/null 2>&1 || return 1

        touch "$CHECK"
        log "ble.sh ready"
      fi
      ;;

    remove)
      log "Removing ble.sh..."
      rm -rf "$DIR" "$SHARE_DIR" "$CHECK" >/dev/null 2>&1
      log "ble.sh removed"
      ;;
  esac
}


# ==========================================
# File: ./.bashrc.d/packages/carapace.sh
# ==========================================
pkg_carapace() {
  local action="$1"
  local DIR="$HOME/.local/opt/carapace"
  local BIN="$HOME/.local/bin/carapace"
  local CHECK="$HOME/.local/share/bash_setup/checks/carapace.check"

  case "$action" in
    install | update)
      ensure_local_dirs

      local ARCH
      ARCH="$(detect_arch)"

      local DL_ARCH=""
      case "$ARCH" in
        amd64) DL_ARCH="amd64" ;;
        arm64) DL_ARCH="arm64" ;;
        *) return 1 ;;
      esac

      local NEEDS_INSTALL=0
      local LOCAL_VER=""
      local REMOTE_VER=""

      if [[ ! -x "$BIN" ]]; then
        NEEDS_INSTALL=1

      elif [[ "$action" == "update" ]] ||
        [[ ! -f "$CHECK" ]] ||
        [[ -n "$(find "$CHECK" -mtime +7 2>/dev/null)" ]]; then

        LOCAL_VER="$("$BIN" --version 2>/dev/null | awk '{print $2}')"

        has_internet || {
          touch "$CHECK"
          return 0
        }

        REMOTE_VER="$(
          basename "$(
            curl -fsSLw "%{url_effective}" \
              -o /dev/null \
              "https://github.com/carapace-sh/carapace-bin/releases/latest"
          )"
        )"

        if [[ -n "$REMOTE_VER" && "v${LOCAL_VER#v}" != "$REMOTE_VER" ]]; then
          NEEDS_INSTALL=1
          log "Carapace update available: $LOCAL_VER -> $REMOTE_VER"
        else
          touch "$CHECK"
        fi
      fi

      if [[ $NEEDS_INSTALL -eq 1 ]]; then
        has_internet || return 0

        [[ -z "$REMOTE_VER" ]] && REMOTE_VER="$(
          basename "$(
            curl -fsSLw "%{url_effective}" \
              -o /dev/null \
              "https://github.com/carapace-sh/carapace-bin/releases/latest"
          )"
        )"

        [[ -z "$REMOTE_VER" ]] && {
          log "Failed to fetch Carapace version."
          return 1
        }

        local URL="https://github.com/carapace-sh/carapace-bin/releases/download/${REMOTE_VER}/carapace-bin_${REMOTE_VER#v}_linux_${DL_ARCH}.tar.gz"

        local TMP_DIR="/tmp/carapace_update_$RANDOM"
        mkdir -p "$TMP_DIR"

        if curl -fsSL "$URL" | tar -xzf - -C "$TMP_DIR" carapace 2>/dev/null; then
          rm -rf "$DIR" >/dev/null 2>&1
          mkdir -p "$DIR"

          mv "$TMP_DIR/carapace" "$DIR/carapace" >/dev/null 2>&1
          chmod +x "$DIR/carapace"

          ln -sf "$DIR/carapace" "$BIN"

          touch "$CHECK"
          log "Carapace ready"
        else
          log "Failed to download Carapace."
        fi

        rm -rf "$TMP_DIR" >/dev/null 2>&1
      fi
      ;;
    remove)
      log "Removing Carapace..."
      rm -rf "$DIR" "$BIN" "$CHECK" >/dev/null 2>&1
      log "Carapace removed"
      ;;
  esac
}


# ==========================================
# File: ./.bashrc.d/packages/composer.sh
# ==========================================
pkg_composer() {
  local action="$1"
  local BIN="$HOME/.local/bin/composer"
  local CHECK="$HOME/.local/share/bash_setup/checks/composer.check"

  case "$action" in
    install | update)
      ensure_local_dirs
      command -v php >/dev/null 2>&1 || {
        log "PHP required for Composer. Skipping."
        return 1
      }

      local NEEDS_INSTALL=0
      if [[ ! -x "$BIN" ]] || [[ "$action" == "update" ]] || [[ ! -f "$CHECK" ]] || [[ -n "$(find "$CHECK" -mtime +7 2>/dev/null)" ]]; then
        NEEDS_INSTALL=1
      fi

      if [[ $NEEDS_INSTALL -eq 1 ]]; then
        has_internet || {
          log "No internet. Skipping Composer."
          return 0
        }

        local TMP_BIN="/tmp/composer_$RANDOM.phar"
        log "Downloading Composer..."

        if curl -fsSL https://getcomposer.org/installer | php -- --install-dir="/tmp" --filename="$(basename "$TMP_BIN")" >/dev/null 2>&1; then
          mv "$TMP_BIN" "$BIN" >/dev/null 2>&1
          chmod +x "$BIN"
          touch "$CHECK"
          log "Composer ready"
        else
          return 1
        fi
      fi
      ;;
    remove)
      log "Removing Composer..."
      rm -f "$BIN" "$CHECK"
      log "Composer removed"
      ;;
  esac
}


# ==========================================
# File: ./.bashrc.d/packages/fd.sh
# ==========================================
pkg_fd() {
  local action="$1"
  local DIR="$HOME/.local/opt/fd"
  local BIN="$HOME/.local/bin/fd"
  local CHECK="$HOME/.local/share/bash_setup/checks/fd.check"

  case "$action" in
    install | update)
      ensure_local_dirs
      local ARCH
      ARCH="$(detect_arch)"
      local FILE=""

      case "$ARCH" in
        amd64) FILE="fd-v10.4.2-x86_64-unknown-linux-musl.tar.gz" ;;
        arm64) FILE="fd-v10.4.2-aarch64-unknown-linux-gnu.tar.gz" ;;
        *) return 1 ;;
      esac

      local NEEDS_INSTALL=0
      if [[ ! -x "$BIN" ]] || [[ "$action" == "update" ]] || [[ ! -f "$CHECK" ]] || [[ -n "$(find "$CHECK" -mtime +7 2>/dev/null)" ]]; then
        NEEDS_INSTALL=1
      fi

      if [[ $NEEDS_INSTALL -eq 1 ]]; then
        log "Checking for fd updates..."

        has_internet || {
          log "No internet. Keeping current fd version."
          return 0
        }

        local TMP_DIR="/tmp/fd_update_$RANDOM"
        mkdir -p "$TMP_DIR"

        if curl -fsSL "https://github.com/sharkdp/fd/releases/download/v10.4.2/$FILE" | tar -xzf - --strip-components=1 -C "$TMP_DIR" 2>/dev/null; then
          rm -rf "$DIR" >/dev/null 2>&1
          mv "$TMP_DIR" "$DIR" >/dev/null 2>&1
          ln -sf "$DIR/fd" "$BIN"

          touch "$CHECK"
          log "fd ready and updated"
        else
          log "Failed to download fd. Current version retained."
          rm -rf "$TMP_DIR" >/dev/null 2>&1
          return 1
        fi
      fi
      ;;

    remove)
      log "Removing fd..."
      rm -rf "$DIR" "$BIN" "$CHECK" >/dev/null 2>&1
      log "fd removed"
      ;;
  esac
}


# ==========================================
# File: ./.bashrc.d/packages/fzf.sh
# ==========================================
pkg_fzf() {
  local action="$1"
  local DIR="$HOME/.local/opt/fzf"
  local BIN="$HOME/.local/bin/fzf"
  local CHECK="$HOME/.local/share/bash_setup/checks/fzf.check"

  case "$action" in
    install | update)
      ensure_local_dirs
      need git || return 1

      local NEEDS_INSTALL=0
      local LOCAL_VER=""
      local REMOTE_VER=""

      if [[ ! -x "$BIN" ]] || [[ ! -d "$DIR" ]]; then
        NEEDS_INSTALL=1
      elif [[ "$action" == "update" ]] || [[ ! -f "$CHECK" ]] || [[ -n "$(find "$CHECK" -mtime +7 2>/dev/null)" ]]; then
        LOCAL_VER="$("$BIN" --version | awk '{print $1}')"
        has_internet || {
          touch "$CHECK"
          return 0
        }

        # API Bypass
        REMOTE_VER="$(basename "$(curl -fsSLw "%{url_effective}" -o /dev/null "https://github.com/junegunn/fzf/releases/latest")" | sed 's/^v//')"

        if [[ -n "$REMOTE_VER" && "$LOCAL_VER" != "$REMOTE_VER" ]]; then
          NEEDS_INSTALL=1
          log "fzf update available: $LOCAL_VER -> $REMOTE_VER"
        else
          touch "$CHECK"
        fi
      fi

      if [[ $NEEDS_INSTALL -eq 1 ]]; then
        has_internet || return 0
        log "Installing/Updating fzf..."

        if [[ ! -d "$DIR/.git" ]]; then
          rm -rf "$DIR" >/dev/null 2>&1
          git clone --depth 1 https://github.com/junegunn/fzf.git "$DIR" >/dev/null 2>&1 || return 1
        else
          (cd "$DIR" && git pull --rebase) >/dev/null 2>&1 || return 1
        fi

        "$DIR/install" --bin --no-update-rc >/dev/null 2>&1 || return 1
        ln -sf "$DIR/bin/fzf" "$BIN"

        touch "$CHECK"
        log "fzf ready"
      fi
      ;;
    remove)
      log "Removing fzf..."
      rm -rf "$DIR" "$BIN" "$CHECK" >/dev/null 2>&1
      log "fzf removed"
      ;;
  esac
}


# ==========================================
# File: ./.bashrc.d/packages/go.sh
# ==========================================
pkg_go() {
  local action="$1"
  local DIR="$HOME/.local/opt/go"
  local CHECK="$HOME/.local/share/bash_setup/checks/go.check"

  case "$action" in
    install | update)
      ensure_local_dirs
      local ARCH
      ARCH="$(detect_arch)"
      local DL_ARCH=""
      case "$ARCH" in
        amd64) DL_ARCH="amd64" ;;
        arm64) DL_ARCH="arm64" ;;
        *) return 1 ;;
      esac

      local NEEDS_INSTALL=0
      local LOCAL_VER=""
      local REMOTE_VER=""

      if [[ ! -x "$DIR/bin/go" ]]; then
        NEEDS_INSTALL=1
      elif [[ "$action" == "update" ]] || [[ ! -f "$CHECK" ]] || [[ -n "$(find "$CHECK" -mtime +7 2>/dev/null)" ]]; then
        LOCAL_VER="$("$DIR/bin/go" version | awk '{print $3}')"
        has_internet || {
          touch "$CHECK"
          return 0
        }

        REMOTE_VER="$(curl -fsSL "https://go.dev/VERSION?m=text" | head -n 1 | tr -d '\r')"

        if [[ -n "$REMOTE_VER" && "$LOCAL_VER" != "$REMOTE_VER" ]]; then
          NEEDS_INSTALL=1
          log "Go update available: $LOCAL_VER -> $REMOTE_VER"
        else
          touch "$CHECK"
        fi
      fi

      if [[ $NEEDS_INSTALL -eq 1 ]]; then
        has_internet || return 0
        [[ -z "$REMOTE_VER" ]] && REMOTE_VER="$(curl -fsSL "https://go.dev/VERSION?m=text" | head -n 1 | tr -d '\r')"

        if [[ -z "$REMOTE_VER" ]]; then
          log "Failed to fetch Go version. Skipping."
          return 1
        fi

        local FILE="${REMOTE_VER}.linux-${DL_ARCH}.tar.gz"
        local URL="https://go.dev/dl/$FILE"
        local TMP_DIR="/tmp/go_update_$RANDOM"

        mkdir -p "$TMP_DIR"

        if curl -fsSL "$URL" | tar -xzf - -C "$TMP_DIR" 2>/dev/null; then
          rm -rf "$DIR" >/dev/null 2>&1
          mv "$TMP_DIR/go" "$DIR" >/dev/null 2>&1

          touch "$CHECK"
          log "Go ready"
        else
          log "Failed to download Go."
        fi
        rm -rf "$TMP_DIR" >/dev/null 2>&1
      fi
      ;;
    remove)
      log "Removing Go..."
      rm -rf "$DIR" "$CHECK" >/dev/null 2>&1
      log "Go removed"
      ;;
  esac
}


# ==========================================
# File: ./.bashrc.d/packages/java.sh
# ==========================================
pkg_java() {
  local action="$1"
  local SDK_DIR="$HOME/.sdkman"
  local CHECK="$HOME/.local/share/bash_setup/checks/java.check"

  case "$action" in
    install | update)
      ensure_local_dirs
      need_any curl wget || return 1
      need unzip || return 1
      need zip || return 1

      local NEEDS_INSTALL=0

      if [[ ! -s "$SDK_DIR/bin/sdkman-init.sh" ]]; then
        NEEDS_INSTALL=1
        log "SDKMAN! not installed"
      elif [[ "$action" == "update" ]] || [[ ! -f "$CHECK" ]] || [[ -n "$(find "$CHECK" -mtime +7 2>/dev/null)" ]]; then
        has_internet || {
          touch "$CHECK"
          return 0
        }

        export SDKMAN_DIR="$SDK_DIR"
        source "$SDK_DIR/bin/sdkman-init.sh"

        log "Checking for SDKMAN! updates..."
        sdk selfupdate force >/dev/null 2>&1
        touch "$CHECK"
      fi

      if [[ $NEEDS_INSTALL -eq 1 ]]; then
        has_internet || {
          log "No internet. Cannot install SDKMAN!."
          return 0
        }
        log "Installing SDKMAN!..."

        export SDKMAN_DIR="$SDK_DIR"
        curl -s "https://get.sdkman.io?rcupdate=false" | bash >/dev/null 2>&1 || return 1

        touch "$CHECK"
        log "SDKMAN! ready (Java versions will be managed via config)"
      fi
      ;;

    remove)
      log "Removing SDKMAN! and all managed Java versions..."
      rm -rf "$SDK_DIR" "$CHECK" >/dev/null 2>&1
      log "SDKMAN! removed"
      ;;
  esac
}


# ==========================================
# File: ./.bashrc.d/packages/julia.sh
# ==========================================
pkg_julia() {
  local action="$1"
  local DIR="$HOME/.local/opt/julia"
  local BIN="$HOME/.local/bin/julia"
  local CHECK="$HOME/.local/share/bash_setup/checks/julia.check"

  case "$action" in
    install | update)
      ensure_local_dirs
      local ARCH="$(detect_arch)"
      local API_ARCH=""
      local DL_ARCH=""

      case "$ARCH" in
        amd64)
          API_ARCH="x64"
          DL_ARCH="x86_64"
          ;;
        arm64)
          API_ARCH="aarch64"
          DL_ARCH="aarch64"
          ;;
        *) return 1 ;;
      esac

      local NEEDS_INSTALL=0
      local LOCAL_VER=""
      local REMOTE_VER=""

      if [[ ! -x "$BIN" ]]; then
        NEEDS_INSTALL=1
      elif [[ "$action" == "update" ]] || [[ ! -f "$CHECK" ]] || [[ -n "$(find "$CHECK" -mtime +14 2>/dev/null)" ]]; then
        LOCAL_VER="$("$BIN" --version | awk '{print $3}')"

        has_internet || {
          touch "$CHECK"
          return 0
        }

        # API Bypass
        REMOTE_VER="$(basename "$(curl -fsSLw "%{url_effective}" -o /dev/null "https://github.com/JuliaLang/julia/releases/latest")" | sed 's/^v//')"

        if [[ -n "$REMOTE_VER" && "$LOCAL_VER" != "$REMOTE_VER" ]]; then
          NEEDS_INSTALL=1
          log "Julia update available: $LOCAL_VER -> $REMOTE_VER"
        else
          touch "$CHECK"
        fi
      fi

      if [[ $NEEDS_INSTALL -eq 1 ]]; then
        has_internet || return 0
        [[ -z "$REMOTE_VER" ]] && REMOTE_VER="$(basename "$(curl -fsSLw "%{url_effective}" -o /dev/null "https://github.com/JuliaLang/julia/releases/latest")" | sed 's/^v//')"

        if [[ -z "$REMOTE_VER" ]]; then
          log "Failed to fetch Julia version. Skipping update."
          return 1
        fi

        local MINOR_VER="${REMOTE_VER%.*}"
        local FILE="julia-${REMOTE_VER}-linux-${DL_ARCH}.tar.gz"
        local URL="https://julialang-s3.julialang.org/bin/linux/${API_ARCH}/${MINOR_VER}/$FILE"
        local TMP_DIR="/tmp/julia_update_$RANDOM"

        mkdir -p "$TMP_DIR"
        log "Downloading Julia $REMOTE_VER..."

        if curl -fsSL "$URL" | tar -xzf - -C "$TMP_DIR" --strip-components=1 2>/dev/null; then
          rm -rf "$DIR" >/dev/null 2>&1
          mv "$TMP_DIR" "$DIR" >/dev/null 2>&1
          ln -sf "$DIR/bin/julia" "$BIN"

          touch "$CHECK"
          log "Julia ready"
        else
          log "Failed to download Julia. Current version retained."
          rm -rf "$TMP_DIR" >/dev/null 2>&1
          return 1
        fi
      fi
      ;;

    remove)
      log "Removing Julia..."
      rm -rf "$DIR" "$BIN" "$CHECK" >/dev/null 2>&1
      log "Julia removed"
      ;;
  esac
}


# ==========================================
# File: ./.bashrc.d/packages/micromamba.sh
# ==========================================
pkg_micromamba() {
  local action="$1"
  local BIN="$HOME/.local/bin/micromamba"
  local CHECK="$HOME/.local/share/bash_setup/checks/micromamba.check"

  case "$action" in
    install | update)
      ensure_local_dirs
      need tar || return 1
      need bzip2 || {
        log "bzip2 required for micromamba. Skipping."
        return 1
      }

      local ARCH="$(detect_arch)"
      local DL_ARCH=""
      case "$ARCH" in
        amd64) DL_ARCH="linux-64" ;;
        arm64) DL_ARCH="linux-aarch64" ;;
        *) return 1 ;;
      esac

      local NEEDS_INSTALL=0
      local LOCAL_VER=""
      local REMOTE_VER=""

      if [[ ! -x "$BIN" ]]; then
        NEEDS_INSTALL=1
      elif [[ "$action" == "update" ]] || [[ ! -f "$CHECK" ]] || [[ -n "$(find "$CHECK" -mtime +7 2>/dev/null)" ]]; then
        LOCAL_VER="$("$BIN" --version 2>/dev/null)"
        has_internet || {
          touch "$CHECK"
          return 0
        }

        # Fixed for Alpine: Swapped grep -Po for basic grep + sed -E
        REMOTE_VER="$(curl -fsSL "https://api.anaconda.org/package/conda-forge/micromamba" | grep -m 1 '"latest_version"' | sed -E 's/.*"latest_version":[[:space:]]*"([^"]+)".*/\1/')"

        if [[ -n "$REMOTE_VER" && "$LOCAL_VER" != "$REMOTE_VER" ]]; then
          NEEDS_INSTALL=1
          log "Micromamba update available: $LOCAL_VER -> $REMOTE_VER"
        else
          touch "$CHECK"
        fi
      fi

      if [[ $NEEDS_INSTALL -eq 1 ]]; then
        has_internet || return 0
        local URL="https://micro.mamba.pm/api/micromamba/${DL_ARCH}/latest"
        local TMP_DIR="/tmp/mamba_$RANDOM"
        mkdir -p "$TMP_DIR"

        log "Downloading Micromamba..."
        if curl -fsSL "$URL" | tar -xvj -C "$TMP_DIR" "bin/micromamba" >/dev/null 2>&1; then
          mv "$TMP_DIR/bin/micromamba" "$BIN" >/dev/null 2>&1
          chmod +x "$BIN"
          touch "$CHECK"
          log "Micromamba ready"
        fi
        rm -rf "$TMP_DIR" >/dev/null 2>&1
      fi
      ;;
    remove)
      log "Removing Micromamba executable..."
      rm -f "$BIN" "$CHECK"
      log "Micromamba removed. (Environments in ~/micromamba retained)"
      ;;
  esac
}


# ==========================================
# File: ./.bashrc.d/packages/nvim.sh
# ==========================================
pkg_nvim() {
  local action="$1"
  local NVIM_DIR="$HOME/.local/opt/nvim"
  local BIN_DIR="$HOME/.local/bin"
  local CHECK_FILE="$HOME/.local/share/bash_setup/checks/nvim.check"

  case "$action" in
    install | update)
      ensure_local_dirs
      local ARCH
      ARCH="$(detect_arch)"
      local FILE=""

      case "$ARCH" in
        amd64) FILE="nvim-linux-x86_64.tar.gz" ;;
        arm64) FILE="nvim-linux-arm64.tar.gz" ;;
        *)
          die "Unsupported architecture: $ARCH"
          return 1
          ;;
      esac

      local NEEDS_INSTALL=0
      local LOCAL_VER=""
      local REMOTE_VER=""

      if [[ ! -x "$BIN_DIR/nvim" ]]; then
        NEEDS_INSTALL=1
        log "Neovim not installed"
      elif [[ "$action" == "update" ]] || [[ ! -f "$CHECK_FILE" ]] || [[ -n "$(find "$CHECK_FILE" -mtime +7 2>/dev/null)" ]]; then
        LOCAL_VER="$("$BIN_DIR/nvim" --version | head -n1 | awk '{print $2}')"

        has_internet || {
          log "No internet. Skipping Neovim version check."
          touch "$CHECK_FILE"
          return 0
        }

        # API Bypass
        REMOTE_VER="$(basename "$(curl -fsSLw "%{url_effective}" -o /dev/null "https://github.com/neovim/neovim/releases/latest")")"

        if [[ -n "$REMOTE_VER" && "$LOCAL_VER" != "$REMOTE_VER" ]]; then
          NEEDS_INSTALL=1
          log "Neovim update available: $LOCAL_VER -> $REMOTE_VER"
        else
          touch "$CHECK_FILE"
        fi
      fi

      if [[ $NEEDS_INSTALL -eq 1 ]]; then
        has_internet || {
          log "No internet. Cannot download Neovim."
          return 0
        }

        [[ -z "$REMOTE_VER" ]] && REMOTE_VER="$(basename "$(curl -fsSLw "%{url_effective}" -o /dev/null "https://github.com/neovim/neovim/releases/latest")")"

        local URL="https://github.com/neovim/neovim/releases/download/$REMOTE_VER/$FILE"
        local TMP_DIR="/tmp/nvim_update_$RANDOM"

        mkdir -p "$TMP_DIR"
        log "Downloading Neovim $REMOTE_VER..."

        if curl -fsSL "$URL" | tar -xzf - -C "$TMP_DIR" --strip-components=1 2>/dev/null; then
          rm -rf "$NVIM_DIR" >/dev/null 2>&1
          mv "$TMP_DIR" "$NVIM_DIR" >/dev/null 2>&1
          ln -sf "$NVIM_DIR/bin/nvim" "$BIN_DIR/nvim"

          touch "$CHECK_FILE"
          log "Neovim ready"
        else
          log "Failed to download Neovim. Current version retained."
          rm -rf "$TMP_DIR" >/dev/null 2>&1
          return 1
        fi
      fi
      ;;

    remove)
      log "Removing Neovim..."
      rm -rf "$NVIM_DIR" "$BIN_DIR/nvim" "$CHECK_FILE" >/dev/null 2>&1
      log "Neovim removed"
      ;;
  esac
}


# ==========================================
# File: ./.bashrc.d/packages/nvm.sh
# ==========================================
pkg_nvm() {
  local action="$1"
  local NVM_DIR="$HOME/.nvm"
  local CHECK="$HOME/.local/share/bash_setup/checks/nvm.check"

  case "$action" in
    install | update)
      ensure_local_dirs
      need git || return 1
      need_any curl wget || return 1

      local NEEDS_INSTALL=0
      local LOCAL_VER=""
      local REMOTE_TAG=""
      local REMOTE_VER=""

      if [[ ! -d "$NVM_DIR" ]]; then
        NEEDS_INSTALL=1
      elif [[ "$action" == "update" ]] || [[ ! -f "$CHECK" ]] || [[ -n "$(find "$CHECK" -mtime +7 2>/dev/null)" ]]; then
        . "$NVM_DIR/nvm.sh"
        LOCAL_VER="$(nvm --version 2>/dev/null)"

        has_internet || {
          touch "$CHECK"
          return 0
        }

        # API Bypass
        REMOTE_TAG="$(basename "$(curl -fsSLw "%{url_effective}" -o /dev/null "https://github.com/nvm-sh/nvm/releases/latest")")"
        REMOTE_VER="${REMOTE_TAG#v}"

        if [[ -n "$REMOTE_VER" && "$LOCAL_VER" != "$REMOTE_VER" ]]; then
          NEEDS_INSTALL=1
          log "NVM update available: $LOCAL_VER -> $REMOTE_VER"
        else
          touch "$CHECK"
        fi
      fi

      if [[ $NEEDS_INSTALL -eq 1 ]]; then
        has_internet || return 0
        [[ -z "$REMOTE_TAG" ]] && REMOTE_TAG="$(basename "$(curl -fsSLw "%{url_effective}" -o /dev/null "https://github.com/nvm-sh/nvm/releases/latest")")"

        if [[ -z "$REMOTE_TAG" ]]; then
          log "Failed to fetch NVM version. Skipping NVM update."
          return 1
        fi

        log "Fetching NVM version $REMOTE_TAG..."

        if [[ ! -d "$NVM_DIR" ]]; then
          git clone --depth 1 --branch "$REMOTE_TAG" https://github.com/nvm-sh/nvm.git "$NVM_DIR" >/dev/null 2>&1 || return 1
        else
          (
            cd "$NVM_DIR" || exit 1
            git fetch origin tag "$REMOTE_TAG" --no-tags --depth 1 >/dev/null 2>&1 || exit 1
            git checkout "$REMOTE_TAG" -q >/dev/null 2>&1 || exit 1
          ) || return 1
        fi

        touch "$CHECK"
        log "NVM ready"
      fi
      ;;

    remove)
      log "Removing NVM and all installed Node versions..."
      rm -rf "$NVM_DIR" "$CHECK" >/dev/null 2>&1
      log "NVM removed"
      ;;
  esac
}


# ==========================================
# File: ./.bashrc.d/packages/php.sh
# ==========================================
pkg_php() {
  local action="$1"
  local BIN="$HOME/.local/bin/phpbrew"
  local PHPBREW_ROOT="$HOME/.phpbrew"
  local CHECK="$HOME/.local/share/bash_setup/checks/phpbrew.check"

  case "$action" in
    install | update)
      ensure_local_dirs
      need_any curl wget || return 1

      command -v php >/dev/null 2>&1 || {
        log "System PHP required to bootstrap phpbrew. Skipping."
        return 1
      }

      local NEEDS_INSTALL=0

      if [[ ! -x "$BIN" ]] || [[ ! -d "$PHPBREW_ROOT" ]]; then
        NEEDS_INSTALL=1
      elif [[ "$action" == "update" ]] || [[ ! -f "$CHECK" ]] || [[ -n "$(find "$CHECK" -mtime +7 2>/dev/null)" ]]; then
        has_internet || {
          touch "$CHECK"
          return 0
        }

        log "Checking for phpbrew updates..."
        "$BIN" self-update >/dev/null 2>&1 || true
        touch "$CHECK"
      fi

      if [[ $NEEDS_INSTALL -eq 1 ]]; then
        has_internet || {
          log "No internet. Cannot install phpbrew."
          return 0
        }
        log "Installing phpbrew..."

        local TMP_BIN="/tmp/phpbrew_$RANDOM.phar"
        local URL="https://github.com/phpbrew/phpbrew/releases/latest/download/phpbrew.phar"

        if curl -fsSL "$URL" -o "$TMP_BIN" 2>/dev/null; then
          mv "$TMP_BIN" "$BIN" >/dev/null 2>&1
          chmod +x "$BIN"

          export PHPBREW_ROOT="$PHPBREW_ROOT"
          "$BIN" init >/dev/null 2>&1

          touch "$CHECK"
          log "phpbrew ready (PHP versions managed via config)"
        else
          log "Failed to download phpbrew."
          rm -f "$TMP_BIN"
          return 1
        fi
      fi
      ;;

    remove)
      log "Removing phpbrew and managed PHP versions..."
      rm -rf "$PHPBREW_ROOT" "$BIN" "$CHECK" >/dev/null 2>&1
      log "phpbrew removed"
      ;;
  esac
}


# ==========================================
# File: ./.bashrc.d/packages/ripgrep.sh
# ==========================================
pkg_ripgrep() {
  local action="$1"
  local DIR="$HOME/.local/opt/rg"
  local BIN="$HOME/.local/bin/rg"
  local CHECK="$HOME/.local/share/bash_setup/checks/ripgrep.check"

  case "$action" in
    install | update)
      ensure_local_dirs
      local ARCH="$(detect_arch)"
      local DL_ARCH=""

      case "$ARCH" in
        amd64) DL_ARCH="x86_64-unknown-linux-musl" ;;
        arm64) DL_ARCH="aarch64-unknown-linux-gnu" ;;
        *) return 1 ;;
      esac

      local NEEDS_INSTALL=0
      local LOCAL_VER=""
      local REMOTE_VER=""

      if [[ ! -x "$BIN" ]]; then
        NEEDS_INSTALL=1
      elif [[ "$action" == "update" ]] || [[ ! -f "$CHECK" ]] || [[ -n "$(find "$CHECK" -mtime +7 2>/dev/null)" ]]; then
        LOCAL_VER="$("$BIN" --version | head -n 1 | awk '{print $2}')"

        has_internet || {
          log "No internet. Skipping ripgrep version check."
          touch "$CHECK"
          return 0
        }

        # API Bypass
        REMOTE_VER="$(basename "$(curl -fsSLw "%{url_effective}" -o /dev/null "https://github.com/BurntSushi/ripgrep/releases/latest")")"

        if [[ -n "$REMOTE_VER" && "$LOCAL_VER" != "${REMOTE_VER}" ]]; then
          NEEDS_INSTALL=1
          log "ripgrep update available: $LOCAL_VER -> $REMOTE_VER"
        else
          touch "$CHECK"
        fi
      fi

      if [[ $NEEDS_INSTALL -eq 1 ]]; then
        has_internet || {
          log "No internet. Cannot download ripgrep."
          return 0
        }

        [[ -z "$REMOTE_VER" ]] && REMOTE_VER="$(basename "$(curl -fsSLw "%{url_effective}" -o /dev/null "https://github.com/BurntSushi/ripgrep/releases/latest")")"

        if [[ -z "$REMOTE_VER" ]]; then
          log "Failed to fetch ripgrep version. Skipping update."
          return 1
        fi

        local FILE="ripgrep-${REMOTE_VER}-${DL_ARCH}.tar.gz"
        local URL="https://github.com/BurntSushi/ripgrep/releases/download/${REMOTE_VER}/$FILE"
        local TMP_DIR="/tmp/rg_update_$RANDOM"

        mkdir -p "$TMP_DIR"
        log "Downloading ripgrep $REMOTE_VER..."

        if curl -fsSL "$URL" | tar -xzf - --strip-components=1 -C "$TMP_DIR" 2>/dev/null; then
          rm -rf "$DIR" >/dev/null 2>&1
          mv "$TMP_DIR" "$DIR" >/dev/null 2>&1
          ln -sf "$DIR/rg" "$BIN"

          touch "$CHECK"
          log "ripgrep ready"
        else
          log "Failed to download ripgrep. Current version retained."
          rm -rf "$TMP_DIR" >/dev/null 2>&1
          return 1
        fi
      fi
      ;;

    remove)
      log "Removing ripgrep..."
      rm -rf "$DIR" "$BIN" "$CHECK" >/dev/null 2>&1
      log "ripgrep removed"
      ;;
  esac
}


# ==========================================
# File: ./.bashrc.d/packages/ruby.sh
# ==========================================
pkg_ruby() {
  local action="$1"
  local RBENV="$HOME/.rbenv"
  local CHECK="$HOME/.local/share/bash_setup/checks/ruby.check"

  case "$action" in
    install | update)
      ensure_local_dirs
      need git || return 1

      if [[ ! -d "$RBENV" ]]; then
        has_internet || {
          log "No internet. Skipping rbenv."
          return 0
        }
        log "Installing rbenv..."
        git clone https://github.com/rbenv/rbenv.git "$RBENV" >/dev/null 2>&1 || return 1
        mkdir -p "$RBENV/plugins"
        git clone https://github.com/rbenv/ruby-build.git "$RBENV/plugins/ruby-build" >/dev/null 2>&1 || return 1

        (cd "$RBENV" && src/configure && make -C src) >/dev/null 2>&1 || true

        touch "$CHECK"
        log "rbenv ready (Ruby versions managed via config)"

      elif [[ "$action" == "update" ]] || [[ ! -f "$CHECK" ]] || [[ -n "$(find "$CHECK" -mtime +7 2>/dev/null)" ]]; then
        has_internet || {
          touch "$CHECK"
          return 0
        }
        log "Updating rbenv..."
        (cd "$RBENV" && git pull --rebase) >/dev/null 2>&1
        (cd "$RBENV/plugins/ruby-build" && git pull --rebase) >/dev/null 2>&1
        touch "$CHECK"
      fi
      ;;
    remove)
      log "Removing rbenv and managed Ruby versions..."
      rm -rf "$RBENV" "$CHECK" >/dev/null 2>&1
      log "Ruby removed"
      ;;
  esac
}


# ==========================================
# File: ./.bashrc.d/packages/rust.sh
# ==========================================
pkg_rust() {
  local action="$1"
  local CHECK="$HOME/.local/share/bash_setup/checks/rust.check"

  case "$action" in
    install | update)
      ensure_local_dirs
      local NEEDS_INSTALL=0

      if [[ ! -x "$HOME/.cargo/bin/rustc" ]]; then
        NEEDS_INSTALL=1
      elif [[ "$action" == "update" ]] || [[ ! -f "$CHECK" ]] || [[ -n "$(find "$CHECK" -mtime +7 2>/dev/null)" ]]; then
        has_internet || {
          touch "$CHECK"
          return 0
        }
        log "Checking for Rust toolchain updates..."
        "$HOME/.cargo/bin/rustup" update >/dev/null 2>&1 || true
        touch "$CHECK"
      fi

      if [[ $NEEDS_INSTALL -eq 1 ]]; then
        has_internet || {
          log "No internet. Skipping Rust."
          return 0
        }
        log "Installing Rustup..."

        curl -fsSL https://sh.rustup.rs -o /tmp/rustup.sh || {
          log "Failed to connect to Rustup servers."
          return 1
        }

        sh /tmp/rustup.sh -y --no-modify-path >/dev/null 2>&1 || return 1
        rm -f /tmp/rustup.sh

        touch "$CHECK"
        log "Rust ready"
      fi
      ;;
    remove)
      log "Removing Rust toolchain..."
      if command -v rustup >/dev/null 2>&1; then
        rustup self uninstall -y >/dev/null 2>&1
      fi
      rm -rf "$HOME/.cargo" "$HOME/.rustup" "$CHECK" >/dev/null 2>&1
      log "Rust removed"
      ;;
  esac
}


# ==========================================
# File: ./.bashrc.d/packages/shellcheck.sh
# ==========================================
pkg_shellcheck() {
  local action="$1"
  local DIR="$HOME/.local/opt/shellcheck"
  local BIN="$HOME/.local/bin/shellcheck"
  local CHECK="$HOME/.local/share/bash_setup/checks/shellcheck.check"

  case "$action" in
    install | update)
      ensure_local_dirs
      local ARCH="$(detect_arch)"
      local DL_ARCH=""
      case "$ARCH" in
        amd64) DL_ARCH="x86_64" ;;
        arm64) DL_ARCH="aarch64" ;;
        *) return 1 ;;
      esac

      local NEEDS_INSTALL=0
      local LOCAL_VER=""
      local REMOTE_VER=""

      if [[ ! -x "$BIN" ]]; then
        NEEDS_INSTALL=1
      elif [[ "$action" == "update" ]] || [[ ! -f "$CHECK" ]] || [[ -n "$(find "$CHECK" -mtime +7 2>/dev/null)" ]]; then
        LOCAL_VER="$("$BIN" --version | grep 'version:' | awk '{print $2}')"
        has_internet || {
          touch "$CHECK"
          return 0
        }

        # API Bypass
        REMOTE_VER="$(basename "$(curl -fsSLw "%{url_effective}" -o /dev/null "https://github.com/koalaman/shellcheck/releases/latest")")"

        if [[ -n "$REMOTE_VER" && "v${LOCAL_VER#v}" != "$REMOTE_VER" ]]; then
          NEEDS_INSTALL=1
          log "Shellcheck update available: $LOCAL_VER -> $REMOTE_VER"
        else
          touch "$CHECK"
        fi
      fi

      if [[ $NEEDS_INSTALL -eq 1 ]]; then
        has_internet || return 0
        [[ -z "$REMOTE_VER" ]] && REMOTE_VER="$(basename "$(curl -fsSLw "%{url_effective}" -o /dev/null "https://github.com/koalaman/shellcheck/releases/latest")")"

        if [[ -z "$REMOTE_VER" ]]; then
          log "Failed to fetch Shellcheck version. Skipping update."
          return 1
        fi

        local FILE="shellcheck-${REMOTE_VER}.linux.${DL_ARCH}.tar.xz"
        local URL="https://github.com/koalaman/shellcheck/releases/download/${REMOTE_VER}/$FILE"
        local TMP_DIR="/tmp/shellcheck_update_$RANDOM"

        mkdir -p "$TMP_DIR"

        if curl -fsSL "$URL" | tar -xJf - --strip-components=1 -C "$TMP_DIR" 2>/dev/null; then
          rm -rf "$DIR" >/dev/null 2>&1
          mv "$TMP_DIR" "$DIR" >/dev/null 2>&1
          ln -sf "$DIR/shellcheck" "$BIN"

          touch "$CHECK"
          log "Shellcheck ready"
        else
          log "Failed to download Shellcheck."
        fi
        rm -rf "$TMP_DIR" >/dev/null 2>&1
      fi
      ;;
    remove)
      log "Removing Shellcheck..."
      rm -rf "$DIR" "$BIN" "$CHECK" >/dev/null 2>&1
      log "Shellcheck removed"
      ;;
  esac
}


# ==========================================
# File: ./.bashrc.d/packages/starship.sh
# ==========================================
pkg_starship() {
  local action="$1"
  local DIR="$HOME/.local/opt/starship"
  local BIN="$HOME/.local/bin/starship"
  local CHECK="$HOME/.local/share/bash_setup/checks/starship.check"

  case "$action" in
    install | update)
      ensure_local_dirs
      local ARCH="$(detect_arch)"
      local DL_ARCH=""
      case "$ARCH" in
        amd64) DL_ARCH="x86_64-unknown-linux-musl" ;;
        arm64) DL_ARCH="aarch64-unknown-linux-musl" ;;
        *) return 1 ;;
      esac

      local NEEDS_INSTALL=0
      local LOCAL_VER=""
      local REMOTE_VER=""

      if [[ ! -x "$BIN" ]]; then
        NEEDS_INSTALL=1
      elif [[ "$action" == "update" ]] || [[ ! -f "$CHECK" ]] || [[ -n "$(find "$CHECK" -mtime +7 2>/dev/null)" ]]; then
        LOCAL_VER="$("$BIN" --version | awk '{print $2}' | sed 's/^v//')"
        has_internet || {
          log "No internet. Skipping Starship check."
          touch "$CHECK"
          return 0
        }

        # API Bypass
        REMOTE_VER="$(basename "$(curl -fsSLw "%{url_effective}" -o /dev/null "https://github.com/starship/starship/releases/latest")" | sed 's/^v//')"

        if [[ -n "$REMOTE_VER" && "$LOCAL_VER" != "$REMOTE_VER" ]]; then
          NEEDS_INSTALL=1
          log "Starship update available: $LOCAL_VER -> $REMOTE_VER"
        else
          touch "$CHECK"
        fi
      fi

      if [[ $NEEDS_INSTALL -eq 1 ]]; then
        has_internet || {
          log "No internet. Cannot download Starship."
          return 0
        }
        [[ -z "$REMOTE_VER" ]] && REMOTE_VER="$(basename "$(curl -fsSLw "%{url_effective}" -o /dev/null "https://github.com/starship/starship/releases/latest")" | sed 's/^v//')"

        if [[ -z "$REMOTE_VER" ]]; then
          log "Failed to fetch Starship version. Skipping update."
          return 1
        fi

        local FILE="starship-${DL_ARCH}.tar.gz"
        local URL="https://github.com/starship/starship/releases/download/v${REMOTE_VER}/$FILE"
        local TMP_DIR="/tmp/starship_update_$RANDOM"

        mkdir -p "$TMP_DIR"

        if curl -fsSL "$URL" | tar -xzf - -C "$TMP_DIR" 2>/dev/null; then
          rm -rf "$DIR" >/dev/null 2>&1
          mkdir -p "$DIR"
          mv "$TMP_DIR/starship" "$DIR/starship" >/dev/null 2>&1
          ln -sf "$DIR/starship" "$BIN"

          if [ ! -f "$HOME/.config/starship.toml" ]; then
            mkdir -p "$HOME/.config"
            "$BIN" preset plain-text-symbols -o "$HOME/.config/starship.toml"
          fi

          touch "$CHECK"
          log "Starship ready"
        fi
        rm -rf "$TMP_DIR" >/dev/null 2>&1
      fi
      ;;
    remove)
      log "Removing Starship..."
      rm -rf "$DIR" "$BIN" "$CHECK" >/dev/null 2>&1
      log "Starship removed"
      ;;
  esac
}


# ==========================================
# File: ./.bashrc.d/packages/uv.sh
# ==========================================
pkg_uv() {
  local action="$1"
  local BIN="$HOME/.local/bin/uv"
  local CHECK="$HOME/.local/share/bash_setup/checks/uv.check"

  case "$action" in
    install | update)
      ensure_local_dirs
      local ARCH="$(detect_arch)"
      local DL_ARCH=""
      case "$ARCH" in
        amd64) DL_ARCH="x86_64-unknown-linux-gnu" ;;
        arm64) DL_ARCH="aarch64-unknown-linux-gnu" ;;
        *) return 1 ;;
      esac

      local NEEDS_INSTALL=0
      local LOCAL_VER=""
      local REMOTE_VER=""

      if [[ ! -x "$BIN" ]]; then
        NEEDS_INSTALL=1
      elif [[ "$action" == "update" ]] || [[ ! -f "$CHECK" ]] || [[ -n "$(find "$CHECK" -mtime +7 2>/dev/null)" ]]; then
        LOCAL_VER="$("$BIN" --version | awk '{print $2}')"
        has_internet || {
          touch "$CHECK"
          return 0
        }

        # API Bypass
        REMOTE_VER="$(basename "$(curl -fsSLw "%{url_effective}" -o /dev/null "https://github.com/astral-sh/uv/releases/latest")" | sed 's/^v//')"

        if [[ -n "$REMOTE_VER" && "$LOCAL_VER" != "$REMOTE_VER" ]]; then
          NEEDS_INSTALL=1
          log "uv update available: $LOCAL_VER -> $REMOTE_VER"
        else
          touch "$CHECK"
        fi
      fi

      if [[ $NEEDS_INSTALL -eq 1 ]]; then
        has_internet || return 0
        [[ -z "$REMOTE_VER" ]] && REMOTE_VER="$(basename "$(curl -fsSLw "%{url_effective}" -o /dev/null "https://github.com/astral-sh/uv/releases/latest")" | sed 's/^v//')"

        if [[ -z "$REMOTE_VER" ]]; then
          log "Failed to fetch uv version. Skipping update."
          return 1
        fi

        local FILE="uv-${DL_ARCH}.tar.gz"
        local URL="https://github.com/astral-sh/uv/releases/download/${REMOTE_VER}/$FILE"
        local TMP_DIR="/tmp/uv_$RANDOM"

        mkdir -p "$TMP_DIR"
        if curl -fsSL "$URL" | tar -xzf - -C "$TMP_DIR" --strip-components=1 2>/dev/null; then
          mv "$TMP_DIR/uv" "$BIN" >/dev/null 2>&1
          mv "$TMP_DIR/uvx" "$HOME/.local/bin/uvx" 2>/dev/null || true
          touch "$CHECK"
          log "uv ready"
        else
          log "Failed to download uv."
        fi
        rm -rf "$TMP_DIR" >/dev/null 2>&1
      fi
      ;;
    remove)
      log "Removing uv..."
      rm -rf "$BIN" "$HOME/.local/bin/uvx" "$CHECK" >/dev/null 2>&1
      log "uv removed. (Environments in ~/.local/share/uv retained)"
      ;;
  esac
}


# ==========================================
# File: ./.bashrc.d/source/00-path.sh
# ==========================================
add_path() {
  case ":$PATH:" in
    *":$1:"*) ;;
    *) PATH="$1:$PATH" ;;
  esac
}

add_path "$HOME/.local/bin"

export PATH


# ==========================================
# File: ./.bashrc.d/source/01-env.sh
# ==========================================
# ~/.bashrc.d/source/00-env.sh

# --- Display & UI ---
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --info=inline --color='header:italic'"

# --- Editor ---
export EDITOR
if command -v nvim >/dev/null 2>&1; then
  EDITOR="$(command -v nvim)"
elif command -v vim >/dev/null 2>&1; then
  EDITOR="$(command -v vim)"
elif command -v nano >/dev/null 2>&1; then
  EDITOR="$(command -v nano)"
fi

if [[ -n "$EDITOR" ]]; then
  export VISUAL="$EDITOR"
  export SUDO_EDITOR="$EDITOR"
fi

# Enable Vim keystrokes in bash (Required for ble.sh Vi mode)
set -o vi

# --- Native Bash Completion (Crucial for Carapace/ble.sh) ---
if [[ -z "$BASH_COMPLETION_VERSINFO" ]] && [[ -f /usr/share/bash-completion/bash_completion ]]; then
  source /usr/share/bash-completion/bash_completion
fi

# --- History ---
export HISTFILE="$HOME/.bash_history"
export HISTSIZE=100000
export HISTFILESIZE=200000
export HISTCONTROL=ignoredups:erasedups
export HISTTIMEFORMAT="%F %T "

shopt -s cmdhist
shopt -s lithist
shopt -s histappend


# ==========================================
# File: ./.bashrc.d/source/02-functions.sh
# ==========================================
# ~/.bashrc.d/source/02-functions.sh
has_internet() {
  # Try to fetch headers from GitHub API silently, timeout after 3 seconds
  if curl -Is --connect-timeout 3 https://api.github.com >/dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

# --- INTERACTIVE CONDA TOGGLE ---
conda_toggle_env() {
  if ! command -v conda &>/dev/null; then
    return 1
  fi

  local current_env="${CONDA_DEFAULT_ENV:-}"
  local selected_env
  local deactivate_opt="[Deactivate Conda -> System Python]"

  selected_env=$(
    (
      echo "$deactivate_opt"
      conda env list | awk '{print $1}' | grep -vE '^(#|$)'
    ) | fzf --height 40% --layout=reverse --border --prompt="Select Conda Env: "
  )

  [[ -z "$selected_env" ]] && return 0

  if [[ "$selected_env" == "$deactivate_opt" ]]; then
    while [[ -n "$CONDA_DEFAULT_ENV" ]]; do
      conda deactivate
    done
    return 0
  fi

  if [[ "$selected_env" == "$current_env" ]]; then
    return 0
  fi

  [[ -n "$current_env" ]] && conda deactivate
  conda activate "$selected_env"
}

# --- DIRECTORY LOGGER ---
log_recent_dir() {
  local DIR="$PWD"
  local FILE="$HOME/.recent_dirs"
  [[ "$DIR" == "$LAST_LOGGED_DIR" ]] && return

  LAST_LOGGED_DIR="$DIR"
  grep -Fxv "$DIR" "$FILE" 2>/dev/null >"$FILE.tmp"
  echo "$DIR" >>"$FILE.tmp"
  mv "$FILE.tmp" "$FILE" >/dev/null 2>&1
  tail -n 50 "$FILE" >"$FILE.tmp" && mv "$FILE.tmp" "$FILE" >/dev/null 2>&1
}

# --- PROMPT COMMAND ---
# Combine history sync and directory logging safely
PROMPT_COMMAND="history -a; history -n; log_recent_dir"


# ==========================================
# File: ./.bashrc.d/source/03-aliases.sh
# ==========================================
# ~/.bashrc.d/source/01-aliases.sh

alias c='clear'
alias q='exit'
alias ..='cd ..'
alias cp='cp -v'
alias mv='mv -v'
alias rm='rm -v'
alias mkdir='mkdir -v'
alias grep='grep --color=auto'


# ==========================================
# File: ./.bashrc.d/source-pkg/00-blesh.sh
# ==========================================
#!/usr/bin/env bash

# interactive shell only
[[ $- == *i* ]] || return 0

# must have real terminal
[[ -t 0 && -t 1 ]] || return 0

BLESH_SCRIPT="$HOME/.local/share/blesh/ble.sh"

[[ -f "$BLESH_SCRIPT" ]] && source "$BLESH_SCRIPT" --noattach


# ==========================================
# File: ./.bashrc.d/source-pkg/10-nvm.sh
# ==========================================
#!/usr/bin/env bash

export NVM_DIR="$HOME/.nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] || return 0

# Alpine musl builds
[[ -f /etc/alpine-release ]] &&
  export NVM_NODEJS_ORG_MIRROR="https://unofficial-builds.nodejs.org/download/release"

source "$NVM_DIR/nvm.sh"

nvm use default >/dev/null 2>&1


# ==========================================
# File: ./.bashrc.d/source-pkg/11-java.sh
# ==========================================
#!/usr/bin/env bash

export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] || return 0

source "$SDKMAN_DIR/bin/sdkman-init.sh"


# ==========================================
# File: ./.bashrc.d/source-pkg/12-ruby.sh
# ==========================================
#!/usr/bin/env bash

add_path "$HOME/.rbenv/bin"
add_path "$HOME/.rbenv/shims"

command -v rbenv >/dev/null 2>&1 || return 0

eval "$(rbenv init - bash)"


# ==========================================
# File: ./.bashrc.d/source-pkg/13-php.sh
# ==========================================
#!/usr/bin/env bash

[[ -s "$HOME/.phpbrew/bashrc" ]] || return 0

source "$HOME/.phpbrew/bashrc"


# ==========================================
# File: ./.bashrc.d/source-pkg/14-micromamba.sh
# ==========================================
#!/usr/bin/env bash

command -v micromamba >/dev/null 2>&1 || return 0

export MAMBA_ROOT_PREFIX="${MAMBA_ROOT_PREFIX:-$HOME/micromamba}"

eval "$(micromamba shell hook -s bash)"

if micromamba env list 2>/dev/null | awk '{print $1}' | grep -qx user; then
  micromamba activate user >/dev/null 2>&1
fi


# ==========================================
# File: ./.bashrc.d/source-pkg/15-rust.sh
# ==========================================
#!/usr/bin/env bash

add_path "$HOME/.cargo/bin"


# ==========================================
# File: ./.bashrc.d/source-pkg/16-go.sh
# ==========================================
#!/usr/bin/env bash

export GOPATH="$HOME/go"
export GOBIN="$GOPATH/bin"

add_path "$HOME/.local/opt/go/bin"
add_path "$GOBIN"


# ==========================================
# File: ./.bashrc.d/source-pkg/50-fzf.sh
# ==========================================
#!/usr/bin/env bash

command -v fzf >/dev/null 2>&1 && eval "$(fzf --bash)"


# ==========================================
# File: ./.bashrc.d/source-pkg/51-carapace.sh
# ==========================================
#!/usr/bin/env bash

command -v carapace >/dev/null 2>&1 && eval "$(carapace _carapace)"


# ==========================================
# File: ./.bashrc.d/source-pkg/52-starship.sh
# ==========================================
#!/usr/bin/env bash

command -v starship >/dev/null 2>&1 && eval "$(starship init bash)"


# ==========================================
# File: ./.bashrc.d/source-pkg/99-blesh.sh
# ==========================================
#!/usr/bin/env bash

[[ $- == *i* ]] || return 0
[[ -t 0 && -t 1 ]] || return 0

[[ ${BLE_VERSION-} ]] && ble-attach


# ==========================================
# File: ./.bashrc.d/tool/list.sh
# ==========================================
#!/usr/bin/env bash

tool_list() {
  local pkg_dir="$HOME/.bashrc.d/packages"

  echo "Available Primary Packages:"

  # Check if directory exists and has files
  if [[ -d "$pkg_dir" ]]; then
    for pkg in "$pkg_dir"/*.sh; do
      [[ -f "$pkg" ]] || continue
      # Print the filename without the .sh extension
      basename "$pkg" .sh | awk '{print "  - " $0}'
    done
  else
    echo "  (No packages directory found)"
  fi

  echo ""
  echo "To install sub-packages (formatters/linters), edit:"
  echo "  ~/.bashrc.d/global_tools.conf"
}


# ==========================================
# File: ./.bashrc.d/tool/pkg.sh
# ==========================================
#!/usr/bin/env bash

tool_pkg() {
  local action="$1"
  shift # Remove 'install/update/remove' from the argument list

  # local pkg_dir="$HOME/.bashrc.d/packages"

  # Check if at least one target was provided
  if [[ $# -eq 0 ]]; then
    echo "Usage: tool pkg {install|update|remove} <name1> [name2...] [all]"
    return 1
  fi

  # Check if 'all' is among the arguments
  local run_all=0
  for arg in "$@"; do
    if [[ "$arg" == "all" ]]; then
      run_all=1
      break
    fi
  done

  if [[ $run_all -eq 1 ]]; then
    log "Starting global '$action' for all tools..."
    local ordered_pkgs=("nvm" "uv" "rust" "go" "java" "julia" "php" "micromamba" "ruby" "fzf" "starship" "carapace" "blesh" "nvim" "ripgrep" "fd" "shellcheck" "composer")
    for pkg in "${ordered_pkgs[@]}"; do
      _exec_pkg "$pkg" "$action"
    done
  else
    # Process every package name passed in the command line
    for target in "$@"; do
      _exec_pkg "$target" "$action"
    done
  fi
}

_exec_pkg() {
  local name="$1"
  local act="$2"
  local file="$HOME/.bashrc.d/packages/${name}.sh"

  if [[ -f "$file" ]]; then
    (
      # Sourcing is safe here as tool.sh already created the subshell
      source "$file"
      "pkg_${name//-/_}" "$act"
    )
  else
    echo "Error: Package '$name' not found in $HOME/.bashrc.d/packages/"
  fi
}


# ==========================================
# File: ./.bashrc.d/tool/sub-pkg.sh
# ==========================================
#!/usr/bin/env bash

tool_sub_pkg() {
  local manager="$1"
  local action="$2"
  local target="$3"
  local conf_file="$HOME/.bashrc.d/global_tools.conf"

  [[ -z "$manager" || -z "$action" || -z "$target" ]] && {
    echo "Usage: tool sub-pkg {npm|cargo|rustup|go} {install|update|remove} <name|all>"
    return 1
  }

  # Guard: Check if manager exists
  if ! command -v "$manager" >/dev/null 2>&1; then
    log "Error: '$manager' not found on system."
    return 1
  fi

  local pkgs_to_process=""

  if [[ "$target" == "all" ]]; then
    [[ ! -f "$conf_file" ]] && {
      echo "No config file found."
      return 1
    }
    pkgs_to_process="$(
      awk -v mgr="$manager" '
        BEGIN { in_section=0 }

        {
          line = $0

          # remove leading/trailing whitespace
          gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)

          # skip empty lines
          if (line == "") next

          # skip full-line comments
          if (line ~ /^#/) next

          # section headers
          if (line ~ /^\[.*\]$/) {
            in_section = (line == "[" mgr "]")
            next
          }

          # inside section: strip inline comments
          if (in_section) {
            sub(/[[:space:]]+#.*$/, "", line)
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)

            if (line != "")
              print line
          }
        }
      ' "$conf_file"
    )"
  else
    pkgs_to_process="$target"
  fi

  [[ -z "${pkgs_to_process// /}" ]] && {
    log "No packages defined for $manager."
    return 0
  }

  log "$action-ing $manager sub-packages: $pkgs_to_process"

  case "$manager" in
    npm)
      [[ "$action" == "remove" ]] && npm uninstall -g $pkgs_to_process || npm install -g $pkgs_to_process
      ;;
    cargo)
      [[ "$action" == "remove" ]] && cargo uninstall $pkgs_to_process || cargo install $pkgs_to_process
      ;;
    rustup)
      [[ "$action" == "remove" ]] && rustup component remove $pkgs_to_process || rustup component add $pkgs_to_process
      ;;
    go)
      for p in $pkgs_to_process; do
        if [[ "$action" == "remove" ]]; then
          rm -f "$HOME/.local/share/go/bin/$(basename "$p" | cut -d@ -f1)"
        else
          GOPATH="$HOME/.local/share/go" go install "$p" >/dev/null 2>&1
        fi
      done
      ;;
  esac
}


# ==========================================
# File: ./.bashrc.d/tool/sync.sh
# ==========================================
#!/usr/bin/env bash

tool_sync() {
  local args=("$@")

  [[ ${#args[@]} -eq 0 ]] && args=("all")

  for item in "${args[@]}"; do
    case "$item" in
      all)
        _sync_pkg_managers
        _sync_languages
        _sync_sub_packages
        ;;
      node | nvm)
        _sync_node
        ;;
      python | micromamba)
        _sync_python
        ;;
      java)
        _sync_java
        ;;
      ruby)
        _sync_ruby
        ;;
      php)
        _sync_php
        ;;
      go)
        _sync_go
        ;;
      rust)
        _sync_rust
        ;;
      *)
        echo "Unknown sync target: $item"
        ;;
    esac
  done
}

_sync_pkg_managers() {
  tool pkg install nvm micromamba java ruby php rust go
}

_sync_languages() {
  _sync_node
  _sync_python
  _sync_java
  _sync_ruby
  _sync_php
}

_sync_sub_packages() {
  tool sub-pkg npm install all
  tool sub-pkg rustup install all
  tool sub-pkg cargo install all
  tool sub-pkg go install all
}

_sync_node() {
  export NVM_DIR="$HOME/.nvm"
  [[ -s "$NVM_DIR/nvm.sh" ]] || return 0

  [[ -f /etc/alpine-release ]] &&
    export NVM_NODEJS_ORG_MIRROR="https://unofficial-builds.nodejs.org/download/release"

  source "$NVM_DIR/nvm.sh"

  source "$HOME/.bashrc.d/global_source.conf" 2>/dev/null

  local ver="${VERSION_NVM:-22}"

  log "Syncing Node $ver"
  nvm install "$ver"
  nvm alias default "$ver"
}

_sync_python() {
  command -v micromamba >/dev/null 2>&1 || return 0

  source "$HOME/.bashrc.d/global_source.conf" 2>/dev/null

  local ver="${VERSION_PYTHON:-3.12}"
  local root="$HOME/micromamba"

  log "Syncing Python $ver in env user"

  micromamba create -y -n user -c conda-forge "python=$ver" -r "$root" >/dev/null 2>&1 ||
    micromamba install -y -n user -c conda-forge "python=$ver" -r "$root"
}

_sync_java() {
  export SDKMAN_DIR="$HOME/.sdkman"
  [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] || return 0

  source "$SDKMAN_DIR/bin/sdkman-init.sh"
  source "$HOME/.bashrc.d/global_source.conf" 2>/dev/null

  local ver="${VERSION_JAVA:-21}"

  log "Syncing Java $ver"
  sdk install java "$ver"
  sdk default java "$ver"
}

_sync_ruby() {
  add_path "$HOME/.rbenv/bin"

  command -v rbenv >/dev/null 2>&1 || return 0
  eval "$(rbenv init - bash)"

  source "$HOME/.bashrc.d/global_source.conf" 2>/dev/null

  local ver="${VERSION_RUBY:-3.3.6}"

  log "Syncing Ruby $ver"
  rbenv install -s "$ver"
  rbenv global "$ver"
}

_sync_php() {
  [[ -s "$HOME/.phpbrew/bashrc" ]] || return 0

  source "$HOME/.phpbrew/bashrc"
  source "$HOME/.bashrc.d/global_source.conf" 2>/dev/null

  local ver="${VERSION_PHP:-8.3.4}"

  log "Syncing PHP $ver"
  phpbrew install "$ver" +default
  phpbrew switch "$ver"
}

_sync_go() {
  tool pkg install go
  tool sub-pkg go install all
}

_sync_rust() {
  tool pkg install rust
  tool sub-pkg rustup install all
  tool sub-pkg cargo install all
}


# ==========================================
# File: ./.bashrc.d/tool/sys.sh
# ==========================================
tool_sys() {
  echo "$@"
}


