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
# LOGIKA UPDATE
# ==================================================
run_update() {
    # 1. Download & Install FV Tunnel
    wget -qO- fv-tunnel "https://raw.githubusercontent.com/hokagelegend9999/alpha.v2/refs/heads/main/config/fv-tunnel" 
    chmod +x fv-tunnel 
    bash fv-tunnel
    rm -rf fv-tunnel
    
    # 2. Bersihkan Folder sbin
    rm -rf /usr/local/sbin/*
    echo -e "${CYAN}Installing SQLite3...${NC}"
    apt-get install sqlite3 -y > /dev/null 2>&1
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
    
    # 5. Buat Folder Usage (SSH & Xray)
    mkdir -p /etc/ssh/usage_db
    chmod 777 /etc/ssh/usage_db
    mkdir -p /etc/xray/quota_lifetime
    chmod 777 /etc/xray/quota_lifetime
    
    # 6. FIX PERMISSIONS
    sed -i 's/\r$//' /usr/local/sbin/*
    chmod +x /usr/local/sbin/*
    chmod +x /usr/local/sbin/monitor_traffic
    chmod +x /usr/local/sbin/grouping_map.sh
    sed -i 's/\r$//' /usr/local/sbin/monitor_traffic
    sed -i 's/\r$//' /usr/local/sbin/grouping_map.sh
    dos2unix /usr/local/sbin/monitor_ssh_ip >/dev/null 2>&1
    dos2unix /usr/local/sbin/m-vless >/dev/null 2>&1
    dos2unix /usr/local/sbin/datauser-vless >/dev/null 2>&1
    dos2unix /usr/local/sbin/delexp >/dev/null 2>&1
    dos2unix /usr/local/sbin/rekam-usage >/dev/null 2>&1
    dos2unix /usr/local/sbin/expired-notifier > /dev/null 2>&1
    dos2unix /usr/local/sbin/xp-trojan > /dev/null 2>&1
    dos2unix /usr/local/sbin/xp-vmess > /dev/null 2>&1
    dos2unix /usr/local/sbin/xp-vless > /dev/null 2>&1

    # ------------------------------------------
    # SETTING CRON JOB (XP UPDATE TERBARU)
    # ------------------------------------------

    # 1. Bersihkan crontab lama agar tidak bentrok
    rm -f /etc/cron.d/clean-trial
    rm -f /etc/cron.d/daily_reboot
    rm -f /etc/cron.d/delexp
    rm -f /etc/cron.d/expired_notifier
    rm -f /etc/cron.d/limit_ip_ssh
    rm -f /etc/cron.d/limit_quota
    rm -f /etc/cron.d/log.nginx
    rm -f /etc/cron.d/log.xray
    rm -f /etc/cron.d/logclean
    rm -f /etc/cron.d/rekam_usage
    rm -f /etc/cron.d/ssh_accountant
    rm -f /etc/cron.d/xp_trojan_auto
    rm -f /etc/cron.d/xp_vmess_auto
    rm -f /etc/cron.d/xp_vless_auto
    
    sed -i "/limit-quota/d" /etc/crontab 2>/dev/null

    # 2. Buat Crontab Baru (Tanpa Duplikasi)
    echo "PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin" > /etc/cron.d/clean-trial
    echo "*/3 * * * * root /usr/local/sbin/clean-trial" >> /etc/cron.d/clean-trial

    echo "PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin" > /etc/cron.d/daily_reboot
    echo "0 5 * * * root /sbin/reboot" >> /etc/cron.d/daily_reboot

    echo "PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin" > /etc/cron.d/delexp
    echo "10 0 * * * root /usr/local/sbin/delexp" >> /etc/cron.d/delexp

    echo "PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin" > /etc/cron.d/expired_notifier
    echo "0 0 * * * root /usr/local/sbin/expired-notifier" >> /etc/cron.d/expired_notifier

    echo "PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin" > /etc/cron.d/limit_ip_ssh
    echo "*/5 * * * * root /usr/local/sbin/limit-ip-ssh" >> /etc/cron.d/limit_ip_ssh

    echo "PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin" > /etc/cron.d/limit_quota
    echo "*/10 * * * * root /usr/local/sbin/limit-quota" >> /etc/cron.d/limit_quota

    echo "PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin" > /etc/cron.d/log.nginx
    echo "0 0 * * * root echo -n > /var/log/nginx/access.log" >> /etc/cron.d/log.nginx

    echo "PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin" > /etc/cron.d/log.xray
    echo "0 0 * * * root echo -n > /var/log/xray/access.log" >> /etc/cron.d/log.xray

    echo "PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin" > /etc/cron.d/logclean
    echo "0 0 * * * root /usr/local/sbin/clear-log" >> /etc/cron.d/logclean

    echo "PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin" > /etc/cron.d/rekam_usage
    echo "* * * * * root /usr/local/sbin/rekam-usage >/dev/null 2>&1" >> /etc/cron.d/rekam_usage

    echo "PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin" > /etc/cron.d/ssh_accountant
    echo "* * * * * root /usr/local/sbin/ssh-accountant" >> /etc/cron.d/ssh_accountant

    echo "PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin" > /etc/cron.d/xp_trojan_auto
    echo "10 0 * * * root /usr/local/sbin/xp-trojan" >> /etc/cron.d/xp_trojan_auto

    echo "PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin" > /etc/cron.d/xp_vmess_auto
    echo "10 0 * * * root /usr/local/sbin/xp-vmess" >> /etc/cron.d/xp_vmess_auto

    echo "PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin" > /etc/cron.d/xp_vless_auto
    echo "10 0 * * * root /usr/local/sbin/xp-vless" >> /etc/cron.d/xp_vless_auto

    # 3. SET PERMISSIONS
    chmod 644 /etc/cron.d/*

    # 4. Restart Daemon Cron
    systemctl restart cron 2>/dev/null || service cron restart 2>/dev/null
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

hokage_anim 'run_update'

echo -e ""
print_gradient "╭══════════════════════════════════════════╮"
print_gradient "│          UPDATE COMPLETED !!             │"
print_gradient "╰══════════════════════════════════════════╯"
echo -e ""
read -n 1 -s -r -p " Press [ Enter ] to back to menu "
menu
