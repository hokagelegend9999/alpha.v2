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
# Menangkap variabel AUTO_NS yang dikirim bot melalui SSH wrapper
if [[ -n "$AUTO_NS" ]]; then
    NS_DOMAIN=$(echo "$AUTO_NS" | tr -d '[:space:]')
    echo -e "${BGreen} [BOT MODE] NS Domain Diterima: $NS_DOMAIN ${NC}"
else
    # Jika dijalankan manual (bukan via bot)
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

# Mematikan systemd-resolved agar port 53 bebas (Penting untuk Ubuntu)
if systemctl is-active --quiet systemd-resolved; then
    systemctl stop systemd-resolved
    systemctl disable systemd-resolved
fi

# 🛡️ FIX: Menghindari VPS kehilangan koneksi DNS (Dikunci Permanen)
chattr -i /etc/resolv.conf 2>/dev/null
rm -f /etc/resolv.conf
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 1.1.1.1" >> /etc/resolv.conf
chattr +i /etc/resolv.conf

# 5. Konfigurasi Binary SlowDNS
mkdir -p /etc/slowdns
chmod 777 /etc/slowdns

REPO="https://raw.githubusercontent.com/hokagelegend9999/alpha.v2/refs/heads/main/slowdns"
wget -q -O /etc/slowdns/server.key "${REPO}/server.key"
wget -q -O /etc/slowdns/server.pub "${REPO}/server.pub"
wget -q -O /etc/slowdns/sldns-server "${REPO}/sldns-server"
wget -q -O /etc/slowdns/sldns-client "${REPO}/sldns-client"
chmod +x /etc/slowdns/sldns-server
chmod +x /etc/slowdns/sldns-client

# 6. Pembuatan Systemd Service (Premium & Stabil)
# Server Service
cat > /etc/systemd/system/server-sldns.service << END
[Unit]
Description=Server SlowDNS By Hokage Legend
After=network.target nss-lookup.target

[Service]
Type=simple
User=root
ExecStart=/etc/slowdns/sldns-server -udp :5300 -privkey-file /etc/slowdns/server.key $NS_DOMAIN 127.0.0.1:2269
Restart=always
RestartSec=3s

[Install]
WantedBy=multi-user.target
END

# Client Service
cat > /etc/systemd/system/client-sldns.service << END
[Unit]
Description=Client SlowDNS By Hokage Legend
After=network.target nss-lookup.target

[Service]
Type=simple
User=root
ExecStart=/etc/slowdns/sldns-client -udp 8.8.8.8:53 --pubkey-file /etc/slowdns/server.pub $NS_DOMAIN 127.0.0.1:2269
Restart=on-failure

[Install]
WantedBy=multi-user.target
END

# 7. Finalisasi
systemctl daemon-reload
systemctl enable --now client-sldns server-sldns
systemctl restart client-sldns server-sldns

clear
# 8. Kirim Notifikasi ke Bot Telegram (SINKRONISASI)
if [[ -n "$AUTO_CHATID" ]]; then
    TOKEN="8401742770:AAFs81f2dBEfAIgr9uq2i_96ryclSG95ue8"
    URL="https://api.telegram.org/bot$TOKEN/sendMessage"
    
    TEXT="<b>✅ SLOWDNS INSTALLED SUCCESSFULLY</b>%0A"
    TEXT+="<code>─────────────────────────────</code>%0A"
    TEXT+="📡 <b>IP VPS      :</b> <code>$(curl -s ifconfig.me)</code>%0A"
    TEXT+="🌐 <b>NS Domain  :</b> <code>$NS_DOMAIN</code>%0A"
    TEXT+="🔌 <b>Target Port :</b> <code>127.0.0.1:2269</code>%0A"
    TEXT+="📅 <b>Waktu       :</b> <code>$(date +'%Y-%m-%d %H:%M:%S')</code>%0A"
    TEXT+="<code>─────────────────────────────</code>%0A"
    TEXT+="🚀 <b>Hokage Legend SlowDNS Service</b>"

    # Tombol Kembali
    KEYBOARD='{"inline_keyboard": [[{"text": "🔙 KEMBALI KE MENU", "callback_data": "menu"}]]}'

    curl -s -X POST "$URL" \
         -d chat_id="$AUTO_CHATID" \
         -d text="$TEXT" \
         -d parse_mode="html" \
         -d reply_markup="$KEYBOARD" > /dev/null 2>&1
fi
sleep 2
