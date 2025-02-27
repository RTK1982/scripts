#!/usr/bin/env bash
#
# install-tailscale.sh
# Installs Tailscale on Ubuntu 22.x and brings it up.
# Usage:
#   chmod +x install-tailscale.sh
#   ./install-tailscale.sh

set -e

echo "==> Updating apt and installing prerequisites..."
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl

echo "==> Adding Tailscale’s GPG key..."
curl -fsSL https://tailscale.com/gpg.key \
  | sudo gpg --dearmor -o /usr/share/keyrings/tailscale-archive-keyring.gpg

echo "==> Adding Tailscale’s stable repository for Ubuntu 22.x (jammy)..."
# If you're on Ubuntu 22.04 "jammy," lsb_release -cs should return "jammy".
# Adjust manually if needed (e.g., 'jammy' is correct for 22.04).
echo "deb [signed-by=/usr/share/keyrings/tailscale-archive-keyring.gpg] \
https://pkgs.tailscale.com/stable/ubuntu \
$(lsb_release -cs) main" \
  | sudo tee /etc/apt/sources.list.d/tailscale.list

echo "==> Updating apt to include Tailscale’s repo..."
sudo apt-get update

echo "==> Installing Tailscale..."
sudo apt-get install -y tailscale

echo "==> Enabling Tailscale service to start on boot..."
sudo systemctl enable tailscale

echo "==> Bringing Tailscale up..."
# This command will print out a URL; paste it into a browser to authenticate.
sudo tailscale up

echo "==> Tailscale is running!"
echo "You can check status with:  tailscale status"
