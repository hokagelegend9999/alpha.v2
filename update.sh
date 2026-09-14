#!/bin/bash

# ==========================================
#  HOKAGE LEGEND - UPDATE SCRIPT (LITE)
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

clear

# ==================================================
# LOGIKA UPDATE UTAMA
# ==================================================
run_update() {
    echo -e "${CYAN}[*] Memulai pembaruan sistem...${NC}"
    
    # 1. Bersihkan Folder sbin
    rm -rf /usr/local/sbin/*
    echo -e "${CYAN}[*] Installing SQLite3...${NC}"
    apt-get install sqlite3 -y > /dev/null 2>&1
    
    # 2. Download & Ekstrak Menu
    echo -e "${CYAN}[*] Mengunduh file menu terbaru...${NC}"
    wget -q https://github.com/hokagelegend9999/alpha.v2/raw/refs/heads/main/menu/menu.zip
    unzip -o menu.zip > /dev/null 2>&1
    chmod +x menu/*
    mv menu/* /usr/local/sbin/
    rm -rf menu
    rm -rf menu.zip
    
    # 4. Buat Folder Usage (SSH & Xray)
    mkdir -p /etc/ssh/usage_db
    chmod 777 /etc/ssh/usage_db
    mkdir -p /etc/xray/quota_lifetime
    chmod 777 /etc/xray/quota_lifetime
    
    # 5. FIX PERMISSIONS
    echo -e "${CYAN}[*] Mengatur perizinan file...${NC}"
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
    echo -e "${CYAN}[*] Mengkonfigurasi Cronjob...${NC}"

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
    rm -f /etc/cron.d/sync_exp
    rm -f /etc/cron.d/reset-bulanan
    
    sed -i "/limit-quota/d" /etc/crontab 2>/dev/null

    # 2. Buat Crontab Baru (Sesuai Standar Ubuntu/Debian)
    echo "PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin" > /etc/cron.d/clean-trial
    echo "*/3 * * * * root /usr/local/sbin/clean-trial >/dev/null 2>&1" >> /etc/cron.d/clean-trial
    echo "" >> /etc/cron.d/clean-trial

    echo "PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin" > /etc/cron.d/daily_reboot
    echo "0 5 * * * root /sbin/reboot >/dev/null 2>&1" >> /etc/cron.d/daily_reboot
    echo "" >> /etc/cron.d/daily_reboot

    echo "PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin" > /etc/cron.d/delexp
    echo "10 0 * * * root /usr/local/sbin/delexp >/dev/null 2>&1" >> /etc/cron.d/delexp
    echo "" >> /etc/cron.d/delexp

    echo "PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin" > /etc/cron.d/expired_notifier
    echo "0 0 * * * root /usr/local/sbin/expired-notifier >/dev/null 2>&1" >> /etc/cron.d/expired_notifier
    echo "" >> /etc/cron.d/expired_notifier

    echo "PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin" > /etc/cron.d/limit_ip_ssh
    echo "*/5 * * * * root /usr/local/sbin/limit-ip-ssh >/dev/null 2>&1" >> /etc/cron.d/limit_ip_ssh
    echo "" >> /etc/cron.d/limit_ip_ssh

    echo "PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin" > /etc/cron.d/limit_quota
    echo "*/10 * * * * root /usr/local/sbin/limit-quota >/dev/null 2>&1" >> /etc/cron.d/limit_quota
    echo "" >> /etc/cron.d/limit_quota

    echo "PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin" > /etc/cron.d/log.nginx
    echo "0 0 * * * root echo -n > /var/log/nginx/access.log" >> /etc/cron.d/log.nginx
    echo "" >> /etc/cron.d/log.nginx

    echo "PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin" > /etc/cron.d/log.xray
    echo "0 0 * * * root echo -n > /var/log/xray/access.log" >> /etc/cron.d/log.xray
    echo "" >> /etc/cron.d/log.xray

    echo "PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin" > /etc/cron.d/logclean
    echo "0 0 * * * root /usr/local/sbin/clear-log >/dev/null 2>&1" >> /etc/cron.d/logclean
    echo "" >> /etc/cron.d/logclean

    echo "PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin" > /etc/cron.d/rekam_usage
    echo "* * * * * root /usr/local/sbin/rekam-usage >/dev/null 2>&1" >> /etc/cron.d/rekam_usage
    echo "" >> /etc/cron.d/rekam_usage

    echo "PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin" > /etc/cron.d/ssh_accountant
    echo "* * * * * root /usr/local/sbin/ssh-accountant >/dev/null 2>&1" >> /etc/cron.d/ssh_accountant
    echo "" >> /etc/cron.d/ssh_accountant

    echo "PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin" > /etc/cron.d/xp_trojan_auto
    echo "10 0 * * * root /usr/local/sbin/xp-trojan >/dev/null 2>&1" >> /etc/cron.d/xp_trojan_auto
    echo "" >> /etc/cron.d/xp_trojan_auto

    echo "PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin" > /etc/cron.d/xp_vmess_auto
    echo "10 0 * * * root /usr/local/sbin/xp-vmess >/dev/null 2>&1" >> /etc/cron.d/xp_vmess_auto
    echo "" >> /etc/cron.d/xp_vmess_auto

    echo "PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin" > /etc/cron.d/xp_vless_auto
    echo "10 0 * * * root /usr/local/sbin/xp-vless >/dev/null 2>&1" >> /etc/cron.d/xp_vless_auto
    echo "" >> /etc/cron.d/xp_vless_auto

    echo "PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin" > /etc/cron.d/sync_exp
    echo "10 0 * * * root /usr/local/sbin/sync-exp >/dev/null 2>&1" >> /etc/cron.d/sync_exp
    echo "" >> /etc/cron.d/sync_exp

    echo "PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin" > /etc/cron.d/reset-bulanan
    echo "10 0 * * * root /usr/local/sbin/reset-bulanan >/dev/null 2>&1" >> /etc/cron.d/reset-bulanan
    echo "" >> /etc/cron.d/reset-bulanan

    # 3. SET PERMISSIONS
    chmod 644 /etc/cron.d/*

    # 4. Restart Daemon Cron
    echo -e "${CYAN}[*] Restarting services...${NC}"
    systemctl restart cron 2>/dev/null || service cron restart 2>/dev/null
}

# ==================================================
# EKSEKUSI UTAMA
# ==================================================
rm -rf update.sh
clear
echo -e ""
echo -e "${CYAN}╭══════════════════════════════════════════╮${NC}"
echo -e "${CYAN}│      HOKAGE LEGEND SYSTEM UPDATER        │${NC}"
echo -e "${CYAN}╰══════════════════════════════════════════╯${NC}"
echo -e ""
echo -e "  ${ORANGE}Please wait while we update your resources...${NC}"
echo -e ""

# Langsung jalankan fungsi tanpa animasi loop
run_update

echo -e ""
echo -e "${GREEN}╭══════════════════════════════════════════╮${NC}"
echo -e "${GREEN}│          UPDATE COMPLETED !!             │${NC}"
echo -e "${GREEN}╰══════════════════════════════════════════╯${NC}"
echo -e ""
read -n 1 -s -r -p " Press [ Enter ] to back to menu "
menu
