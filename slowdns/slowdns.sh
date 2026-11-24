#!/bin/bash
# =========================================
# Quick Setup | SlowDNS Manager (Updated v2)
# Integrasi Arsitektur Baru (Direct UDP 53 + NOTRACK)
# =========================================

BGreen='\e[1;32m'
BYellow='\e[1;33m'
BRed='\e[1;31m'
NC='\e[0m'

WORK_DIR="/etc/slowdns"
REPO="https://raw.githubusercontent.com/hokagelegend9999/alpha.v2/refs/heads/main/slowdns"
REPO_BACKUP="https://raw.githubusercontent.com/hokagelegend9999/slowdns/main"

# Deteksi otomatis port target (jika Dropbear 2269 aktif pakai 2269, jika tidak gunakan SSH 22)
if ss -tlpn | grep -q ':2269 '; then
    TARGET_PORT="127.0.0.1:2269"
else
    TARGET_PORT="127.0.0.1:22"
fi

# 1. Bersihkan Service & Aturan NAT SlowDNS Lama
systemctl stop server-sldns client-sldns slowdns 2>/dev/null
systemctl disable server-sldns client-sldns 2>/dev/null
rm -f /etc/systemd/system/server-sldns.service /etc/systemd/system/client-sldns.service
iptables -t nat -D PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5300 2>/dev/null
iptables -D INPUT -p udp --dport 5300 -j ACCEPT 2>/dev/null
iptables -I INPUT -p udp --dport 53 -j ACCEPT
netfilter-persistent save >/dev/null 2>&1

# 2. Logika Sinkronisasi Variabel Bot
if [[ -n "$AUTO_NS" ]]; then
    NS_DOMAIN=$(echo "$AUTO_NS" | tr -d '[:space:]')
    echo -e "${BGreen} [BOT MODE] NS Domain Diterima: $NS_DOMAIN ${NC}"
else
    echo -e "${BYellow} [!] Warning: Variabel Bot tidak terdeteksi.${NC}"
    read -rp " Masukkan Subdomain NS: " manual_ns
    NS_DOMAIN=${manual_ns:-"dns-id.hokagelegend.net"}
fi

echo "$NS_DOMAIN" > /root/nsdomain

# 3. Bebaskan Port 53
if systemctl is-active --quiet systemd-resolved; then
    systemctl stop systemd-resolved
    systemctl disable systemd-resolved
fi

chattr -i /etc/resolv.conf 2>/dev/null
rm -f /etc/resolv.conf
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 1.1.1.1" >> /etc/resolv.conf
chattr +i /etc/resolv.conf

# 4. Siapkan Folder & Ambil Berkas
mkdir -p "$WORK_DIR"
chown root:root "$WORK_DIR"
chmod 0755 "$WORK_DIR"

# Prioritaskan salin berkas lokal jika ada
if [[ -f "/root/slowdns/install.sh" && -f "/root/slowdns/slowdns" ]]; then
    cp -f /root/slowdns/install.sh "$WORK_DIR/install.sh"
    cp -f /root/slowdns/slowdns "$WORK_DIR/slowdns"
fi

# Fallback unduh jika belum ada di WORK_DIR
if [[ ! -s "$WORK_DIR/install.sh" ]] || grep -q "404: Not Found" "$WORK_DIR/install.sh" 2>/dev/null; then
    wget -q -O "$WORK_DIR/install.sh" "${REPO}/install.sh" 2>/dev/null || true
    if [[ ! -s "$WORK_DIR/install.sh" ]] || grep -q "404: Not Found" "$WORK_DIR/install.sh" 2>/dev/null; then
        if [[ -f "/root/slowdns.tar.gz" ]]; then
            tar -xzf /root/slowdns.tar.gz -C "$WORK_DIR" install.sh 2>/dev/null || true
        elif [[ -f "/root/backup_slowdns_etc.tar.gz" ]]; then
            tar -xzf /root/backup_slowdns_etc.tar.gz -C /tmp 2>/dev/null && cp /tmp/etc/slowdns/install.sh "$WORK_DIR/"
        fi
    fi
fi

if [[ ! -s "$WORK_DIR/slowdns" ]] || grep -q "404: Not Found" "$WORK_DIR/slowdns" 2>/dev/null; then
    wget -q -O "$WORK_DIR/slowdns" "${REPO}/slowdns" 2>/dev/null || true
    if [[ ! -s "$WORK_DIR/slowdns" ]] || grep -q "404: Not Found" "$WORK_DIR/slowdns" 2>/dev/null; then
        wget -q -O "$WORK_DIR/slowdns" "${REPO_BACKUP}/slowdns" 2>/dev/null || true
    fi
    if [[ ! -s "$WORK_DIR/slowdns" ]] || grep -q "404: Not Found" "$WORK_DIR/slowdns" 2>/dev/null; then
        if [[ -f "/root/backup_slowdns_etc.tar.gz" ]]; then
            tar -xzf /root/backup_slowdns_etc.tar.gz -C /tmp 2>/dev/null && cp /tmp/etc/slowdns/slowdns "$WORK_DIR/"
        elif [[ -f "/root/slowdns.tar.gz" ]]; then
            tar -xzf /root/slowdns.tar.gz -C "$WORK_DIR" slowdns 2>/dev/null || true
        fi
    fi
