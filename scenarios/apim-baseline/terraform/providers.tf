terraform {
  required_version = ">= 1.6.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.66"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.9"
    }
  }
}

provider "azurerm" {
  resource_provider_registrations = "none"
  features {}
}

provider "azapi" {}
