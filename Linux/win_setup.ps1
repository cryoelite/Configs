
Write-Host "Starting Windows Setup Script win_setup.ps1"
Write-Host "Requires seed.img, which is generated on any linux host with cloud-localds seed.img user-data.yaml metadata.yaml"

function Test-IsAdmin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function check_hyper_v {

    Write-Host "Checking for Hyper-V"
    $hypervFeature = dism.exe /Online /Get-FeatureInfo /FeatureName:Microsoft-Hyper-V-All
    if (-not ($hypervFeature -like "*State : Enabled*")) {
        Write-Host "Enabling Hyper V"
        Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
    }
    Write-Host "Hyper V is enabled"
}

function download_image {
    param (
        [string]$img_path,
        [string]$arch,
        [string]$arm64_vm_url,
        [string]$amd64_vm_url
    )

    Write-Host "Downloading $img_path"
    $url = ""
    # https://www.reddit.com/r/Ubuntu/comments/8zyt3p/comment/e2mldhj/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button 
    # and
    # https://www.reddit.com/r/Ubuntu/comments/29boes/comment/cije5ir/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button

    if ($arch -eq "amd64") {
        $url = $amd64_vm_url
    }
    else {
        $url = $arm64_vm_url
    }


    Write-Host "Downloading $url"
    Invoke-WebRequest -Uri $url -OutFile $img_path
    Write-Host "Download completed successfully. Saved as '$img_path'."


}

function setup_image {
    param (
        [string]$arch,
        [string]$img_path,
        [string]$url_sha256,
        [string]$arm64_vm_url,
        [string]$amd64_vm_url
    )

    Write-Host "Checking\Downloading and attaching image $img_path"

    if (Test-Path $img_path) {
        Write-Host "$img_path exists, verifying SHA256 Checksum"
        Write-Host "Downloading SHA256 Checksum"
        
        #$url_sha256_gpg = "https://cloud-images.ubuntu.com/oracular/current/SHA256SUMS.gpg" Not verifying GPG right now
        $sha256_file = "$env:TMP\SHA256SUMS"
        Invoke-WebRequest -Uri $url_sha256 -OutFile $sha256_file

        #Write-Host "Installing GPG4Win to get gpg to verify checksums"
        #winget.exe install -e --id GnuPG.Gpg4win
        #gpg.exe --verify SHA256SUMS.gpg SHA256SUMS
        $calculatedChecksum = (CertUtil -hashfile $img_path SHA256)[1].Trim()
    
        Write-Host "Calculated checksum: $calculatedChecksum for $img_path"
        Write-Host "Looking for checksum in $sha256_file..."
        $content = Get-Content -Path $sha256_file -Raw
        $lines = $content -split "`n"

        $expectedChecksum = $null
        Write-Host "Iterating over lines of the checksum file to locate the image ending with $img_path's ending"
        foreach ($line in $lines) {
            if ($line.Length -gt 67) {
                $imagename_in_file = $line.Substring(66)
                if ($img_path.EndsWith($imagename_in_file)) {
                    $expectedChecksum = $line.Substring(0, 64);
                    Write-Host "Found checksum $expectedChecksum for $imagename_in_file in $sha256_file"
                }
            }
        }
        
        if ($null -eq $expectedChecksum) {
            Write-Error "Error: Checksum not found for $img_path in $sha256_file. Cannot continue"
            throw "Checksum mismatch for $img_path, not found in $sha256_file"
        }

        Write-Host "Our checksum $calculatedChecksum and Expected checksum: $expectedChecksum"
        if ($calculatedChecksum -eq $expectedChecksum) {
            Write-Host "Checksum verified successfully! The file is valid."
        }
        else {
            Write-Host "Checksum verification failed! The file isn't up-to-date or corrupted."
            download_image -imgPath $img_path -arch $arch -arm64_vm_url $arm64_vm_url -amd64_vm_url $amd64_vm_url
        }  


    }
    else {
        download_image -img_path $img_path -arch $arch -arm64_vm_url $arm64_vm_url -amd64_vm_url $amd64_vm_url
    }
}

    
function start_qemu {
    param ([bool]$should_cloud_init, 
        [string]$vm_name,
        [string]$memory_size,
        [string]$cpu_cores,
        [string]$disk_path,
        [string]$seed_img,
        [string]$qemu_path,
        [string]$state_sav_path
    )
    Write-Host "Setting up and Starting QEMU"


    # https://powersj.io/posts/ubuntu-qemu-cli/
    $qemu_args = @(
        "-name", $vm_name
        "-machine", "accel=whpx,type=q35"
        "-m", $memory_size 
        "-smp", "cores=$cpu_cores"
        "-nographic"
        "-device", "virtio-net-pci,netdev=net0"
        "-netdev", "user,id=net0,hostfwd=tcp::2222-:22"
        "-drive", "if=virtio,format=qcow2,file=$disk_path"

    )
    if ($should_cloud_init) {
        $qemu_args += "-drive", "if=virtio,format=raw,file=$seed_img"
    }

    $qemu_command = $qemu_path + " " + ($qemu_args -join " ")

    Write-Host "Starting QEMU $vm_name"
    Start-Process alacritty `
        -ArgumentList @("-e", $qemu_command) `

    Write-Host "QEMU $vm_name started. \n Note: Shutdown with 'shutdown -h now' inside the VM to save state, killing the process does not save state"
}

