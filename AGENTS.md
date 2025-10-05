## Agent Instructions for Custom Alpine ISO Builder

This repository contains a single shell script, `build-nextbook-iso.sh`, designed to create a custom Alpine Linux ISO.

### Primary Goal

The main goal of any task in this repository is to modify or improve the `build-nextbook-iso.sh` script. The script itself is the sole deliverable.

### Development Process

1.  **Understand the Script:** The script automates a complex build process using `docker-abuild` and Alpine's `aports` system. Before making changes, understand how the script pieces together the final ISO.
2.  **Modify the Script Directly:** All changes should be made directly to the `build-nextbook-iso.sh` script. Do not try to run the build steps manually unless you are actively debugging a specific part of the script.
3.  **Self-Contained Script:** The script is designed to be self-contained. It clones all necessary dependencies and creates all required configuration files at runtime. Maintain this principle. Avoid adding other files to the repository unless absolutely necessary.

### Testing and Verification

-   **No Automated Tests:** There are no unit or integration tests.
-   **Verification:** The only way to verify changes is to execute the `build-nextbook-iso.sh` script on a Linux environment with Docker and `sudo` access. Due to the limitations of the current sandbox, it is not possible to run the script here.
-   **Success Criteria:** A successful run is defined by the script completing without errors and the final `.iso` file being present in the `alpine-build/output/` directory.

### Key Challenges

-   **Docker-in-Docker:** The build process relies on running Docker commands to build a Docker image that then builds the ISO. This is complex.
-   **Permissions:** The build requires `sudo` and specific user permissions (`--user root`) inside the container. Be mindful of how commands and environment variables are passed through `sudo`.
-   **File Paths:** Pay close attention to file paths. The build happens inside a container, and paths must be correct relative to the container's filesystem. The final ISO is retrieved via a Docker volume mount.