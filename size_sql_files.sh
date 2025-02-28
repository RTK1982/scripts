#!/bin/bash

# Define the backup directory
BACKUP_DIR="/var/backups/mariadb"

# Calculate the total size of all *.sql files in the directory in kilobytes
TOTAL_SIZE=$(find "$BACKUP_DIR" -type f -name "*.sql" -exec du -k {} + | awk '{sum += $1} END {print sum}')

# Output the total size in kilobytes to the terminal (without "KB" suffix)
echo "$TOTAL_SIZE"

# Save the total size in size.txt in the same directory (without "KB" suffix)
echo "$TOTAL_SIZE" > "$BACKUP_DIR/size.txt"