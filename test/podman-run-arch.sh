run_arch_amd64() { _run_arch_logic "amd64"; }
run_arch_arm64() { _run_arch_logic "arm64"; }

_run_arch_logic() {
  local arch=$1
  CNAME="test-run-arch-$arch"
  podman rm -f $CNAME 2>/dev/null || true
  podman run --rm -i --platform "linux/$arch" -v "$PWD:/workspace:Z" --name $CNAME archlinux:latest bash <<'EOF'
set -e

pacman -Sy --noconfirm --needed bash git curl wget tar gzip xz unzip zip bzip2 which \
shadow sudo procps-ng make gcc grep sed gawk findutils coreutils base-devel libffi \
libyaml openssl zlib readline gmp lua luarocks php openssl pkgconf fontconfig \
freetype2 harfbuzz jq tmux imagemagick ghostscript pandoc sqlite bat btop ncdu 1>/dev/null

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
