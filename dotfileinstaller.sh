#!/bin/bash

# curl -fsSL https://raw.githubusercontent.com/chsbusch-dot/dotfiles/main/dotfileinstaller.sh | bash

set -e

echo "Starting dotfiles and environment installation for macOS / Ubuntu..."

OS="$(uname -s)"
ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}
REPO_URL="https://raw.githubusercontent.com/chsbusch-dot/dotfiles/main"
ZSHRC="$HOME/.zshrc"
BASHRC="$HOME/.bashrc"

# ==========================================
# 1. System Updates & Base Packages
# ==========================================
if [ "$OS" = "Linux" ]; then
    sudo apt-get update
    sudo apt-get install -y curl wget git tmux zsh build-essential openssh-server open-vm-tools htop ntopng
elif [ "$OS" = "Darwin" ]; then
    if ! xcode-select -p &> /dev/null; then
        xcode-select --install
        echo "Please wait for Xcode Command Line Tools to finish installing, then run this script again."
        exit 1
    fi
else
    echo "Unsupported OS."
    exit 1
fi

# ==========================================
# 2. Install Homebrew
# ==========================================
if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    if [ "$OS" = "Linux" ]; then
        eval "$([ -x /home/linuxbrew/.linuxbrew/bin/brew ] && /home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    elif [ "$OS" = "Darwin" ]; then
        [ -x "/opt/homebrew/bin/brew" ] && eval "$(/opt/homebrew/bin/brew shellenv)" || eval "$(/usr/local/bin/brew shellenv)"
    fi
fi

if [ "$OS" = "Darwin" ]; then
    brew install wget curl tmux git htop ntopng
fi

if [ "$OS" = "Linux" ]; then
    touch "$BASHRC"
    if ! grep -q 'brew shellenv bash' "$BASHRC"; then
        echo >> "$BASHRC"
        echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv bash)"' >> "$BASHRC"
    fi
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv bash)"

    sudo apt-get install -y build-essential
    brew install gcc
fi

# ==========================================
# 3. Install Oh My Zsh & Powerlevel10k
# ==========================================
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

if [ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
fi

# ==========================================
# 4. Install Zsh Plugins
# ==========================================
echo "Cloning Zsh plugins..."
[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] && git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ] && git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
[ ! -d "$ZSH_CUSTOM/plugins/you-should-use" ] && git clone https://github.com/MichaelAquilina/zsh-you-should-use "$ZSH_CUSTOM/plugins/you-should-use"
[ ! -d "$ZSH_CUSTOM/plugins/zsh-bat" ] && git clone https://github.com/fdellwing/zsh-bat "$ZSH_CUSTOM/plugins/zsh-bat"

brew tap matheusml/zsh-ai
brew install zsh-ai
[ ! -d "$ZSH_CUSTOM/plugins/zsh-ai" ] && git clone https://github.com/matheusml/zsh-ai "$ZSH_CUSTOM/plugins/zsh-ai"

# ==========================================
# 5. Fetch Shell Configuration
# ==========================================
echo "Downloading .p10k.zsh configuration..."
curl -fsSL "$REPO_URL/.p10k.zsh" -o "$HOME/.p10k.zsh"

echo "Downloading .zshrc configuration..."
mkdir -p "$HOME"
if [ -f "$ZSHRC" ]; then
    cp "$ZSHRC" "$ZSHRC".backup.$(date +%s) 2>/dev/null || true
fi
curl -fsSL "$REPO_URL/.zshrc" -o "$ZSHRC"

# ==========================================
# 6. Final Polish & Shell Swap
# ==========================================
if [ "$SHELL" != "$(command -v zsh)" ]; then
    if [ -t 0 ] && [ -t 1 ]; then
        echo "Changing default shell to Zsh..."

        # Use sudo so authentication happens cleanly in an interactive terminal.
        if sudo chsh -s "$(command -v zsh)" "$USER"; then
            echo "Default shell changed to Zsh."
        else
            echo "Warning: Could not change shell automatically (authentication failed or policy blocked)."
            echo "You can run this manually later: chsh -s $(command -v zsh) $USER"
        fi
    else
        echo "Skipping automatic shell change (non-interactive run detected, e.g. curl|bash)."
        echo "Run manually after install: chsh -s $(command -v zsh) $USER"
    fi
fi

echo "=========================================="
echo "Installation complete! Launching Zsh..."
echo "=========================================="

# Replace current bash session with a fresh zsh session, which loads ~/.zshrc.
exec zsh -l