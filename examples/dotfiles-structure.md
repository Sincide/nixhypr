# Recommended Dotfiles Structure

This document outlines the recommended structure for your dotfiles repository to work seamlessly with the NixOS Hyprland setup script.

## 📁 Directory Structure

```
your-dotfiles/
├── hyprland/
│   ├── hyprland.conf          # Main Hyprland configuration
│   ├── keybinds.conf          # Keybinding definitions
│   ├── windowrules.conf       # Window rules
│   └── autostart.conf         # Autostart applications
├── waybar/
│   ├── config                 # Waybar configuration (JSON)
│   ├── style.css              # Waybar styling
│   └── modules/               # Custom modules (optional)
├── fish/
│   ├── config.fish            # Fish shell configuration
│   ├── functions/             # Custom functions
│   │   ├── ll.fish
│   │   └── mkcd.fish
│   └── completions/           # Custom completions
├── fuzzel/
│   └── fuzzel.ini             # Fuzzel launcher configuration
├── foot/
│   └── foot.ini               # Foot terminal configuration
├── kitty/
│   ├── kitty.conf             # Kitty terminal configuration
│   └── themes/                # Color themes
├── scripts/
│   ├── screenshot.sh          # Screenshot utility
│   ├── wallpaper-changer.sh   # Wallpaper management
│   └── system-info.sh         # System information
└── themes/
    ├── catppuccin/            # Color theme files
    └── nord/                  # Alternative theme
```

## 🔧 Configuration Examples

### Hyprland Configuration (`hyprland/hyprland.conf`)

```bash
# Basic Hyprland configuration
monitor=,preferred,auto,1

# Source additional configs
source = ~/.config/hypr/keybinds.conf
source = ~/.config/hypr/windowrules.conf
source = ~/.config/hypr/autostart.conf

# Input configuration
input {
    kb_layout = us
    follow_mouse = 1
    touchpad {
        natural_scroll = no
    }
    sensitivity = 0
}

# General settings
general {
    gaps_in = 5
    gaps_out = 10
    border_size = 2
    col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
    col.inactive_border = rgba(595959aa)
    layout = dwindle
}

# Decoration
decoration {
    rounding = 10
    blur {
        enabled = true
        size = 3
        passes = 1
    }
    drop_shadow = yes
    shadow_range = 4
    shadow_render_power = 3
    col.shadow = rgba(1a1a1aee)
}

# Animations
animations {
    enabled = yes
    bezier = myBezier, 0.05, 0.9, 0.1, 1.05
    animation = windows, 1, 7, myBezier
    animation = windowsOut, 1, 7, default, popin 80%
    animation = border, 1, 10, default
    animation = borderangle, 1, 8, default
    animation = fade, 1, 7, default
    animation = workspaces, 1, 6, default
}

# Layout
dwindle {
    pseudotile = yes
    preserve_split = yes
}

# Misc
misc {
    force_default_wallpaper = 0
}
```

### Waybar Configuration (`waybar/config`)

```json
{
    "layer": "top",
    "position": "top",
    "height": 30,
    "spacing": 4,
    "modules-left": ["hyprland/workspaces"],
    "modules-center": ["hyprland/window"],
    "modules-right": ["pulseaudio", "network", "cpu", "memory", "temperature", "battery", "clock", "tray"],
    
    "hyprland/workspaces": {
        "disable-scroll": true,
        "all-outputs": true,
        "format": "{icon}",
        "format-icons": {
            "1": "",
            "2": "",
            "3": "",
            "4": "",
            "5": "",
            "urgent": "",
            "focused": "",
            "default": ""
        }
    },
    
    "clock": {
        "tooltip-format": "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>",
        "format-alt": "{:%Y-%m-%d}"
    },
    
    "cpu": {
        "format": "{usage}% ",
        "tooltip": false
    },
    
    "memory": {
        "format": "{}% "
    },
    
    "battery": {
        "states": {
            "warning": 30,
            "critical": 15
        },
        "format": "{capacity}% {icon}",
        "format-charging": "{capacity}% ",
        "format-plugged": "{capacity}% ",
        "format-alt": "{time} {icon}",
        "format-icons": ["", "", "", "", ""]
    },
    
    "network": {
        "format-wifi": "{essid} ({signalStrength}%) ",
        "format-ethernet": "{ipaddr}/{cidr} ",
        "tooltip-format": "{ifname} via {gwaddr} ",
        "format-linked": "{ifname} (No IP) ",
        "format-disconnected": "Disconnected ⚠",
        "format-alt": "{ifname}: {ipaddr}/{cidr}"
    },
    
    "pulseaudio": {
        "format": "{volume}% {icon} {format_source}",
        "format-bluetooth": "{volume}% {icon} {format_source}",
        "format-bluetooth-muted": " {icon} {format_source}",
        "format-muted": " {format_source}",
        "format-source": "{volume}% ",
        "format-source-muted": "",
        "format-icons": {
            "headphone": "",
            "hands-free": "",
            "headset": "",
            "phone": "",
            "portable": "",
            "car": "",
            "default": ["", "", ""]
        },
        "on-click": "pavucontrol"
    }
}
```

