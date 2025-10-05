#!/bin/sh

# This script automates the process of building a custom Alpine Linux ISO
# for the Nextbook device, including the LXQt desktop, Wi-Fi firmware,
# and a custom wallpaper.
#
# Requirements:
# - A Linux environment with Docker and Git installed.
# - Sudo privileges to run Docker commands.
#
# Instructions:
# 1. Save this script as build-nextbook-iso.sh
# 2. Make it executable: chmod +x build-nextbook-iso.sh
# 3. Run it: ./build-nextbook-iso.sh

set -e

echo ">>> Setting up the build environment..."

# 1. Clean up previous builds and create the main directory
rm -rf alpine-build
mkdir alpine-build
cd alpine-build

# 2. Clone the required Alpine repositories
echo ">>> Cloning Alpine aports and docker-abuild repositories..."
git clone --depth=1 https://gitlab.alpinelinux.org/alpine/aports.git
git clone --depth=1 https://gitlab.alpinelinux.org/alpine/docker-abuild.git

# 3. Create the custom ISO profile: mkimg.nextbook.sh
echo ">>> Creating custom ISO profile..."
cat << 'EOF' > aports/scripts/mkimg.nextbook.sh
profile_nextbook() {
	profile_standard
	modloop_sign=no
	title="Nextbook LXQt"
	desc="Alpine with LXQt, configured for the Nextbook tablet."
	profile_abbrev="nextbook"
	image_name="geitalpine-3.22.1-x86.iso"
	arch="x86_64"
	apks="$apks
		# Core desktop
		xorg-server
		sddm
		lxqt-desktop
		lxterminal
		elogind

		# Recommended LXQt apps
		lximage-qt
		pavucontrol-qt
		arandr
		obconf-qt
		screengrab

		# Basic user applications
		firefox
		font-dejavu
		"

	# Create directories in the apkovl overlay
	mkdir -p "$apkovl_dir"/lib/firmware/rtlwifi
	mkdir -p "$apkovl_dir"/etc/modules-load.d
	mkdir -p "$apkovl_dir"/usr/share/backgrounds
	mkdir -p "$apkovl_dir"/etc/xdg/pcmanfm-qt/lxqt
	mkdir -p "$apkovl_dir"/usr/local/bin
	mkdir -p "$apkovl_dir"/etc/xdg/autostart

	# Download the rtl8723bs firmware
	wget https://git.codelinaro.org/clo/qsdk/linux-firmware/-/raw/caf_migration/korg/master/rtlwifi/rtl8723bs_nic.bin \
		-O "$apkovl_dir"/lib/firmware/rtlwifi/rtl8723bs_nic.bin

	# Configure the rtl8723bs kernel module to load on boot
	echo "rtl8723bs" > "$apkovl_dir"/etc/modules-load.d/rtl8723bs.conf

	# Download the wallpaper
	wget https://factanimal.com/wp-content/uploads/2022/07/alpine-ibex-facts.jpg \
		-O "$apkovl_dir"/usr/share/backgrounds/alpine-ibex.jpg

	# Set the default wallpaper
	echo "[Desktop]" > "$apkovl_dir"/etc/xdg/pcmanfm-qt/lxqt/settings.conf
	echo "wallpaper=/usr/share/backgrounds/alpine-ibex.jpg" >> "$apkovl_dir"/etc/xdg/pcmanfm-qt/lxqt/settings.conf

	# Copy and configure the Wi-Fi setup script
	cp wifi-setup.sh "$apkovl_dir"/usr/local/bin/wifi-setup.sh
	chmod +x "$apkovl_dir"/usr/local/bin/wifi-setup.sh

	# Create autostart entry for the Wi-Fi script
	echo "[Desktop Entry]" > "$apkovl_dir"/etc/xdg/autostart/wifi-setup.desktop
	echo "Name=Wi-Fi Setup" >> "$apkovl_dir"/etc/xdg/autostart/wifi-setup.desktop
	echo "Exec=/usr/local/bin/wifi-setup.sh" >> "$apkovl_dir"/etc/xdg/autostart/wifi-setup.desktop
	echo "Type=Application" >> "$apkovl_dir"/etc/xdg/autostart/wifi-setup.desktop
}
EOF

# 4. Create the interactive Wi-Fi setup script
echo ">>> Creating interactive Wi-Fi setup script..."
cat << 'EOF' > aports/scripts/wifi-setup.sh
#!/bin/sh
# This script is run on startup to configure the Wi-Fi connection.
SSID="GNet"
# Open a terminal and prompt for the password
lxterminal -t "Wi-Fi Setup" -e /bin/sh -c "
	echo 'Please enter the password for the Wi-Fi network: $SSID'
	read -s -p 'Password: ' password
	echo
	# Generate the wpa_supplicant configuration
	wpa_passphrase '$SSID' \"\$password\" >> /etc/wpa_supplicant/wpa_supplicant.conf
	# Connect to the network
	wpa_supplicant -B -i wlan0 -c /etc/wpa_supplicant/wpa_supplicant.conf
	udhcpc -i wlan0
	echo 'Wi-Fi setup complete. You can close this window.'
	read -p 'Press Enter to close...'
"
EOF

# 5. Prepare the docker-abuild environment
echo ">>> Preparing docker-abuild environment..."
cd docker-abuild
make
# Remove interactive flags that prevent non-interactive execution
sed -i 's/--tty --interactive/ /' dabuild
cd ..

# 6. Run the build
echo ">>> Starting the ISO build process. This may take a long time..."
cd aports/scripts

# The final, fully corrected build command
sudo DABUILD_ARGS="--entrypoint sh --user root" ../../docker-abuild/dabuild -c \
"./mkimage.sh \
--profile nextbook \
--repository http://dl-cdn.alpinelinux.org/alpine/edge/main \
--repository http://dl-cdn.alpinelinux.org/alpine/edge/community \
--outdir /home/builder/packages"

cd ../..

echo ""
echo ">>> Build complete!"
echo "Your custom ISO should be located in: alpine-build/packages/edge/x86_64/"
echo "File: geitalpine-3.22.1-x86.iso"
ls -l alpine-build/packages/edge/x86_64/