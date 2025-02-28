#!/bin/bash

# Check if the directory is provided as an argument
if [ -z "$1" ]; then
    echo "Usage: $0 <directory>"
    exit 1
fi

# Get the directory from the first argument
DIRECTORY="$1"

# Iterate over all files in the directory
for FILE in "$DIRECTORY"/*; do
    # Skip if it's not a regular file
    if [ ! -f "$FILE" ]; then
        continue
    fi

    # Generate the base name for the parity file (remove the extension)
    BASENAME=$(basename "$FILE")
    PARITY_FILE="$DIRECTORY/$BASENAME.par2"

    # If a parity file already exists, skip the file
    if [ -f "$PARITY_FILE" ]; then
        echo "Parity file already exists, skipping: $PARITY_FILE"
        continue
    fi

    # Create a new parity file with 15% redundancy and 10 recovery blocks
    echo "Creating parity file for: $FILE"
    par2 c -r25 -n15 "$PARITY_FILE" "$FILE"
done

echo "Parity file creation complete for all files in $DIRECTORY."


#chmod +x create_parity_files.sh
#./create_parity_files.sh /path/to/your/directory