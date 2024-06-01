#!/bin/bash
echo "Hello"
winget install Microsoft.PowerShell --accept-package-agreements
cmd /c mklink /J C:\\Users\\$Env:UserName\\.logseq .\\.logseq
cmd /c mklink /J C:\\Users\\$Env:UserName\\AppData\\alacritty\alacritty.toml .\\alacritty




