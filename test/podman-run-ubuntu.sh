run_ubuntu_amd64() { _run_ubuntu_logic "amd64"; }
run_ubuntu_arm64() { _run_ubuntu_logic "arm64"; }

_run_ubuntu_logic() {
  local arch=$1
  CNAME="test-run-ubuntu-$arch"
  podman rm -f $CNAME 2>/dev/null || true
  podman run --rm -i \
    --platform "linux/$arch" \
    -v "$PWD:/workspace:Z" \
    --name $CNAME ubuntu:latest bash -s <<'EOF'
set -exo pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get update >/dev/null

apt-get install -y bash git curl wget tar gzip xz-utils unzip zip bzip2 passwd sudo \
procps make gcc g++ grep sed gawk findutils coreutils libffi-dev libyaml-dev libssl-dev \
zlib1g-dev libreadline-dev libgmp-dev lua5.4 liblua5.4-dev luarocks jq tmux \
imagemagick ghostscript pandoc sqlite3 bat btop ncdu pkg-config \
libfontconfig1-dev libfreetype6-dev libharfbuzz-dev libsqlite3-dev \
libicu-dev libcurl4-openssl-dev libpng-dev libgraphite2-dev \
autoconf bison re2c libxml2-dev libonig-dev libzip-dev 1>/dev/null

# Fix the Debian 'bat' naming conflict so validation passes
ln -sf /usr/bin/batcat /usr/local/bin/bat

useradd -m -s /bin/bash tester
echo "tester ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
cp -r /workspace /home/tester/project && chown -R tester:tester /home/tester

su - tester -c 'bash -l -s' <<'INNER_EOF'
echo "--- COPYING FILES ---"
mkdir -p ~/.config
cp ~/project/.bashrc ~/.bashrc
cp ~/project/.bash_profile ~/.bash_profile
cp ~/project/.blerc ~/.blerc
cp -r ~/project/.bashrc.d ~/.bashrc.d
cp ~/project/.config/starship.toml ~/.config
. ~/.bashrc

echo "--- INSTALLATION ---"
tool pkg install all
tool sync all

validate() {
  local cmd="$1"
  shift

  if command -v "$cmd" >/dev/null 2>&1; then
    local ver

    ver="$("$cmd" "$@" 2>/dev/null | head -n 1)"

    printf "PASS %-18s %s\n" "$cmd" "${ver:-unknown}"
  else
    printf "FAIL %-18s\n" "$cmd"
  fi
}

echo "--- VALIDATION ---"
VALIDATIONS=(
  "fzf --version" "nvim --version" "starship --version" "carapace --version"
  "uv --version" "python --version" "pip --version" "node --version"
  "npm --version" "rustc --version" "cargo --version" "rustfmt --version"
  "clippy-driver --version" "go version" "shellcheck --version" "shfmt --version"
  "ruby --version" "gem --version" "markdown-toc --version" "php --version"
  "composer --version" "java --version" "javac --version" "julia --version"
  "lua -v" "luarocks --version" "jq --version" "yq --version" "tmux -V"
  "magick --version" "gs --version" "lazygit --version" "delta --version"
  "pandoc --version" "sqlite3 --version" "bat --version" "eza --version"
  "zoxide --version" "btop --version" "ncdu --version" "tectonic --version"
)

for item in "${VALIDATIONS[@]}"; do
  cmd="${item%% *}"
  args="${item#"$cmd"}"

  if [[ "$cmd" == "$args" ]]; then
    validate "$cmd"
  else
    validate "$cmd" $args
  fi
done

echo "--- TIMING ---"
bash -lc exit
for i in {1..3}; do 
  echo "Run #$i:"
  time bash -ic exit
  echo
done
INNER_EOF
EOF
}
