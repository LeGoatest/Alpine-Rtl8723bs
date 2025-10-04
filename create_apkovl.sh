#!/bin/sh

set -e

FIRMWARE_URL="https://raw.githubusercontent.com/wkennington/linux-firmware/master/rtlwifi/rtl8723bs_nic.bin"
FIRMWARE_FILE="rtl8723bs_nic.bin"
TMP_DIR="lib"
OUTPUT_FILE="apkovl.tar.gz"

echo "Downloading firmware..."
wget -q "$FIRMWARE_URL" -O "$FIRMWARE_FILE"

echo "Creating directory structure..."
mkdir -p "$TMP_DIR/firmware/rtlwifi"

echo "Moving firmware to correct location..."
mv "$FIRMWARE_FILE" "$TMP_DIR/firmware/rtlwifi/"

echo "Creating apkovl archive..."
tar -czf "$OUTPUT_FILE" "$TMP_DIR"

echo "Cleaning up..."
rm -r "$TMP_DIR"

echo "Successfully created $OUTPUT_FILE"