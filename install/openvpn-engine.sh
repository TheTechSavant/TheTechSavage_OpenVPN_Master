#!/bin/bash
# Nyr's Engine - Refactored for TheTechSavage PAM Authentication
# Includes Full DNS, IPv6 Routing, SELinux & LXC/OpenVZ Failsafes

if readlink /proc/$$/exe | grep -q "dash"; then
	echo 'This installer needs to be run with "bash", not "sh".'
	exit
fi

read -N 999999 -t 0.001

if grep -qs "ubuntu" /etc/os-release; then
	os="ubuntu"
	os_version=$(grep 'VERSION_ID' /etc/os-release | cut -d '"' -f 2 | tr -d '.')
	group_name="nogroup"
elif [[ -e /etc/debian_version ]]; then
	os="debian"
	os_version=$(grep -oE '[0-9]+' /etc/debian_version | head -1)
	group_name="nogroup"
elif [[ -e /etc/almalinux-release || -e /etc/rocky-release || -e /etc/centos-release ]]; then
	os="centos"
	os_version=$(grep -shoE '[0-9]+' /etc/almalinux-release /etc/rocky-release /etc/centos-release | head -1)
	group_name="nobody"
elif [[ -e /etc/fedora-release ]]; then
	os="fedora"
	os_version=$(grep -oE '[0-9]+' /etc/fedora-release | head -1)
	group_name="nobody"
else
	echo "Unsupported OS."
	exit
fi

if [[ "$EUID" -ne 0 ]]; then
	echo "This installer needs to be run with superuser privileges."
	exit
fi

if [[ ! -e /dev/net/tun ]] || ! ( exec 7<>/dev/net/tun ) 2>/dev/null; then
	echo "TUN needs to be enabled before running this installer."
	exit
fi

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Auto-Detect Internal & Public IPv4
ip=$(ip -4 route get 8.8.8.8 | awk {'print $7'} | tr -d '\n')
public_ip=$(curl -sS -4 ifconfig.me)

# Disable IPv6 Configuration
ip6=""

echo "Which protocol should OpenVPN use?"
echo "   1) UDP (recommended)"
echo "   2) TCP"
read -p "Protocol [1]: " protocol
case "$protocol" in
	1|"") protocol=udp ;;
	2) protocol=tcp ;;
esac

echo
echo "What port should OpenVPN listen on?"
read -p "Port [1194]: " port
[[ -z "$port" ]] && port="1194"

echo
echo "Select a DNS server for the clients:"
echo "   1) Default system resolvers"
echo "   2) Google"
echo "   3) 1.1.1.1"
echo "   4) OpenDNS"
echo "   5) Quad9"
echo "   6) Gcore"
echo "   7) AdGuard"
echo "   8) Specify custom resolvers"
read -p "DNS server [1]: " dns
until [[ -z "$dns" || "$dns" =~ ^[1-8]$ ]]; do
	echo "$dns: invalid selection."
	read -p "DNS server [1]: " dns
done

if [[ "$dns" = "8" ]]; then
	echo
	until [[ -n "$custom_dns" ]]; do
		echo "Enter DNS servers (one or more IPv4 addresses, separated by commas or spaces):"
		read -p "DNS servers: " dns_input
		dns_input=$(echo "$dns_input" | tr ',' ' ')
		for dns_ip in $dns_input; do
			if [[ "$dns_ip" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]]; then
				if [[ -z "$custom_dns" ]]; then
					custom_dns="$dns_ip"
				else
					custom_dns="$custom_dns $dns_ip"
				fi
			fi
		done
		if [ -z "$custom_dns" ]; then
			echo "Invalid input."
		fi
	done
fi

echo
echo "OpenVPN installation is ready to begin."
read -n1 -r -p "Press any key to continue..."

# Install Packages & Firewalls
if ! systemctl is-active --quiet firewalld.service && ! hash iptables 2>/dev/null; then
	if [[ "$os" == "centos" || "$os" == "fedora" ]]; then
		firewall="firewalld"
	elif [[ "$os" == "debian" || "$os" == "ubuntu" ]]; then
		firewall="iptables"
	fi
fi

# LXC/OpenVZ Container Failsafe
if systemd-detect-virt -cq; then
	mkdir /etc/systemd/system/openvpn-server@server.service.d/ 2>/dev/null
	echo "[Service]
