#!/bin/bash
set -euo pipefail

echo "Creating network and volume..."
podman network create lamp-net || true
podman volume create db-data || true

echo "Starting MariaDB..."
podman run -d --name mariadb --network lamp-net \
-e MARIADB_ROOT_PASSWORD=rootpass \
-e MARIADB_USER=appuser \
-e MARIADB_PASSWORD=apppass \
-e MARIADB_DATABASE=hellodb \
-v db-data:/var/lib/mysql:Z \
-p 3306:3306 \
registry.access.redhat.com/hi/mariadb:latest

echo "Starting PHP-FPM..."
podman run -d --name php-fpm --network lamp-net \
-e DB_HOST=mariadb \
-e DB_USER=appuser \
-e DB_PASS=apppass \
-e DB_NAME=hellodb \
-v ./app:/var/www/html:z \
registry.access.redhat.com/hi/php:latest-fpm

echo "Starting Apache HTTPD..."
podman run -d --name httpd --network lamp-net \
-p 8080:8080 \
-v ./app:/var/www/html:z,ro \
-v ./httpd/proxy-php.conf:/etc/httpd/conf.d/proxy-php.conf:Z,ro \
registry.access.redhat.com/hi/httpd:latest

echo "--------------------------------------------------------"
echo "LAMP stack is running!"
echo "To stop the stack, run: podman stop httpd php-fpm mariadb"
echo "To completely remove the containers, run: podman rm -f httpd php-fpm mariadb"
echo "--------------------------------------------------------"
