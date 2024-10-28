#!/bin/bash
#Run with `sudo sh linux_setup.sh`

apt-get update -y 
apt-get upgrade -y
apt-get full-upgrade -y
apt-get clean

apt-get install -y docker.io nano dirmngr gnupg software-properties-common curl gcc build-essential p7zip-full nano vim usbutils git \
    python3 python3-venv \
    clang clangd gdb llvm libreoffice

/bin/bash -c "curl --proto '=https' --tlsv1.2 https://sh.rustup.rs -sSf | sh"                   #Rust https://doc.rust-lang.org/book/ch01-01-installation.html#installing-rustup-on-linux-or-macos
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" #Brew https://brew.sh/
brew install node@23                                                                            #Node https://nodejs.org/en/download/package-manager
/bin/bash -c 'curl -fsSL https://deno.land/install.sh | sh'                                     #deno https://docs.deno.com/runtime/getting_started/installation/

git config --global user.name "cryoelite"
git config --global user.email "itscryonim@gmail.com"

apt-get update -y
apt-get upgrade -y
apt-get full-upgrade -y
apt-get clean
