# Authentication
admin_username = "azureuser"
admin_password = "YourSecurePassword123!" # Change this!
ssh_allowed_ip = [
  "88.74.173.52",
  "176.2.16.211"
]

# Nomad/Consul
nomad_consul_rg_name               = "rg-nomad-consul"
nomad_consul_vnet_name             = "vnet-nomad-consul"
nomad_consul_vnet_address_space    = ["10.1.0.0/16"]
nomad_consul_subnet_name           = "snet-nomad-consul"
nomad_consul_subnet_address_prefix = "10.1.1.0/24"
nomad_consul_lb_private_ip         = "10.1.1.10"
nomad_lb_port                      = 4646
nomad_consul_instance_count        = 3 # Scale to 3 later
nomad_consul_vm_size               = "Standard_B1ms"
nomad_consul_image_publisher       = "Canonical"
nomad_consul_image_offer           = "0001-com-ubuntu-server-jammy"
nomad_consul_image_sku             = "22_04-lts"
nomad_consul_image_version         = "latest"

# Peering and Storage
enable_vnet_peering = true
os_disk_type        = "Standard_LRS"
os_disk_size_gb     = 30

# Tags
tags = {
  Environment = "dev"
  Project     = "hashi-infra"
  Phase       = "2-nomad-consul"
}


vault_lb_private_ip = "10.0.1.10"