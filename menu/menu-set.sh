#!/bin/bash
/usr/bin/auth.sh || exit 1
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'
MYIP=$(curl -sS -4 ifconfig.me)

# Dynamically fetch Port and Protocol from the active config
if [[ -f /etc/openvpn/server/server.conf ]]; then
    OVPN_PORT=$(grep '^port ' /etc/openvpn/server/server.conf | cut -d " " -f 2)
    OVPN_PROTO=$(grep '^proto ' /etc/openvpn/server/server.conf | cut -d " " -f 2 | tr '[:lower:]' '[:upper:]')
else
    OVPN_PORT="Unknown"
    OVPN_PROTO="Unknown"
fi

clear
echo -e "${CYAN}┌─────────────────────────────────────────────────────┐${NC}"
echo -e "${YELLOW}               SYSTEM SETTINGS MANAGER                ${NC}"
echo -e "${CYAN}└─────────────────────────────────────────────────────┘${NC}"
echo -e " [\033[0;32m01\033[0m]  Speedtest VPS"
echo -e " [\033[0;32m02\033[0m]  View System Ports"
echo -e " [\033[0;32m03\033[0m]  Set Auto Reboot"
echo -e " [\033[0;32m04\033[0m]  View Reboot Logs"
echo -e " [\033[0;32m05\033[0m]  Restart OpenVPN Services"
echo -e " [\033[0;32m06\033[0m]  Server Health Check"
echo -e " [\033[0;32m07\033[0m]  Pull Updates (OTA)"
echo -e "${CYAN}└─────────────────────────────────────────────────────┘${NC}"
echo -e " [\033[0;31m00\033[0m]  Back to Main Menu"
echo ""
read -p " Select menu : " opt || exit 1

case $opt in
1|01) speedtest ;;
2|02) 
    clear
    echo -e "${CYAN}┌─────────────────────────────────────────────────────┐${NC}"
    echo -e "${YELLOW}                 SYSTEM PORTS & INFO                  ${NC}"
    echo -e "${CYAN}└─────────────────────────────────────────────────────┘${NC}"
    echo -e "  - OpenVPN Server  : $OVPN_PORT ($OVPN_PROTO)"
    echo -e "  - Nginx Configs   : 85 (HTTP)"
    echo -e "  - OVPN Management : 7505 (Localhost)"
    echo -e "${CYAN}└─────────────────────────────────────────────────────┘${NC}"
    read -n 1 -s -r -p "Press any key to return..." 
    menu-set.sh ;;
3|03)
    read -p " Input hour (0-23): " hour
    if [[ "$hour" =~ ^[0-9]+$ ]] && [ "$hour" -ge 0 ] && [ "$hour" -le 23 ]; then
        echo "0 $hour * * * root /sbin/reboot" > /etc/cron.d/auto_reboot
        service cron restart
        echo -e "${GREEN}Auto-Reboot set to daily at $hour:00!${NC}"
    else
        echo -e "${RED}[ERROR] Invalid Number!${NC}"
    fi
    sleep 2; menu-set.sh ;;
4|04)
    clear
    echo -e "${CYAN}┌─────────────────────────────────────────────────────┐${NC}"
    echo -e "${YELLOW}                 SERVER REBOOT LOG                    ${NC}"
    echo -e "${CYAN}└─────────────────────────────────────────────────────┘${NC}"
    last reboot | head -n 10
    read -n 1 -s -r -p "Press any key to return..." ; menu-set.sh ;;
5|05)
    systemctl restart openvpn-server@server
    echo -e "${GREEN}OpenVPN Engine Restarted Successfully!${NC}"
    sleep 2; menu-set.sh ;;
6|06) health-check ;;
7|07) /usr/bin/update.sh ;;
0|00) menu ;;
*) echo -e "${RED}Invalid Option${NC}"; sleep 1; menu-set.sh ;;
esac
