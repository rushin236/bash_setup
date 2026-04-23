# ~/.bash_profile

# --- GUI / Window Manager Environment ---
export QT_QPA_PLATFORMTHEME=qt5ct

# --- Global PATH Setup ---
# Ensure local bin exists and is added to PATH for the entire session
mkdir -p "$HOME/.local/bin"
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) export PATH="$HOME/.local/bin:$PATH" ;;
esac

# --- Load Interactive Shell Settings ---
[[ -f ~/.bashrc ]] && . ~/.bashrc
