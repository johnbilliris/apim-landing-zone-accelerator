targetScope = 'tenant'

// Parameters
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

param hubSubscriptionId string 
param spokeSubscriptionId string
param applicationInsightsSubscriptionId string = hubSubscriptionId  

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Resource Names and Parameters
module resourceNames 'resourceNames.bicep' = {
  name: 'resourceNamesDeployment'
  scope: subscription(hubSubscriptionId)
  params: {
    workloadName: workloadName
    environment: environment
    location: location
  }
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Existing Log Analytics Workspaces and Diagnostic Settings
// Existing Application Insights
module existingResources 'existingResources.bicep' = {
  name: 'existingResourcesDeployment'
  scope: subscription(hubSubscriptionId)
}

var logAnalyticsWorkspaces = existingResources.outputs.logAnalyticsWorkspaces
var hasSentinelLogAnalyticsWorkspaces = logAnalyticsWorkspaces != null && length(filter(logAnalyticsWorkspaces, law => law.type == 'sentinel')) > 0
var hasLogAnalyticsWorkspaces = logAnalyticsWorkspaces != null && length(filter(logAnalyticsWorkspaces, law => law.type == 'law')) > 0
var sentinel = hasSentinelLogAnalyticsWorkspaces ? filter(logAnalyticsWorkspaces, law => law.type == 'sentinel')[0] : null
var logAnalytics = hasLogAnalyticsWorkspaces ? filter(logAnalyticsWorkspaces, law => law.type == 'law')[0] : null

var sentinelDiagnosticSettings = !(hasSentinelLogAnalyticsWorkspaces && sentinel.diagnosticSettingsEnabled) ? null : [{
  namenamePrefix: sentinel.diagnosticSetting.?namePrefix
  destinationSuffix: sentinel.type
  workspaceResourceId: sentinelLogAnalyticsWorkspace.id
  logCategoriesAndGroups: sentinel.diagnosticSetting.?logCategoriesAndGroups
  metricCategories: sentinel.diagnosticSetting.?metricCategories
}]

var logAnalyticsDiagnosticSettings = !(hasLogAnalyticsWorkspaces && logAnalytics.diagnosticSettingsEnabled) ? null : [{
  namenamePrefix: logAnalytics.diagnosticSetting.?namePrefix
  destinationSuffix: logAnalytics.type
  workspaceResourceId: lawLogAnalyticsWorkspace.id
  logCategoriesAndGroups: logAnalytics.diagnosticSetting.?logCategoriesAndGroups
  metricCategories: logAnalytics.diagnosticSetting.?metricCategories
}]

resource sentinelLogAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2025-07-01' existing = if (hasSentinelLogAnalyticsWorkspaces) {
  name: sentinel.name
  scope: resourceGroup(sentinel.subscriptionId, sentinel.resourceGroupName)
}
resource lawLogAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2025-07-01' existing = if (hasLogAnalyticsWorkspaces) {
  name: logAnalytics.name
  scope: resourceGroup(logAnalytics.subscriptionId, logAnalytics.resourceGroupName)
}

var applicationInsights = existingResources.outputs.applicationInsights
module appInsightsModule 'shared/modules/appInsights.bicep' = {
  name: 'appInsightsDeployment'
  scope: subscription(applicationInsightsSubscriptionId)
  params: {
    applicationInsights: applicationInsights
  }
}

var applicationInsightsId = appInsightsModule.outputs.id
var applicationInsightsConnectionString = appInsightsModule.outputs.connectionString

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Variables



