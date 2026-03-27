targetScope = 'subscription'

// Parameters
@description('Location for all resources.')
param location string = deployment().location
@description('Name of the networking resource group.')
param networkingResourceGroupName string
@description('Name of the shared resource group.')
param sharedResourceGroupName string
@description('Name of the App Service Environment resource group.')
param aseResourceGroupName string
@description('Tags to be applied to all resources.')
param tags object = {}
@description('Whether to deploy sample APIs and resources.')
param deploySample bool = true

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Virtual Network parameters
@description('Required. The Virtual Network (vNet) Name.')
param virtualNetworkName string = 'vnet-spoke'
@description('Required. An Array of 1 or more IP Address Prefixes for the Virtual Network.')
param vNetAddressPrefixes array = [
  '172.17.0.0/16'
]
@description('Required. The subnet properties.')
param subnets array
@description('Route configuration for Azure Firewall traffic.')
param firewallRoute object = {}
@description('The private endpoint subnet name.')
param privateEndpointSubnetName string
@description('Name of the network security group for private endpoints.')
param privateEndpointNsgName string
@description('Name of the subnet for App Service Environment.')
param appSubnetName string
@description('Name of the network security group for ASE subnet.')
param appNsgName string
@description('Name of the route table for ASE subnet.')
param aseRouteTableName string

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// App Service Environment parameters
@description('Required. Name of ASEv3.')
param aseName string
@description('Required. Dedicated host count of ASEv3.')
param dedicatedHostCount int = 0
@description('Required. Zone redundant of ASEv3.')
param zoneRedundant bool = false
@description('Required. Specifies which endpoints to serve internally in the Virtual Network for the App Service Environment: \'None\', \'Publishing\', \'Web\', \'Web, Publishing\'')
@allowed([
  'None', 'Publishing', 'Web', 'Web, Publishing'
])
param internalLoadBalancingMode string = 'Web, Publishing'

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Azure Key Vault parameters
@description('Name of the Azure Key Vault resource.')
param keyVaultName string 
@description('Name of the Key Vault private endpoint.')
param keyVaultPrivateEndpointName string
@description('Name of the Key Vault private endpoint network interface.')
param keyVaultPrivateEndpointNetworkInterfaceName string

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Azure Log Analytics parameters
@description('The Log Analytics workspace.')
param logAnalyticsWorkspaceId string
@description('Array of diagnostic settings for Log Analytics.')
param logAnalyticsDiagnosticSettings array = []

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Application Insights parameters
@description('The connection string of the Application Insights instance that the API Management service will log to.')
param applicationInsightsConnectionString string?

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Azure Event Grid parameters
@description('The name of the Event Grid to be created.')
param eventGridName string
@description('Name of the Event Grid private endpoint.')
param eventGridPrivateEndpointName string
@description('Name of the Event Grid private endpoint network interface.')
param eventGridPrivateEndpointNetworkInterfaceName string

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Azure Service Bus parameters
@description('The name of the Service Bus to be created.')
param serviceBusName string 
@description('The SKU of the Service Bus to be created. Only premium tier of Azure Service Bus supports private endpoints.')
@allowed([
  'Premium'
  'Standard'
])
param serviceBusSku string = 'Premium'
@description('The capacity of the Service Bus to be created.')
@minValue(1)
param serviceBusCapacity int = 2
@description('Name of the Service Bus private endpoint.')
param serviceBusPrivateEndpointName string
@description('Name of the Service Bus private endpoint network interface.')
param serviceBusPrivateEndpointNetworkInterfaceName string

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Storage account parameters
@description('Name of the Azure Storage Account resource.')
param storageAccountName string
@description('Name of the Storage Account private endpoint.')
param storageAccountPrivateEndpointName string
@description('Name of the Storage Account private endpoint network interface.')
param storageAccountPrivateEndpointNetworkInterfaceName string

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Variables


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Resource Groups
resource networkingResourceGroup 'Microsoft.Resources/resourceGroups@2025-04-01' = {
  name: networkingResourceGroupName
  location: location
  tags: tags
}

resource sharedResourceGroup 'Microsoft.Resources/resourceGroups@2025-04-01' = {
  name: sharedResourceGroupName
  location: location
  tags: tags
}

