// --------------------------------------------------------------------------------
// Bicep file that builds all the resource names used by other Bicep templates
// --------------------------------------------------------------------------------
targetScope = 'subscription'

@description('A short name for the workload being deployed alphanumberic only')
@maxLength(8)
param workloadName string = 'inte'

@description('The environment for which the deployment is being executed')
@allowed([
  'dev'
  'uat'
  'prod'
  'dr'
])
param environment string = 'dev'

@description('The Azure location for which the deployment is being executed')
@allowed([
  'australiaeast'
  'australiasoutheast'
])
param location string = 'australiaeast'

// --------------------------------------------------------------------------------
// pull resource abbreviations from a common JSON file
@description('Resource abbreviations loaded from JSON configuration file.')
var resourceAbbreviations = loadJsonContent('abbreviations.json')

@description('Shortened location prefix for resource naming.')
var shortenedLocation = toLower(location) == 'australiaeast' ? 'ae-' : 'as-'
@description('Standard resource suffix combining location, workload and environment.')
var resourceSuffix = '${shortenedLocation}${workloadName}-${environment}-'


// Global resources
@description('The location for which the deployment is being executed')
output location string = location

output tags object = {
  workloadName: workloadName
  environment: environment
  location: location
  SecurityControl: 'Ignore'
}

output deploySample bool = true

// Hub resources
@description('Resource suffix for hub resources.')
var hubResourceSuffix = '${shortenedLocation}hub-'
@description('Name of the route table for gateway subnet.')
var routeTableGatewaySubnetName = toLower('${resourceAbbreviations.networkRouteTables}${shortenedLocation}GW-01')
@description('Name of the Application Gateway resource.')
var appGatewayName = '${resourceAbbreviations.networkApplicationGateways}${hubResourceSuffix}02'
@description('Array of subnet configurations for the hub virtual network.')
var hubVirtualNetworkSubnets = [
  {
    name: 'gatewaySubnet'
    addressPrefix: '10.132.0.64/26'
    delegations: []
    networkSecurityGroupName: null
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
    routeTableName: routeTableGatewaySubnetName
    serviceEndpoints: null
  }
  {
    name: 'AzureBastionSubnet'
    addressPrefix: '10.132.0.128/27'
    delegations: []
    networkSecurityGroupName: '${resourceAbbreviations.networkNetworkSecurityGroups}${shortenedLocation}${resourceAbbreviations.networkBastionHosts}01'
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
    routeTableName: null
    serviceEndpoints: null
  }
  {
    name: 'AzureFirewallSubnet'
    addressPrefix: '10.132.0.0/26'
    delegations: []
    networkSecurityGroupName: null
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
    routeTableName: null
    serviceEndpoints: null
  }
  {
    name: 'AzureFirewallManagementSubnet'
    addressPrefix: '10.132.0.192/27'
    delegations: []
    networkSecurityGroupName: null
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
    routeTableName: null
    serviceEndpoints: null
  }
  {
    name: 'DNSPRInbound'
    addressPrefix: '10.132.0.224/28'
    delegations: [
      {
        name: 'Microsoft.Network/dnsResolvers'
        properties: {
          serviceName: 'Microsoft.Network/dnsResolvers'
        }
      }
    ]
    networkSecurityGroupName: null
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
    routeTableName: null
    serviceEndpoints: null
  }
  {
    name: 'AppGatewaySubnet'
    addressPrefix: '10.132.0.160/28'
    delegations: []
    networkSecurityGroupName: null
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
    routeTableName: null
    serviceEndpoints: [
      {
        service: 'Microsoft.KeyVault'
        locations: [
          '*'
        ]
      }
      {
        service: 'Microsoft.Storage'
      }
    ]
  }
  {
    name: 'AzureAppGatewaySubnet'
    addressPrefix: '10.132.13.0/25'
    delegations: []
    networkSecurityGroupName: null
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
    routeTableName: null
    serviceEndpoints: [
      {
        service: 'Microsoft.KeyVault'
        locations: [
          '*'
        ]
      }
    ]
  }
  {
    name: '${resourceAbbreviations.networkVirtualNetworksSubnets}${hubResourceSuffix}${resourceAbbreviations.apiManagementService}01'
    addressPrefix: '10.132.13.128/26'
    delegations: [

      {
        name: 'Microsoft.Web/serverFarms'
        properties: {
          serviceName: 'Microsoft.Web/serverFarms'
        }
      }
    ]
    networkSecurityGroupName: '${resourceAbbreviations.networkNetworkSecurityGroups}${shortenedLocation}${resourceAbbreviations.apiManagementService}01'
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
    routeTableName: '${resourceAbbreviations.networkRouteTables}${shortenedLocation}${resourceAbbreviations.apiManagementService}01'
    serviceEndpoints: [
      {
        service: 'Microsoft.Storage'
      }
      {
        service: 'Microsoft.Sql'
      }
      {
        service: 'Microsoft.EventHub'
      }
      {
        service: 'Microsoft.ServiceBus'
      }
      {
        service: 'Microsoft.KeyVault'
      }
      {
        service: 'Microsoft.AzureActiveDirectory'
      }
    ]
  }
  {
    name: '${resourceAbbreviations.networkVirtualNetworksSubnets}${hubResourceSuffix}${resourceAbbreviations.networkPrivateEndpoints}01'
    addressPrefix: '10.132.13.192/26'
    delegations: null
    networkSecurityGroupName: '${resourceAbbreviations.networkNetworkSecurityGroups}${shortenedLocation}${resourceAbbreviations.networkPrivateEndpoints}01'
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
    routeTableName: '${resourceAbbreviations.networkRouteTables}${shortenedLocation}${resourceAbbreviations.networkPrivateEndpoints}01'
    serviceEndpoints: []
  }
]

