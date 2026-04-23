source_miniconda() {
  local CONDA_DIR="$HOME/miniconda3"
  [[ -d "$CONDA_DIR" ]] || return 0

  __conda_setup="$("$CONDA_DIR/bin/conda" shell.bash hook 2>/dev/null)"

  if [[ $? -eq 0 ]]; then
    eval "$__conda_setup"
  else
    export PATH="$CONDA_DIR/bin:$PATH"
    return 0
  fi

  unset __conda_setup
  conda activate user >/dev/null 2>&1 || true
}
