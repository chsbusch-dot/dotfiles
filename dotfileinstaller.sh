#!/bin/bash

# curl -fsSL https://raw.githubusercontent.com/chsbusch-dot/dotfiles/main/dotfileinstaller.sh | bash

set -e

echo "Starting dotfiles and environment installation for macOS / Ubuntu..."

OS="$(uname -s)"
ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}
REPO_URL="https://raw.githubusercontent.com/chsbusch-dot/dotfiles/main"
ZSHRC="$HOME/.zshrc"
BASHRC="$HOME/.bashrc"
AI_ENV_FILE="$HOME/.zsh-ai.env"
TTY_DEVICE="/dev/tty"

has_tty() {
    [ -r "$TTY_DEVICE" ] && [ -w "$TTY_DEVICE" ]
}

prompt_input() {
    local __var_name="$1"
    local __prompt="$2"
    local __default="${3-}"
    local __value

    if [ -n "$__default" ]; then
        printf "%s" "$__prompt" > "$TTY_DEVICE"
        IFS= read -r __value < "$TTY_DEVICE" || __value=""
        __value=${__value:-$__default}
    else
        printf "%s" "$__prompt" > "$TTY_DEVICE"
        IFS= read -r __value < "$TTY_DEVICE" || __value=""
    fi

    printf -v "$__var_name" '%s' "$__value"
}

prompt_secret() {
    local __var_name="$1"
    local __prompt="$2"
    local __value

    if ! IFS= read -r -s -p "$__prompt" __value < "$TTY_DEVICE"; then
        __value=""
    fi
    printf "\n" > "$TTY_DEVICE"
    printf -v "$__var_name" '%s' "$__value"
}

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
if [ ! -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]; then
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended || true
fi

if [ ! -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]; then
    echo "Oh My Zsh installer did not create a usable $HOME/.oh-my-zsh setup. Cloning fallback copy..."
    rm -rf "$HOME/.oh-my-zsh"
    git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
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

echo "Sourcing downloaded .zshrc..."
if ! zsh -ic "source \"$ZSHRC\"" >/dev/null 2>&1; then
    echo "Warning: Failed to source $ZSHRC in zsh during installation."
fi

