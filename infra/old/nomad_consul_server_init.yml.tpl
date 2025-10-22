#cloud-config
#
# This script configures a server node with Consul and Nomad.
# It now includes robust wait logic to poll the Vault health endpoint
# to ensure Vault is unsealed before Nomad starts.
#
package_update: true
packages:
  - unzip
  - docker.io
  - netcat-openbsd # Required for the 'nc' command used in the wait loops

runcmd:
  # --- Install Binaries ---
  - '[ -f /usr/bin/consul ] || (curl -o consul.zip https://releases.hashicorp.com/consul/1.13.2/consul_1.13.2_linux_amd64.zip && unzip consul.zip && mv consul /usr/bin/)'
  - '[ -f /usr/bin/nomad ] || (curl -o nomad.zip https://releases.hashicorp.com/nomad/1.4.1/nomad_1.4.1_linux_amd64.zip && unzip nomad.zip && mv nomad /usr/bin/)'
  - mkdir -p /opt/consul /opt/nomad/data

  # --- Generate Consul Server Config ---
  - |
    cat <<EOF > /etc/consul.hcl
    datacenter = "azure-servers"
    data_dir = "/opt/consul"
    bind_addr = "0.0.0.0"
    client_addr = "0.0.0.0"
    advertise_addr = "${private_ip}"
    bootstrap_expect = ${server_count}
    server = true
    ui_config { enabled = true }
    retry_join = ${consul_retry_join}
    acl { enabled = true, default_policy = "deny", enable_token_persistence = true }
    EOF

  # --- Generate Nomad Server Config ---
  - |
    cat <<EOF > /etc/nomad.hcl
    datacenter = "azure-servers"
    data_dir  = "/opt/nomad/data"
    bind_addr = "0.0.0.0"
    server { enabled = true, bootstrap_expect = ${server_count} }
    acl { enabled = true }
    vault { enabled = true, address = "http://${vault_leader_ip}:8200" }
    consul { address = "127.0.0.1:8500" }
    EOF

  # --- Create systemd Services ---
  - 'echo "[Unit]\nDescription=Consul Server\n[Service]\nExecStart=/usr/bin/consul agent -config-file=/etc/consul.hcl\n[Install]\nWantedBy=multi-user.target" > /etc/systemd/system/consul.service'
  - 'echo "[Unit]\nDescription=Nomad Server\n[Service]\nExecStart=/usr/bin/nomad agent -config-file=/etc/nomad.hcl\n[Install]\nWantedBy=multi-user.target" > /etc/systemd/system/nomad.service'
  - systemctl daemon-reload
  - systemctl enable consul nomad

  # --- Start Services with Intelligent Wait Logic ---
  - systemctl start consul
  - |
    echo "Waiting until Vault is unsealed and ready..."
    # FIX: The %{http_code} is escaped as %%{http_code} to prevent Terraform's template engine from interpreting it.
    while [ "$(curl -s -o /dev/null -w '%%{http_code}' http://${vault_leader_ip}:8200/v1/sys/health)" != "200" ]; do
      echo "Vault is not ready yet. Waiting 10 seconds..."
      sleep 10
    done
    echo "Vault is unsealed and ready! Starting Nomad."
  - systemctl start nomad

  # --- Automatically Bootstrap Consul and Nomad (Idempotent) ---
  - |
    sleep 30 # Give services time to start and elect a leader
    if [ ! -f /opt/consul/consul.token ]; then
      /usr/bin/consul acl bootstrap > /opt/consul/consul.token
    fi
    if [ ! -f /opt/nomad/nomad.token ]; then
      /usr/bin/env NOMAD_ADDR=http://127.0.0.1:4646 /usr/bin/nomad acl bootstrap > /opt/nomad/nomad.token
    fi