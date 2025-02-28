#!/bin/bash

# Set to ignore errors
set +e

# Stop the lighttpd service
echo "Stopping lighttpd service..."
systemctl stop lighttpd

# Uninstall lighttpd and related packages
echo "Uninstalling lighttpd and related packages..."
apt-get remove --purge -y lighttpd lighttpd-mod-webdav lighttpd-mod-openssl apache2-utils openssl

# Remove the lighttpd configuration directory
echo "Removing lighttpd configuration directory..."
rm -rf /etc/lighttpd

# Remove the WebDAV data directory
echo "Removing WebDAV data directory..."
rm -rf /webdavdata

# Remove the SSL certificate directory
echo "Removing SSL certificate directory..."
rm -rf /etc/lighttpd/certs

# Remove the log files
echo "Removing lighttpd log files..."
rm -rf /var/log/lighttpd

# Clean up unused dependencies
echo "Cleaning up unused dependencies..."
apt-get autoremove -y

# Verify removal
echo "Verifying removal of lighttpd..."
dpkg -l | grep lighttpd

echo "Uninstallation complete."
