#!/bin/bash

# Usage: ./generate_cert.sh "<DN_and_CN>"
# Example: ./generate_cert.sh "localhost"

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 \"<DN_and_CN>\""
  exit 1
fi

DN_CN=$1
SUBJECT="/CN=${DN_CN}"

# Create the nginx directory if it doesn't exist
echo "Generating certificate with subject: ${SUBJECT}"

openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout ./server.key -out ./server.crt -subj "/C=CH/ST=BE/L=Bern/O=IT Service/OU=IT/CN=localhost" -addext "basicConstraints=critical,CA:TRUE,pathlen:0" -addext "keyUsage=critical,digitalSignature,keyCertSign,cRLSign,keyEncipherment,dataEncipherment,keyAgreement" -addext "extendedKeyUsage=serverAuth,clientAuth,ipsecEndSystem,ipsecTunnel,ipsecUser,1.3.6.1.4.1.311.54.1.2" -addext "subjectAltName = DNS:localhost.loc,IP:127.0.0.1" -addext "certificatePolicies = 1.2.3.4"
