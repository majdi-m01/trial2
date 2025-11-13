# This file defines the input variables needed for the Nomad Developer configuration.
# These values will be provided in a separate terraform.tfvars file.

variable "nomad_address" {
  description = "The public address of the Nomad cluster (e.g., http://<ip_address>:4646)."
  type        = string
}

variable "nomad_developer_token" {
  description = "An ACL token with 'developer' policy permissions, used for submitting jobs."
  type        = string
  sensitive   = true # Marks this variable as sensitive to prevent it from being shown in CLI output.
}