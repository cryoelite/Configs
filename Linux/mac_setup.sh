#!/bin/zsh

echo "Starting mac_setup script"
echo "Make sure multipass is already installed"

vm_name=galhydromy
vm_size=64G

echo "Deleting existing vm with name $vm_name"
multipass delete $vm_name --purge
echo "Deletion successful"

echo "Launching VM"
multipass launch -n $vm_name --cloud-init ./user-data.yaml
multipass stop $vm_name 
multipass mount --type=native ../ $vm_name:/mnt/
multipass set local.$vm_name.disk=$vm_size 
multipass start $vm_name
echo "Launched VM"

echo "Outputting VM details"
multipass list
