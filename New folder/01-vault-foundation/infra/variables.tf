# Core infrastructure variables
variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "westeurope"
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
  description = "VM size for Vault VMSS (low cost: Standard_B1ms)"
  type        = string
  default     = "Standard_B1ms"
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

# Common Storage variables
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