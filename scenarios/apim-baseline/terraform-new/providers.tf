provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    api_management {
      purge_soft_delete_on_destroy = false
    }
  }
  subscription_id = var.hub_subscription_id
}

provider "azurerm" {
  alias           = "spoke"
  subscription_id = var.spoke_subscription_id
  features {}
}

provider "azurerm" {
  alias           = "app_insights"
  subscription_id = var.application_insights_subscription_id
  features {}
}

provider "azapi" {}
