# NixOS Hyprland Setup Script - Testing Checklist

## Pre-Testing Requirements

### Test Environments Needed:
- [ ] Fresh NixOS 24.11 minimal installation
- [ ] Fresh NixOS 24.05 installation  
- [ ] NixOS unstable channel installation
- [ ] NixOS with existing Home Manager
- [ ] NixOS with flakes enabled
- [ ] VM with limited disk space (< 20GB)
- [ ] System with NVIDIA graphics
- [ ] System with AMD graphics
- [ ] System with Intel integrated graphics

## Critical Test Scenarios

### 1. Fresh Installation Tests
- [ ] **Minimal NixOS 24.11**: Run script on completely fresh install
- [ ] **Network connectivity**: Test with poor/intermittent connection
- [ ] **Disk space**: Test with limited available space
- [ ] **User permissions**: Test with different user configurations

### 2. Existing Configuration Tests
- [ ] **Existing packages**: System with some packages already installed
- [ ] **Custom configuration.nix**: Non-standard config file structure
- [ ] **Existing Home Manager**: Different HM installation methods
- [ ] **Conflicting services**: Systems with existing window managers

### 3. Hardware Compatibility Tests
- [ ] **NVIDIA proprietary drivers**: Test Hyprland with NVIDIA
- [ ] **AMD open drivers**: Test with AMDGPU
- [ ] **Intel integrated**: Test with Intel graphics
- [ ] **Multiple displays**: Test multi-monitor setups
- [ ] **HiDPI displays**: Test scaling issues

### 4. Edge Case Tests
- [ ] **No internet during git clone**: Test offline scenarios
- [ ] **Invalid dotfiles repo**: Test with broken/private repos
- [ ] **Corrupted channels**: Test with broken nix channels
- [ ] **Full disk during rebuild**: Test disk space exhaustion
- [ ] **Interrupted script**: Test recovery from partial runs

### 5. User Experience Tests
- [ ] **All interactive prompts**: Test every Y/n choice
- [ ] **Invalid inputs**: Test with malformed responses
- [ ] **Skip options**: Test skipping each major component
- [ ] **Rollback scenarios**: Test when things go wrong

## Known Limitations to Document

### 1. **Flakes Incompatibility**
```bash
# Detection needed:
if [[ -f /etc/nixos/flake.nix ]]; then
    print_error "This script doesn't support flakes-based NixOS configurations"
    print_error "Please use Home Manager flakes setup instead"
    exit 1
fi
```

### 2. **Graphics Driver Requirements**
```bash
# Should check and warn:
check_graphics() {
    if lspci | grep -i nvidia; then
        print_warning "NVIDIA GPU detected. You may need to configure drivers manually"
        print_warning "Add 'services.xserver.videoDrivers = [\"nvidia\"];' to configuration.nix"
    fi
}
```

### 3. **Display Manager Integration**
```bash
# Should configure display manager:
setup_display_manager() {
    if ! grep -q "services.xserver.enable" /etc/nixos/configuration.nix; then
        print_warning "No display manager configured. Hyprland may not appear in login screen"
        read -p "Configure SDDM display manager? (Y/n): " setup_dm
        if [[ "$setup_dm" =~ ^[Yy]$ ]]; then
            # Add SDDM configuration
        fi
    fi
}
```

## Failure Recovery Procedures

### 1. **Configuration.nix Backup Recovery**
```bash
restore_config() {
    if [[ -f "/etc/nixos/configuration.nix.backup.*" ]]; then
        latest_backup=$(ls -t /etc/nixos/configuration.nix.backup.* | head -1)
        cp "$latest_backup" /etc/nixos/configuration.nix
        nixos-rebuild switch
    fi
}
```

### 2. **Home Manager Reset**
```bash
reset_home_manager() {
    sudo -u "$USERNAME" rm -rf ~/.config/home-manager
    sudo -u "$USERNAME" nix-env --uninstall home-manager
}
```

### 3. **Service Cleanup**
```bash
cleanup_services() {
    systemctl stop ollama || true
    systemctl disable ollama || true
}
```

## Recommended Testing Order

1. **Start with VM snapshots** - Take snapshot before each test
2. **Test minimal scenarios first** - Basic functionality
3. **Add complexity gradually** - Test edge cases
4. **Document all failures** - Create issue list
5. **Test fixes thoroughly** - Verify each fix works

## Success Criteria

### Must Work:
- [ ] Fresh NixOS 24.11 installation
- [ ] Basic Hyprland desktop launches
- [ ] Fish shell is default and functional
- [ ] Waybar displays correctly
- [ ] Fuzzel launcher works
- [ ] Ollama service starts

### Should Work:
- [ ] Home Manager configuration applies
- [ ] Dotfiles integration works
- [ ] Extra drive mounting works
- [ ] All interactive prompts function

### Nice to Have:
- [ ] Works on older NixOS versions
- [ ] Handles edge cases gracefully
- [ ] Good error messages and recovery

## Post-Testing Documentation

After testing, create:
- [ ] **Known Issues** list
- [ ] **Compatibility Matrix** (NixOS versions, hardware)
- [ ] **Troubleshooting Guide** 
- [ ] **Alternative Installation Methods**
- [ ] **Recovery Procedures** 