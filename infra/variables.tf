# ==============================================================================
# General settings
# ==============================================================================

variable "subscription_id" {
  description = "Target Azure subscription ID."
  type        = string
}

variable "location" {
  description = "Azure region for all resources."
  type        = string
  default     = "Germany West Central"
}

variable "environment" {
  description = "Environment label (dev/staging/prod)."
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name used as a prefix for resource names."
  type        = string
  default     = "hashistack"
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default = {
    CostCenter = "SpikeReply"
  }
}

# ==============================================================================
# Admin access
# ==============================================================================

variable "vm_admin_username" {
  description = "Admin username for SSH."
  type        = string
  default     = "azureuser"
}

variable "admin_ip_addresses" {
  description = "List of CIDRs allowed for SSH access."
  type        = list(string)
}

variable "admin_ssh_public_key" {
  description = "SSH public key used for all VMSS instances."
  type        = string
}

variable "enable_password_auth" {
  description = "Enable SSH password authentication on VMSS instances."
  type        = bool
  default     = false
}

variable "vm_admin_password" {
  description = "Admin password for SSH (used if enable_password_auth = true)."
  type        = string
  sensitive   = true
  default     = null
}

# ==============================================================================
# Networking (Server VNet + Subnets)
# ==============================================================================

variable "server_vnet_cidr" {
  description = "CIDR for the server VNet."
  type        = string
  default     = "10.0.0.0/16"
}

variable "vault_subnet_cidr" {
  description = "CIDR for the Vault subnet."
  type        = string
  default     = "10.0.1.0/24"
}

variable "core_subnet_cidr" {
  description = "CIDR for the Consul/Nomad subnet."
  type        = string
  default     = "10.0.2.0/24"
}

# ==============================================================================
# Clients (datacenters)
# ==============================================================================

variable "clients_instance_count" {
  description = "Default number of client instances per datacenter VMSS."
  type        = number
  default     = 0
}

variable "clients_vm_size" {
  description = "VM size for client VMSS nodes."
  type        = string
  default     = "Standard_B1ms"
}

