# This file defines the input variables needed to configure the Consul provider.
# These values will be provided in a separate terraform.tfvars file.

variable "consul_address" {
  description = "The public address of the Nomad/Consul cluster (e.g., http://<ip_address>:8500)."
  type        = string
}

variable "consul_bootstrap_token" {
  description = "The initial bootstrap token for Consul's ACL system, obtained via 'consul acl bootstrap'."
  type        = string
  sensitive   = true # Marks this variable as sensitive to prevent it from being shown in CLI output.
}