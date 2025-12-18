#--------------------------------------------------------------
# APIM Landing Zone - Main Terraform Configuration
# Equivalent to main.bicep
#--------------------------------------------------------------

#--------------------------------------------------------------
# Data Sources - Existing Resources
#--------------------------------------------------------------

data "azurerm_log_analytics_workspace" "law" {
  name                = var.log_analytics_workspace_name
  resource_group_name = var.log_analytics_workspace_resource_group
}

data "azurerm_log_analytics_workspace" "sentinel" {
  name                = var.sentinel_workspace_name
  resource_group_name = var.sentinel_workspace_resource_group
}

data "azurerm_application_insights" "app_insights" {
  provider            = azurerm.app_insights
  count               = var.application_insights_name != "" ? 1 : 0
  name                = var.application_insights_name
  resource_group_name = var.application_insights_resource_group
}

#--------------------------------------------------------------
# Hub Resource Groups
#--------------------------------------------------------------

resource "azurerm_resource_group" "hub_network" {
  name     = local.hub_network.resource_group_name
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_resource_group" "apim" {
  count    = var.deploy_apim ? 1 : 0
  name     = local.hub_api.apim_resource_group_name
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_resource_group" "bastion" {
  count    = var.deploy_bastion ? 1 : 0
  name     = local.hub_bastion.bastion_resource_group_name
  location = var.location
  tags     = local.common_tags
}

#--------------------------------------------------------------
# Network Security Groups
#--------------------------------------------------------------

module "apim_nsg" {
  source              = "./modules/api/apim-nsg"
  count               = var.deploy_apim ? 1 : 0
  name                = local.hub_api.apim_nsg_name
  location            = var.location
  resource_group_name = azurerm_resource_group.hub_network.name
  tags                = local.common_tags
}

module "private_endpoint_nsg" {
  source              = "./modules/networking/nsg"
  name                = local.hub_network.private_endpoint_nsg_name
  location            = var.location
  resource_group_name = azurerm_resource_group.hub_network.name
  security_rules      = []
  tags                = local.common_tags
}

module "bastion_nsg" {
  source              = "./modules/networking/bastion-nsg"
  count               = var.deploy_bastion ? 1 : 0
  name                = local.hub_bastion.bastion_nsg_name
  location            = var.location
  resource_group_name = azurerm_resource_group.hub_network.name
  tags                = local.common_tags
}

#--------------------------------------------------------------
# Route Tables
#--------------------------------------------------------------

module "apim_route_table" {
  source              = "./modules/networking/route-table"
  count               = var.deploy_apim ? 1 : 0
  name                = local.hub_api.apim_route_table_name
  location            = var.location
  resource_group_name = azurerm_resource_group.hub_network.name
  routes = [
    {
      name                   = "ApiManagementControlPlane"
      address_prefix         = "ApiManagement"
      next_hop_type          = "Internet"
      next_hop_in_ip_address = null
    },
    {
      name                   = "DefaultRoute"
      address_prefix         = "0.0.0.0/0"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = var.firewall_private_ip
    }
  ]
  disable_bgp_route_propagation = false
  tags                          = local.common_tags
}

module "gateway_route_table" {
  source              = "./modules/networking/route-table"
  name                = local.hub_network.route_table_gateway_subnet_name
  location            = var.location
  resource_group_name = azurerm_resource_group.hub_network.name
  routes = [
    {
      name                   = "VNET-AE-IDENTITY-01"
      address_prefix         = "10.132.2.0/24"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = var.firewall_private_ip
    },
    {
      name                   = "VNET-AE-MGMT-01"
      address_prefix         = "10.132.1.0/24"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = var.firewall_private_ip
    }
  ]
  disable_bgp_route_propagation = false
  tags                          = local.common_tags
}

module "private_endpoint_route_table" {
  source              = "./modules/networking/route-table"
  name                = local.hub_network.private_endpoint_route_table_name
  location            = var.location
  resource_group_name = azurerm_resource_group.hub_network.name
  routes = [
    {
      name                   = "DefaultRoute"
      address_prefix         = "0.0.0.0/0"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = var.firewall_private_ip
    }
  ]
  disable_bgp_route_propagation = true
  tags                          = local.common_tags
}

#--------------------------------------------------------------
# Hub Virtual Network
#--------------------------------------------------------------

module "hub_vnet" {
  source              = "./modules/networking/vnet"
  name                = local.hub_network.virtual_network_name
  location            = var.location
  resource_group_name = azurerm_resource_group.hub_network.name
  address_space       = var.hub_vnet_address_prefixes
  subnets             = local.hub_vnet_subnets
  tags                = local.common_tags

  # Map NSG and Route Table IDs
  nsg_ids = merge(
    var.deploy_apim ? { (local.hub_api.apim_nsg_name) = module.apim_nsg[0].id } : {},
    { (local.hub_network.private_endpoint_nsg_name) = module.private_endpoint_nsg.id },
    var.deploy_bastion ? { (local.hub_bastion.bastion_nsg_name) = module.bastion_nsg[0].id } : {}
  )

  route_table_ids = merge(
    var.deploy_apim ? { (local.hub_api.apim_route_table_name) = module.apim_route_table[0].id } : {},
    { (local.hub_network.route_table_gateway_subnet_name) = module.gateway_route_table.id },
    { (local.hub_network.private_endpoint_route_table_name) = module.private_endpoint_route_table.id }
  )

  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.law.id

  depends_on = [
    module.apim_nsg,
    module.private_endpoint_nsg,
    module.bastion_nsg,
    module.apim_route_table,
    module.gateway_route_table,
    module.private_endpoint_route_table
  ]
}

