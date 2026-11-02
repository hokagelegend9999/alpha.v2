#!/bin/bash
# =========================================
# Quick Setup | SlowDNS Manager (Auto-Mode)
# =========================================
# [INFO] Integrasi Otomatis dengan Bot Hokage Legend
# =========================================

BGreen='\e[1;32m'
BYellow='\e[1;33m'
BRed='\e[1;31m'
NC='\e[0m'

# 1. Bersihkan Konfigurasi Lama (Antisipasi Re-install)
iptables -t nat -F PREROUTING
iptables -D INPUT -p udp --dport 5300 -j ACCEPT 2>/dev/null
rm -f /root/nsdomain

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
iptables -I INPUT -p udp --dport 5300 -j ACCEPT
iptables -t nat -I PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5300
netfilter-persistent save >/dev/null 2>&1

# 4. Instalasi Dependencies
apt update -y
apt install -y python3 python3-dnslib net-tools dnsutils curl wget git dos2unix lsof >/dev/null 2>&1

# Mematikan systemd-resolved agar port 53 bebas
if systemctl is-active --quiet systemd-resolved; then
    systemctl stop systemd-resolved
    systemctl disable systemd-resolved
fi

# Mengunci DNS VPS
chattr -i /etc/resolv.conf 2>/dev/null
rm -f /etc/resolv.conf
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 1.1.1.1" >> /etc/resolv.conf
chattr +i /etc/resolv.conf

# 5. Konfigurasi Binary SlowDNS (Mengamankan dari file 0 byte)
mkdir -p /etc/slowdns
chmod 755 /etc/slowdns

# Gunakan binary lokal yang valid (1.6M) jika sudah ada
if [[ -s "/etc/slowdns/slowdns" ]]; then
    cp -f /etc/slowdns/slowdns /etc/slowdns/sldns-server
elif [[ -s "/root/slowdns/slowdns" ]]; then
    cp -f /root/slowdns/slowdns /etc/slowdns/sldns-server
else
    REPO="https://github.com/hokagelegend9999/slowdns/raw/refs/heads/main/slowdns"
    wget -q -O /etc/slowdns/sldns-server "${REPO}/sldns-server"
fi

chmod +x /etc/slowdns/sldns-server

# Generate server.key & server.pub otomatis jika belum ada atau berukuran 0 byte
if [[ ! -s "/etc/slowdns/server.key" ]] || [[ ! -s "/etc/slowdns/server.pub" ]]; then
    rm -f /etc/slowdns/server.key /etc/slowdns/server.pub
    /etc/slowdns/sldns-server -gen-key -privkey-file /etc/slowdns/server.key -pubkey-file /etc/slowdns/server.pub
    chmod 600 /etc/slowdns/server.key
    chmod 644 /etc/slowdns/server.pub
fi

PUBKEY=$(cat /etc/slowdns/server.pub 2>/dev/null)

# 6. Pembuatan Systemd Service (Server SlowDNS)
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

# Matikan client-sldns jika file client 0 byte agar log tidak penuh error
if [[ ! -s "/etc/slowdns/sldns-client" ]]; then
    systemctl stop client-sldns 2>/dev/null
    systemctl disable client-sldns 2>/dev/null
    rm -f /etc/systemd/system/client-sldns.service
fi

# 7. Finalisasi
systemctl daemon-reload
systemctl reset-failed server-sldns 2>/dev/null
systemctl enable --now server-sldns
systemctl restart server-sldns

clear
# 8. Kirim Notifikasi ke Bot Telegram (SINKRONISASI + PUBLIC KEY)
if [[ -n "$AUTO_CHATID" ]]; then
    TOKEN="8401742770:AAFXaP8YTgwBztSwOqxCUQRTzD2dlQhk9xA"
    URL="https://api.telegram.org/bot$TOKEN/sendMessage"
    
    TEXT="<b>✅ SLOWDNS INSTALLED SUCCESSFULLY</b>%0A"
    TEXT+="<code>─────────────────────────────</code>%0A"
    TEXT+="📡 <b>IP VPS      :</b> <code>$(curl -s ifconfig.me)</code>%0A"
    TEXT+="🌐 <b>NS Domain  :</b> <code>$NS_DOMAIN</code>%0A"
    TEXT+="🔑 <b>Public Key :</b> <code>$PUBKEY</code>%0A"
    TEXT+="🔌 <b>Target Port :</b> <code>127.0.0.1:22</code>%0A"
    TEXT+="📅 <b>Waktu       :</b> <code>$(date +'%Y-%m-%d %H:%M:%S')</code>%0A"
    TEXT+="<code>─────────────────────────────</code>%0A"
    TEXT+="🚀 <b>Hokage Legend SlowDNS Service</b>"

    KEYBOARD='{"inline_keyboard": [[{"text": "🔙 KEMBALI KE MENU", "callback_data": "menu"}]]}'

    curl -s -X POST "$URL" \
         -d chat_id="$AUTO_CHATID" \
         -d text="$TEXT" \
         -d parse_mode="html" \
         -d reply_markup="$KEYBOARD" > /dev/null 2>&1
fi
sleep 2
