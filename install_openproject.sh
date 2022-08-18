#!/bin/bash
################################################################################
# Copyright © 2022 JonnyS
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
################################################################################
# Almost unnecessary copyright notice which is required for public repo.
# This is a convenient script to install OpenProject with default settings.

SCRIPT_DIR=`realpath \`dirname ${BASH_SOURCE[0]}\``

# Stop user from running the script as root as there are commands that uses sudo explicitly!
# https://stackoverflow.com/a/28776100
if [ `id -u` -eq 0 ]; then
    echo "Do not run as sudo/root!"
    exit 1
fi

if [[ -z "`getent group sudo | cut -d: -f4 | grep \`whoami\``" ]]; then
    # Debian does not allow sudo by non-sudoer
    echo "Installation can only be done by sudoer!"
    exit 2
fi

if ! command -v docker &> /dev/null; then
    echo "Installing Docker Engine . . ."
    if [[ ! -f ${SCRIPT_DIR}/install_docker.sh ]]; then
        # Download install_docker.sh script if its not available
        # This can happen if this script was downloaded individually
        wget --directory-prefix=${SCRIPT_DIR} \
            https://raw.githubusercontent.com/jonnysoe/install-scripts/main/install_docker.sh
    fi
    if [[ -f ${SCRIPT_DIR}/install_docker.sh ]]; then
        # Install Docker Engine if install script is available
        bash ${SCRIPT_DIR}/install_docker.sh
        rm ${SCRIPT_DIR}/install_docker.sh
    fi
    if ! command -v docker &> /dev/null; then
        echo "Failed to install Docker Engine"
        exit 1
    fi
fi

# Create OpenProject directory
sudo mkdir -p /opt/openproject
sudo chmod -R a+rwx /opt/openproject
pushd /opt/openproject > /dev/null

# Clone Docker Compose
# https://www.openproject.org/docs/installation-and-operations/installation/docker/#quick-start
git clone https://github.com/opf/openproject-deploy --depth=1 --branch=stable/12 openproject
pushd openproject/compose > /dev/null
docker compose pull
docker compose up -d
ERROR_CODE=$?
popd > /dev/null

popd > /dev/null
exit ${ERROR_CODE}
