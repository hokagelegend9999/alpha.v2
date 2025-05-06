
## 🚀 TAMPILAN MENU

Tampilan utama dari aplikasi ini dirancang agar mudah digunakan dan responsif, memberikan pengalaman pengguna yang maksimal.

<p align="center">
  <img src="https://github.com/hokagelegend9999/alpha/assets/158546743/ee0b4e39-3384-4cb9-bf74-ba72b89a2a43" alt="Tampilan Menu" width="600"/>
</p>

---

## 💾 BACKUP DATA VPS

Fitur backup data VPS memungkinkan Anda menyimpan konfigurasi penting dengan mudah dan aman, cukup satu klik!

<p align="center">
  <img src="https://github.com/hokagelegend9999/alpha/blob/main/1.png?raw=true" alt="Backup Data VPS" width="400"/>
 <img src="https://github.com/hokagelegend9999/alpha/blob/main/2.png?raw=true" alt="Backup Data VPS" width="400"/>
 <img src="https://github.com/hokagelegend9999/alpha.v2/blob/main/Screenshot%202025-04-23%20153225.png?raw=true alt="Backup Data VPS" width="400"/>
</p>



### INSTALL SCRIPT 
```
apt install -y && apt update -y && apt upgrade -y && wget -q https://raw.githubusercontent.com/hokagelegend9999/alpha.v2/refs/heads/main/premi.sh && chmod +x premi.sh && ./premi.sh
```

## UPDATE SCRIPT
```
wget -q https://raw.githubusercontent.com/hokagelegend9999/alpha.v2/refs/heads/main/update.sh && chmod +x update.sh && ./update.sh
```

### SUPPORT OS LINUX
- UBUNTU 20.04.05
- DEBIAN 10

### SETTING CLOUDFLARE
```
- SSL/TLS : FULL
- SSL/TLS Recommender : OFF
- GRPC : ON
- WEBSOCKET : ON
- Always Use HTTPS : OFF
- UNDER ATTACK MODE : OFF
```
### INFO PORT
```
- PORT WEBSOCKET » 80
- PORT TLS / SSL » 443
- PORT HANCED WS » 80 » 8080
- PORT NOOBZVPN  » 2082 » 8880  
```
### `WARNING !`
```
Jika Mendapatkan Status Service Off
Silahkan Restart Service.
Jika Statsus Service Masih Off
Silahkan Reboot vps kalian
```


- Langkah 1: 
Membuat Bot di Telegram
Buka Telegram dan Cari BotFather:

Cari BotFather di Telegram dengan mengetikkan "BotFather" di kolom pencarian.
Pilih BotFather (akun resmi dengan tanda centang biru).
Membuat Bot Baru:
![Screenshot 2024-06-04 115130](https://github.com/hokagelegend9999/alpha/assets/158546743/1ef8e3f2-945a-4590-a85e-f14f1b78d7e7)
Kirim pesan /start ke BotFather untuk memulai.
Kirim pesan /newbot untuk membuat bot baru.
Ikuti instruksi untuk memberikan nama dan username untuk bot Anda.
Setelah selesai, BotFather akan memberikan token API bot. Simpan token ini karena akan digunakan dalam skrip Anda.


- Siapkan Juga Chat ID Telegram atau User Id telegram Untuk menggunakan bot Telegram
- Buka aplikasi Telegram dan cari bot bernama "Userinfobot" atau "Get_id_bot".
- 
  ![Screenshot 2024-06-05 082241](https://github.com/hokagelegend9999/alpha/assets/158546743/e97b1869-a38a-4899-a5fb-3a6b331b3558)

Klik "Start" untuk memulai bot.
Bot akan secara otomatis mengirimkan pesan berisi chat ID kamu.




### mendapatkan akses root ke vps mu

``````

  wget -qO- -O aksesroot.sh https://raw.githubusercontent.com/hokagelegend9999/alpha.v2/refs/heads/main/aksesroot.sh && bash aksesroot.sh

```````


#### install debian 11

````
apt update -y && apt install wget -y
wget https://raw.githubusercontent.com/hokagelegend9999/alpha.v2/refs/heads/main/premi_fixed_debian11.sh
chmod +x premi_fixed_debian11.sh
./premi_fixed_debian11.sh

```



#### INSTALL ULANG VPS UBUNTU DEBIAN

```
curl -O https://raw.githubusercontent.com/hokagelegend9999/alpha.v2/refs/heads/main/reinstall.sh
chmod +x reinstall.sh
bash reinstall.sh debian 11 --password PASSWORD_KAMU

```
INSTALL HAPROXY DEBIAN 11

sudo apt install -t bullseye-backports haproxy
sed -i "s#xxx#https://raw.githubusercontent.com/hokagelegend9999/alpha.v2/refs/heads/main/#g" /etc/haproxy/haproxy.cfg
sudo systemctl restart haproxy
sudo systemctl status haproxy
