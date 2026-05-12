# --- History ---
export HISTFILE="$HOME/.bash_history"
export HISTSIZE=500000
export HISTFILESIZE=1000000
export HISTCONTROL=ignoredups:erasedups
export HISTIGNORE="&:[ ]*"
export HISTTIMEFORMAT="%F %T "

shopt -s histappend
shopt -s cmdhist
shopt -s lithist

PROMPT_COMMAND+=(
  "history -a"
  "history -c"
  "history -r"
  "log_recent_dir"
)
