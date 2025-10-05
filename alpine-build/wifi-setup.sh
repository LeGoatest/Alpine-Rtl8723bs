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