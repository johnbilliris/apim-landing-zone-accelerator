// Parameters
@description('Location for all resources.')
param location string = resourceGroup().location

@description('Name of the Key Vault to be created.')
param keyVaultName string

@description('Tags to be applied to all resources.')
param tags object = {}

@description('Array of secrets to store in the Key Vault.')
param secrets array = []

@description('Resource ID of the Log Analytics workspace.')
param logAnalyticsWorkspaceId string

@description('An array of Diagnostic Settings to be applied to the Key Vault.')
param diagnosticSettings array = []

@description('An array of Virtual Network Rules to be applied to the Key Vault.')
param virtualNetworkRules array = []

@description('The subnet Resource ID where the Key Vault Private Endpoint will be deployed.')
param privateEndpointSubnetId string

@description('The Private DNS Zone Resource ID to link with the Key Vault Private Endpoint.')
param privateDnsZoneResourceId string

@description('Name of the Key Vault private endpoint.')
param keyVaultPrivateEndpointName string = ''
@description('Name of the Key Vault private endpoint network interface.')
param keyVaultPrivateEndpointNetworkInterfaceName string = ''

@description('Current UTC timestamp for deployment.')
param now string = utcNow()
@description('Whether to enable public network access based on config.')
var hasPublicNetworkAccess = (empty(privateEndpointSubnetId) || empty(privateDnsZoneResourceId)) && empty(virtualNetworkRules) ? true : false

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Azure Key Vault
module keyVault 'br/public:avm/res/key-vault/vault:0.13.3' = {
  name: 'keyVaultDeployment'
  params: {
    name: keyVaultName
    location: location
    tags: tags
    sku: 'premium'
    
    publicNetworkAccess: hasPublicNetworkAccess ? 'Enabled' : 'Disabled'
    networkAcls: hasPublicNetworkAccess ? null : {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
      ipRules: []
      virtualNetworkRules: !empty(virtualNetworkRules) ? virtualNetworkRules : []
    }

    // Configure private endpoints
    privateEndpoints: empty(privateEndpointSubnetId) || empty(privateDnsZoneResourceId) ? null : [
      {
        name: keyVaultPrivateEndpointName
        customNetworkInterfaceName: keyVaultPrivateEndpointNetworkInterfaceName
        service: 'vault'
        subnetResourceId: privateEndpointSubnetId
        privateDnsZoneGroup: {
          privateDnsZoneGroupConfigs: [
            {
              privateDnsZoneResourceId: privateDnsZoneResourceId
            }
          ]
        }
        privateLinkServiceConnectionName: keyVaultPrivateEndpointName
        tags: tags
      }
    ]

    // Enable diagnostics to send to Log Analytics workspace
    diagnosticSettings:  [
        for (diagnosticSetting, index) in (diagnosticSettings ?? []): {
        name: '${diagnosticSetting.?namePrefix}${keyVaultName}-${diagnosticSetting.?destinationSuffix}'
        workspaceResourceId: logAnalyticsWorkspaceId
        logCategoriesAndGroups: diagnosticSetting.?logCategoriesAndGroups
        metricCategories: diagnosticSetting.?metricCategories
      }
    ]

    secrets: [
      for (secret, index) in (secrets ?? []): {
        attributes: {
          exp: secret.?expiry == null ? null : dateTimeToEpoch(dateTimeAdd(now, 'P${secret.expiry}D'))
          nbf: 10000
        }
        contentType: secret.?contentType
        name: secret.?name
        value: secret.?value
      }
    ]

    // RBAC configuration 
    enableRbacAuthorization: true
    
    // Soft delete and purge protection
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enablePurgeProtection: false
  }
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

output id string = keyVault.outputs.resourceId
output resourceGroupName string = keyVault.outputs.resourceGroupName
output name string = keyVault.outputs.name
output vaultUri string = keyVault.outputs.uri
output location string = keyVault.outputs.location
