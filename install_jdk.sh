#!/bin/sh

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
    if [[ -z $JAVA_HOME ]]; then
        # It should look like /usr/lib/jvm/java-1.8.0-amazon-corretto
        # Reference: https://www.serverlab.ca/tutorials/linux/administration-linux/how-to-set-environment-variables-in-linux/
        if [[ -z `cat /etc/profile.d/custom.sh | grep JAVA_HOME` ]]; then
            CORRETTO_PATH=/usr/lib/jvm/`ls /usr/lib/jvm/ | grep corretto`
            JAVA_HOME="export JAVA_HOME=$CORRETTO_PATH"
            if [[ ! -f /etc/profile.d/custom.sh ]]; then
                sudo touch /etc/profile.d/custom.sh
            fi
            sudo sh -c "echo $JAVA_HOME >> /etc/profile.d/custom.sh"
        fi
    fi
}

install_jdk
