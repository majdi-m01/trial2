#cloud-config
#
# This script configures a Vault server node with Azure Key Vault Auto-Unseal
# and AUTOMATICALLY initializes the server after a short wait period.
#
package_update: true
packages:
  - unzip

runcmd:
  # --- Install Vault ---
  - '[ -f /usr/bin/vault ] || (curl -o vault.zip https://releases.hashicorp.com/vault/1.12.1/vault_1.12.1_linux_amd64.zip && unzip vault.zip && mv vault /usr/bin/)'
  - mkdir -p /opt/vault/data

  # --- Generate Vault Server Config with Auto-Unseal ---
  - |
    cat <<EOF > /etc/vault.hcl
    ui = true
    disable_mlock = true

    storage "raft" {
      path    = "/opt/vault/data"
      node_id = "${node_name}"
      retry_join {
        leader_api_addr = "http://${leader_private_ip}:8200"
      }
    }

    listener "tcp" {
      address       = "0.0.0.0:8200"
      tls_disable   = 1
    }

    seal "azurekeyvault" {
      tenant_id      = "${tenant_id}"
      vault_name     = "${key_vault_name}"
      key_name       = "${key_name}"
    }

    api_addr = "http://${access_public_ip}:8200"
    cluster_addr = "http://${private_ip}:8201"
    EOF

  # --- Create and Start systemd Service ---
  - 'echo "[Unit]\nDescription=Vault Server\n[Service]\nExecStart=/usr/bin/vault server -config=/etc/vault.hcl\n[Install]\nWantedBy=multi-user.target" > /etc/systemd/system/vault.service'
  - systemctl daemon-reload
  - systemctl enable vault
  - systemctl start vault

  # --- Automatically Initialize Vault (Idempotent) ---
  # This command will run only if the vault.initialized file does not exist.
  # It waits 30 seconds for the service to stabilize before initializing.
  - |
    sleep 30
    if [ ! -f /opt/vault/vault.initialized ]; then
      /usr/bin/env VAULT_ADDR=http://127.0.0.1:8200 /usr/bin/vault operator init -key-shares=1 -key-threshold=1 > /opt/vault/init.keys && touch /opt/vault/vault.initialized
    fi