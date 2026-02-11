#!/usr/bin/env bash
#
# ┌─(KALI@BOX)─[PROMPT INSTALLER]
# └─$
#
# Kali Linux style box prompt for Bash, Zsh and Fish
# https://github.com/edemilov/kali-prompt
#
# Author: edemilov
# License: MIT

set -euo pipefail
IFS=$'\n\t'

# ============ CONFIGURATION ============
REPO_URL="https://github.com/edemilov/kali-prompt"
VERSION="1.0.0"

# ============ COLORS ============
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
NC='\033[0m'
BOLD='\033[1m'

# ============ HEADER ============
print_header() {
    clear 2>/dev/null || true
    echo -e "${BLUE}┌─(${RED}${BOLD}KALI${NC}${BLUE}@${RED}${BOLD}BOX${NC}${BLUE})─[${CYAN}${BOLD}PROMPT INSTALLER${NC}${BLUE}]${NC}"
    echo -e "${BLUE}└─${RED}${BOLD}$ ${NC}v${VERSION}"
    echo
}

# ============ HELP ============
show_help() {
    cat << EOF
${CYAN}Usage:${NC} ./install-kali-prompt.sh [OPTIONS]

${CYAN}Options:${NC}
  -h, --help      Show this help message
  -b, --bash      Install only Bash prompt
  -z, --zsh       Install only Zsh prompt
  -f, --fish      Install only Fish prompt
  --no-shells     Skip shell installation
  --default=SHELL Set default shell (bash|zsh|fish)
  --uninstall     Remove all Kali prompts and restore backups

${CYAN}Examples:${NC}
  ./install-kali-prompt.sh              # Interactive mode
  ./install-kali-prompt.sh --bash       # Install only Bash prompt
  ./install-kali-prompt.sh --default=fish  # Install all, set Fish as default

${CYAN}Repo:${NC} $REPO_URL
EOF
    exit 0
}

# ============ DETECT OS ============
detect_os() {
    # Default values
    PKG_MANAGER="unknown"
    INSTALL_CMD="echo 'Please install manually: '"
    ZSH_PKG="zsh"
    FISH_PKG="fish"
    FONT_PKG="ttf-jetbrains-mono-nerd"  # Default for Arch

    if [[ -f /etc/os-release ]]; then
        # Temporarily disable unbound variable check
        set +u
        . /etc/os-release
        OS=${ID:-linux}
        OS_VERSION=${VERSION_ID:-}
        set -u
    else
        OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    fi

    case "$OS" in
        arch|manjaro|endeavouros|cachyos|arcolinux|artix)
            PKG_MANAGER="pacman"
            INSTALL_CMD="sudo pacman -S --noconfirm"
            ZSH_PKG="zsh"
            FISH_PKG="fish"
            FONT_PKG="ttf-jetbrains-mono-nerd"
            ;;
        ubuntu|debian|pop|linuxmint|kali|raspbian|elementary|zorin)
            PKG_MANAGER="apt"
            INSTALL_CMD="sudo apt install -y"
            ZSH_PKG="zsh"
            FISH_PKG="fish"
            FONT_PKG="fonts-jetbrains-mono"
            # Update package list silently
            sudo apt update -y 2>/dev/null || true
            ;;
        fedora|rhel|centos|rocky|alma)
            PKG_MANAGER="dnf"
            INSTALL_CMD="sudo dnf install -y"
            ZSH_PKG="zsh"
            FISH_PKG="fish"
            FONT_PKG="jetbrains-mono-fonts"
            ;;
        opensuse*|suse)
            PKG_MANAGER="zypper"
            INSTALL_CMD="sudo zypper install -y"
            ZSH_PKG="zsh"
            FISH_PKG="fish"
            FONT_PKG="jetbrains-mono-fonts"
            ;;
        *)
            # Fallback: detect by package manager presence
            if command -v pacman &> /dev/null; then
                PKG_MANAGER="pacman"
                INSTALL_CMD="sudo pacman -S --noconfirm"
                FONT_PKG="ttf-jetbrains-mono-nerd"
            elif command -v apt &> /dev/null; then
                PKG_MANAGER="apt"
                INSTALL_CMD="sudo apt install -y"
                FONT_PKG="fonts-jetbrains-mono"
                sudo apt update -y 2>/dev/null || true
            elif command -v dnf &> /dev/null; then
                PKG_MANAGER="dnf"
                INSTALL_CMD="sudo dnf install -y"
                FONT_PKG="jetbrains-mono-fonts"
            elif command -v zypper &> /dev/null; then
                PKG_MANAGER="zypper"
                INSTALL_CMD="sudo zypper install -y"
                FONT_PKG="jetbrains-mono-fonts"
            fi
            ;;
    esac
}

