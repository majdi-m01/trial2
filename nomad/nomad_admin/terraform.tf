# This file configures the Terraform providers for the Nomad Admin configuration.

terraform {
  required_providers {
    nomad = {
      source  = "hashicorp/nomad"
      version = "~> 2.4.0"
    }
  }
  # NOTE: No backend block is configured.
  # Terraform will use a local state file in this directory by default.
}

provider "nomad" {
  # The provider is now configured dynamically using input variables.
  # The `secret_id` is used for ACL tokens.
  address   = var.nomad_address
  secret_id = var.nomad_bootstrap_token
}