#--------------------------------------------------------------
# Azure Firewall Module
#--------------------------------------------------------------

variable "name" {
  type        = string
  description = "Name of the Azure Firewall"
}

variable "location" {
  type        = string
  description = "Azure region for the resource"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "public_ip_name" {
  type        = string
  description = "Name of the public IP for the Firewall"
}

variable "subnet_id" {
  type        = string
  description = "ID of the AzureFirewallSubnet"
}

variable "zones" {
  type        = list(string)
  description = "Availability zones for the Firewall"
  default     = ["1", "2", "3"]
}

variable "deploy_sample" {
  type        = bool
  description = "Whether to deploy sample application rules"
  default     = false
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "Resource ID of the Log Analytics workspace for diagnostics"
  default     = ""
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the resource"
  default     = {}
}

resource "azurerm_public_ip" "firewall" {
  name                = var.public_ip_name
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.zones
  tags                = var.tags
}

resource "azurerm_firewall" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  zones               = var.zones
  tags                = var.tags

  ip_configuration {
    name                 = "configuration"
    subnet_id            = var.subnet_id
    public_ip_address_id = azurerm_public_ip.firewall.id
  }
}

# Application Rule Collection - Sample App Rules
resource "azurerm_firewall_application_rule_collection" "sample" {
  count               = var.deploy_sample ? 1 : 0
  name                = "allow-sampleapp-rules"
  azure_firewall_name = azurerm_firewall.this.name
  resource_group_name = var.resource_group_name
  priority            = 110
  action              = "Allow"

  rule {
    name             = "allow-echo-api"
    source_addresses = ["*"]
    target_fqdns     = ["echo.playground.azure-api.net"]

    protocol {
      port = 443
      type = "Https"
    }
  }

  rule {
    name             = "allow-colors-api"
    source_addresses = ["*"]
    target_fqdns     = ["colors-api.azurewebsites.net"]

    protocol {
      port = 443
      type = "Https"
    }
  }

  rule {
    name             = "allow-github"
    source_addresses = ["*"]
    target_fqdns     = ["github.com", "www.github.com", "*.github.com"]

    protocol {
      port = 443
      type = "Https"
    }
  }

  rule {
    name             = "allow-nuget"
    source_addresses = ["*"]
    target_fqdns     = ["nuget.org", "www.nuget.org", "api.nuget.org"]

    protocol {
      port = 443
      type = "Https"
    }
  }
}

# Application Rule Collection - Core App Rules
resource "azurerm_firewall_application_rule_collection" "core" {
  name                = "allow-app-rules"
  azure_firewall_name = azurerm_firewall.this.name
  resource_group_name = var.resource_group_name
  priority            = 100
  action              = "Allow"

  rule {
    name             = "allow-ase-management"
    source_addresses = ["*"]
    target_fqdns     = ["bing.com"]

    protocol {
      port = 80
      type = "Http"
    }
    protocol {
      port = 443
      type = "Https"
    }
  }

  rule {
    name             = "allow-apim-capture"
    source_addresses = ["*"]
    target_fqdns     = ["partner.prod.repmap.microsoft.com", "dc.services.visualstudio.com"]

    protocol {
      port = 443
      type = "Https"
    }
  }

  rule {
    name             = "allow-apim-metrics"
    source_addresses = ["*"]
    target_fqdns     = ["prod3.prod.microsoftmetrics.com"]

    protocol {
      port = 1886
      type = "Https"
    }
  }

  rule {
    name             = "allow-app-insights"
    source_addresses = ["*"]
    target_fqdns     = ["*.applicationinsights.azure.com", "*.monitor.azure.com"]

    protocol {
      port = 1886
      type = "Https"
    }
  }

  rule {
    name             = "allow-certs"
    source_addresses = ["*"]
    target_fqdns     = ["s.symcd.com", "ts-ocsp.ws.symantec.com", "ocsp.digicert.com", "ts-crl.ws.symantec.com"]

    protocol {
      port = 80
      type = "Http"
    }
  }
}

# Network Rule Collection
resource "azurerm_firewall_network_rule_collection" "core" {
  name                = "allow-network-rules"
  azure_firewall_name = azurerm_firewall.this.name
  resource_group_name = var.resource_group_name
  priority            = 100
  action              = "Allow"

  rule {
    name                  = "allow-ntp"
    source_addresses      = ["*"]
    destination_addresses = ["*"]
    destination_ports     = ["12000", "123"]
    protocols             = ["Any"]
  }
}

# Diagnostic settings
resource "azurerm_monitor_diagnostic_setting" "firewall" {
  count                      = var.log_analytics_workspace_id != "" ? 1 : 0
  name                       = "diag-${var.name}"
  target_resource_id         = azurerm_firewall.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category_group = "allLogs"
  }

  metric {
    category = "AllMetrics"
  }
}

output "id" {
  description = "The ID of the Azure Firewall"
  value       = azurerm_firewall.this.id
}

output "name" {
  description = "The name of the Azure Firewall"
  value       = azurerm_firewall.this.name
}

output "private_ip_address" {
  description = "The private IP address of the Azure Firewall"
  value       = azurerm_firewall.this.ip_configuration[0].private_ip_address
}

output "public_ip_address" {
  description = "The public IP address of the Azure Firewall"
  value       = azurerm_public_ip.firewall.ip_address
}
