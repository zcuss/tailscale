#!/usr/bin/env bash
# ============================================================
# Zero's Firebase Studio Full Bootstrap + Tailscale Installer
# Usage: bash -c "$(curl -fsSL https://raw.githubusercontent.com/zcuss/tailscale/Main/install.sh)"
# ============================================================

set -e

echo "=============================================="
echo " Zero's Firebase Studio Environment Setup"
echo "=============================================="

# ============================================================
# BAGIAN 1: Nix Store PATH & Alias Bootstrap
# ============================================================

echo ""
echo "[Bootstrap 1/3] Mencari Nix store PATH dari environment system..."

NIX_PATH_FULL=$(cat /etc/environment 2>/dev/null | grep "^PATH=" | cut -d= -f2-)

if [ -z "$NIX_PATH_FULL" ]; then
    NIX_PATH_FULL=$(su - user -c 'echo $PATH' 2>/dev/null || true)
fi

if [ -z "$NIX_PATH_FULL" ]; then
    NODE_STORE=$(find /nix/store -maxdepth 2 -name 'nodejs-*' -type d 2>/dev/null | head -1)
    IDX_STORE=$(find /nix/store -maxdepth 2 -name 'idx-builtins-*' -type d 2>/dev/null | head -1)
    NIX_PATH_FULL="${NODE_STORE}/bin:/usr/bin:/bin:/home/user/.local/bin"
    [ -n "$IDX_STORE" ] && NIX_PATH_FULL="${NIX_PATH_FULL}:${IDX_STORE}/bin"
fi

echo "  → PATH: ${NIX_PATH_FULL}"

echo "[Bootstrap 2/3] Menulis ke ~/.bashrc..."

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

echo "[Bootstrap 3/3] Menerapkan dan verifikasi..."

export PATH="${NIX_PATH_FULL}:$PATH"
alias pnpm="npx pnpm" 2>/dev/null || true

if npx pnpm -v > /dev/null 2>&1; then
    echo "  ✓ Setup berhasil. pnpm v$(npx pnpm -v) siap."
    echo "  ✓ Tutup terminal ini dan buka yang baru, atau jalankan: source ~/.bashrc"
else
    echo "  ⚠ pnpm belum terverifikasi. Pastikan Node.js tersedia, lalu jalankan: source ~/.bashrc"
fi

echo ""
echo "  Tools tersedia: node, npm, npx, pnpm"

# ============================================================
# BAGIAN 2: Tailscale Installer
# ============================================================

echo ""
echo "=============================================="
echo " Tailscale Installer for Google IDX"
echo "=============================================="

TAILSCALE_VERSION="1.66.4"
TAILSCALE_DIR="$HOME/tailscale-${TAILSCALE_VERSION}"
TAILSCALED="$TAILSCALE_DIR/tailscaled"
TAILSCALE="$TAILSCALE_DIR/tailscale"
OPERATOR="${OPERATOR:-user}"
TIMEOUT_AUTH=120

# 1. Unduh dan ekstrak jika belum ada
if [ ! -f "$TAILSCALED" ]; then
    echo "[1/5] Mengunduh Tailscale biner statis..."
    cd "$HOME"
    wget -q "https://pkgs.tailscale.com/stable/tailscale_${TAILSCALE_VERSION}_amd64.tgz" -O tailscale.tgz
    tar -xzf tailscale.tgz
    rm tailscale.tgz
    if [ -d "tailscale_${TAILSCALE_VERSION}_amd64" ]; then
        mv "tailscale_${TAILSCALE_VERSION}_amd64" "$TAILSCALE_DIR"
    fi
    echo "[1/5] Biner berhasil disiapkan."
else
    echo "[1/5] Biner Tailscale sudah ada, lewati unduh."
fi

cd "$TAILSCALE_DIR"

# 2. Jalankan tailscaled (userspace) — diperbaiki
echo "[2/5] Menjalankan tailscaled (userspace-networking)..."

# Matikan hanya proses tailscaled yang sudah ada, JANGAN bunuh shell sendiri
TAILSCALED_PID=$(pgrep -f "tailscaled" 2>/dev/null || true)
if [ -n "$TAILSCALED_PID" ]; then
    kill "$TAILSCALED_PID" 2>/dev/null || true
    sleep 1
fi

# Jalankan tailscaled di background dengan cara yang lebih aman
nohup "$TAILSCALED" --tun=userspace-networking --socks5-server=localhost:1055 > /tmp/tailscaled.log 2>&1 &
TAILSCALED_PID=$!
echo "tailscaled dijalankan (PID $TAILSCALED_PID)"

# Tunggu hingga daemon siap
echo "Menunggu daemon siap..."
for i in $(seq 1 15); do
    sleep 1
    if "$TAILSCALE" status >/dev/null 2>&1; then
        echo "Daemon siap setelah ${i} detik."
        break
    fi
done

# 3. Koneksi ke Tailscale
echo "[3/5] Menghubungkan ke akun Tailscale..."
"$TAILSCALE" up --accept-dns=false --operator="$OPERATOR"

echo ""
echo "=============================================="
echo "  Klik URL di atas, login ke akun Tailscale"
echo "  dan berikan otorisasi pada browser."
echo "  SETELAH BERHASIL, KEMBALI KE SINI dan tekan"
echo "  ENTER untuk melanjutkan."
echo "=============================================="
read -p "Tekan Enter jika sudah selesai otorisasi..."

# 4. Verifikasi koneksi
echo "[4/5] Memeriksa koneksi..."
elapsed=0
while true; do
    ip=$("$TAILSCALE" ip -4 2>/dev/null || true)
    if [ -n "$ip" ] && [ "$ip" != "null" ]; then
        echo "Terhubung dengan IP: $ip"
        break
    fi
    sleep 2
    elapsed=$((elapsed + 2))
    if [ $elapsed -ge $TIMEOUT_AUTH ]; then
        echo "ERROR: Perangkat belum terhubung dalam ${TIMEOUT_AUTH} detik."
        echo "Coba jalankan kembali skrip atau periksa status di admin console Tailscale."
        exit 1
    fi
done

# 5. Aktifkan Tailscale SSH
echo "[5/5] Mengaktifkan Tailscale SSH..."
"$TAILSCALE" set --ssh --operator="$OPERATOR"

# 6. Informasi koneksi
echo ""
echo "=============================================="
echo " Instalasi selesai! "
echo " Gunakan informasi berikut untuk SSH dari Windows:"
echo ""
TAILSCALE_IP=$("$TAILSCALE" ip -4 2>/dev/null || echo "tidak ditemukan")
CURRENT_USER=$(whoami)
echo "   Perintah SSH:"
echo "   ssh ${CURRENT_USER}@${TAILSCALE_IP}"
echo ""
echo "   Contoh:"
echo "   ssh user@${TAILSCALE_IP}"
echo "=============================================="
