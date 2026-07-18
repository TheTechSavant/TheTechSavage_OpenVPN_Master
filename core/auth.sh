#!/bin/bash
# --- TheTechSavage Central Authentication Module (OpenVPN Edition) ---
CACHE_FILE="/tmp/.vps_auth_token"

if [[ -f "$CACHE_FILE" ]]; then
    if [[ -n "$(find "$CACHE_FILE" -mmin -15 -print 2>/dev/null)" ]]; then
        exit 0
    fi
fi

if ! tty -s; then sleep $((RANDOM % 15)); fi

MYIP=$(curl -sS -4 ifconfig.me)
API_URL="https://file2link.thetechsavage.org.ng/api/check_ip?ip=$MYIP"
RESPONSE=$(curl -s -m 10 "$API_URL")

if [[ -z "$RESPONSE" ]]; then
    TODAY="TechSavage_$(date +%Y-%m-%d)"
    if [[ "$(cat $CACHE_FILE 2>/dev/null)" == "$TODAY" ]]; then
        touch "$CACHE_FILE"
        exit 0
    else
        clear
        echo -e "\033[0;31m[!] CRITICAL ERROR: Unable to reach License Server API.\033[0m"
        exit 1
    fi
fi

STATUS=$(echo "$RESPONSE" | grep -o '"status": *"[^"]*"' | cut -d'"' -f4)
CLIENT_NAME=$(echo "$RESPONSE" | grep -o '"client": *"[^"]*"' | cut -d'"' -f4)
EXP_DATE=$(echo "$RESPONSE" | grep -o '"exp": *"[^"]*"' | cut -d'"' -f4)
MSG=$(echo "$RESPONSE" | grep -o '"message": *"[^"]*"' | cut -d'"' -f4)

# Fallback if the API doesn't provide a specific error message
[[ -z "$MSG" ]] && MSG="IP Not Registered or License Expired"

if [[ "$STATUS" != "valid" ]]; then
    if [[ -x /usr/bin/enforcer.sh ]]; then
        /usr/bin/enforcer.sh > /dev/null 2>&1 &
    fi
    clear
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    CYAN='\033[0;36m'
    NC='\033[0m'

    echo -e "${RED}════════════════════════════════════════════════════════════${NC}"
    echo -e "${RED}           ⚠️  SYSTEM LOCKDOWN: LICENSE EXPIRED  ⚠️           ${NC}"
    echo -e "${RED}════════════════════════════════════════════════════════════${NC}"
    echo -e ""
    echo -e "${YELLOW} Your TheTechSavage Autoscript license is currently inactive.${NC}"
    echo -e " Server IP  : ${GREEN}$MYIP${NC}"
    echo -e " API Status : ${RED}$MSG${NC}"
    echo -e ""
    echo -e "${CYAN} [ SERVICE INFRASTRUCTURE STATUS ]${NC}"
    echo -e " ❌ OpenVPN Engine & Routing Nodes:          ${RED}OFFLINE${NC}"
    echo -e " ❌ Nginx Multiplexers & Profile Hub:        ${RED}OFFLINE${NC}"
    echo -e " ❌ Client Internet Access & Routing:        ${RED}SUSPENDED${NC}"
    echo -e " ✅ Base Admin SSH Access (Port 22):         ${GREEN}ACTIVE${NC}"
    echo -e ""
    echo -e "${YELLOW} [ AUTOMATED SYSTEM NOTICE ]${NC}"
    echo -e " The License Enforcer has safely suspended all networking and"
    echo -e " user routing services to protect the server architecture."
    echo -e ""
    echo -e " Your client accounts, VPS IP, and configurations are safe."
    echo -e " However, no connections will be processed until the license"
    echo -e " is formally renewed via the Master API."
    echo -e ""
    echo -e "${CYAN} ➔ To automatically restore all services and power up the${NC}"
    echo -e "${CYAN}    nodes, please contact the Administrator for renewal:${NC}"
    echo -e ""
    echo -e " 💬 Support : ${CYAN}https://t.me/TheTechSavagesupport${NC}"
    echo -e " 🤖 Bot     : ${CYAN}https://t.me/THETECHSAVAGE_BOT${NC}"
    echo -e ""
    echo -e "${RED}════════════════════════════════════════════════════════════${NC}"
    
    rm -f "$CACHE_FILE"
    exit 1
fi

if [[ -f /etc/openvpn/license_dead ]]; then
    if [[ -x /usr/bin/enforcer.sh ]]; then
        /usr/bin/enforcer.sh > /dev/null 2>&1 &
        sleep 2
    fi
fi

echo "$CLIENT_NAME" > /etc/openvpn/client_name
echo "$EXP_DATE" > /etc/openvpn/exp_date
echo "TechSavage_$(date +%Y-%m-%d)" > "$CACHE_FILE"