LimitNPROC=infinity" > /etc/systemd/system/openvpn-server@server.service.d/disable-limitnproc.conf
fi

if [[ "$os" = "debian" || "$os" = "ubuntu" ]]; then
	apt-get update
	apt-get install -y --no-install-recommends openvpn openssl ca-certificates $firewall
elif [[ "$os" = "centos" ]]; then
	dnf install -y epel-release
	dnf install -y openvpn openssl ca-certificates tar $firewall
else
	dnf install -y openvpn openssl ca-certificates tar $firewall
fi

if [[ "$firewall" == "firewalld" ]]; then
	systemctl enable --now firewalld.service
fi

# Setup Easy-RSA (Only for Server Certs now)
easy_rsa_url='https://github.com/OpenVPN/easy-rsa/releases/download/v3.2.6/EasyRSA-3.2.6.tgz'
mkdir -p /etc/openvpn/server/easy-rsa/
{ wget -qO- "$easy_rsa_url" 2>/dev/null || curl -sL "$easy_rsa_url" ; } | tar xz -C /etc/openvpn/server/easy-rsa/ --strip-components 1
chown -R root:root /etc/openvpn/server/easy-rsa/
cd /etc/openvpn/server/easy-rsa/
./easyrsa --batch init-pki
./easyrsa --batch build-ca nopass
./easyrsa gen-tls-crypt-key

echo '-----BEGIN DH PARAMETERS-----
MIIBCAKCAQEA//////////+t+FRYortKmq/cViAnPTzx2LnFg84tNpWp4TZBFGQz
+8yTnc4kmz75fS/jY2MMddj2gbICrsRhetPfHtXV/WVhJDP1H18GbtCFY2VVPe0a
87VXE15/V8k1mE8McODmi3fipona8+/och3xWKE2rec1MKzKT0g6eXq8CrGCsyT7
YdEIqUuyyOP7uWrat2DX9GgdT0Kj3jlN9K5W7edjcrsZCwenyO4KbXCeAvzhzffi
7MA0BM0oNC9hkXL+nOmFg/+OTxIy7vKBg8P+OxtMb61zO7X8vC7CIAXFjvGDfRaD
ssbzSibBsu/6iGtCOGEoXJf//////////wIBAg==
-----END DH PARAMETERS-----' > /etc/openvpn/server/dh.pem

ln -s /etc/openvpn/server/dh.pem pki/dh.pem
./easyrsa --batch --days=3650 build-server-full server nopass
cp pki/ca.crt pki/private/ca.key pki/issued/server.crt pki/private/server.key /etc/openvpn/server
cp pki/private/easyrsa-tls.key /etc/openvpn/server/tc.key

# Locate PAM Plugin Dynamically
PLUGIN=$(find /usr -type f -name "openvpn-plugin-auth-pam.so" | head -n 1)

# Generate server.conf (INJECTED PAM AUTH & IPv6)
echo "port $port
proto $protocol
dev tun
ca ca.crt
cert server.crt
key server.key
dh dh.pem
tls-crypt tc.key
topology subnet
server 10.8.0.0 255.255.255.0
plugin $PLUGIN login
verify-client-cert none
username-as-common-name
status /var/log/openvpn-status.log" > /etc/openvpn/server/server.conf

if [[ -z "$ip6" ]]; then
	echo 'push "redirect-gateway def1 bypass-dhcp"' >> /etc/openvpn/server/server.conf
else
	echo 'server-ipv6 fddd:1194:1194:1194::/64' >> /etc/openvpn/server/server.conf
	echo 'push "redirect-gateway def1 ipv6 bypass-dhcp"' >> /etc/openvpn/server/server.conf
fi
echo 'ifconfig-pool-persist ipp.txt' >> /etc/openvpn/server/server.conf

