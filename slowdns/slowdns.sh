#!/bin/bash
# ==========================================
#   HOKAGE LEGEND ULTIMATE MENU
#   Fitur: ZIVPN Monitor & SlowDNS Installer (v8 Patch)
# ==========================================

BIBlack='\033[1;90m'      # Black
BIRed='\033[1;91m'        # Red
BIGreen='\033[1;92m'      # Green
BIYellow='\033[1;93m'     # Yellow
BIBlue='\033[1;94m'       # Blue
BIPurple='\033[1;95m'     # Purple
BICyan='\033[1;96m'       # Cyan
BIWhite='\033[1;97m'      # White
NC='\e[0m'

export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[0;33m'
export BLUE='\033[0;34m'
export PURPLE='\033[0;35m'
export CYAN='\033[0;36m'
export LIGHT='\033[0;37m'
export NC='\033[0m'

y='\033[1;33m'
CYAN="\033[96m"
z="\033[96m"
Blue="\033[0;34m"
green='\033[0;32m'
grenbo="\e[92;1m"
purple="\033[1;95m"
YELL='\033[0;33m'
white='\033[1;37m'
G1="\033[1;31m" 
G2="\033[1;33m" 

print_yellow() {
    echo -e "${y}$1${NC}"
}

MYIP=$(curl -sS ipv4.icanhazip.com 2>/dev/null)
IPVPS=$MYIP
username=$(cat /usr/bin/user 2>/dev/null || echo "Unknown")
exp=$(cat /usr/bin/e 2>/dev/null || echo "Unknown")
certifacate="?" 
sts="${green}Active${NC}"

# ==========================================
# SUB-MENU ZIVPN
# ==========================================
function menu_zivpn() {
    CONFIG_FILE="/etc/zivpn/config.json"
    DB_FILE="/etc/ssh/.ssh.db"

    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "${RED}Error: ZiVPN belum terinstall atau config hilang!${NC}"
        sleep 2
        return
    fi

    clear
    print_yellow "════════════════════════════════════════════"
    echo -e "${GREEN}          ZIVPN USER MANAGEMENT          ${NC}"
    print_yellow "      ═════════════════════════════      "
    echo -e " [1] Tambah User ZiVPN"
    echo -e " [2] Hapus User ZiVPN"
    echo -e " [3] Edit Password User ZiVPN"
    echo -e " [4] Lihat Daftar User & Detail (Monitor)"
    echo -e " [5] Cek Koneksi IP Aktif ZiVPN"
    echo -e " [6] Sync Semua User SSH ke ZiVPN"
    echo -e " [x] Kembali ke Menu Utility"
    print_yellow "════════════════════════════════════════════"
    read -p " Pilih Menu [1-6 / x] : " option

    case $option in
        1)
            read -p "Username: " user
            jq --arg u "$user" '.auth.config += [$u]' "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
            systemctl restart zivpn
            echo -e "${GREEN}Berhasil menambah user: $user${NC}"
            sleep 2; menu_zivpn ;;
        2)
            read -p "Username: " user
            jq --arg u "$user" '.auth.config -= [$u]' "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
            systemctl restart zivpn
            echo -e "${GREEN}Berhasil menghapus user: $user${NC}"
            sleep 2; menu_zivpn ;;
        4)
            clear
            echo -e "Daftar User ZiVPN:"
            jq -r '.auth.config[]' "$CONFIG_FILE" | nl
            read -p "Tekan enter untuk kembali..."
            menu_zivpn ;;
        x) return ;;
        *) menu_zivpn ;;
    esac
}

clear
echo -e " "
print_yellow "══════════════════════════════════════════════════════════"
echo -e "                  ${y}MENU UTILITY SYSTEM${NC}      "
print_yellow "══════════════════════════════════════════════════════════"
echo -e "${z}$NC [${white}15${NC}]$grenbo MENU ZIVPN PREMIUM$NC              ${z} $NC [${white}16${NC}]$purple CLEAN CACHE,LOG,RAM$NC"
echo -e "${z}$NC [${white}19${NC}]$grenbo FIX XRAY CONFIG$NC                 ${z} $NC [${white}20${NC}]$purple MENU SLOWDNS$NC"
print_yellow "══════════════════════════════════════════════════════════"
echo -e "         ${y}SELECT THE MENU BY TYPING 1/20 THEN ENTER${NC} "
print_yellow "══════════════════════════════════════════════════════════"
echo -e "${Blue} $NC${G1}Developer${NC}      ${z}=${NC} HOKAGE LEGEND"
echo -e "${Blue} $NC${G1}IP ADDRESS${NC}     ${z}=${NC} $IPVPS${NC}"
print_yellow "══════════════════════════════════════════════════════════"
echo -e ""
read -p " PILIH OPSI MENU [ 1-20 atau x] ➤ : " opt
echo -e ""

