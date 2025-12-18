#--------------------------------------------------------------
# Bastion Network Security Group Module
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

resource "azurerm_network_security_group" "bastion" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  # Inbound Rules
  security_rule {
    name                       = "Inbound-HTTPS-Allow"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Inbound-GWManager-Allow"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "GatewayManager"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Inbound-LoadBalancer-Allow"
    priority                   = 140
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Inbound-BastionHostComms-Allow"
    priority                   = 160
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_ranges    = ["8080", "5701"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  # Outbound Rules
  security_rule {
    name                       = "Outbound-BastionHostComms-Allow"
    priority                   = 180
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_ranges    = ["8080", "5701"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "Outbound-SSH-Allow"
    priority                   = 200
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "Outbound-RDP-Allow"
    priority                   = 220
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "Outbound-HTTPStoAzureCloud"
    priority                   = 240
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "AzureCloud"
    description                = "Egress Traffic to other public endpoints in Azure"
  }

  security_rule {
    name                       = "Outbound-HTTPtoInternet"
    priority                   = 260
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
    description                = "Egress Traffic to other public endpoints in Azure"
  }
}

output "id" {
  description = "The ID of the Network Security Group"
  value       = azurerm_network_security_group.bastion.id
}

output "name" {
  description = "The name of the Network Security Group"
  value       = azurerm_network_security_group.bastion.name
}
