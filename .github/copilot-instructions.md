# Copilot Instructions

## Repository Overview

This is a **dotfiles repository** for automated macOS/Ubuntu environment setup. It provisions a full Zsh-based developer environment via a single bootstrap script.

## Files

- **`dotfileinstaller.sh`** — Main bootstrap script. Run it via `curl | bash` or directly. Uses `set -e`; any failed command aborts the entire installation.
- **`p10k.zsh`** — Powerlevel10k prompt configuration (rainbow style, nerdfont-v3, powerline separators, 12h time, instant prompt enabled). Deployed to `~/.p10k.zsh` by the installer.

## Installer Architecture

The script runs 7 sequential stages:

1. **System packages** — `apt-get` on Linux, `xcode-select` check on macOS
2. **Homebrew** — Installs if missing; handles both Apple Silicon (`/opt/homebrew`) and Intel (`/usr/local`) paths
3. **Oh My Zsh + Powerlevel10k** — Unattended install; clones p10k theme into `$ZSH_CUSTOM/themes/`
4. **Zsh plugins** — Clones into `$ZSH_CUSTOM/plugins/`: `zsh-autosuggestions`, `zsh-syntax-highlighting`, `zsh-you-should-use`, `zsh-bat`, `zsh-ai`
5. **p10k config** — `curl`s `p10k.zsh` from `$REPO_URL` to `~/.p10k.zsh`
6. **`.zshrc` mutation** — Prepends p10k instant prompt block, patches `ZSH_THEME` and `plugins=(...)` lines via `sed`, appends `zsh-ai` config and p10k sourcing
7. **Shell swap** — `chsh` to Zsh, then `exec zsh -l`

## Key Conventions

- **Idempotency guards**: Every install step checks existence first (`[ ! -d ... ] && git clone ...`, `if ! command -v brew`, etc.). Re-running the script is safe.
- **`.zshrc` is patched, not replaced**: The script uses `sed -i.bak` to mutate existing lines and appends new blocks only when a sentinel string is absent (`grep -q`). Always preserve this pattern when adding new `.zshrc` modifications.
- **`REPO_URL` must be updated**: The placeholder `https://raw.githubusercontent.com/your-username/dotfiles/main` must point to the actual repo before using the script. The `p10k.zsh` fetch in stage 5 depends on this.
- **`OPENAI_API_KEY` placeholder**: Stage 6 appends `export OPENAI_API_KEY="your-key-here"` to `.zshrc`. Never commit a real key here.
- **macOS packages via Homebrew, Linux via apt**: The two OS paths diverge at stage 1 and reconverge at stage 3. Linux relies on system `brew` (Linuxbrew) for everything after stage 1.
- **`p10k.zsh` live reload**: After editing `p10k.zsh`, apply changes with `source ~/.p10k.zsh` — no shell restart needed (the file unsets all `POWERLEVEL9K_*` vars at the top for this purpose).
