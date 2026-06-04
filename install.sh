#!/bin/bash

echo "============================================="
echo "  Memulai Otomasi Tailscale SSH Berbasis IDX "
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

# 4. Ambil nama user aktif IDX secara dinamis (zcusclaw-xxxxxxxxx)
USER_AKTIF=$(whoami)

# 5. Hubungkan ke Tailnet & Paksa Aktifkan Tailscale SSH bawaan dengan flag --reset
echo "[*] Menghubungkan ke Tailnet dan Mengaktifkan Fitur SSH..."
./tailscale up --accept-dns=false --ssh --operator=$USER_AKTIF --reset --qr

# 6. Tampilkan Informasi Akhir
IP_TAILSCALE=$(./tailscale ip -4)
echo "============================================="
echo "       INSTALASI SELESAI & SUKSES!           "
echo "============================================="
echo "User Resmi IDX Anda: $USER_AKTIF"
echo "IP Tailscale Anda  : $IP_TAILSCALE"
echo "---------------------------------------------"
echo "Silakan remote dari CMD Windows Anda dengan mengetik:"
echo "ssh $USER_AKTIF@$IP_TAILSCALE"
echo "============================================="