# DNS Options
case "$dns" in
	1|"")
		if grep '^nameserver' "/etc/resolv.conf" | grep -qv '127.0.0.53' ; then
			resolv_conf="/etc/resolv.conf"
		else
			resolv_conf="/run/systemd/resolve/resolv.conf"
		fi
		grep -v '^#\|^;' "$resolv_conf" | grep '^nameserver' | grep -v '127.0.0.53' | grep -oE '[0-9]{1,3}(\.[0-9]{1,3}){3}' | while read line; do
			echo "push \"dhcp-option DNS $line\"" >> /etc/openvpn/server/server.conf
		done
	;;
	2)
		echo 'push "dhcp-option DNS 8.8.8.8"' >> /etc/openvpn/server/server.conf
		echo 'push "dhcp-option DNS 8.8.4.4"' >> /etc/openvpn/server/server.conf
	;;
	3)
		echo 'push "dhcp-option DNS 1.1.1.1"' >> /etc/openvpn/server/server.conf
		echo 'push "dhcp-option DNS 1.0.0.1"' >> /etc/openvpn/server/server.conf
	;;
	4)
		echo 'push "dhcp-option DNS 208.67.222.222"' >> /etc/openvpn/server/server.conf
		echo 'push "dhcp-option DNS 208.67.220.220"' >> /etc/openvpn/server/server.conf
	;;
	5)
		echo 'push "dhcp-option DNS 9.9.9.9"' >> /etc/openvpn/server/server.conf
		echo 'push "dhcp-option DNS 149.112.112.112"' >> /etc/openvpn/server/server.conf
	;;
	6)
		echo 'push "dhcp-option DNS 95.85.95.85"' >> /etc/openvpn/server/server.conf
		echo 'push "dhcp-option DNS 2.56.220.2"' >> /etc/openvpn/server/server.conf
	;;
	7)
		echo 'push "dhcp-option DNS 94.140.14.14"' >> /etc/openvpn/server/server.conf
		echo 'push "dhcp-option DNS 94.140.15.15"' >> /etc/openvpn/server/server.conf
	;;
	8)
		for dns_ip in $custom_dns; do
			echo "push \"dhcp-option DNS $dns_ip\"" >> /etc/openvpn/server/server.conf
		done
	;;
esac

echo 'push "block-outside-dns"' >> /etc/openvpn/server/server.conf
echo "keepalive 10 120
user nobody
group $group_name
persist-key
persist-tun
verb 3" >> /etc/openvpn/server/server.conf

if [[ "$protocol" = "udp" ]]; then
	echo "explicit-exit-notify" >> /etc/openvpn/server/server.conf
fi

# Enable Routing
echo 'net.ipv4.ip_forward=1' > /etc/sysctl.d/99-openvpn-forward.conf
echo 1 > /proc/sys/net/ipv4/ip_forward

if [[ -n "$ip6" ]]; then
	echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.d/99-openvpn-forward.conf
	echo 1 > /proc/sys/net/ipv6/conf/all/forwarding
fi

# Firewall / IPTables Routing
if systemctl is-active --quiet firewalld.service; then
	firewall-cmd --add-port="$port"/"$protocol"
	firewall-cmd --zone=trusted --add-source=10.8.0.0/24
	firewall-cmd --permanent --add-port="$port"/"$protocol"
	firewall-cmd --permanent --zone=trusted --add-source=10.8.0.0/24
	firewall-cmd --direct --add-rule ipv4 nat POSTROUTING 0 -s 10.8.0.0/24 ! -d 10.8.0.0/24 -j MASQUERADE
	firewall-cmd --permanent --direct --add-rule ipv4 nat POSTROUTING 0 -s 10.8.0.0/24 ! -d 10.8.0.0/24 -j MASQUERADE
	if [[ -n "$ip6" ]]; then
		firewall-cmd --zone=trusted --add-source=fddd:1194:1194:1194::/64
		firewall-cmd --permanent --zone=trusted --add-source=fddd:1194:1194:1194::/64
		firewall-cmd --direct --add-rule ipv6 nat POSTROUTING 0 -s fddd:1194:1194:1194::/64 ! -d fddd:1194:1194:1194::/64 -j SNAT --to "$ip6"
		firewall-cmd --permanent --direct --add-rule ipv6 nat POSTROUTING 0 -s fddd:1194:1194:1194::/64 ! -d fddd:1194:1194:1194::/64 -j SNAT --to "$ip6"
	fi
else
	iptables_path=$(command -v iptables)
	ip6tables_path=$(command -v ip6tables)
	if [[ $(systemd-detect-virt) == "openvz" ]] && readlink -f "$(command -v iptables)" | grep -q "nft" && hash iptables-legacy 2>/dev/null; then
		iptables_path=$(command -v iptables-legacy)
		ip6tables_path=$(command -v ip6tables-legacy)
	fi
	echo "[Unit]
