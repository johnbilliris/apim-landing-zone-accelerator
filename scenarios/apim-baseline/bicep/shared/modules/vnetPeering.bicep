targetScope = 'resourceGroup'

@description('Virtual network name to create peering on')
param vnetName string

@description('Peering name')
param peeringName string

@description('Remote virtual network resource ID')
param remoteVnetId string

@description('Allow forwarded traffic')
param allowForwardedTraffic bool = true

@description('Allow virtual network access')
param allowVirtualNetworkAccess bool = true

@description('Allow gateway transit')
param allowGatewayTransit bool = false

@description('Use remote gateways')
param useRemoteGateways bool = false

resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' existing = {
  name: vnetName
}

resource peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-02-01' = {
  name: peeringName
  parent: vnet
  properties: {
    allowForwardedTraffic: allowForwardedTraffic
    allowVirtualNetworkAccess: allowVirtualNetworkAccess
    allowGatewayTransit: allowGatewayTransit
    useRemoteGateways: useRemoteGateways
    remoteVirtualNetwork: {
      id: remoteVnetId
    }
  }
}
