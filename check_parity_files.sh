#!/bin/bash

# Check if the directory is provided as an argument
if [ -z "$1" ]; then
    echo "Usage: $0 <directory>"
    exit 1
fi

# Get the directory from the first argument
DIRECTORY="$1"

# Output file for the results
OUTPUT_FILE="paritycheck.txt"

# Start a new output file or clear the existing one
echo "Parity Check Results" > "$OUTPUT_FILE"
echo "---------------------" >> "$OUTPUT_FILE"

# Find all .par2 files in the directory and its subdirectories
find "$DIRECTORY" -name '*.par2' | while read PARITY_FILE; do
    echo "Checking parity file: $PARITY_FILE"
    
    # Verify the files using the found parity file
    par2 v "$PARITY_FILE"
    
    # Capture the exit code
    EXIT_CODE=$?
    
    # Write the result to the output file
    if [ $EXIT_CODE -eq 0 ]; then
        echo "Verification successful for: $PARITY_FILE" >> "$OUTPUT_FILE"
        echo "Exit Code: $EXIT_CODE" >> "$OUTPUT_FILE"
    else
        echo "Verification failed for: $PARITY_FILE" >> "$OUTPUT_FILE"
        echo "Exit Code: $EXIT_CODE" >> "$OUTPUT_FILE"
    fi
    
    echo "" >> "$OUTPUT_FILE"
    
    echo "Exit Code: $EXIT_CODE"
    echo
done

echo "Parity file checking completed. Results saved to $OUTPUT_FILE."



#chmod +x check_parity_files.sh
#./check_parity_files.sh /path/to/your/directory
#
#