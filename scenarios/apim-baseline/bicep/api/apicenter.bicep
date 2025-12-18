@description('Specifies the location for resources.')
param location string = resourceGroup().location

@description('The name of the API center.')
param apiCenterName string = 'apicenter${uniqueString(resourceGroup().id, location)}'

@description('The name of the API Management resource which contains the APIs.')
param apimName string = ''

@description('Tags to apply to all resources.')
param tags object = {}


var hasApim = !empty(apimName) ? true : false

resource apim 'Microsoft.ApiManagement/service@2024-05-01' existing = if (hasApim) {
  name: apimName
}

resource apiCenterService 'Microsoft.ApiCenter/services@2024-03-01' = {
  name: apiCenterName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  #disable-next-line BCP187
  sku: {
    name: 'Free'
  }
}

resource apiCenterWorkspace 'Microsoft.ApiCenter/services/workspaces@2024-03-01' = {
  parent: apiCenterService
  name: 'default'
  dependsOn: [ 
    roleAssignment
  ]
  properties: {
    title: 'Default workspace'
    description: 'Default workspace'
  }
}

resource apiWorkspaceEnvironment 'Microsoft.ApiCenter/services/workspaces/environments@2024-06-01-preview' = if (hasApim) {
  parent: apiCenterWorkspace
  name: 'Production'
  properties: {
    description: 'Production'
    kind: 'production'
    onboarding: {
      developerPortalUri: [
        #disable-next-line BCP318
        apim.properties.developerPortalUrl
      ]
      instructions: 'No instructions provided.'
    }
    server: {
      managementPortalUri: [
        #disable-next-line BCP318
        apim.properties.gatewayUrl
      ]
      type: 'azure-api-management'
    }
    title: 'Production API Management Environment'
  }
}


resource apiSource 'Microsoft.ApiCenter/services/workspaces/apiSources@2024-06-01-preview' = if (hasApim) {
  parent: apiCenterWorkspace
  name: apimName
  dependsOn: [
    apiWorkspaceEnvironment
    roleAssignment
  ]
  properties: {
    azureApiManagementSource: {
      // The correct format is: 'b5e5570f-671d-4290-9a28-52c53214f03d/21718850-a0d4-458f-a2e0-f86a6aa07f26/systemAssigned'
      msiResourceId: '${tenant().tenantId}/${apiCenterService.identity.principalId}/systemAssigned'
      resourceId: apim.id
    }
    importSpecification: 'always'
    // The correct format is: '/workspaces/{0}/environments/{1}
    targetEnvironmentId: '/workspaces/${apiCenterWorkspace.name}/environments/Production'
    targetLifecycleStage: 'production'
  }
}


// Azure RBAC for API Center to read API Management APIs
@description('Role ID for API Management Service Reader.')
var apiManagementServiceReaderRoleId = '71522526-b88f-4d52-b57f-d31fc3546d0d'

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (hasApim) {
  name: guid(apim.id, apiCenterService.id, apiManagementServiceReaderRoleId)
  scope: apim
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', apiManagementServiceReaderRoleId)
    principalId: apiCenterService.identity.principalId
    principalType: 'ServicePrincipal'
  }
}


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

output id string = apiCenterService.id
output resourceGroupName string = resourceGroup().name
output name string = apiCenterService.name
output location string = apiCenterService.location
