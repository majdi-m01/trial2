terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.1"
    }
  }

  required_version = ">= 1.0"
}

provider "azurerm" {
  features {}
}

# Random string for resource naming to avoid conflicts
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}