# This file configures the Terraform providers for the Nomad Developer configuration.

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
  # The provider is configured to use a specific developer token,
  # granting it permissions only to manage jobs, not the cluster itself.
  address   = var.nomad_address
  secret_id = var.nomad_developer_token
}