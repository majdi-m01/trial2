###############################################################################
# Subscription / Environment / Tags
###############################################################################

subscription_id = "f8cea8db-c84b-44eb-aa67-f8c938abbfda" # Target Azure subscription ID

environment  = "dev"        # Environment label (dev/staging/prod)
project_name = "hashistack" # Prefix for resource names

location = "westeurope" # Azure region for all resources

tags = { # Common tags applied to all resources
  CostCenter  = "SpikeReply"
  ManagedBy   = "Terraform - Majdi"
  Environment = "dev"
  Project     = "hashistack"
}

###############################################################################
# Admin Access
###############################################################################

vm_admin_username = "adminuser" # Admin username for SSH on VMSS nodes
# Your SSH public key for VMSS
admin_ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCxzCpD2oQJ3N25HTMGIPizyFZ14WEHNXXHT6RmjKnZkczoOuSoKwROvZOJs9P87RCEYRFtISJERqyA3KmvuOgaHZsD3VCpeloVKFmTuKjnZ6NwCegtqcb4YcF7n8qlDbrdyHa8hfgguJAti0XFjckTaC2B/PrDuMLxzxCyMimLLcvEZGBPU2Bou8zlnD4vX+KfHqP1brxzF0OayYqdM5ik8V7iVXbBULKuuE0J9tjvX5M4OlD4CDJjzSL+0jTgPlx7X9FtFG8sw/2NsOnsISK62oVTqmMjMXmnboOW8bQtprVP+eR9TfkyunQUTFFJaG6ViisdzwywiwaTlmYXGRj9++yFJDmGg/4efUOhwsotODBTfZEEEudnlZ1XCnzqBGBQHMib//nzlAotGCsWM5e5wEUFpcFsJh1PDLntM8hUmzxVArdGAgj4AWdJduwoGcfQiT/vYyqrdjtik20oluNBN0Xid1oK/X4lFnvUVdYbAN/UqgVhJEtc5L/6v6sY6N60bUvHeogz2W5rspIahVBTZdl25hNzwXkZs1Zj6Ha9K1Vr95R5ZiLt/U1lgofNrSxKv21hrFAjnt3y8eyhiXuGy4pxssnwU3Er16XzLaJ0KeBnsCyl383nQpCDCON10ox7l81gPLr1YgLs0ZA+4xrUsqoFhuhY5RaSRirAcVvHLQ=="
admin_ip_addresses = [ # CIDRs allowed to SSH (tighten for prod)
  "212.114.159.234",
  "20.93.142.26",
  "88.64.185.12"
]

enable_password_auth = true
vm_admin_password    = "YourStrongPassword!ChangeMe123"

###############################################################################
# Networking - Server VNet and Subnets
###############################################################################

server_vnet_cidr  = "10.0.0.0/16" # Server VNet CIDR
vault_subnet_cidr = "10.0.1.0/24" # Vault subnet CIDR
core_subnet_cidr  = "10.0.2.0/24" # Consul/Nomad subnet CIDR

###############################################################################
# Client Datacenters (one VNet + one subnet per DC)
###############################################################################

# Client pools (per datacenter VMSS)
clients_instance_count     = 2               # Start at 0 for cost control; set 1+ when needed
clients_vm_size            = "Standard_B1ms" # Low-cost default
clients_os_disk_type       = "Standard_LRS"
clients_os_disk_size_gb    = 32
clients_upgrade_mode       = "Manual"
clients_zones              = []   # [] means no AZ spreading for cheapest tests
clients_custom_data_base64 = null # Set to base64 cloud-init when ready

# Define as many datacenters as needed. Each DC defines its VNet and a single subnet.

datacenters = {
  dc1 = {
    vnet_cidr    = "10.10.0.0/16" # Client VNet CIDR for dc1
    subnet_cidr  = "10.10.1.0/24" # Client subnet CIDR for dc1
    client_count = 2              # Placeholder for future use
  }
  dc2 = {
    vnet_cidr    = "10.20.0.0/16"
    subnet_cidr  = "10.20.1.0/24"
    client_count = 2
  }
}

enable_vnet_peering = true # Peer each client VNet with the server VNet

###############################################################################
# Key Vault (software-protected key for Vault auto-unseal)
###############################################################################

