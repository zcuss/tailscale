#!/usr/bin/env bash
# Tailscale Installer untuk Google Firebase Studio (IDX) tanpa sudo
# Jalankan: bash -c "$(curl -fsSL https://raw.githubusercontent.com/zcuss/tailscale/Main/install.sh)"

set -e

TAILSCALE_VERSION="1.66.4"
TAILSCALE_DIR="$HOME/tailscale-${TAILSCALE_VERSION}"
TAILSCALE_BIN_DIR="$TAILSCALE_DIR"
TAILSCALED="$TAILSCALE_BIN_DIR/tailscaled"
TAILSCALE="$TAILSCALE_BIN_DIR/tailscale"
OPERATOR="${OPERATOR:-user}"
TIMEOUT_AUTH=120  # detik menunggu otorisasi

echo "=== Tailscale Installer for Google IDX ==="

# 1. Unduh dan ekstrak jika belum ada
if [ ! -f "$TAILSCALED" ]; then
    echo "[1/5] Mengunduh Tailscale biner statis..."
    cd "$HOME"
    wget -q "https://pkgs.tailscale.com/stable/tailscale_${TAILSCALE_VERSION}_amd64.tgz" -O tailscale.tgz
    tar -xzf tailscale.tgz
    rm tailscale.tgz
    # rename folder standar
    if [ -d "tailscale_${TAILSCALE_VERSION}_amd64" ]; then
        mv "tailscale_${TAILSCALE_VERSION}_amd64" "$TAILSCALE_DIR"
    fi
    echo "[1/5] Biner berhasil disiapkan."
else
    echo "[1/5] Biner Tailscale sudah ada, lewati unduh."
fi

cd "$TAILSCALE_BIN_DIR"

# 2. Jalankan tailscaled (userspace)
echo "[2/5] Menjalankan tailscaled (userspace-networking)..."
# Hentikan proses lama jika ada
pkill -f "tailscaled" 2>/dev/null || true
sleep 1
# Jalankan di background
nohup "$TAILSCALED" --tun=userspace-networking --socks5-server=localhost:1055 &>/tmp/tailscaled.log &
echo "tailscaled dijalankan (PID $!)"

# Tunggu hingga daemon siap
echo "Menunggu daemon siap..."
for i in {1..10}; do
    if "$TAILSCALE" status >/dev/null 2>&1; then
        break
    fi
    sleep 1
done

# 3. Koneksi ke Tailscale + Jeda Otorisasi Manual
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

# 4. Verifikasi koneksi setelah Tuan konfirmasi
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
        echo "ERROR: Setelah menekan Enter, perangkat belum terhubung dalam ${TIMEOUT_AUTH} detik."
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
