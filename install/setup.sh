#!/bin/bash
# ==========================================================
# TheTechSavage Independent OpenVPN Master Installer
# ==========================================================

# 1. DEFINE YOUR INDEPENDENT VAULT
REPO_BASE="https://raw.githubusercontent.com/TheTechSavant/TheTechSavage_OpenVPN_Master/main"

# 2. LICENSE CHECK
MYIP=$(curl -sS -4 ifconfig.me)
API_URL="https://file2link.thetechsavage.org.ng/api/check_ip?ip=$MYIP"
RESPONSE=$(curl -s -m 10 "$API_URL")

if [[ ! "$RESPONSE" =~ "valid" ]]; then
    echo "LICENSE ERROR: Access Denied. Contact Admin."
    exit 1
fi

clear
echo "Initializing System Architecture..."
mkdir -p /etc/xray /etc/openvpn /usr/local/etc/openvpn /var/log/xray

# Added nginx to serve the universal file
apt update && apt install -y openvpn easy-rsa iptables-persistent unzip wget curl vnstat nginx

# 3. RUN THE OPENVPN ENGINE
echo "=========================================================="
echo " Starting OpenVPN Core Configuration..."
echo "=========================================================="
wget -q "$REPO_BASE/install/openvpn-engine.sh" -O /tmp/openvpn-engine.sh
chmod +x /tmp/openvpn-engine.sh
/tmp/openvpn-engine.sh
rm -f /tmp/openvpn-engine.sh

# ---- ADD THIS LINE HERE ----
echo "management 127.0.0.1 7505" >> /etc/openvpn/server/server.conf
systemctl restart openvpn-server@server

# 4. SETUP NGINX DOWNLOAD DIRECTORY
echo "Configuring Nginx File Server on Port 85..."
mkdir -p /var/www/html/ovpn
cp /root/Universal-Client.ovpn /var/www/html/ovpn/Universal-Client.ovpn
chmod 644 /var/www/html/ovpn/*.ovpn

cat > /etc/nginx/conf.d/ovpn-download.conf <<EOF
server {
    listen 85;
    server_name _;
    root /var/www/html/ovpn;
    autoindex on;
}
EOF
rm -f /etc/nginx/sites-enabled/default
systemctl restart nginx

# 5. DEPLOY CORE FILES
echo "Deploying Core Security Modules..."
wget -q "$REPO_BASE/core/auth.sh" -O /usr/bin/auth.sh
wget -q "$REPO_BASE/core/enforcer.sh" -O /usr/bin/enforcer.sh
wget -q "$REPO_BASE/core/version.txt" -O /etc/openvpn/version.txt

chmod +x /usr/bin/auth.sh /usr/bin/enforcer.sh
chattr +i /usr/bin/auth.sh /usr/bin/enforcer.sh

# 6. DEPLOY MENU & OVPN MANAGER
echo "Deploying Management Suite..."
wget -q "$REPO_BASE/menu/menu" -O /usr/bin/menu
wget -q "$REPO_BASE/menu/menu-ovpn.sh" -O /usr/bin/menu-ovpn.sh
wget -q "$REPO_BASE/menu/menu-ssh.sh" -O /usr/bin/menu-set.sh
wget -q "$REPO_BASE/menu/update.sh" -O /usr/bin/update.sh
wget -q "$REPO_BASE/menu/speedtest" -O /usr/bin/speedtest
wget -q "$REPO_BASE/menu/health-check" -O /usr/bin/health-check

wget -q "$REPO_BASE/ovpn/add-ovpn" -O /usr/bin/add-ovpn
wget -q "$REPO_BASE/ovpn/del-ovpn" -O /usr/bin/del-ovpn
wget -q "$REPO_BASE/ovpn/renew-ovpn" -O /usr/bin/renew-ovpn
wget -q "$REPO_BASE/ovpn/member-ovpn" -O /usr/bin/member-ovpn
wget -q "$REPO_BASE/ovpn/cek-ovpn" -O /usr/bin/cek-ovpn
wget -q "$REPO_BASE/ovpn/sniper" -O /usr/bin/ovpn-sniper
wget -q "$REPO_BASE/ovpn/xp" -O /usr/bin/ovpn-xp
wget -q "$REPO_BASE/ovpn/trial-ovpn" -O /usr/bin/trial-ovpn
wget -q "$REPO_BASE/ovpn/limit-ovpn" -O /usr/bin/limit-ovpn
wget -q "$REPO_BASE/ovpn/timed-ovpn" -O /usr/bin/timed-ovpn
wget -q "$REPO_BASE/ovpn/autokill-ovpn" -O /usr/bin/autokill-ovpn
wget -q "$REPO_BASE/ovpn/locker-ovpn" -O /usr/bin/locker-ovpn
wget -q "$REPO_BASE/ovpn/api-ovpn" -O /usr/bin/api-ovpn

wget -q "$REPO_BASE/utils/backup" -O /usr/bin/backup.sh
wget -q "$REPO_BASE/utils/restore" -O /usr/bin/restore.sh

apt install -y socat # Ensure socat is installed for the sniper interface

chmod +x /usr/bin/menu* /usr/bin/add-ovpn /usr/bin/del-ovpn /usr/bin/renew-ovpn /usr/bin/member-ovpn /usr/bin/cek-ovpn /usr/bin/ovpn-sniper /usr/bin/ovpn-xp /usr/bin/trial-ovpn /usr/bin/limit-ovpn /usr/bin/timed-ovpn /usr/bin/autokill-ovpn /usr/bin/locker-ovpn /usr/bin/api-ovpn /usr/bin/backup.sh /usr/bin/restore.sh /usr/bin/speedtest /usr/bin/health-check /usr/bin/update.sh

# Note: Ensure rclone is installed for the backup system
curl -s https://rclone.org/install.sh | sudo bash > /dev/null 2>&1
mkdir -p /root/.config/rclone
wget -q "$REPO_BASE/core/rclone.conf" -O /root/.config/rclone/rclone.conf

# 7. CONFIGURE ENFORCER CRON
echo "0 * * * * root /usr/bin/enforcer.sh" > /etc/cron.d/license_enforcer
echo "*/5 * * * * root /usr/bin/ovpn-sniper" > /etc/cron.d/ovpn-sniper
echo "0 1 * * * root /usr/bin/ovpn-xp" > /etc/cron.d/ovpn-xp

service cron restart

echo "=========================================================="
echo "INSTALLATION COMPLETE. AUTHENTICATION LOCKED."
echo "Universal Profile: http://$MYIP:85/Universal-Client.ovpn"
echo "Type 'menu' to initialize your OpenVPN Management Suite."
echo "=========================================================="

rm -f /root/setup.sh