kv_name     = "kv-hashistack"    # Base KV name; random suffix appended automatically
kv_key_name = "vault-unseal-key" # Name of the unseal key inside Key Vault

###############################################################################
# Vault VM Scale Set
###############################################################################

vault_instance_count = 3               # 1 for dev, or an odd number >=3 for HA
vault_vm_size        = "Standard_B1ms" # VM size for Vault VMSS

vault_image = { # OS image for Vault nodes
  publisher = "Canonical"
  offer     = "0001-com-ubuntu-server-jammy"
  sku       = "22_04-lts"
  version   = "latest"
}

vault_os_disk_type       = "Standard_LRS" # OS disk type for Vault VMSS
vault_os_disk_size_gb    = 30             # OS disk size (GB) for Vault VMSS
vault_upgrade_mode       = "Manual"       # VMSS upgrade mode: Manual|Automatic|Rolling
vault_zones              = []             # Spread across AZs (adjust per region)
enable_vault_ilb         = true           # Internal LB in front of Vault VMSS (false by default)
vault_custom_data_base64 = null           # Base64 cloud-init (set later when you add bootstrap)


vault_version      = "1.15.6"
vault_api_addr     = "" # let cloud-init derive from primary IP
vault_cluster_addr = ""
vault_tls_disable  = "1" # dev: no TLS

###############################################################################
# Consul/Nomad (Core) VM Scale Set
###############################################################################

core_instance_count = 3               # 1 for dev, or an odd number >=3 for HA
core_vm_size        = "Standard_B1ms" # VM size for Core VMSS

core_image = { # OS image for Consul/Nomad nodes
  publisher = "Canonical"
  offer     = "0001-com-ubuntu-server-jammy"
  sku       = "22_04-lts"
  version   = "latest"
}

core_os_disk_type       = "Standard_LRS" # OS disk type for Core VMSS
core_os_disk_size_gb    = 30             # OS disk size (GB) for Core VMSS
core_upgrade_mode       = "Manual"       # VMSS upgrade mode: Manual|Automatic|Rolling
core_zones              = []             # Spread across AZs (adjust per region)
enable_core_ilb         = true           # Internal LB in front of Core VMSS (false by default)
core_custom_data_base64 = null           # Base64 cloud-init (set later when you add bootstrap)

###############################################################################
# JUMPHOST VM
###############################################################################

enable_jump_host          = true
jump_host_vm_size         = "Standard_B1ms" # keep small for cost
jump_host_os_disk_size_gb = 30
jump_host_subnet          = "vault" # or "core"
jump_host_ssh_public_key  = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCxzCpD2oQJ3N25HTMGIPizyFZ14WEHNXXHT6RmjKnZkczoOuSoKwROvZOJs9P87RCEYRFtISJERqyA3KmvuOgaHZsD3VCpeloVKFmTuKjnZ6NwCegtqcb4YcF7n8qlDbrdyHa8hfgguJAti0XFjckTaC2B/PrDuMLxzxCyMimLLcvEZGBPU2Bou8zlnD4vX+KfHqP1brxzF0OayYqdM5ik8V7iVXbBULKuuE0J9tjvX5M4OlD4CDJjzSL+0jTgPlx7X9FtFG8sw/2NsOnsISK62oVTqmMjMXmnboOW8bQtprVP+eR9TfkyunQUTFFJaG6ViisdzwywiwaTlmYXGRj9++yFJDmGg/4efUOhwsotODBTfZEEEudnlZ1XCnzqBGBQHMib//nzlAotGCsWM5e5wEUFpcFsJh1PDLntM8hUmzxVArdGAgj4AWdJduwoGcfQiT/vYyqrdjtik20oluNBN0Xid1oK/X4lFnvUVdYbAN/UqgVhJEtc5L/6v6sY6N60bUvHeogz2W5rspIahVBTZdl25hNzwXkZs1Zj6Ha9K1Vr95R5ZiLt/U1lgofNrSxKv21hrFAjnt3y8eyhiXuGy4pxssnwU3Er16XzLaJ0KeBnsCyl383nQpCDCON10ox7l81gPLr1YgLs0ZA+4xrUsqoFhuhY5RaSRirAcVvHLQ=="