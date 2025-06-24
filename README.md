# NixOS Hyprland Post-Installation Setup Script

**A comprehensive, interactive script to transform a fresh NixOS installation into a fully configured Hyprland desktop environment.**

![NixOS](https://img.shields.io/badge/NixOS-24.11%20%7C%2024.05-blue?logo=nixos)
![Hyprland](https://img.shields.io/badge/Hyprland-Latest-purple?logo=wayland)
![Shell](https://img.shields.io/badge/Shell-Fish-green?logo=gnubash)
![License](https://img.shields.io/badge/License-MIT-yellow)

## 🎯 What This Script Does

Transforms a minimal NixOS installation into a complete Hyprland desktop with:

- **🪟 Hyprland** - Modern Wayland compositor
- **📊 Waybar** - Customizable status bar
- **🚀 Fuzzel** - Application launcher
- **🐟 Fish Shell** - User-friendly shell (set as default)
- **🤖 Ollama** - Local AI service
- **🎨 Matugen** - Dynamic theming tool
- **📱 Terminal Emulators** - foot and kitty
- **⚙️ Home Manager** - Declarative user environment (optional)
- **💾 Dotfiles Integration** - Automatic setup from your repo
- **🗄️ Drive Auto-mounting** - Configure additional storage

## 🎮 Optimized For

- **✅ Latest Stable NixOS** (24.11, 24.05)
- **✅ Intel Graphics** (integrated and discrete)
- **✅ AMD Graphics** (integrated and discrete)
- **❌ NVIDIA Graphics** (not supported by this script)

## 📋 Prerequisites

### System Requirements
- Fresh NixOS installation (graphical installer, no desktop chosen)
- At least 8GB RAM
- 20GB+ free disk space
- Stable internet connection
- Intel or AMD graphics hardware

### Before Running
1. Complete NixOS installation via graphical installer
2. Boot into your new NixOS system
3. Ensure you have a regular user account created
4. Have sudo/root access available

## 🚀 Quick Start

### 1. Download and Run
```bash
# Download the script
curl -O https://raw.githubusercontent.com/YOUR_USERNAME/nixos-hyprland-setup/main/postinstall_nixos_hyprland.sh

# Make it executable
chmod +x postinstall_nixos_hyprland.sh

# Run as root
sudo ./postinstall_nixos_hyprland.sh
```

### 2. Follow the Interactive Prompts
The script will guide you through:
- User account verification
- Home Manager installation (optional)
- Dotfiles repository setup (optional)
- Configuration method selection
- Package installation and configuration
- Ollama AI model setup (optional)
- Additional drive mounting (optional)

### 3. Reboot and Enjoy
After completion, reboot and select "Hyprland" from your display manager.

## 📁 Repository Structure

```
nixos-hyprland-setup/
├── postinstall_nixos_hyprland.sh    # Main installation script
├── README.md                        # This file
├── SUCCESS_PROBABILITY.md           # Success rate analysis
├── TESTING_CHECKLIST.md            # Comprehensive testing guide
├── LICENSE                          # MIT License
└── examples/
    ├── configuration.nix.example    # Example NixOS config
    ├── home.nix.example            # Example Home Manager config
    └── dotfiles-structure.md       # Recommended dotfiles layout
```

## ⚡ Success Rate

**95%+ success rate** for the target use case:
- Latest stable NixOS (24.11/24.05)
- Intel or AMD graphics
- Fresh installation
- Stable internet connection

See [SUCCESS_PROBABILITY.md](SUCCESS_PROBABILITY.md) for detailed analysis.

## 🛠️ What Gets Installed

### Core Desktop Environment
- **Hyprland** - Wayland compositor with hardware acceleration
- **Waybar** - Status bar with system information
- **Fuzzel** - Fast application launcher
- **SDDM** - Display manager (if needed)

### Development & Productivity
- **Fish Shell** - Modern shell with auto-completion
- **Git** - Version control
- **Ollama** - Local AI service with model management
- **Home Manager** - Declarative user environment management

### Terminal & Utilities
- **foot** - Fast Wayland terminal
- **kitty** - Feature-rich terminal emulator
- **Wayland utilities** - wl-clipboard, grim, slurp for screenshots
- **System tools** - htop, neofetch, curl, wget

### Modern CLI Tools
- **eza** - Modern ls replacement
- **bat** - Syntax-highlighted cat
- **ripgrep** - Fast text search
- **fd** - Modern find replacement
- **fzf** - Fuzzy finder

## 🎨 Dotfiles Integration

The script can automatically set up your dotfiles repository:

### Supported Structure
```
your-dotfiles/
├── hyprland/          # Hyprland configuration
├── waybar/            # Waybar configuration  
├── fish/              # Fish shell configuration
├── fuzzel/            # Fuzzel launcher configuration
├── foot/              # foot terminal configuration
├── kitty/             # kitty terminal configuration
└── scripts/           # Custom scripts → ~/.local/bin
```

### Setup Options
- **Symlink** (recommended) - Live updates when you change dotfiles
- **Copy** - Static copy, won't auto-update

## 🔧 Configuration Methods

### System-Level Configuration
- Packages installed via `/etc/nixos/configuration.nix`
- System-wide availability
- Requires `sudo nixos-rebuild switch` for changes

### Home Manager Configuration  
- User-level package management
- Declarative user environment
- Per-user customization
- Easy rollbacks

## 🤖 Ollama AI Integration

Optional AI service setup with:
- Automatic service configuration
- Model preloading options
- Popular models suggested:
  - `llama3.2:3b` (2GB) - General purpose
  - `phi3:mini` (2.3GB) - Coding assistant
  - `codellama:7b` (3.8GB) - Code generation
  - `qwen2.5:3b` (1.8GB) - Efficient general model

## 🗄️ Drive Auto-mounting

Automatically detect and configure additional storage:
- Lists unmounted block devices
- Interactive mounting configuration
- Adds entries to `/etc/nixos/configuration.nix`
- Supports various filesystems (auto-detection)

## 🛡️ Safety Features

### Pre-flight Checks
- ✅ NixOS system verification
- ✅ Internet connectivity test
- ✅ Disk space validation (5GB minimum)
- ✅ Flakes configuration detection
- ✅ Graphics hardware detection

### Error Recovery
- 🔄 Automatic configuration.nix backup
- 🔄 Rollback on failed rebuilds
- 🔄 Graceful failure handling
- 🔄 Clear error messages and recovery instructions

## 🧪 Testing

See [TESTING_CHECKLIST.md](TESTING_CHECKLIST.md) for comprehensive testing procedures.

### Recommended Testing Approach
1. **VM Testing** - Test in virtual machine first
2. **Snapshot Creation** - Create VM snapshots before running
3. **Fresh Installation** - Test on clean NixOS install
4. **Documentation** - Document any issues found

## 🐛 Troubleshooting

### Common Issues

#### Script Fails During nixos-rebuild
```bash
# Check the error output, then restore backup
sudo cp /etc/nixos/configuration.nix.backup.* /etc/nixos/configuration.nix
sudo nixos-rebuild switch
```

#### Home Manager Installation Fails
```bash
# Remove and retry
rm -rf ~/.config/home-manager
nix-channel --update
```

#### Hyprland Won't Start
- Ensure your graphics drivers are working: `lspci | grep VGA`
- Check if Wayland is supported: `echo $XDG_SESSION_TYPE`
- Verify Hyprland is installed: `which Hyprland`

#### Ollama Service Issues
```bash
# Check service status
systemctl status ollama

# Restart service
sudo systemctl restart ollama

# Check logs
journalctl -u ollama -f
```

## 🤝 Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Test thoroughly (see TESTING_CHECKLIST.md)
4. Submit a pull request with detailed description

### Areas for Contribution
- Additional dotfiles structure support
- More comprehensive hardware detection
- Additional terminal/application configurations
- Improved error handling and recovery
- Documentation improvements

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **NixOS Community** - For the amazing declarative OS
- **Hyprland** - For the fantastic Wayland compositor
- **Home Manager** - For user environment management
- **Fish Shell** - For the user-friendly shell experience

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/YOUR_USERNAME/nixos-hyprland-setup/issues)
- **Discussions**: [GitHub Discussions](https://github.com/YOUR_USERNAME/nixos-hyprland-setup/discussions)
- **NixOS Discourse**: [NixOS Community](https://discourse.nixos.org/)

---

**⭐ If this script helped you set up your NixOS Hyprland desktop, please give it a star!** 