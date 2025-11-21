#!/usr/bin/env bash
set -euo pipefail

if id "vault" >/dev/null 2>&1; then
    echo "[cloud-init] User 'vault' already exists."
else
    echo "[cloud-init] Creating system user 'vault'..."
    useradd --system --home /etc/vault.d --shell /bin/false vault
fi

# Create required directories early with correct ownership
mkdir -p /etc/vault.d /opt/vault/data
chown -R vault:vault /etc/vault.d /opt/vault/data