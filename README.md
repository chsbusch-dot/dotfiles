# dotfiles

One-liner bootstrap for a full Zsh developer environment on **macOS** and **Ubuntu**.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/chsbusch-dot/dotfiles/main/dotfileinstaller.sh | bash
```

That's it. The script installs everything, prompts you for an AI provider, and drops you into a fresh Zsh session when done.

---

## What Gets Installed

| Step | What happens |
|------|-------------|
| **1. System packages** | `apt-get` (Linux) or Xcode CLI check (macOS) |
| **2. Homebrew** | Installs if missing; handles Apple Silicon, Intel, and Linuxbrew |
| **3. Oh My Zsh + Powerlevel10k** | Unattended OMZ install with a git-clone fallback; p10k cloned into `$ZSH_CUSTOM/themes/` |
| **4. Zsh plugins** | `zsh-autosuggestions`, `zsh-syntax-highlighting`, `you-should-use`, `zsh-bat`, `zsh-ai` |
| **5. Shell config** | Downloads `.zshrc` and `.p10k.zsh` from this repo; backs up any existing `.zshrc` |
| **6. AI provider** | Interactive menu to pick and configure your AI provider (saved to `~/.zsh-ai.env`) |
| **7. Shell swap** | `chsh` to Zsh, then `exec zsh -l` |

---

## AI Provider

During install you'll see a menu:

```
Choose Your AI Provider
1. Anthropic Claude (Default)
2. OpenAI
3. Google Gemini
4. Ollama (Local & Free)
5. Mistral AI
6. Grok (X.AI)
7. OpenAI-Compatible Servers
8. Perplexity
```

Your API key is saved to `~/.zsh-ai.env` (mode `600`, never committed to git). To reconfigure after install, delete that file and re-run the installer, or edit it directly.

### Reconfigure later

```bash
rm ~/.zsh-ai.env
curl -fsSL https://raw.githubusercontent.com/chsbusch-dot/dotfiles/main/dotfileinstaller.sh | bash
```

---

## Re-running

The installer is **idempotent** — every step checks whether its target already exists before acting. Running it again is safe.

---

## Files

| File | Purpose |
|------|---------|
| `dotfileinstaller.sh` | Main bootstrap script |
| `.zshrc` | Zsh config deployed to `~/.zshrc` |
| `.p10k.zsh` | Powerlevel10k prompt config deployed to `~/.p10k.zsh` |

---

## After Install

- Open a new terminal — Powerlevel10k rainbow prompt is ready.
- Use `Ctrl+K` (or your configured keybind) to ask the AI inline from any prompt.
- Reload p10k config without restarting: `source ~/.p10k.zsh`
- AI provider settings live in `~/.zsh-ai.env` — edit any time.