resource aseResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: aseResourceGroupName
  location: location
  tags: tags
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Network Security Groups
module privateEndpointNetworkSecurityGroup 'br/public:avm/res/network/network-security-group:0.5.2' = {
  name: 'privateEndpointNetworkSecurityGroupDeployment'
  scope: networkingResourceGroup
  params: {
    name: privateEndpointNsgName
    location: location
    tags: tags
    securityRules: []
  }
}

module appServiceEnvironmentNetworkSecurityGroup 'br/public:avm/res/network/network-security-group:0.5.2' = {
  name: 'appServiceEnvironmentNetworkSecurityGroupDeployment'
  scope: networkingResourceGroup
  params: {
    name: appNsgName
    location: location
    tags: tags
    securityRules: [
      { 
        name: 'AllowHTTPSInbound'
        properties: {
          description: 'Allow HTTPS inbound'
          access: 'Allow'
          destinationAddressPrefix: '*'
          destinationAddressPrefixes: null
          destinationPortRanges: null
          destinationPortRange: '443'
          direction: 'Inbound'
          priority: 100
          protocol: 'Tcp'
          sourceAddressPrefix: 'VirtualNetwork'
          sourcePortRanges: null
          sourcePortRange: '*'
        }
      }
      { 
        name: 'AllowHealthPingInbound'
        properties: {
          description: 'Allow Health Ping inbound'
          access: 'Allow'
          destinationAddressPrefix: '*'
          destinationAddressPrefixes: null
          destinationPortRanges: null
          destinationPortRange: '80'
          direction: 'Inbound'
          priority: 101
          protocol: 'Tcp'
          sourceAddressPrefix: 'AzureLoadBalancer'
          sourcePortRanges: null
          sourcePortRange: '*'
        }
      }
    ]
  }
}

// Route Tables
module aseRouteTable 'br/public:avm/res/network/route-table:0.5.0' = {
  name: 'aseRouteTableDeployment'
  scope: networkingResourceGroup
  params: {
    name: aseRouteTableName
    location: location
    tags: tags
    disableBgpRoutePropagation: false
    routes: [
      firewallRoute
    ]
  }
}


// ---- Create Virtual Network with subnets ----
module networking './networking/networking.bicep' = {
  name: 'spokeNetworkDeployment'
  scope: networkingResourceGroup
  dependsOn: [
    privateEndpointNetworkSecurityGroup
    appServiceEnvironmentNetworkSecurityGroup
    aseRouteTable
  ]
  params: {
    useExistingVirtualNetwork: false
    useExistingVirtualNetworkSubnets: false
    virtualNetworkName: virtualNetworkName
    vNetAddressPrefixes: vNetAddressPrefixes
    location: location
    tags: tags
    subnets: subnets  
    deployDns: true
  }
}

