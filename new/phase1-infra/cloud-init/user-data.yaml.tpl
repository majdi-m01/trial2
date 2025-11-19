#cloud-config
package_update: true
write_files:
  # -------------------------------------------------------------------------
  # 0. Create User
  # -------------------------------------------------------------------------
  - path: /usr/local/bin/00-create-vault-user.sh
    permissions: "0755"
    owner: root:root
    content: |
      ${create_user_content}

  # -------------------------------------------------------------------------
  # 1. Install Prerequisites (Retry Logic)
  # -------------------------------------------------------------------------
  - path: /usr/local/bin/01-install-prereqs.sh
    permissions: "0755"
    owner: root:root
    content: |
      ${prereqs_content}

  # -------------------------------------------------------------------------
  # 2. Install Vault & Setup User
  # -------------------------------------------------------------------------
  - path: /usr/local/bin/02-install-vault.sh
    permissions: "0755"
    owner: root:root
    content: |
      ${install_vault_content}

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
  - /usr/local/bin/00-create-vault-user.sh
  - /usr/local/bin/01-install-prereqs.sh
  - /usr/local/bin/02-install-vault.sh

  # -------------------------------------------------------------------------
  # 5. Runtime Configuration: Replace placeholders in vault.hcl with local IP and hostname
  # -------------------------------------------------------------------------
  - |
    HOST_SHORT=$(hostname -s)
    PRIVATE_IP=$(hostname -I | awk '{print $1}' | tr -d '[:space:]')
    echo "[cloud-init] Detected short hostname: $HOST_SHORT"
    echo "[cloud-init] Detected private IP: $PRIVATE_IP"
    sed -i -e "s/LOCAL_HOSTNAME/$HOST_SHORT/g" -e "s/LOCAL_IP/$PRIVATE_IP/g" /etc/vault.d/vault.hcl

  - systemctl daemon-reload
  - systemctl enable --now vault