#!/bin/bash

# Function to add a package to the apt-mark hold list
hold_package() {
    apt-mark hold "$1"
}

# Check if the script is being run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root."
  exit 1
fi

# Hold Docker packages to prevent updates from the repository
hold_package docker-ce
hold_package docker-ce-cli
hold_package containerd.io
hold_package docker-compose

# Update the package list
apt-get update

# Uninstall any old versions of Docker, Docker-Compose, and Portainer
apt-get remove -y docker docker-engine docker.io containerd runc

# Install prerequisites
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker's official GPG key (for Ubuntu)
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Set up the stable repository for Docker (for Ubuntu)
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update the package list again to include Docker packages from Docker's repository
apt-get update

# Install Docker Engine
apt-get install -y docker-ce docker-ce-cli containerd.io

# Verify that Docker is installed correctly
docker --version

# Initialize Docker Swarm (ignore error if already initialized)
docker swarm init || true

# Install Docker-Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# Apply executable permissions to the binary
chmod +x /usr/local/bin/docker-compose

# Verify that Docker-Compose is installed correctly
docker-compose --version

# Install Portainer (in Swarm mode)
docker volume create portainer_data
docker service create --name portainer \
    --publish 8000:8000 --publish 9443:9443 \
    --replicas=1 \
    --constraint 'node.role == manager' \
    --mount type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
    --mount type=volume,src=portainer_data,dst=/data \
    portainer/portainer-ce:latest

# Verify that Portainer is running
docker service ls | grep portainer

echo "Docker, Docker-Compose, Docker Swarm, and Portainer have been installed successfully."
