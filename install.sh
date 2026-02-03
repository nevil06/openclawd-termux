#!/bin/bash
#
# OpenClawd-Termux Installer
# One-liner: curl -fsSL https://raw.githubusercontent.com/mithun50/openclawd-termux/main/install.sh | bash
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════╗"
echo "║     OpenClawd-Termux Installer            ║"
echo "║     AI Gateway for Android                ║"
echo "╚═══════════════════════════════════════════╝"
echo -e "${NC}"

# Check if running in Termux
if [ ! -d "/data/data/com.termux" ] && [ -z "$TERMUX_VERSION" ]; then
    echo -e "${YELLOW}Warning:${NC} Not running in Termux - some features may not work"
fi

# Update and install packages
echo -e "\n${BLUE}[1/2]${NC} Installing required packages..."
pkg update -y
pkg install -y nodejs-lts git proot-distro

echo -e "  ${GREEN}✓${NC} Node.js $(node --version)"
echo -e "  ${GREEN}✓${NC} npm $(npm --version)"
echo -e "  ${GREEN}✓${NC} git installed"
echo -e "  ${GREEN}✓${NC} proot-distro installed"

# Install openclawd-termux from npm
echo -e "\n${BLUE}[2/2]${NC} Installing openclawd-termux..."
npm install -g openclawd-termux

echo -e "\n${GREEN}═══════════════════════════════════════════${NC}"
echo -e "${GREEN}Installation complete!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Run setup:      openclawdx setup"
echo "  2. Run onboarding: openclawdx onboarding"
echo "     → Select 'Loopback (127.0.0.1)' when asked!"
echo "  3. Start gateway:  openclawdx start"
echo ""
echo -e "Dashboard: ${BLUE}http://127.0.0.1:18789${NC}"
echo ""
echo -e "${YELLOW}Tip:${NC} Disable battery optimization for Termux in Android settings"
echo ""
