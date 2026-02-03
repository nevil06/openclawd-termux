/**
 * OpenClawd Installer - Handles environment setup for Termux
 */

import { execSync, spawn } from 'child_process';
import fs from 'fs';
import path from 'path';
import { installBypass, getBypassScriptPath, getNodeOptions, isAndroid } from './bionic-bypass.js';

const HOME = process.env.HOME || '/data/data/com.termux/files/home';
const BASHRC = path.join(HOME, '.bashrc');
const ZSHRC = path.join(HOME, '.zshrc');

export function checkDependencies() {
  const deps = {
    node: false,
    npm: false,
    git: false,
    proot: false
  };

  try {
    execSync('node --version', { stdio: 'pipe' });
    deps.node = true;
  } catch {}

  try {
    execSync('npm --version', { stdio: 'pipe' });
    deps.npm = true;
  } catch {}

  try {
    execSync('git --version', { stdio: 'pipe' });
    deps.git = true;
  } catch {}

  try {
    execSync('which proot-distro', { stdio: 'pipe' });
    deps.proot = true;
  } catch {}

  return deps;
}

export function installTermuxDeps() {
  console.log('Installing Termux dependencies...');

  const packages = ['nodejs-lts', 'git', 'openssh'];

  try {
    execSync('pkg update -y', { stdio: 'inherit' });
    execSync(`pkg install -y ${packages.join(' ')}`, { stdio: 'inherit' });
    return true;
  } catch (err) {
    console.error('Failed to install Termux packages:', err.message);
    return false;
  }
}

export function setupBionicBypass() {
  console.log('Setting up Bionic Bypass...');

  const scriptPath = installBypass();
  const nodeOptions = getNodeOptions();
  const exportLine = `export NODE_OPTIONS="${nodeOptions}"`;

  // Add to shell configs
  for (const rcFile of [BASHRC, ZSHRC]) {
    if (fs.existsSync(rcFile)) {
      const content = fs.readFileSync(rcFile, 'utf8');
      if (!content.includes('bionic-bypass')) {
        fs.appendFileSync(rcFile, `\n# OpenClawd Bionic Bypass\n${exportLine}\n`);
        console.log(`Updated ${path.basename(rcFile)}`);
      }
    }
  }

  // Also set for current session
  process.env.NODE_OPTIONS = nodeOptions;

  return scriptPath;
}

export function installOpenClaw() {
  console.log('Installing OpenClaw...');

  try {
    execSync('npm install -g openclaw', { stdio: 'inherit' });
    return true;
  } catch (err) {
    console.error('Failed to install OpenClaw:', err.message);
    console.log('You may need to install it manually: npm install -g openclaw');
    return false;
  }
}

export function configureTermux() {
  console.log('Configuring Termux for background operation...');

  // Create wake-lock script
  const wakeLockScript = path.join(HOME, '.openclawd', 'wakelock.sh');
  const wakeLockContent = `#!/bin/bash
# Keep Termux awake while OpenClaw runs
termux-wake-lock
trap "termux-wake-unlock" EXIT
exec "$@"
`;

  fs.writeFileSync(wakeLockScript, wakeLockContent, 'utf8');
  fs.chmodSync(wakeLockScript, '755');

  console.log('Wake-lock script created');
  console.log('');
  console.log('IMPORTANT: Disable battery optimization for Termux in Android settings!');

  return true;
}

export function getInstallStatus() {
  return {
    bionicBypass: fs.existsSync(getBypassScriptPath()),
    nodeOptions: process.env.NODE_OPTIONS?.includes('bionic-bypass') || false,
    openClaw: (() => {
      try {
        execSync('which openclaw', { stdio: 'pipe' });
        return true;
      } catch {
        return false;
      }
    })()
  };
}
