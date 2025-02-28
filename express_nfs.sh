#!/bin/bash

# Check if the required parameter for directory is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <directory_to_share>"
    echo "Example: $0 /srv/nfs/share"
    exit 1
fi

SHARE_DIR=$1

# Define RFC1918 networks
RFC1918_NETWORKS=("10.0.0.0/8" "172.16.0.0/12" "192.168.0.0/16")

# Update package list and install NFS server
apt update
apt install -y nfs-kernel-server

# Create the directory to be shared
mkdir -p "$SHARE_DIR"

# Set up the NFS export for the RFC1918 networks
for NETWORK in "${RFC1918_NETWORKS[@]}"; do
    echo "$SHARE_DIR $NETWORK(rw,sync,no_subtree_check,no_root_squash)" >> /etc/exports
done

# Apply the export configuration
exportfs -ra

# Ensure NFSv3 is enabled
sed -i '/^RPCNFSDOPTS=/c\RPCNFSDOPTS="--nfs-version 3"' /etc/default/nfs-kernel-server

# Restart the NFS server to apply changes
systemctl restart nfs-kernel-server

# Check if ufw is active and configure the firewall
if systemctl is-active --quiet ufw; then
    echo "Configuring UFW firewall..."
    for NETWORK in "${RFC1918_NETWORKS[@]}"; do
        ufw allow from "$NETWORK" to any port nfs
    done
    ufw reload
elif systemctl is-active --quiet firewalld; then
    echo "Configuring Firewalld..."
    for NETWORK in "${RFC1918_NETWORKS[@]}"; do
        firewall-cmd --permanent --zone=public --add-source="$NETWORK"
    done
    firewall-cmd --permanent --zone=public --add-service=nfs
    firewall-cmd --reload
else
    echo "No active firewall (ufw or firewalld) detected, skipping firewall configuration."
fi

echo "NFSv3 server setup complete. Shared directory: $SHARE_DIR"

