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
