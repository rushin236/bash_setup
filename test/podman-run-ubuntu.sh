run_ubuntu_amd64() { _run_ubuntu_logic "amd64"; }
run_ubuntu_arm64() { _run_ubuntu_logic "arm64"; }

_run_ubuntu_logic() {
  local arch=$1
  CNAME="test-run-ubuntu-$arch"
  podman rm -f $CNAME 2>/dev/null || true
  podman run --rm -i --platform "linux/$arch" -v "$PWD:/workspace:Z" --name $CNAME ubuntu:latest bash <<'EOF'
set -e

export DEBIAN_FRONTEND=noninteractive

apt-get update >/dev/null
apt-get install -y bash git curl wget tar gzip xz-utils unzip zip bzip2 passwd sudo \
procps make gcc g++ grep sed gawk findutils coreutils libffi-dev libyaml-dev libssl-dev \
zlib1g-dev libreadline-dev libgmp-dev lua5.4 liblua5.4-dev luarocks php-cli jq tmux \
imagemagick ghostscript pandoc sqlite3 bat btop ncdu pkg-config \
libfontconfig1-dev libfreetype6-dev libharfbuzz-dev libsqlite3-dev \
libicu-dev libcurl4-openssl-dev libpng-dev libgraphite2-dev 1>/dev/null

# Fix the Debian 'bat' naming conflict so validation passes
ln -sf /usr/bin/batcat /usr/local/bin/bat

useradd -m -s /bin/bash tester
echo "tester ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
cp -r /workspace /home/tester/project && chown -R tester:tester /home/tester

su - tester -c 'bash -l' <<'INNER_EOF'
echo "--- COPYING FILES ---"
cp ~/project/.bashrc ~/.bashrc
cp ~/project/.bash_profile ~/.bash_profile
cp ~/project/.blerc ~/.blerc
cp -r ~/project/.bashrc.d ~/.bashrc.d
. ~/.bashrc

echo "--- INSTALLATION ---"
tool pkg install all
tool sync all

echo "--- VALIDATION ---"
for x in fzf nvim starship carapace uv python pip node npm rustc cargo go \
rustfmt clippy-driver shellcheck shfmt ruby gem markdown-toc \
php composer java javac julia lua luarocks jq yq tmux \
magick gs lazygit delta pandoc sqlite3 bat eza zoxide btop ncdu tectonic; do
  command -v $x >/dev/null && echo "PASS $x" || echo "FAIL $x"
done

echo "--- TIMING ---"
bash -lc exit
for i in {1..3}; do echo "Run #$i:"; time bash -lc exit; echo ; done
INNER_EOF
EOF
}
