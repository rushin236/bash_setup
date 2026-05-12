# ~/.bashrc.d/source/03-history.sh

# --- History ---
export HISTFILE="$HOME/.bash_history"
export HISTSIZE=20000
export HISTFILESIZE=50000
export HISTCONTROL=ignoreboth:erasedups
export HISTIGNORE="&:[ ]*"
export HISTTIMEFORMAT="%F %T "

shopt -s histappend
shopt -s cmdhist
shopt -s lithist

PROMPT_COMMAND='history -a; history -n'