case $opt in
15 | 15) 
    menu_zivpn 
    ;;
20 | 20)
    clear
    print_yellow "══════════════════════════════════════════════════"
    echo -e "               ${CYAN}MENU SLOWDNS PREMIUM${NC}                "
    print_yellow "══════════════════════════════════════════════════"
    echo -e " [1]  Install SlowDNS (Offical v8 Patch)"
    echo -e " [2]  Uninstall SlowDNS"
    echo -e " [x]  Kembali ke Menu Utility"
    print_yellow "══════════════════════════════════════════════════"
    read -p " Pilih Opsi [1-2 atau x]: " sldns_opt
    
    case $sldns_opt in
        1)
            clear
            C_BLUE='\033[0;34m'
            C_CYAN='\033[1;96m'
            C_YELLOW='\033[1;33m'
            C_GREEN='\033[1;32m'
            C_NC='\033[0m'
            BGreen='\e[1;32m'
            BYellow='\e[1;33m'
            
            echo -e "${C_BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_NC}"
            echo -e "${C_CYAN}         🚀 INSTALASI SLOWDNS PREMIUM 🚀         ${C_NC}"
            echo -e "${C_BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_NC}"
            
            # 1. Bersihkan Konfigurasi Lama
            echo -ne "${C_YELLOW} [⚙] Membersihkan sistem lama... ${C_NC}"
            iptables -t nat -F PREROUTING
            iptables -D INPUT -p udp --dport 5300 -j ACCEPT 2>/dev/null
            iptables -D INPUT -p udp --dport 53 -j ACCEPT 2>/dev/null
            rm -f /root/nsdomain
            
            systemctl stop server-sldns client-sldns slowdns 2>/dev/null
            systemctl disable server-sldns client-sldns slowdns 2>/dev/null
            rm -f /etc/systemd/system/server-sldns.service
            rm -f /etc/systemd/system/client-sldns.service
            echo -e "${C_GREEN}[OK]${C_NC}"
            
            # 2. Sinkronisasi Domain
            echo -e ""
            if [[ -n "$AUTO_NS" ]]; then
                NS_DOMAIN=$(echo "$AUTO_NS" | tr -d '[:space:]')
                echo -e "${BGreen} [BOT MODE] NS Domain Diterima: $NS_DOMAIN ${C_NC}"
            else
                echo -e "${BYellow} [!] Warning: Variabel Bot tidak terdeteksi.${C_NC}"
                read -rp " [?] Masukkan Subdomain NS: " manual_ns
                NS_DOMAIN=${manual_ns:-"ns.hokage.web.id"}
            fi
            echo "$NS_DOMAIN" > /root/nsdomain
            echo -e ""
            
            # 3. Jaringan & Port 53
            echo -ne "${C_YELLOW} [⚙] Mengatur Routing Jaringan... ${C_NC}"
            iptables -I INPUT -p udp --dport 53 -j ACCEPT
            netfilter-persistent save >/dev/null 2>&1
            echo -e "${C_GREEN}[OK]${C_NC}"
            
            # 4. Resolv & Dependencies
            echo -ne "${C_YELLOW} [⚙] Memperbarui Dependensi & DNS... ${C_NC}"
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
            echo -e "${C_GREEN}[OK]${C_NC}"
            
            # 5. Konfigurasi Binary (Dari Repo Terbaru - Murni Binary)
            echo -ne "${C_YELLOW} [⚙] Mengunduh Binary SlowDNS... ${C_NC}"
            mkdir -p /etc/slowdns
            chmod 777 /etc/slowdns
            
            # Menggunakan link langsung ke file 'slowdns'
            wget -q -O /etc/slowdns/slowdns "https://raw.githubusercontent.com/hokagelegend9999/slowdns/main/slowdns"
            chmod +x /etc/slowdns/slowdns
            echo -e "${C_GREEN}[OK]${C_NC}"
            
            echo -ne "${C_YELLOW} [⚙] Menghasilkan Keys... ${C_NC}"
            /etc/slowdns/slowdns -gen-key -privkey-file /etc/slowdns/server.key -pubkey-file /etc/slowdns/server.pub
            PUBKEY=$(cat /etc/slowdns/server.pub)
            echo -e "${C_GREEN}[OK]${C_NC}"
            
            # 6. Pembuatan Systemd Service
            echo -ne "${C_YELLOW} [⚙] Membangun Service Systemd... ${C_NC}"
            cat > /etc/systemd/system/slowdns.service << END
[Unit]
Description=SlowDNS Server by Hokage Legend
After=network.target nss-lookup.target

