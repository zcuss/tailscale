#!/bin/bash

# ============================================================
# Zero's Firebase Studio Environment Bootstrap (Dynamic)
# Usage: bash -c "$(curl -fsSL https://raw.githubusercontent.com/zcuss/tailscale/Main/install.sh)"
# ============================================================

set -e

echo "[1/3] Mencari Nix store PATH dari environment system..."

# Ambil PATH dari environment system asli sebelum shell init overrides
NIX_PATH_FULL=$(cat /etc/environment 2>/dev/null | grep "^PATH=" | cut -d= -f2-)

# Fallback: coba ambil dari environment bawaan user
if [ -z "$NIX_PATH_FULL" ]; then
    NIX_PATH_FULL=$(su - user -c 'echo $PATH' 2>/dev/null)
fi

# Fallback 2: scan /nix/store/ untuk binary node lalu bangun path minimal
if [ -z "$NIX_PATH_FULL" ]; then
    NODE_STORE=$(find /nix/store -maxdepth 2 -name 'nodejs-*' -type d 2>/dev/null | head -1)
    IDX_STORE=$(find /nix/store -maxdepth 2 -name 'idx-builtins-*' -type d 2>/dev/null | head -1)
    NIX_PATH_FULL="${NODE_STORE}/bin:/usr/bin:/bin:/home/user/.local/bin"
    [ -n "$IDX_STORE" ] && NIX_PATH_FULL="${NIX_PATH_FULL}:${IDX_STORE}/bin"
fi

echo "  → PATH: ${NIX_PATH_FULL}"

echo "[2/3] Menulis ke ~/.bashrc..."

cat >> ~/.bashrc << NIXPATH
# --- Zero: Firebase Studio Nix store PATH (auto-detected) ---
export PATH="${NIX_PATH_FULL}:\$PATH"
NIXPATH

cat >> ~/.bashrc << 'ALIASES'
# --- Zero: Bypass EROFS Nix store ---
alias pnpm="npx pnpm"
alias yarn="npx yarn"
alias pnpx="npx pnpx"
ALIASES

echo "[3/3] Menerapkan dan verifikasi..."

export PATH="${NIX_PATH_FULL}:$PATH"
alias pnpm="npx pnpm" 2>/dev/null || true

if npx pnpm -v > /dev/null 2>&1; then
    echo ""
    echo "  ✓ Setup berhasil. pnpm v$(npx pnpm -v) siap."
    echo "  ✓ Tutup terminal ini dan buka yang baru, atau jalankan: source ~/.bashrc"
else
    echo ""
    echo "  ⚠ pnpm belum terverifikasi. Pastikan Node.js tersedia, lalu jalankan: source ~/.bashrc"
fi

echo ""
echo "  Tools tersedia: node, npm, npx, pnpm"
