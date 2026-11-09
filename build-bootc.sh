#!/bin/bash
set -euo pipefail

IMAGE="localhost/lampdev-hardened-bootc:latest"

echo "Building bootc image..."
podman build -f Containerfile.bootc -t "$IMAGE" .

echo "Build complete: $IMAGE"
