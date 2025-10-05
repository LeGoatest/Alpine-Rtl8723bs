#!/bin/sh
# This script sets up the build environment for creating the custom Alpine ISO.
# It installs Docker and Git on an Alpine Linux system.
# The script should be run by a user with sudo privileges. It will prompt for a password.

set -e

# 1. Check if sudo is available
if ! command -v sudo > /dev/null; then
	echo "Error: sudo command not found. Please install sudo or run this script as root." >&2
	exit 1
fi

echo ">>> This script requires sudo privileges to install packages."
echo ">>> You may be prompted for your password."

# 2. Update the Alpine package index using sudo
echo ">>> Updating package index..."
sudo apk update

# 3. Install Docker, Docker Compose, and Git using sudo
echo ">>> Installing dependencies (Docker and Git)..."
sudo apk add docker docker-compose git

# 4. Add the Docker service to the default runlevel and start it using sudo
echo ">>> Configuring and starting Docker service..."
sudo rc-update add docker default
sudo rc-service docker start

echo ""
echo ">>> Setup complete!"
echo "Docker and Git have been installed and the Docker service has been started."
echo "The environment is now ready for the build process."
echo "You can now run the main build script: ./build-nextbook-iso.sh"