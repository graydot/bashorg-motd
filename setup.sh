#!/bin/bash

# Setup script for Bash.org MOTD
# Automatically detects shell environment and adds MOTD to appropriate RC file

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MOTD_SCRIPT="$SCRIPT_DIR/motd.sh"
WUT_SCRIPT="$SCRIPT_DIR/wut"
MOTD_COMMENT="# Bash.org MOTD Quote"

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to detect current shell
detect_shell() {
    local shell_name=$(basename "$SHELL")
    echo "$shell_name"
}

# Function to get RC file path for a given shell
get_rc_file() {
    local shell="$1"
    case "$shell" in
        "bash")
            # Check for .bashrc first, then .bash_profile
            if [ -f "$HOME/.bashrc" ]; then
                echo "$HOME/.bashrc"
            elif [ -f "$HOME/.bash_profile" ]; then
                echo "$HOME/.bash_profile"
            else
                echo "$HOME/.bashrc"  # Default to .bashrc
            fi
            ;;
        "zsh")
            echo "$HOME/.zshrc"
            ;;
        "fish")
            echo "$HOME/.config/fish/config.fish"
            ;;
        *)
            echo "$HOME/.profile"  # Fallback
            ;;
    esac
}

# Function to check if MOTD is already configured
is_motd_configured() {
    local rc_file="$1"
    [ -f "$rc_file" ] && grep -q "$MOTD_SCRIPT" "$rc_file"
}

# Function to add MOTD to RC file
add_motd_to_rc() {
    local rc_file="$1"
    local shell="$2"
    
    # Create directory if it doesn't exist (for fish)
    local rc_dir=$(dirname "$rc_file")
    if [ ! -d "$rc_dir" ]; then
        mkdir -p "$rc_dir"
        print_info "Created directory: $rc_dir"
    fi
    
    # Create RC file if it doesn't exist
    if [ ! -f "$rc_file" ]; then
        touch "$rc_file"
        print_info "Created RC file: $rc_file"
    fi
    
    # Add MOTD configuration
    echo "" >> "$rc_file"
    echo "$MOTD_COMMENT" >> "$rc_file"
    
    if [ "$shell" = "fish" ]; then
        # Fish shell syntax
        echo "if test -f \"$MOTD_SCRIPT\"" >> "$rc_file"
        echo "    \"$MOTD_SCRIPT\"" >> "$rc_file"
        echo "end" >> "$rc_file"
        
        # Add wut command to PATH
        if [ -f "$WUT_SCRIPT" ]; then
            echo "# Add wut command to PATH" >> "$rc_file"
            echo "set -gx PATH \"$SCRIPT_DIR\" \$PATH" >> "$rc_file"
        fi
    else
        # Bash/Zsh syntax
        echo "if [ -f \"$MOTD_SCRIPT\" ]; then" >> "$rc_file"
        echo "    \"$MOTD_SCRIPT\"" >> "$rc_file"
        echo "fi" >> "$rc_file"
        
        # Add wut command to PATH
        if [ -f "$WUT_SCRIPT" ]; then
            echo "# Add wut command to PATH" >> "$rc_file"
            echo "export PATH=\"$SCRIPT_DIR:\$PATH\"" >> "$rc_file"
        fi
    fi
    
    print_success "Added MOTD to $rc_file"
}

# Function to remove MOTD from RC file
remove_motd_from_rc() {
    local rc_file="$1"
    
    if [ -f "$rc_file" ]; then
        # Create a temporary file without the MOTD section
        local temp_file=$(mktemp)
        local in_motd_section=false
        
        while IFS= read -r line; do
            if [[ "$line" == "$MOTD_COMMENT" ]]; then
                in_motd_section=true
                continue
            elif [[ "$in_motd_section" == true ]]; then
                # Skip lines that are part of the MOTD section
                if [[ "$line" == "if"* ]] || [[ "$line" == "    "* ]] || [[ "$line" == "fi" ]] || [[ "$line" == "end" ]] || [[ "$line" == "" ]]; then
                    continue
                else
                    in_motd_section=false
                    echo "$line" >> "$temp_file"
                fi
            else
                echo "$line" >> "$temp_file"
            fi
        done < "$rc_file"
        
        mv "$temp_file" "$rc_file"
        print_success "Removed MOTD from $rc_file"
    fi
}

