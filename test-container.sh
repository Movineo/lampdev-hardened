#!/bin/bash
set -euo pipefail

IMAGE="localhost/lampdev-hardened-bootc:latest"
NAME="lampdev-bootc"

podman rm -f "$NAME" 2>/dev/null || true

echo "Starting bootc image in container mode..."
podman run -d --name "$NAME" \
  --privileged \
  --tmpfs /var/lib/containers:rw \
  -p 8081:8080 \
  "$IMAGE" \
  /sbin/init

echo "Waiting for systemd to initialize..."
sleep 5

echo "Starting services (this will pull the images automatically)..."
# We use 'start' because Quadlet units are automatically generated
podman exec "$NAME" systemctl start mariadb php-fpm httpd

echo "Waiting for database initialization..."
sleep 15

echo "Service status:"
podman exec "$NAME" systemctl is-active mariadb php-fpm httpd

echo ""
echo "Setting up port forwarding..."
HTTPD_IP=$(podman exec "$NAME" podman inspect httpd --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}')
podman exec "$NAME" bash -c "nohup socat TCP-LISTEN:8080,fork,reuseaddr,bind=0.0.0.0 TCP:${HTTPD_IP}:8080 &"

echo ""
echo "Application is running at: http://127.0.0.1:8081"
echo "--------------------------------------------------------"
echo "To stop the bootc container, run: podman stop $NAME"
echo "To completely remove the container, run: podman rm -f $NAME"
echo "--------------------------------------------------------"
