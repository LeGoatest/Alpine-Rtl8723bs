# Custom Alpine Linux ISO Builder for Nextbook

This project provides a single, self-contained shell script to build a custom Alpine Linux ISO tailored for the Nextbook (NXW9QC132) tablet. The resulting ISO is designed to be lightweight and functional on low-specification hardware.

## Features

The custom ISO includes:
- **Alpine Linux (Edge Branch):** A modern, lightweight base system.
- **LXQt Desktop Environment:** A fast and resource-efficient desktop.
- **Realtek RTL8723BS Wi-Fi:** Includes the necessary firmware (`rtl8723bs_nic.bin`) and kernel module configuration for the Nextbook's Wi-Fi card.
- **Interactive Wi-Fi Setup:** On first boot, a terminal window will open, prompting the user to enter the password for the "GNet" network.
- **Custom Wallpaper:** A scenic image of an Alpine Ibex is set as the default desktop background.
- **Essential Applications:** Includes Firefox for web browsing.

## Requirements

To run the build script, you will need:
- A Linux-based operating system.
- **Docker:** The build process is containerized for a clean and reproducible environment.
- **Git:** Required to clone the Alpine Linux build repositories.
- **Sudo / Root Privileges:** Necessary to run Docker commands.

## How to Build the ISO

1.  **Download the Script:**
    Save the `build-nextbook-iso.sh` script to your local machine.

2.  **Make it Executable:**
    Open a terminal and run the following command:
    ```sh
    chmod +x build-nextbook-iso.sh
    ```

3.  **Run the Build Script:**
    Execute the script with `sudo` or as a user with Docker privileges:
    ```sh
    ./build-nextbook-iso.sh
    ```

The script will handle everything:
- It cleans up any previous build attempts.
- It clones the latest Alpine `aports` and `docker-abuild` repositories.
- It generates all necessary configuration files on the fly.
- It runs the containerized build process.

The build process can take a significant amount of time, depending on your internet connection and machine's performance.

## Output

When the script finishes, you will find the custom ISO image in the following location:
`alpine-build/output/geitalpine-3.22.1-x86.iso`

You can then use this ISO file to create a bootable USB drive using a tool like `dd`, Balena Etcher, or Rufus.

## Troubleshooting

-   **Permission Denied for Docker:** If you see an error related to the Docker daemon socket, ensure you are running the script with `sudo` or that your user is part of the `docker` group.
-   **Build Failures:** The script is designed to be robust, but network issues or changes in the upstream Alpine repositories could cause failures. If the build fails, you can simply re-run the script. It will start from a clean state.
-   **Wi-Fi Not Working:** Double-check that the `rtl8723bs` is the correct module for your device. The firmware is included, but hardware variations can exist.