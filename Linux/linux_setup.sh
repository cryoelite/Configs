#!/bin/bash

echo "Starting linux_setup.sh, LSH"

flog="LSH:" #Filename in log
logF() {    #log file
    msg=$1
    echo "$flog $msg"
}

logF "Run with \$(bash linux_setup.sh) NOT sudo sh..."

git_username="cryoelite"
git_email="itscryonim@gmail.com"

logF "Updating and Upgrading"
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get full-upgrade -y
sudo apt-get clean

logF "Installing Packages"
sudo apt-get install -y docker.io docker-compose nano dirmngr gnupg software-properties-common curl gcc build-essential p7zip-full nano vim usbutils git \
    python3 python3-venv \
    clang clangd gdb llvm libreoffice bison cifs-utils \
    cmake g++ pkg-config libfreetype6-dev libfontconfig1-dev libxcb-xfixes0-dev libxkbcommon-dev
    
logF "Installing Vivaldi (Only on ubuntu)"
sudo snap install vivaldi

logF "Installing Rust"
curl --proto '=https' --tlsv1.2 https://sh.rustup.rs -sSf | sh #Rust https://doc.rust-lang.org/book/ch01-01-installation.html#installing-rustup-on-linux-or-macos
chmod +r "$HOME/.cargo/env"
. "$HOME/.cargo/env"

logF "Installing Brew"
NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" #Brew https://brew.sh/
echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >>~/.profile
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

logF "Installing Node"
brew install node@23

logF "Installing deno"
curl -fsSL https://deno.land/install.sh | sh #deno https://docs.deno.com/runtime/getting_started/installation/

logF "Installing Go"
bash -c "curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer | bash"
chmod +r "/home/auhydromy/.gvm/scripts/gvm"
. /home/auhydromy/.gvm/scripts/gvm
gvm install go1.20.6 -B
gvm use go1.20.6
export GOROOT_BOOTSTRAP=$GOROOT
gvm install go1.23.3
gvm use go1.23.3 --default
go version

logF "Installing alacritty"
cargo install alacritty

logF "Set up Git (TODO, take name and email from user)"
#git config --global user.name "cryoelite"
#git config --global user.email "itscryonim@gmail.com"

logF "Updating and Upgrading"
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get full-upgrade -y
sudo apt-get clean
