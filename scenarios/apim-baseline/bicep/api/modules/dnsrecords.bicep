

@description('Name of the API Management service.')
param apimName                  string

@description('The private IP address for DNS records. For StandardV2 SKU, this should be the private endpoint IP. For other SKUs, this should be the APIM internal IP.')
param ipAddress string


resource apimDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: '${apimName}.azure-api.net'
}

resource gatewayRecord 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  parent: apimDnsZone
  name: '${apimName}.azure-api.net'
  properties: {
    aRecords: [
      {
        ipv4Address: ipAddress
      }
    ]
    ttl: 36000
  }
}

resource developerRecord 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  parent: apimDnsZone
  name: '${apimName}.developer.azure-api.net'
  properties: {
    aRecords: [
      {
        ipv4Address: ipAddress
      }
    ]
    ttl: 36000
  }
}
