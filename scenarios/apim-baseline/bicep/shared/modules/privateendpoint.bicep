@description('Name of the private endpoint resource.')
param privateEndpointName string
@description('Group ID for the private link service connection.')
param groupId string
@description('Azure region for resource deployment.')
param location string
@description('Name of the virtual network for DNS zone linking.')
param vnetName string
@description('Resource group containing the virtual network.')
param networkingResourceGroupName string
@description('Resource ID of the subnet for the private endpoint.')
param subnetId string
@description('Resource ID of the service to connect to.')
param serviceResourceId string
@description('Whether to create a new private DNS zone.')
param createDnsZone bool = true
@description('Domain name for the private DNS zone.')
param domain string
@description('Tags to be applied to the resource')
param tags object

#disable-next-line BCP081
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2024-10-01' = {
  name: privateEndpointName
  location: location
  tags: !empty(tags) ? tags : null
  properties: {
    customNetworkInterfaceName: '${privateEndpointName}-nic'
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: privateEndpointName
        properties: {
          privateLinkServiceId: serviceResourceId
          groupIds: [
            groupId
          ]
        }
      }
    ]
  }
}

module dnsZoneNew './dnszone.bicep' = if (createDnsZone == true) {
  name: take('${replace(domain, '.', '-')}-deploy', 64)
  params: {
    vnetName: vnetName
    networkingResourceGroupName: networkingResourceGroupName
    domain: domain
    tags: tags
  }
  dependsOn: [
    privateEndpoint
  ]
}

resource dnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' existing = if (createDnsZone == false) {
  scope: resourceGroup(networkingResourceGroupName)
  name: domain
}

@description('Name of the private DNS zone.')
var dnsZoneName = (createDnsZone == true) ? dnsZoneNew.outputs.dnsZoneName : dnsZone.name
@description('Resource ID of the private DNS zone.')
var dnsZoneId = (createDnsZone == true) ? dnsZoneNew.outputs.dnsZoneId : dnsZone.id

#disable-next-line BCP081
resource dnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-10-01' = {
  name: 'default'
  parent: privateEndpoint
  properties: {
    privateDnsZoneConfigs: [
      {      
        name: dnsZoneName
        properties: {
          privateDnsZoneId: dnsZoneId          
        }
      }
    ]
  }
}

output privateEndpointId string = privateEndpoint.id
output privateEndpointName string = privateEndpoint.name
output dnsZoneGroupId string = dnsZoneGroup.id
output location string = location


