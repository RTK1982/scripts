#!/bin/bash

SMTP_SERVER="$1"
PORTS=("995" "993" "465" "587")

if [ -z "$SMTP_SERVER" ]; then
    echo "Usage: $0 <smtp-server>"
    exit 1
fi

# Function to check a specific port
check_port() {
    local PORT=$1
    local PROTOCOL=$2

    # Run OpenSSL command and capture the output
    OUTPUT=$(openssl s_client -connect ${SMTP_SERVER}:${PORT} -${PROTOCOL} < /dev/null 2>/dev/null)

    if [ $? -ne 0 ]; then
        echo -e "\033[0;31mPORT ${PORT}: CLOSED OR ERROR\033[0m"
    elif echo "$OUTPUT" | grep -q "Verify return code: 0 (ok)"; then
        echo -e "\033[0;32mPORT ${PORT}: SSL certificate chain is correct.\033[0m"
    else
        echo -e "\033[0;31mPORT ${PORT}: SSL certificate chain is broken or not correct!\033[0m"
    fi
}

# Loop through the well-known ports and test them
for PORT in "${PORTS[@]}"; do
    case $PORT in
        995|993) 
            check_port $PORT "tls1_2"
            ;;
        465|587)
            check_port $PORT "starttls smtp"
            ;;
        *)
            echo "Unknown port: $PORT"
            ;;
    esac
done
