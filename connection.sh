#!/bin/bash

# Define the MariaDB connection parameters
DB_HOST="localhost"
DB_PORT="3306"
DB_USER="testdb"
DB_PASS="testdb"

# Attempt to connect to the MariaDB server
mysql -h $DB_HOST -P $DB_PORT -u $DB_USER -p$DB_PASS -e "EXIT" 2>/dev/null

# Check if the connection was successful
if [ $? -eq 0 ]; then
    echo "1"
else
    echo "0"
fi