targetScope='resourceGroup'

/*
 * Input parameters
*/

@description('The name of the API Management resource to be created.')
param apimName            string

@description('The subnet resource id to use for APIM.')
@minLength(1)
param apimSubnetId string

@description('The email address of the publisher of the APIM resource.')
@minLength(1)
param publisherEmail string = 'apim@contoso.com'

@description('Company name of the publisher of the APIM resource.')
@minLength(1)
param publisherName string = 'Contoso'

@description('The pricing tier of the APIM resource.')
@allowed(['Developer', 'Premium', 'StandardV2'])
param skuName string = 'Developer'

@description('Zone numbers e.g. 1,2,3.')
param availabilityZones array = (skuName == 'Premium') ? [
  '1'
  '2'
  '3'
] : []

@description('The instance size of the APIM resource.')
param capacity int = 1

@description('The type of virtual network integration to deploy. In \'External\' mode, a public IP address will be associated with the API Management service instance. In \'Internal\' mode, the instance is only accessible using private networking.')
@allowed([
  'External'
  'Internal'
  'None'
])
param virtualNetworkType string

@description('Location for Azure resources.')
param location string = resourceGroup().location

@description('Tags to apply to all resources.')
param tags object = {}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Application Insights Parameters
param applicationInsightsId string?
param applicationInsightsConnectionString string?

@description('The name of the Key Vault to grant access to.')
param keyVaultName                  string
@description('Resource group containing the Key Vault.')
param keyVaultResourceGroupName     string

@description('Name of the virtual network for APIM.')
param vnetName string
@description('Resource group containing the virtual network.')
param networkingResourceGroupName string


param privateEndpointName string
param privateEndpointNetworkInterfaceName string
param privateEndpointSubnetId string

param diagnosticSettings array = []

@description('Whether to deploy sample APIs and resources.')
param deploySample bool = true

/*
 * Resources
*/

var hasApplicationInsights = !empty(applicationInsightsId) && !empty(applicationInsightsConnectionString)
var apimPrivateDnsZoneName = '${apimName}.azure-api.net'
var loggerName = hasApplicationInsights ? last(split(applicationInsightsId!, '/')) : ''


resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-05-01' existing = {
  name: vnetName
  scope: resourceGroup(networkingResourceGroupName)
}


module privateDnsZone 'br/public:avm/res/network/private-dns-zone:0.7.0' = {
  name: 'apimPrivateDnsZoneDeployment'
  scope: resourceGroup(networkingResourceGroupName)
  params: {
    name: apimPrivateDnsZoneName
    location: 'global'
    virtualNetworkLinks: [
      {
        virtualNetworkResourceId: virtualNetwork.id
      }
    ]
    tags: tags
  }
}

