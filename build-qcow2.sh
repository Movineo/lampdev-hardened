#!/bin/bash
set -euo pipefail

IMAGE="localhost/lampdev-hardened-bootc:latest"
OUTPUT_DIR="./output"
USER_STORAGE="${HOME}/.local/share/containers/storage"

mkdir -p "$OUTPUT_DIR"

# Copy the OS image from rootless to root storage
echo "Copying bootc image to root storage..."
sudo podman pull "containers-storage:[overlay@${USER_STORAGE}]${IMAGE}"

echo "Building qcow2 disk image from $IMAGE..."
sudo podman run --rm --privileged \
  --security-opt label=type:unconfined_t \
  -v /var/lib/containers/storage:/var/lib/containers/storage \
  -v "${OUTPUT_DIR}:/output" \
  -v ./config.toml:/config.toml:ro \
  registry.redhat.io/rhel10/bootc-image-builder:latest \
  --type qcow2 \
  "$IMAGE"

echo "Disk image created at: ${OUTPUT_DIR}/qcow2/disk.qcow2"
