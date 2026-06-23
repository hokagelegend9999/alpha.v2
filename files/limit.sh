#!/bin/bash
# ==========================================================
# HOKAGE LEGEND: AUTO INSTALLER LIMITER (STANDAR FHS LINUX)
# Target Direktori: /usr/local/sbin/
# ==========================================================

REPO="https://raw.githubusercontent.com/hokagelegend9999/alpha.v2/refs/heads/main/"

echo -e "[1/4] Membersihkan sistem dari struktur lama..."
systemctl stop limitvmess limitvless limittrojan limitshadowsocks >/dev/null 2>&1
systemctl disable limitvmess limitvless limittrojan limitshadowsocks >/dev/null 2>&1
# Menghapus file limit yang berserakan di folder xray
rm -f /etc/xray/limit.*
rm -f /etc/systemd/system/limit*.service

echo -e "[2/4] Mendownload File Eksekusi ke /usr/local/sbin/..."
wget -q -O /usr/local/sbin/limit-vmess "${REPO}files/vmess"
wget -q -O /usr/local/sbin/limit-vless "${REPO}files/vless"
wget -q -O /usr/local/sbin/limit-trojan "${REPO}files/trojan"
wget -q -O /usr/local/sbin/limit-shadowsocks "${REPO}files/shadowsocks"

# Memberikan hak akses eksekusi ke semua script limit
chmod +x /usr/local/sbin/limit-*

echo -e "[3/4] Menulis ulang Systemd Service secara Dinamis..."
# Fungsi pintar untuk menghemat kode (Otomatis menulis 4 file service)
create_service() {
    local name=$1
    cat > /etc/systemd/system/limit${name}.service <<-EOF
[Unit]
Description=Hokage Legend Limit ${name} Service
Documentation=https://t.me/hokagelegend1
After=network.target nss-lookup.target

[Service]
Type=simple
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/sbin/limit-${name}
Restart=on-failure
RestartSec=3s

[Install]
WantedBy=multi-user.target
EOF
}

# Mengeksekusi fungsi untuk membuat ke-4 service
create_service "vmess"
create_service "vless"
create_service "trojan"
create_service "shadowsocks"

echo -e "[4/4] Merestart dan Mengunci Service di Latar Belakang..."
systemctl daemon-reload
systemctl enable --now limitvmess
systemctl enable --now limitvless
systemctl enable --now limittrojan
systemctl enable --now limitshadowsocks

# Pengecekan Akhir
echo -e "\n✅ INSTALASI SELESAI!"
echo -e "Semua script limit sekarang beroperasi dari: /usr/local/sbin/"
