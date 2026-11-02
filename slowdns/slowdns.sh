#!/bin/bash
# =========================================
# Quick Setup | SlowDNS Manager (Auto-Mode Fixed)
# =========================================
# [INFO] Integrasi Otomatis dengan Bot Hokage Legend
# =========================================

BGreen='\e[1;32m'
BYellow='\e[1;33m'
BRed='\e[1;31m'
NC='\e[0m'

# 1. Bersihkan Konfigurasi Lama (Antisipasi Re-install)
iptables -t nat -F PREROUTING 2>/dev/null
iptables -D INPUT -p udp --dport 5300 -j ACCEPT 2>/dev/null
iptables -D INPUT -p udp --dport 53 -j ACCEPT 2>/dev/null
rm -f /root/nsdomain

systemctl stop server-sldns client-sldns slowdns 2>/dev/null
systemctl disable server-sldns client-sldns slowdns 2>/dev/null
rm -f /etc/systemd/system/server-sldns.service
rm -f /etc/systemd/system/client-sldns.service

# 2. Logika Sinkronisasi Variabel Bot
if [[ -n "$AUTO_NS" ]]; then
    NS_DOMAIN=$(echo "$AUTO_NS" | tr -d '[:space:]')
    echo -e "${BGreen} [BOT MODE] NS Domain Diterima: $NS_DOMAIN ${NC}"
else
    echo -e "${BYellow} [!] Warning: Variabel Bot tidak terdeteksi.${NC}"
    read -rp " Masukkan Subdomain NS: " manual_ns
    NS_DOMAIN=${manual_ns:-"ns.hokage.web.id"}
fi

echo "$NS_DOMAIN" > /root/nsdomain

# 3. Pengaturan Jaringan (Port 53 & 5300)
iptables -I INPUT -p udp --dport 53 -j ACCEPT
iptables -I INPUT -p udp --dport 5300 -j ACCEPT
iptables -t nat -I PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5300
netfilter-persistent save >/dev/null 2>&1

# 4. Instalasi Dependencies
apt update -y >/dev/null 2>&1
apt install -y python3 python3-dnslib net-tools dnsutils curl wget git dos2unix lsof >/dev/null 2>&1

if systemctl is-active --quiet systemd-resolved; then
    systemctl stop systemd-resolved
    systemctl disable systemd-resolved
fi

chattr -i /etc/resolv.conf 2>/dev/null
rm -f /etc/resolv.conf
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 1.1.1.1" >> /etc/resolv.conf
chattr +i /etc/resolv.conf

# 5. Konfigurasi Binary SlowDNS
mkdir -p /etc/slowdns
chmod 777 /etc/slowdns

REPO="https://raw.githubusercontent.com/Fatehfadz/source/refs/heads/main/slowdns"
wget -q -O /etc/slowdns/server.key "${REPO}/server.key" 2>/dev/null || true
wget -q -O /etc/slowdns/server.pub "${REPO}/server.pub" 2>/dev/null || true
wget -q -O /etc/slowdns/sldns-server "${REPO}/sldns-server" 2>/dev/null || true
wget -q -O /etc/slowdns/sldns-client "${REPO}/sldns-client" 2>/dev/null || true

# Jika key belum ada dari repo, generate otomatis
if [ ! -f /etc/slowdns/server.key ]; then
    wget -q -O /etc/slowdns/slowdns "https://raw.githubusercontent.com/hokagelegend9999/slowdns/main/slowdns"
    chmod +x /etc/slowdns/slowdns
    /etc/slowdns/slowdns -gen-key -privkey-file /etc/slowdns/server.key -pubkey-file /etc/slowdns/server.pub
    cp /etc/slowdns/slowdns /etc/slowdns/sldns-server
    cp /etc/slowdns/slowdns /etc/slowdns/sldns-client
fi

chmod +x /etc/slowdns/sldns-server 2>/dev/null
chmod +x /etc/slowdns/sldns-client 2>/dev/null

# 6. Pembuatan Systemd Service (Diubah ke port 22 agar tidak Connection Refused)
cat > /etc/systemd/system/server-sldns.service << END
[Unit]
Description=Server SlowDNS By Hokage Legend
After=network.target nss-lookup.target

[Service]
Type=simple
User=root
ExecStart=/etc/slowdns/sldns-server -udp :5300 -privkey-file /etc/slowdns/server.key $NS_DOMAIN 127.0.0.1:22
Restart=always
RestartSec=3s

[Install]
WantedBy=multi-user.target
END

cat > /etc/systemd/system/client-sldns.service << END
[Unit]
Description=Client SlowDNS By Hokage Legend
After=network.target nss-lookup.target

[Service]
Type=simple
User=root
ExecStart=/etc/slowdns/sldns-client -udp 8.8.8.8:53 --pubkey-file /etc/slowdns/server.pub $NS_DOMAIN 127.0.0.1:22
Restart=on-failure

[Install]
WantedBy=multi-user.target
END

# 7. Finalisasi
systemctl daemon-reload
systemctl enable --now client-sldns server-sldns
systemctl restart client-sldns server-sldns

PUBKEY=$(cat /etc/slowdns/server.pub 2>/dev/null || echo "Kunci tidak ditemukan")

clear
echo -e "${BGreen} [✔] Instalasi SlowDNS Versi Lama Berhasil Diperbarui! ${NC}"
echo -e " NS Domain : $NS_DOMAIN"
echo -e " Public Key: $PUBKEY"
