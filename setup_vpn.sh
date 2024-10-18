#!/bin/bash

# Function to check command success
check_command() {
    if [ $? -ne 0 ]; then
        log "Error: $1"
        exit 1
    fi
}

echo "Configuring Host A and Host B nodes..."
echo "--------------------------------------"
echo ""

# Retrieve public keys
HOST_A_PUBKEY=$(kathara exec ha "cat /etc/wireguard/public.key")
check_command "Failed to retrieve Host A's public key"

HOST_B_PUBKEY=$(kathara exec hb "cat /etc/wireguard/public.key")
check_command "Failed to retrieve Host B's public key"

# Copy configs to root node
kathara exec ha "cat /etc/wireguard/wg0.conf" > shared/ha_wg0.conf
kathara exec hb "cat /etc/wireguard/wg0.conf" > shared/hb_wg0.conf

# Update configs
sed -i "s|HOST_B_PUBKEY_PLACEHOLDER|$HOST_B_PUBKEY|" shared/ha_wg0.conf
sed -i "s|HOST_A_PUBKEY_PLACEHOLDER|$HOST_A_PUBKEY|" shared/hb_wg0.conf

# Copy configs back to nodes
kathara exec ha "mv shared/ha_wg0.conf /etc/wireguard/wg0.conf"
kathara exec hb "mv shared/hb_wg0.conf /etc/wireguard/wg0.conf"

# Verify the updates
echo "Configuration of Host A node:"
echo "-----------------------------"
kathara exec ha "cat /etc/wireguard/wg0.conf"
echo ""

echo "Configuration of Host B node:"
echo "-----------------------------"
kathara exec hb "cat /etc/wireguard/wg0.conf"
echo ""

# Start WireGuard interfaces
echo "Starting WireGuard on Host A"
echo "----------------------------"
kathara exec ha "wg-quick up wg0"
check_command "Failed to start WireGuard on Host A"
echo ""

echo "Starting WireGuard on Host B"
echo "----------------------------"
kathara exec hb "wg-quick up wg0"
check_command "Failed to start WireGuard on Host B"
echo ""
