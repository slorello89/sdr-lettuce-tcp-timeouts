#!/bin/bash

# Domain to block
DOMAIN="lettuce-cutoff-redis"

# Resolve the domain to an IP address (IPv4)
IP=$(getent ahosts "$DOMAIN" | grep 'STREAM' | awk '{ print $1 }' | head -n 1)

if [[ -z "$IP" ]]; then
    echo "Failed to resolve $DOMAIN"
    exit 1
fi

echo "Blocking outbound traffic to $DOMAIN ($IP)..."

# Add iptables rule to drop outbound packets to the resolved IP
sudo iptables -A OUTPUT -d "$IP" -j DROP

echo "Done. Outbound traffic to $DOMAIN ($IP) is now blocked."