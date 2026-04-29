# ~/.bashrc

# 1. Foundation
if [[ -f "$HOME/.bashrc.d/00-foundation.sh" ]]; then
  source "$HOME/.bashrc.d/00-foundation.sh"
fi

if [[ -f "$HOME/.bashrc.d/01-fetch.sh" ]]; then
  source "$HOME/.bashrc.d/01-fetch.sh"
fi

# 2. Tool CLI Engine
if [[ -f "$HOME/.bashrc.d/02-tool.sh" ]]; then
  source "$HOME/.bashrc.d/02-tool.sh"
fi

# 3. Core Environment
if [[ -d "$HOME/.bashrc.d/source" ]]; then
  for file in "$HOME/.bashrc.d/source"/*.sh; do
    [[ -f "$file" ]] && source "$file"
  done
fi

# 4. Package Initializers & Environment Sync
if [[ -d "$HOME/.bashrc.d/source-pkg" ]]; then
  # Because of the numbers, 00-blesh-init runs first, and 99-blesh-attach runs last!
  for file in "$HOME/.bashrc.d/source-pkg"/*.sh; do
    [[ -f "$file" ]] && source "$file"
  done
fi