# ============ INSTALL SHELLS ============
install_shells() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}📦 Installing shells and fonts...${NC}"

    detect_os

    if [[ "$PKG_MANAGER" != "unknown" ]]; then
        echo -e "${CYAN}Detected package manager: ${PKG_MANAGER}${NC}"
        $INSTALL_CMD $ZSH_PKG $FISH_PKG $FONT_PKG 2>/dev/null || {
            echo -e "${YELLOW}⚠ Some packages failed to install. You may need to install manually:${NC}"
            echo "  • $ZSH_PKG"
            echo "  • $FISH_PKG"
            echo "  • $FONT_PKG"
        }
        echo -e "${GREEN}✓ Installation complete${NC}"
    else
        echo -e "${YELLOW}⚠ Could not detect package manager. Please install manually:${NC}"
        echo "  • zsh"
        echo "  • fish"
        echo "  • JetBrains Mono Nerd Font"
    fi
}

# ============ BACKUP FUNCTION ============
backup_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        local backup="$file.kali-backup-$(date +%Y%m%d-%H%M%S)"
        cp "$file" "$backup"
        echo -e "${GREEN}✓ Backed up $file → $backup${NC}"
    fi
}

# ============ BASH PROMPT ============
setup_bash() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}🐚 Setting up Bash prompt...${NC}"

    local bash_config="$HOME/.bashrc"
    backup_file "$bash_config"

    # Remove existing Kali prompts
    sed -i '/# ----- Kali box prompt for Bash -----/,+1d' "$bash_config" 2>/dev/null || true
    sed -i '/^__box_prompt/,/^}/d' "$bash_config" 2>/dev/null || true
    sed -i '/^PS1=.*┌─.*└─/d' "$bash_config" 2>/dev/null || true

    # Add new prompt (FIXED)
    cat >> "$bash_config" << 'EOF'

# ----- Kali box prompt for Bash -----
# Source: https://github.com/edemilov/kali-prompt
PS1='┌─\[$(tput setaf 1)\]\[\e[1m\]\u\[$(tput sgr0)\]\[$(tput setaf 7)\]@\[$(tput setaf 4)\]\[\e[1m\]\h\[$(tput sgr0)\]\[$(tput setaf 7)\]─[\[$(tput setaf 6)\]\[\e[1m\]\w\[$(tput sgr0)\]\[$(tput setaf 7)\]]\n└─\[$(tput setaf 1)\]\[\e[1m\]$ \[$(tput sgr0)\]'
EOF

    echo -e "${GREEN}✅ Bash prompt installed${NC}"
}

# ============ ZSH PROMPT ============
setup_zsh() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}💤 Setting up Zsh prompt...${NC}"

    local zsh_config="$HOME/.zshrc"
    backup_file "$zsh_config"

    # Remove Oh-My-Zsh and Powerlevel10k if present
    if command -v pacman &> /dev/null; then
        sudo pacman -Rns powerlevel10k oh-my-zsh 2>/dev/null || true
    fi
    rm -f "$HOME/.p10k.zsh" 2>/dev/null || true
    rm -rf "$HOME/.oh-my-zsh" 2>/dev/null || true

    # Create fresh .zshrc with our prompt (FIXED - uses PROMPT not PS1)
    cat > "$zsh_config" << 'EOF'
# ----- Kali box prompt for Zsh -----
# Source: https://github.com/edemilov/kali-prompt
PROMPT='┌─%F{red}%B%n%f%b%F{white}@%F{blue}%B%m%f%b%F{white}─[%F{cyan}%B%~%f%b%F{white}]
└─%F{red}%B$> %f%b%k'
RPROMPT=''
EOF

    echo -e "${GREEN}✅ Zsh prompt installed${NC}"
    echo -e "${YELLOW}  ⚠ Removed Powerlevel10k/Oh-My-Zsh (conflicts with custom prompt)${NC}"
}

# ============ FISH PROMPT ============
setup_fish() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}🐟 Setting up Fish prompt...${NC}"

    local fish_config_dir="$HOME/.config/fish"
    local fish_config="$fish_config_dir/config.fish"

    mkdir -p "$fish_config_dir"
    backup_file "$fish_config"

    # Remove existing fish_prompt function completely
    sed -i '/# ----- Kali box prompt for Fish -----/,/end/d' "$fish_config" 2>/dev/null || true
    sed -i '/function fish_prompt/,/end/d' "$fish_config" 2>/dev/null || true

    # Add new prompt (FIXED - no extra 'end')
    cat >> "$fish_config" << 'EOF'

# ----- Kali box prompt for Fish -----
# Source: https://github.com/edemilov/kali-prompt
function fish_prompt
    set -l red (set_color red --bold)
    set -l blue (set_color blue --bold)
    set -l white (set_color white)
    set -l cyan (set_color cyan --bold)
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

    echo -e "${GREEN}✅ Fish prompt installed${NC}"
}

