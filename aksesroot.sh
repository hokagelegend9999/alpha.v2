#!/bin/bash
# xixi
# echo "$crot    ALL=(ALL:ALL) ALL" >> /etc/sudoers;
wget -q -O /etc/ssh/sshd_config https://raw.githubusercontent.com/hokagelegend9999/alpha.v2/refs/heads/main/sshd_config;
systemctl restart sshd;
clear;
echo -e "Masukkan Password:";
read -e pwe;
usermod -p "$(perl -e "print crypt('$pwe', 'Q4')")" root;
clear;
printf "Mohon Simpan Informasi Akun VPS Ini
============================================
Akun Root (Akun Utama)
Ip address = $(curl -Ls http://ipinfo.io/ip)
Username   = root
Password   = $pwe
============================================
"
echo "";
exit;
