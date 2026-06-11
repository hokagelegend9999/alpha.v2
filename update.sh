#!/bin/bash

# ==========================================
#  HOKAGE LEGEND - UPDATE SCRIPT (THEMED)
# ==========================================

# --- DEFINISI WARNA TEMA ---
NC='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
WHITE='\033[0;37m'
BOLD='\033[1m'
BLINK='\033[5m'

# --- INSTALL LOLCAT (JIKA BELUM ADA) ---
if ! command -v lolcat &> /dev/null; then
    apt-get install ruby -y &> /dev/null
    gem install lolcat &> /dev/null
fi

clear

# ==================================================
# FUNGSI GRADASI (SESUAI TEMA HOKAGE)
# ==================================================
print_gradient() {
    local text="$1"
    awk -v text="$text" 'BEGIN {
        len = length(text);
        r_start=255; g_start=215; b_start=0;
        r_mid=0;      g_mid=128;   b_mid=255;
        r_end=138;    g_end=43;    b_end=226;
        for (i=0; i<len; i++) {
            ratio = i / (len-1);
            if (ratio <= 0.5) {
                f = ratio * 2;
                r = int(r_start + (r_mid - r_start) * f);
                g = int(g_start + (g_mid - g_start) * f);
                b = int(b_start + (b_mid - b_start) * f);
            } else {
                f = (ratio - 0.5) * 2;
                r = int(r_mid + (r_end - r_mid) * f);
                g = int(g_mid + (g_end - g_mid) * f);
                b = int(b_mid + (b_end - b_mid) * f);
            }
            printf "\033[38;2;%d;%d;%dm%s", r, g, b, substr(text, i+1, 1);
        }
        printf "\033[0m\n";
    }'
}

# --- FUNGSI ANIMASI LOADING PREMIUM ---
hokage_anim() {
    CMD="$1"
    
    # Menjalankan perintah update di background
    (
        [[ -e $HOME/fim ]] && rm $HOME/fim
        $CMD >/dev/null 2>&1
        touch $HOME/fim
    ) >/dev/null 2>&1 &
    
    PID=$! # Ambil Process ID
    
    tput civis # Sembunyikan kursor
    
    # Loop animasi selama proses berjalan
    while [ -d /proc/$PID ]; do
        # Frame 1
        echo -ne "\r${CYAN} [${ORANGE}●${WHITE}•••••••••${CYAN}] ${PURPLE}Downloading Data...${NC}"
        sleep 0.2
        # Frame 2
        echo -ne "\r${CYAN} [${ORANGE}••${WHITE}••••••••${CYAN}] ${PURPLE}Verifying Files... ${NC}"
        sleep 0.2
        # Frame 3
        echo -ne "\r${CYAN} [${ORANGE}••••${WHITE}••••••${CYAN}] ${PURPLE}Unpacking Data...  ${NC}"
        sleep 0.2
        # Frame 4
        echo -ne "\r${CYAN} [${ORANGE}••••••${WHITE}••••${CYAN}] ${PURPLE}Configuring...     ${NC}"
        sleep 0.2
        # Frame 5
        echo -ne "\r${CYAN} [${ORANGE}••••••••${WHITE}••${CYAN}] ${PURPLE}Setting Cronjob... ${NC}"
        sleep 0.2
        # Frame 6
        echo -ne "\r${CYAN} [${ORANGE}••••••••••${CYAN}] ${PURPLE}Finalizing...      ${NC}"
        sleep 0.2
        
        # Cek jika proses selesai via file flag
        if [[ -e $HOME/fim ]]; then
            rm $HOME/fim
            break
        fi
    done
    
    # Tampilan Sukses
    echo -ne "\r${CYAN} [${GREEN}██████████${CYAN}] ${GREEN}${BOLD}UPDATE SUCCESS!    ${NC}\n"
    tput cnorm # Tampilkan kursor kembali
}

