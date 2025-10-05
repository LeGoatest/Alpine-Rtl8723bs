#!/bin/bash
set -e

# =================================================================================
# == Alpine Linux Custom ISO Build Script (v3)
# =================================================================================
#
# This script builds a fully custom Alpine Linux ISO using Docker and the official
# Alpine `aports` build system. This is the correct and recommended method for
# creating a reproducible, customized Alpine ISO.
#
# REQUIREMENTS:
#   - Docker must be installed and running.
#   - The user running the script must have permission to run Docker.
#   - ~5GB of free disk space for the build process.
#
# USAGE:
#   1. Review and adjust the variables in the "USER CONFIGURATION" section.
#   2. Make the script executable: `chmod +x build_iso.sh`
#   3. Run the script: `./build_iso.sh`
#
# The script will prompt you for your Wi-Fi password for security.
# The final ISO will be created in the 'iso_output' directory.
#
# =================================================================================
# == USER CONFIGURATION
# =================================================================================

# --- Profile Name ---
# This defines the name for your custom profile and the final ISO file.
readonly PROFILE_NAME="nextbook-lxqt"

# --- Packages ---
# A list of packages to include in the ISO. LXDM is the display manager for LXQt.
# Find packages at: https://pkgs.alpinelinux.org/packages
readonly ALPINE_PACKAGES=(
    "alpine-base"
    "lxqt"
    "lxdm"
    "firefox-esr"
    "htop"
    "wpa_supplicant"
    "linux-firmware" # Includes a wide range of firmware
)

# --- Wi-Fi Network ---
# Your Wi-Fi Network Name (SSID). You will be prompted for the password.
readonly WIFI_SSID="GNet"

# --- System Settings ---
readonly KEYBOARD_LAYOUT="us"
readonly TIMEZONE="UTC"
readonly KERNEL_MODULES_TO_LOAD="rtl8723bs"

# --- Firmware ---
# The specific firmware file for the Nextbook's Wi-Fi.
readonly FIRMWARE_URL="https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/plain/rtl_bt/rtl8723bs_nic.bin"
readonly FIRMWARE_TARGET_PATH="lib/firmware/rtl_bt/rtl8723bs_nic.bin"

# =================================================================================
# == SCRIPT LOGIC - DO NOT EDIT BELOW THIS LINE
# =================================================================================

# --- Setup ---
readonly WORK_DIR="build_work"
readonly OUTPUT_DIR="iso_output"
readonly CUSTOM_FILES_DIR="$WORK_DIR/custom_files_for_overlay"

echo "==> Starting Alpine ISO Build for profile: $PROFILE_NAME"

# Check for Docker
if ! command -v docker &> /dev/null; then
    echo "ERROR: Docker is not installed. Please install it to continue."
    exit 1
fi

# Securely get Wi-Fi password
read -s -p "Please enter the password for Wi-Fi network '$WIFI_SSID': " WIFI_PSK
echo ""
if [ -z "$WIFI_PSK" ]; then
    echo "ERROR: Password cannot be empty."
    exit 1
fi

# --- Cleanup and Directory Setup ---
echo "==> Cleaning up previous build artifacts..."
rm -rf "$WORK_DIR" "$OUTPUT_DIR"
mkdir -p "$WORK_DIR" "$OUTPUT_DIR" "$CUSTOM_FILES_DIR"
mkdir -p "$CUSTOM_FILES_DIR/etc/apk"
mkdir -p "$CUSTOM_FILES_DIR/etc/wpa_supplicant"
mkdir -p "$CUSTOM_FILES_DIR/etc/modules-load.d"
mkdir -p "$CUSTOM_FILES_DIR/$(dirname "$FIRMWARE_TARGET_PATH")"

# --- Create Custom Files for Overlay ---
echo "==> Generating custom configuration files..."

# 1. Packages to install
printf "%s\n" "${ALPINE_PACKAGES[@]}" > "$CUSTOM_FILES_DIR/etc/apk/world"

# 2. Kernel module to load on boot
echo "$KERNEL_MODULES_TO_LOAD" > "$CUSTOM_FILES_DIR/etc/modules-load.d/custom.conf"

