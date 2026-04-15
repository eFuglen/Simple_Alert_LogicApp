@description('Name of the API connection resource (Microsoft.Web/connections).')
param connectionName string

@description('Azure region for the API connection resource.')
param location string

@description('Managed API name, for example arm, office365, or keyvault.')
param managedApiName string

@description('Subscription ID used when constructing the managed API resource ID.')
param subscriptionId string = subscription().subscriptionId

@description('Tags to apply to the API connection resource.')
param tags object = {}

// API version for Microsoft.Web/connections - stable version for consuming managed APIs
// See: https://learn.microsoft.com/en-us/azure/logic-apps/authenticate-with-managed-identity?tabs=consumption#single-authentication
resource apiConnection 'Microsoft.Web/connections@2016-06-01' = {
  name: connectionName
  location: location
  kind: 'V1'
  tags: tags
  properties: {
    displayName: connectionName
    api: {
      id: subscriptionResourceId(subscriptionId, 'Microsoft.Web/locations/managedApis', location, managedApiName)
    }
    parameterValueType: 'Alternative'
  }
}

output connectionId string = apiConnection.id
