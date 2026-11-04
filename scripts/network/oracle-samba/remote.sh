#!/usr/bin/env bash
# Runs on oracle as root (copied and started by ./setup). Reads the Samba
# password on stdin.
set -euo pipefail
pw=$(cat)
dir=$(cd "$(dirname "$0")" && pwd)
rule=(-s 100.91.0.0/16 -i wt0 -p tcp -m tcp --dport 445 -j ACCEPT)

if ! dpkg -s samba >/dev/null 2>&1; then
	DEBIAN_FRONTEND=noninteractive apt-get install -y -qq samba >/dev/null
fi
install -m 0644 "$dir/smb.conf" /etc/samba/smb.conf
install -m 0644 "$dir/users.map" /etc/samba/users.map
testparm -s >/dev/null 2>&1 || { testparm -s; exit 1; }

printf '%s\n%s\n' "$pw" "$pw" | smbpasswd -s -a ubuntu >/dev/null

# Firewall: allow 445 from NetBird before the final REJECT, live and saved
if ! iptables -C INPUT "${rule[@]}" 2>/dev/null; then
	pos=$(iptables -L INPUT --line-numbers | awk '/REJECT/{print $1; exit}')
	iptables -I INPUT "$pos" "${rule[@]}"
fi
line="-A INPUT ${rule[*]}"
if ! grep -qxF -- "$line" /etc/iptables/rules.v4; then
	cp /etc/iptables/rules.v4 "/etc/iptables/rules.v4.backup.$(date +%Y%m%d_%H%M%S)"
	awk -v l="$line" '!done && /^-A INPUT -j REJECT/ {print l; done=1} {print}' \
		/etc/iptables/rules.v4 > /etc/iptables/rules.v4.new
	mv /etc/iptables/rules.v4.new /etc/iptables/rules.v4
fi

systemctl disable --now nmbd samba-ad-dc >/dev/null 2>&1 || true
systemctl enable smbd >/dev/null 2>&1
systemctl restart smbd
echo "smbd: $(systemctl is-active smbd)"
