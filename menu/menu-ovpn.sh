#!/bin/bash
/usr/bin/auth.sh || exit 1
if [[ "$(cat /tmp/.vps_auth_token 2>/dev/null)" != "TechSavage_$(date +%Y-%m-%d)" ]]; then exit 1; fi

clear
echo -e "\033[0;36m┌─────────────────────────────────────────────────────┐\033[0m"
echo -e "\033[0;33m                 OPENVPN MANAGEMENT                   \033[0m"
echo -e "\033[0;36m└─────────────────────────────────────────────────────┘\033[0m"
echo -e "    \033[0;32m[01]\033[0m Create OpenVPN User"
echo -e "    \033[0;32m[02]\033[0m Generate Trial Account"
echo -e "    \033[0;32m[03]\033[0m Create Timed Account (Mins)"
echo -e "    \033[0;32m[04]\033[0m Renew User Expiry"
echo -e "    \033[0;32m[05]\033[0m Delete OpenVPN User"
echo -e "    \033[0;32m[06]\033[0m List All Members"
echo -e "    \033[0;32m[07]\033[0m Check Active Connections"
echo -e "\033[0;36m┌─────────────────────────────────────────────────────┐\033[0m"
echo -e "    \033[0;31m[00]\033[0m Back to Main Menu"
echo -e "\033[0;36m└─────────────────────────────────────────────────────┘\033[0m"

read -p " Select menu : " opt || exit 1
case $opt in
    1|01) add-ovpn ;;
    2|02) trial-ovpn ;;
    3|03) timed-ovpn ;;
    4|04) renew-ovpn ;;
    5|05) del-ovpn ;;
    6|06) member-ovpn ;;
    7|07) cek-ovpn ;;
    0|00) menu ;;
    *) echo "Invalid Option"; sleep 1; menu-ovpn.sh ;;
esac