# 3. Wi-Fi Configuration
cat > "$CUSTOM_FILES_DIR/etc/wpa_supplicant/wpa_supplicant.conf" <<EOF
ctrl_interface=/var/run/wpa_supplicant
ctrl_interface_group=wheel
network={
    ssid="$WIFI_SSID"
    psk="$WIFI_PSK"
}
EOF

# 4. Download custom firmware
echo "==> Downloading required firmware..."
if ! curl -L -o "$CUSTOM_FILES_DIR/$FIRMWARE_TARGET_PATH" "$FIRMWARE_URL"; then
    echo "ERROR: Failed to download firmware. Please check URL."
    exit 1
fi

# --- Create `genapkovl-custom.sh` script ---
# This script is executed by `mkimage.sh` inside the container to build the overlay.
cat > "$WORK_DIR/genapkovl-$PROFILE_NAME.sh" <<'EOF'
#!/bin/sh
set -e
# This script is run by mkimage.sh to create the apkovl.
# It copies files from /custom_files (mounted from the host) into the overlay.
# It also enables services that should start on boot.
# Copy all pre-made custom files into the overlay temp directory
cp -r /custom_files/* "$tmp/"
# Set correct file permissions
makefile root:root 0644 "$tmp"/etc/apk/world
makefile root:root 0600 "$tmp"/etc/wpa_supplicant/wpa_supplicant.conf
# Enable services to start at boot
rc_add networking boot
rc_add wpa_supplicant boot
rc_add lxdm boot
EOF
chmod +x "$WORK_DIR/genapkovl-$PROFILE_NAME.sh"

# --- Create Profile Script ---
# This is the main recipe for `mkimage.sh`.
echo "==> Creating custom mkimage profile..."
cat > "$WORK_DIR/mkimg.$PROFILE_NAME.sh" <<EOF
profile_$PROFILE_NAME() {
    profile_standard
    kernel_cmdline="console=tty0"
    apks="\$apks $(echo "${ALPINE_PACKAGES[@]}")"
    apkovl="/aports/scripts/genapkovl-$PROFILE_NAME.sh"
    hostname="$PROFILE_NAME"
    timezone="$TIMEZONE"
    keymap="$KEYBOARD_LAYOUT"
}
EOF

# --- Build the ISO using Docker ---
echo "==> Pulling the latest Alpine image..."
docker pull alpine:latest

echo "==> Building the custom ISO inside a Docker container... (This may take several minutes)"
docker run --rm \
    -v "$(pwd)/$WORK_DIR":/work \
    -v "$(pwd)/$CUSTOM_FILES_DIR":/custom_files \
    -v "$(pwd)/$OUTPUT_DIR":/output \
    alpine:latest /bin/sh -ce "
        set -e
        echo '==> (Container) Installing build tools...'
        apk add --no-cache git abuild alpine-conf syslinux xorriso squashfs-tools grub mtools

        echo '==> (Container) Cloning aports tree...'
        git clone --depth=1 https://gitlab.alpinelinux.org/alpine/aports.git /aports

        echo '==> (Container) Creating build user and signing keys...'
        adduser -D builder
        addgroup builder abuild
        chown builder:abuild /aports
        su builder -c 'abuild-keygen -a -n'

        echo '==> (Container) Copying custom build scripts into aports...'
        cp /work/mkimg.$PROFILE_NAME.sh /aports/scripts/
        cp /work/genapkovl-$PROFILE_NAME.sh /aports/scripts/

        echo '==> (Container) Running mkimage.sh...'
        cd /aports/scripts
        ./mkimage.sh \\
            --tag edge \\
            --outdir /output \\
            --arch x86_64 \\
            --repository http://dl-cdn.alpinelinux.org/alpine/edge/main \\
            --profile $PROFILE_NAME
    "

# --- Finalize ---
echo ""
echo "=================================================================="
echo "== Build Complete!"
echo "=================================================================="
echo ""
ISO_FILE=$(find "$OUTPUT_DIR" -name "*.iso" | head -n 1)
if [ -f "$ISO_FILE" ]; then
    echo "Custom ISO created at: $ISO_FILE"
    echo "You can now burn this file to a USB drive and boot your Nextbook."
    # Clean up password variable
    unset WIFI_PSK
else
    echo "ERROR: ISO file not found. The build may have failed. Check logs above."
    # Clean up password variable
    unset WIFI_PSK
    exit 1
fi
echo "=================================================================="

exit 0