function get_arch {
    
    Write-Host "Getting architecture"
    $arch = "unknown"
    $system_arch = [System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture

    if ($system_arch -eq "Arm64") {
        Write-Host "Platform: arm64"
        $arch = "arm64"
    }
    elseif ($system_arch -eq "X64") {
        Write-Host "Platform: amd64"
        $arch = "amd64"
    }
    else {
        Write-Host "Unknown platform: $system_arch"
        throw "Unknown platform: $system_arch"
    }
    Write-Host "Architecture: $arch"
    return $arch    
}

function setup_disk {
    param (
        [string]$img_path,
        [string]$disk_path,
        [string]$disk_folder,
        [string]$disk_size,
        [string]$qemu_img_path
    )
    Write-Host "Setting up disk at $disk_path"

    Write-Host "Making Directory $disk_folder"
    New-Item -ItemType Directory -Path $disk_folder -Force

    <#     Write-Host "Generating qcow2 disk from $img_path"
    
    Start-Process -FilePath $qemu_img_path `
        -ArgumentList @("convert", "-f", "raw", "-O", "qcow2", $img_path, $disk_path) `
        -NoNewWindow -Wait #>
    Write-Host "Copying $img_path to $disk_path"
    Copy-Item -Path $img_path -Destination $disk_path

    Write-Host "Successfully finished generating $disk_path"
 
    Write-Host "Resizing $disk_path"
    Start-Process -FilePath $qemu_img_path `
        -ArgumentList @("resize", $disk_path, $disk_size) `
        -NoNewWindow -Wait
    Write-Host "Successfully resized $disk_path to $disk_size" 
}
function main {
    if (-not (Test-IsAdmin)) {
        Write-Host "Please run as Admin"
        throw "Not running as admin"
    }
    try {
        Write-Host "Installing QEMU"
        winget.exe install QEMU

        $vm_name = "crubuntu"
        $memory_size = "4G"
        $disk_size = "20G"
        $disk_folder = "C:\NFBase\VMs\"
        $disk_path = "C:\NFBase\VMs\$vm_name.img"   
        $disk_save_file = "C:\NFBase\VMs\${vm_name}_state.sav"   
        $cpu_cores = 2
        $seed_img = ".\seed.img"
        $qemu_img_path = "C:\Program Files\qemu\qemu-img.exe"
        $qemu_path = "C:\Program Files\qemu\qemu-system-x86_64.exe"
        $url_sha256 = "https://cloud-images.ubuntu.com/oracular/current/SHA256SUMS"
        $arm64_vm_url = "https://cloud-images.ubuntu.com/oracular/current/oracular-server-cloudimg-arm64.img"
        $amd64_vm_url = "https://cloud-images.ubuntu.com/oracular/current/oracular-server-cloudimg-amd64.img"
        $arch = get_arch
        $img_path = "$env:TMP\ubuntu-oracular-server-cloudimg-$arch.img"
        $cleanup = $false
        
        if ($cleanup) {
            Write-Host "Cleaning up VM and its files (except seed.img)"
            Remove-Item $disk_path -Force
            Remove-Item $img_path -Force
            Write-Host "Cleanup complete"
        }
        else {
            Write-Host "Checking if $disk_path exists" 
            if ((Test-Path $disk_path)) {
                Write-Host "$disk_path already exists, starting the VM directly"
                start_qemu -should_cloud_init $false -vm_name $vm_name -memory_size $memory_size -cpu_cores $cpu_cores -disk_path $disk_path -seed_img $seed_img -qemu_path $qemu_path -state_sav_path $disk_save_file
            }
            else {
                Write-Host "$disk_path doesn't exist, creating it (and the VM)"
                if (-not (Test-Path $seed_img)) {
                    Write-Error "$seed_img doesn't exist, can't continue"
                    throw "No seed image $seed_img"
                }

                setup_image -arch $arch -img_path $img_path -arm64_vm_url $arm64_vm_url -amd64_vm_url $amd64_vm_url -url_sha256 $url_sha256

                setup_disk -img_path $img_path -disk_path $disk_path -disk_folder $disk_folder -disk_size $disk_size -qemu_img_path $qemu_img_path

                start_qemu -should_cloud_init $true -vm_name $vm_name -memory_size $memory_size -cpu_cores $cpu_cores -disk_path $disk_path -seed_img $seed_img -qemu_path $qemu_path -state_sav_path $disk_save_file
            }
            Write-Host "Finished setting up VM $vm_name, for ssh follow https://askubuntu.com/a/497898/1701747 and then ssh with ssh root@localhost -p 2222"
            exit 0
        }
    }

    catch {
        Write-Error "Error $_"
        exit 1
    }
    
}

main