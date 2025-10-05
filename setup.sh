#!/bin/sh
# This script prepares and runs the ISO build process.

set -e

echo ">>> Preparing the build script..."
chmod +x build-nextbook-iso.sh

echo ">>> Starting the build process..."
./build-nextbook-iso.sh