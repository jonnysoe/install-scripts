#!/bin/bash
function install_ovpn() {
    OVPNS=(`ls *.ovpn`)
    for OVPN in "${OVPNS[@]}"; do
        VPN_NAME=${OVPN%.*}
        NMCONNECTION=/etc/NetworkManager/system-connections/${VPN_NAME}.nmconnection
        if [[ -f ${NMCONNECTION} ]]; then
            echo "Skipped: ${VPN_NAME} was already added (${NMCONNECTION})"
        else
            echo "Adding `realpath ${VPN_NAME}`..."

            # https://computingforgeeks.com/nmcli-connect-to-openvpn-server/
            sudo nmcli connection import type openvpn file ${OVPN} || return

            # alternatively use: openvpn --config <file>
            # https://www.cactusvpn.com/tutorials/how-to-set-up-openvpn-ubuntu-command-line/
        fi
    done
}

# Stop user from running the script as root as there are commands that uses sudo explicitly!
# https://stackoverflow.com/a/28776100
if [ `id -u` -eq 0 ]
    then echo "Do not run as sudo/root!"
    exit 1
fi

pushd ~/Downloads > /dev/null

# Download BulletVPN configuration files
# https://support.bulletvpn.com/hc/en-us/articles/115004463909-How-to-Set-up-BulletVPN-OpenVPN-Manually-on-Ubuntu-Linux
if [[ ! -f BulletVPN-OpenVPN.zip ]]; then
    echo "Downloading BulletVPN-OpenVPN.zip..."
    wget -O BulletVPN-OpenVPN.zip 'https://www.bulletvpn.com/account/download/BulletVPN-OpenVPN.zip'
fi
if [[ -f BulletVPN-OpenVPN.zip ]]; then
    echo "Extracting BulletVPN-OpenVPN.zip..."
    unzip -u BulletVPN-OpenVPN.zip -d BulletVPN-OpenVPN
fi

# Add all BulletVPN configurations
pushd BulletVPN-OpenVPN > /dev/null
install_ovpn
RETURN_ERROR=$?
popd > /dev/null

popd > /dev/null
exit ${RETURN_ERROR}