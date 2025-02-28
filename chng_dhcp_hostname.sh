#!/bin/bash

# Check if hostname argument is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <new-hostname>"
    exit 1
fi

# Assign the input parameter to the NEW_HOSTNAME variable
NEW_HOSTNAME=$1

# Step 1: Modify /etc/network/interfaces
INTERFACES_FILE="/etc/network/interfaces"
VM_BRIDGE="vmbr0"

# Backup the current interfaces file
cp $INTERFACES_FILE ${INTERFACES_FILE}.bak

# Remove existing vmbr0 configuration if any
sed -i '/^auto vmbr0/,+5d' $INTERFACES_FILE

# Gather all physical interfaces (excluding loopback)
PHY_INTERFACES=$(grep -E "^(auto|iface)" $INTERFACES_FILE | grep -v "lo" | grep -oE "iface\s+\w+" | awk '{print $2}' | sort -u)

# Configure vmbr0 with DHCP and active-backup bonding
cat <<EOF >> $INTERFACES_FILE

auto $VM_BRIDGE
iface $VM_BRIDGE inet dhcp
    bridge_ports $(echo $PHY_INTERFACES)
    bridge_stp off
    bridge_fd 0
    bond_mode active-backup
    bond_miimon 100
    bond_downdelay 200
    bond_updelay 200
EOF

# Remove static IP configurations from physical interfaces
sed -i '/^\s*address\s\|^\s*netmask\s\|^\s*gateway\s/d' $INTERFACES_FILE

# Restart networking to apply changes
systemctl restart networking

# Step 2: Set the new hostname
hostnamectl set-hostname $NEW_HOSTNAME

# Step 3: Verify and Apply Hostname
# Update /etc/hostname
echo "$NEW_HOSTNAME" > /etc/hostname

# Ensure /etc/hosts is updated (simplified example, adjust as needed)
sed -i "s/^127.0.1.1\s.*/127.0.1.1 $NEW_HOSTNAME/" /etc/hosts

# Reload the systemd-hostnamed service to apply changes
systemctl restart systemd-hostnamed

# Check if hostname is correctly set
CURRENT_HOSTNAME=$(hostname)
if [ "$CURRENT_HOSTNAME" != "$NEW_HOSTNAME" ]; then
  echo "Error: Hostname was not set correctly. Exiting."
  exit 1
fi

# Step 4: Create /etc/dhcp/dhclient-exit-hooks.d/update-etc-hosts
HOOKS_DIR="/etc/dhcp/dhclient-exit-hooks.d"
HOOKS_FILE="$HOOKS_DIR/update-etc-hosts"
NEW_HOSTNAME_LOWER=$(echo "$NEW_HOSTNAME" | tr '[:upper:]' '[:lower:]')

# Ensure the hooks directory exists
mkdir -p $HOOKS_DIR

# Create the hook file
cat <<EOF > $HOOKS_FILE
#!/bin/sh
if [ "\$reason" = "BOUND" ] || [ "\$reason" = "RENEW" ]; then
  new_ip_address=\$new_ip_address
  sed -i "s/^.*\\s${NEW_HOSTNAME_LOWER}\\s.*\$/\${new_ip_address} ${NEW_HOSTNAME_LOWER} ${NEW_HOSTNAME_LOWER}/" /etc/hosts
fi
EOF

# Make the hook file readable and executable by root
chmod 700 $HOOKS_FILE
chown root:root $HOOKS_FILE

# Step 5: Regenerate Proxmox certificates
pvecm updatecerts --force

echo "Configuration complete. Please verify your network settings, hostname, and certificates."
