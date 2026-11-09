#!/bin/bash
set -euo pipefail

KEY_FILE="$HOME/.ssh/id_ed25519.pub"
OUTPUT="config.toml"

# Check SSH public key
if [[ ! -f "$KEY_FILE" ]]; then
    echo "SSH public key not found: $KEY_FILE"
    exit 1
fi

# Check OpenSSL
command -v openssl >/dev/null || {
    echo "OpenSSL is required."
    exit 1
}

PUB_KEY=$(< "$KEY_FILE")

# Collect admin password
read -rsp "Enter admin password: " ADMIN_PASSWORD
echo
read -rsp "Confirm admin password: " CONFIRM_PASSWORD
echo

if [[ "$ADMIN_PASSWORD" != "$CONFIRM_PASSWORD" ]]; then
    echo "Passwords do not match."
    exit 1
fi

if [[ -z "$ADMIN_PASSWORD" ]]; then
    echo "Password cannot be empty."
    exit 1
fi

# Generate password hash
PASSWORD_HASH=$(printf '%s' "$ADMIN_PASSWORD" | openssl passwd -6 -stdin)
unset ADMIN_PASSWORD CONFIRM_PASSWORD

# Generate bootc configuration
umask 077

cat > "$OUTPUT" <<EOF
[[customizations.user]]
name = "admin"
password = "${PASSWORD_HASH}"
groups = ["wheel"]
key = "${PUB_KEY}"

[[customizations.filesystem]]
mountpoint = "/"
minsize = "10 GiB"
EOF

chmod 600 "$OUTPUT"

echo "Bootc configuration generated: $OUTPUT"
