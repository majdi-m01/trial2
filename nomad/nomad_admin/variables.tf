# This file defines the input variables needed for the Nomad Admin configuration.
# These values will be provided in a separate terraform.tfvars file.

variable "nomad_address" {
  description = "The public address of the Nomad cluster (e.g., http://<ip_address>:4646)."
  type        = string
}

variable "nomad_bootstrap_token" {
  description = "The initial bootstrap token for Nomad's ACL system, obtained via 'nomad acl bootstrap'."
  type        = string
  sensitive   = true # Marks this variable as sensitive to prevent it from being shown in CLI output.
}