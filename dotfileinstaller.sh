#!/bin/bash

# curl -fsSL https://raw.githubusercontent.com/chsbusch-dot/dotfiles/main/dotfileinstaller.sh | bash


set -e 

echo "Starting dotfiles and environment installation for macOS / Ubuntu..."

OS="$(uname -s)"
ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}
REPO_URL="https://raw.githubusercontent.com/chsbusch-dot/dotfiles/main"

# ==========================================
# 1. System Updates & Base Packages
# ==========================================
if [ "$OS" = "Linux" ]; then
    sudo apt-get update
    # Added htop and ntopng to the base Linux installation
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
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    elif [ "$OS" = "Darwin" ]; then
        [ -x "/opt/homebrew/bin/brew" ] && eval "$(/opt/homebrew/bin/brew shellenv)" || eval "$(/usr/local/bin/brew shellenv)"
    fi
fi

if [ "$OS" = "Darwin" ]; then
    # Added htop and ntopng to the Homebrew installation
    brew install wget curl tmux git htop ntopng
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
[ ! -d "$ZSH_CUSTOM/plugins/zsh-you-should-use" ] && git clone https://github.com/MichaelAquilina/zsh-you-should-use "$ZSH_CUSTOM/plugins/zsh-you-should-use"
[ ! -d "$ZSH_CUSTOM/plugins/zsh-bat" ] && git clone https://github.com/fdellwing/zsh-bat "$ZSH_CUSTOM/plugins/zsh-bat"

brew tap matheusml/zsh-ai
brew install zsh-ai
[ ! -d "$ZSH_CUSTOM/plugins/zsh-ai" ] && git clone https://github.com/matheusml/zsh-ai "$ZSH_CUSTOM/plugins/zsh-ai"

# ==========================================
# 5. Fetch .p10k.zsh Configuration
# ==========================================
echo "Downloading .p10k.zsh configuration..."
curl -fsSL "$REPO_URL/p10k.zsh" -o ~/.p10k.zsh

# ==========================================
# 6. Configure .zshrc
# ==========================================
echo "Configuring .zshrc..."

# Some unattended setups do not create ~/.zshrc automatically.
if [ ! -f ~/.zshrc ]; then
    touch ~/.zshrc
fi

cp ~/.zshrc ~/.zshrc.backup.$(date +%s) 2>/dev/null || true

# Add p10k instant prompt to the very top of .zshrc
if ! grep -q "p10k-instant-prompt" ~/.zshrc; then
    # Create a temporary file to prepend the instant prompt code
    cat << 'EOF' > ~/.zshrc.tmp
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
EOF
    cat ~/.zshrc >> ~/.zshrc.tmp
    mv ~/.zshrc.tmp ~/.zshrc
fi

# Set Theme and Plugins
sed -i.bak 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc
sed -i.bak 's/^plugins=(.*/plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-you-should-use zsh-bat zsh-ai)/' ~/.zshrc

# Append zsh-ai and p10k sourcing to the bottom
if ! grep -q "ZSH_AI_PROVIDER" ~/.zshrc; then
    echo -e "\n# ZSH AI Configuration" >> ~/.zshrc
    echo 'source $(brew --prefix)/share/zsh-ai/zsh-ai.plugin.zsh' >> ~/.zshrc
    echo 'export OPENAI_API_KEY="your-key-here"' >> ~/.zshrc
    echo 'export ZSH_AI_PROVIDER="openai"' >> ~/.zshrc
fi

if ! grep -q "source ~/.p10k.zsh" ~/.zshrc; then
    echo -e "\n# To customize prompt, run \`p10k configure\` or edit ~/.p10k.zsh." >> ~/.zshrc
    echo '[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh' >> ~/.zshrc
fi

# ==========================================
# 7. Final Polish & Shell Swap
# ==========================================
if [ "$SHELL" != "$(which zsh)" ]; then
    echo "Changing default shell to Zsh..."
    chsh -s $(which zsh)
fi

echo "=========================================="
echo "Installation complete! Launching Zsh..."
echo "=========================================="

# Replace current bash session with a fresh zsh session (this automatically sources .zshrc)
exec zsh -l