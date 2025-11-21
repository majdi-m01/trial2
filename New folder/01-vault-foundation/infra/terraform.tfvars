location = "westeurope"

# Authentication
admin_username = "azureuser"
admin_password = "YourSecurePassword123!" # Change this!
ssh_allowed_ip = "88.74.173.52"              # Change this to your public IP address

# Key Vault
key_vault_name    = "kv-hashi-infra"
key_vault_sku     = "standard"
key_vault_rg_name = "rg-keyvault"
vault_key_name    = "vault-seal-key"
vault_key_type    = "RSA"
vault_key_size    = 2048

# Vault Cluster (start with 1 for a clean single-node setup, scale to 3 or 5 later)
vault_rg_name               = "rg-vault"
vault_vnet_name             = "vnet-vault"
vault_vnet_address_space    = ["10.0.0.0/16"]
vault_subnet_name           = "snet-vault"
vault_subnet_address_prefix = "10.0.1.0/24"
vault_lb_private_ip         = "10.0.1.10"
vault_lb_port               = 8200
vault_instance_count        = 3 # Scale to 3 or 5 later
vault_vm_size               = "Standard_B1ms"
vault_image_publisher       = "Canonical"
vault_image_offer           = "0001-com-ubuntu-server-jammy"
vault_image_sku             = "22_04-lts"
vault_image_version         = "latest"

# Common Storage
os_disk_type    = "Standard_LRS"
os_disk_size_gb = 30

# Tags
tags = {
  Environment = "dev"
  Project     = "hashi-infra"
  Phase       = "1-vault-foundation"
}