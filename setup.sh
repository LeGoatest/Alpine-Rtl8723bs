#!/bin/sh
# This script sets up the Jules VM environment by installing Docker and Git.
# It assumes the VM is running Alpine Linux and requires root privileges.

set -e

# 1. Check for root privileges
if [ "$(id -u)" -ne 0 ]; then
	echo "This script must be run as root. Please use sudo or log in as the root user." >&2
	exit 1
fi

echo ">>> Installing dependencies (Docker and Git)..."

# 2. Update the Alpine package index
apk update

# 3. Install Docker, Docker Compose, and Git
apk add docker docker-compose git

# 4. Add the Docker service to the default runlevel and start it
echo ">>> Configuring and starting Docker service..."
rc-update add docker default
rc-service docker start

echo ""
echo ">>> Setup complete!"
echo "Docker and Git have been installed and the Docker service has been started."
echo "The environment is now ready for the build process."
echo "You can now run the main build script: ./build-nextbook-iso.sh"