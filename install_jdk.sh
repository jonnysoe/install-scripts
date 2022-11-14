#!/bin/bash

function add_path() {
    local PATH_NAME=${1}
    local PATH_STRING=${2}
    if [[ -z ${!PATH_NAME} ]]; then
        # Reference: https://www.serverlab.ca/tutorials/linux/administration-linux/how-to-set-environment-variables-in-linux/
        if [[ ! -f /etc/profile.d/custom.sh ]] || \
            [[ "`grep ${PATH_NAME} /etc/profile.d/custom.sh`" != "${PATH_STRING}" ]]
        then
            local LINE="export ${PATH_NAME}=${PATH_STRING}"
            sudo sh -c "echo $LINE >> /etc/profile.d/custom.sh"
            echo "Appended ${PATH_NAME} to /etc/profile.d/custom.sh, restart to take effect."
        fi
    fi
}

function install_jdk() {
    # Install Amazon Corretto (OpenJDK)
    if [[ -z `java -version 2>&1 | grep -m1 Corretto` ]]; then
        # Requires java-common
        if [[ -z "`apt list | grep java-common`" ]]; then
            sudo apt install -y java-common
        fi

        wget -O corretto.deb 'https://corretto.aws/downloads/latest/amazon-corretto-17-x64-linux-jdk.deb'
        sudo gdebi -n corretto.deb
    fi

    # Make sure JAVA_HOME global environment variable is set
    local CORRETTO_PATH=`find /usr/lib/jvm/ -maxdepth 1 -type d | grep corretto`
    add_path JAVA_HOME ${CORRETTO_PATH}
}

install_jdk
