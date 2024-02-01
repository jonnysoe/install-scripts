#!/bin/bash

function add_path() {
    local PATH_NAME=${1}
    local PATH_STRING=${2}
    # Indirect parameter expansion to test out environment variable passed in by caller.
    # eg. When JAVA_HOME was passed in, it is equivalent to evaluating ${JAVA_HOME}
    # https://stackoverflow.com/a/1921337/19336104
    if [[ -z ${!PATH_NAME} ]]; then
        # Add to system-wide bashrc
        # https://askubuntu.com/a/503222
        # /etc/bash.bashrc is the preferred method over /etc/profile.d
        # /etc/bash.bashrc will run everytime a user launch the terminal
        # /etc/profile.d only runs upon login
        if [[ ! -f /etc/bash.bashrc ]] || \
            [[ -z "`grep ${PATH_NAME} /etc/bash.bashrc | grep ${PATH_STRING}`" ]]; then
            local LINE="export ${PATH_NAME}=${PATH_STRING}"
            sudo sh -c "echo $LINE >> /etc/bash.bashrc"
            echo "Appended ${PATH_NAME} to /etc/bash.bashrc."
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
