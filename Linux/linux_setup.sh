#!/bin/bash
#Run with `sudo sh linux_setup.sh`

apt-get update -y
apt-get upgrade -y
apt-get full-upgrade -y
apt-get clean

apt-get install -y docker.io nano dirmngr gnupg software-properties-common curl gcc build-essential p7zip-full nano vim usbutils git \
    python3 python3-venv \
    clang clangd gdb llvm

curl --proto '=https' --tlsv1.3 https://sh.rustup.rs -sSf | sh -s -- -y                         #Rust
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" #Brew
brew install node@23                                                                            #Node
curl -fsSL https://deno.land/install.sh | sh                                                    #deno

apt-get update -y
apt-get upgrade -y
apt-get full-upgrade -y
apt-get clean
