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
# This is a convenient script to install Docker Engine silently.

if [[ $EUID -eq 0 ]]; then
   echo "This script must NOT be run as root!"
   exit 1
fi

# Add GPG Key
# https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository
sudo mkdir -p /etc/apt/trusted.gpg.d/

if [[ -z "`apt-key list | grep -i docker`" ]]; then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/docker.gpg
fi

# Add Docker repo
sudo add-apt-repository "deb https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# Install Docker Engine
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Add docker subgroup to simplify use without sudo
# https://docs.docker.com/engine/install/linux-postinstall/
sudo groupadd docker 2>/dev/null
sudo usermod -aG docker `whoami`
newgrp docker

# Reclaim ownership of docker subdirectory if ran erroneously in an earlier installation
if [[ -d ~/.docker ]]; then
    sudo chown -R `whoami`:`whoami` ~/.docker
    sudo chmod -R g+rwx ~/.docker
fi

# Allow RW for docker socket if ran erroneously in an earlier installation
if [[ -e /var/run/docker.sock ]]; then
    sudo chmod a+rw /var/run/docker.sock
fi
