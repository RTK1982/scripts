#!/bin/bash

# Function to display usage instructions
usage() {
    echo "Usage: $0 -f <folder_path> -o <output_directory>"
    exit 1
}

# Parse command-line arguments
while getopts "f:o:" opt; do
    case $opt in
        f) FOLDER_PATH="$OPTARG" ;;
        o) OUTPUT_DIR="$OPTARG" ;;
        *) usage ;;
    esac
done

# Check if both parameters were provided
if [ -z "$FOLDER_PATH" ] || [ -z "$OUTPUT_DIR" ]; then
    usage
fi

# Ensure the output directory exists
mkdir -p "$OUTPUT_DIR"

# Get the current date
DATE=$(date +'%Y-%m-%d')

# Extract the base folder name and format it
FOLDER_NAME=$(basename "$FOLDER_PATH" | sed 's/[\/]/_/g')

# Generate the checksums file with the folder path in the filename
OUTPUT_FILE="$OUTPUT_DIR/${FOLDER_NAME}_checksums_$DATE.md5"
find "$FOLDER_PATH" -type f -exec md5sum {} + > "$OUTPUT_FILE"

echo "Checksums have been saved to $OUTPUT_FILE"