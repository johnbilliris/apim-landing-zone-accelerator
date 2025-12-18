@description('Whether to use an existing virtual network.')
param useExistingVirtualNetwork bool = false

@description('Whether to use existing virtual network subnets.')
param useExistingVirtualNetworkSubnets bool = false

@description('Required. The Virtual Network (vNet) Name.')
param virtualNetworkName string

@description('Required. An Array of 1 or more IP Address Prefixes for the Virtual Network.')
param vNetAddressPrefixes array

@description('Location.')
param location string = resourceGroup().location

@description('Tags to be applied to the resource')
param tags object

@description('Required. The subnet properties.')
param subnets array

@description('An array of Diagnostic Settings to be applied to the virtual network.')
param diagnosticSettings array = []

@description('Deploy Private DNS Zones for Private Endpoints.')
param deployDns bool = false


@description('Private DNS zone name for Key Vault.')
#disable-next-line no-hardcoded-env-urls
var keyVaultPrivateDnsZoneName = 'privatelink.vaultcore.azure.net'

@description('Private DNS zone name for Azure Monitor.')
#disable-next-line no-hardcoded-env-urls
var monitorPrivateDnsZoneName = 'privatelink.monitor.azure.com'

@description('Private DNS zone name for Event Hub.')
#disable-next-line no-hardcoded-env-urls
var eventHubPrivateDnsZoneName = 'privatelink.servicebus.windows.net'

@description('Private DNS zone name for SQL Database.')
#disable-next-line no-hardcoded-env-urls
var sqlDbPrivateDnsZoneName = 'privatelink.database.azure.com'

@description('Private DNS zone name for Storage Blob.')
#disable-next-line no-hardcoded-env-urls
var storageBlobPrivateDnsZoneName = 'privatelink.blob.core.windows.net'

@description('Private DNS zone name for Storage File.')
#disable-next-line no-hardcoded-env-urls
var storageFilePrivateDnsZoneName = 'privatelink.file.core.windows.net'

@description('Private DNS zone name for Storage Table.')
#disable-next-line no-hardcoded-env-urls
var storageTablePrivateDnsZoneName = 'privatelink.table.core.windows.net'

@description('Private DNS zone name for Storage Queue.')
#disable-next-line no-hardcoded-env-urls
var storageQueuePrivateDnsZoneName = 'privatelink.queue.core.windows.net'

@description('Private DNS zone name for Event Grid.')
#disable-next-line no-hardcoded-env-urls
var eventGridPrivateDnsZoneName = 'privatelink.eventgrid.azure.net'

@description('Private DNS zone name for Service Bus.')
#disable-next-line no-hardcoded-env-urls
var serviceBusPrivateDnsZoneName = 'privatelink.servicebus.windows.net'

@description('Array of all private DNS zone names to deploy.')
var privateDnsZoneNames = [
  keyVaultPrivateDnsZoneName
  monitorPrivateDnsZoneName
  eventHubPrivateDnsZoneName 
  sqlDbPrivateDnsZoneName
  storageBlobPrivateDnsZoneName
  storageFilePrivateDnsZoneName
  storageTablePrivateDnsZoneName
  storageQueuePrivateDnsZoneName
  eventGridPrivateDnsZoneName
]

resource virtualNetworkExisting 'Microsoft.Network/virtualNetworks@2025-01-01' existing = if (useExistingVirtualNetwork)  {
  name: virtualNetworkName
}

resource virtualNetworkNew 'Microsoft.Network/virtualNetworks@2025-01-01' = if (!useExistingVirtualNetwork) {
  name: virtualNetworkName
  location: location
  tags: tags
  properties: {
    privateEndpointVNetPolicies: 'Disabled'
    addressSpace: {
      addressPrefixes: vNetAddressPrefixes
    }
    subnets: [for item in (useExistingVirtualNetworkSubnets ? [] : subnets): {
      name: item.name
      properties: {
        addressPrefix: item.addressPrefix
        networkSecurityGroup: (empty(item.networkSecurityGroupName) ? null : json('{"id": "${resourceId('Microsoft.Network/networkSecurityGroups', item.networkSecurityGroupName)}"}'))
        privateEndpointNetworkPolicies: empty(item.privateEndpointNetworkPolicies) ? null : item.privateEndpointNetworkPolicies
        privateLinkServiceNetworkPolicies: empty(item.privateLinkServiceNetworkPolicies) ? null : item.privateLinkServiceNetworkPolicies
        serviceEndpoints: empty(item.serviceEndpoints) ? null : item.serviceEndpoints
        routeTable: empty(item.routeTableName) ? null : json('{"id": "${resourceId('Microsoft.Network/routeTables', item.routeTableName)}"}')
        delegations: empty(item.delegations) ? null : item.delegations
      }
    }]
  }
}

