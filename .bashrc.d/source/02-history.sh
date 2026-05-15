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
pwd:clear:c:\
exit:q:\
history*:\
bg:fg:jobs:\
btop:htop:*ps"

shopt -s histappend
shopt -s cmdhist
shopt -s lithist

PROMPT_COMMAND+=("history -a" "history -n")

_async_history_clean() {
  local marker="$HOME/.cache/bash_history_cleaner.marker"
  local hist_file="$HOME/.bash_history"

  mkdir -p "$HOME/.cache"

  # Check marker (bails out if younger than 60 mins)
  if [[ -f "$marker" ]] && [[ -z $(find "$marker" -mmin +60 2>/dev/null) ]]; then
    return 0
  fi
  touch "$marker"

  # Background process
  (
    local tmp_file="${hist_file}.tmp"
    >"$tmp_file" # Ensure temp file is empty

    # Split your dynamic HISTIGNORE variable by colons into an array
    IFS=':' read -ra ignore_patterns <<<"$HISTIGNORE"

    # Associative array to track duplicates
    local -A seen
    local skip_next_timestamp=false

    # Process the file backwards using tac
    while IFS= read -r line; do

      # If the line is a timestamp (e.g., #1684000010)
      if [[ "$line" =~ ^#[0-9]+$ ]]; then
        if [[ "$skip_next_timestamp" == true ]]; then
          skip_next_timestamp=false # Reset and drop this timestamp
        else
          echo "$line" >>"$tmp_file" # Keep it
        fi

      # If the line is a command
      else
        local cmd="$line"
        local should_ignore=false

        # 1. Exact HISTIGNORE matching
        for pattern in "${ignore_patterns[@]}"; do
          # Note: $pattern is intentionally unquoted here so Bash treats it
          # as a native glob pattern exactly like HISTIGNORE does.
          if [[ "$cmd" == $pattern ]]; then
            should_ignore=true
            break
          fi
        done

        # 2. Duplicate matching
        if [[ -n "${seen[$cmd]}" ]]; then
          should_ignore=true
        fi

        # 3. Action
        if [[ "$should_ignore" == true ]]; then
          skip_next_timestamp=true # Drop this command and flag its timestamp
        else
          echo "$cmd" >>"$tmp_file" # Keep this command
          seen["$cmd"]=1
          skip_next_timestamp=false
        fi
      fi
    done < <(tac "$hist_file")

    # Reverse it back and safely overwrite the original history file
    tac "$tmp_file" >"$hist_file"
    rm -f "$tmp_file"
  ) >/dev/null 2>&1 &
  disown
}

# Trigger the check instantly on boot
_async_history_clean
