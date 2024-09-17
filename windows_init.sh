#!/bin/bash

echo "Installing Tools"
#TODO: Prompt for each step, in all subsequent sections too



echo "LazyVim Installation Started"

echo "Install LazyVim ?"
#...
echo "Installing Git"
winget install --id Git.Git -e --source winget
winget install Neovim.Neovim
#Install alacritty (manually for now)
start https://github.com/alacritty/alacritty/releases 
echo "Installing Rigrep"
winget install BurntSushi.ripgrep.MSVC 
echo "Installing fd"
winget install sharkdp.fd

#Not required as it's simply a config, which I have already created and added
#echo "Installing LazyVim" #As given here https://www.lazyvim.org/installation
#git clone https://github.com/LazyVim/starter $env:LOCALAPPDATA\nvim
#Remove-Item $env:LOCALAPPDATA\nvim\.git -Recurse -Force

echo "Setting up configs"
winget install Microsoft.PowerShell --accept-package-agreements
cmd /c mklink /J $env:UserName\\.logseq .\\.logseq
cmd /c mklink /J $env:APPDATA\\alacritty\alacritty.toml .\\alacritty
cmd /c mklink /J $env:LOCALAPPDATA\\nvim .\\nvim
cmd /c mklink /J $env:APPDATA\\Zed .\\Zed

#Install fonts from nerdfonts (https://www.nerdfonts.com/)
curl -o cousine.zip "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/Cousine.zip"
curl -o CCM.zip "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/CascadiaMono.zip"
mkdir TempFiles
unzip cousine.zip -d "./TempFiles/Fonts/cousine/"
unzip CCM.zip -d "./TempFiles/Fonts/CCM/"
rm -f cousine.zip
rm -f CCM.zip
#TODO Install the fonts

echo "LazyVim Installation Finished"


