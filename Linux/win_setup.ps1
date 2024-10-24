
Write-Output "Starting Windows Setup Script win_setup.ps1"
Write-Output "Requires seed.img, which is generated on any linux host with cloud-localds seed.img user-data.yaml metadata.yaml"

function Test-IsAdmin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsAdmin)) {
    Write-Output "Please run as Admin"
    exit 1
}
try {
    $hypervFeature = dism.exe /Online /Get-FeatureInfo /FeatureName:Microsoft-Hyper-V-All
    if (-not ($hypervFeature -like "*State : Enabled*")) {
        Write-Output "Enabling Hyper V"
        Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
    }
    Write-Output "Hyper V enabled"
}
catch {
    Write-Error "Error $_"
    exit 1
}

winget.exe install QEMU

$vm_name = "crubuntu"
$memory_size = "4G"
$disk_size = "20G"   
$cpu_cores = 2
$seed_img = ".\seed.img"

try {
    if (-not (Test-Path $seed_img)) {
        Write-Error "$seed_img doesn't exist, can't continue"
        exit 1
    }
    else {
        Write-Output "$seed_img exists, continuing"
    }
}
catch {
    Write-Error "Error $_"
    exit 1
}
Write-Output "Checking architecture"
$arch = "unknown"
$system_arch = [System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture

if ($system_arch -eq "Arm64") {
    Write-Output "Platform: arm64"
    $arch = "arm64"
}
elseif ($system_arch -eq "X64") {
    Write-Output "Platform: amd64"
    $arch = "amd64"
}
else {
    Write-Output "Unknown platform: $system_arch"
    exit 1
}

# https://www.reddit.com/r/Ubuntu/comments/8zyt3p/comment/e2mldhj/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button 
# and
# https://www.reddit.com/r/Ubuntu/comments/29boes/comment/cije5ir/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button

$imgPath = "$env:TMP\ubuntu-oracular-server-cloudimg-$arch.img"
Write-Output "Checking\Downloading and attaching iso $imgPath"

if (Test-Path $imgPath) {
    Write-Output "$imgPath already exists"
}
else {
    Write-Output "$imgPath doesn't exist, downloading"
    $url = ""
    if ($arch -eq "amd64") {
        $url = "https://cloud-images.ubuntu.com/oracular/current/oracular-server-cloudimg-amd64.img"
    }
    else {
        $url = "https://cloud-images.ubuntu.com/oracular/current/oracular-server-cloudimg-arm64.img"
    }

    try {
        Write-Output "Downloading $url"
        Invoke-WebRequest -Uri $url -OutFile $imgPath
        Write-Output "Download completed successfully. Saved as '$imgPath'."
    }
    catch {
        Write-Output "Error downloading the file: $_"
        exit 1 
    }
    
}
Write-Output "Installing Python 3.13 or skipping if it is installed"
try {
    $python3_path = "$env:TMP\python-3.13.0-$arch.exe"
    if (Test-Path $python3_path) {
        Write-Output "Python 3.13 already downloaded"
    }
    else {
        Write-Output "Downloading Python 3.13"
        Invoke-WebRequest -Uri "https://www.python.org/ftp/python/3.13.0/python-3.13.0-$arch.exe" -OutFile "$env:TMP\python-3.13.0-$arch.exe"
        Write-Output "Download completed successfully. Saved as '$python3_path'."
    }
    Write-Output "Installing Python 3.13"
    Start-Process -FilePath $python3_path -Wait 
    Write-Output "Installation finished for Python 3.13."
}
catch {
    Write-Output "Error with python installation: $_"
    exit 1 
}



<# Write-Output "Setting up virtual switch for the VM, if it doesn't already exist"
$switchName = "crswitch" 
try {
     
    $adapterName = "Ethernet" 
    $virtualSwitch = Get-VMSwitch -Name $switchName -ErrorAction SilentlyContinue

    if (-not $virtualSwitch) {
        Write-Output "Virtual Switch $switchName doesn't exist, creating it"
        New-VMSwitch -Name $switchName -NetAdapterName $adapterName 
        Write-Host "Created virtual switch: $switchName"
    }
    else {
        Write-Host "Virtual switch already exists: $switchName"
    }
    Write-Host "Virtual switch $switchName setup complete"
}
catch {
    Write-Output "Failed to set up/check switch: $_"
    exit 1 
} #>
#If python was installed, it won't be in this script's environment, but the other shell will have it anyway, so good thing our python server runs in another window.
Write-Output "Starting Python server to serve cloud-init files to the VM"
$process = Start-Process alacritty `
    -ArgumentList '-e', 'python.exe -m http.server --directory .' `
    -PassThru
Write-Output "Python process Started"

Write-Host "Setting up and Starting QEMU"
$qemu_path = "C:\Program Files\qemu\qemu-system-x86_64.exe"
# https://powersj.io/posts/ubuntu-qemu-cli/
$qemu_args = @(
    "-name", $vm_name
    "-machine", "accel=whpx,type=q35"
    "-m", $memory_size 
    "-smp", "cores=$cpu_cores"
    "-nographic"
    "-device", "virtio-net-pci,netdev=net0"
    "-netdev", "user,id=net0,hostfwd=tcp::2222-:22"
    "-drive", "if=virtio,format=qcow2,file=$imgPath"
    "-drive", "if=virtio,format=raw,file=$seed_img"
)

Start-Process -FilePath $qemu_path -ArgumentList $qemu_args -PassThru -Wait

Write-Host "QEMU $vm_name started"
Write-Output "Stopping Python server"
Stop-Process -Id $process.Id
Write-Output "Stopped Python server"

# ssh -p 2222 localhost
# Optional: After VM setup, you can connect via SSH (ensure port forwarding)
# ssh ubuntu@localhost -p 2222


exit 0