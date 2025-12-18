#--------------------------------------------------------------
# APIM Network Security Group Module
# Equivalent to api-management-nsg.bicep
#--------------------------------------------------------------

variable "name" {
  type        = string
  description = "Name of the Network Security Group"
}

variable "location" {
  type        = string
  description = "Azure region for the resource"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the resource"
  default     = {}
}

resource "azurerm_network_security_group" "apim" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  # Inbound Rules
  security_rule {
    name                       = "Client_communication_to_API_Management"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "AzureFrontDoor.Backend"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "Secure_Client_communication_to_API_Management"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "AzureFrontDoor.Backend"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "Management_endpoint_for_Azure_portal_and_Powershell"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3443"
    source_address_prefix      = "ApiManagement"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "Publish_Diagnostic_Logs_and_Metrics"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["1886", "443"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "AzureMonitor"
  }

  # Outbound Rules
  security_rule {
    name                       = "Dependency_on_Azure_Storage"
    priority                   = 130
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "Storage"
    description                = "APIM service dependency on Azure Blob and Azure Table Storage"
  }

  security_rule {
    name                       = "Azure_Active_Directory_and_Azure_KeyVault_dependency"
    priority                   = 140
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "AzureActiveDirectory"
    description                = "Connect to Azure Active Directory for Developer Portal Authentication or for Oauth2 flow during any Proxy Authentication"
  }

  security_rule {
    name                       = "Access_to_Azure_SQL_endpoints"
    priority                   = 150
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1433"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "Sql"
  }

  security_rule {
    name                       = "Access_to_Azure_KeyVault"
    priority                   = 160
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "AzureKeyVault"
    description                = "Allow APIM service control plane access to KeyVault to refresh secrets"
  }

  security_rule {
    name                       = "Dependency_for_Log_to_event_Hub_policy"
    priority                   = 170
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_ranges    = ["5671", "5672", "443"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "EventHub"
  }

  security_rule {
    name                       = "Dependency_on_Azure_File_Share_for_GIT"
    priority                   = 180
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "445"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "Storage"
  }

  security_rule {
    name                       = "Health_and_Monitoring_Extension"
    priority                   = 190
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["443", "12000"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "AzureCloud"
  }

  security_rule {
    name                       = "Connect_To_SMTP_Relay"
    priority                   = 210
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["25", "587", "25028"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "Internet"
  }

  security_rule {
    name                       = "Access_Redis_Service"
    priority                   = 220
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "6381-6383"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "Sync_Counters_for_Rate_Limit"
    priority                   = 230
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "4290"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "Sync_Counters_for_Rate_Limit_Outbound"
    priority                   = 240
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "4290"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "Azure_Infrastructure_Load_Balancer"
    priority                   = 250
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "6390"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "VirtualNetwork"
  }
}

output "id" {
  description = "The ID of the Network Security Group"
  value       = azurerm_network_security_group.apim.id
}

output "name" {
  description = "The name of the Network Security Group"
  value       = azurerm_network_security_group.apim.name
}
