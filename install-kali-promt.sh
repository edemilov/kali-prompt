#!/bin/bash

# ============================================
# KALI BOX PROMPT INSTALLER
# Sets up identical two-line box prompts for:
#   • Bash  → └─$
#   • Zsh   → └─$>
#   • Fish  → └─>
# ============================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}┌─(${RED}KALI${BLUE}@${RED}BOX${BLUE})─[${CYAN}PROMPT INSTALLER${BLUE}]${NC}"
echo -e "${BLUE}└─${RED}$ ${NC}\n"

# Detect OS and package manager
detect_pkg_manager() {
    if command -v pacman &> /dev/null; then
        PKG_MANAGER="pacman"
        INSTALL_CMD="sudo pacman -S --noconfirm"
        ZSH_PKG="zsh"
        FISH_PKG="fish"
        FONT_PKG="ttf-jetbrains-mono-nerd"
    elif command -v apt &> /dev/null; then
        PKG_MANAGER="apt"
        INSTALL_CMD="sudo apt install -y"
        ZSH_PKG="zsh"
        FISH_PKG="fish"
        FONT_PKG="fonts-jetbrains-mono"
    elif command -v dnf &> /dev/null; then
        PKG_MANAGER="dnf"
        INSTALL_CMD="sudo dnf install -y"
        ZSH_PKG="zsh"
        FISH_PKG="fish"
        FONT_PKG="jetbrains-mono-fonts"
    else
        echo -e "${YELLOW}Could not detect package manager. Skipping installations.${NC}"
        PKG_MANAGER="unknown"
        INSTALL_CMD="echo 'Please install: '"
    fi
}

# Install shells if desired
install_shells() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}Do you want to install Fish and Zsh? (y/n)${NC}"
    read -r install_shells_choice

    if [[ "$install_shells_choice" =~ ^[Yy]$ ]]; then
        echo -e "${CYAN}Installing shells...${NC}"
        detect_pkg_manager
        $INSTALL_CMD $ZSH_PKG $FISH_PKG $FONT_PKG
    fi
}

# ============ BASH PROMPT ============
setup_bash() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}Setting up Bash prompt...${NC}"

    BASH_CONFIG="$HOME/.bashrc"

    # Backup
    cp "$BASH_CONFIG" "$BASH_CONFIG.kali-backup" 2>/dev/null || true

    # Remove any existing custom prompt lines
    sed -i '/# ----- Kali box prompt for Bash -----/,+1d' "$BASH_CONFIG"
    sed -i '/^__box_prompt/,/^}/d' "$BASH_CONFIG"
    sed -i '/^PS1=.*┌─.*└─/d' "$BASH_CONFIG"

    # Add new prompt
    cat >> "$BASH_CONFIG" << 'EOF'

# ----- Kali box prompt for Bash -----
PS1='┌─\[$(tput setaf 1)\]\u\[$(tput setaf 7)\]@\[$(tput setaf 4)\]\h\[$(tput setaf 7)\]─[\[$(tput setaf 6)\]\w\[$(tput setaf 7]\]]\n└─\[$(tput setaf 1)\]$ \[$(tput sgr0)\]'
EOF

    echo -e "${GREEN}✓ Bash prompt installed${NC}"
}

# ============ ZSH PROMPT ============
setup_zsh() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}Setting up Zsh prompt...${NC}"

    ZSH_CONFIG="$HOME/.zshrc"

    # Backup
    [ -f "$ZSH_CONFIG" ] && cp "$ZSH_CONFIG" "$ZSH_CONFIG.kali-backup"

    # Remove Powerlevel10k and Oh-My-Zsh if present
    if command -v pacman &> /dev/null; then
        sudo pacman -Rns powerlevel10k oh-my-zsh 2>/dev/null || true
    fi

    # Clean up existing configs
    rm -f "$HOME/.p10k.zsh" 2>/dev/null
    rm -rf "$HOME/.oh-my-zsh" 2>/dev/null

    # Create fresh .zshrc with just our prompt
    cat > "$ZSH_CONFIG" << 'EOF'
# ----- Kali box prompt for Zsh -----
PROMPT=$'%{\e[0m%}┌─(%{\e[31m%}%n%{\e[97m%}@%{\e[34m%}%m%{\e[97m%})─[%{\e[36m%}%~%{\e[97m%}]\n└─%{\e[31m%}$> %{\e[0m%}'
RPROMPT=''
EOF

    echo -e "${GREEN}✓ Zsh prompt installed${NC}"
    echo -e "${YELLOW}  Removed Powerlevel10k and Oh-My-Zsh (they conflict with custom prompt)${NC}"
}

