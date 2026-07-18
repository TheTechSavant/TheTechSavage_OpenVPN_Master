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
    clear
    echo -e "${CYAN}┌─────────────────────────────────────────────────────┐${NC}"
    echo -e "${YELLOW}                 AUTO-REBOOT SETTINGS                 ${NC}"
    echo -e "${CYAN}└─────────────────────────────────────────────────────┘${NC}"
    echo -e "  [\033[0;32m1\033[0m] Every 1 Hour"
    echo -e "  [\033[0;32m2\033[0m] Every 6 Hours"
    echo -e "  [\033[0;32m3\033[0m] Every 12 Hours"
    echo -e "  [\033[0;32m4\033[0m] Every 24 Hours (Daily)"
    echo -e "  [\033[0;31m5\033[0m] Turn OFF Auto-Reboot"
    echo -e "${CYAN}└─────────────────────────────────────────────────────┘${NC}"
    echo -e "  [\033[0;31m0\033[0m] Back to Settings Menu"
    echo ""
    read -p " Select Option : " rbt_opt
    
    case $rbt_opt in
        1)
            echo "0 * * * * root /sbin/reboot" > /etc/cron.d/auto_reboot
            echo -e " \n${GREEN}[OK] Auto-Reboot set to Every 1 Hour!${NC}"
            ;;
        2)
            echo "0 */6 * * * root /sbin/reboot" > /etc/cron.d/auto_reboot
            echo -e " \n${GREEN}[OK] Auto-Reboot set to Every 6 Hours!${NC}"
            ;;
        3)
            echo "0 */12 * * * root /sbin/reboot" > /etc/cron.d/auto_reboot
            echo -e " \n${GREEN}[OK] Auto-Reboot set to Every 12 Hours!${NC}"
            ;;
        4)
            echo "0 0 * * * root /sbin/reboot" > /etc/cron.d/auto_reboot
            echo -e " \n${GREEN}[OK] Auto-Reboot set to Every 24 Hours (Midnight)!${NC}"
            ;;
        5)
            rm -f /etc/cron.d/auto_reboot
            echo -e " \n${RED}[!] Auto-Reboot turned OFF!${NC}"
            ;;
        0)
            menu-set.sh
            ;;
        *)
            echo -e " \n${RED}Invalid Option${NC}"
            ;;
    esac
    service cron restart > /dev/null 2>&1
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
    echo -e "\n${GREEN}OpenVPN Engine Restarted Successfully!${NC}"
    sleep 2; menu-set.sh ;;
6|06) health-check ;;
7|07) /usr/bin/update.sh ;;
0|00) menu ;;
*) echo -e "\n${RED}Invalid Option${NC}"; sleep 1; menu-set.sh ;;
esac