After=network-online.target
Wants=network-online.target
[Service]
Type=oneshot
ExecStart=$iptables_path -w 5 -t nat -A POSTROUTING -s 10.8.0.0/24 ! -d 10.8.0.0/24 -j MASQUERADE
ExecStart=$iptables_path -w 5 -I INPUT -p $protocol --dport $port -j ACCEPT
ExecStart=$iptables_path -w 5 -I FORWARD -s 10.8.0.0/24 -j ACCEPT
ExecStart=$iptables_path -w 5 -I FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
ExecStop=$iptables_path -w 5 -t nat -D POSTROUTING -s 10.8.0.0/24 ! -d 10.8.0.0/24 -j MASQUERADE
ExecStop=$iptables_path -w 5 -D INPUT -p $protocol --dport $port -j ACCEPT
ExecStop=$iptables_path -w 5 -D FORWARD -s 10.8.0.0/24 -j ACCEPT
ExecStop=$iptables_path -w 5 -D FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT" > /etc/systemd/system/openvpn-iptables.service
	if [[ -n "$ip6" ]]; then
		echo "ExecStart=$ip6tables_path -w 5 -t nat -A POSTROUTING -s fddd:1194:1194:1194::/64 ! -d fddd:1194:1194:1194::/64 -j SNAT --to $ip6
ExecStart=$ip6tables_path -w 5 -I FORWARD -s fddd:1194:1194:1194::/64 -j ACCEPT
ExecStart=$ip6tables_path -w 5 -I FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
ExecStop=$ip6tables_path -w 5 -t nat -D POSTROUTING -s fddd:1194:1194:1194::/64 ! -d fddd:1194:1194:1194::/64 -j SNAT --to $ip6
ExecStop=$ip6tables_path -w 5 -D FORWARD -s fddd:1194:1194:1194::/64 -j ACCEPT
ExecStop=$ip6tables_path -w 5 -D FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT" >> /etc/systemd/system/openvpn-iptables.service
	fi
	echo "RemainAfterExit=yes
[Install]
WantedBy=multi-user.target" >> /etc/systemd/system/openvpn-iptables.service
	systemctl enable --now openvpn-iptables.service
fi

# SELinux Port Failsafe
if sestatus 2>/dev/null | grep "Current mode" | grep -q "enforcing" && [[ "$port" != 1194 ]]; then
	if ! hash semanage 2>/dev/null; then
		dnf install -y policycoreutils-python-utils
	fi
	semanage port -a -t openvpn_port_t -p "$protocol" "$port"
fi

[[ -n "$public_ip" ]] && ip="$public_ip"

# Generate Master Client Config (INJECTED auth-user-pass)
echo "client
dev tun
proto $protocol
remote $ip $port
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
auth-user-pass
ignore-unknown-option block-outside-dns
verb 3" > /etc/openvpn/server/client-common.txt

# Port 53 Failsafe: Clear systemd-resolved if Port 53 is chosen
if [[ "$port" == "53" ]] && systemctl is-active --quiet systemd-resolved.service; then
	sed -i 's/#DNSStubListener=yes/DNSStubListener=no/' /etc/systemd/resolved.conf
	sed -i 's/DNSStubListener=yes/DNSStubListener=no/' /etc/systemd/resolved.conf
	systemctl restart systemd-resolved
	rm -f /etc/resolv.conf
	ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf
fi

# Start OpenVPN
systemctl enable --now openvpn-server@server.service

# Build the Universal .ovpn file
grep -vh '^#' /etc/openvpn/server/client-common.txt > /root/Universal-Client.ovpn
echo "<ca>" >> /root/Universal-Client.ovpn
cat /etc/openvpn/server/ca.crt >> /root/Universal-Client.ovpn
echo "</ca>" >> /root/Universal-Client.ovpn
echo "<tls-crypt>" >> /root/Universal-Client.ovpn
cat /etc/openvpn/server/tc.key >> /root/Universal-Client.ovpn
echo "</tls-crypt>" >> /root/Universal-Client.ovpn

echo "OpenVPN Engine Deployed with PAM Authentication!"
