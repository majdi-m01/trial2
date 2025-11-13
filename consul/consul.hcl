datacenter = "azure"
data_dir = "/opt/consul"
bind_addr = "0.0.0.0" # Listen on all IPv4
advertise_addr = "127.0.0.1"

acl {
  enabled = true
}

ui_config{
  enabled = true
}

server = true
bootstrap_expect=1

client_addr = "0.0.0.0"
