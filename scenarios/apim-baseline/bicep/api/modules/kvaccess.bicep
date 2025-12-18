@description('Name of the Key Vault to grant access to.')
param keyVaultName            string
@description('Managed identity object for access policy.')
param managedIdentity         object   

resource keyVault 'Microsoft.KeyVault/vaults@2025-05-01' existing = {
  name: keyVaultName
}

resource accessPolicyGrant 'Microsoft.KeyVault/vaults/accessPolicies@2025-05-01' = {
  parent: keyVault
  name: 'add'
  properties: {
    accessPolicies: [
      {
        objectId: managedIdentity.principalId
        tenantId: managedIdentity.tenantId
        permissions: {
          secrets: [ 
            'get' 
            'list'
          ]
          certificates: [
            'get'
            'list'
          ]
        }                  
      }
    ]
  }
}

