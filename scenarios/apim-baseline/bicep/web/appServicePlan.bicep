@description('App service location.')
param location string = resourceGroup().location

@description('Tags to be applied to all resources.')
param tags object = {}

@description('App service plan prefix.')
param appServicePlanName string

@description('App service plan hosting environment profile name (ASEv3 name).')
param appServiceEnvironmentName string

@description('App service plan sku.')
param sku string = 'IsolatedV2'

@description('App service plan sku code.')
param skuCode string = 'I1V2'

@description('The number of worker instances of your App Service plan that should be provisioned.')
param appServicePlanCapacity int

@description('Zone Redundant')
param zoneRedundant bool = false

resource appServiceEnvironment 'Microsoft.Web/hostingEnvironments@2024-11-01' existing = if (!empty(appServiceEnvironmentName)) { 
  name: appServiceEnvironmentName
}

resource hostingPlan 'Microsoft.Web/serverfarms@2024-11-01' = {
  name: appServicePlanName
  location: location
  tags: tags
  sku: {
    tier: sku
    name: skuCode
    capacity: appServicePlanCapacity
  }
  properties: {
    hostingEnvironmentProfile: {
      id: empty(appServiceEnvironment) ? null : appServiceEnvironment.id
    }
    zoneRedundant: zoneRedundant
  }
}

output id string = hostingPlan.id
output name string = hostingPlan.name
output location string = hostingPlan.location
output resourceGroupName string = resourceGroup().name
//output managedIdentityPrincipalId string = hostingPlan.identity.principalId
