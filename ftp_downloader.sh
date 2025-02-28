#!/bin/bash

# Check if the required parameters are provided
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <ftp_url> <local_directory> <zip_filename>"
    echo "Example: $0 ftp://example.com/path/to/file.zip /diag file.zip"
    exit 1
fi

# Assign parameters to variables
FTP_SERVER="$1"
LOCAL_DIR="$2"
ZIP_FILE="$LOCAL_DIR/$3"

# Step 1: Download the ZIP file from the FTP server
echo "Downloading ZIP file from FTP server..."
curl -o "$ZIP_FILE" "$FTP_SERVER"

# Step 2: Unpack the contents of the ZIP file to the specified directory
echo "Unpacking ZIP file to $LOCAL_DIR..."
mkdir -p "$LOCAL_DIR"
unzip -o "$ZIP_FILE" -d "$LOCAL_DIR"

# Step 3: Set read and execute permissions for everyone on every file in the specified directory
echo "Setting read and execute permissions for all files in $LOCAL_DIR..."
chmod -R a+rx "$LOCAL_DIR"

# Clean up the downloaded ZIP file
echo "Cleaning up the downloaded ZIP file..."
rm "$ZIP_FILE"

echo "Operation completed successfully."
