# ~/.bashrc.d/source/03-history.sh

# --- History ---
export HISTFILE="$HOME/.bash_history"
export HISTSIZE=50000
export HISTFILESIZE=200000
export HISTCONTROL=ignoreboth:erasedups
export HISTTIMEFORMAT="%F %T "
export HISTIGNORE="\
ls:ll:la:l:ls -al:\
cd:cd ..:cd ~:\
pwd:clear:\
exit:q:\
history*:\
*ps"

shopt -s histappend
shopt -s cmdhist
shopt -s lithist

PROMPT_COMMAND+=("history -a" "history -n")

_async_history_clean() {
  local marker="$HOME/.cache/bash_history_cleaner.marker"
  local hist_file="$HOME/.bash_history"

  # 1. Ensure the cache directory exists
  mkdir -p "$HOME/.cache"

  # 2. Check if the marker exists and is YOUNGER than 60 minutes.
  # If it is, exit instantly to keep startup at 0ms.
  if [[ -f "$marker" ]] && [[ -z $(find "$marker" -mmin +60 2>/dev/null) ]]; then
    return 0
  fi

  # 3. Touch the marker immediately so other terminal tabs don't trigger it
  touch "$marker"

  # 4. Run the heavy cleaner in an isolated, disowned background process
  (
    # Create a temporary file
    local tmp_file="${hist_file}.tmp"

    # Run your exact awk cleaner logic
    tac "$hist_file" | awk 'NR%2==1 {cmd=$0; next} {if (!seen[cmd]++) {print cmd; print $0}}' | tac >"$tmp_file"

    # Safely overwrite the original
    mv "$tmp_file" "$hist_file"
  ) >/dev/null 2>&1 &
  disown
}

# Trigger the check instantly on boot
_async_history_clean
