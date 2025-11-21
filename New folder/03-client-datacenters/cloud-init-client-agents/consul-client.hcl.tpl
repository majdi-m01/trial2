datacenter = "${datacenter}"
data_dir   = "/opt/consul/data"
log_level  = "INFO"

# This is a client agent
server = false

# Join the Consul servers via their internal load balancer
retry_join = ["${consul_server_lb_ip}"]