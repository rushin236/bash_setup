# --- History ---
export HISTFILE="$HOME/.bash_history"
export HISTSIZE=500000
export HISTFILESIZE=1000000
export HISTCONTROL=ignoreboth:erasedups
export HISTIGNORE="&:[ ]*"
export HISTTIMEFORMAT="%F %T "

shopt -s histappend
shopt -s cmdhist
shopt -s lithist

PROMPT_COMMAND+=(
  "history -a"
  "history -n"
  "log_recent_dir"
)
