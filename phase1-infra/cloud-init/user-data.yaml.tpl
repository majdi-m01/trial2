#cloud-config
package_update: true
write_files:
  # -------------------------------------------------------------------------
  # 1. Install Prerequisites (Retry Logic)
  # -------------------------------------------------------------------------
  - path: /usr/local/bin/01-install-prereqs.sh
    permissions: "0755"
    owner: root:root
    content: |
      #!/usr/bin/env bash
      set -euo pipefail
      
      # Retry loop for apt-get to handle transient cloud networking issues
      for i in {1..12}; do
        if apt-get update -y && apt-get install -y curl unzip jq; then
          echo "[cloud-init] Prereqs installed successfully."
          exit 0
        fi
        echo "[cloud-init] apt retry $i/12..."
        sleep 10
      done
      echo "[cloud-init] Failed to install prerequisites after retries." >&2
      exit 1

  # -------------------------------------------------------------------------
  # 2. Install Vault & Setup User
  # -------------------------------------------------------------------------
  - path: /usr/local/bin/02-install-vault.sh
    permissions: "0755"
    owner: root:root
    content: |
      #!/usr/bin/env bash
      set -euo pipefail

      # --- A. Create User First ---
      if ! id -u vault >/dev/null 2>&1; then
        echo "[cloud-init] Creating vault user..."
        useradd --system --home /etc/vault.d --shell /bin/false vault
      fi

      # --- B. Determine Version ---
      LATEST=""
      
      # 1. Try dynamic lookup
      if command -v jq >/dev/null; then
        echo "[cloud-init] Attempting to fetch latest version..."
        # Note: We use $${} to tell Terraform "Leave this for Bash"
        LATEST=$(curl -sL https://releases.hashicorp.com/vault/index.json | jq -r '.versions[].version' | grep -vE 'ent|beta|rc|alpha' | sort -V | tail -n1 || true)
      fi

      # 2. Fallback if dynamic lookup failed
      if [[ -z "$${LATEST}" ]]; then
        echo "[cloud-init] WARNING: Could not fetch latest version. Defaulting to fallback."
        LATEST="1.18.1"
      fi

      echo "[cloud-init] Selected Version: $${LATEST}"

      # --- C. Install Binary ---
      if command -v vault >/dev/null 2>&1; then
        echo "[cloud-init] Vault already installed."
      else
        echo "[cloud-init] Downloading Vault $${LATEST}..."
        cd /tmp
        
        # ESCAPED VARIABLES HERE: $${LATEST}
        if curl -fsSLO "https://releases.hashicorp.com/vault/$${LATEST}/vault_$${LATEST}_linux_amd64.zip"; then
           unzip -o "vault_$${LATEST}_linux_amd64.zip" -d /usr/local/bin
           chmod 0755 /usr/local/bin/vault
           setcap cap_ipc_lock=+ep /usr/local/bin/vault
           rm -f "vault_$${LATEST}_linux_amd64.zip"
           echo "[cloud-init] Vault binary installed."
        else
           echo "[cloud-init] CRITICAL: Download failed. Check network/version." >&2
           exit 1
        fi
      fi

      # --- D. Configure Directories & Permissions ---
      mkdir -p /etc/vault.d /opt/vault/data
      chown -R vault:vault /etc/vault.d /opt/vault/data
      
      if [ -f /etc/vault.d/vault.hcl ]; then
         chown vault:vault /etc/vault.d/vault.hcl
         chmod 0640 /etc/vault.d/vault.hcl
      fi

  # -------------------------------------------------------------------------
  # 3. Vault Configuration (Injected via Terraform)
  # -------------------------------------------------------------------------
  - path: /etc/vault.d/vault.hcl
    permissions: "0640"
    owner: root:root
    content: |
      ${vault_hcl_content}

  # -------------------------------------------------------------------------
  # 4. Systemd Service
  # -------------------------------------------------------------------------
  - path: /etc/systemd/system/vault.service
    permissions: "0644"
    owner: root:root
    content: |
      ${vault_service_content}

runcmd:
  - /usr/local/bin/01-install-prereqs.sh
  - /usr/local/bin/02-install-vault.sh
  - systemctl daemon-reload
  - systemctl enable --now vault