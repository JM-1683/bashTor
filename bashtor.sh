#!/bin/bash

# Name: bashtor.sh

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "You must run BashTor as root." 
    exit 1
fi

# Install necessary tools if not already present
if ! command -v jq &>/dev/null; then
    echo "Installing jq..."
    dnf install -y jq
fi

if ! command -v firewall-cmd &>/dev/null; then
    echo "firewalld is not installed or not in PATH. Please ensure it's installed and accessible."
    exit 1
fi

# Fetch the list of Tor exit nodes
echo "Fetching Tor exit node IPs..."
curl -s https://check.torproject.org/torbulkexitlist?ip=$(curl -s https://ipinfo.io/ip) -o tor_exit_list.txt

# Block IPs using firewalld
echo "Blocking Tor IPs with firewalld..."
while read -r ip; do
    firewall-cmd --permanent --add-rich-rule="rule family='ipv4' source address='$ip' reject"
done < tor_exit_list.txt

firewall-cmd --reload

# Cleanup
rm tor_exit_list.txt

echo "Blocking complete!"
