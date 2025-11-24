# Authentication
admin_username = "azureuser"
admin_password = "YourSecurePassword123!" # Change this!
ssh_allowed_ip = "88.74.173.52"              # Change this to your public IP address

# Clients Data Centers (start with single DC, 1 VM)
clients_rg_name            = "rg-clients"
clients_vnet_name          = "vnet-clients"
clients_vnet_address_space = ["10.2.0.0/16"]
datacenter_configs         = { "dc1" = 2 } # Deploy 2 client VMs in datacenter "dc1"
datacenter_lb_port         = 80
clients_vm_size            = "Standard_B1ls"
clients_image_publisher    = "Canonical"
clients_image_offer        = "0001-com-ubuntu-server-jammy"
clients_image_sku          = "22_04-lts"
clients_image_version      = "latest"
datacenter_subnet_prefixes = [] # Let Terraform auto-generate subnet prefixes

# Peering and Storage
enable_vnet_peering = true
os_disk_type        = "Standard_LRS"
os_disk_size_gb     = 30

# Tags
tags = {
  Environment = "dev"
  Project     = "hashi-infra"
  Phase       = "3-client-datacenters"
}