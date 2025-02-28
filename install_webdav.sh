#!/bin/bash

# Exit on any error
set -e

# Define the username and password
USERNAME="webdavuser"
PASSWORD="yourpassword"  # Set your desired password here

# Define the HTTP and HTTPS ports
HTTP_PORT="5005"
HTTPS_PORT="5006"

# Retrieve the current IP address of the server
DOMAIN_OR_IP=$(hostname -I | awk '{print $1}')

# Update package lists
echo "Updating package lists..."
apt-get update

# Check if lighttpd is installed
if dpkg -l | grep -q "^ii  lighttpd "; then
    echo "lighttpd is already installed."
else
    echo "Installing lighttpd..."
    apt-get install -y lighttpd
fi

# Check if openssl is installed
if dpkg -l | grep -q "^ii  openssl "; then
    echo "openssl is already installed."
else
    echo "Installing openssl..."
    apt-get install -y openssl
fi

# Check if lighttpd-mod-webdav is installed
if dpkg -l | grep -q "^ii  lighttpd-mod-webdav "; then
    echo "lighttpd-mod-webdav is already installed."
else
    echo "Installing lighttpd-mod-webdav..."
    apt-get install -y lighttpd-mod-webdav
fi

# Check if ssl module is installed
if dpkg -l | grep -q "^ii  lighttpd-mod-openssl "; then
    echo "lighttpd-mod-openssl is already installed."
else
    echo "Installing lighttpd-mod-openssl..."
    apt-get install -y lighttpd-mod-openssl
fi

# Enable WebDAV and SSL modules
echo "Enabling WebDAV and SSL modules..."
set +e  # Temporarily disable exit on error
lighty-enable-mod webdav --force
lighty-enable-mod ssl --force
set -e  # Re-enable exit on error

# Create the WebDAV directory
echo "Creating WebDAV directory /webdavdata/..."
mkdir -p /webdavdata/
chown www-data:www-data /webdavdata/

# Generate a self-signed TLS certificate
echo "Generating self-signed TLS certificate..."
CERT_DIR="/etc/lighttpd/certs"
mkdir -p $CERT_DIR
openssl req -new -x509 -keyout $CERT_DIR/lighttpd.pem -out $CERT_DIR/lighttpd.pem -days 3650 -nodes -subj "/CN=$DOMAIN_OR_IP"

# Configure lighttpd to use HTTP on port 5005 and HTTPS on port 5006
echo "Configuring lighttpd to use HTTP on port $HTTP_PORT and HTTPS on port $HTTPS_PORT..."
tee /etc/lighttpd/lighttpd.conf > /dev/null <<EOL
server.modules = (
    "mod_access",
    "mod_alias",
    "mod_compress",
    "mod_redirect",
    "mod_webdav",
    "mod_openssl"
)

# Set the global server document root
server.document-root = "/var/www/html"

# Set up HTTP and HTTPS ports
server.bind = "$DOMAIN_OR_IP"

# Set up the default socket for HTTP
\$SERVER["socket"] == ":$HTTP_PORT" { }

# Set up the socket for HTTPS with TLS/SSL
\$SERVER["socket"] == ":$HTTPS_PORT" {
    ssl.engine  = "enable"
    ssl.pemfile = "$CERT_DIR/lighttpd.pem"
}

# WebDAV configuration for /webdavdata/
\$HTTP["url"] =~ "^/webdav($|/)" {
    webdav.activate = "enable"
    webdav.is-readonly = "disable"
    webdav.sqlite-db-name = "/webdavdata/webdav.db"
    alias.url = ( "/webdav" => "/webdavdata" )
    dir-listing.activate = "enable"
    server.upload-dirs = ( "/var/cache/lighttpd/uploads" )
}

# Optional: Access control (Basic Auth)
auth.backend = "plain"
auth.backend.plain.userfile = "/etc/lighttpd/webdav.htpasswd"
auth.require = ( "/webdav" => ( "method" => "basic", "realm" => "webdav", "require" => "user=$USERNAME" ) )

# Logging
server.errorlog = "/var/log/lighttpd/error.log"
accesslog.filename = "/var/log/lighttpd/access.log"

index-file.names = ( "index.html" )
url.access-deny = ( "~", ".inc" )
EOL

# Create a user for WebDAV access (Basic Auth) and set the password automatically
echo "Setting up Basic Authentication with predefined password..."
if dpkg -l | grep -q "^ii  apache2-utils "; then
    echo "apache2-utils is already installed."
else
    apt-get install -y apache2-utils
fi
echo -n "$USERNAME:" | tee /etc/lighttpd/webdav.htpasswd
echo -n "$PASSWORD" | openssl passwd -apr1 -stdin | tee -a /etc/lighttpd/webdav.htpasswd > /dev/null

# Restart lighttpd to apply changes
echo "Restarting lighttpd service..."
systemctl restart lighttpd

echo "WebDAV setup complete. You can access it via:"
echo " - HTTP:  http://$DOMAIN_OR_IP:$HTTP_PORT/webdav/"
echo " - HTTPS: https://$DOMAIN_OR_IP:$HTTPS_PORT/webdav/"
