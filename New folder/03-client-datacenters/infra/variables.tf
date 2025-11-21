# -----------------------------------------------------------------------------
# Variables Populated from Previous Phases (via shared_outputs.auto.tfvars.json)
# -----------------------------------------------------------------------------
variable "location" {
  type        = string
  description = "Azure region from Phase 1"
}

# From Phase 1
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

# From Phase 2
variable "nomad_consul_rg_name" {
  type        = string
  description = "Resource Group name for Nomad/Consul cluster from Phase 2"
}
variable "nomad_consul_vnet_id" {
  type        = string
  description = "VNet ID for Nomad/Consul cluster from Phase 2"
}
variable "nomad_consul_vnet_name" {
  type        = string
  description = "VNet Name for Nomad/Consul cluster from Phase 2"
}
variable "nomad_consul_vnet_address_space" {
  type        = list(string)
  description = "Address space for Nomad/Consul VNet from Phase 2"
}
variable "nomad_consul_lb_private_ip" {
  type        = string
  description = "Private IP for Nomad/Consul internal LB from Phase 2"
}

# -----------------------------------------------------------------------------
# Variables for Phase 3 (Client Datacenters)
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
  type        = string
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
}

variable "clients_image_offer" {
  description = "OS image offer for Client VMs"
  type        = string
}

variable "clients_image_sku" {
  description = "OS image SKU for Client VMs"
  type        = string
}

variable "clients_image_version" {
  description = "OS image version for Client VMs"
  type        = string
}

variable "datacenter_subnet_prefixes" {
  description = "List of address prefixes for Data Center subnets (one per DC). If empty, auto-generates sequential."
  type        = list(string)
  default     = []
}

# VNet Peering variables
variable "enable_vnet_peering" {
  description = "Enable VNet peering between all VNets"
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