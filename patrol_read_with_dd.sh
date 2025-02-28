#!/bin/bash

# Run the dd command and capture the output
output=$(dd if=/dev/sda of=/dev/null bs=512 2>&1)

# Extract the relevant lines for both languages
line1=$(echo "$output" | grep -E "records in|Datensätze ein" | head -n 1)
line2=$(echo "$output" | grep -E "records out|Datensätze aus" | head -n 1)

# Compare the lines
if [ "$line1" == "$line2" ]; then
    echo 1
else
    echo 0
fi
