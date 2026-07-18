#!/bin/bash
# ==========================================
# TheTechSavage OpenVPN License Enforcer
# ==========================================

MYIP=$(curl -sS -4 ifconfig.me)
API_URL="https://file2link.thetechsavage.org.ng/api/check_ip?ip=$MYIP"
RESPONSE=$(curl -s -m 10 "$API_URL")

if [[ -z "$RESPONSE" ]]; then exit 0; fi

STATUS=$(echo "$RESPONSE" | grep -o '"status": *"[^"]*"' | cut -d'"' -f4)

if [[ "$STATUS" != "valid" ]]; then
    # --- KILL SWITCH ENGAGED ---
    if [[ ! -f /etc/openvpn/license_dead ]]; then
        touch /etc/openvpn/license_dead
        # Stopping OpenVPN and helper proxies
        systemctl stop openvpn-server@server
        systemctl disable openvpn-server@server > /dev/null 2>&1
    fi
else
    # --- LICENSE IS VALID ---
    if [[ -f /etc/openvpn/license_dead ]]; then
        rm -f /etc/openvpn/license_dead
        systemctl enable openvpn-server@server > /dev/null 2>&1
        systemctl start openvpn-server@server
    fi
fi