variable "clients_image" {
  description = "Image reference for client VMSS."
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  default = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

variable "clients_os_disk_type" {
  description = "OS disk type for client VMSS."
  type        = string
  default     = "Standard_LRS"
}

variable "clients_os_disk_size_gb" {
  description = "OS disk size (GB) for client VMSS."
  type        = number
  default     = 32
}

variable "clients_upgrade_mode" {
  description = "Upgrade mode for client VMSS."
  type        = string
  default     = "Manual"
}

variable "clients_zones" {
  description = "Availability zones for client VMSS."
  type        = list(string)
  default     = []
}

variable "clients_custom_data_base64" {
  description = "Base64-encoded cloud-init for client nodes (optional; infra-only by default)."
  type        = string
  default     = null
}

variable "datacenters" {
  description = "Map of datacenters and their network/client sizing."
  type = map(object({
    vnet_cidr    = string # VNet CIDR for the DC
    subnet_cidr  = string # Subnet CIDR inside the VNet
    client_count = number # Number of client nodes (for future if you later add VMSS/VMs)
  }))
  default = {
    dc1 = {
      vnet_cidr    = "10.10.0.0/16"
      subnet_cidr  = "10.10.1.0/24"
      client_count = 0
    }
  }
}

variable "enable_vnet_peering" {
  description = "Whether to peer client VNets with the server VNet."
  type        = bool
  default     = true
}

# ==============================================================================
# Key Vault
# ==============================================================================

variable "kv_name" {
  description = "Base name for Key Vault (a random suffix will be appended)."
  type        = string
  default     = "kv-hashistack"
}

variable "kv_key_name" {
  description = "Name of the software-protected key used for Vault auto-unseal."
  type        = string
  default     = "vault-unseal-key"
}

# ==============================================================================
# VMSS - Vault
# ==============================================================================

variable "vault_instance_count" {
  description = "Number of Vault instances in the VMSS."
  type        = number
  default     = 3
  validation {
    condition     = var.vault_instance_count == 1 || (var.vault_instance_count >= 3 && var.vault_instance_count % 2 != 0)
    error_message = "Vault instance count must be 1 or an odd number >= 3."
  }
}

variable "vault_vm_size" {
  description = "VM size for Vault nodes."
  type        = string
  default     = "Standard_D4s_v5"
}

variable "vault_image" {
  description = "Image reference for Vault VMSS."
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  default = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

variable "vault_os_disk_type" {
  description = "OS disk type for Vault VMSS."
  type        = string
  default     = "Premium_LRS"
}

variable "vault_os_disk_size_gb" {
  description = "OS disk size (GB) for Vault VMSS."
  type        = number
  default     = 64
}

variable "vault_upgrade_mode" {
  description = "Upgrade mode for Vault VMSS."
  type        = string
  default     = "Manual"
}

variable "vault_zones" {
  description = "Availability zones for Vault VMSS."
  type        = list(string)
  default     = ["1", "2", "3"]
}

variable "enable_vault_ilb" {
  description = "Enable an internal load balancer in front of the Vault VMSS."
  type        = bool
  default     = false
}

variable "vault_custom_data_base64" {
  description = "Base64-encoded cloud-init for Vault nodes (optional; infra-only by default)."
  type        = string
  default     = null
}

variable "vault_version" {
  type    = string
  default = "1.15.6"
}
variable "vault_api_addr" { # if empty, derives from IP
  type    = string
  default = ""
}
variable "vault_cluster_addr" {
  type    = string
  default = ""
}
variable "vault_tls_disable" { # "1" no TLS, "0" TLS
  type    = string
  default = "1"
}

# ==============================================================================
# VMSS - Core (Consul/Nomad)
# ==============================================================================

variable "core_instance_count" {
  description = "Number of Consul/Nomad instances in the VMSS."
  type        = number
  default     = 3
  validation {
    condition     = var.core_instance_count == 1 || (var.core_instance_count >= 3 && var.core_instance_count % 2 != 0)
    error_message = "Core instance count must be 1 or an odd number >= 3."
  }
}

variable "core_vm_size" {
  description = "VM size for Consul/Nomad nodes."
  type        = string
  default     = "Standard_D4s_v5"
}

variable "core_image" {
  description = "Image reference for Consul/Nomad VMSS."
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  default = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

variable "core_os_disk_type" {
  description = "OS disk type for Core VMSS."
  type        = string
  default     = "Premium_LRS"
}

variable "core_os_disk_size_gb" {
  description = "OS disk size (GB) for Core VMSS."
  type        = number
  default     = 64
}

variable "core_upgrade_mode" {
  description = "Upgrade mode for Core VMSS."
  type        = string
  default     = "Manual"
}

variable "core_zones" {
  description = "Availability zones for Core VMSS."
  type        = list(string)
  default     = ["1", "2", "3"]
}

variable "enable_core_ilb" {
  description = "Enable an internal load balancer in front of the Core VMSS."
  type        = bool
  default     = false
}

variable "core_custom_data_base64" {
  description = "Base64-encoded cloud-init for Core nodes (optional; infra-only by default)."
  type        = string
  default     = null
}

# Versions
variable "consul_version" {
  description = "Version of Consul to install"
  type        = string
  default     = "1.19.2"
}

variable "nomad_version" {
  description = "Version of Nomad to install"
  type        = string
  default     = "1.9.2"
}

# ==============================================================================
# Jump Host (publicly reachable SSH entry point)
# ==============================================================================

variable "enable_jump_host" {
  description = "Whether to deploy a jump host with a public IP."
  type        = bool
  default     = true
}

variable "jump_host_vm_size" {
  description = "VM size for the jump host."
  type        = string
  default     = "Standard_B1ms"
}

variable "jump_host_os_disk_size_gb" {
  description = "OS disk size for the jump host."
  type        = number
  default     = 30
}

variable "jump_host_ssh_public_key" {
  description = "SSH public key used only for the jump host."
  type        = string
}

variable "jump_host_subnet" {
  description = "Which server subnet to place the jump host in: 'vault' or 'core'."
  type        = string
  default     = "vault"
  validation {
    condition     = contains(["vault", "core"], var.jump_host_subnet)
    error_message = "jump_host_subnet must be either 'vault' or 'core'."
  }
}