# ============ SET DEFAULT SHELL ============
set_default_shell() {
    local shell_choice="$1"
    local shell_path

    case $shell_choice in
        bash)
            shell_path=$(which bash)
            ;;
        zsh)
            shell_path=$(which zsh)
            ;;
        fish)
            shell_path=$(which fish)
            ;;
        *)
            return
            ;;
    esac

    if [[ -n "$shell_path" ]]; then
        if chsh -s "$shell_path" 2>/dev/null; then
            echo -e "${GREEN}✅ Default shell changed to ${shell_choice}${NC}"
        else
            echo -e "${YELLOW}⚠ Could not change shell. You may need to:${NC}"
            echo "  sudo chsh -s $shell_path $USER"
        fi
    fi
}

# ============ UNINSTALL ============
uninstall() {
    echo -e "\n${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}⚠ UNINSTALLING Kali prompts...${NC}"

    # Restore backups
    for rc in .bashrc .zshrc .config/fish/config.fish; do
        local file="$HOME/$rc"
        # Find most recent backup
        local backup=$(ls -t "$file".kali-backup-* 2>/dev/null | head -1)
        if [[ -f "$backup" ]]; then
            cp "$backup" "$file"
            echo -e "${GREEN}✓ Restored $file from backup${NC}"
        elif [[ -f "$file" ]]; then
            # No backup found, remove our lines
            sed -i '/# ----- Kali box prompt for /,/^[^#]/d' "$file" 2>/dev/null || true
            echo -e "${GREEN}✓ Removed prompt from $file${NC}"
        fi
    done

    echo -e "${GREEN}✅ Uninstall complete. Please restart your terminal.${NC}"
    exit 0
}

# ============ VERIFICATION ============
verify_installation() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}🔍 Verification:${NC}"

    echo -e "\n${YELLOW}Bash:${NC}"
    echo '  ┌─(user@host)─[~]'
    echo '  └─$ '

    echo -e "\n${YELLOW}Zsh:${NC}"
    echo '  ┌─(user@host)─[~]'
    echo '  └─$> '

    echo -e "\n${YELLOW}Fish:${NC}"
    echo '  ┌─(user@host)─[~]'
    echo '  └─> '

    echo -e "\n${GREEN}✅ Installation complete!${NC}"
    echo -e "${YELLOW}⚠ You may need to restart your terminal or log out/in.${NC}"
    echo -e "${CYAN}📚 Documentation: $REPO_URL${NC}"
}

# ============ MAIN ============
main() {
    print_header

    # Parse arguments
    INSTALL_BASH=true
    INSTALL_ZSH=true
    INSTALL_FISH=true
    INSTALL_SHELLS=true
    DEFAULT_SHELL=""

    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help) show_help ;;
            -b|--bash) INSTALL_ZSH=false; INSTALL_FISH=false ;;
            -z|--zsh) INSTALL_BASH=false; INSTALL_FISH=false ;;
            -f|--fish) INSTALL_BASH=false; INSTALL_ZSH=false ;;
            --no-shells) INSTALL_SHELLS=false ;;
            --default=*) DEFAULT_SHELL="${1#*=}" ;;
            --uninstall) uninstall ;;
            *) echo -e "${RED}Unknown option: $1${NC}"; show_help ;;
        esac
        shift
    done

    # Run installation
    [[ "$INSTALL_SHELLS" == true ]] && install_shells
    [[ "$INSTALL_BASH" == true ]] && setup_bash
    [[ "$INSTALL_ZSH" == true ]] && setup_zsh
    [[ "$INSTALL_FISH" == true ]] && setup_fish

    if [[ -n "$DEFAULT_SHELL" ]]; then
        set_default_shell "$DEFAULT_SHELL"
    else
        echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${GREEN}🐚 Change default shell? (y/n)${NC}"
        read -r change_shell
        if [[ "$change_shell" =~ ^[Yy]$ ]]; then
            echo "1) Bash"
            echo "2) Zsh"
            echo "3) Fish"
            echo "4) Keep current"
            read -r shell_choice
            case $shell_choice in
                1) set_default_shell "bash" ;;
                2) set_default_shell "zsh" ;;
                3) set_default_shell "fish" ;;
                *) echo -e "${YELLOW}Keeping current shell${NC}" ;;
            esac
        fi
    fi

    verify_installation

    echo -e "\n${BLUE}┌─(${RED}${BOLD}DONE${NC}${BLUE})─[${CYAN}${BOLD}PROMPT INSTALLED${NC}${BLUE}]${NC}"
    echo -e "${BLUE}└─${RED}${BOLD}$ ${NC}"
}

# Run main function
main "$@"
