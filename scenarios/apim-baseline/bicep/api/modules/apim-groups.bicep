
param apimName string

resource apim 'Microsoft.ApiManagement/service@2024-10-01-preview' existing = {
  name: apimName
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// APIM Groups
resource administrators 'Microsoft.ApiManagement/service/groups@2024-06-01-preview' = {
  parent: apim
  name: 'administrators'
  properties: {
    displayName: 'Administrators'
    description: 'Administrators is a built-in group containing the admin email account provided at the time of service creation. Its membership is managed by the system.'
    type: 'system'
  }
}

resource developers 'Microsoft.ApiManagement/service/groups@2024-06-01-preview' = {
  parent: apim
  name: 'developers'
  properties: {
    displayName: 'Developers'
    description: 'Developers is a built-in group. Its membership is managed by the system. Signed-in users fall into this group.'
    type: 'system'
  }
}

resource guests 'Microsoft.ApiManagement/service/groups@2024-06-01-preview' = {
  parent: apim
  name: 'guests'
  properties: {
    displayName: 'Guests'
    description: 'Guests is a built-in group. Its membership is managed by the system. Unauthenticated users visiting the developer portal fall into this group.'
    type: 'system'
  }
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Products
resource starter 'Microsoft.ApiManagement/service/products@2024-06-01-preview' = {
  parent: apim
  name: 'Starter'
  properties: {
    displayName: 'Starter'
    description: 'Subscribers will be able to run 5 calls/minute up to a maximum of 100 calls/week.'
    subscriptionRequired: true
    approvalRequired: false
    subscriptionsLimit: 1
    state: 'published'
  }
}

resource unlimited 'Microsoft.ApiManagement/service/products@2024-06-01-preview' = {
  parent: apim
  name: 'Unlimited'
  properties: {
    displayName: 'Unlimited'
    description: 'Subscribers have completely unlimited access to the API. Administrator approval is required.'
    subscriptionRequired: true
    approvalRequired: true
    subscriptionsLimit: 1
    state: 'published'
  }
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Products to Groups associations
resource starter_administrators 'Microsoft.ApiManagement/service/products/groups@2024-06-01-preview' = {
  parent: starter
  name: 'administrators'
  dependsOn: [ administrators]
}

resource unlimited_administrators 'Microsoft.ApiManagement/service/products/groups@2024-06-01-preview' = {
  parent: unlimited
  name: 'administrators'
  dependsOn: [ administrators]
}

resource starter_developers 'Microsoft.ApiManagement/service/products/groups@2024-06-01-preview' = {
  parent: starter
  name: 'developers'
  dependsOn: [ developers]
}

resource unlimited_developers 'Microsoft.ApiManagement/service/products/groups@2024-06-01-preview' = {
  parent: unlimited
  name: 'developers'
  dependsOn: [ developers]
}

resource starter_guests 'Microsoft.ApiManagement/service/products/groups@2024-06-01-preview' = {
  parent: starter
  name: 'guests'
  dependsOn: [ guests]
}

resource unlimited_guests 'Microsoft.ApiManagement/service/products/groups@2024-06-01-preview' = {
  parent: unlimited
  name: 'guests'
  dependsOn: [ guests]
}