resource virtualNetwork_diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = [
  for (diagnosticSetting, index) in ( !useExistingVirtualNetwork ? diagnosticSettings ?? [] : []): {
    name: '${diagnosticSetting.?namePrefix}${virtualNetworkName}-${diagnosticSetting.?destinationSuffix}'
    properties: {
      workspaceId: diagnosticSetting.?workspaceResourceId
      metrics: [
        for group in (diagnosticSetting.?metricCategories ?? [{ category: 'AllMetrics' }]): {
          category: group.category
          enabled: group.?enabled ?? true
          timeGrain: null
        }
      ]
      logs: [
        for group in (diagnosticSetting.?logCategoriesAndGroups ?? [{ categoryGroup: 'allLogs' }]): {
          categoryGroup: group.?categoryGroup
          category: group.?category
          enabled: group.?enabled ?? true
        }
      ]
    }
    scope:  virtualNetworkNew
  }
]

module dnsDeployment '../shared/modules/dnszone.bicep' = [for privateDnsZoneName in privateDnsZoneNames: if (deployDns) {
  name: 'dns-deployment-${privateDnsZoneName}'
  scope: resourceGroup()
  dependsOn: [
    virtualNetworkNew
    virtualNetworkExisting
  ] 
  params: {
    vnetName: virtualNetworkName
    networkingResourceGroupName: resourceGroup().name
    domain: privateDnsZoneName
    tags: tags
  }
}]

output id string = useExistingVirtualNetwork ? virtualNetworkExisting.id : virtualNetworkNew.id
output name string = virtualNetworkName
output location string = location
output resourceGroupName string = resourceGroup().name
output keyVaultPrivateDnsZoneName string = keyVaultPrivateDnsZoneName
output monitorPrivateDnsZoneName string = monitorPrivateDnsZoneName
output eventHubPrivateDnsZoneName string = eventHubPrivateDnsZoneName
output sqlDbPrivateDnsZoneName string = sqlDbPrivateDnsZoneName
output storageBlobPrivateDnsZoneName string = storageBlobPrivateDnsZoneName
output storageFilePrivateDnsZoneName string = storageFilePrivateDnsZoneName
output storageTablePrivateDnsZoneName string = storageTablePrivateDnsZoneName
output storageQueuePrivateDnsZoneName string = storageQueuePrivateDnsZoneName
output eventGridPrivateDnsZoneName string = eventGridPrivateDnsZoneName
output serviceBusPrivateDnsZoneName string = serviceBusPrivateDnsZoneName

@description('The resource IDs of the deployed subnets.')
output deployedSubnets array = [
  for (subnet, index) in (subnets ?? []): { 
    #disable-next-line BCP318
    name: useExistingVirtualNetwork ? virtualNetworkExisting.properties.subnets[index].name : virtualNetworkNew.properties.subnets[index].name
    #disable-next-line BCP318
    resourceId: useExistingVirtualNetwork ? virtualNetworkExisting.properties.subnets[index].id : virtualNetworkNew.properties.subnets[index].id
  }
]

@description('Service Bus private DNS zone array for output.')
var serviceBusPrivateDnsZone = [{ name: serviceBusPrivateDnsZoneName, resourceId: deployDns ? resourceId('Microsoft.Network/privateDnsZones', serviceBusPrivateDnsZoneName) : null }]
@description('Array of deployed private DNS zones with resource IDs.')
var deployedDnsZones_ array = [
  for (privateDnsZoneName,index) in privateDnsZoneNames:{
    name: privateDnsZoneName
    resourceId: deployDns ? resourceId('Microsoft.Network/privateDnsZones', privateDnsZoneName) : null
  }
]

output deployedDnsZones array = union(serviceBusPrivateDnsZone, deployedDnsZones_)

