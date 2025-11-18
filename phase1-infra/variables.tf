# Core infrastructure variables
variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "East US"
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}

# Authentication variables
variable "admin_username" {
  description = "Admin username for all VMs"
  type        = string
  default     = "azureuser"
}

variable "admin_password" {
  description = "Admin password for all VMs (use secrets management in production)"
  type        = string
  sensitive   = true
}

variable "ssh_allowed_ip" {
  description = "CIDR for SSH access (e.g., your IP/32)"
  type        = string
  default     = "0.0.0.0/0" # Restrict this in production
}

# Key Vault variables
variable "key_vault_name" {
  description = "Name for Azure Key Vault"
  type        = string
  default     = "kv-hashi"
}

variable "key_vault_sku" {
  description = "SKU for Key Vault"
  type        = string
  default     = "standard" # Low cost
}

variable "key_vault_rg_name" {
  description = "Resource Group name for Key Vault"
  type        = string
  default     = "rg-keyvault"
}

variable "vault_key_name" {
  description = "Name of the key in Key Vault for Vault auto-unseal"
  type        = string
  default     = "vault-seal-key"
}

variable "vault_key_type" {
  description = "Type of key for Vault auto-unseal (RSA)"
  type        = string
  default     = "RSA"
}

variable "vault_key_size" {
  description = "Size of the key for Vault auto-unseal"
  type        = number
  default     = 2048
}

# Vault Cluster variables
variable "vault_rg_name" {
  description = "Resource Group name for Vault cluster"
  type        = string
  default     = "rg-vault"
}

variable "vault_vnet_name" {
  description = "VNet name for Vault cluster"
  type        = string
  default     = "vnet-vault"
}

variable "vault_vnet_address_space" {
  description = "Address space for Vault VNet"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "vault_subnet_name" {
  description = "Subnet name for Vault cluster"
  type        = string
  default     = "snet-vault"
}

variable "vault_subnet_address_prefix" {
  description = "Address prefix for Vault subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "vault_lb_private_ip" {
  description = "Private IP for Vault internal LB frontend"
  type        = string
  default     = "10.0.1.10"
}

variable "vault_lb_port" {
  description = "Port for Vault LB rule"
  type        = number
  default     = 8200
}

variable "vault_instance_count" {
  description = "Number of instances in Vault VMSS (1, 3, or 5)"
  type        = number
  default     = 1
  validation {
    condition     = contains([1, 3, 5], var.vault_instance_count)
    error_message = "Vault instance count must be 1, 3, or 5."
  }
}

variable "vault_vm_size" {
  description = "VM size for Vault VMSS (low cost: Standard_B1ls)"
  type        = string
  default     = "Standard_B1ls"
}

variable "vault_image_publisher" {
  description = "OS image publisher for Vault VMs"
  type        = string
  default     = "Canonical"
}

variable "vault_image_offer" {
  description = "OS image offer for Vault VMs"
  type        = string
  default     = "0001-com-ubuntu-server-jammy"
}

variable "vault_image_sku" {
  description = "OS image SKU for Vault VMs"
  type        = string
  default     = "22_04-lts"
}

variable "vault_image_version" {
  description = "OS image version for Vault VMs"
  type        = string
  default     = "latest"
}

# Nomad/Consul Server Cluster variables
variable "nomad_consul_rg_name" {
  description = "Resource Group name for Nomad/Consul cluster"
  type        = string
  default     = "rg-nomad-consul"
}

variable "nomad_consul_vnet_name" {
  description = "VNet name for Nomad/Consul cluster"
  type        = string
  default     = "vnet-nomad-consul"
}

variable "nomad_consul_vnet_address_space" {
  description = "Address space for Nomad/Consul VNet"
  type        = list(string)
  default     = ["10.1.0.0/16"]
}

variable "nomad_consul_subnet_name" {
  description = "Subnet name for Nomad/Consul cluster"
  type        = string
  default     = "snet-nomad-consul"
}

variable "nomad_consul_subnet_address_prefix" {
  description = "Address prefix for Nomad/Consul subnet"
  type        = string
  default     = "10.1.1.0/24"
}

variable "nomad_consul_lb_private_ip" {
  description = "Private IP for Nomad/Consul internal LB frontend"
  type        = string
  default     = "10.1.1.10"
}

variable "nomad_lb_port" {
  description = "Port for Nomad LB rule (API/UI)"
  type        = number
  default     = 4646
}

variable "nomad_consul_instance_count" {
  description = "Number of instances in Nomad/Consul VMSS (1, 2, or 3)"
  type        = number
  default     = 1
  validation {
    condition     = contains([1, 2, 3], var.nomad_consul_instance_count)
    error_message = "Nomad/Consul instance count must be 1, 2, or 3."
  }
}

variable "nomad_consul_vm_size" {
  description = "VM size for Nomad/Consul VMSS (low cost: Standard_B1ls)"
  type        = string
  default     = "Standard_B1ls"
}

variable "nomad_consul_image_publisher" {
  description = "OS image publisher for Nomad/Consul VMs"
  type        = string
  default     = "Canonical"
}

variable "nomad_consul_image_offer" {
  description = "OS image offer for Nomad/Consul VMs"
  type        = string
  default     = "0001-com-ubuntu-server-jammy"
}

variable "nomad_consul_image_sku" {
  description = "OS image SKU for Nomad/Consul VMs"
  type        = string
  default     = "22_04-lts"
}

variable "nomad_consul_image_version" {
  description = "OS image version for Nomad/Consul VMs"
  type        = string
  default     = "latest"
}

# Client Data Centers variables
variable "clients_rg_name" {
  description = "Resource Group name for Clients and Data Centers"
  type        = string
  default     = "rg-clients"
}

variable "clients_vnet_name" {
  description = "VNet name for Clients"
  type        = string
  default     = "vnet-clients"
}

variable "clients_vnet_address_space" {
  description = "Address space for Clients VNet"
  type        = list(string)
  default     = ["10.2.0.0/16"]
}

variable "datacenter_configs" {
  description = "Map of datacenter index (starting from 0) to VMSS instance count for each Data Center"
  type        = map(number)
  default     = { 0 = 1 }
}

variable "datacenter_lb_port" {
  description = "Port for Data Center LB rules (external ingress)"
  type        = number
  default     = 80
}

variable "clients_vm_size" {
  description = "VM size for Client Data Center VMSS (low cost: Standard_B1ls)"
  type        = string
  default     = "Standard_B1ls"
}

variable "clients_image_publisher" {
  description = "OS image publisher for Client VMs"
  type        = string
  default     = "Canonical"
}

variable "clients_image_offer" {
  description = "OS image offer for Client VMs"
  type        = string
  default     = "0001-com-ubuntu-server-jammy"
}

variable "clients_image_sku" {
  description = "OS image SKU for Client VMs"
  type        = string
  default     = "22_04-lts"
}

variable "clients_image_version" {
  description = "OS image version for Client VMs"
  type        = string
  default     = "latest"
}

variable "datacenter_subnet_prefixes" {
  description = "List of address prefixes for Data Center subnets (one per DC). If empty, auto-generates sequential."
  type        = list(string)
  default     = []
}

# VNet Peering variables (for inter-cluster communication)
variable "enable_vnet_peering" {
  description = "Enable VNet peering between all VNets"
  type        = bool
  default     = true
}

# Storage variables (low cost)
variable "os_disk_type" {
  description = "OS disk storage type (Standard_LRS for low cost)"
  type        = string
  default     = "Standard_LRS"
}

variable "os_disk_size_gb" {
  description = "OS disk size in GB"
  type        = number
  default     = 30
}