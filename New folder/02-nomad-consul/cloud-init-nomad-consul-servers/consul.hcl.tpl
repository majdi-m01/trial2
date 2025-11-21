datacenter       = "servers-datacenter"
data_dir         = "/opt/consul/data"
log_level        = "INFO"

server           = true
bootstrap_expect = ${bootstrap_expect}

ui_config {
  enabled = true
}

bind_addr   = "0.0.0.0" #private ip??
client_addr = "0.0.0.0"

advertise_addr = "${advertise_addr_consul}"  # Advertise the VM's private IP for gossip

# Auto-join using the internal load balancer's address.
retry_join = ["${leader_api_addr}"]

#acl {
#  enabled = true
#  default_policy = "deny"
#  enable_token_persistence = true
#}