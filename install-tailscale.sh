cat << 'EOF' > install-tailscale.sh
#!/bin/bash

echo "============================================="
echo "Memulai Otomasi Instalasi Tailscale SSH (IDX)"
echo "============================================="

# 1. Masuk ke direktori home
cd ~

# 2. Unduh biner statis jika belum ada
if [ ! -d "tailscale_1.66.4_amd64" ]; then
    echo "[*] Mengunduh biner statis Tailscale..."
    wget https://pkgs.tailscale.com/stable/tailscale_1.66.4_amd64.tgz
    echo "[*] Mengekstrak arsip..."
    tar -xzvf tailscale_1.66.4_amd64.tgz
    rm tailscale_1.66.4_amd64.tgz
fi

cd tailscale_1.66.4_amd64

# 3. Jalankan daemon tailscaled di background jika belum aktif
if ! pgrep -x "tailscaled" > /dev/null; then
    echo "[*] Menjalankan daemon Tailscale (Userspace Mode)..."
    ./tailscaled --tun=userspace-networking --socks5-server=localhost:1055 &
    sleep 2
else
    echo "[*] Daemon Tailscale sudah berjalan."
fi

# 4. Ambil nama user aktif secara dinamis
USER_AKTIF=$(whoami)

# 5. Hubungkan ke Tailnet
echo "[*] Memicu tautan otentikasi Tailscale..."
./tailscale up --accept-dns=false --operator=$USER_AKTIF

# 6. Aktifkan Fitur Tailscale SSH
echo "[*] Mengaktifkan fitur Tailscale SSH..."
./tailscale set --ssh --operator=$USER_AKTIF

# 7. Tampilkan Informasi Akhir
IP_TAILSCALE=$(./tailscale ip -4)
echo "============================================="
echo "       INSTALASI SELESAI & SUKSES!           "
echo "============================================="
echo "User Lokal Anda  : $USER_AKTIF"
echo "IP Tailscale Anda: $IP_TAILSCALE"
echo "---------------------------------------------"
echo "Silakan remote dari CMD Windows Anda dengan mengetik:"
echo "ssh $USER_AKTIF@$IP_TAILSCALE"
echo "============================================="
EOF
