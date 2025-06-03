#!/bin/bash

pushd ~/Downloads > /dev/null

# https://gist.github.com/Jacobboogiebear/2af9a49f8e9fdc2641ae019be58c4acd
# sudo apt install -y git build-essential autotools-dev libssl-dev libtasn1-6-dev libjson-glib-dev expect socat libseccomp-dev libgmp3-dev

# Prepare package for distro
packages=()

if [[ -z "`apt list 2> /dev/null | grep git | grep installed`" ]]; then
    packages=(git)
fi
if [[ -z "`apt list 2> /dev/null | grep build-essential | grep installed`" ]]; then
    packages=(build-essential)
fi
if [[ -z "`apt list 2> /dev/null | grep autotools-dev | grep installed`" ]]; then
    packages=(autotools-dev)
fi
if [[ -z "`apt list 2> /dev/null | grep libssl-dev | grep installed`" ]]; then
    packages=(libssl-dev)
fi
if [[ -z "`apt list 2> /dev/null | grep libtasn1-6-dev | grep installed`" ]]; then
    packages=(libtasn1-6-dev)
fi
if [[ -z "`apt list 2> /dev/null | grep libjson-glib-dev | grep installed`" ]]; then
    packages=(libjson-glib-dev)
fi
if [[ -z "`apt list 2> /dev/null | grep expect | grep installed`" ]]; then
    packages=(expect)
fi
if [[ -z "`apt list 2> /dev/null | grep socat | grep installed`" ]]; then
    packages=(socat)
fi
if [[ -z "`apt list 2> /dev/null | grep libseccomp-dev | grep installed`" ]]; then
    packages=(libseccomp-dev)
fi
if [[ -z "`apt list 2> /dev/null | grep libgmp3-dev | grep installed`" ]]; then
    packages=(libgmp3-dev)
fi

# Install if there are missing packages
if [ ${#packages[@]} -gt 0 ]; then
    sudo apt install -y ${packages[@]}
fi

if [[ -z "`ldconfig -p | grep libtpms`" ]]; then
    if [[ ! -d libtpms ]]; then
        git clone https://github.com/stefanberger/libtpms.git
    fi
fi
if ! command -v swtpm &> /dev/null; then
    if [[ ! -d swtpm ]]; then
        git clone https://github.com/stefanberger/swtpm.git
    fi
fi

if [[ -z "`ldconfig -p | grep libtpms`" ]]; then
    pushd libtpms > /dev/null

    # Build and install
    ./autogen.sh --prefix=/usr --with-tpm2 --with-openssl
    make -j`nproc`
    sudo make install

    # update ld cache
    sudo ldconfig

    popd > /dev/null
    rm -rf libtpms
fi

if ! command -v swtpm &> /dev/null; then
    pushd swtpm > /dev/null

    # Build and install
    ./autogen.sh --prefix=/usr
    make -j`nproc`
    sudo make install

    # @TODO: Consider making a real deb package
    # Get PACKAGE_VERSION from configure script (cannot be sourced), so replace "=" and "'"
    VERSION=(`grep "PACKAGE_VERSION=" configure | sed "s/=/ /g" | sed "s/'/ /g"`)

    # Make a fake dpkg entry to be visible for apt
    PACKAGE_NAME=swtpm_${VERSION[1]}
    mkdir -p ${PACKAGE_NAME}/DEBIAN
    mkdir -p ${PACKAGE_NAME}/usr/bin
    # cp src/swtpm/.libs/swtpm ${PACKAGE_NAME}/usr/bin
    echo "Package: swtpm" > ${PACKAGE_NAME}/DEBIAN/control
    echo "Version: ${VERSION[1]}" >> ${PACKAGE_NAME}/DEBIAN/control
    echo "Priority: optional" >> ${PACKAGE_NAME}/DEBIAN/control
    echo "Architecture: amd64" >> ${PACKAGE_NAME}/DEBIAN/control
    echo "Essential: no" >> ${PACKAGE_NAME}/DEBIAN/control
    echo "Maintainer: Fake <fake@fake.com>" >> ${PACKAGE_NAME}/DEBIAN/control
    echo "Description: Software TPM (swtpm)" >> ${PACKAGE_NAME}/DEBIAN/control

    # Build the fake swtpm package
    dpkg-deb --build --root-owner-group ${PACKAGE_NAME}

    # Install the fake swtpm to add to dpkg entry
    sudo gdebi -n ${PACKAGE_NAME}.deb

    popd > /dev/null
    rm -rf swtpm
fi

popd > /dev/null
