#!/bin/bash
set -euo pipefail

QCOW2="./output/qcow2/disk.qcow2"
VM_NAME="lampdev-hardened"
CONFIG_FILE="./config.toml"
USER_DATA="./user-data"

# Validate required files
for FILE in "$QCOW2" "$CONFIG_FILE" "$USER_DATA"; do
    if [[ ! -f "$FILE" ]]; then
        echo "ERROR: Required file not found: $FILE"
        exit 1
    fi
done

# Read the configured username (never print the password hash)
VM_USER=$(awk -F'"' '/name[[:space:]]*=/ {print $2; exit}' "$CONFIG_FILE")
VM_USER=${VM_USER:-admin}

echo "Launching VM: $VM_NAME"

# Configure and launch the VM
VM_ARGS=(
    --connect qemu:///system
    --name "$VM_NAME"
    --cpu host-model
    --vcpus 2
    --memory 4096
    --network network=default
    --noautoconsole
    --import
    --disk "${QCOW2},format=qcow2"
    --os-variant rhel10-unknown
    --cloud-init "user-data=${USER_DATA}"
)

sudo virt-install "${VM_ARGS[@]}"

echo "VM launched. Waiting for IP address..."

VM_IP=""

for ATTEMPT in $(seq 1 24); do
    VM_IP=$(sudo virsh domifaddr "$VM_NAME" 2>/dev/null |
        awk '/ipv4/ {split($4,a,"/"); print a[1]; exit}')

    [[ -n "$VM_IP" ]] && break

    sleep 5
done

if [[ -z "$VM_IP" ]]; then
    echo "VM started, but its IP address was not detected."
    echo "Check with: sudo virsh domifaddr $VM_NAME"
    echo "Or: sudo virsh net-dhcp-leases default"
    exit 1
fi

echo
echo "VM: $VM_NAME"
echo "IP address: $VM_IP"
echo "Application: http://${VM_IP}:8080"
echo "Console: sudo virsh console $VM_NAME"
echo "Login username: $VM_USER"
echo "Use the admin password configured during image creation."
echo
echo "Stop VM: sudo virsh shutdown $VM_NAME"
echo "Force stop: sudo virsh destroy $VM_NAME"
