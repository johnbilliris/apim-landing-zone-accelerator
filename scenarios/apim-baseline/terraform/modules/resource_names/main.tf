data "azurerm_client_config" "current" {}

variable "workload_name" {
  type    = string
  default = "inte"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "location" {
  type    = string
  default = "australiaeast"
}

locals {
  resource_abbreviations = jsondecode(file("${path.module}/../../abbreviations.json"))

  shortened_location = lower(var.location) == "australiaeast" ? "ae-" : "as-"
  resource_suffix    = "${local.shortened_location}${var.workload_name}-${var.environment}-"
  hub_resource_suffix = "${local.shortened_location}hub-"

  route_table_gateway_subnet_name = lower("${local.resource_abbreviations.networkRouteTables}${local.shortened_location}GW-01")
  app_gateway_name                = "${local.resource_abbreviations.networkApplicationGateways}${local.hub_resource_suffix}02"
}

output "location" {
  value = var.location
}

output "tags" {
  value = {
    workloadName    = var.workload_name
    environment     = var.environment
    location        = var.location
    SecurityControl = "Ignore"
  }
}

output "deploy_sample" {
  value = true
}

output "hub" {
  value = {
    subscriptionId = "c8703ebc-bc5d-488d-9489-5883c9fde6c2"
    network = {
      resourceGroupName                    = "${local.resource_abbreviations.resourcesResourceGroups}${local.shortened_location}connect-network-01"
      virtualNetworkName                   = "${local.resource_abbreviations.networkVirtualNetworks}${local.shortened_location}hub-01"
      virtualNetworkAddressPrefixes        = ["10.132.0.0/24", "10.132.13.0/24"]
      routeTableGatewaySubnetName          = local.route_table_gateway_subnet_name
      privateEndpointSubnetName            = "${local.resource_abbreviations.networkVirtualNetworksSubnets}${local.hub_resource_suffix}${local.resource_abbreviations.networkPrivateEndpoints}01"
      privateEndpointNetworkSecurityGroupName = "${local.resource_abbreviations.networkNetworkSecurityGroups}${local.shortened_location}${local.resource_abbreviations.networkPrivateEndpoints}01"
      privateEndpointRouteTableName        = "${local.resource_abbreviations.networkRouteTables}${local.shortened_location}${local.resource_abbreviations.networkPrivateEndpoints}01"
      useExistingVirtualNetwork            = false
      useExistingVirtualNetworkSubnets     = false
    }
    api = {
      apiCenterName                          = "${local.resource_abbreviations.apiCenterService}${local.hub_resource_suffix}06"
      deployApiCenter                        = true
      apimName                               = "${local.resource_abbreviations.apiManagementService}${local.hub_resource_suffix}01"
      publisherEmail                         = "john.billiris@microsoft.com"
      publisherName                          = "John Billiris"
      apimSkuName                            = "StandardV2"
      apimCapacity                           = 1
      apimVirtualNetworkType                 = "External"
      apimSubnetName                         = "${local.resource_abbreviations.networkVirtualNetworksSubnets}${local.hub_resource_suffix}${local.resource_abbreviations.apiManagementService}01"
      apimNetworkSecurityGroupName           = "${local.resource_abbreviations.networkNetworkSecurityGroups}${local.shortened_location}${local.resource_abbreviations.apiManagementService}01"
      apimRouteTableName                     = "${local.resource_abbreviations.networkRouteTables}${local.shortened_location}${local.resource_abbreviations.apiManagementService}01"
      apimResourceGroupName                  = "${local.resource_abbreviations.resourcesResourceGroups}${local.shortened_location}connect-${local.resource_abbreviations.apiManagementService}01"
      apimPrivateEndpointName                = "${local.resource_abbreviations.networkPrivateEndpoints}${local.resource_abbreviations.apiManagementService}${local.hub_resource_suffix}01"
      apimPrivateEndpointNetworkInterfaceName = "${local.resource_abbreviations.networkPrivateEndpoints}${local.resource_abbreviations.apiManagementService}${local.hub_resource_suffix}01-${replace(local.resource_abbreviations.networkNetworkInterfaces, "-", "")}"
      availabilityZones                      = ["1", "2", "3"]
      deployApim                             = true
    }
    appGateway = {
      appGatewayName       = local.app_gateway_name
      appGatewayPublicIPName = "${local.resource_abbreviations.networkPublicIPAddresses}${local.app_gateway_name}"
      appGatewayWAFPolicyName = "POLICY-AZF-AE-AGW-03"
      deployAppGateway     = true
    }
    azureFirewall = {
      azureFirewallName       = "${local.resource_abbreviations.networkAzureFirewalls}${local.hub_resource_suffix}01"
      azureFirewallPublicIPName = "${local.resource_abbreviations.networkPublicIPAddresses}${local.resource_abbreviations.networkAzureFirewalls}${local.hub_resource_suffix}01"
      deployAzureFirewall     = true
    }
    bastion = {
      bastionHostName         = "${local.resource_abbreviations.networkBastionHosts}${local.shortened_location}01"
      bastionResourceGroupName = "${local.resource_abbreviations.resourcesResourceGroups}${local.shortened_location}connect-${local.resource_abbreviations.networkBastionHosts}01"
      bastionPublicIPName     = "${local.resource_abbreviations.networkPublicIPAddresses}${local.resource_abbreviations.networkBastionHosts}${local.shortened_location}01"
      bastionNsgName          = "${local.resource_abbreviations.networkNetworkSecurityGroups}${local.shortened_location}${local.resource_abbreviations.networkBastionHosts}01"
      deployBastion           = true
    }
    keyVault = {
      keyVaultName = "${local.resource_abbreviations.keyVaultVaults}${local.shortened_location}hub-nd-01"
      deployKeyVault = true
    }
  }
}

output "spoke" {
  value = {
    subscriptionId                            = data.azurerm_client_config.current.subscription_id
    networkingResourceGroupName               = "${local.resource_abbreviations.resourcesResourceGroups}${local.resource_suffix}network-01"
    sharedResourceGroupName                   = "${local.resource_abbreviations.resourcesResourceGroups}${local.resource_suffix}common-01"
    apimResourceGroupName                     = "${local.resource_abbreviations.resourcesResourceGroups}${local.resource_suffix}${local.resource_abbreviations.apiManagementService}01"
    aseResourceGroupName                      = "${local.resource_abbreviations.resourcesResourceGroups}${local.resource_suffix}${local.resource_abbreviations.webSitesAppServiceEnvironment}01"
    virtualNetworkName                        = "${local.resource_abbreviations.networkVirtualNetworks}${local.resource_suffix}01"
    virtualNetworkAddressPrefixes             = ["172.17.0.0/16"]
    appNsgName                                = "${local.resource_abbreviations.networkNetworkSecurityGroups}${local.resource_suffix}${local.resource_abbreviations.webSitesAppServiceEnvironment}01"
    appSubnetName                             = "${local.resource_abbreviations.networkVirtualNetworksSubnets}${local.resource_suffix}${local.resource_abbreviations.webSitesAppServiceEnvironment}01"
    privateEndpointSubnetName                 = "${local.resource_abbreviations.networkVirtualNetworksSubnets}${local.resource_suffix}${local.resource_abbreviations.networkPrivateEndpoints}01"
    privateEndpointNsgName                    = "${local.resource_abbreviations.networkNetworkSecurityGroups}${local.resource_suffix}${local.resource_abbreviations.networkPrivateEndpoints}01"
    aseRouteTableName                         = "${local.resource_abbreviations.networkRouteTables}${local.resource_suffix}${local.resource_abbreviations.webSitesAppServiceEnvironment}01"
    keyVaultName                              = "${local.resource_abbreviations.keyVaultVaults}${local.resource_suffix}01"
    aseName                                   = "${local.resource_abbreviations.webSitesAppServiceEnvironment}${local.resource_suffix}01"
    dedicatedHostCount                        = var.environment == "prod" ? 2 : 0
    zoneRedundantAse                          = var.environment == "prod" ? true : false
    applicationInsightsName                   = "${local.resource_abbreviations.insightsComponents}${local.resource_suffix}01"
    eventGridName                             = "${local.resource_abbreviations.eventGridNamespaces}${local.resource_suffix}01"
    serviceBusName                            = "${local.resource_abbreviations.serviceBusNamespaces}${local.resource_suffix}01"
    serviceBusSku                             = "Standard"
    serviceBusCapacity                        = var.environment == "prod" ? 2 : 1
    storageAccountName                        = lower(replace("${local.resource_abbreviations.storageStorageAccounts}${local.resource_suffix}01", "-", ""))
  }
}