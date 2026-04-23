# Initial source
source ~/.bashrc.d/install/00-foundation.sh
source ~/.bashrc.d/install/01-fetch.sh
source ~/.bashrc.d/install/02-tool.sh

source ~/.bashrc.d/source/00-path.sh
source ~/.bashrc.d/source/01-env.sh
source ~/.bashrc.d/source/02-functions.sh
source ~/.bashrc.d/source/03-aliases.sh

# Install update tools
source ~/.bashrc.d/install/10-fzf.sh
source ~/.bashrc.d/install/11-starship.sh
source ~/.bashrc.d/install/12-carapace.sh
source ~/.bashrc.d/install/13-blesh.sh

# Install once tools
# source ~/.bashrc.d/install/20-miniconda.sh
source ~/.bashrc.d/install/21-nvm.sh
source ~/.bashrc.d/install/22-nvim.sh
source ~/.bashrc.d/install/23-rust.sh
source ~/.bashrc.d/install/24-go.sh
source ~/.bashrc.d/install/25-ripgrep.sh
source ~/.bashrc.d/install/26-fd.sh
source ~/.bashrc.d/install/27-stylua.sh
source ~/.bashrc.d/install/28-tree-sitter.sh
source ~/.bashrc.d/install/28-tree-sitter.sh
# source ~/.bashrc.d/install/29-rust-extra.sh
source ~/.bashrc.d/install/30-shellcheck.sh
source ~/.bashrc.d/install/31-shfmt.sh
source ~/.bashrc.d/install/32-markdown-toc.sh
# source ~/.bashrc.d/install/33-ruby.sh
# source ~/.bashrc.d/install/34-composer.sh
# source ~/.bashrc.d/install/35-java.sh
# source ~/.bashrc.d/install/36-julia.sh

# Source all tool scripts first
source ~/.bashrc.d/source/10-fzf.sh
source ~/.bashrc.d/source/11-starship.sh
source ~/.bashrc.d/source/12-carapace.sh
source ~/.bashrc.d/source/13-blesh.sh
source ~/.bashrc.d/source/20-miniconda.sh
source ~/.bashrc.d/source/21-nvm.sh

source_blesh
source_miniconda
source_nvm
source_fzf
source_carapace
source_starship
attach_blesh
