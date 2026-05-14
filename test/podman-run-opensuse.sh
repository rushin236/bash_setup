run_opensuse_amd64() { _run_opensuse_logic "amd64"; }
run_opensuse_arm64() { _run_opensuse_logic "arm64"; }

_run_opensuse_logic() {
  local arch=$1
  CNAME="test-run-opensuse-$arch"
  podman rm -f $CNAME 2>/dev/null || true
  podman run --rm -i \
    --platform "linux/$arch" \
    -v "$PWD:/workspace:Z" \
    --name $CNAME opensuse/tumbleweed bash -s <<'EOF'
set -exo pipefail

zypper --non-interactive ref

zypper --non-interactive install \
bash git curl wget tar gzip xz unzip zip bzip2 shadow sudo procps make gcc gcc-c++ grep sed \
gawk findutils coreutils libffi-devel libyaml-devel libopenssl-devel zlib-devel \
readline-devel gmp-devel lua54 lua54-devel lua54-luarocks jq tmux ImageMagick \
ghostscript pandoc sqlite3 bat btop ncdu pkgconf-pkg-config \
fontconfig-devel freetype2-devel harfbuzz-devel sqlite3-devel \
libicu-devel libcurl-devel libpng16-devel graphite2-devel \
autoconf bison re2c libxml2-devel oniguruma-devel libzip-devel 1>/dev/null

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
