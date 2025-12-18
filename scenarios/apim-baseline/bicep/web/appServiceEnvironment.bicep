@description('App service environment location.')
param location string = resourceGroup().location

@description('Tags to be applied to all resources.')
param tags object = {}

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

@description('Optional. Property to enable and disable new private endpoint connection creation on ASE.')
param allowNewPrivateEndpointConnections bool = false

@description('Optional. Property to enable and disable FTP on ASEV3.')
param ftpEnabled bool = false

@description('Optional. Customer provided Inbound IP Address. Only able to be set on Ase create.')
param inboundIpAddressOverride string = ''

@description('Optional. Property to enable and disable Remote Debug on ASEv3.')
param remoteDebugEnabled bool = false


@description('Required. The subnet ID for the App Service Environment.')
param subnetId string

@description('Whether to create private DNS zone for ASE.')
param createPrivateDNS bool = true
@description('Resource group for the private DNS zone.')
param privateDnsResourceGroupName string = ''
@description('Resource ID of the virtual network.')
param virtualNetworkId string = substring(subnetId, 0, lastIndexOf(subnetId, '/subnets/'))
@description('Resource ID of the Log Analytics workspace.')
param logAnalyticsWorkspaceId string


resource asev3 'Microsoft.Web/hostingEnvironments@2025-03-01' = {
  name: aseName
  location: location
  kind: 'ASEv3'
  tags: tags
#disable-next-line BCP187
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    clusterSettings: [
      {
          name: 'DisableTls1.0'
          value: '1'
      }
    ]
    dedicatedHostCount: dedicatedHostCount
    zoneRedundant: zoneRedundant
    internalLoadBalancingMode: internalLoadBalancingMode
    virtualNetwork: {
      id: subnetId
    } 
  }
}


resource aseConfig 'Microsoft.Web/hostingEnvironments/configurations@2024-11-01' = {
  name: 'networking'
  parent: asev3
  properties: {
    allowNewPrivateEndpointConnections: allowNewPrivateEndpointConnections
    ftpEnabled: ftpEnabled
    inboundIpAddressOverride: inboundIpAddressOverride
    remoteDebugEnabled: remoteDebugEnabled
  }
}


resource appServiceEnvironment_diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(logAnalyticsWorkspaceId)) {
  name: '${aseName}-diagnosticSettings'
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      { 
        categoryGroup: 'allLogs'
        enabled: true 
      }
    ]
  }
  scope: asev3
}


@description('Whether to proceed with private DNS zone creation.')
var proceedWithPrivateDNS = createPrivateDNS && internalLoadBalancingMode != 'None'
@description('DNS suffix name for the private DNS zone.')
var privateDNSZoneName = asev3.properties.dnsSuffix


module privatednszone 'appServiceEnvironmentPrivateDNSZone.bicep' = if (proceedWithPrivateDNS) {
  name: 'appServiceEnvironment-PrivateDNSZone-Deployment'
  scope: resourceGroup(privateDnsResourceGroupName)
  params: {
    privateDNSZoneName: privateDNSZoneName
    virtualNetworkId: virtualNetworkId
    aseName: asev3.name
    aseResourceGroupName: resourceGroup().name
  }
}



output name string = asev3.name
output id string = asev3.id
output resourceGroupName string = resourceGroup().name
output location string = asev3.location
output privateDNSZoneName string = asev3.properties.dnsSuffix
output internalInboundIpAddress string = aseConfig.properties.internalInboundIpAddresses[0]
//output managedIdentityPrincipalId string = asev3.identity.principalId
//output managedIdentityTenantId string = asev3.identity.tenantId

