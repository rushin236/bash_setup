
# bash_setup

A portable Bash environment bootstrap for Linux systems.

`bash_setup` provides a consistent shell setup across supported distributions with:

- Structured Bash config (`~/.bashrc.d`)
- Package/runtime bootstrap commands
- Language toolchain setup
- Neovim-friendly developer tools
- Cross-distro package support
- Reproducible user environment

---

# Current Status

**Release:** `v0.1.0`

Supported distributions:

- Arch Linux
- Debian
- Ubuntu
- Fedora
- openSUSE

Not currently supported:

- Alpine Linux  
  (Micromamba compatibility issues)

---

# Features

- Modular Bash config layout
- `tool pkg install all`
- `tool sync all`
- Python / Node / Go / Rust / Java setup
- CLI tools bootstrap
- Fast shell startup design
- Good Neovim ecosystem support

---

# Installation

## 1. Clone Repository

```bash
cd ~
git clone <your-repo-url> bash_setup
```

---

## 2. Install Base Dependencies

Choose your distro.

---

# Arch Linux

```bash
sudo pacman -Sy --noconfirm --needed \
bash git curl wget tar gzip xz unzip zip bzip2 which \
shadow sudo procps-ng make gcc grep sed gawk findutils coreutils base-devel libffi \
libyaml openssl zlib readline gmp lua luarocks php pkgconf fontconfig \
freetype2 harfbuzz jq tmux imagemagick ghostscript pandoc sqlite bat btop ncdu
```

---

# Debian / Ubuntu

```bash
sudo apt-get update
sudo apt-get install -y \
bash git curl wget tar gzip xz-utils unzip zip bzip2 passwd sudo \
procps make gcc g++ grep sed gawk findutils coreutils libffi-dev libyaml-dev \
libssl-dev zlib1g-dev libreadline-dev libgmp-dev lua5.4 liblua5.4-dev luarocks \
php-cli jq tmux imagemagick ghostscript pandoc sqlite3 bat btop ncdu pkg-config \
libfontconfig1-dev libfreetype6-dev libharfbuzz-dev libsqlite3-dev \
libicu-dev libcurl4-openssl-dev libpng-dev libgraphite2-dev
```

---

# Fedora

```bash
sudo dnf install -y \
bash git curl wget tar gzip xz unzip zip bzip2 shadow-utils sudo procps-ng make \
gcc gcc-c++ grep sed gawk findutils coreutils libffi-devel libyaml-devel \
openssl-devel zlib-devel readline-devel gmp-devel lua lua-devel luarocks php-cli \
jq tmux ImageMagick ghostscript pandoc sqlite bat btop ncdu pkgconf-pkg-config \
fontconfig-devel freetype-devel harfbuzz-devel sqlite-devel \
libicu-devel graphite2-devel libcurl-devel libpng-devel
```

---

# openSUSE

```bash
sudo zypper --non-interactive refresh

sudo zypper --non-interactive install \
bash git curl wget tar gzip xz unzip zip bzip2 shadow sudo procps make gcc gcc-c++ \
grep sed gawk findutils coreutils libffi-devel libyaml-devel libopenssl-devel \
zlib-devel readline-devel gmp-devel lua54 lua54-devel lua54-luarocks php php-cli \
jq tmux ImageMagick ghostscript pandoc sqlite3 bat btop ncdu pkgconf-pkg-config \
fontconfig-devel freetype2-devel harfbuzz-devel sqlite3-devel \
libicu-devel libcurl-devel libpng16-devel graphite2-devel
```

---

# 3. Copy Configuration Files

```bash
cp ~/bash_setup/.bashrc ~/.bashrc
cp ~/bash_setup/.bash_profile ~/.bash_profile
cp ~/bash_setup/.blerc ~/.blerc
cp -r ~/bash_setup/.bashrc.d ~/.bashrc.d
```

---

# 4. Reload Shell

```bash
source ~/.bashrc
```

---

# 5. Install Packages / Toolchains

```bash
tool pkg install all
tool sync all
```

---

# Main Commands

## Install all managed packages

```bash
tool pkg install all
```

## Update packages

```bash
tool pkg update all
```

## Remove packages

```bash
tool pkg remove all
```

## Sync runtime tools

```bash
tool sync all
```

---

# Directory Layout

```text
~/.bashrc
~/.bash_profile
~/.blerc
~/.bashrc.d/
```

---

# Notes

* User-local installs preferred where possible
* Designed for developer machines
* Works well with Neovim setups
* Uses modular source files

---

# Updating

```bash
cd ~/bash_setup
git pull
cp -r .bashrc.d ~/.bashrc.d
cp .bashrc ~/.bashrc
cp .bash_profile ~/.bash_profile
source ~/.bashrc
tool pkg update all
tool sync all
```

---

# Roadmap

* Alpine Linux support
* Better release automation
* Expanded distro testing
* More package backends

---

# License

MIT

---

# Author

Rushikesh Shinde

```
```
