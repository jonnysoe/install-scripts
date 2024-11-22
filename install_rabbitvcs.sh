#!/bin/bash
# http://wiki.rabbitvcs.org/wiki/install/ubuntu

# Prepare package for distro
packages=()

if [[ -z "`apt list 2> /dev/null | grep rabbitvcs-core | grep installed`" ]]; then
    packages=(rabbitvcs-core)
fi

if [[ -z "`apt list 2> /dev/null | grep rabbitvcs-core | grep installed`" ]]; then
    packages=(rabbitvcs-cli)
fi

if command -v nautilus; then
    if [[ -z "`apt list 2> /dev/null | grep rabbitvcs-nautilus | grep installed`" ]]; then
        packages+=(rabbitvcs-nautilus)
    fi
fi

if command -v thunar; then
    if [[ -z "`apt list 2> /dev/null | grep rabbitvcs-thunar | grep installed`" ]]; then
        packages+=(thunar-vcs-plugin rabbitvcs-thunar)
    fi
fi

# The GEdit plugin don't seem to work on Ubuntu 22.
if command -v gedit; then
    if [[ -z "`apt list 2> /dev/null | grep rabbitvcs-gedit | grep installed`" ]]; then
        packages+=(rabbitvcs-gedit)
    fi
fi

# Install if there are missing packages
if [ ${#packages[@]} -gt 0 ]; then
    # Add ppa
    sudo add-apt-repository -y ppa:rabbitvcs/ppa

    # Install all packages
    sudo apt install -y ${packages[@]}

    # Refresh Desktop Environment
    if command -v nautilus; then
        pkill nautilus
    fi
    pkill gnome-shell
fi