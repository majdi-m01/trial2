# This file configures the Terraform providers for the Vault Admin configuration.

terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 4.6.0"
    }
  }
  # NOTE: No backend block is configured.
  # Terraform will use a local state file in this directory by default.
}

provider "vault" {
  # The provider is now configured dynamically using input variables.
  # This allows you to target any Vault cluster without changing the code.
  address = var.vault_address
  token   = var.vault_root_token
}