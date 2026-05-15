# ~/.bashrc.d/source/03-history.sh

# --- History ---
export HISTFILE="$HOME/.bash_history"
export HISTSIZE=100000
export HISTFILESIZE=200000
export HISTCONTROL=ignoreboth:erasedups
export HISTTIMEFORMAT="%F %T "

shopt -s histappend
shopt -s cmdhist
shopt -s lithist

PROMPT_COMMAND+=("history -a" "history -n")
