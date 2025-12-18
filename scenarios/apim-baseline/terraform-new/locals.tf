#--------------------------------------------------------------
# Local Variables - Resource Naming
#--------------------------------------------------------------

locals {
  # Resource abbreviations based on Azure naming conventions
  resource_abbreviations = {
    api_management_service          = "apim-"
    api_center_service              = "apic-"
    network_security_groups         = "nsg-"
    network_virtual_networks        = "vnet-"
    network_virtual_networks_subnets = "snet-"
    network_route_tables            = "udr-"
    network_public_ip_addresses     = "pip-"
    network_private_endpoints       = "pe-"
    network_network_interfaces      = "nic-"
    network_application_gateways    = "agw-"
    network_azure_firewalls         = "azf-"
    network_bastion_hosts           = "bastion-"
    resources_resource_groups       = "rg-"
    key_vault_vaults                = "kv-"
    insights_components             = "appi-"
    diagnostic_settings             = "diag-"
  }

  # Location-based prefix
  shortened_location = lower(var.location) == "australiaeast" ? "ae-" : "as-"
  
  # Hub resource suffix
  hub_resource_suffix = "${local.shortened_location}hub-"
  
  # Workload resource suffix
  resource_suffix = "${local.shortened_location}${var.workload_name}-${var.environment}-"

  # Common tags
  common_tags = merge(var.tags, {
    workloadName    = var.workload_name
    environment     = var.environment
    location        = var.location
    SecurityControl = "Ignore"
  })

  #--------------------------------------------------------------
  # Hub Network Resource Names
  #--------------------------------------------------------------
  hub_network = {
    resource_group_name                     = "${local.resource_abbreviations.resources_resource_groups}${local.shortened_location}connect-network-01"
    virtual_network_name                    = "${local.resource_abbreviations.network_virtual_networks}${local.shortened_location}hub-01"
    private_endpoint_subnet_name            = "${local.resource_abbreviations.network_virtual_networks_subnets}${local.hub_resource_suffix}${local.resource_abbreviations.network_private_endpoints}01"
    private_endpoint_nsg_name               = "${local.resource_abbreviations.network_security_groups}${local.shortened_location}${local.resource_abbreviations.network_private_endpoints}01"
    private_endpoint_route_table_name       = "${local.resource_abbreviations.network_route_tables}${local.shortened_location}${local.resource_abbreviations.network_private_endpoints}01"
    route_table_gateway_subnet_name         = "${local.resource_abbreviations.network_route_tables}${local.shortened_location}GW-01"
  }

  #--------------------------------------------------------------
  # API Management Resource Names
  #--------------------------------------------------------------
  hub_api = {
    apim_name                               = "${local.resource_abbreviations.api_management_service}${local.hub_resource_suffix}01"
    apim_resource_group_name                = "${local.resource_abbreviations.resources_resource_groups}${local.shortened_location}connect-${local.resource_abbreviations.api_management_service}01"
    apim_subnet_name                        = "${local.resource_abbreviations.network_virtual_networks_subnets}${local.hub_resource_suffix}${local.resource_abbreviations.api_management_service}01"
    apim_nsg_name                           = "${local.resource_abbreviations.network_security_groups}${local.shortened_location}${local.resource_abbreviations.api_management_service}01"
    apim_route_table_name                   = "${local.resource_abbreviations.network_route_tables}${local.shortened_location}${local.resource_abbreviations.api_management_service}01"
    apim_private_endpoint_name              = "${local.resource_abbreviations.network_private_endpoints}${local.resource_abbreviations.api_management_service}${local.hub_resource_suffix}01"
    apim_private_endpoint_nic_name          = "${local.resource_abbreviations.network_private_endpoints}${local.resource_abbreviations.api_management_service}${local.hub_resource_suffix}01-${replace(local.resource_abbreviations.network_network_interfaces, "-", "")}"
    api_center_name                         = "${local.resource_abbreviations.api_center_service}${local.hub_resource_suffix}05"
  }

  #--------------------------------------------------------------
  # Application Gateway Resource Names
  #--------------------------------------------------------------
  hub_app_gateway = {
    app_gateway_name                        = "${local.resource_abbreviations.network_application_gateways}${local.hub_resource_suffix}02"
    app_gateway_public_ip_name              = "${local.resource_abbreviations.network_public_ip_addresses}${local.resource_abbreviations.network_application_gateways}${local.hub_resource_suffix}02"
    app_gateway_waf_policy_name             = "POLICY-AZF-AE-AGW-03"
  }

  #--------------------------------------------------------------
  # Azure Firewall Resource Names
  #--------------------------------------------------------------
  hub_firewall = {
    azure_firewall_name                     = "${local.resource_abbreviations.network_azure_firewalls}${local.hub_resource_suffix}01"
    azure_firewall_public_ip_name           = "${local.resource_abbreviations.network_public_ip_addresses}${local.resource_abbreviations.network_azure_firewalls}${local.hub_resource_suffix}01"
  }

  #--------------------------------------------------------------
  # Bastion Resource Names
  #--------------------------------------------------------------
  hub_bastion = {
    bastion_host_name                       = "${local.resource_abbreviations.network_bastion_hosts}${local.shortened_location}01"
    bastion_resource_group_name             = "${local.resource_abbreviations.resources_resource_groups}${local.shortened_location}connect-${local.resource_abbreviations.network_bastion_hosts}01"
    bastion_public_ip_name                  = "${local.resource_abbreviations.network_public_ip_addresses}${local.resource_abbreviations.network_bastion_hosts}${local.shortened_location}01"
    bastion_nsg_name                        = "${local.resource_abbreviations.network_security_groups}${local.shortened_location}${local.resource_abbreviations.network_bastion_hosts}01"
  }

  #--------------------------------------------------------------
  # Key Vault Resource Names
  #--------------------------------------------------------------
  hub_key_vault = {
    key_vault_name                          = "${local.resource_abbreviations.key_vault_vaults}${local.shortened_location}hub-nd-01"
  }

  #--------------------------------------------------------------
  # Hub Virtual Network Subnets
  #--------------------------------------------------------------
  hub_vnet_subnets = [
    {
      name                             = "GatewaySubnet"
      address_prefix                   = "10.132.0.64/26"
      delegations                      = []
      network_security_group_name      = null
      route_table_name                 = local.hub_network.route_table_gateway_subnet_name
      service_endpoints                = []
      private_endpoint_network_policies = "Disabled"
    },
    {
      name                             = "AzureBastionSubnet"
      address_prefix                   = "10.132.0.128/27"
      delegations                      = []
      network_security_group_name      = local.hub_bastion.bastion_nsg_name
      route_table_name                 = null
      service_endpoints                = []
      private_endpoint_network_policies = "Disabled"
    },
    {
      name                             = "AzureFirewallSubnet"
      address_prefix                   = "10.132.0.0/26"
      delegations                      = []
      network_security_group_name      = null
      route_table_name                 = null
      service_endpoints                = []
      private_endpoint_network_policies = "Disabled"
    },
    {
      name                             = "AzureFirewallManagementSubnet"
      address_prefix                   = "10.132.0.192/27"
      delegations                      = []
      network_security_group_name      = null
      route_table_name                 = null
      service_endpoints                = []
      private_endpoint_network_policies = "Disabled"
    },
    {
      name                             = "DNSPRInbound"
      address_prefix                   = "10.132.0.224/28"
      delegations                      = ["Microsoft.Network/dnsResolvers"]
      network_security_group_name      = null
      route_table_name                 = null
      service_endpoints                = []
      private_endpoint_network_policies = "Disabled"
    },
    {
      name                             = "AppGatewaySubnet"
      address_prefix                   = "10.132.0.160/28"
      delegations                      = []
      network_security_group_name      = null
      route_table_name                 = null
      service_endpoints                = ["Microsoft.KeyVault", "Microsoft.Storage"]
      private_endpoint_network_policies = "Disabled"
    },
    {
      name                             = "AzureAppGatewaySubnet"
      address_prefix                   = "10.132.13.0/25"
      delegations                      = []
      network_security_group_name      = null
      route_table_name                 = null
      service_endpoints                = ["Microsoft.KeyVault"]
      private_endpoint_network_policies = "Disabled"
    },
    {
      name                             = local.hub_api.apim_subnet_name
      address_prefix                   = "10.132.13.128/26"
      delegations                      = ["Microsoft.Web/serverFarms"]
      network_security_group_name      = local.hub_api.apim_nsg_name
      route_table_name                 = local.hub_api.apim_route_table_name
      service_endpoints                = ["Microsoft.Storage", "Microsoft.Sql", "Microsoft.EventHub", "Microsoft.ServiceBus", "Microsoft.KeyVault", "Microsoft.AzureActiveDirectory"]
      private_endpoint_network_policies = "Disabled"
    },
    {
      name                             = local.hub_network.private_endpoint_subnet_name
      address_prefix                   = "10.132.13.192/26"
      delegations                      = []
      network_security_group_name      = local.hub_network.private_endpoint_nsg_name
      route_table_name                 = local.hub_network.private_endpoint_route_table_name
      service_endpoints                = []
      private_endpoint_network_policies = "Disabled"
    }
  ]
}
