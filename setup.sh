#!/bin/sh
# This script sets up the Jules VM environment by installing Docker.
# It assumes the VM is running Alpine Linux.

set -e

echo ">>> Installing Docker..."

# Update the Alpine package index
apk update

# Install Docker and related tools
apk add docker docker-compose

# Add the Docker service to the default runlevel and start it
rc-update add docker default
rc-service docker start

echo ">>> Docker has been installed and started successfully."
echo ">>> The build environment is now set up."
echo "You can now run the main build script: ./build-nextbook-iso.sh"