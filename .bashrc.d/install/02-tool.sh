tool() {
  local cmd="$1"
  local target="$2"

  case "$cmd:$target" in
    install:fzf) install_or_update_fzf ;;
    install:nvim) install_or_update_nvim ;;
    install:starship) install_or_update_starship ;;
    install:carapace) install_or_update_carapace ;;
    install:blesh) install_or_update_blesh ;;
    # install:miniconda) install_or_update_miniconda ;;
    install:nvm) install_or_update_nvm ;;
    install:rust) install_or_update_rust ;;
    install:go) install_or_update_go ;;
    install:ripgrep) install_or_update_ripgrep ;;
    install:fd) install_or_update_fd ;;
    install:stylua) install_or_update_stylua ;;
    install:tree-sitter) install_or_update_tree_sitter ;;
    # install:rust-extra) install_or_update_rust_extra ;;
    install:shellcheck) install_or_update_shellcheck ;;
    install:shfmt) install_or_update_shfmt ;;
    install:markdown-toc) install_or_update_markdown_toc ;;
    # install:ruby) install_or_update_ruby ;;
    # install:composer) install_or_update_composer ;;
    # install:java) install_or_update_java ;;
    # install:julia) install_or_update_julia ;;

    install:all)
      install_or_update_fzf
      install_or_update_nvim
      install_or_update_starship
      install_or_update_carapace
      install_or_update_blesh
      # install_or_update_miniconda
      install_or_update_nvm
      install_or_update_rust
      install_or_update_go
      install_or_update_ripgrep
      install_or_update_fd
      install_or_update_stylua
      install_or_update_tree_sitter
      # install_or_update_rust_extra
      install_or_update_shellcheck
      install_or_update_shfmt
      install_or_update_markdown_toc
      # install_or_update_ruby
      # install_or_update_composer
      # install_or_update_java
      # install_or_update_julia
      ;;
    *)
      echo "Usage: tool install {fzf|nvim|starship|carapace|blesh|all}"
      ;;
  esac
}
