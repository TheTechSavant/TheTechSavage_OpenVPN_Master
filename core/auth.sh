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

if [[ "$STATUS" != "valid" ]]; then
    if [[ -x /usr/bin/enforcer.sh ]]; then
        /usr/bin/enforcer.sh > /dev/null 2>&1 &
    fi
    clear
    echo -e "\033[0;31m════════════════════════════════════════════════════════════\033[0m"
    echo -e "\033[0;31m           ⚠️  SYSTEM LOCKDOWN: LICENSE EXPIRED  ⚠️           \033[0m"
    echo -e "\033[0;31m════════════════════════════════════════════════════════════\033[0m"
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
