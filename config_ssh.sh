#!/bin/bash

# Define the configuration file name
CONF_FILE="/etc/ssh/sshd_config.d/unicosys.conf"

# Check if the configuration file already exists
if [ -f "$CONF_FILE" ]; then
    echo "Configuration file $CONF_FILE already exists."
else
    # Create a new configuration file and add the recommended security settings
    echo "Creating $CONF_FILE and adding security configurations..."
    bash -c "cat > $CONF_FILE" <<EOL
# Custom SSH configuration for enhanced security by unico.systems

# Enable public key authentication
PubkeyAuthentication yes

# Disable password authentication
PasswordAuthentication no

# Disable root login
PermitRootLogin no

# Restrict SSH access to specific users and groups
AllowUsers allowed_user
AllowGroups allowed_group

# Disable X11 forwarding
X11Forwarding no

# Use only SSH Protocol 2
Protocol 2

# Set idle timeout interval to 5 minutes
ClientAliveInterval 300
ClientAliveCountMax 0

# Limit authentication attempts to prevent brute-force attacks
MaxAuthTries 3

# Use strong encryption ciphers and MACs
Ciphers aes256-gcm@openssh.com,chacha20-poly1305@openssh.com
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com

# Disable host-based authentication
HostbasedAuthentication no

# Increase logging verbosity for security auditing
LogLevel VERBOSE

# Disallow login with empty passwords
PermitEmptyPasswords no
EOL

    echo "Security configurations added to $CONF_FILE."
fi

# Restart the SSH service to apply the changes
echo "Restarting SSH service..."
systemctl restart ssh

echo "SSH service restarted. Configuration complete."
