param apimName string
param productName string
param apiName string = 'colors-api'

resource apim 'Microsoft.ApiManagement/service@2024-06-01-preview' existing = {
  name: apimName
}

resource product 'Microsoft.ApiManagement/service/products@2024-06-01-preview' existing = {
  parent: apim
  name: productName
}

resource starter_colors_api 'Microsoft.ApiManagement/service/products/apis@2024-06-01-preview' = {
  parent: product
  name: apiName
}
