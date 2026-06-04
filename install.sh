#!/bin/bash

echo "============================================="
echo "  Memulai Otomasi Koneksi Jaringan Tailscale "
echo "============================================="

# 1. Masuk ke direktori home
cd ~

# 2. Unduh biner statis jika belum ada
if [ ! -d "tailscale_1.66.4_amd64" ]; then
    echo "[*] Mengunduh biner statis Tailscale..."
    wget -q https://pkgs.tailscale.com/stable/tailscale_1.66.4_amd64.tgz
    echo "[*] Mengekstrak arsip..."
    tar -xzvf tailscale_1.66.4_amd64.tgz > /dev/null
    rm tailscale_1.66.4_amd64.tgz
fi

cd tailscale_1.66.4_amd64

# 3. Jalankan daemon tailscaled secara independen
if ! pgrep -x "tailscaled" > /dev/null; then
    echo "[*] Menjalankan daemon Tailscale (Userspace Mode)..."
    ./tailscaled --tun=userspace-networking --socks5-server=localhost:1055 > /dev/null 2>&1 &
    sleep 3
else
    echo "[*] Daemon Tailscale sudah berjalan."
fi

# 4. Hubungkan ke Tailnet
echo "[*] Memicu tautan otentikasi Tailscale..."
./tailscale up --accept-dns=false --qr

# 5. Buat Password Baru untuk User Aktif Tuan
USER_AKTIF=$(whoami)
echo "[*] Menyetel password SSH untuk user: $USER_AKTIF"
echo "$USER_AKTIF:zcusclaw123" | sudo chpasswd

# 6. Perbaikan Direktori Runtime SSHD & Jalankan Server OpenSSH
echo "[*] Memulai ulang Server OpenSSH lokal..."
sudo mkdir -p /var/run/sshd
sudo chmod 0755 /var/run/sshd
sudo ssh-keygen -A > /dev/null 2>&1

# Matikan sshd lama jika ada, lalu jalankan yang baru di port 2222
sudo pkill -f "sshd -p 2222"
sudo /usr/sbin/sshd -p 2222 -o "PasswordAuthentication=yes" -o "PermitRootLogin=yes"

# 7. Tampilkan Informasi Akhir
IP_TAILSCALE=$(./tailscale ip -4)
echo "============================================="
echo "       INSTALASI SELESAI & SUKSES!           "
echo "============================================="
echo "IP Tailscale Anda: $IP_TAILSCALE"
echo "Port SSH Anda    : 2222"
echo "Password SSH Anda: zcusclaw123"
echo "---------------------------------------------"
echo "Silakan remote dari CMD Windows Anda dengan mengetik:"
echo "ssh $USER_AKTIF@$IP_TAILSCALE -p 2222"
echo "============================================="
