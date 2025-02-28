#!/bin/bash

# Paths to the files
FILE_TO_ENCRYPT="example.txt"
ENCRYPTED_FILE="encrypted_file.bin"
DECRYPTED_FILE="decrypted_example.txt"
PUBLIC_KEY="public_key.pem"
PRIVATE_KEY="private_key.pem"
IV_FILE="iv.txt"

# Function to display usage
usage() {
    echo "Usage: $0 -e|-d -i <input_file> -o <output_file> -k <key_file>"
    echo "  -e: Encrypt the file"
    echo "  -d: Decrypt the file"
    echo "  -i: Input file"
    echo "  -o: Output file"
    echo "  -k: Public or Private key file"
    exit 1
}

# Check if at least 1 argument is passed
if [ $# -eq 0 ]; then
    usage
fi

# Parse command-line arguments
while getopts "edi:o:k:" opt; do
    case $opt in
        e)
            MODE="encrypt"
            ;;
        d)
            MODE="decrypt"
            ;;
        i)
            INPUT_FILE="$OPTARG"
            ;;
        o)
            OUTPUT_FILE="$OPTARG"
            ;;
        k)
            KEY_FILE="$OPTARG"
            ;;
        *)
            usage
            ;;
    esac
done

# Check if all required parameters are provided
if [ -z "$MODE" ] || [ -z "$INPUT_FILE" ] || [ -z "$OUTPUT_FILE" ] || [ -z "$KEY_FILE" ]; then
    usage
fi

# Encrypt function
encrypt_file() {
    # Generate a random AES key and IV
    AES_KEY=$(openssl rand -base64 32)
    IV=$(openssl rand -hex 16)

    # Encrypt the AES key using the public RSA key
    echo -n "$AES_KEY" | openssl rsautl -encrypt -pubin -inkey "$KEY_FILE" -out aes_key.enc

    # Encrypt the file using the AES key and IV
    openssl enc -aes-256-cbc -K $(echo -n $AES_KEY | xxd -p) -iv $IV -in "$INPUT_FILE" -out "$OUTPUT_FILE"

    # Save the IV and the encrypted AES key
    echo "$IV" > "$IV_FILE"
    cat aes_key.enc >> "$OUTPUT_FILE"

    # Clean up temporary files
    rm aes_key.enc

    # Zero out the original file
    shred -u "$INPUT_FILE"

    echo "File encrypted and original file securely deleted!"
}

# Decrypt function
decrypt_file() {
    # Extract the IV and encrypted AES key from the encrypted file
    IV=$(head -n 1 "$IV_FILE")
    AES_KEY_ENC=$(tail -c +$(($(wc -l < "$IV_FILE") + 2)) "$INPUT_FILE" | head -c 256)

    # Decrypt the AES key using the private RSA key
    AES_KEY=$(echo "$AES_KEY_ENC" | openssl rsautl -decrypt -inkey "$KEY_FILE")

    # Decrypt the file using the AES key and IV
    openssl enc -d -aes-256-cbc -K $(echo -n $AES_KEY | xxd -p) -iv $IV -in "$INPUT_FILE" -out "$OUTPUT_FILE"

    echo "File decrypted successfully!"
}

# Execute the appropriate function
if [ "$MODE" == "encrypt" ]; then
    encrypt_file
elif [ "$MODE" == "decrypt" ]; then
    decrypt_file
else
    usage
fi




#ENCRYPT: ./file_handling.sh -e -i example.txt -o encrypted_file.bin -k public_key.pem
#DECRYPT: ./file_handling.sh -d -i encrypted_file.bin -o decrypted_example.txt -k private_key.pem

