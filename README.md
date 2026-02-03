# OpenClawd-Termux

Run OpenClaw AI Gateway on Android using Termux with the Bionic Bypass fix.

## Quick Install

**One-liner (recommended):**
```bash
curl -fsSL https://raw.githubusercontent.com/mithun50/openclawdx-termux/main/install.sh | bash
```

**Or via npm:**
```bash
npm install -g openclawdx-termux
openclawdxx setup
```

## Requirements

- Android 10 or higher
- Termux from [F-Droid](https://f-droid.org/packages/com.termux/) (NOT Play Store)
- Node.js 18+ (installed automatically)

## What This Package Does

1. **Bionic Bypass** - Fixes `os.networkInterfaces()` crash on Android's Bionic libc
2. **Shell Configuration** - Sets up `NODE_OPTIONS` automatically
3. **Wake-lock Helper** - Keeps Termux running in background

## Usage

```bash
# First-time setup
openclawdxx setup

# Check installation status
openclawdx status

# Start OpenClaw gateway
openclawdx start

# Show help
openclawdx help
```

## Manual Setup

If the installer doesn't work, follow these steps:

### 1. Install dependencies
```bash
pkg update && pkg install -y nodejs-lts git
```

### 2. Create Bionic Bypass script
```bash
mkdir -p ~/.openclawdx
cat > ~/.openclawdx/bionic-bypass.js << 'EOF'
const os = require('os');
const originalNetworkInterfaces = os.networkInterfaces;
os.networkInterfaces = function() {
  try {
    const interfaces = originalNetworkInterfaces.call(os);
    if (interfaces && Object.keys(interfaces).length > 0) {
      return interfaces;
    }
  } catch (e) {}
  return {
    lo: [{
      address: '127.0.0.1',
      netmask: '255.0.0.0',
      family: 'IPv4',
      mac: '00:00:00:00:00:00',
      internal: true,
      cidr: '127.0.0.1/8'
    }]
  };
};
EOF
```

### 3. Configure shell
```bash
echo 'export NODE_OPTIONS="--require $HOME/.openclawdx/bionic-bypass.js"' >> ~/.bashrc
source ~/.bashrc
```

### 4. Install and run OpenClaw
```bash
npm install -g openclaw
openclaw onboarding  # Select "Loopback (127.0.0.1)"
openclaw gateway --verbose
```

## Configuration

### Onboarding Options

When running `openclaw onboarding`:
- **Binding**: Select `Loopback (127.0.0.1)` for non-rooted devices
- **API Keys**: Add your Gemini/OpenAI keys

### Battery Optimization

**Important:** Disable battery optimization for Termux to prevent Android from killing the process.

Settings → Apps → Termux → Battery → Unrestricted

### Wake Lock

To keep Termux running while screen is off:
```bash
~/.openclawdx/wakelock.sh openclaw gateway
```

## Commands

| Command | Description |
|---------|-------------|
| `/status` | Check gateway status |
| `/think high` | Enable high-quality thinking |
| `/reset` | Reset session |

## Dashboard

Access the web dashboard at: `http://127.0.0.1:18789`

## Troubleshooting

### "os.networkInterfaces is not a function"
The Bionic Bypass isn't loaded. Run:
```bash
openclawdxx setup
source ~/.bashrc
```

### Gateway crashes on startup
Make sure you selected "Loopback (127.0.0.1)" during onboarding:
```bash
openclaw onboarding
```

### Process killed in background
Disable battery optimization for Termux and use the wake-lock script.

### Permission denied
```bash
termux-setup-storage
```

## Credits

- Based on the guide by [Sagar Tamang](https://sagartamang.com/blog/openclaw-on-android-termux)
- OpenClaw project

## License

MIT