# ==========================================
# 6. Configure AI Provider
# ==========================================
configure_ai_provider() {
    local provider_choice api_key openai_url openai_model openai_api_key choice_prompt

    printf "\n" > "$TTY_DEVICE"
    printf "Choose Your AI Provider\n" > "$TTY_DEVICE"
    printf "1. Anthropic Claude (Default)\n" > "$TTY_DEVICE"
    printf "2. OpenAI\n" > "$TTY_DEVICE"
    printf "3. Google Gemini\n" > "$TTY_DEVICE"
    printf "4. Ollama (Local & Free)\n" > "$TTY_DEVICE"
    printf "5. Mistral AI\n" > "$TTY_DEVICE"
    printf "6. Grok (X.AI)\n" > "$TTY_DEVICE"
    printf "7. OpenAI-Compatible Servers\n" > "$TTY_DEVICE"
    printf "8. Perplexity\n\n" > "$TTY_DEVICE"

    prompt_input provider_choice "Select provider [1]: " "1"

    umask 077
    : > "$AI_ENV_FILE"
    {
        echo "# Generated by dotfileinstaller.sh"
        echo "# Update this file to change your zsh-ai provider settings."
    } >> "$AI_ENV_FILE"

    case "$provider_choice" in
        1)
            prompt_secret api_key "Paste your Anthropic API key: "
            {
                echo "export ANTHROPIC_API_KEY=\"$api_key\""
                echo "export ZSH_AI_PROVIDER=\"anthropic\""
            } >> "$AI_ENV_FILE"
            ;;
        2)
            prompt_secret api_key "Paste your OpenAI API key: "
            {
                echo "export OPENAI_API_KEY=\"$api_key\""
                echo "export ZSH_AI_PROVIDER=\"openai\""
            } >> "$AI_ENV_FILE"
            ;;
        3)
            prompt_secret api_key "Paste your Gemini API key: "
            {
                echo "export GEMINI_API_KEY=\"$api_key\""
                echo "export ZSH_AI_PROVIDER=\"gemini\""
            } >> "$AI_ENV_FILE"
            ;;
        4)
            {
                echo "export ZSH_AI_PROVIDER=\"ollama\""
            } >> "$AI_ENV_FILE"
            printf "Ollama selected. Install Ollama separately and run: ollama pull llama3.2\n" > "$TTY_DEVICE"
            ;;
        5)
            prompt_secret api_key "Paste your Mistral API key: "
            {
                echo "export MISTRAL_API_KEY=\"$api_key\""
                echo "export ZSH_AI_PROVIDER=\"mistral\""
            } >> "$AI_ENV_FILE"
            ;;
        6)
            prompt_secret api_key "Paste your X.AI API key: "
            {
                echo "export XAI_API_KEY=\"$api_key\""
                echo "export ZSH_AI_PROVIDER=\"grok\""
            } >> "$AI_ENV_FILE"
            ;;
        7)
            prompt_input openai_url "OpenAI-compatible URL [http://localhost:8080/v1/chat/completions]: " "http://localhost:8080/v1/chat/completions"
            prompt_input openai_model "Model name [your-model-name]: " "your-model-name"
            prompt_secret openai_api_key "Optional API key for proxy auth (press Enter to skip): "
            {
                echo "export ZSH_AI_PROVIDER=\"openai\""
                echo "export ZSH_AI_OPENAI_URL=\"$openai_url\""
                echo "export ZSH_AI_OPENAI_MODEL=\"$openai_model\""
                if [ -n "$openai_api_key" ]; then
                    echo "export ZSH_AI_OPENAI_API_KEY=\"$openai_api_key\""
                fi
            } >> "$AI_ENV_FILE"
            ;;
        8)
            prompt_secret api_key "Paste your Perplexity API key: "
            prompt_input openai_model "Perplexity model [llama-3.1-sonar-small-128k-online]: " "llama-3.1-sonar-small-128k-online"
            {
                echo "export OPENAI_API_KEY=\"$api_key\""
                echo "export ZSH_AI_PROVIDER=\"openai\""
                echo "export ZSH_AI_OPENAI_URL=\"https://api.perplexity.ai/chat/completions\""
                echo "export ZSH_AI_OPENAI_MODEL=\"$openai_model\""
            } >> "$AI_ENV_FILE"
            ;;
        *)
            printf "Invalid selection. Falling back to Anthropic Claude.\n" > "$TTY_DEVICE"
            prompt_secret api_key "Paste your Anthropic API key: "
            {
                echo "export ANTHROPIC_API_KEY=\"$api_key\""
                echo "export ZSH_AI_PROVIDER=\"anthropic\""
            } >> "$AI_ENV_FILE"
            ;;
    esac

    chmod 600 "$AI_ENV_FILE"
    echo "Saved zsh-ai configuration to $AI_ENV_FILE"
}

if has_tty; then
    if [ -f "$AI_ENV_FILE" ]; then
        prompt_input choice_prompt "Existing AI config found at $AI_ENV_FILE. Replace it? [y/N]: " "N"
        case "$choice_prompt" in
            [Yy]|[Yy][Ee][Ss])
                configure_ai_provider
                ;;
            *)
                echo "Keeping existing AI provider configuration."
                ;;
        esac
    else
        configure_ai_provider
    fi
else
    if [ ! -f "$AI_ENV_FILE" ]; then
        umask 077
        cat <<'EOF' > "$AI_ENV_FILE"
# Generated by dotfileinstaller.sh
# No terminal was available for prompts. Configure one provider, then start a new zsh session.
# export ANTHROPIC_API_KEY="your-api-key-here"
# export ZSH_AI_PROVIDER="anthropic"
EOF
        chmod 600 "$AI_ENV_FILE"
    fi
    echo "Skipping interactive AI provider setup (no terminal available for prompts)."
    echo "Edit $AI_ENV_FILE after install to configure your provider."
fi

# ==========================================
# 7. Final Polish & Shell Swap
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