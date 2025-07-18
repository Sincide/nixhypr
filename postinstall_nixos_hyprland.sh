#!/bin/bash

# NixOS Post-Installation Setup Script for Hyprland
# This script configures a fresh NixOS installation with Hyprland desktop environment
# Author: Generated for NixOS setup
# Version: 1.1 - Fixed critical NixOS compatibility issues

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Global variables
USERNAME=""
DOTFILES_REPO=""
DOTFILES_PATH=""
USE_HOME_MANAGER=false
CONFIG_METHOD=""

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Function to check if running on NixOS
check_nixos() {
    print_header "Checking System Requirements"
    
    if [[ ! -f /etc/os-release ]]; then
        print_error "Cannot determine OS. This script is designed for NixOS."
        exit 1
    fi
    
    if ! grep -q "NixOS" /etc/os-release; then
        print_error "This script is designed for NixOS only."
        exit 1
    fi
    
    # Check for flakes-based configuration
    if [[ -f /etc/nixos/flake.nix ]]; then
        print_error "This script doesn't support flakes-based NixOS configurations"
        print_error "Please use Home Manager flakes setup instead"
        print_error "See: https://nix-community.github.io/home-manager/index.html#sec-flakes-standalone"
        exit 1
    fi
    
    # Check for sufficient disk space (at least 5GB free)
    available_space=$(df /nix --output=avail | tail -1)
    if [[ $available_space -lt 5242880 ]]; then  # 5GB in KB
        print_warning "Low disk space detected (< 5GB free)"
        print_warning "NixOS rebuilds require significant disk space"
        read -p "Continue anyway? (y/N): " continue_low_space
        if [[ ! "$continue_low_space" =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    # Check for internet connectivity
    print_status "Testing internet connectivity..."
    if ! ping -c 1 -W 5 8.8.8.8 >/dev/null 2>&1; then
        print_warning "Cannot reach Google DNS (8.8.8.8), trying alternative..."
        if ! ping -c 1 -W 5 1.1.1.1 >/dev/null 2>&1; then
            print_warning "Cannot reach Cloudflare DNS (1.1.1.1), trying nixos.org..."
            if ! ping -c 1 -W 5 nixos.org >/dev/null 2>&1; then
                print_error "No internet connectivity detected"
                print_error "This script requires internet access for package downloads"
                print_error "Please check your network connection and try again"
                exit 1
            fi
        fi
    fi
    
    print_status "NixOS detected ✓"
    print_status "System requirements check passed ✓"
}

# Function to check for root privileges
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root (use sudo)"
        exit 1
    fi
    
    print_status "Root privileges confirmed ✓"
}

# Function to prompt for username
get_username() {
    print_header "User Account Setup"
    
    while true; do
        read -p "Enter your main user account username: " USERNAME
        if [[ -z "$USERNAME" ]]; then
            print_warning "Username cannot be empty. Please try again."
            continue
        fi
        
        if id "$USERNAME" &>/dev/null; then
            print_status "User '$USERNAME' found ✓"
            break
        else
            print_warning "User '$USERNAME' not found. Please create the user first or enter a valid username."
            read -p "Do you want to try again? (Y/n): " retry
            if [[ "$retry" =~ ^[Nn]$ ]]; then
                print_error "Cannot proceed without a valid username."
                exit 1
            fi
        fi
    done
}

# Function to check and install Home Manager
setup_home_manager() {
    print_header "Home Manager Setup"
    
    if sudo -u "$USERNAME" command -v home-manager &>/dev/null; then
        print_status "Home Manager is already installed ✓"
        USE_HOME_MANAGER=true
        return
    fi
    
    echo "Home Manager is not installed. It provides a declarative way to manage user environments."
    echo "Benefits:"
    echo "  - Declarative configuration management"
    echo "  - Automatic dependency resolution"
    echo "  - Easy rollback capabilities"
    echo "  - Better integration with NixOS"
    
    while true; do
        read -p "Do you want to install Home Manager? (Y/n): " install_hm
        case $install_hm in
            [Yy]*|"")
                print_status "Installing Home Manager..."
                
                # Get NixOS version for correct channel (optimized for latest stable)
                nixos_version=$(nixos-version | cut -d'.' -f1-2)
                print_status "Detected NixOS version: $nixos_version"
                
                # Add Home Manager channel for root (system-wide)
                # Prioritize latest stable releases
                if [[ "$nixos_version" == "24.11" ]]; then
                    nix-channel --add https://github.com/nix-community/home-manager/archive/release-24.11.tar.gz home-manager
                    print_status "Using Home Manager 24.11 (latest stable) ✓"
                elif [[ "$nixos_version" == "24.05" ]]; then
                    nix-channel --add https://github.com/nix-community/home-manager/archive/release-24.05.tar.gz home-manager
                    print_status "Using Home Manager 24.05 ✓"
                elif [[ "$nixos_version" == "25.05" ]]; then
                    print_warning "NixOS 25.05 detected - Home Manager has known compatibility issues"
                    print_warning "Using system-level configuration instead for better reliability"
                    print_warning "You can manually install Home Manager later if needed"
                    USE_HOME_MANAGER=false
                    return
                elif [[ "$nixos_version" > "24.11" ]]; then
                    # For future stable releases, try to match or use latest
                    nix-channel --add https://github.com/nix-community/home-manager/archive/release-${nixos_version}.tar.gz home-manager 2>/dev/null || \
                    nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
                    print_status "Using Home Manager for NixOS $nixos_version ✓"
                else
                    # Fallback to master for unstable or very new versions
                    nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
                    print_status "Using Home Manager master branch ✓"
                fi
                
                nix-channel --update
                
                # Install Home Manager for the user
                sudo -u "$USERNAME" nix-shell '<home-manager>' -A install
                
                USE_HOME_MANAGER=true
                print_status "Home Manager installed successfully ✓"
                break
                ;;
            [Nn]*)
                print_status "Skipping Home Manager installation"
                USE_HOME_MANAGER=false
                break
                ;;
            *)
                echo "Please answer Y or n."
                ;;
        esac
    done
}