# ============ FISH PROMPT ============
setup_fish() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}Setting up Fish prompt...${NC}"

    FISH_CONFIG_DIR="$HOME/.config/fish"
    FISH_CONFIG="$FISH_CONFIG_DIR/config.fish"

    mkdir -p "$FISH_CONFIG_DIR"

    # Backup
    [ -f "$FISH_CONFIG" ] && cp "$FISH_CONFIG" "$FISH_CONFIG.kali-backup"

    # Remove any existing fish_prompt function
    sed -i '/function fish_prompt/,/end/d' "$FISH_CONFIG" 2>/dev/null || true

    # Add new prompt
    cat >> "$FISH_CONFIG" << 'EOF'

# ----- Kali box prompt for Fish -----
function fish_prompt
    set -l red (set_color red)
    set -l blue (set_color blue)
    set -l white (set_color white)
    set -l cyan (set_color cyan)
    set -l gray (set_color brblack)
    set -l normal (set_color normal)

    echo -n "┌─"
    echo -n $red"("$USER
    echo -n $white"@"
    echo -n $blue(hostname -s)
    echo -n $red")"
    echo -n $gray"─"
    echo -n $white"["
    echo -n $cyan(prompt_pwd)
    echo -n $white"]"
    echo

    echo -n "└─"
    echo -n $red"> "
    echo -n $normal
end
EOF

    echo -e "${GREEN}✓ Fish prompt installed${NC}"
}

# ============ SET DEFAULT SHELL ============
set_default_shell() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}Which shell do you want as default?${NC}"
    echo "1) Bash (current default)"
    echo "2) Zsh"
    echo "3) Fish"
    echo "4) Keep current"
    read -r shell_choice

    case $shell_choice in
        1) chsh -s $(which bash) && echo -e "${GREEN}✓ Default shell changed to Bash${NC}" ;;
        2) chsh -s $(which zsh) && echo -e "${GREEN}✓ Default shell changed to Zsh${NC}" ;;
        3) chsh -s $(which fish) && echo -e "${GREEN}✓ Default shell changed to Fish${NC}" ;;
        *) echo -e "${YELLOW}Keeping current default shell${NC}" ;;
    esac
}

# ============ VERIFICATION ============
verify_installation() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}Installation complete!${NC}"
    echo -e "\n${CYAN}Quick verification:${NC}"

    echo -e "\n${YELLOW}Bash prompt:${NC}"
    echo '  PS1="┌─(\u@\h)─[\w]\n└─\$ "' | bash --norc --noprofile 2>/dev/null | head -2

    if command -v zsh &> /dev/null; then
        echo -e "\n${YELLOW}Zsh prompt:${NC}"
        echo 'PROMPT=$'\''%{\e[0m%}┌─(%{\e[31m%}%n%{\e[97m%}@%{\e[34m%}%m%{\e[97m%})─[%{\e[36m%}%~%{\e[97m%}]\n└─%{\e[31m%}$> %{\e[0m%}'\''; print -P "$PROMPT"' | zsh --no-rcs 2>/dev/null | head -2
    fi

    if command -v fish &> /dev/null; then
        echo -e "\n${YELLOW}Fish prompt:${NC}"
        fish -c 'function fish_prompt; echo "┌─(user@host)─[pwd]\n└─> "; end; fish_prompt' 2>/dev/null | head -2
    fi

    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✅ Kali box prompts installed successfully!${NC}"
    echo -e "${YELLOW}Note: You may need to restart your terminal or log out/in.${NC}"
}

# ============ MAIN ============
main() {
    install_shells
    setup_bash
    setup_zsh
    setup_fish
    set_default_shell
    verify_installation

    echo -e "\n${CYAN}Quick reference:${NC}"
    echo "  • Bash  → └─$"
    echo "  • Zsh   → └─$>"
    echo "  • Fish  → └─>"
    echo -e "\n${BLUE}┌─(${RED}DONE${BLUE})─[${CYAN}PROMPT INSTALLED${BLUE}]${NC}"
    echo -e "${BLUE}└─${RED}$ ${NC}"
}

# Run main function
main
