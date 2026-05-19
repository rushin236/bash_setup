## bash_setup (Development & Testing Playground)

This repository serves as the official development sandbox, orchestration hub, and cross-distribution test harness for the core [`.bash_setup`](https://www.google.com/search?q=%5Bhttps://github.com/rushin236/.bash_setup%5D(https://github.com/rushin236/.bash_setup)) project.

The actual environment configuration framework lives inside the `.bash_setup` submodule. This repository provides a multi-architecture Podman environment to build, debug, and validate changes instantly across multiple Linux distributions.

---
## Architecture Setup & Cloning

The core project is tracked as a submodule pinned to target the `main` branch. To clone this development harness along with the absolute freshest commits from the `.bash_setup` upstream, run:

```bash
git clone --recurse-submodules --remote-submodules git@github.com:rushin236/bash_setup.git
cd bash_setup
```

### Pulling Latest Submodule Changes Mid-Development

If updates are pushed to the `.bash_setup` project separately, pull them into this harness using:

```bash
git submodule update --remote --merge
```

---
## Supported Testing Matrix

The validation test suite offers complete multi-architecture capability, testing both **`amd64`** and **`arm64`** environments across the following distributions:

* Arch Linux
* Alpine Linux
* Debian (Stable)
* Ubuntu (Latest)
* Fedora (Latest)
* openSUSE (Tumbleweed)

---
## Interactive Test Framework

Test configurations are orchestrated using the execution wrapper script `./test-run.sh`. To make the harness functions available in your active shell, source the core test entrypoint:

```bash
source ./test-run.sh
```

Once sourced, the `test` command becomes active with three key diagnostic operations: `run`, `shell`, and `blank`.

### 1. Automated Installation & Validation Suite (`test run`)

This command mounts your local directory workspace into a Podman container, installs base distribution dependencies, sets up configuration symlinks, triggers `tool pkg install all && tool sync all`, and executes an integrated version-validation suite across your runtimes.

* **Syntax:** `test run <distro> <architecture>`
* **Examples:**
```bash
# Run automation against Arch Linux on amd64
test run arch amd64

# Run automation against Ubuntu on arm64
test run ubuntu arm64

# Run validation across BOTH amd64 and arm64 targets for Fedora
test run fedora all

```

### 2. Interactive Development Shell (`test shell`)

Drops you directly inside an interactive Bash session as a passwordless `tester` user inside the target container environment, pre-loading your current development files. Perfect for manual testing, debugging edge cases, or fine-tuning setup scripts.

* **Syntax:** `test shell <distro> <architecture>`
* **Examples:**
```bash
# Debug interactive Alpine environment on amd64
test shell alpine amd64

# Debug interactive Debian environment on arm64
test shell debian arm64
```

### 3. Clean-Slate Environment Check (`test blank`)

Launches a bare interactive environment utilizing native distribution container settings. Installs minimal dependencies (`git`, `make`, `curl`, `wget`, `tar`, `xz`) and leaves configuring or executing script runtimes entirely up to your manual interaction.

* **Syntax:** `test blank <distro> <architecture>`
* **Examples:**
```bash
# Launch a pristine Fedora container environment
test blank fedora amd64
```

---
## Directory & Submodule Layout

```text
.
├── .bash_setup/             # <-- Core framework submodule (The active dev code)
├── .bash_profile            # Development shell entrypoints
├── .bashrc                  # Development dotfile configurations
├── .blerc                   # Development ble.sh rc file
├── test-run.sh              # Harness framework wrapper script
└── test/                    # Distribution Podman orchestration drivers
    ├── 00-test.sh           # Main router logic
    ├── 01-run.sh            # Validation framework configuration
    ├── 02-shell.sh          # Interactive container router
    ├── 03-blank-shell.sh    # Clean slate shell router
    └── podman-*.sh          # Distro-specific automation scripts

```

---
## Development Cycle Best Practices

1. **Modify Submodule:** Make structural changes, fix package hooks, or alter bootstrap paths inside the nested `.bash_setup/` directory.
2. **Local Integration Test:** Ensure changes parse seamlessly without syntax errors using local test runners:
```bash
test run arch amd64
```
3. **Interactive Fixes:** If a distribution tool fails validation, step directly inside to repair pathing hooks interactively:
```bash
test shell debian amd64
```
4. **Commit Upstream:** Remember to commit and push changes directly from within your `.bash_setup` submodule directory up to its dedicated repository when development is complete!
