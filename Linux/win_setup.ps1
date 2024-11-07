
Write-Host "Starting Windows Setup Script win_setup.ps1"
function Test-IsAdmin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function main {
    if (-not (Test-IsAdmin)) {
        Write-Host "Please run as Admin"
        throw "Not running as admin"
    }
    try {
    Write-Host "Starting mac_setup script"
    Write-Host "Make sure multipass is already installed"

    $vm_name="auhydromy"
    $vm_size="64G"

    Write-Host "Deleting existing vm with name $vm_name"
    multipass delete $vm_name --purge
    Write-Host "Deletion successful"

    Write-Host "Launching VM"
    multipass launch -n ${vm_name} --cloud-init ./user-data.yaml
    multipass stop ${vm_name} --force
    multipass set local.privileged-mounts=Yes
    multipass mount --type=classic ../ ${vm_name}:/mnt/
    multipass set local.${vm_name}.disk=${vm_size}
    multipass start ${vm_name}
    Write-Host "Launched VM"

    Write-Host "Outputting VM details"
    multipass list
    }

    catch {
        Write-Error "Error $_"
        exit 1
    }
    
}

main    