
Write-Output "Starting Windows Setup Script win_setup.ps1"

function Test-IsAdmin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsAdmin)) {
    Write-Output "Please run as Admin"
    exit 1
}

winget.exe install QEMU

$vmName = "cr_Ubuntu"
$memoryStartupBytes = 4GB
$vmPath = "C:\VMs\$vmName"
$vhdPath = "$vmPath\$vmName.vhd"
#$switchName = "cr_ExternalSwitch"
$switchName = "Default Switch"
Write-Output "Using default values"

try {

    Write-Output "Checking if VM $vmName exists"
    $vm = Get-VM -Name $vmName -ErrorAction SilentlyContinue

    if ($vm) {
        Write-Output "VM '$vmName' exists. Removing it"

        # Stop the VM if it's running
        if ($vm.State -eq 'Running') {
            Stop-VM -Name $vmName -Force
            Write-Output "VM '$vmName' stopped."
        }

        Remove-VM -Name $vmName -Force
        Write-Output "VM '$vmName' removed."
    
    }
    Write-Output "Checking if VHD $vhdPath exists"
    if (Test-Path $vhdPath) {
        Write-Output "VHD file '$vhdPath' exists. Removing VHD..."
        Remove-Item -Path $vhdPath -Force
        Write-Output "VHD file '$vhdPath' removed."
    }
    <#   
    Write-Output "Checking if VM Switch $switchName exists"
   $switch = Get-VMSwitch -Name $switchName -ErrorAction SilentlyContinue
    if ($switch) {
        Write-Output "Switch $switchName exists, removing"
        Remove-VMSwitch -Name $switchName -Force
        Write-Output "Switch $switchName removed"
    } #>
}
catch {
    Write-Error "Error $_"
    exit 1
}
try {
    Write-Output "Enabling Hyper V"
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
    Write-Output "Hyper V enabled"
}
catch {
    Write-Error "Error $_"
    exit 1
}

try {
    Write-Output "Checking architecture"
    $arch = [System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture
    if ($arch -eq "Arm64") {
        Write-Output "Platform: arm64"
        $arch = "arm64"
    }
    elseif ($arch -eq "X64") {
        Write-Output "Platform: amd64"
        $arch = "amd64"
    }
    else {
        Write-Output "Unknown platform: $arch"
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
            exit 1  # Exit the script on download failure
        }
    
    }

    $rawPath = "$env:TMP\ubuntu-24.10-server-cloudimg-$arch.raw"
    if (Test-Path $rawPath) {
        Remove-Item -Path $rawPath -Force
    }
    #Write-Output "Converting and storing $imgPath to $rawPath and then to $vhdPath"
    Write-Output "Converting and storing $imgPath to $vhdPath"
    #https://superuser.com/a/1093615/1088896
    $qemu_img_path = "C:\Program Files\qemu\qemu-img.exe"
    #& $qemu_img_path convert -f qcow2 -O raw $imgPath $rawPath #Convert to raw, to ensure compression or encryption and ensure it is not sparse
    #& $qemu_img_path convert -f raw  -O vpc -o subformat=dynamic $rawPath $vhdPath
    fsutil.exe sparse setflag "$imgPath" 0
    & $qemu_img_path convert -f qcow2  -O vpc -o subformat=dynamic $imgPath $vhdPath
    fsutil.exe sparse setflag "$vhdPath" 0
    Write-Output "Conversion and storage done for $vmName"
}
catch {
    Write-Error "Error $_"
    exit 1
}
try {
<#     Write-Output "Creating new switch $switchName"
    $SWITCH = @{
        Name              = $switchName
        NetAdapterName    = (Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1).Name 
        AllowManagementOS = $true
    }

    New-VMSwitch @SWITCH  #>

    $VM = @{
        Name               = $vmName
        MemoryStartupBytes = $memoryStartupBytes
        Generation         = 2
        Path               = $vmPath
        SwitchName         = $switchName
    
    }
    Write-Output "Creating New VM $vmName"
    New-VM @VM 
    Write-Output "New VM Created"

}
catch {
    Write-Error "Error $_"
    exit 1
}

try {
    Write-Output "Attaching $vhdPath to $vmName"
    Add-VMHardDiskDrive -VMName $vmName -Path $vhdPath
    Write-Output "Attached $vhdPath to $vmName"

    #Enabling Secure Boot
    Set-VMFirmware -VMName $vmName -EnableSecureBoot On -SecureBootTemplate "MicrosoftUEFICertificateAuthority"

    Write-Output "Starting $vmName"
    Start-VM -Name $vmName
    Write-Output "$vmName started"

    Write-Output "Waiting 60 seconds for the VM to finish starting"
    Start-Sleep -Seconds 60 
    Write-Output "Done"

    Get-VM -Name $vmName | Format-List
    Get-VMNetworkAdapter -VMName $vmName

    $vmIp = Get-VMNetworkAdapter -VMName $vmName | Select-Object -ExpandProperty IPAddresses

    Write-Output "VM '$vmName' created and started."
    Write-Output "IP Address: $vmIp"
    Write-Output "You can now SSH into the VM using 'ssh ubuntu@$vmIp'."
}
catch {
    Write-Error "Error $_"
    exit 1
}
exit 0