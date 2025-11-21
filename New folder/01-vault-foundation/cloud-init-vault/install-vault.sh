#!/usr/bin/env bash
# FILE: cloud-init/install-vault.sh
set -euo pipefail

VAULT_VERSION="1.18.1"   # guaranteed to exist forever

echo "[cloud-init] Installing Vault ${VAULT_VERSION}..."

if command -v vault >/dev/null 2>&1; then
  echo "[cloud-init] Vault already installed ($(vault version))."
  exit 0
fi

cd /tmp

echo "[cloud-init] Downloading vault_${VAULT_VERSION}_linux_amd64.zip ..."
curl -fsSLO "https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip"

echo "[cloud-init] Unzipping..."
unzip "vault_${VAULT_VERSION}_linux_amd64.zip"

echo "[cloud-init] Installing binary..."
install -m 0755 vault /usr/local/bin/vault
rm -f vault "vault_${VAULT_VERSION}_linux_amd64.zip"

# Required capability for mlock (even though we disable mlock, keep it)
if command -v setcap >/dev/null 2>&1; then
  setcap cap_ipc_lock=+ep /usr/local/bin/vault || true
fi

echo "[cloud-init] Vault ${VAULT_VERSION} installed successfully!"
vault version