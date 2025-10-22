# vault/vault_admin/variables.tf (Corrected)

# --- Provider Configuration ---
variable "vault_address" {
  description = "The public address of the Vault cluster (e.g., http://<ip_address>:8200)."
  type        = string
}

variable "vault_root_token" {
  description = "The initial root token for Vault, obtained via 'vault operator init'."
  type        = string
  sensitive   = true
}

# --- Integration Configuration ---
variable "nomad_address" {
  description = "The public address of the Nomad cluster for setting up integrations (e.g., http://<ip_address>:4646)."
  type        = string
}

# --- NEW VARIABLES ---
variable "nomad_private_ip" {
  description = "The private IP of the Nomad server for internal service-to-service communication."
  type        = string
}

variable "nomad_bootstrap_token" {
  description = "The root/bootstrap token for the Nomad cluster."
  type        = string
  sensitive   = true
}
# ---------------------

variable "consul_address" {
  description = "The public address of the Consul cluster for setting up integrations (e.g., http://<ip_address>:8500)."
  type        = string
}

# --- NEW VARIABLE ---
variable "consul_bootstrap_token" {
  description = "The root/bootstrap token for the Consul cluster."
  type        = string
  sensitive   = true
}
# --------------------

variable "gitlab_url" {
  description = "The URL for your GitLab instance, for setting up GitLab JWT authentication."
  type        = string
  default     = "https://gitlab.com"
}