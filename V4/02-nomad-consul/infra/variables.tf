# -----------------------------------------------------------------------------
# Variables Populated from Phase 1 (shared_outputs.auto.tfvars.json)
# -----------------------------------------------------------------------------
variable "location" {
  type        = string
  description = "Azure region from Phase 1"
}

variable "vault_rg_name" {
  type        = string
  description = "Resource Group name for Vault cluster from Phase 1"
}

variable "vault_vnet_id" {
  type        = string
  description = "VNet ID for Vault cluster from Phase 1"
}

variable "vault_vnet_name" {
  type        = string
  description = "VNet Name for Vault cluster from Phase 1"
}

variable "vault_lb_private_ip" {
  type        = string
  description = "LB IP for Vault cluster from Phase 1"
}

# -----------------------------------------------------------------------------
# Variables for Phase 2 (Nomad/Consul Cluster)
# -----------------------------------------------------------------------------
variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}

variable "admin_username" {
  description = "Admin username for all VMs"
  type        = string
}

variable "admin_password" {
  description = "Admin password for all VMs"
  type        = string
  sensitive   = true
}

variable "ssh_allowed_ip" {
  description = "CIDR for SSH access (e.g., your IP/32)"
  type = list(string)
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
}

variable "nomad_consul_image_offer" {
  description = "OS image offer for Nomad/Consul VMs"
  type        = string
}

variable "nomad_consul_image_sku" {
  description = "OS image SKU for Nomad/Consul VMs"
  type        = string
}

variable "nomad_consul_image_version" {
  description = "OS image version for Nomad/Consul VMs"
  type        = string
}

# VNet Peering variables
variable "enable_vnet_peering" {
  description = "Enable VNet peering between VNets"
  type        = bool
  default     = true
}

# Storage variables
variable "os_disk_type" {
  description = "OS disk storage type"
  type        = string
}

variable "os_disk_size_gb" {
  description = "OS disk size in GB"
  type        = number
}