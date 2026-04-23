install_or_update_miniconda() {
  ensure_local_dirs

  local CONDA_DIR="$HOME/miniconda3"
  local CHECK_DIR="$HOME/.local/share/bash_setup/checks"
  local CHECK_FILE="$CHECK_DIR/miniconda.check"

  local ARCH=""
  local FILE=""
  local URL=""

  need_any curl wget || return 1

  if [[ -d "$CONDA_DIR" ]]; then
    log "Miniconda already installed"
    touch "$CHECK_FILE"
    return 0
  fi

  ARCH="$(detect_arch)"

  case "$ARCH" in
    amd64) FILE="Miniconda3-latest-Linux-x86_64.sh" ;;
    arm64) FILE="Miniconda3-latest-Linux-aarch64.sh" ;;
    *)
      die "Unsupported architecture: $ARCH"
      return 1
      ;;
  esac

  URL="https://repo.anaconda.com/miniconda/$FILE"

  log "Installing Miniconda..."

  curl -fsSL "$URL" -o /tmp/miniconda.sh >/dev/null 2>&1 || return 1

  bash /tmp/miniconda.sh -b -p "$CONDA_DIR" >/dev/null 2>&1 || return 1

  rm -f /tmp/miniconda.sh

  "$CONDA_DIR/bin/conda" config --system --set auto_activate_base false >/dev/null 2>&1 || true
  "$CONDA_DIR/bin/conda" tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main >/dev/null 2>&1 || true
  "$CONDA_DIR/bin/conda" tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r >/dev/null 2>&1 || true
  "$CONDA_DIR/bin/conda" create -n user python=3.12 pip -y >/dev/null 2>&1 || true

  touch "$CHECK_FILE"

  log "Miniconda ready"
}