fi

chown root:root "$WORK_DIR/install.sh" "$WORK_DIR/slowdns"
chmod 0755 "$WORK_DIR/install.sh" "$WORK_DIR/slowdns"
dos2unix "$WORK_DIR/install.sh" >/dev/null 2>&1

# 5. Salin atau Buat Key Baru & Pre-konfigurasi slowdns.env
if [[ ! -f "$WORK_DIR/server.key" ]]; then
    if [[ -f "/root/slowdns/server.key" && -f "/root/slowdns/server.pub" ]]; then
        cp -f /root/slowdns/server.key "$WORK_DIR/server.key"
        cp -f /root/slowdns/server.pub "$WORK_DIR/server.pub"
    elif [[ -f "/root/backup_slowdns_etc.tar.gz" ]]; then
        tar -xzf /root/backup_slowdns_etc.tar.gz -C /tmp 2>/dev/null
        cp -f /tmp/etc/slowdns/server.key "$WORK_DIR/server.key" 2>/dev/null || true
        cp -f /tmp/etc/slowdns/server.pub "$WORK_DIR/server.pub" 2>/dev/null || true
    fi
fi

if [[ ! -f "$WORK_DIR/server.key" ]]; then
    "$WORK_DIR/slowdns" -gen-key -privkey-file "$WORK_DIR/server.key" -pubkey-file "$WORK_DIR/server.pub"
fi

if [[ -f "$WORK_DIR/server.key" && -f "$WORK_DIR/server.pub" ]]; then
    chown root:root "$WORK_DIR/server.key" "$WORK_DIR/server.pub"
    chmod 0600 "$WORK_DIR/server.key"
    chmod 0644 "$WORK_DIR/server.pub"
fi

# Ambil daftar IP publik untuk NOTRACK binding
DIRECT_BINDINGS=$(ip -o -4 addr show scope global | awk '{sub(/@.*/, "", $2); split($4, a, "/"); print a[1]","$2}' | tr '\n' ' ' | sed 's/ $//')

cat > "$WORK_DIR/slowdns.env" <<EOF
SLOWDNS_BINARY="slowdns"
SLOWDNS_UDP_ADDR=":53"
SLOWDNS_PRIVKEY_FILE="$WORK_DIR/server.key"
SLOWDNS_DOMAIN="$NS_DOMAIN"
SLOWDNS_UPSTREAM_ADDR="$TARGET_PORT"
SLOWDNS_EXTRA_ARGS=""
SLOWDNS_DIRECT_IPV4=""
SLOWDNS_DIRECT_INTERFACE=""
SLOWDNS_DIRECT_BINDINGS="$DIRECT_BINDINGS"
EOF

chown root:root "$WORK_DIR/slowdns.env"
chmod 0600 "$WORK_DIR/slowdns.env"

# 6. Jalankan Installer Baru dalam Mode Non-Interaktif
cd "$WORK_DIR"
bash "$WORK_DIR/install.sh" install

PUB_KEY=$(cat "$WORK_DIR/server.pub" 2>/dev/null)
echo -e "${BGreen} [OK] SlowDNS Berhasil Diinstal!${NC}"
echo -e "${BGreen} NS Domain  : $NS_DOMAIN${NC}"
echo -e "${BGreen} Public Key : $PUB_KEY${NC}"
echo -e "${BGreen} Upstream   : $TARGET_PORT${NC}"

# 7. Kirim Notifikasi ke Bot Telegram jika variabel bot ada
if [[ -n "$AUTO_CHATID" ]]; then
    TOKEN="8401742770:AAFs81f2dBEfAIgr9uq2i_96ryclSG95ue8"
    URL="https://api.telegram.org/bot$TOKEN/sendMessage"
    
    TEXT="<b>⚙️ SLOWDNS UPDATED & INSTALLED</b>%0A"
    TEXT+="<code>───────────────────────────────</code>%0A"
    TEXT+="🌐 <b>IP VPS      :</b> <code>$(curl -s ifconfig.me)</code>%0A"
    TEXT+="🔑 <b>NS Domain  :</b> <code>$NS_DOMAIN</code>%0A"
    TEXT+="🔓 <b>Public Key :</b> <code>$PUB_KEY</code>%0A"
    TEXT+="🚪 <b>Target Port :</b> <code>$TARGET_PORT</code>%0A"
    TEXT+="⚡ <b>Mode        :</b> <code>Direct UDP 53 (NOTRACK)</code>%0A"
    TEXT+="🕒 <b>Waktu       :</b> <code>$(date +'%Y-%m-%d %H:%M:%S')</code>%0A"
    TEXT+="<code>─────────────────────────────</code>%0A"
    TEXT+="🤖 <b>Hokage Legend SlowDNS Service</b>"

    KEYBOARD='{"inline_keyboard": [[{"text": "« KEMBALI KE MENU", "callback_data": "menu"}]]}'

    curl -s -X POST "$URL" \
         -d chat_id="$AUTO_CHATID" \
         -d text="$TEXT" \
         -d parse_mode="html" \
         -d reply_markup="$KEYBOARD" > /dev/null 2>&1
fi
