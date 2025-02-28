#!/bin/bash

# Define the backup directory
BACKUP_DIR="/var/backups/mariadb"

# Count all *.sql files in the directory
SQL_COUNT=$(find "$BACKUP_DIR" -type f -name "*.sql" | wc -l)

# Save the count in count.txt in the same directory
echo "$SQL_COUNT" > "$BACKUP_DIR/count.txt"
