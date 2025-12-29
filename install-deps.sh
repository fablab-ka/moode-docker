#!/bin/bash
set -e

# File paths
STAGE2_LIST="/tmp/moode-cfg/stage2_04-moode-install_01-packages"
STAGE3_LIST="/tmp/moode-cfg/stage3_01-moode-install_01-packages"

# Packages to exclude (Hardware specific, Kernel, Custom Moode pkgs not in Debian)
EXCLUDE_LIST=(
    "rpi-update"
    "raspberrypi-bootloader"
    "raspberrypi-kernel"
    "libraspberrypi-bin"
    "libraspberrypi0"
    "pi-bluetooth"
    "bluez-firmware"
    "firmware-*"
    "linux-image-*"
    "alsa-cdsp"
    "alsacap"
    "ashuffle"
    "boss2-oled-p3"
    "camilladsp"
    "camillagui"
    "caps"
    "librespot"
    "libupnpp16"
    "libnpupnp13"
    "log2ram"
    "mpd2cdspvolume"
    "nqptp"
    "peppy-alsa"
    "peppy-meter"
    "peppy-spectrum"
    "pleezer"
    "python3-camilladsp-plot"
    "python3-camilladsp"
    "python3-libupnpp"
    "shairport-sync-metadata-reader"
    "shairport-sync"
    "squeezelite"
    "trx"
    "udisks-glue"
    "udisks"
    "upmpdcli-qobuz"
    "upmpdcli-tidal"
    "upmpdcli"
    "moode-player"
    "python3-rpi.gpio"
    "chromium" # Often problematic in Docker, install manually if needed
    "chromium-browser"
    "xinit"
    "xorg"
    "wifi-connect"
)

# Function to clean and filter list
get_packages() {
    local list_file="$1"
    grep -vE '^\s*#' "$list_file" | grep -vE '^\s*$' | while read -r pkg; do
        # Remove version constraints (e.g., pkg=1.2.3)
        pkg_name=$(echo "$pkg" | cut -d'=' -f1)
        
        # Check exclusion
        skip=0
        for exclude in "${EXCLUDE_LIST[@]}"; do
            if [[ "$pkg_name" == $exclude* ]]; then
                skip=1
                break
            fi
        done
        
        if [ $skip -eq 0 ]; then
            echo "$pkg_name"
        fi
    done
}

echo "Extracting packages from $STAGE2_LIST and $STAGE3_LIST..."

PACKAGES_STAGE2=$(get_packages "$STAGE2_LIST")
PACKAGES_STAGE3=$(get_packages "$STAGE3_LIST")

ALL_PACKAGES="$PACKAGES_STAGE2 $PACKAGES_STAGE3"

# Dedup
SORTED_PACKAGES=$(echo "$ALL_PACKAGES" | tr ' ' '\n' | sort -u | tr '\n' ' ')

echo "Installing packages: $SORTED_PACKAGES"

# Install
# We use || true for the bulk install in case one fails, but ideally we should be precise.
# To be safe, we can try to install them one by one or in batches, or just fail if one is missing.
# For now, let's try bulk and fail on error.
apt-get update
apt-get install -y --no-install-recommends $SORTED_PACKAGES