[Service]
Type=simple
User=root
ExecStart=/etc/slowdns/slowdns -udp :53 -privkey-file /etc/slowdns/server.key $NS_DOMAIN 127.0.0.1:2269
Restart=always
RestartSec=3s

[Install]
WantedBy=multi-user.target
END
            echo -e "${C_GREEN}[OK]${C_NC}"
            
            # 7. Finalisasi
            systemctl daemon-reload
            systemctl enable --now slowdns >/dev/null 2>&1
            systemctl restart slowdns
            
            # 8. Notifikasi Bot Telegram
            if [[ -n "$AUTO_CHATID" ]]; then
                TOKEN="8401742770:AAFs81f2dBEfAIgr9uq2i_96ryclSG95ue8"
                URL="https://api.telegram.org/bot$TOKEN/sendMessage"
                
                TEXT="<b>✅ SLOWDNS INSTALLED SUCCESSFULLY</b>%0A"
                TEXT+="<code>─────────────────────────────</code>%0A"
                TEXT+="📡 <b>IP VPS      :</b> <code>$(curl -s ifconfig.me)</code>%0A"
                TEXT+="🌐 <b>NS Domain   :</b> <code>$NS_DOMAIN</code>%0A"
                TEXT+="🔑 <b>Pub Key     :</b> <code>$PUBKEY</code>%0A"
                TEXT+="🔌 <b>Target Port :</b> <code>127.0.0.1:2269</code>%0A"
                TEXT+="📅 <b>Waktu       :</b> <code>$(date +'%Y-%m-%d %H:%M:%S')</code>%0A"
                TEXT+="<code>─────────────────────────────</code>%0A"
                TEXT+="🚀 <b>Hokage Legend SlowDNS Service V8</b>"
            
                KEYBOARD='{"inline_keyboard": [[{"text": "🔙 KEMBALI KE MENU", "callback_data": "menu"}]]}'
            
                curl -s -X POST "$URL" \
                     -d chat_id="$AUTO_CHATID" \
                     -d text="$TEXT" \
                     -d parse_mode="html" \
                     -d reply_markup="$KEYBOARD" > /dev/null 2>&1
            fi
            
            echo -e "\n${C_GREEN} [✔] Instalasi SlowDNS Berhasil Terpasang!${C_NC}"
            echo -e "${C_CYAN} PUB KEY Anda: ${WHITE}$PUBKEY${C_NC}"
            echo -e "${C_BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_NC}\n"
            
            read -n 1 -s -r -p "Tekan tombol apa saja untuk kembali..."
            menu-x
            ;;
        2)
            clear
            C_BLUE='\033[0;34m'
            C_CYAN='\033[1;96m'
            C_YELLOW='\033[1;33m'
            C_GREEN='\033[1;32m'
            C_NC='\033[0m'
            
            echo -e "${C_BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_NC}"
            echo -e "${C_CYAN}         🗑️  UNINSTALL SLOWDNS PREMIUM 🗑️         ${C_NC}"
            echo -e "${C_BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_NC}"
            echo -e ""
            
            echo -ne "${C_YELLOW} [⚙] Menghentikan dan menonaktifkan proses... ${C_NC}"
            systemctl stop slowdns > /dev/null 2>&1
            systemctl disable slowdns > /dev/null 2>&1
            echo -e "${C_GREEN}[OK]${C_NC}"
            
            echo -ne "${C_YELLOW} [⚙] Menghapus binary dan konfigurasi... ${C_NC}"
            rm -f /etc/systemd/system/slowdns.service
            systemctl daemon-reload > /dev/null 2>&1
            rm -rf /etc/slowdns
            rm -f /root/nsdomain
            echo -e "${C_GREEN}[OK]${C_NC}"
            
            echo -ne "${C_YELLOW} [⚙] Membersihkan aturan Iptables (Port 53)... ${C_NC}"
            iptables -t nat -D PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5300 > /dev/null 2>&1
            iptables -D INPUT -p udp --dport 5300 -j ACCEPT > /dev/null 2>&1
            iptables -D INPUT -p udp --dport 53 -j ACCEPT > /dev/null 2>&1
            netfilter-persistent save > /dev/null 2>&1
            echo -e "${C_GREEN}[OK]${C_NC}"
            
            echo -e "\n${C_GREEN} [✔] SlowDNS Berhasil Dihapus Sepenuhnya!${C_NC}"
            echo -e "${C_BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_NC}\n"
            
            read -n 1 -s -r -p "Tekan tombol apa saja untuk kembali..."
            menu-x
            ;;
        x) menu-x ;;
        *) echo -e "${RED}Pilihan salah!${NC}"; sleep 1; menu-x ;;
    esac
    ;;
x) exit 0 ;;
*) echo -e "Salah input" ;;
esac
