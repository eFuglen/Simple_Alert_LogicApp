@description('Logic App workflow name.')
param logicAppName string

@description('Azure region for Logic App.')
param location string

@description('Workflow state.')
@allowed([
  'Enabled'
  'Disabled'
])
param state string = 'Enabled'

@description('Workflow definition JSON object.')
param workflowDefinition object

@description('Workflow parameters object, for example the $connections map.')
param workflowParameters object = {}

@description('Request trigger name used to generate callback URL for Action Group integration.')
param requestTriggerName string = 'manual'

@description('Tags to apply to the Logic App.')
param tags object = {}

resource logicApp 'Microsoft.Logic/workflows@2019-05-01' = {
  name: logicAppName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    state: state
    definition: workflowDefinition
    parameters: workflowParameters
  }
}

var triggerResourceId = resourceId('Microsoft.Logic/workflows/triggers', logicAppName, requestTriggerName)

output logicAppId string = logicApp.id
output logicAppNameOut string = logicApp.name
@secure()
output requestTriggerCallbackUrl string = listCallbackUrl(triggerResourceId, '2019-05-01').value