// Outputs
@description('The resource names of all objects in the Hub')
output hub object = {
  subscriptionId : 'c8703ebc-bc5d-488d-9489-5883c9fde6c2'
  network: {
    resourceGroupName : '${resourceAbbreviations.resourcesResourceGroups}${shortenedLocation}connect-network-01'
    // Virtual Network
    virtualNetworkName : '${resourceAbbreviations.networkVirtualNetworks}${shortenedLocation}hub-01'
    virtualNetworkAddressPrefixes : [
      '10.132.0.0/24'
      '10.132.13.0/24'
    ]
    virtualNetworkSubnets : hubVirtualNetworkSubnets
    routeTableGatewaySubnetName: routeTableGatewaySubnetName
    privateEndpointSubnetName : '${resourceAbbreviations.networkVirtualNetworksSubnets}${hubResourceSuffix}${resourceAbbreviations.networkPrivateEndpoints}01'
    privateEndpointNetworkSecurityGroupName : '${resourceAbbreviations.networkNetworkSecurityGroups}${shortenedLocation}${resourceAbbreviations.networkPrivateEndpoints}01'
    privateEndpointRouteTableName: '${resourceAbbreviations.networkRouteTables}${shortenedLocation}${resourceAbbreviations.networkPrivateEndpoints}01'
    useExistingVirtualNetwork : false
    useExistingVirtualNetworkSubnets : false
  }
  api: {
    // API Center
    apiCenterName : '${resourceAbbreviations.apiCenterService}${hubResourceSuffix}06'
    deployApiCenter : true
    // API Management
    apimName : '${resourceAbbreviations.apiManagementService}${hubResourceSuffix}01'
    publisherEmail : 'john.billiris@microsoft.com'
    publisherName : 'John Billiris'
    apimSkuName : 'StandardV2'
    apimCapacity : 1
    apimVirtualNetworkType : 'External' // 'Internal' | 'External' | 'None'. 'Internal' for 'Developer' or 'Premium' SKUs only. 'External' for all other SKUs.
    apimSubnetName : '${resourceAbbreviations.networkVirtualNetworksSubnets}${hubResourceSuffix}${resourceAbbreviations.apiManagementService}01'
    apimNetworkSecurityGroupName : '${resourceAbbreviations.networkNetworkSecurityGroups}${shortenedLocation}${resourceAbbreviations.apiManagementService}01'
    apimRouteTableName : '${resourceAbbreviations.networkRouteTables}${shortenedLocation}${resourceAbbreviations.apiManagementService}01'
    apimResourceGroupName : '${resourceAbbreviations.resourcesResourceGroups}${shortenedLocation}connect-${resourceAbbreviations.apiManagementService}01'
    apimPrivateEndpointName : '${resourceAbbreviations.networkPrivateEndpoints}${resourceAbbreviations.apiManagementService}${hubResourceSuffix}01'
    apimPrivateEndpointNetworkInterfaceName : '${resourceAbbreviations.networkPrivateEndpoints}${resourceAbbreviations.apiManagementService}${hubResourceSuffix}01-${replace(resourceAbbreviations.networkNetworkInterfaces, '-', '')}'
    availabilityZones : [
      '1'
      '2'
      '3'
    ] // Only available for Premium SKU
    deployApim : true
  }
  // App Gateway
  appGateway: {  
    appGatewayName : appGatewayName
    appGatewayPublicIPName : '${resourceAbbreviations.networkPublicIPAddresses}${appGatewayName}'
    appGatewayWAFPolicyName : 'POLICY-AZF-AE-AGW-03'
    deployAppGateway : true
  }
  // Azure Firewall
  azureFirewall: {
    azureFirewallName : '${resourceAbbreviations.networkAzureFirewalls}${hubResourceSuffix}01'
    azureFirewallPublicIPName : '${resourceAbbreviations.networkPublicIPAddresses}${resourceAbbreviations.networkAzureFirewalls}${hubResourceSuffix}01'
    deployAzureFirewall : true
  }
  // Bastion Resources
  bastion: {
    bastionHostName : '${resourceAbbreviations.networkBastionHosts}${shortenedLocation}01'
    bastionResourceGroupName : '${resourceAbbreviations.resourcesResourceGroups}${shortenedLocation}connect-${resourceAbbreviations.networkBastionHosts}01'
    bastionPublicIPName : '${resourceAbbreviations.networkPublicIPAddresses}${resourceAbbreviations.networkBastionHosts}${shortenedLocation}01'
    bastionNsgName : '${resourceAbbreviations.networkNetworkSecurityGroups}${shortenedLocation}${resourceAbbreviations.networkBastionHosts}01'
    deployBastion : true
  }
  // Key Vault
  keyVault: {
    keyVaultName : '${resourceAbbreviations.keyVaultVaults}${shortenedLocation}hub-nd-01'
    deployKeyVault : true
  }
}


