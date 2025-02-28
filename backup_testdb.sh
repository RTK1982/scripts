#!/bin/bash

# Set the variables
BACKUP_DIR="/var/backups/mariadb"
DB_NAME="testdb"
USER="root"
PASSWORD="UNIstdPW.2022"
TIMESTAMP=$(date +"%F_%H-%M-%S")
BACKUP_FILE="$BACKUP_DIR/${DB_NAME}_$TIMESTAMP.sql"

# Ensure the backup directory exists
mkdir -p $BACKUP_DIR

# Perform the backup
mysqldump -u $USER -p$PASSWORD --all-databases > $BACKUP_FILE

# Optionally, you can compress the backup to save space
# gzip $BACKUP_FILE