#--------------------------------------------------------------
# Azure Firewall
#--------------------------------------------------------------

module "azure_firewall" {
  source              = "./modules/networking/firewall"
  count               = var.deploy_azure_firewall ? 1 : 0
  name                = local.hub_firewall.azure_firewall_name
  location            = var.location
  resource_group_name = azurerm_resource_group.hub_network.name
  public_ip_name      = local.hub_firewall.azure_firewall_public_ip_name
  subnet_id           = module.hub_vnet.subnet_ids["AzureFirewallSubnet"]
  zones               = ["1", "2", "3"]
  deploy_sample       = var.deploy_sample
  tags                = local.common_tags

  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.sentinel.id

  depends_on = [module.hub_vnet]
}

#--------------------------------------------------------------
# Key Vault
#--------------------------------------------------------------

module "hub_key_vault" {
  source              = "./modules/shared/keyvault"
  count               = var.deploy_key_vault ? 1 : 0
  name                = local.hub_key_vault.key_vault_name
  location            = var.location
  resource_group_name = azurerm_resource_group.hub_network.name
  tags                = local.common_tags

  virtual_network_subnet_ids = var.deploy_app_gateway ? [
    module.hub_vnet.subnet_ids["AppGatewaySubnet"],
    module.hub_vnet.subnet_ids["AzureAppGatewaySubnet"]
  ] : []

  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.law.id

  depends_on = [module.hub_vnet]
}

#--------------------------------------------------------------
# Application Gateway Public IP
#--------------------------------------------------------------

resource "azurerm_public_ip" "app_gateway" {
  count               = var.deploy_app_gateway ? 1 : 0
  name                = local.hub_app_gateway.app_gateway_public_ip_name
  location            = var.location
  resource_group_name = azurerm_resource_group.hub_network.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
  tags                = local.common_tags
}

#--------------------------------------------------------------
# Application Gateway
#--------------------------------------------------------------

module "app_gateway" {
  source              = "./modules/gateway/appgw"
  count               = var.deploy_app_gateway ? 1 : 0
  name                = local.hub_app_gateway.app_gateway_name
  location            = var.location
  resource_group_name = azurerm_resource_group.hub_network.name
  subnet_id           = module.hub_vnet.subnet_ids["AppGatewaySubnet"]
  public_ip_id        = azurerm_public_ip.app_gateway[0].id
  waf_policy_name     = local.hub_app_gateway.app_gateway_waf_policy_name
  key_vault_id        = var.deploy_key_vault ? module.hub_key_vault[0].id : null
  backend_fqdn        = "${local.hub_api.apim_name}.azure-api.net"
  tags                = local.common_tags

  depends_on = [
    module.hub_vnet,
    module.hub_key_vault
  ]
}

#--------------------------------------------------------------
# Azure Bastion
#--------------------------------------------------------------

module "bastion" {
  source              = "./modules/networking/bastion"
  count               = var.deploy_bastion ? 1 : 0
  name                = local.hub_bastion.bastion_host_name
  location            = var.location
  resource_group_name = azurerm_resource_group.bastion[0].name
  public_ip_name      = local.hub_bastion.bastion_public_ip_name
  virtual_network_id  = module.hub_vnet.id
  subnet_id           = module.hub_vnet.subnet_ids["AzureBastionSubnet"]
  tags                = local.common_tags

  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.law.id

  depends_on = [module.hub_vnet]
}

#--------------------------------------------------------------
# API Management
#--------------------------------------------------------------

module "apim" {
  source              = "./modules/api/apim"
  count               = var.deploy_apim ? 1 : 0
  name                = local.hub_api.apim_name
  location            = var.location
  resource_group_name = azurerm_resource_group.apim[0].name
  
  publisher_email     = var.apim_publisher_email
  publisher_name      = var.apim_publisher_name
  sku_name            = var.apim_sku_name
  sku_capacity        = var.apim_capacity
  virtual_network_type = var.apim_virtual_network_type
  subnet_id           = module.hub_vnet.subnet_ids[local.hub_api.apim_subnet_name]
  availability_zones  = var.apim_sku_name == "Premium" ? var.apim_availability_zones : []
  
  # Private endpoint configuration for StandardV2
  private_endpoint_subnet_id           = module.hub_vnet.subnet_ids[local.hub_network.private_endpoint_subnet_name]
  private_endpoint_name                = local.hub_api.apim_private_endpoint_name
  private_endpoint_nic_name            = local.hub_api.apim_private_endpoint_nic_name
  
  # DNS Zone configuration
  virtual_network_id                   = module.hub_vnet.id
  virtual_network_name                 = module.hub_vnet.name
  networking_resource_group_name       = azurerm_resource_group.hub_network.name
  
  # Key Vault access
  key_vault_id                         = var.deploy_key_vault ? module.hub_key_vault[0].id : null
  key_vault_name                       = var.deploy_key_vault ? module.hub_key_vault[0].name : ""
  key_vault_resource_group_name        = azurerm_resource_group.hub_network.name
  
  # Application Insights
  application_insights_id              = length(data.azurerm_application_insights.app_insights) > 0 ? data.azurerm_application_insights.app_insights[0].id : ""
  application_insights_connection_string = length(data.azurerm_application_insights.app_insights) > 0 ? data.azurerm_application_insights.app_insights[0].connection_string : ""
  
  # Diagnostics
  log_analytics_workspace_id           = data.azurerm_log_analytics_workspace.law.id
  
  # Sample deployment
  deploy_sample                        = var.deploy_sample
  
  tags                                 = local.common_tags

  depends_on = [
    module.hub_vnet,
    module.hub_key_vault,
    module.app_gateway,
    module.apim_nsg,
    module.apim_route_table
  ]
}
