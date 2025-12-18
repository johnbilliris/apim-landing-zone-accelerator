targetScope = 'subscription'

param applicationInsights array


// looks like this
// output applicationInsights array = [
//   {
//     name: 'appi-ae-mgmt-01'
//     resourceGroupName: 'rg-ae-mgmt-oms-01'
//     subscriptionId : subscription().subscriptionId
//   }
// ]


var hasApplicationInsights = applicationInsights != null && length(applicationInsights) > 0


resource applicationInsight 'Microsoft.Insights/components@2020-02-02' existing = if (hasApplicationInsights) {
  name: applicationInsights[0].name
  scope: resourceGroup(applicationInsights[0].subscriptionId, applicationInsights[0].resourceGroupName)
}

output id string = hasApplicationInsights ? applicationInsight.id : ''
output connectionString string = hasApplicationInsights ? applicationInsight.properties.ConnectionString : ''
