#!/bin/bash

echo "Starting linux_setup.sh, LSH"

flog="LSH:" #Filename in log
logF() {    #log file
    msg=$1
    echo "$flog $msg"
}

logF "Run with \$(bash linux_setup.sh) NOT sudo sh..."
USER=$(whoami)
arch=$(uname -m)

logF "Updating and Upgrading"
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get full-upgrade -y
sudo apt-get clean

logF "Installing Packages and snapd (snap daemon for snap packages, very useful!)"
sudo apt-get install -y docker.io nano dirmngr gnupg software-properties-common curl gcc build-essential p7zip-full nano vim git \
    python3 python3-venv \
    clang clangd gdb llvm libreoffice bison cifs-utils \
    cmake g++ pkg-config libfreetype6-dev libfontconfig1-dev libxcb-xfixes0-dev libxkbcommon-dev apt-transport-https ca-certificates xterm libssl-dev snapd

logF "Installing docker compose v2"
sudo groupadd docker
sudo usermod -aG docker $USER
DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
mkdir -p $DOCKER_CONFIG/cli-plugins
curl -SL https://github.com/docker/compose/releases/download/v2.30.3/docker-compose-linux-$arch -o $DOCKER_CONFIG/cli-plugins/docker-compose
chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose
sudo systemctl restart docker

logF "Enabling passwordless sudo for current user"
echo "$USER ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/$USER
sudo chmod 0440 /etc/sudoers.d/$USER

logF "Starting SSH and enabling autostart on boot"
sudo systemctl enable ssh
sudo systemctl start ssh

logF "Updating and Upgrading"
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get full-upgrade -y
sudo apt-get autoremove -y
sudo apt-get clean

logF "Current IP"
ip addr
