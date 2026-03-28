variable "nsg_name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type    = string
  default = "australiaeast"
}

variable "tags" {
  type    = map(string)
  default = {}
}

resource "azurerm_network_security_group" "apim" {
  name                = var.nsg_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

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
    name                       = "Dependency_for_Log_to_event_Hub_policy_and_monitoring_agent"
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
    name                       = "Publish_Diagnostic_Logs_and_Metrics_Resource_Health_and_Application_Insights"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["1886", "443"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "AzureMonitor"
  }

  security_rule {
    name                       = "Connect_To_SMTP_Relay_for_sending_e-mails"
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
    name                       = "Access_Redis_Service_for_Cache_policies_between_machines"
    priority                   = 220
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "6381-6383"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "Sync_Counters_for_Rate_Limit_policies_between_machines"
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
    name                       = "Azure_Infrastructure_Load_Balancer"
    priority                   = 240
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "VirtualNetwork"
  }
}

output "resource_id" {
  value = azurerm_network_security_group.apim.id
}

output "name" {
  value = azurerm_network_security_group.apim.name
}

output "location" {
  value = azurerm_network_security_group.apim.location
}

output "resource_group_name" {
  value = azurerm_network_security_group.apim.resource_group_name
}