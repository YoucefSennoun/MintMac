#!/bin/bash

# ============================================================
#  MintMac Setup Script
#  Transforms a fresh Linux Mint 22 Cinnamon install
#  into a macOS-looking desktop
#  Author: Youcef Sennoun
#  GitHub: https://github.com/yourusername/MintMac
# ============================================================

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_step() { echo -e "\n${BLUE}==>${NC} $1"; }
print_ok()   { echo -e "${GREEN}[OK]${NC} $1"; }
print_warn() { echo -e "${YELLOW}[!]${NC} $1"; }
print_err()  { echo -e "${RED}[ERROR]${NC} $1"; }

echo -e "${GREEN}"
echo "  __  __ _       _   __  __             "
echo " |  \/  (_)_ __ | |_|  \/  | __ _  ___ "
echo " | |\/| | | '_ \| __| |\/| |/ _\` |/ __|"
echo " | |  | | | | | | |_| |  | | (_| | (__ "
echo " |_|  |_|_|_| |_|\__|_|  |_|\__,_|\___|"
echo -e "${NC}"
echo "  macOS-style desktop for Linux Mint 22 Cinnamon"
echo "  ================================================"
echo ""

# ============================================================
# CHECK — Must run from MintMac folder
# ============================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_FILE="$SCRIPT_DIR/MintMac-desktop.tar.gz"

if [ ! -f "$BACKUP_FILE" ]; then
    print_err "MintMac-desktop.tar.gz not found!"
    print_err "Make sure you cloned the full repo and run from inside it."
    exit 1
fi

# Check if running on Linux Mint
if ! grep -q "Linux Mint" /etc/os-release 2>/dev/null; then
    print_warn "This script is designed for Linux Mint 22 Cinnamon."
    read -p "Continue anyway? (y/N): " CONTINUE
    [[ "$CONTINUE" != "y" && "$CONTINUE" != "Y" ]] && exit 1
fi

# Check internet connection
print_step "Checking internet connection..."
if ! ping -c 1 google.com &>/dev/null; then
    print_err "No internet connection. Please connect and try again."
    exit 1
fi
print_ok "Internet connection OK"

# ============================================================
# STEP 1 — Update system
# ============================================================
print_step "Updating system packages..."
sudo apt update -y && sudo apt upgrade -y
print_ok "System updated"

# ============================================================
# STEP 2 — Install dependencies
# ============================================================
print_step "Installing dependencies..."
sudo apt install -y \
    git \
    plank \
    gtk2-engines-murrine \
    gtk2-engines-pixbuf \
    sassc \
    curl \
    wget \
    tlp \
    tlp-rdw \
    vainfo \
    libva-drm2 \
    libva-x11-2 \
    i965-va-driver \
    va-driver-all
print_ok "Dependencies installed"

# ============================================================
# STEP 3 — Install Ulauncher (Spotlight search)
# ============================================================
print_step "Installing Ulauncher (Spotlight-style search)..."
sudo add-apt-repository universe -y
sudo apt install -y ulauncher
print_ok "Ulauncher installed"

# ============================================================
# STEP 4 — Restore Desktop Backup
# ============================================================
print_step "Restoring MintMac desktop configuration..."
tar -xzf "$BACKUP_FILE" -C ~/
print_ok "Desktop configuration restored"

# ============================================================
# STEP 5 — Apply Themes via gsettings
# ============================================================
print_step "Applying themes..."
gsettings set org.cinnamon.desktop.interface gtk-theme "WhiteSur-Dark"
gsettings set org.cinnamon.desktop.interface icon-theme "WhiteSur-dark"
gsettings set org.cinnamon.desktop.interface cursor-theme "WhiteSur-cursors"
gsettings set org.cinnamon.desktop.wm.preferences theme "WhiteSur-Dark"
gsettings set org.cinnamon.theme name "WhiteSur-Dark"
print_ok "Themes applied"

# ============================================================
# STEP 6 — Autostart Plank
# ============================================================
print_step "Setting up Plank autostart..."
mkdir -p ~/.config/autostart
cat > ~/.config/autostart/plank.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Plank
Comment=Dock
Exec=plank
Icon=plank
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF
print_ok "Plank autostart configured"

# ============================================================
# STEP 7 — Autostart Ulauncher
# ============================================================
print_step "Setting up Ulauncher autostart..."
cat > ~/.config/autostart/ulauncher.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Ulauncher
Comment=Application Launcher
Exec=ulauncher --hide-window
Icon=ulauncher
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF
print_ok "Ulauncher autostart configured (Ctrl+Space to open)"

# ============================================================
# STEP 8 — Configure Cinnamon Panel (top bar like macOS)
# ============================================================
print_step "Configuring panel..."
gsettings set org.cinnamon panels-enabled "['1:0:top']"
print_ok "Panel set to top (macOS style)"

# ============================================================
# STEP 9 — Disable GPU Hardware Acceleration
# ============================================================
print_step "Disabling GPU acceleration for stability..."

# Chrome
mkdir -p ~/.config/google-chrome
cat > ~/.config/google-chrome/chrome-flags.conf << 'EOF'
--disable-gpu
--disable-gpu-compositing
--disable-software-rasterizer
EOF

# VSCode
mkdir -p ~/.config/Code
cat > ~/.config/Code/argv.json << 'EOF'
{
    "disable-hardware-acceleration": true
}
EOF

# Antigravity
mkdir -p ~/.config/Antigravity
cat > ~/.config/Antigravity/argv.json << 'EOF'
{
    "disable-hardware-acceleration": true
}
EOF

# Chrome desktop entry
if [ -f /usr/share/applications/google-chrome.desktop ]; then
    sudo sed -i 's|Exec=/usr/bin/google-chrome-stable |Exec=/usr/bin/google-chrome-stable --disable-gpu |g' \
        /usr/share/applications/google-chrome.desktop
    print_ok "Chrome GPU disabled"
fi

print_ok "GPU acceleration disabled"

# ============================================================
# STEP 10 — TLP Power Management
# ============================================================
print_step "Enabling TLP power management..."
sudo systemctl enable tlp
sudo tlp start
print_ok "TLP running"

# ============================================================
# DONE
# ============================================================
echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  MintMac setup complete! Please reboot.${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo "  After reboot:"
echo "  • Ctrl+Space    → Ulauncher (Spotlight search)"
echo "  • Plank dock    → autostarts at bottom"
echo "  • Top bar       → macOS-style menu bar"
echo ""
echo -e "${YELLOW}  Install these manually after reboot:${NC}"
echo "  • Chrome      → https://chrome.google.com"
echo "  • Antigravity → https://antigravity.google"
echo "  • VSCode      → https://code.visualstudio.com"
echo ""
