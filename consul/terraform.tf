# This file configures the Terraform providers for the Consul service configuration.

terraform {
  required_providers {
    consul = {
      source  = "hashicorp/consul"
      version = "~> 2.21.0"
    }
  }
  # NOTE: No backend block is configured.
  # Terraform will use a local state file in this directory by default.
}

provider "consul" {
  # The provider is now configured dynamically using input variables.
  # This allows you to target any Consul cluster without changing the code.
  address = var.consul_address
  token   = var.consul_bootstrap_token
}