module apim 'br/public:avm/res/api-management/service:0.12.0' = {
  name: 'apimServiceDeployment'
  params: {
    // Required parameters
    name: apimName
    publisherEmail: publisherEmail
    publisherName: publisherName
    location: location
    // Non-required parameters
    apiDiagnostics : (hasApplicationInsights) ? [

    ] : []
    availabilityZones: ((length(availabilityZones) > 0 && skuName == 'Premium') ? availabilityZones : null)
    customProperties: {
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_RSA_WITH_AES_128_GCM_SHA256': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_RSA_WITH_AES_256_CBC_SHA256': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_RSA_WITH_AES_128_CBC_SHA256': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_RSA_WITH_AES_256_CBC_SHA': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_RSA_WITH_AES_128_CBC_SHA': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TripleDes168': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Tls10': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Tls11': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Ssl30': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Tls10': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Tls11': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Ssl30': 'false'
    }
    diagnosticSettings: [
        for (diagnosticSetting, index) in (diagnosticSettings ?? []): {
        name: '${diagnosticSetting.?namePrefix}${apimName}-${diagnosticSetting.?destinationSuffix}'
        workspaceResourceId: diagnosticSetting.?workspaceResourceId
        logCategoriesAndGroups: diagnosticSetting.?logCategoriesAndGroups
        metricCategories: diagnosticSetting.?metricCategories
      }
    ]
    enableDeveloperPortal: true
    managedIdentities: {
      systemAssigned: true
    }
    minApiVersion: '2021-08-01'
    loggers: (hasApplicationInsights) ? [
      {
        name: loggerName
        type: 'applicationInsights'
        targetResourceId: applicationInsightsId
        credentials: {
          #disable-next-line BCP318
          connectionString: applicationInsightsConnectionString!
        }
        isBuffered: true
      }
    ] : []
    privateEndpoints: (skuName == 'StandardV2') ? [
      {
        name: privateEndpointName
        customNetworkInterfaceName: privateEndpointNetworkInterfaceName
        subnetResourceId: privateEndpointSubnetId
        service: 'Gateway'
        privateDnsZoneGroup: {
          privateDnsZoneGroupConfigs: [
            {
              privateDnsZoneResourceId: privateDnsZone.outputs.resourceId
            }
          ]
        }
        tags: tags
      }
    ] : null
    products: deploySample ? [
      {
        name: 'Starter'
        displayName: 'Starter'
        description: 'Subscribers will be able to run 5 calls/minute up to a maximum of 100 calls/week.'
        subscriptionRequired: true
        approvalRequired: false
        subscriptionsLimit: 1
        state: 'published'
      }
      {
        name: 'Unlimited'
        displayName: 'Unlimited'
        description: 'Subscribers have completely unlimited access to the API. Administrator approval is required.'
        subscriptionRequired: true
        approvalRequired: true
        subscriptionsLimit: 1
        state: 'published'
      }
    ] : []
    publicNetworkAccess: 'Enabled'
    sku: skuName
    skuCapacity: capacity
    subnetResourceId: apimSubnetId
    virtualNetworkType: virtualNetworkType
    tags: tags
  }
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// APIM Groups
module apimGroups './modules/apim-groups.bicep' = {
  name: 'apimGroupsDeployment'
  params: {
    apimName: apim.outputs.name
  }
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Colors API
// Deploy the Colors API if parameter is set to true
module colorsApi './modules/colors-api.bicep' = if (deploySample) {
  name: 'colorsApiDeploy'
  dependsOn: [
    apimGroups
  ]
  params: {
    apimName: apim.outputs.name
  }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module apimApplicationInsights './modules/applicationInsights.bicep' = if (hasApplicationInsights) {
  name: 'apimApplicationInsightsDeployment'
  dependsOn: [
    colorsApi
  ]
  params: {
    apimName: apim.outputs.name
    loggerName: loggerName
    apiNames: (deploySample) ? [
      'colors-api'
    ] : []
  }
}


module kvaccess './modules/kvaccess.bicep' = {
  name: 'apimKeyVaultAccessDeployment'
  scope: resourceGroup(keyVaultResourceGroupName)
  params: {
    managedIdentity:    { 
      principalId: apim.outputs.systemAssignedMIPrincipalId!
      tenantId:  tenant().tenantId
    }
    keyVaultName:       keyVaultName
  }
}


// For non-StandardV2 SKUs, we need a separate module to get the private IP since the existing resource 
// can't be evaluated at deployment time when its name depends on another module's output
module getApimPrivateIp './modules/get-apim-private-ip.bicep' = if (skuName != 'StandardV2') {
  name: 'getApimPrivateIpDeploy'
  params: {
    apimName: apim.outputs.name
  }
}

// Creation of private DNS zones
module dnsZoneModule './modules/dnsrecords.bicep' = {
  name: 'apimDnsRecordsDeploy'
  scope: resourceGroup(networkingResourceGroupName)
  params: {
    apimName: apim.outputs.name
    ipAddress: (skuName == 'StandardV2') 
      ? apim.outputs.privateEndpoints[0].customDnsConfigs[0].ipAddresses[0] 
      : getApimPrivateIp.outputs.privateIPAddress
  }
}


module apim2 'br/public:avm/res/api-management/service:0.12.0' = {
  name: 'apimServiceDeploymentDisablePublicAccess'
  dependsOn: [
    apimApplicationInsights
    dnsZoneModule
  ]
  params: {
    // Required parameters
    name: apimName
    publisherEmail: publisherEmail
    publisherName: publisherName
    location: location
    // Non-required parameters
    apiDiagnostics : (hasApplicationInsights) ? [

    ] : []
    availabilityZones: ((length(availabilityZones) > 0 && skuName == 'Premium') ? availabilityZones : null)
    customProperties: {
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_RSA_WITH_AES_128_GCM_SHA256': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_RSA_WITH_AES_256_CBC_SHA256': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_RSA_WITH_AES_128_CBC_SHA256': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_RSA_WITH_AES_256_CBC_SHA': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_RSA_WITH_AES_128_CBC_SHA': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TripleDes168': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Tls10': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Tls11': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Ssl30': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Tls10': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Tls11': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Ssl30': 'false'
    }
    diagnosticSettings: [
        for (diagnosticSetting, index) in (diagnosticSettings ?? []): {
        name: '${diagnosticSetting.?namePrefix}${apimName}-${diagnosticSetting.?destinationSuffix}'
        workspaceResourceId: diagnosticSetting.?workspaceResourceId
        logCategoriesAndGroups: diagnosticSetting.?logCategoriesAndGroups
        metricCategories: diagnosticSetting.?metricCategories
      }
    ]
    enableDeveloperPortal: true
    managedIdentities: {
      systemAssigned: true
    }
    minApiVersion: '2021-08-01'
    loggers: (hasApplicationInsights) ? [
      {
        name: loggerName
        type: 'applicationInsights'
        targetResourceId: applicationInsightsId
        credentials: {
          #disable-next-line BCP318
          connectionString: applicationInsightsConnectionString!
        }
        isBuffered: true
      }
    ] : []
    privateEndpoints: (skuName == 'StandardV2') ? [
      {
        name: privateEndpointName
        customNetworkInterfaceName: privateEndpointNetworkInterfaceName
        subnetResourceId: privateEndpointSubnetId
        service: 'Gateway'
        privateDnsZoneGroup: {
          privateDnsZoneGroupConfigs: [
            {
              privateDnsZoneResourceId: privateDnsZone.outputs.resourceId
            }
          ]
        }
        tags: tags
      }
    ] : null
    products: deploySample ? [
      {
        name: 'Starter'
        displayName: 'Starter'
        description: 'Subscribers will be able to run 5 calls/minute up to a maximum of 100 calls/week.'
        subscriptionRequired: true
        approvalRequired: false
        subscriptionsLimit: 1
        state: 'published'
      }
      {
        name: 'Unlimited'
        displayName: 'Unlimited'
        description: 'Subscribers have completely unlimited access to the API. Administrator approval is required.'
        subscriptionRequired: true
        approvalRequired: true
        subscriptionsLimit: 1
        state: 'published'
      }
    ] : []
    publicNetworkAccess: 'Disabled'
    sku: skuName
    skuCapacity: capacity
    subnetResourceId: apimSubnetId
    virtualNetworkType: virtualNetworkType
    tags: tags
  }
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

output id string = apim.outputs.resourceId
output name string = apim.outputs.name
output location string = apim.outputs.location
output apimSystemAssignedPrincipalId string = apim.outputs.systemAssignedMIPrincipalId!
//output apiManagementInternalIPAddress string = apim.outputs.internalIPAddress
//output apiManagementHostName string = apim.outputs.hostName
//output apiManagementDeveloperPortalHostName string = replace(apim.outputs.developerPortalUrl, 'https://', '')
//@description('Gateway URL for the deployed API Management resource.')
//output apimGatewayUrl string = apim.outputs.gatewayUrl


