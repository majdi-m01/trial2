# Copy to terraform.tfvars and customize

location = "westeurope"

# Authentication
admin_username = "azureuser"
admin_password = "YourSecurePassword123!" # Change this!
ssh_allowed_ip = "88.74.173.52"

# Key Vault
key_vault_name    = "kv-hashi-infra"
key_vault_sku     = "standard"
key_vault_rg_name = "rg-keyvault"
vault_key_name    = "vault-seal-key"
vault_key_type    = "RSA"
vault_key_size    = 2048

# Vault Cluster (start with 1 for clean single-node)
vault_rg_name               = "rg-vault"
vault_vnet_name             = "vnet-vault"
vault_vnet_address_space    = ["10.0.0.0/16"]
vault_subnet_name           = "snet-vault"
vault_subnet_address_prefix = "10.0.1.0/24"
vault_lb_private_ip         = "10.0.1.10"
vault_lb_port               = 8200
vault_instance_count        = 3 # Scale to 3/5 later
vault_vm_size               = "Standard_B1ms"
vault_image_publisher       = "Canonical"
vault_image_offer           = "0001-com-ubuntu-server-jammy"
vault_image_sku             = "22_04-lts"
vault_image_version         = "latest"

# Nomad/Consul
nomad_consul_rg_name               = "rg-nomad-consul"
nomad_consul_vnet_name             = "vnet-nomad-consul"
nomad_consul_vnet_address_space    = ["10.1.0.0/16"]
nomad_consul_subnet_name           = "snet-nomad-consul"
nomad_consul_subnet_address_prefix = "10.1.1.0/24"
nomad_consul_lb_private_ip         = "10.1.1.10"
nomad_lb_port                      = 4646
nomad_consul_instance_count        = 1 # Scale to 2/3 later
nomad_consul_vm_size               = "Standard_B1ls"
nomad_consul_image_publisher       = "Canonical"
nomad_consul_image_offer           = "0001-com-ubuntu-server-jammy"
nomad_consul_image_sku             = "22_04-lts"
nomad_consul_image_version         = "latest"

# Clients Data Centers (start with single DC, 1 VM)
clients_rg_name            = "rg-clients"
clients_vnet_name          = "vnet-clients"
clients_vnet_address_space = ["10.2.0.0/16"]
datacenter_configs         = { 0 = 1 } # DC 0: 1 clean VM
datacenter_lb_port         = 80
clients_vm_size            = "Standard_B1ls"
clients_image_publisher    = "Canonical"
clients_image_offer        = "0001-com-ubuntu-server-jammy"
clients_image_sku          = "22_04-lts"
clients_image_version      = "latest"
datacenter_subnet_prefixes = [] # Auto-generate

# Peering and Storage
enable_vnet_peering = true
os_disk_type        = "Standard_LRS"
os_disk_size_gb     = 30

# Tags
tags = {
  Environment = "dev"
  Project     = "hashi-infra"
  Phase       = "1-infra-only"
}