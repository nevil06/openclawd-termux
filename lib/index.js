/**
 * OpenClawd-Termux - Main entry point
 */

import { createRequire } from 'module';
import fs from 'fs';
import path from 'path';
import {
  checkDependencies,
  installTermuxDeps,
  setupBionicBypass,
  installOpenClaw,
  configureTermux,
  getInstallStatus
} from './installer.js';
import { isAndroid, checkBypassInstalled } from './bionic-bypass.js';

const VERSION = '1.0.0';

function printBanner() {
  console.log(`
╔═══════════════════════════════════════════╗
║     OpenClawd-Termux v${VERSION}              ║
║     AI Gateway for Android                ║
╚═══════════════════════════════════════════╝
`);
}

function printHelp() {
  console.log(`
Usage: openclawd <command>

Commands:
  setup       Full installation and configuration
  status      Check installation status
  bypass      Install/update Bionic Bypass only
  start       Start OpenClaw gateway
  help        Show this help message

Examples:
  openclawd setup     # First-time setup
  openclawd start     # Start the gateway
  openclawd status    # Check if everything is installed
`);
}

async function runSetup() {
  console.log('Starting OpenClawd setup for Termux...\n');

  // Check if we're on Android/Termux
  if (!isAndroid()) {
    console.log('Warning: This package is designed for Android/Termux.');
    console.log('Some features may not work on other platforms.\n');
  }

  // Step 1: Check dependencies
  console.log('[1/4] Checking dependencies...');
  const deps = checkDependencies();
  console.log(`  Node.js: ${deps.node ? '✓' : '✗'}`);
  console.log(`  npm: ${deps.npm ? '✓' : '✗'}`);
  console.log(`  git: ${deps.git ? '✓' : '✗'}`);
  console.log('');

  // Step 2: Install Bionic Bypass
  console.log('[2/4] Installing Bionic Bypass...');
  const bypassPath = setupBionicBypass();
  console.log(`  Installed at: ${bypassPath}`);
  console.log('');

  // Step 3: Configure Termux
  console.log('[3/4] Configuring Termux...');
  configureTermux();
  console.log('');

  // Step 4: Install OpenClaw (optional)
  console.log('[4/4] OpenClaw installation...');
  const status = getInstallStatus();
  if (!status.openClaw) {
    console.log('  OpenClaw not found. Install with: npm install -g openclaw');
  } else {
    console.log('  OpenClaw is already installed ✓');
  }
  console.log('');

  // Done
  console.log('═══════════════════════════════════════════');
  console.log('Setup complete!');
  console.log('');
  console.log('Next steps:');
  console.log('  1. Restart your terminal (or run: source ~/.bashrc)');
  console.log('  2. Run: openclaw onboarding');
  console.log('  3. Start gateway: openclawd start');
  console.log('');
  console.log('Dashboard will be at: http://127.0.0.1:18789');
  console.log('═══════════════════════════════════════════');
}

function showStatus() {
  console.log('Installation Status:\n');

  const status = getInstallStatus();
  const deps = checkDependencies();

  console.log('Dependencies:');
  console.log(`  Node.js:        ${deps.node ? '✓ installed' : '✗ missing'}`);
  console.log(`  npm:            ${deps.npm ? '✓ installed' : '✗ missing'}`);
  console.log(`  git:            ${deps.git ? '✓ installed' : '✗ missing'}`);
  console.log('');

  console.log('OpenClawd:');
  console.log(`  Bionic Bypass:  ${status.bionicBypass ? '✓ installed' : '✗ not installed'}`);
  console.log(`  NODE_OPTIONS:   ${status.nodeOptions ? '✓ configured' : '✗ not set (restart terminal)'}`);
  console.log(`  OpenClaw:       ${status.openClaw ? '✓ installed' : '✗ not installed'}`);
  console.log('');

  if (status.bionicBypass && status.openClaw) {
    console.log('Status: Ready to run!');
    console.log('Start with: openclawd start');
  } else {
    console.log('Status: Setup incomplete');
    console.log('Run: openclawd setup');
  }
}

function startGateway() {
  const status = getInstallStatus();

  if (!status.bionicBypass) {
    console.log('Bionic Bypass not installed. Running setup first...\n');
    setupBionicBypass();
  }

  if (!status.openClaw) {
    console.error('OpenClaw is not installed.');
    console.log('Install with: npm install -g openclaw');
    process.exit(1);
  }

  console.log('Starting OpenClaw gateway...\n');

  const { spawn } = await import('child_process');
  const gateway = spawn('openclaw', ['gateway', '--verbose'], {
    stdio: 'inherit',
    env: {
      ...process.env,
      NODE_OPTIONS: process.env.NODE_OPTIONS || `--require "${path.join(process.env.HOME, '.openclawd', 'bionic-bypass.js')}"`
    }
  });

  gateway.on('error', (err) => {
    console.error('Failed to start gateway:', err.message);
  });
}

export async function main(args) {
  const command = args[0] || 'help';

  printBanner();

  switch (command) {
    case 'setup':
    case 'install':
      await runSetup();
      break;

    case 'status':
      showStatus();
      break;

    case 'bypass':
      console.log('Installing Bionic Bypass...');
      const bypassPath = setupBionicBypass();
      console.log(`Installed at: ${bypassPath}`);
      console.log('Restart your terminal to apply changes.');
      break;

    case 'start':
    case 'run':
      await startGateway();
      break;

    case 'help':
    case '--help':
    case '-h':
    default:
      printHelp();
      break;
  }
}