// ---- End Virtual Network with subnets ----
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Azure App Service Environment
@description('Resource ID of the subnet for App Service Environment.')
var aseSubnetId = filter(networking.outputs.deployedSubnets, subnet => subnet.name == appSubnetName)[0].resourceId
var aseSubnetCIDR = filter(subnets, subnet => subnet.name == appSubnetName)[0].addressPrefix
module appServiceEnvironment './web/main.bicep' = {
  name: 'aseDeployment'
  scope: aseResourceGroup
  params: {
    aseName: aseName
    location: location
    tags: tags
    applicationInsightsConnectionString: applicationInsightsConnectionString
    dedicatedHostCount: dedicatedHostCount
    zoneRedundant: zoneRedundant
    internalLoadBalancingMode: internalLoadBalancingMode
    subnetId: aseSubnetId
    createPrivateDNS: true
    privateDnsResourceGroupName: networkingResourceGroup.name
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    deploySample: deploySample
  }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Azure Key Vault

@description('Resource ID of the subnet for private endpoints.')
var privateEndpointSubnetId = filter(networking.outputs.deployedSubnets, subnet => subnet.name == privateEndpointSubnetName)[0].resourceId
@description('Resource ID of the Key Vault private DNS zone.')
var privateDnsZoneResourceId = filter(networking.outputs.deployedDnsZones, dnsZone => dnsZone.name == networking.outputs.keyVaultPrivateDnsZoneName)[0].resourceId

module keyVault './shared/modules/keyvault.bicep' = {
  name: 'spokeKeyVaultDeployment'
  scope: sharedResourceGroup
  params: {
    keyVaultName: keyVaultName
    location: location
    tags: tags
    privateEndpointSubnetId: privateEndpointSubnetId
    privateDnsZoneResourceId: privateDnsZoneResourceId
    keyVaultPrivateEndpointName: keyVaultPrivateEndpointName
    keyVaultPrivateEndpointNetworkInterfaceName: keyVaultPrivateEndpointNetworkInterfaceName
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    diagnosticSettings: logAnalyticsDiagnosticSettings
  }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Azure Event Grid

// Get private endpoint subnet and DNS zone references (same pattern as Key Vault)
@description('Resource ID of the subnet for Event Grid private endpoint.')
var eventGridPrivateEndpointSubnetId = filter(networking.outputs.deployedSubnets, subnet => subnet.name == privateEndpointSubnetName)[0].resourceId
@description('Resource ID of the Event Grid private DNS zone.')
var eventGridPrivateDnsZoneResourceId = filter(networking.outputs.deployedDnsZones, dnsZone => dnsZone.name == networking.outputs.eventGridPrivateDnsZoneName)[0].resourceId

module eventGrid 'br/public:avm/res/event-grid/namespace:0.7.3' = {
  scope: sharedResourceGroup
  name: 'eventGridDeployment'
  params: {
    name: eventGridName
    location: location
    tags: tags
    isZoneRedundant: true
    
    // Disable public network access (private endpoints only)
    publicNetworkAccess: 'Disabled'
    
    // Diagnostics settings
    diagnosticSettings: [
        for (diagnosticSetting, index) in (logAnalyticsDiagnosticSettings ?? []): {
        name: '${diagnosticSetting.?namePrefix}${eventGridName}-${diagnosticSetting.?destinationSuffix}'
        workspaceResourceId: diagnosticSetting.?workspaceResourceId
        logCategoriesAndGroups: diagnosticSetting.?logCategoriesAndGroups
        metricCategories: diagnosticSetting.?metricCategories
      }
    ]
    
    // Private endpoint configuration
    privateEndpoints: [
      {
        name: eventGridPrivateEndpointName
        customNetworkInterfaceName: eventGridPrivateEndpointNetworkInterfaceName
        subnetResourceId: eventGridPrivateEndpointSubnetId
        privateDnsZoneGroup: {
          privateDnsZoneGroupConfigs: [
            {
              privateDnsZoneResourceId: eventGridPrivateDnsZoneResourceId
            }
          ]
        }
        tags: tags
      }
    ]

    // roleAssignments: [
    //   {
    //     principalId: apiManagement.outputs.apimSystemAssignedPrincipalId
    //     principalType: 'ServicePrincipal'
    //     roleDefinitionIdOrName: 'd5a91429-5739-47e2-a06b-3470a27159e7'  // 'EventGrid Data Sender'
    //   }
    //   {
    //     principalId: apiManagement.outputs.apimSystemAssignedPrincipalId
    //     principalType: 'ServicePrincipal'
    //     roleDefinitionIdOrName: '2414bbcf-6497-4faf-8c65-045460748405' // 'EventGrid EventSubscription Reader'
    //   }
    // ]
  }
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Azure Service Bus

// Get private endpoint subnet and DNS zone references (same pattern as Key Vault)
@description('Resource ID of the subnet for Service Bus private endpoint.')
var serviceBusPrivateEndpointSubnetId = filter(networking.outputs.deployedSubnets, subnet => subnet.name == privateEndpointSubnetName)[0].resourceId
@description('Resource ID of the Service Bus private DNS zone.')
var serviceBusPrivateDnsZoneResourceId = filter(networking.outputs.deployedDnsZones, dnsZone => dnsZone.name == networking.outputs.serviceBusPrivateDnsZoneName)[0].resourceId

module serviceBus 'br/public:avm/res/service-bus/namespace:0.16.0' = {
  scope: sharedResourceGroup
  name: 'serviceBusDeployment'
  params: {
    name: serviceBusName
    location: location
    tags: tags
    skuObject: {
      capacity: serviceBusCapacity
      name: serviceBusSku
    }
    
    // Disable public network access (private endpoints only)
    publicNetworkAccess: (serviceBusSku == 'Premium') ? 'Disabled' : 'Enabled'
    
    // Diagnostics settings
    diagnosticSettings: [
        for (diagnosticSetting, index) in (logAnalyticsDiagnosticSettings ?? []): {
        name: '${diagnosticSetting.?namePrefix}${serviceBusName}-${diagnosticSetting.?destinationSuffix}'
        workspaceResourceId: diagnosticSetting.?workspaceResourceId
        logCategoriesAndGroups: diagnosticSetting.?logCategoriesAndGroups
        metricCategories: diagnosticSetting.?metricCategories
      }
    ]
    
    // Private endpoint configuration (same pattern as Key Vault)
    privateEndpoints: (serviceBusSku == 'Premium') ? [
      {
        name: serviceBusPrivateEndpointName
        customNetworkInterfaceName: serviceBusPrivateEndpointNetworkInterfaceName
        subnetResourceId: serviceBusPrivateEndpointSubnetId
        privateDnsZoneGroup: {
          privateDnsZoneGroupConfigs: [
            {
              privateDnsZoneResourceId: serviceBusPrivateDnsZoneResourceId
            }
          ]
        }
        tags: tags
      }
    ] : []

    networkRuleSets: (serviceBusSku == 'Premium') ? null : {
      publicNetworkAccess: 'Disabled'
      defaultAction: 'Deny'
      ipRules: [
        {
          ipMask: aseSubnetCIDR
          action: 'Allow'
        }
      ]
    }


    // roleAssignments: [
    //   {
    //     principalId: '<principalId>'
    //     principalType: 'ServicePrincipal'
    //     roleDefinitionIdOrName: 'Owner'
    //   }
    //   {
    //     principalId: '<principalId>'
    //     principalType: 'ServicePrincipal'
    //     roleDefinitionIdOrName: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
    //   }
    //   {
    //     principalId: '<principalId>'
    //     principalType: 'ServicePrincipal'
    //     roleDefinitionIdOrName: '<roleDefinitionIdOrName>'
    //   }
    // ]
  }
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Azure Storage Account with SFTP enabled

// Get private endpoint subnet and storage blob private DNS zone references
@description('Resource ID of the subnet for Storage private endpoint.')
var storagePrivateEndpointSubnetId = filter(networking.outputs.deployedSubnets, subnet => subnet.name == privateEndpointSubnetName)[0].resourceId
@description('Resource ID of the Storage Blob private DNS zone.')
var storageBlobPrivateDnsZoneResourceId = filter(networking.outputs.deployedDnsZones, dnsZone => dnsZone.name == networking.outputs.storageBlobPrivateDnsZoneName)[0].resourceId

#disable-next-line BCP081
module storageAccount 'br/public:avm/res/storage/storage-account:0.29.0' = {
  scope: sharedResourceGroup
  name: 'storageAccountDeployment'
  params: {
    name: storageAccountName
    location: location
    tags: tags
    
    // Storage account configuration
    kind: 'StorageV2'
    skuName: 'Standard_ZRS'
    
    // Enable SFTP
    enableSftp: true
    isLocalUserEnabled : true
    
    // Security configuration - disable public access
    allowBlobPublicAccess: false
    publicNetworkAccess: 'Disabled'
    
    // Enable hierarchical namespace for SFTP
    enableHierarchicalNamespace: true
    
    // Diagnostics settings
    diagnosticSettings: [
        for (diagnosticSetting, index) in (logAnalyticsDiagnosticSettings ?? []): {
        name: '${diagnosticSetting.?namePrefix}${storageAccountName}-${diagnosticSetting.?destinationSuffix}'
        workspaceResourceId: diagnosticSetting.?workspaceResourceId
        //logCategoriesAndGroups: diagnosticSetting.?logCategoriesAndGroups
        metricCategories: diagnosticSetting.?metricCategories
      }
    ]
    
    // Private endpoint configuration for blob service
    privateEndpoints: [
      {
        name: storageAccountPrivateEndpointName
        customNetworkInterfaceName: storageAccountPrivateEndpointNetworkInterfaceName
        service: 'blob'
        subnetResourceId: storagePrivateEndpointSubnetId
        privateDnsZoneGroup: {
          privateDnsZoneGroupConfigs: [
            {
              privateDnsZoneResourceId: storageBlobPrivateDnsZoneResourceId
            }
          ]
        }
        tags: tags
      }
    ]
  }
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

output virtualNetworkId string = networking.outputs.id
output virtualNetworkName string = networking.outputs.name
