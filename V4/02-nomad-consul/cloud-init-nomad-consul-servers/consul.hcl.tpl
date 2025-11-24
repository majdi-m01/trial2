datacenter = "servers-datacenter"
data_dir   = "/opt/consul/data"
log_level  = "INFO"

server           = true
bootstrap_expect = ${bootstrap_expect}

ui_config {
  enabled = true
}

bind_addr     = "0.0.0.0"
client_addr   = "0.0.0.0"
advertise_addr = "${advertise_addr_consul}"

retry_join = ["${consul_retry_join_ip}"]

# Optional future: uncomment to switch to Azure tag auto-join (no LB dependency)
# retry_join = ["provider=azure tag_name=ConsulCluster tag_value=nomad-consul-servers"]
#acl {
#  enabled = true
#  default_policy = "deny"
#  enable_token_persistence = true
#}