//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
module hub './hub.bicep' = {
  name: 'hubResourcesDeployment'
  scope: subscription(hubSubscriptionId)
  params: {
    // Core
    location: location
    tags: resourceNames.outputs.tags
    deploySample: resourceNames.outputs.deploySample
    // Network
    hubResourceGroupName: resourceNames.outputs.hub.network.resourceGroupName
    virtualNetworkName: resourceNames.outputs.hub.network.virtualNetworkName
    virtualNetworkAddressPrefixes: resourceNames.outputs.hub.network.virtualNetworkAddressPrefixes
    virtualNetworkSubnets: resourceNames.outputs.hub.network.virtualNetworkSubnets
    routeTableGatewaySubnetName: resourceNames.outputs.hub.network.routeTableGatewaySubnetName
    privateEndpointSubnetName : resourceNames.outputs.hub.network.privateEndpointSubnetName
    privateEndpointNetworkSecurityGroupName: resourceNames.outputs.hub.network.privateEndpointNetworkSecurityGroupName
    privateEndpointRouteTableName: resourceNames.outputs.hub.network.privateEndpointRouteTableName
    useExistingVirtualNetwork : resourceNames.outputs.hub.network.useExistingVirtualNetwork
    useExistingVirtualNetworkSubnets : resourceNames.outputs.hub.network.useExistingVirtualNetworkSubnets
    // API
    apiCenterName: resourceNames.outputs.hub.api.apiCenterName
    deployApiCenter: resourceNames.outputs.hub.api.deployApiCenter
    apimName: resourceNames.outputs.hub.api.apimName
    apimPublisherEmail: resourceNames.outputs.hub.api.publisherEmail
    apimPublisherName: resourceNames.outputs.hub.api.publisherName
    apimSkuName: resourceNames.outputs.hub.api.apimSkuName
    apimCapacity: resourceNames.outputs.hub.api.apimCapacity
    apimVirtualNetworkType: resourceNames.outputs.hub.api.apimVirtualNetworkType
    apimSubnetName: resourceNames.outputs.hub.api.apimSubnetName
    apimNetworkSecurityGroupName: resourceNames.outputs.hub.api.apimNetworkSecurityGroupName
    apimRouteTableName: resourceNames.outputs.hub.api.apimRouteTableName
    apimResourceGroupName: resourceNames.outputs.hub.api.apimResourceGroupName
    apimAvailabilityZones: resourceNames.outputs.hub.api.availabilityZones
    apimPrivateEndpointName: resourceNames.outputs.hub.api.apimPrivateEndpointName
    apimPrivateEndpointNetworkInterfaceName: resourceNames.outputs.hub.api.apimPrivateEndpointNetworkInterfaceName
    deployApim: resourceNames.outputs.hub.api.deployApim
    // App Gateway
    appGatewayName: resourceNames.outputs.hub.appGateway.appGatewayName
    appGatewayPublicIPName: resourceNames.outputs.hub.appGateway.appGatewayPublicIPName
    appGatewayWAFPolicyName: resourceNames.outputs.hub.appGateway.appGatewayWAFPolicyName
    deployAppGateway: resourceNames.outputs.hub.appGateway.deployAppGateway
    // Application Insights
    applicationInsightsId: applicationInsightsId
    applicationInsightsConnectionString: applicationInsightsConnectionString
    // Azure Firewall
    azureFirewallName: resourceNames.outputs.hub.azureFirewall.azureFirewallName
    azureFirewallPublicIpName: resourceNames.outputs.hub.azureFirewall.azureFirewallPublicIPName
    deployAzureFirewall: resourceNames.outputs.hub.azureFirewall.deployAzureFirewall
    // Bastion
    bastionHostName: resourceNames.outputs.hub.bastion.bastionHostName
    bastionResourceGroupName: resourceNames.outputs.hub.bastion.bastionResourceGroupName
    bastionPublicIPName: resourceNames.outputs.hub.bastion.bastionPublicIPName
    bastionNetworkSecurityGroupName: resourceNames.outputs.hub.bastion.bastionNsgName
    deployBastion: resourceNames.outputs.hub.bastion.deployBastion
    // Key Vault
    keyVaultName: resourceNames.outputs.hub.keyVault.keyVaultName
    deployKeyVault: resourceNames.outputs.hub.keyVault.deployKeyVault
    // Log Analytics
    logAnalyticsWorkspaceId: lawLogAnalyticsWorkspace.id
    logAnalyticsDiagnosticSettings: logAnalyticsDiagnosticSettings
    sentinelLogAnalyticsWorkspaceId: sentinelLogAnalyticsWorkspace.id
    sentinelDiagnosticSettings: sentinelDiagnosticSettings
  }
}

// var firewallRoute = {
//         name: 'DefaultRoute'
//         properties: {
//           addressPrefix: '0.0.0.0/0'
//           nextHopType: 'VirtualAppliance'
//           nextHopIpAddress: hub.outputs.azureFirewallPrivateIp
//         }
//       }

