#!/bin/bash

# Default values
SNMP_USER="monitoring"
SNMP_AUTH_PASS="monitoring"
SNMP_PRIV_PASS="monitoring"
SNMP_AUTH_ALGO="SHA-256"
SNMP_PRIV_ALGO="AES-256"

# Parse command-line arguments
while getopts u:a:p:x:y: flag
do
    case "${flag}" in
        u) SNMP_USER=${OPTARG};;
        a) SNMP_AUTH_PASS=${OPTARG};;
        p) SNMP_PRIV_PASS=${OPTARG};;
        x) SNMP_AUTH_ALGO=${OPTARG};;
        y) SNMP_PRIV_ALGO=${OPTARG};;
        *) echo "Usage: $0 [-u user] [-a auth_password] [-p priv_password] [-x auth_algo] [-y priv_algo]"; exit 1;;
    esac
done

# SNMP configuration file
SNMP_CONF="/etc/snmp/snmpd.conf"

# Backup existing SNMP configuration file
cp $SNMP_CONF ${SNMP_CONF}.bak

# Add SNMPv3 user with specified algorithms to the configuration
cat <<EOF >> $SNMP_CONF

# SNMPv3 user configuration
createUser $SNMP_USER $SNMP_AUTH_ALGO $SNMP_AUTH_PASS $SNMP_PRIV_ALGO $SNMP_PRIV_PASS
rouser $SNMP_USER priv
EOF

# Restart SNMP service to apply changes
systemctl restart snmpd

echo "SNMPv3 user '$SNMP_USER' created with $SNMP_AUTH_ALGO authentication and $SNMP_PRIV_ALGO encryption."