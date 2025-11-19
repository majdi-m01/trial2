#!/usr/bin/env bash
set -euo pipefail

echo "[cloud-init] Installing HashiCorp Vault..."

# Determine latest OSS version
LATEST=""
if command -v jq >/dev/null 2>&1; then
  LATEST=$(curl -fsSL https://releases.hashicorp.com/vault/index.json | \
           jq -r '.versions[].version' | \
           grep -vE 'ent|beta|rc|alpha' | \
           sort -V | tail -n1) || true
fi

# Fallback if lookup fails
if [[ -z "$LATEST" ]]; then
  echo "[cloud-init] WARNING: Could not fetch latest version, falling back to 1.18.1"
  LATEST="1.18.1"
fi

echo "[cloud-init] Installing Vault version: $LATEST"

if command -v vault >/dev/null 2>&1; then
  echo "[cloud-init] Vault binary already present."
else
  cd /tmp
  curl -fsSLO "https://releases.hashicorp.com/vault/${LATEST}/vault_${LATEST}_linux_amd64.zip"
  unzip -o "vault_${LATEST}_linux_amd64.zip"
  mv vault /usr/local/bin/vault
  chmod 0755 /usr/local/bin/vault
  setcap cap_ipc_lock=+ep /usr/local/bin/vault
  rm -f "vault_${LATEST}_linux_amd64.zip"
  echo "[cloud-init] Vault $LATEST installed."
fi

# Ensure config file has correct ownership (just in case)
if [[ -f /etc/vault.d/vault.hcl ]]; then
  chown vault:vault /etc/vault.d/vault.hcl
  chmod 640 /etc/vault.d/vault.hcl
fi

echo "[cloud-init] Vault installation complete."