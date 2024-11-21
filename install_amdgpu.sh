#!/bin/bash

function install_amdgpu_deb() {
    pushd ~/Downloads > /dev/null

    # https://www.amd.com/en/support/download/linux-drivers.html
    sudo apt update && sudo apt upgrade -y

    if [[ -z "`apt list 2>/dev/null | grep amdgpu-install/now | grep installed`" ]]; then
        # Install gdebi to automatically install deb dependencies, it only depends on `rsync` for now
        if [[ -z "`apt list 2>/dev/null | grep gdebi | grep installed`" ]]; then
            sudo apt install -y gdebi
        fi

        # Even debian uses ubuntu deb files, they are essentially the same anyway, whether using focal or jammy
        # You can check with `dpkg-deb --info`
        if [[ ! -v UBUNTU_CODENAME ]]; then
            UBUNTU_CODENAME=jammy
        fi

        local link=https://repo.radeon.com/amdgpu-install/6.2.4/ubuntu/${UBUNTU_CODENAME}/amdgpu-install_6.2.60204-1_all.deb

        if ! wget --spider ${link} > /dev/null 2>&1; then
            echo "Current Ubuntu version (${UBUNTU_CODENAME}) is not supported!"
            return 2
        fi

        local package=`basename ${link}`
        if [[ ! -f ${package} ]]; then
            wget ${link}
        fi

        if [[ ! -f ${package} ]]; then
            echo "Installer Download failed!"
            return 3
        fi
        sudo gdebi -n ./${package}

        # Cleanup

    fi


    if [[ -z "`cat /usr/bin/amdgpu-install | grep ${ID}`" ]]; then
        # If current ID is not available, try parents if available
        local parents=(${ID_LIKE})
        for parent in ${parents[@]}; do
            # This regex detects for example if parent is "ubuntu", it looks for "ubuntu)", "ubuntu|debian)" or anything in between
            # Basically a hack for most of Ubuntu and Debian derivative OS like Zorin, Elementary OS, Pop!_OS
            # @todo fixme low priority bug, this allows "ubuntu|)" or "ubuntu|debian|)" which is wrong
            if [[ -n "`cat /usr/bin/amdgpu-install | grep ${parent}[A-Za-z\|]*\)$`" ]]; then
                # Add current ${ID} if ${ID_LIKE} is available
                # The lucky part of the install script is that it refers to OS names with Alphabets,
                # while ${ID} is lower case, so a simple sed will do to append current ${ID}
                sudo sed -i "s@${parent}@${parent}|${ID}@g" /usr/bin/amdgpu-install
                break
            fi
        done
    fi

    # @todo use `apt-cache policy amdgpu` to check installed version before calling
    sudo amdgpu-install -y --usecase=graphics,opencl --accept-eula
    sudo usermod -a -G render,video $LOGNAME

    # Not a requirement, but radeontop is a good tool for Radeon
    # https://wiki.debian.org/AtiHowTo
    if [[ -z "`apt list 2>/dev/null | grep radeontop | grep installed`" ]]; then
        sudo apt install -y radeontop
    fi

    popd > /dev/null
}

# Stop user from running the script as root as there are commands that uses sudo explicitly!
# https://stackoverflow.com/a/28776100
if [ `id -u` -eq 0 ]
    then echo "Do not run as sudo/root!"
    exit 1
fi

source /etc/os-release
ID_LIST="${ID} ${ID_LIKE}"
if [[ -n "`echo ${ID_LIST} | grep -e ubuntu -e debian`" ]]; then
    install_amdgpu_deb || exit $?
else
    echo "This script does not support ${ID} yet!"
    exit $?
fi