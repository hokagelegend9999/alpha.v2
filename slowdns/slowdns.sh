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
            echo -e "${CYAN}         🚀 INSTALASI SLOWDNS PREMIUM 🚀         ${NC}"
            echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            
            # Setup direktori SlowDNS (Sesuai panduan resmi)
            mkdir -p /root/slowdns[cite: 11]
            cd /root/slowdns || exit[cite: 11]

            # Mengunduh patch binary dan installer 
            echo -ne "${YELLOW} [⚙] Mengunduh Binary SlowDNS... ${NC}"
            wget -q -O slowdns-linux-amd64.tar.gz "https://raw.githubusercontent.com/hokagelegend9999/slowdns/main/slowdns-linux-amd64.tar.gz"[cite: 10]
            tar -zxvf slowdns-linux-amd64.tar.gz >/dev/null 2>&1
            chmod +x slowdns[cite: 8]
            echo -e "${GREEN}[OK]${NC}"

            echo -ne "${YELLOW} [⚙] Mengunduh Installer Resmi... ${NC}"
            wget -q -O install.sh "https://raw.githubusercontent.com/hokagelegend9999/slowdns/main/install.sh"[cite: 10]
            chmod +x install.sh
            echo -e "${GREEN}[OK]${NC}"

            echo -e "\n${YELLOW}Konfigurasi Lingkungan SlowDNS...${NC}"
            read -p " [?] Masukkan NS Domain Anda: " input_ns
            export NS_DOMAIN="${input_ns:-ns.hokage.web.id}"[cite: 9]
            echo "$NS_DOMAIN" > /root/nsdomain[cite: 9]

            # Menulis file slowdns.env agar tidak perlu prompt interaktif (Silent Install)
            cat > slowdns.env <<EOF
SLOWDNS_BINARY="slowdns"
SLOWDNS_UDP_ADDR=":53"
SLOWDNS_DOMAIN="${NS_DOMAIN}"
SLOWDNS_UPSTREAM_ADDR="127.0.0.1:22"
SLOWDNS_PRIVKEY_FILE="/root/slowdns/server.key"
EOF
            
            # Fix Resolv & Port 53 agar bersih 
            if systemctl is-active --quiet systemd-resolved; then
                systemctl stop systemd-resolved[cite: 9]
                systemctl disable systemd-resolved[cite: 9]
            fi
            chattr -i /etc/resolv.conf 2>/dev/null[cite: 9]
            rm -f /etc/resolv.conf[cite: 9]
            echo "nameserver 8.8.8.8" > /etc/resolv.conf[cite: 9]
            echo "nameserver 1.1.1.1" >> /etc/resolv.conf[cite: 9]
            chattr +i /etc/resolv.conf[cite: 9]
            
            # Eksekusi installer resmi
            echo -e "\n${YELLOW} [⚙] Memulai Proses Pemasangan... ${NC}"
            bash install.sh install[cite: 8]

            echo -e "\n${GREEN} [✔] Instalasi SlowDNS Berhasil Terpasang!${NC}"
            PUBKEY=$(cat /root/slowdns/server.pub)[cite: 9, 11]
            echo -e "${CYAN} PUB KEY Anda: ${WHITE}$PUBKEY${NC}"
            
            # (Opsional) Kirim Notif Tele jika diperlukan
            if [[ -n "$AUTO_CHATID" ]]; then[cite: 9]
                TEXT="<b>✅ SLOWDNS INSTALLED SUCCESSFULLY</b>%0A"[cite: 9]
                TEXT+="🌐 <b>NS Domain   :</b> <code>$NS_DOMAIN</code>%0A"[cite: 9]
                TEXT+="🔑 <b>Pub Key     :</b> <code>$PUBKEY</code>%0A"[cite: 9]
                curl -s -X POST "https://api.telegram.org/bot8401742770:AAFs81f2dBEfAIgr9uq2i_96ryclSG95ue8/sendMessage" \
                     -d chat_id="$AUTO_CHATID" -d text="$TEXT" -d parse_mode="html" > /dev/null 2>&1[cite: 9]
            fi

            read -n 1 -s -r -p "Tekan tombol apa saja untuk kembali..."
            ;;
        2)
            clear
            echo -e "${CYAN}         🗑️  UNINSTALL SLOWDNS PREMIUM 🗑️         ${NC}"
            
            cd /root/slowdns || exit[cite: 11]
            if [ -f "install.sh" ]; then
                bash install.sh uninstall[cite: 8, 11]
                echo -e "${GREEN}Service berhasil dihapus.${NC}"[cite: 11]
            else
                systemctl stop slowdns.service 2>/dev/null[cite: 11]
                systemctl disable slowdns.service 2>/dev/null
                rm -f /etc/systemd/system/slowdns.service
                systemctl daemon-reload
                echo -e "${GREEN}Penghapusan manual selesai.${NC}"
            fi

            read -n 1 -s -r -p "Tekan tombol apa saja untuk kembali..."
            ;;
        x) exit 0 ;;
        *) echo -e "${RED}Pilihan salah!${NC}"; sleep 1 ;;
    esac
    ;;
x) exit 0 ;;
*) echo -e "Salah input" ;;
esac
