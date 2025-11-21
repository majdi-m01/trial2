datacenter = "servers-datacenter"
data_dir   = "/opt/nomad/data"
log_level  = "INFO"

server {
  enabled          = true
  bootstrap_expect = ${bootstrap_expect}
}

client {
  enabled = false 
}

# Point to the local Consul agent for service discovery
consul {
  address = "127.0.0.1:8500"
}

# Advertise the node's local IP for communication
advertise {
    http = "${advertise_addr_nomad}:4646"
    rpc  = "${advertise_addr_nomad}:4647"
    serf = "${advertise_addr_nomad}:4648"
}

# Networking
bind_addr = "0.0.0.0" # Listen on all interfaces so LB requests work

# INTEGRATION: Vault (Connecting to LB #1)
vault {
  enabled = true
  
  # Point this to your Azure Load Balancer #1 IP/DNS
  address = "${vault_lb_address}"
  
  # Since you are using Azure, you might leave the token management 
  # to the specific Vault/Nomad integration tutorial, but you need
  # a token to start (or use create_from_role if configured).
  # token = "..." 
  
  # DISABLE TLS (As requested)
  tls_skip_verify = true
}