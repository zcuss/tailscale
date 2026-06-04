#!/bin/bash

echo "============================================="
echo "  Memulai Otomasi SSH Userspace (Google IDX) "
echo "============================================="

# 1. Masuk ke direktori home
cd ~

# 2. Unduh biner statis Tailscale jika belum ada
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
    echo "[*] Menjalankan daemon Tailscale..."
    ./tailscaled --tun=userspace-networking --socks5-server=localhost:1055 > /dev/null 2>&1 &
    sleep 3
else
    echo "[*] Daemon Tailscale sudah berjalan."
fi

# 4. Hubungkan ke Tailnet MURNI SEBAGAI JEMBATAN JARINGAN (Matikan fitur --ssh bawaan)
echo "[*] Menyinkronkan jaringan Tailscale..."
./tailscale up --accept-dns=false --reset > /dev/null 2>&1

# 5. GENERATE KEY SSH UNTUK USER AKTIF (Bypass Password)
echo "[*] Menyiapkan kunci keamanan SSH..."
mkdir -p ~/.ssh
chmod 700 ~/.ssh
if [ ! -f "~/.ssh/id_rsa" ]; then
    ssh-keygen -A > /dev/null 2>&1
fi

# 6. BUAT KONFIGURASI SSHD KHUSUS USER (TANPA SUDO)
echo "[*] Membuat konfigurasi OpenSSH lokal..."
cat << 'EOF' > ~/.ssh/sshd_config_user
Port 2222
HostKey ~/.ssh/ssh_host_rsa_key
HostKey ~/.ssh/ssh_host_ecdsa_key
HostKey ~/.ssh/ssh_host_ed25519_key
PidFile ~/.ssh/sshd.pid
ChallengeResponseAuthentication no
PasswordAuthentication yes
PubkeyAuthentication yes
PermitEmptyPasswords yes
UsePAM no
EOF

# Jalankan ulang server SSHD lokal di port 2222 di bawah user aktif
pkill -f "sshd -f $HOME/.ssh/sshd_config_user"
/usr/sbin/sshd -f ~/.ssh/sshd_config_user

# 7. Tampilkan Informasi Akhir
IP_TAILSCALE=$(./tailscale ip -4)
USER_AKTIF=$(whoami)
echo "============================================="
echo "       INSTALASI SELESAI & SUKSES!           "
echo "============================================="
echo "IP Tailscale Anda: $IP_TAILSCALE"
echo "Port SSH Anda    : 2222"
echo "User Anda        : $USER_AKTIF"
echo "---------------------------------------------"
echo "Silakan remote dari CMD Windows Anda dengan mengetik:"
echo "ssh $USER_AKTIF@$IP_TAILSCALE -p 2222"
echo "============================================="