# Function to show current configuration
show_status() {
    local shell=$(detect_shell)
    local rc_file=$(get_rc_file "$shell")
    
    echo -e "${BLUE}Current Configuration:${NC}"
    echo "  Shell: $shell"
    echo "  RC File: $rc_file"
    echo "  MOTD Script: $MOTD_SCRIPT"
    
    if is_motd_configured "$rc_file"; then
        echo -e "  Status: ${GREEN}CONFIGURED${NC}"
    else
        echo -e "  Status: ${YELLOW}NOT CONFIGURED${NC}"
    fi
}

# Function to install MOTD
install_motd() {
    local shell=$(detect_shell)
    local rc_file=$(get_rc_file "$shell")
    
    print_info "Detected shell: $shell"
    print_info "RC file: $rc_file"
    
    # Check if MOTD script exists
    if [ ! -f "$MOTD_SCRIPT" ]; then
        print_error "MOTD script not found at: $MOTD_SCRIPT"
        print_error "Please ensure motd.sh is in the same directory as this setup script"
        exit 1
    fi
    
    # Make MOTD script executable
    chmod +x "$MOTD_SCRIPT"
    
    # Make wut command executable
    if [ -f "$WUT_SCRIPT" ]; then
        chmod +x "$WUT_SCRIPT"
    fi
    
    # Check if already configured
    if is_motd_configured "$rc_file"; then
        print_warning "MOTD is already configured in $rc_file"
        read -p "Do you want to reinstall? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            remove_motd_from_rc "$rc_file"
            add_motd_to_rc "$rc_file" "$shell"
        else
            print_info "Installation cancelled"
            exit 0
        fi
    else
        add_motd_to_rc "$rc_file" "$shell"
    fi
    
    print_success "MOTD setup complete!"
    print_info "To activate immediately, run: source $rc_file"
    print_info "Or open a new terminal to see the MOTD"
}

# Function to uninstall MOTD
uninstall_motd() {
    local shell=$(detect_shell)
    local rc_file=$(get_rc_file "$shell")
    
    if is_motd_configured "$rc_file"; then
        remove_motd_from_rc "$rc_file"
        print_success "MOTD removed from $rc_file"
    else
        print_warning "MOTD is not configured in $rc_file"
    fi
}

# Function to test MOTD
test_motd() {
    if [ -f "$MOTD_SCRIPT" ]; then
        print_info "Testing MOTD script..."
        "$MOTD_SCRIPT"
    else
        print_error "MOTD script not found at: $MOTD_SCRIPT"
        exit 1
    fi
}

# Function to show help
show_help() {
    echo "Bash.org MOTD Setup Script"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  install     Install MOTD to your shell RC file (default)"
    echo "  uninstall   Remove MOTD from your shell RC file"
    echo "  status      Show current configuration status"
    echo "  test        Test the MOTD script"
    echo "  help        Show this help message"
    echo ""
    echo "Supported shells: bash, zsh, fish"
    echo ""
    echo "Examples:"
    echo "  $0                # Install MOTD"
    echo "  $0 install        # Install MOTD"
    echo "  $0 uninstall      # Remove MOTD"
    echo "  $0 status         # Show configuration"
    echo "  $0 test           # Test MOTD display"
}

# Main function
main() {
    case "${1:-install}" in
        "install")
            install_motd
            ;;
        "uninstall")
            uninstall_motd
            ;;
        "status")
            show_status
            ;;
        "test")
            test_motd
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            print_error "Unknown command: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

main "$@"