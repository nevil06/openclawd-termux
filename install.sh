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
NC='\033[0m' # No Color

# Paths
HOME_DIR="${HOME:-/data/data/com.termux/files/home}"
OPENCLAWD_DIR="$HOME_DIR/.openclawd"
BYPASS_SCRIPT="$OPENCLAWD_DIR/bionic-bypass.js"
BASHRC="$HOME_DIR/.bashrc"
ZSHRC="$HOME_DIR/.zshrc"

echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════╗"
echo "║     OpenClawd-Termux Installer            ║"
echo "║     AI Gateway for Android                ║"
echo "╚═══════════════════════════════════════════╝"
echo -e "${NC}"

# Check if running in Termux
check_termux() {
    if [ -d "/data/data/com.termux" ] || [ -n "$TERMUX_VERSION" ]; then
        echo -e "${GREEN}✓${NC} Running in Termux"
        return 0
    else
        echo -e "${YELLOW}⚠${NC} Not running in Termux - some features may not work"
        return 0
    fi
}

# Check for required commands
check_dependencies() {
    echo -e "\n${BLUE}[1/5]${NC} Checking dependencies..."

    local missing=()

    if ! command -v node &> /dev/null; then
        missing+=("nodejs-lts")
    else
        echo -e "  ${GREEN}✓${NC} Node.js $(node --version)"
    fi

    if ! command -v npm &> /dev/null; then
        missing+=("nodejs-lts")
    else
        echo -e "  ${GREEN}✓${NC} npm $(npm --version)"
    fi

    if ! command -v git &> /dev/null; then
        missing+=("git")
    else
        echo -e "  ${GREEN}✓${NC} git installed"
    fi

    if [ ${#missing[@]} -ne 0 ]; then
        echo -e "\n${YELLOW}Installing missing packages...${NC}"
        pkg update -y
        pkg install -y "${missing[@]}"
    fi
}

# Create Bionic Bypass script
install_bionic_bypass() {
    echo -e "\n${BLUE}[2/5]${NC} Installing Bionic Bypass..."

    mkdir -p "$OPENCLAWD_DIR"

    cat > "$BYPASS_SCRIPT" << 'BYPASS_EOF'
// OpenClawd Bionic Bypass - Auto-generated
const os = require('os');
const originalNetworkInterfaces = os.networkInterfaces;

os.networkInterfaces = function() {
  try {
    const interfaces = originalNetworkInterfaces.call(os);
    if (interfaces && Object.keys(interfaces).length > 0) {
      return interfaces;
    }
  } catch (e) {
    // Bionic blocked the call, use fallback
  }

  // Return mock loopback interface
  return {
    lo: [
      {
        address: '127.0.0.1',
        netmask: '255.0.0.0',
        family: 'IPv4',
        mac: '00:00:00:00:00:00',
        internal: true,
        cidr: '127.0.0.1/8'
      }
    ]
  };
};
BYPASS_EOF

    chmod 644 "$BYPASS_SCRIPT"
    echo -e "  ${GREEN}✓${NC} Created $BYPASS_SCRIPT"
}

# Configure shell
configure_shell() {
    echo -e "\n${BLUE}[3/5]${NC} Configuring shell environment..."

    local node_options="--require \"$BYPASS_SCRIPT\""
    local export_line="export NODE_OPTIONS=\"$node_options\""
    local comment="# OpenClawd Bionic Bypass"

    for rcfile in "$BASHRC" "$ZSHRC"; do
        if [ -f "$rcfile" ]; then
            if ! grep -q "bionic-bypass" "$rcfile" 2>/dev/null; then
                echo "" >> "$rcfile"
                echo "$comment" >> "$rcfile"
                echo "$export_line" >> "$rcfile"
                echo -e "  ${GREEN}✓${NC} Updated $(basename $rcfile)"
            else
                echo -e "  ${YELLOW}→${NC} $(basename $rcfile) already configured"
            fi
        fi
    done

    # Create bashrc if it doesn't exist
    if [ ! -f "$BASHRC" ]; then
        echo "$comment" > "$BASHRC"
        echo "$export_line" >> "$BASHRC"
        echo -e "  ${GREEN}✓${NC} Created .bashrc"
    fi

    # Export for current session
    export NODE_OPTIONS="$node_options"
}

# Create wake-lock helper
create_wakelock() {
    echo -e "\n${BLUE}[4/5]${NC} Creating wake-lock helper..."

    local wakelock_script="$OPENCLAWD_DIR/wakelock.sh"

    cat > "$wakelock_script" << 'WAKELOCK_EOF'
#!/bin/bash
# Keep Termux awake while OpenClaw runs
termux-wake-lock
trap "termux-wake-unlock" EXIT
exec "$@"
WAKELOCK_EOF

    chmod 755 "$wakelock_script"
    echo -e "  ${GREEN}✓${NC} Created wake-lock script"
}

# Install npm package
install_npm_package() {
    echo -e "\n${BLUE}[5/5]${NC} Installing openclawd-termux..."

    # Check if we should install from npm or local
    if [ -f "./package.json" ] && grep -q "openclawd-termux" "./package.json" 2>/dev/null; then
        echo -e "  ${YELLOW}→${NC} Installing from local directory..."
        npm install -g .
    else
        # Try npm registry, fall back to GitHub
        if npm view openclawd-termux &>/dev/null; then
            npm install -g openclawd-termux
        else
            echo -e "  ${YELLOW}→${NC} Package not on npm yet, skipping global install"
            echo -e "  ${YELLOW}→${NC} Run 'npm publish' to publish, then reinstall"
        fi
    fi
}

# Print completion message
print_complete() {
    echo -e "\n${GREEN}═══════════════════════════════════════════${NC}"
    echo -e "${GREEN}Installation complete!${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "  1. Restart your terminal (or run: source ~/.bashrc)"
    echo "  2. Install OpenClaw: npm install -g openclaw"
    echo "  3. Run onboarding: openclaw onboarding"
    echo "     → Select 'Loopback (127.0.0.1)' when asked!"
    echo "  4. Start gateway: openclaw gateway --verbose"
    echo ""
    echo -e "Dashboard: ${BLUE}http://127.0.0.1:18789${NC}"
    echo ""
    echo -e "${YELLOW}Important:${NC}"
    echo "  • Disable battery optimization for Termux in Android settings"
    echo "  • Use Termux from F-Droid, not Play Store"
    echo ""
}

# Main
main() {
    check_termux
    check_dependencies
    install_bionic_bypass
    configure_shell
    create_wakelock
    install_npm_package
    print_complete
}

main "$@"
