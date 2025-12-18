@description('Name of the virtual network for DNS zone linking.')
param vnetName string
@description('Resource group containing the virtual network.')
param networkingResourceGroupName string
@description('Domain name for the private DNS zone.')
param domain string
@description('Tags to be applied to all resources')
param tags object = {}

resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' existing = {
  name: vnetName
  scope: resourceGroup(networkingResourceGroupName)
}

resource dnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: domain
  location: 'global'
  tags: !empty(tags) ? tags : null
}

resource vnetLinks 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: vnetName
  parent: dnsZone
  location: 'global'
  tags: !empty(tags) ? tags : null
  properties: {
    virtualNetwork: {
      id: vnet.id
    }
    registrationEnabled: false
  }
}

output dnsZoneName string = dnsZone.name
output dnsZoneId string = dnsZone.id
output vnetLinksLink string = vnetLinks.id