### Fish Shell Configuration (`fish/config.fish`)

```fish
# Fish shell configuration

# Set PATH
set -gx PATH $HOME/.local/bin $PATH

# Modern CLI tool aliases
alias ll='eza -l'
alias la='eza -la'
alias ls='eza'
alias cat='bat'
alias grep='rg'
alias find='fd'
alias tree='eza --tree'

# System shortcuts
alias rebuild='sudo nixos-rebuild switch'
alias hm-switch='home-manager switch'

# Git shortcuts
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline'

# Navigation shortcuts
alias ..='cd ..'
alias ...='cd ../..'

# Wayland environment variables
set -gx MOZ_ENABLE_WAYLAND 1
set -gx QT_QPA_PLATFORM wayland
set -gx SDL_VIDEODRIVER wayland
set -gx _JAVA_AWT_WM_NONREPARENTING 1

# Custom functions
function mkcd
    mkdir -p $argv[1]
    cd $argv[1]
end

function gclone
    git clone $argv[1]
    cd (basename $argv[1] .git)
end

function screenshot
    grim -g "(slurp)" ~/Pictures/screenshot-(date +%Y%m%d_%H%M%S).png
end

# Welcome message
echo "Welcome to Fish shell on NixOS Hyprland!"
echo "Run 'neofetch' to see system info"
```

### Useful Scripts (`scripts/`)

#### Screenshot Script (`scripts/screenshot.sh`)

```bash
#!/usr/bin/env bash
# Screenshot utility for Hyprland

case $1 in
    "full")
        grim ~/Pictures/screenshot-$(date +%Y%m%d_%H%M%S).png
        notify-send "Screenshot" "Full screen captured"
        ;;
    "area")
        grim -g "$(slurp)" ~/Pictures/screenshot-$(date +%Y%m%d_%H%M%S).png
        notify-send "Screenshot" "Area captured"
        ;;
    "window")
        grim -g "$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')" ~/Pictures/screenshot-$(date +%Y%m%d_%H%M%S).png
        notify-send "Screenshot" "Window captured"
        ;;
    *)
        echo "Usage: $0 {full|area|window}"
        ;;
esac
```

## 🎨 Theme Integration

### Using Matugen for Dynamic Theming

The script installs `matugen` for dynamic theming. You can integrate it with your dotfiles:

```bash
# Generate theme from wallpaper
matugen image ~/Pictures/wallpaper.jpg

# Apply to Waybar
matugen image ~/Pictures/wallpaper.jpg --format=css > ~/.config/waybar/colors.css

# Apply to Hyprland
matugen image ~/Pictures/wallpaper.jpg --format=hyprland > ~/.config/hypr/colors.conf
```

## 📝 Setup Instructions

1. **Create your dotfiles repository** with the structure above
2. **Customize configurations** to your preferences
3. **Make scripts executable**: `chmod +x scripts/*.sh`
4. **Test locally** before running the setup script
5. **Run the NixOS Hyprland setup script** and provide your dotfiles URL

## 🔗 Integration with Setup Script

The setup script will:
- Clone your dotfiles repository to `~/dotfiles`
- Symlink configuration directories to `~/.config/`
- Install scripts to `~/.local/bin/`
- Set appropriate permissions

This structure ensures maximum compatibility with the automated setup process while maintaining flexibility for your personal customizations. 