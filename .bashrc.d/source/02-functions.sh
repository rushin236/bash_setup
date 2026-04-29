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
  mv "$FILE.tmp" "$FILE"
  tail -n 50 "$FILE" >"$FILE.tmp" && mv "$FILE.tmp" "$FILE"
}

# --- PROMPT COMMAND ---
# Combine history sync and directory logging safely
PROMPT_COMMAND="history -a; history -n; log_recent_dir"