@description('The resource names of all objects in the APIM LZ Spoke')
output spoke object = {
  subscriptionId : subscription().subscriptionId
  subscriptionName : subscription().displayName
  networkingResourceGroupName : '${resourceAbbreviations.resourcesResourceGroups}${resourceSuffix}network-01'
  sharedResourceGroupName : '${resourceAbbreviations.resourcesResourceGroups}${resourceSuffix}common-01'
  apimResourceGroupName : '${resourceAbbreviations.resourcesResourceGroups}${resourceSuffix}${resourceAbbreviations.apiManagementService}01'
  aseResourceGroupName : '${resourceAbbreviations.resourcesResourceGroups}${resourceSuffix}${resourceAbbreviations.webSitesAppServiceEnvironment}01'
  // Virtual Network
  virtualNetworkName : '${resourceAbbreviations.networkVirtualNetworks}${resourceSuffix}01'
  virtualNetworkAddressPrefixes : [
    '172.17.0.0/16'
  ]

  virtualNetworkSubnets : [
    {
      name: '${resourceAbbreviations.networkVirtualNetworksSubnets}${resourceSuffix}${resourceAbbreviations.webSitesAppServiceEnvironment}01'
      addressPrefix: '172.17.36.0/26'
      privateEndpointNetworkPolicies: 'Disabled'
      privateLinkServiceNetworkPolicies: 'Enabled'
      serviceEndpoints: [
        {
          service: 'Microsoft.ServiceBus'
        }
        {
          service: 'Microsoft.AzureActiveDirectory'
        }
      ]
      networkSecurityGroupName : '${resourceAbbreviations.networkNetworkSecurityGroups}${resourceSuffix}${resourceAbbreviations.webSitesAppServiceEnvironment}01'
      routeTableName: '${resourceAbbreviations.networkRouteTables}${resourceSuffix}${resourceAbbreviations.webSitesAppServiceEnvironment}01'
      delegations: [
        {
          name: 'Microsoft.Web.hostingEnvironments'
          properties: {
            serviceName: 'Microsoft.Web/hostingEnvironments'
          }
        }
      ]
    }
    {
      name: '${resourceAbbreviations.networkVirtualNetworksSubnets}${resourceSuffix}${resourceAbbreviations.networkPrivateEndpoints}01'
      addressPrefix: '172.17.36.64/26'
      privateEndpointNetworkPolicies: 'Disabled'
      privateLinkServiceNetworkPolicies: 'Enabled'
      serviceEndpoints: null
      networkSecurityGroupName :  '${resourceAbbreviations.networkNetworkSecurityGroups}${resourceSuffix}${resourceAbbreviations.networkPrivateEndpoints}01'
      routeTableName: null
      delegations: null
    }
    {
      name: 'ManagementSubnet'
      addressPrefix: '172.17.36.192/26'
      privateEndpointNetworkPolicies: 'Disabled'
      privateLinkServiceNetworkPolicies: 'Enabled'
      serviceEndpoints: null
      networkSecurityGroupName : null
      routeTableName: null
      delegations: null
    }
    {
      name: 'snet-compute'
      addressPrefix: '172.17.37.0/26'
      privateEndpointNetworkPolicies: 'Disabled'
      privateLinkServiceNetworkPolicies: 'Enabled'
      serviceEndpoints: null
      networkSecurityGroupName : null
      routeTableName: null
      delegations: null
    }
  ]
  appNsgName : '${resourceAbbreviations.networkNetworkSecurityGroups}${resourceSuffix}${resourceAbbreviations.webSitesAppServiceEnvironment}01'
  appSubnetName: '${resourceAbbreviations.networkVirtualNetworksSubnets}${resourceSuffix}${resourceAbbreviations.webSitesAppServiceEnvironment}01'
  privateEndpointSubnetName : '${resourceAbbreviations.networkVirtualNetworksSubnets}${resourceSuffix}${resourceAbbreviations.networkPrivateEndpoints}01'
  privateEndpointNsgName : '${resourceAbbreviations.networkNetworkSecurityGroups}${resourceSuffix}${resourceAbbreviations.networkPrivateEndpoints}01'
  aseRouteTableName : '${resourceAbbreviations.networkRouteTables}${resourceSuffix}${resourceAbbreviations.webSitesAppServiceEnvironment}01'
  // Key Vault
  keyVaultName : '${resourceAbbreviations.keyVaultVaults}${resourceSuffix}01'
  keyVaultPrivateEndpointName: '${resourceAbbreviations.networkPrivateEndpoints}${resourceAbbreviations.keyVaultVaults}${resourceSuffix}01'
  keyVaultPrivateEndpointNetworkInterfaceName: '${resourceAbbreviations.networkPrivateEndpoints}${resourceAbbreviations.keyVaultVaults}${resourceSuffix}01-${replace(resourceAbbreviations.networkNetworkInterfaces, '-', '')}'
  // App Service Environment
  aseName : '${resourceAbbreviations.webSitesAppServiceEnvironment}${resourceSuffix}01'
  dedicatedHostCount : environment == 'prod' ? 2 : 0
  zoneRedundantAse : environment == 'prod' ? true : false
  applicationInsightsName : '${resourceAbbreviations.insightsComponents}${resourceSuffix}01'
  // Event Grid
  eventGridName : '${resourceAbbreviations.eventGridNamespaces}${resourceSuffix}01'
  eventGridPrivateEndpointName: '${resourceAbbreviations.networkPrivateEndpoints}${resourceAbbreviations.eventGridNamespaces}${resourceSuffix}01'
  eventGridPrivateEndpointNetworkInterfaceName: '${resourceAbbreviations.networkPrivateEndpoints}${resourceAbbreviations.eventGridNamespaces}${resourceSuffix}01-${replace(resourceAbbreviations.networkNetworkInterfaces, '-', '')}'
  // Service Bus
  serviceBusName : '${resourceAbbreviations.serviceBusNamespaces}${resourceSuffix}01'
  serviceBusSku : 'Standard'
  serviceBusCapacity : environment == 'prod' ? 2 : 1
  serviceBusPrivateEndpointName: '${resourceAbbreviations.networkPrivateEndpoints}${resourceAbbreviations.serviceBusNamespaces}${resourceSuffix}01'
  serviceBusPrivateEndpointNetworkInterfaceName: '${resourceAbbreviations.networkPrivateEndpoints}${resourceAbbreviations.serviceBusNamespaces}${resourceSuffix}01-${replace(resourceAbbreviations.networkNetworkInterfaces, '-', '')}'
  // Storage Account
  storageAccountName : toLower(replace('${resourceAbbreviations.storageStorageAccounts}${resourceSuffix}01', '-', ''))
  storageAccountPrivateEndpointName: '${resourceAbbreviations.networkPrivateEndpoints}${resourceAbbreviations.storageStorageAccounts}${resourceSuffix}01'
  storageAccountPrivateEndpointNetworkInterfaceName: '${resourceAbbreviations.networkPrivateEndpoints}${resourceAbbreviations.storageStorageAccounts}${resourceSuffix}01-${replace(resourceAbbreviations.networkNetworkInterfaces, '-', '')}'
  // Virtual Machine
  virtualMachineName : 'vm-ae-inte-dev'
  virtualMachineResourceGroupName : '${resourceAbbreviations.resourcesResourceGroups}${resourceSuffix}compute-01'
  virtualMachineSubnetName : 'snet-compute'
}