# ==================================================
# LOGIKA UPDATE (Script Asli Anda + Cron XP Baru)
# ==================================================
run_update() {
    # 1. Download & Install FV Tunnel
    wget -qO- fv-tunnel "https://raw.githubusercontent.com/hokagelegend9999/alpha.v2/refs/heads/main/config/fv-tunnel" 
    chmod +x fv-tunnel 
    bash fv-tunnel
    rm -rf fv-tunnel
    
    # 2. Bersihkan Folder sbin
    rm -rf /usr/local/sbin/*
    
    # 3. Download & Ekstrak Menu
    wget https://github.com/hokagelegend9999/alpha.v2/raw/refs/heads/main/menu/menu.zip
    unzip -o menu.zip > /dev/null 2>&1
    chmod +x menu/*
    mv menu/* /usr/local/sbin/
    rm -rf menu
    rm -rf menu.zip
    
    # 4. Download Menu Utama
    wget -q -O /usr/local/sbin/menu https://raw.githubusercontent.com/hokagelegend9999/alpha.v2/refs/heads/main/menu/menu
    chmod +x /usr/local/sbin/menu
    
    # 5. Buat Folder Usage (ZIVPN Dihapus)
    mkdir -p /etc/ssh/usage_db
    chmod 777 /etc/ssh/usage_db
    
    # 6. FIX PERMISSIONS
    sed -i 's/\r$//' /usr/local/sbin/*
    chmod +x /usr/local/sbin/*
    dos2unix /usr/local/sbin/m-vless
    dos2unix /usr/local/sbin/datauser-vless
    dos2unix /usr/local/sbin/delexp

    # ======================================================
    # NEW: CREATE REKAM USAGE DAEMON
    # ======================================================
    cat >/usr/local/sbin/rekam-usage <<-'EOF'
#!/bin/bash
# ==========================================
# AUTO ACCOUNTING & BANDWIDTH TRACKER
# Menabung Kuota Tanpa Reset
# ==========================================
USAGE_DB="/etc/ssh/usage_db"
mkdir -p "$USAGE_DB"

# Ambil total byte langsung dari Iptables Kernel
IPTABLES_DUMP=$(iptables-save -c 2>/dev/null)

# Loop ke semua user VPN
awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd | while read user; do
    
    # 1. Baca byte real-time dari iptables saat ini
    live_bytes=$(echo "$IPTABLES_DUMP" | grep -w "uid-owner $user" | sed -n 's/^\[[0-9]*:\([0-9]*\)\].*/\1/p' | awk '{sum+=$1} END {print sum}')
    [[ -z "$live_bytes" ]] && live_bytes=0

    db_file="$USAGE_DB/$user.total"
    last_file="$USAGE_DB/$user.last"

    total_tabungan=0
    last_recorded=0

    [[ -f "$db_file" ]] && total_tabungan=$(cat "$db_file")
    [[ -f "$last_file" ]] && last_recorded=$(cat "$last_file")

    # 2. LOGIKA PENABUNGAN CERDAS
    if (( live_bytes >= last_recorded )); then
        # Jika user masih konek, tambahkan hanya selisihnya
        diff=$((live_bytes - last_recorded))
        total_tabungan=$((total_tabungan + diff))
    else
        # Jika live_bytes lebih kecil, berarti server habis REBOOT atau iptables reset
        # Kita tambahkan utuh live_bytes yang baru ke dalam tabungan
        total_tabungan=$((total_tabungan + live_bytes))
    fi

    # 3. Simpan permanen ke database
    echo "$total_tabungan" > "$db_file"
    echo "$live_bytes" > "$last_file"

done
EOF
    chmod +x /usr/local/sbin/rekam-usage
    dos2unix /usr/local/sbin/rekam-usage > /dev/null 2>&1

    # 7. CREATE BOT NOTIFIER EXPIRED SCRIPT DI SBIN
    cat >/usr/local/sbin/expired-notifier <<-'EOF'
#!/bin/bash
# ======================================================
# HOKAGE LEGEND: AUTOMATED EXPIRED USER NOTIFIER
# SUPPORT: SSH, VMESS, VLESS & TROJAN (XRAY)
# ======================================================

if [ -f "/usr/bin/kyt/var.txt" ]; then
    source /usr/bin/kyt/var.txt
else
    echo "Error: File /usr/bin/kyt/var.txt tidak ditemukan!"
    exit 1
fi

CHAT_ID="$ADMIN"
domain=$(cat /etc/xray/domain 2>/dev/null || echo "$DOMAIN")
IP=$(curl -sS ipv4.icanhazip.com 2>/dev/null || echo "Unknown IP")

TEXT="⚠️ *HOKAGE LEGEND: LAPORAN USER EXPIRED* ⚠️%0A"
TEXT+="━━━━━━━━━━━━━━━━━━━━━━━━━━━━%0A"
TEXT+="👉 *Domain:* \`$domain\`%0A"
TEXT+="👉 *IP Server:* \`$IP\`%0A"
TEXT+="━━━━━━━━━━━━━━━━━━━━━━━━━━━━%0A%0A"

count=0
expired_list=""

# ======================================================
# 1. PENGECEKAN EXPIRED USER SSH
# ======================================================
while IFS=: read -r username _ uid _ _ _ shell; do
    if [[ "$uid" -ge 1000 && "$username" != "nobody" ]]; then
        exp_str=$(chage -l "$username" | grep "Account expires" | cut -d: -f2)
        if [[ "$exp_str" != *"never"* ]]; then 
            exp_date=$(date -d "$exp_str" +%s 2>/dev/null)
            if [ ! -z "$exp_date" ]; then
                today=$(date +%s)
                diff=$(( (exp_date - today) / 86400 ))
                if [[ $diff -lt 0 ]]; then
                    exp_date_fmt=$(date -d "$exp_str" +"%d %b, %Y" 2>/dev/null)
                    expired_list+="👤 *SSH:* \`$username\`%0A📅 *Expired:* $exp_date_fmt%0A--------------------------------%0A"
                    count=$((count+1))
                fi
            fi
        fi
    fi
done < /etc/passwd

# ======================================================
# 2. PENGECEKAN EXPIRED USER VMESS (XRAY)
# ======================================================
if [ -f "/etc/xray/config.json" ]; then
    vmess_data=( $(grep '^###' /etc/xray/config.json | cut -d ' ' -f 2 | sort | uniq) )
    for user in "${vmess_data[@]}"; do
        exp_date_str=$(grep -wE "^### $user" "/etc/xray/config.json" | cut -d ' ' -f 3 | sort | uniq | head -1)
        if [[ $exp_date_str =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
            d1=$(date -d "$exp_date_str" +%s 2>/dev/null)
            d2=$(date -d "$(date +%Y-%m-%d)" +%s)
            if [ ! -z "$d1" ]; then
                diff=$(( (d1 - d2) / 86400 ))
                if [[ "$diff" -lt 0 ]]; then
                    exp_date_fmt=$(date -d "$exp_date_str" +"%d %b, %Y" 2>/dev/null)
                    expired_list+="👤 *VMESS:* \`$user\`%0A📅 *Expired:* $exp_date_fmt%0A--------------------------------%0A"
                    count=$((count+1))
                fi
            fi
        fi
    done
fi

# ======================================================
# 3. PENGECEKAN EXPIRED USER VLESS (XRAY)
# ======================================================
if [ -f "/etc/xray/config.json" ]; then
    vless_data=( $(grep '^#&' /etc/xray/config.json | cut -d ' ' -f 2 | sort | uniq) )
    for user in "${vless_data[@]}"; do
        exp_date_str=$(grep -wE "^#& $user" "/etc/xray/config.json" | cut -d ' ' -f 3 | sort | uniq | head -1)
        if [[ $exp_date_str =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
            d1=$(date -d "$exp_date_str" +%s 2>/dev/null)
            d2=$(date -d "$(date +%Y-%m-%d)" +%s)
            if [ ! -z "$d1" ]; then
                diff=$(( (d1 - d2) / 86400 ))
                if [[ "$diff" -lt 0 ]]; then
                    exp_date_fmt=$(date -d "$exp_date_str" +"%d %b, %Y" 2>/dev/null)
                    expired_list+="👤 *VLESS:* \`$user\`%0A📅 *Expired:* $exp_date_fmt%0A--------------------------------%0A"
                    count=$((count+1))
                fi
            fi
        fi
    done
fi

# ======================================================
# 4. PENGECEKAN EXPIRED USER TROJAN (XRAY)
# ======================================================
if [ -f "/etc/xray/config.json" ]; then
    trojan_data=( $(grep '^#!' /etc/xray/config.json | cut -d ' ' -f 2 | sort | uniq) )
    for user in "${trojan_data[@]}"; do
        exp_date_str=$(grep -wE "^#! $user" "/etc/xray/config.json" | cut -d ' ' -f 3 | sort | uniq | head -1)
        if [[ $exp_date_str =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
            d1=$(date -d "$exp_date_str" +%s 2>/dev/null)
            d2=$(date -d "$(date +%Y-%m-%d)" +%s)
            if [ ! -z "$d1" ]; then
                diff=$(( (d1 - d2) / 86400 ))
                if [[ "$diff" -lt 0 ]]; then
                    exp_date_fmt=$(date -d "$exp_date_str" +"%d %b, %Y" 2>/dev/null)
                    expired_list+="👤 *TROJAN:* \`$user\`%0A📅 *Expired:* $exp_date_fmt%0A--------------------------------%0A"
                    count=$((count+1))
                fi
            fi
        fi
    done
fi

# ======================================================
# 5. PROSES PENGIRIMAN NOTIFIKASI
# ======================================================
if [ $count -gt 0 ]; then
    TEXT+="$expired_list"
    TEXT+="*Total Terdeteksi:* $count User Expired.%0A"
    TEXT+=" Silakan lakukan pembersihan akun segera."
    
    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
        -d "chat_id=$CHAT_ID" \
        -d "text=$TEXT" \
        -d "parse_mode=Markdown" > /dev/null
fi
EOF
    chmod +x /usr/local/sbin/expired-notifier
    dos2unix /usr/local/sbin/expired-notifier > /dev/null 2>&1

    # ======================================================
    # 8. CREATE AUTO DELETE TROJAN SCRIPT (CLI VERSION)
    # ======================================================
    cat >/usr/local/sbin/xp-trojan <<-'EOF'
#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
BACKUP_FILE="/etc/xray/trojan_backup"
[[ ! -f "$BACKUP_FILE" ]] && touch "$BACKUP_FILE"

data=( $(grep '^#!' /etc/xray/config.json | cut -d ' ' -f 2 | sort | uniq) )
now=$(date +"%Y-%m-%d")
found=0

for user in "${data[@]}"; do
    exp=$(grep -w "^#! $user" "/etc/xray/config.json" | cut -d ' ' -f 3 | sort | uniq | head -1)
    if [[ -z "$exp" ]]; then continue; fi

    d1=$(date -d "$exp" +%s 2>/dev/null)
    d2=$(date -d "$now" +%s)
    
    if [[ "$d1" -lt "$d2" ]]; then
        pass_tr=$(grep -wE "^#! $user" -A 3 /etc/xray/config.json | grep "password" | awk -F '"' '{print $4}' | head -n 1)
        if [[ -n "$pass_tr" ]]; then
            if ! grep -q "^$user " "$BACKUP_FILE"; then
                echo "$user $pass_tr" >> "$BACKUP_FILE"
            fi
        fi

        user_safe=$(echo "$user" | sed 's/\//\\\//g')
        sed -i "/^#! $user_safe /,/^},{/d" /etc/xray/config.json
        
        sed -i "/\b$user\b/d" /etc/trojan/.trojan.db 2>/dev/null
        rm -f "/etc/trojan/$user" 2>/dev/null
        rm -f "/etc/hokage/limit/trojan/ip/$user" 2>/dev/null
        rm -f "/var/www/html/trojan-$user.txt" 2>/dev/null
        
        echo "Expired- Trojan Username : $user - Exp: $exp - Dihapus: $now" >> /usr/local/bin/deleteduser
        found=1
    fi
done

if [[ $found -eq 1 ]]; then
    systemctl restart xray 2>/dev/null
fi
EOF
    chmod +x /usr/local/sbin/xp-trojan
    dos2unix /usr/local/sbin/xp-trojan > /dev/null 2>&1

    # ------------------------------------------
    # SETTING CRON JOB (XP UPDATE TERBARU)
    # ------------------------------------------

    # A. SSH ACCOUNTANT
    cat >/etc/cron.d/ssh_accountant <<-END
    SHELL=/bin/sh
    PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
    * * * * * root /usr/local/sbin/ssh-accountant
END

    # B. LIMIT QUOTA
    rm -f /etc/cron.d/limit_quota
    sed -i "/limit-quota/d" /etc/crontab
    cat >/etc/cron.d/limit_quota <<-EOF
    SHELL=/bin/sh
    PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
    */10 * * * * root /usr/local/sbin/limit-quota
EOF

    # C. XP GENERAL (AUTO DELETE)
    cat >/etc/cron.d/xp_all <<-END
    SHELL=/bin/sh
    PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
    10 0 * * * root /usr/local/sbin/xp
END

    # D. BOT EXPIRED NOTIFIER TELEGRAM (Tetap jam 00:00 agar laporan valid)
    cat >/etc/cron.d/expired_notifier <<-END
    SHELL=/bin/sh
    PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
    0 0 * * * root /usr/local/sbin/expired-notifier
END

    # E. LIMIT IP SSH (BOT NOTIFIER MULTI-LOGIN) - NEW
    cat >/etc/cron.d/limit_ip_ssh <<-END
    SHELL=/bin/sh
    PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
    */5 * * * * root /usr/local/sbin/limit-ip-ssh
END

    # F. DELEXP (AUTO DELETE EXPIRED) - Jeda 10 Menit
    cat >/etc/cron.d/delexp <<-END
    SHELL=/bin/sh
    PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
    10 0 * * * root /usr/local/sbin/delexp
END

    # G. REKAM USAGE DAEMON (PENABUNG KUOTA)
    cat >/etc/cron.d/rekam_usage <<-END
    SHELL=/bin/sh
    PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
    * * * * * root /usr/local/sbin/rekam-usage >/dev/null 2>&1
END

    # H. AUTO DELETE TROJAN (Baru Ditambahkan)
    cat >/etc/cron.d/xp_trojan_auto <<-END
    SHELL=/bin/sh
    PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
    10 0 * * * root /usr/local/sbin/xp-trojan
END

    # Restart Cron
    service cron restart
}

# ==================================================
# EKSEKUSI UTAMA
# ==================================================
rm -rf update.sh
clear
echo -e ""
print_gradient "╭══════════════════════════════════════════╮"
print_gradient "│      HOKAGE LEGEND SYSTEM UPDATER        │"
print_gradient "╰══════════════════════════════════════════╯"
echo -e ""
echo -e "  ${ORANGE}Please wait while we update your resources...${NC}"
echo -e ""

# Jalankan Animasi Update
hokage_anim 'run_update'

echo -e ""
print_gradient "╭══════════════════════════════════════════╮"
print_gradient "│          UPDATE COMPLETED !!             │"
print_gradient "╰══════════════════════════════════════════╯"
echo -e ""
read -n 1 -s -r -p " Press [ Enter ] to back to menu"
menu