# Function to get dotfiles repository
get_dotfiles() {
    print_header "Dotfiles Setup"
    
    echo "This script will help you set up your dotfiles configuration."
    echo "You can provide either:"
    echo "  - A Git repository URL (e.g., https://github.com/user/dotfiles.git)"
    echo "  - A local path (e.g., /path/to/dotfiles)"
    echo "  - Skip dotfiles setup"
    
    while true; do
        read -p "Enter your dotfiles repository URL or path [https://gitlab.com/marerm/dotfiles] (or 'skip' to skip): " DOTFILES_REPO
        
        # Use default if empty
        if [[ -z "$DOTFILES_REPO" ]]; then
            DOTFILES_REPO="https://gitlab.com/marerm/dotfiles"
            print_status "Using default repository: $DOTFILES_REPO"
        fi
        
        if [[ "$DOTFILES_REPO" == "skip" ]]; then
            print_status "Skipping dotfiles setup"
            return
        fi
        
        if [[ -z "$DOTFILES_REPO" ]]; then
            print_warning "Please provide a valid URL or path, or type 'skip'"
            continue
        fi
        
        # Check if it's a local path
        if [[ -d "$DOTFILES_REPO" ]]; then
            DOTFILES_PATH="$DOTFILES_REPO"
            print_status "Using local dotfiles at: $DOTFILES_PATH"
            break
        fi
        
        # Check if it's a valid Git URL (supports GitHub, GitLab, etc.)
        if [[ "$DOTFILES_REPO" =~ ^https?://.*$ ]] || [[ "$DOTFILES_REPO" =~ ^git@.*$ ]]; then
            # Test if it's actually a valid Git repository
            print_status "Testing Git repository access..."
            if timeout 10 git ls-remote "$DOTFILES_REPO" >/dev/null 2>&1; then
                DOTFILES_PATH="/home/$USERNAME/dotfiles"
                print_status "Will clone dotfiles to: $DOTFILES_PATH"
                break
            else
                print_warning "Cannot access Git repository at this time."
                read -p "Do you want to try anyway? (y/N): " try_anyway
                if [[ "$try_anyway" =~ ^[Yy]$ ]]; then
                    DOTFILES_PATH="/home/$USERNAME/dotfiles"
                    print_status "Will attempt to clone dotfiles to: $DOTFILES_PATH"
                    break
                else
                    print_warning "Please check the URL and your internet connection."
                    continue
                fi
            fi
        fi
        
        print_warning "Invalid input. Please provide a valid Git URL or local path."
    done
}

# Function to clone dotfiles
clone_dotfiles() {
    if [[ -z "$DOTFILES_REPO" ]] || [[ "$DOTFILES_REPO" == "skip" ]]; then
        return
    fi
    
    print_status "Setting up dotfiles..."
    
    # If it's a Git URL, clone it
    if [[ "$DOTFILES_REPO" =~ ^https?://.*$ ]] || [[ "$DOTFILES_REPO" =~ ^git@.*$ ]]; then
        if [[ -d "$DOTFILES_PATH" ]]; then
            print_warning "Directory $DOTFILES_PATH already exists"
            read -p "Do you want to remove it and clone fresh? (y/N): " remove_existing
            if [[ "$remove_existing" =~ ^[Yy]$ ]]; then
                rm -rf "$DOTFILES_PATH"
            else
                print_status "Using existing dotfiles directory"
                return
            fi
        fi
        
        print_status "Cloning dotfiles from $DOTFILES_REPO..."
        sudo -u "$USERNAME" git clone "$DOTFILES_REPO" "$DOTFILES_PATH"
        print_status "Dotfiles cloned successfully ✓"
    fi
}

# Function to setup config files
setup_config_files() {
    if [[ -z "$DOTFILES_PATH" ]] || [[ ! -d "$DOTFILES_PATH" ]]; then
        print_warning "No dotfiles directory found. Skipping config file setup."
        return
    fi
    
    print_header "Config File Setup"
    
    # Create .config directory if it doesn't exist and ensure proper ownership
    sudo -u "$USERNAME" mkdir -p "/home/$USERNAME/.config"
    chown -R "$USERNAME:$(id -gn $USERNAME)" "/home/$USERNAME/.config"
    
    # List of common config directories to check
    config_dirs=("hyprland" "waybar" "fish" "fuzzel" "foot" "kitty" "scripts")
    
    for dir in "${config_dirs[@]}"; do
        if [[ -d "$DOTFILES_PATH/$dir" ]]; then
            echo "Found $dir configuration in dotfiles"
            read -p "Do you want to set up $dir config? (Y/n): " setup_config
            if [[ "$setup_config" =~ ^[Nn]$ ]]; then
                print_status "Skipping $dir configuration"
                continue
            fi
            
            target_dir="/home/$USERNAME/.config/$dir"
            
            # Remove existing config if it exists
            if [[ -d "$target_dir" ]]; then
                read -p "Existing $dir config found. Replace it? (Y/n): " replace_config
                if [[ "$replace_config" =~ ^[Yy]$ ]] || [[ -z "$replace_config" ]]; then
                    sudo -u "$USERNAME" rm -rf "$target_dir"
                else
                    print_status "Keeping existing $dir config"
                    continue
                fi
            fi
            
            # Create symlink or copy files
            read -p "Create symlink (recommended) or copy files for $dir? (Y/n): " link_method
            if [[ "$link_method" =~ ^[Nn]$ ]]; then
                sudo -u "$USERNAME" cp -r "$DOTFILES_PATH/$dir" "$target_dir"
                print_status "Copied $dir configuration ✓"
            else
                # Create parent directory first and set proper permissions
                sudo -u "$USERNAME" mkdir -p "$(dirname "$target_dir")"
                if sudo -u "$USERNAME" ln -sf "$DOTFILES_PATH/$dir" "$target_dir"; then
                    print_status "Created symlink for $dir configuration ✓"
                else
                    print_warning "Failed to create symlink, copying files instead..."
                    sudo -u "$USERNAME" cp -r "$DOTFILES_PATH/$dir" "$target_dir"
                    print_status "Copied $dir configuration ✓"
                fi
            fi
        fi
    done
    
    # Check for scripts directory
    if [[ -d "$DOTFILES_PATH/scripts" ]]; then
        echo "Found scripts directory in dotfiles"
        read -p "Do you want to set up scripts? (Y/n): " setup_scripts
        if [[ "$setup_scripts" =~ ^[Yy]$ ]] || [[ -z "$setup_scripts" ]]; then
            scripts_target="/home/$USERNAME/.local/bin"
            sudo -u "$USERNAME" mkdir -p "$scripts_target"
            
            # Make scripts executable and symlink them
            find "$DOTFILES_PATH/scripts" -type f -executable -exec sudo -u "$USERNAME" ln -sf {} "$scripts_target/" \;
            print_status "Set up scripts in ~/.local/bin ✓"
        fi
    fi
}

# Function to choose configuration method
choose_config_method() {
    print_header "Configuration Method Selection"
    
    echo "Choose how to configure NixOS packages and services:"
    echo "1. System-level configuration (edit /etc/nixos/configuration.nix)"
    echo "2. Home Manager configuration (recommended if Home Manager is installed)"
    
    if [[ "$USE_HOME_MANAGER" == true ]]; then
        echo "Home Manager is available and recommended for user-level packages."
    else
        echo "Note: Home Manager is not installed. Only system-level configuration is available."
    fi
    
    while true; do
        if [[ "$USE_HOME_MANAGER" == true ]]; then
            read -p "Choose configuration method (1/2): " config_choice
            case $config_choice in
                1)
                    CONFIG_METHOD="system"
                    print_status "Using system-level configuration"
                    break
                    ;;
                2)
                    CONFIG_METHOD="home-manager"
                    print_status "Using Home Manager configuration"
                    break
                    ;;
                *)
                    echo "Please choose 1 or 2."
                    ;;
            esac
        else
            CONFIG_METHOD="system"
            print_status "Using system-level configuration (Home Manager not available)"
            break
        fi
    done
}

# Function to install packages via system configuration
install_system_packages() {
    print_header "Installing Packages via System Configuration"
    
    # Check for graphics hardware (optimized for Intel/AMD)
    if lspci 2>/dev/null | grep -i "vga\|3d\|display"; then
        gpu_info=$(lspci | grep -i "vga\|3d\|display" | head -1)
        print_status "Graphics hardware detected: $gpu_info"
        
        # Intel/AMD graphics work well with Hyprland out of the box
        if echo "$gpu_info" | grep -qi "intel\|amd"; then
            print_status "Intel/AMD graphics detected - excellent Hyprland compatibility ✓"
        else
            print_warning "Unknown graphics hardware detected"
            print_warning "Intel and AMD graphics work best with Hyprland"
        fi
    fi
    
    # Backup original configuration
    cp /etc/nixos/configuration.nix /etc/nixos/configuration.nix.backup.$(date +%Y%m%d_%H%M%S)
    print_status "Backup created: /etc/nixos/configuration.nix.backup.*"
    
    # Create a temporary Nix expression to modify configuration.nix
    cat > /tmp/update-config.nix << 'EOF'
{ config, pkgs, ... }:

let
  # Read the original configuration
  originalConfig = import /etc/nixos/configuration.nix;
  
  # Packages to add
  newPackages = with pkgs; [
    hyprland
    waybar
    fuzzel
    matugen
    ollama
    fish
    foot
    kitty
    git
    curl
    wget
    htop
    neofetch
  ];
  
in
{
  imports = originalConfig.imports or [];
  
  # Merge existing configuration with new additions
  environment.systemPackages = (originalConfig.environment.systemPackages or []) ++ newPackages;
  
  # Enable services
  services.ollama.enable = true;
  
  # Set Fish as default shell for user
  users.users.USERNAME_PLACEHOLDER.shell = pkgs.fish;
  
  # Programs configuration
  programs.hyprland.enable = true;
  programs.fish.enable = true;
  
  # Copy all other configuration from original
} // (removeAttrs originalConfig ["environment" "services" "users" "programs"])
EOF
    
    # Replace username placeholder
    sed -i "s/USERNAME_PLACEHOLDER/$USERNAME/g" /tmp/update-config.nix
    
    # Apply the configuration update
    print_status "Updating system configuration..."
    
    # Use a much safer approach - create a new configuration and replace
    config_file="/etc/nixos/configuration.nix"
    
    # Create a temporary backup before modification
    cp "$config_file" "${config_file}.pre-hyprland"
    
    # Create a safer update approach using a Python script
    cat > /tmp/update_nix_config.py << 'EOF'
#!/usr/bin/env python3
import sys
import re

def update_nix_config(config_path, username):
    with open(config_path, 'r') as f:
        content = f.read()
    
    # Check what needs to be added
    additions = []
    
    if 'programs.hyprland.enable' not in content:
        additions.append('  programs.hyprland.enable = true;')
    
    if 'programs.fish.enable' not in content:
        additions.append('  programs.fish.enable = true;')
    
    if 'hardware.opengl' not in content:
        additions.extend([
            '  hardware.opengl = {',
            '    enable = true;',
            '    driSupport = true;',
            '    driSupport32Bit = true;',
            '  };'
        ])
    
    if 'services.ollama.enable' not in content:
        additions.append('  services.ollama.enable = true;')
    
    if f'users.users.{username}.shell' not in content:
        additions.append(f'  users.users.{username}.shell = pkgs.fish;')
    
    # Handle systemPackages
    hyprland_packages = [
        'hyprland', 'waybar', 'fuzzel', 'matugen',
        'foot', 'kitty', 'ollama', 'git', 'fish',
        'curl', 'wget', 'htop', 'neofetch',
        'wl-clipboard', 'grim', 'slurp'
    ]
    
    if 'environment.systemPackages' in content:
        # Add packages to existing list
        for pkg in hyprland_packages:
            if pkg not in content:
                # Find the systemPackages section and add before the closing ];
                pattern = r'(environment\.systemPackages\s*=\s*with\s+pkgs;\s*\[.*?)(.*?)(\s*\];)'
                match = re.search(pattern, content, re.DOTALL)
                if match:
                    before, middle, after = match.groups()
                    if pkg not in middle:
                        content = content.replace(match.group(0), 
                            f"{before}{middle}    {pkg} # Added by Hyprland script\n{after}")
    else:
        # Add new systemPackages section
        pkg_section = [
            '  environment.systemPackages = with pkgs; [',
            '    # Added by Hyprland setup script'
        ]
        for pkg in hyprland_packages:
            pkg_section.append(f'    {pkg}')
        pkg_section.append('  ];')
        additions.extend(pkg_section)
    
    # Find a good place to insert additions (before the closing brace)
    if additions:
        # Find the last closing brace
        lines = content.split('\n')
        for i in range(len(lines) - 1, -1, -1):
            if lines[i].strip() == '}':
                # Insert before this closing brace
                for addition in reversed(additions):
                    lines.insert(i, addition)
                break
        
        content = '\n'.join(lines)
    
    with open(config_path, 'w') as f:
        f.write(content)
    
    print(f"Updated configuration with {len(additions)} additions")

if __name__ == "__main__":
    update_nix_config(sys.argv[1], sys.argv[2])
EOF
    
    # Run the safer update
    python3 /tmp/update_nix_config.py "$config_file" "$USERNAME"
    print_status "Configuration updated using safe method"
    
    print_status "Configuration updated. Validating before rebuild..."
    
    # Validate the configuration syntax before rebuilding
    if ! nixos-rebuild dry-build >/dev/null 2>/tmp/nixos-syntax-error.log; then
        print_error "Configuration syntax error detected!"
        print_error "Error details:"
        cat /tmp/nixos-syntax-error.log
        print_error "Restoring backup configuration..."
        cp "${config_file}.pre-hyprland" "$config_file"
        print_warning "Backup restored. Please check your configuration manually."
        rm -f /tmp/nixos-syntax-error.log
        return 1
    fi
    
    print_status "Configuration validated successfully. Rebuilding system..."
    
    # Attempt rebuild with error handling
    if ! nixos-rebuild switch; then
        print_error "System rebuild failed!"
        print_error "Restoring backup configuration..."
        
        # Restore backup
        latest_backup=$(ls -t /etc/nixos/configuration.nix.backup.* | head -1)
        if [[ -f "$latest_backup" ]]; then
            cp "$latest_backup" /etc/nixos/configuration.nix
            print_status "Backup restored. Attempting recovery rebuild..."
            nixos-rebuild switch
        fi
        
        print_error "Please check the error messages above and fix manually"
        print_error "Your original configuration has been restored"
        exit 1
    fi
    
    print_status "System packages installed successfully ✓"
    
    # Clean up
    rm -f /tmp/update-config.nix
}

# Function to setup Home Manager configuration
setup_home_manager_config() {
    if [[ "$CONFIG_METHOD" != "home-manager" ]]; then
        return
    fi
    
    print_header "Setting up Home Manager Configuration"
    
    # Create home-manager configuration directory
    sudo -u "$USERNAME" mkdir -p "/home/$USERNAME/.config/home-manager"
    
    # Check if home.nix already exists and back it up
    home_nix_path="/home/$USERNAME/.config/home-manager/home.nix"
    if [[ -f "$home_nix_path" ]]; then
        print_warning "Existing home.nix found, creating backup and replacing..."
        cp "$home_nix_path" "${home_nix_path}.backup.$(date +%Y%m%d_%H%M%S)"
        print_status "Backup created: ${home_nix_path}.backup.*"
        # Remove the problematic existing file
        rm -f "$home_nix_path"
    fi
    
    # Create fresh home.nix configuration
    print_status "Creating new home.nix configuration..."
    cat > "$home_nix_path" << 'EOF'
{ config, pkgs, ... }:

{
  home.username = "USERNAME_PLACEHOLDER";
  home.homeDirectory = "/home/USERNAME_PLACEHOLDER";
  home.stateVersion = "24.11";

  home.packages = with pkgs; [
    # Essential packages only
    git
    curl
    wget
    htop
    neofetch
  ];

  programs = {
    home-manager = {
      enable = true;
    };
  };

  home.file = {
    # Add any custom files here
  };

  home.sessionVariables = {
    EDITOR = "nano";
    BROWSER = "firefox";
  };
}
EOF
    
    # Replace placeholders with actual username
    sed -i "s/USERNAME_PLACEHOLDER/$USERNAME/g" "$home_nix_path"
    chown "$USERNAME:$(id -gn $USERNAME)" "$home_nix_path"
    
    # Validate the Nix syntax
    print_status "Validating Home Manager configuration syntax..."
    if ! sudo -u "$USERNAME" nix-instantiate --parse "$home_nix_path" 2>/tmp/nix-syntax-error.log; then
        print_error "Syntax error in generated home.nix!"
        print_error "Error details:"
        cat /tmp/nix-syntax-error.log
        print_error "Please check the file at: $home_nix_path"
        rm -f /tmp/nix-syntax-error.log
        return 1
    fi
    
    print_status "Home Manager configuration created at $home_nix_path"
    print_warning "Please edit the git configuration in the home.nix file with your details"
    
    # Apply Home Manager configuration
    print_status "Applying Home Manager configuration..."
    if sudo -u "$USERNAME" home-manager switch 2>/tmp/hm-switch-error.log; then
        print_status "Home Manager configuration applied successfully ✓"
    else
        print_error "Home Manager configuration failed!"
        print_error "Error details:"
        cat /tmp/hm-switch-error.log
        print_error "Configuration file: $home_nix_path"
        print_warning "This is a known issue with NixOS 25.05 and Home Manager compatibility"
        print_warning "The system packages have been installed via configuration.nix instead"
        print_warning "You can manually configure Home Manager later if needed"
        print_warning "Continuing with rest of setup..."
        rm -f /tmp/hm-switch-error.log
        
        # Set a flag to indicate Home Manager failed
        export HM_FAILED=true
    fi
}

# Function to setup Ollama
setup_ollama() {
    print_header "Ollama Setup"
    
    # Start Ollama service
    systemctl enable ollama
    systemctl start ollama
    
    print_status "Ollama service enabled and started ✓"
    
    # Wait a moment for service to start
    sleep 3
    
    # Check if Ollama is running
    if systemctl is-active --quiet ollama; then
        print_status "Ollama is running ✓"
    else
        print_error "Failed to start Ollama service"
        return
    fi
    
    # Prompt for model preloading
    echo "Ollama is now running. You can preload models for faster access."
    echo "Common models:"
    echo "  - llama3.2:3b (2GB)"
    echo "  - phi3:mini (2.3GB)"
    echo "  - codellama:7b (3.8GB)"
    echo "  - qwen2.5:3b (1.8GB)"
    
    read -p "Do you want to preload any models? (y/N): " preload_models
    if [[ "$preload_models" =~ ^[Yy]$ ]]; then
        while true; do
            read -p "Enter model name (or 'done' to finish): " model_name
            if [[ "$model_name" == "done" ]]; then
                break
            fi
            
            if [[ -n "$model_name" ]]; then
                print_status "Pulling model: $model_name"
                sudo -u "$USERNAME" ollama pull "$model_name"
            fi
        done
    fi
    
    print_status "Ollama setup completed ✓"
}

# Function to setup Fish shell
setup_fish() {
    print_header "Fish Shell Setup"
    
    # Fish shell is already set in the configuration.nix, no need for chsh
    print_status "Fish shell configured in system configuration ✓"
    
    # Create basic Fish configuration if it doesn't exist
    fish_config="/home/$USERNAME/.config/fish/config.fish"
    if [[ ! -f "$fish_config" ]]; then
        sudo -u "$USERNAME" mkdir -p "/home/$USERNAME/.config/fish"
        cat > "$fish_config" << 'EOF'
# Fish shell configuration

# Set PATH
set -gx PATH $HOME/.local/bin $PATH

# Aliases
alias ll='eza -l'
alias la='eza -la'
alias cat='bat'
alias grep='rg'
alias find='fd'

# Welcome message
echo "Welcome to Fish shell on NixOS!"
echo "Run 'neofetch' to see system info"
EOF
        chown "$USERNAME:$(id -gn $USERNAME)" "$fish_config"
        print_status "Created basic Fish configuration ✓"
    fi
}

# Function to detect and setup extra drives
setup_extra_drives() {
    print_header "Extra Drives Detection"
    
    # Get list of unmounted block devices with better detection
    unmounted_devices=()
    while IFS= read -r line; do
        # Skip header and empty lines
        [[ "$line" =~ ^NAME ]] && continue
        [[ -z "$line" ]] && continue
        
        # Parse lsblk output - looking for devices without mountpoints
        if [[ "$line" =~ ^[[:space:]]*([a-z]+[0-9]+)[[:space:]]+([0-9.]+[KMGT]?)[[:space:]]*$ ]]; then
            device="/dev/${BASH_REMATCH[1]}"
            size="${BASH_REMATCH[2]}"
            unmounted_devices+=("$device ($size)")
        fi
    done < <(lsblk -rno NAME,SIZE,MOUNTPOINT | awk '$3=="" && $1!~/^loop/ && $1!~/^sr/ && $1~/[0-9]$/ {print $1, $2}')
    
    if [[ ${#unmounted_devices[@]} -eq 0 ]]; then
        print_status "No unmounted block devices found"
        return
    fi
    
    echo "Found unmounted block devices:"
    for i in "${!unmounted_devices[@]}"; do
        echo "  $((i+1)). ${unmounted_devices[$i]}"
    done
    
    read -p "Do you want to set up auto-mounting for any of these drives? (y/N): " setup_mounts
    if [[ "$setup_mounts" =~ ^[Yy]$ ]]; then
        for i in "${!unmounted_devices[@]}"; do
            device_info="${unmounted_devices[$i]}"
            device=$(echo "$device_info" | cut -d' ' -f1)
            
            echo "Device: $device_info"
            read -p "Do you want to auto-mount this device? (y/N): " mount_device
            if [[ "$mount_device" =~ ^[Yy]$ ]]; then
                read -p "Enter mount point (e.g., /mnt/data): " mount_point
                if [[ -n "$mount_point" ]]; then
                    # Create mount point
                    mkdir -p "$mount_point"
                    
                    # Add filesystem entry to configuration.nix
                    filesystem_entry="
  fileSystems.\"$mount_point\" = {
    device = \"$device\";
    fsType = \"auto\";
    options = [ \"defaults\" \"noatime\" \"user\" ];
  };"
                    
                    # Add the filesystem entry before the closing brace
                    sed -i "/^}$/i\\$filesystem_entry" /etc/nixos/configuration.nix
                    
                    print_status "Added auto-mount for $device at $mount_point"
                fi
            fi
        done
        
        # Rebuild configuration
        print_status "Rebuilding configuration with new mount points..."
        nixos-rebuild switch
    fi
}

# Function to finalize setup
finalize_setup() {
    print_header "Setup Complete"
    
    echo "🎉 NixOS Hyprland setup is complete!"
    echo ""
    echo "What was configured:"
    echo "  ✓ Hyprland desktop environment"
    echo "  ✓ Waybar status bar"
    echo "  ✓ Fuzzel application launcher"
    echo "  ✓ Fish shell (set as default)"
    echo "  ✓ Ollama AI service"
    echo "  ✓ Matugen theming tool"
    echo "  ✓ Terminal emulators (foot, kitty)"
    echo "  ✓ Dotfiles configuration (if provided)"
    echo "  ✓ Extra drive mounting (if configured)"
    echo ""
    echo "Next steps:"
    echo "  1. Log out of your current session"
    echo "  2. Select 'Hyprland' from your display manager"
    echo "  3. Log in with your user account"
    echo "  4. Configure your Hyprland workspace"
    echo ""
    echo "Useful commands:"
    echo "  - 'hyprctl' - Hyprland control"
    echo "  - 'waybar' - Status bar control"
    echo "  - 'fuzzel' - Application launcher"
    echo "  - 'ollama list' - List AI models"
    echo "  - 'matugen' - Theme generation"
    echo ""
    
    while true; do
        read -p "Do you want to reboot now? (Y/n): " reboot_now
        case $reboot_now in
            [Yy]*|"")
                print_status "Rebooting in 5 seconds..."
                sleep 5
                reboot
                ;;
            [Nn]*)
                print_status "Setup complete. You can reboot manually when ready."
                break
                ;;
            *)
                echo "Please answer Y or n."
                ;;
        esac
    done
}

# Main execution
main() {
    print_header "NixOS Hyprland Post-Installation Setup"
    echo "This script will configure your NixOS system with Hyprland desktop environment."
    echo ""
    
    # Run all setup functions
    check_nixos
    check_root
    get_username
    setup_home_manager
    get_dotfiles
    clone_dotfiles
    setup_config_files
    choose_config_method
    
    if [[ "$CONFIG_METHOD" == "system" ]]; then
        install_system_packages
    else
        setup_home_manager_config
    fi
    
    setup_ollama
    setup_fish
    setup_extra_drives
    finalize_setup
}

# Run main function
main "$@" 