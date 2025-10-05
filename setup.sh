#!/bin/sh
# This script performs a basic setup check for the Jules development environment.
# It prints user, location, and project file information.

echo ">>> Initializing Jules Environment Setup..."
echo ""

echo "--- User Information ---"
echo "Current User: $(whoami)"
echo ""

echo "--- Location Information ---"
echo "Working Directory: $(pwd)"
echo ""

echo "--- Project Files ---"
ls -laF

echo ""
echo ">>> Environment setup check complete."