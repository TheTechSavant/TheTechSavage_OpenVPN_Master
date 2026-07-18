#!/bin/bash
# --- TheTechSavage OTA Updater (OpenVPN Edition) ---
/usr/bin/auth.sh || exit 1

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Define your independent vault
REPO_BASE="https://raw.githubusercontent.com/TheTechSavant/TheTechSavage_OpenVPN_Master/main"

clear
echo -e "${CYAN}┌─────────────────────────────────────────────────────┐${NC}"
echo -e "${YELLOW}                 VAULT OTA UPDATER                    ${NC}"
echo -e "${CYAN}└─────────────────────────────────────────────────────┘${NC}"
echo -e " ${YELLOW}⬇️ Synchronizing architecture with master vault...${NC}"

# --- SAFE DOWNLOAD ENGINE ---
safe_update() {
    local folder=$1
    local file=$2
    
    # Download to a temporary staging file
    wget -qO "/tmp/$file" "${REPO_BASE}/$folder/$file"
    
    # Only deploy if file is > 0 bytes AND is not a GitHub 404 HTML error page
    if [[ -s "/tmp/$file" ]] && ! grep -q "<html" "/tmp/$file"; then
        mv -f "/tmp/$file" "/usr/bin/$file"
        chmod +x "/usr/bin/$file"
        echo -e "   ${GREEN}✔ Updated:${NC} $file"
    else
        rm -f "/tmp/$file"
        echo -e "   ${RED}✘ Failed:${NC} $file (Not found or empty)"
    fi
}

echo -e " \n${YELLOW}⚙️ Upgrading Menus...${NC}"
safe_update "menu" "menu"
safe_update "menu" "menu-ovpn.sh"
safe_update "menu" "menu-set.sh"
safe_update "menu" "speedtest"
safe_update "menu" "health-check"

echo -e " \n${YELLOW}⚙️ Upgrading OpenVPN Modules...${NC}"
safe_update "ovpn" "add-ovpn"
safe_update "ovpn" "del-ovpn"
safe_update "ovpn" "renew-ovpn"
safe_update "ovpn" "member-ovpn"
safe_update "ovpn" "cek-ovpn"
safe_update "ovpn" "sniper"
mv /usr/bin/sniper /usr/bin/ovpn-sniper 2>/dev/null
safe_update "ovpn" "xp"
mv /usr/bin/xp /usr/bin/ovpn-xp 2>/dev/null
safe_update "ovpn" "trial-ovpn"
safe_update "ovpn" "limit-ovpn"
safe_update "ovpn" "timed-ovpn"
safe_update "ovpn" "autokill-ovpn"
safe_update "ovpn" "locker-ovpn"
safe_update "ovpn" "api-ovpn"

echo -e " \n${YELLOW}⚙️ Upgrading Utility Modules...${NC}"
safe_update "utils" "backup"
mv /usr/bin/backup /usr/bin/backup.sh 2>/dev/null
safe_update "utils" "restore"
mv /usr/bin/restore /usr/bin/restore.sh 2>/dev/null

echo -e " \n${YELLOW}⚙️ Upgrading Security Core...${NC}"
chattr -i /usr/bin/auth.sh > /dev/null 2>&1
chattr -i /usr/bin/enforcer.sh > /dev/null 2>&1

safe_update "core" "auth.sh"
safe_update "core" "enforcer.sh"

chattr +i /usr/bin/auth.sh > /dev/null 2>&1
chattr +i /usr/bin/enforcer.sh > /dev/null 2>&1

echo -e " \n${YELLOW}⚙️ Restarting Services...${NC}"
systemctl restart openvpn-server@server
service cron restart

# Update Version File
curl -s -m 5 "${REPO_BASE}/core/version.txt" > /etc/openvpn/version.txt

echo -e "\n${CYAN}└─────────────────────────────────────────────────────┘${NC}"
echo -e " ${GREEN}✅ System Successfully Updated!${NC}"
read -n 1 -s -r -p "Press any key to return..."
menu-set.sh