// module spoke './spoke.bicep' = {
//   name: 'spokeResourcesDeployment'
//   scope: subscription(spokeSubscriptionId)
//   params: {
//     location: location
//     networkingResourceGroupName: resourceNames.outputs.spoke.networkingResourceGroupName
//     sharedResourceGroupName: resourceNames.outputs.spoke.sharedResourceGroupName
//     aseResourceGroupName: resourceNames.outputs.spoke.aseResourceGroupName
//     tags: resourceNames.outputs.tags
//     deploySample: resourceNames.outputs.deploySample
//     virtualNetworkName: resourceNames.outputs.spoke.virtualNetworkName
//     vNetAddressPrefixes: resourceNames.outputs.spoke.virtualNetworkAddressPrefixes
//     subnets: resourceNames.outputs.spoke.virtualNetworkSubnets
//     firewallRoute: firewallRoute
//     privateEndpointSubnetName: resourceNames.outputs.spoke.privateEndpointSubnetName
//     privateEndpointNsgName: resourceNames.outputs.spoke.privateEndpointNsgName
//     aseRouteTableName: resourceNames.outputs.spoke.aseRouteTableName
//     appSubnetName: resourceNames.outputs.spoke.appSubnetName
//     appNsgName: resourceNames.outputs.spoke.appNsgName
//     aseName: resourceNames.outputs.spoke.aseName
//     dedicatedHostCount: resourceNames.outputs.spoke.dedicatedHostCount
//     zoneRedundant: resourceNames.outputs.spoke.zoneRedundantAse
//     keyVaultName: resourceNames.outputs.spoke.keyVaultName
//     keyVaultPrivateEndpointName: resourceNames.outputs.spoke.keyVaultPrivateEndpointName
//     keyVaultPrivateEndpointNetworkInterfaceName: resourceNames.outputs.spoke.keyVaultPrivateEndpointNetworkInterfaceName
//     logAnalyticsWorkspaceId: lawLogAnalyticsWorkspace.id
//     logAnalyticsDiagnosticSettings: logAnalyticsDiagnosticSettings
//     applicationInsightsConnectionString: applicationInsightsConnectionString
//     eventGridName: resourceNames.outputs.spoke.eventGridName
//     eventGridPrivateEndpointName: resourceNames.outputs.spoke.eventGridPrivateEndpointName
//     eventGridPrivateEndpointNetworkInterfaceName: resourceNames.outputs.spoke.eventGridPrivateEndpointNetworkInterfaceName
//     serviceBusName: resourceNames.outputs.spoke.serviceBusName
//     serviceBusSku: resourceNames.outputs.spoke.serviceBusSku
//     serviceBusCapacity: resourceNames.outputs.spoke.serviceBusCapacity
//     serviceBusPrivateEndpointName: resourceNames.outputs.spoke.serviceBusPrivateEndpointName
//     serviceBusPrivateEndpointNetworkInterfaceName: resourceNames.outputs.spoke.serviceBusPrivateEndpointNetworkInterfaceName
//     storageAccountName: resourceNames.outputs.spoke.storageAccountName
//     storageAccountPrivateEndpointName: resourceNames.outputs.spoke.storageAccountPrivateEndpointName
//     storageAccountPrivateEndpointNetworkInterfaceName: resourceNames.outputs.spoke.storageAccountPrivateEndpointNetworkInterfaceName

//     virtualMachineName : resourceNames.outputs.spoke.virtualMachineName
//     virtualMachineResourceGroupName : resourceNames.outputs.spoke.virtualMachineResourceGroupName
//     virtualMachineSubnetName : resourceNames.outputs.spoke.virtualMachineSubnetName
//   }
// }

// ------------------------------------------------------------------------------------------
// Hub–Spoke VNet Peering (delegated modules at RG scope)
// ------------------------------------------------------------------------------------------
// var resourceAbbreviations = loadJsonContent('abbreviations.json')
// var shortenedLocation = toLower(location) == 'australiaeast' ? 'ae-' : 'as-'
// var resourceSuffix = '${shortenedLocation}${workloadName}-${environment}-'
// var hubVnetRg = '${resourceAbbreviations.resourcesResourceGroups}${shortenedLocation}connect-network-01'

// var spokeVnetRg = '${resourceAbbreviations.resourcesResourceGroups}${resourceSuffix}network-01'

// module hubToSpokePeering 'shared/modules/vnetPeering.bicep' = {
//   name: 'hubToSpokePeering'
//   scope: resourceGroup(hubSubscriptionId, hubVnetRg)
//   params: {
//     vnetName: resourceNames.outputs.hub.network.virtualNetworkName
//     peeringName: 'HubToSpoke'
//     remoteVnetId: spoke.outputs.virtualNetworkId
//   }
// }

// module spokeToHubPeering 'shared/modules/vnetPeering.bicep' = {
//   name: 'spokeToHubPeering'
//   scope: resourceGroup(spokeSubscriptionId, spokeVnetRg)
//   params: {
//     vnetName: spoke.outputs.virtualNetworkName
//     peeringName: 'SpokeToHub'
//     remoteVnetId: hub.outputs.hubVirtualNetworkId
//   }
// }








output hub object = resourceNames.outputs.hub
output spoke object = resourceNames.outputs.spoke

// // output sharedResourceGroupName string = sharedResourceGroupName
// // output apimResourceGroupName string = apimResourceGroupName
// // output apimName string = apimName
// // output apimIdentityName string = apimModule.outputs.apimIdentityName
// // output vnetId string = networking.outputs.apimCSVNetId
// // output vnetName string = networking.outputs.apimCSVNetName
// // output privateEndpointSubnetid string = networking.outputs.privateEndpointSubnetid
// // output deploymentIdentityName string = shared.outputs.deploymentIdentityName
// // output deploymentSubnetId string = networking.outputs.deploymentSubnetId
// // output deploymentStorageName string = shared.outputs.deploymentStorageName
// // output keyVaultName string = shared.outputs.keyVaultName
// // output appGatewayName string = appGatewayName
// // output appGatewayPublicIpAddress string = appgwModule.outputs.appGatewayPublicIpAddress

