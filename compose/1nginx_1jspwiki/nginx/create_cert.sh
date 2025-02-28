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

openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout ./server.key -out ./server.crt -subj "${SUBJECT}"
