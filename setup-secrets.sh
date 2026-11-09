#!/bin/bash
set -euo pipefail

# 1. Choose where to save a backup of the passwords.
GENERATED_FILE="/root/lamp-secrets-generated.txt"

# 2. Check if passwords already exist so we do not overwrite them when the server restarts.
# If you want to use PostgreSQL instead, change 'mariadb_root_password' to your new secret name.
if podman secret inspect mariadb_root_password &>/dev/null; then
    echo "Passwords already exist. Skipping setup."
    exit 0
fi

echo "Creating new secure passwords..."

# 3. Create random 16-character passwords.
# This uses standard Linux tools built into the server.
ROOT_PASS=$(head -c 16 /dev/urandom | base64)
APP_PASS=$(head -c 16 /dev/urandom | base64)

# 4. Save a backup copy to a text file so you can log in later.
echo "# Auto-generated LAMP passwords — $(date -Iseconds)" > "$GENERATED_FILE"
echo "MARIADB_ROOT_PASSWORD=$ROOT_PASS" >> "$GENERATED_FILE"
echo "MARIADB_APP_PASSWORD=$APP_PASS" >> "$GENERATED_FILE"

# Lock the file so only the root user can read it.
chmod 600 "$GENERATED_FILE"
echo "Passwords saved to $GENERATED_FILE"

# 5. Save the passwords into Podman's secure storage.
# 5. Save the passwords into Podman's secure storage.
# We use 'echo -n' so it doesn't add a hidden newline (like pressing Enter)
# to the end of the password. 
# To use a different database, change these names (for example, change 'mariadb' to 'postgres').
echo -n "$ROOT_PASS" | podman secret create mariadb_root_password -
echo -n "$APP_PASS"  | podman secret create mariadb_app_password -

echo "Database passwords are set up successfully."
