variable "location" {
  description = "The Azure region for the deployment."
  type        = string
  default     = "Germany West Central"
}

variable "project_name" {
  description = "A name for the project, used as a prefix for resource names."
  type        = string
  default     = "hashistack"
}

# --- Cluster Size Configuration ---
variable "vault_server_count" {
  description = "Number of Vault server nodes. Use 1 for a dev setup, or an odd number >= 3 for HA."
  type        = number
  default     = 3
  validation {
    condition     = var.vault_server_count == 1 || (var.vault_server_count >= 3 && var.vault_server_count % 2 != 0)
    error_message = "The Vault server count must be 1 (for dev) or an odd number of 3 or more for HA."
  }
}

variable "nomad_consul_server_count" {
  description = "Number of Nomad/Consul server nodes. Use 1 for dev, or an odd number >= 3 for HA."
  type        = number
  default     = 3
  validation {
    condition     = var.nomad_consul_server_count == 1 || (var.nomad_consul_server_count >= 3 && var.nomad_consul_server_count % 2 != 0)
    error_message = "The Nomad/Consul server count must be 1 (for dev) or an odd number of 3 or more for HA."
  }
}

# --- Client Datacenter Configuration ---
variable "datacenters" {
  description = "A map defining the client datacenters, their VNet address spaces, and node counts."
  type = map(object({
    vnet_address_space = string
    client_count       = number
  }))
  default = {
    "dc1" = {
      vnet_address_space = "10.10.0.0/16"
      client_count       = 2
    },
    "dc2" = {
      vnet_address_space = "10.20.0.0/16"
      client_count       = 1
    }
  }
}

# --- Admin and VM Credentials ---
variable "admin_username" {
  description = "Admin username for all the virtual machines."
  type        = string
  default     = "adminuser"
}

variable "admin_password" {
  description = "Admin password for all the virtual machines."
  type        = string
  sensitive   = true
}

variable "admin_ip_addresses" {
  description = "A list of your public IP addresses to allow SSH access to the server nodes."
  type        = list(string)
}

# ---SPIKE REPLY TAGGIN FOR TESTING---

variable "tags" {
  description = "A map of tags to apply to all created resources."
  type        = map(string)
  default = {
    CostCenter = "SpikeReply"
  }
}