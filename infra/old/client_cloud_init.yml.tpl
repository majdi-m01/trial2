#cloud-config
#
# This cloud-init script configures a client node.
# It installs and starts both the Consul and Nomad agents in CLIENT mode.
#
package_update: true
packages:
  - unzip
  - docker.io # Required for Nomad to run Docker-based jobs

runcmd:
  # --- Install HashiCorp Binaries ---
  - '[ -f /usr/bin/consul ] || (curl -o consul.zip https://releases.hashicorp.com/consul/1.13.2/consul_1.13.2_linux_amd64.zip && unzip consul.zip && mv consul /usr/bin/)'
  - '[ -f /usr/bin/nomad ] || (curl -o nomad.zip https://releases.hashicorp.com/nomad/1.4.1/nomad_1.4.1_linux_amd64.zip && unzip nomad.zip && mv nomad /usr/bin/)'

  # --- Create Data Directories ---
  - mkdir -p /opt/consul
  - mkdir -p /opt/nomad/data

  # --- Generate Consul Client Config ---
  - |
    cat <<EOF > /etc/consul.hcl
    datacenter = "azure-clients"
    data_dir = "/opt/consul"
    bind_addr = "0.0.0.0"
    client_addr = "0.0.0.0"
    advertise_addr = "${private_ip}"
    server = false
    retry_join = ${consul_retry_join}
    EOF

  # --- Generate Nomad Client Config ---
  - |
    cat <<EOF > /etc/nomad.hcl
    datacenter = "azure-clients"
    data_dir  = "/opt/nomad/data"
    bind_addr = "0.0.0.0"

    client {
      enabled = true
      servers = ${nomad_servers}
    }

    consul {
      address = "127.0.0.1:8500"
    }
    EOF

  # --- Create and Start systemd Services ---
  - 'echo "[Unit]\nDescription=Consul Client Agent\n[Service]\nExecStart=/usr/bin/consul agent -config-file=/etc/consul.hcl\n[Install]\nWantedBy=multi-user.target" > /etc/systemd/system/consul.service'
  - 'echo "[Unit]\nDescription=Nomad Client Agent\n[Service]\nExecStart=/usr/bin/nomad agent -config-file=/etc/nomad.hcl\n[Install]\nWantedBy=multi-user.target" > /etc/systemd/system/nomad.service'
  - systemctl daemon-reload
  - systemctl enable consul nomad
  - systemctl start consul
  - systemctl start nomad