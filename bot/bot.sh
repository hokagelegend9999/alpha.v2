#!/bin/bash
NS=$( cat /etc/xray/dns )
PUB=$( cat /etc/slowdns/server.pub )
domain=$(cat /etc/xray/domain)
#color
grenbo="\e[92;1m"
NC='\e[0m'

#install packages
echo -e "${grenbo}Installing Dependencies...${NC}"
apt update && apt upgrade -y

# --- TAMBAHAN UNTUK ATD (TRIAL VLESS) ---
# Menambahkan 'at' pada list instalasi
apt install python3 python3-pip git at -y

# Memastikan layanan 'atd' berjalan dan otomatis menyala saat server reboot
echo -e "${grenbo}Enabling atd service for auto-kill...${NC}"
systemctl enable atd
systemctl restart atd
# ----------------------------------------

# Bersihkan speedtest lama jika ada (biar tidak bentrok)
apt-get remove speedtest-cli -y > /dev/null 2>&1

cd /usr/bin
wget https://raw.githubusercontent.com/hokagelegend9999/alpha.v2/refs/heads/main/bot/bot.zip
unzip bot.zip
mv bot/* /usr/bin
chmod +x /usr/bin/*
rm -rf bot.zip
clear

wget https://raw.githubusercontent.com/hokagelegend9999/alpha.v2/refs/heads/main/bot/kyt.zip
unzip kyt.zip

# --- UPDATE PENTING DISINI ---
# Install modules bawaan
pip3 install -r kyt/requirements.txt
# Install module Speedtest Python (Wajib untuk fitur speedtest baru)
pip3 install speedtest-cli requests

chmod +x /usr/bin/kyt/shell/bot/*

clear
echo ""
echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e " \e[1;97;101m           ADD BOT PANEL           \e[0m"
echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "${grenbo}Tutorial Creat Bot and ID Telegram${NC}"
echo -e "${grenbo}[*] Creat Bot and Token Bot : @BotFather${NC}"
echo -e "${grenbo}[*] Info Id Telegram : @MissRose_bot , perintah /info${NC}"
echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
read -e -p "[*] Input your Bot Token : " bottoken
read -e -p "[*] Input Your Id Telegram : " admin
echo -e BOT_TOKEN='"'$bottoken'"' >> /usr/bin/kyt/var.txt
echo -e ADMIN='"'$admin'"' >> /usr/bin/kyt/var.txt
echo -e DOMAIN='"'$domain'"' >> /usr/bin/kyt/var.txt
echo -e PUB='"'$PUB'"' >> /usr/bin/kyt/var.txt
echo -e HOST='"'$NS'"' >> /usr/bin/kyt/var.txt
clear

cat > /etc/systemd/system/kyt.service << END
[Unit]
Description=Simple kyt - @kyt
After=network.target

[Service]
WorkingDirectory=/usr/bin
ExecStart=/usr/bin/python3 -m kyt
Restart=always

[Install]
WantedBy=multi-user.target
END

systemctl start kyt 
systemctl enable kyt
systemctl restart kyt
cd /root
rm -rf bot.sh
echo "Done"
echo "Your Data Bot"
echo -e "==============================="
echo "Token Bot         : $bottoken"
echo "Admin          : $admin"
echo "Domain        : $domain"
echo "Pub            : $PUB"
echo "Host           : $NS"
echo -e "==============================="
echo "Setting done"
sleep 2
clear

echo " Installations complete, type /menu on your bot"
