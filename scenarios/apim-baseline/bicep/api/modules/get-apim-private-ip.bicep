@description('Name of the API Management service.')
param apimName string

resource apim 'Microsoft.ApiManagement/service@2024-05-01' existing = {
  name: apimName
}

@description('The private IP address of the APIM service.')
output privateIPAddress string = apim.properties.privateIPAddresses[0]
