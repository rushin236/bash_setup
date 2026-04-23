add_path() {
  case ":$PATH:" in
    *":$1:"*) ;;
    *) PATH="$1:$PATH" ;;
  esac
}

add_path "$HOME/.local/bin"
add_path "$HOME/.cargo/bin"
add_path "$HOME/.local/opt/go/bin"
add_path "$HOME/.rbenv/bin"
add_path "$HOME/.rbenv/shims"

export PATH
