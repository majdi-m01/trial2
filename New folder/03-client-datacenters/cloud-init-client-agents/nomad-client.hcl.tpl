datacenter = "${datacenter}"
data_dir   = "/opt/nomad/data"
log_level  = "INFO"

# This is a client agent
client {
  enabled = true
}

# Point to the local Consul agent for service discovery
consul {
  address = "127.0.0.1:8500"
}