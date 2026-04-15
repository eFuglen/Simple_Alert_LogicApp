targetScope = 'resourceGroup'

@description('Deployment location.')
param location string = resourceGroup().location

@description('Prefix for resource naming.')
param namePrefix string = ''

@description('Tags applied to all resources where supported.')
param tags object = {}

@description('Logic App workflow name.')
param logicAppName string

@description('Request trigger name from workflow definition used to derive callback URL.')
param logicAppRequestTriggerName string = 'When_an_HTTP_request_is_received'

@description('Name of the ARM managed API connection resource that the Logic App uses to read Azure resources.')
param armConnectionName string = 'arm'

@description('Action Group resource name.')
param actionGroupName string

@description('Action Group short name (max 12 chars).')
@maxLength(12)
param actionGroupShortName string

@description('Action Group deployment location.')
param actionGroupLocation string = 'SwedenCentral'

@description('Logic App receiver display name in the Action Group.')
param actionGroupLogicAppReceiverName string

@description('Metric Alert resource name.')
param metricAlertName string = '${namePrefix}metric-alert'

@description('Deploy a metric alert rule. Set to true when you want IaC to create the alert rule.')
param deployMetricAlert bool = true

@description('Alert scope resource ID. Defaults to the current subscription to support alerts across all VMs in the subscription.')
param metricTargetScopeResourceId string = subscription().id

@description('Target resource type for the metric alert scope.')
param metricTargetResourceType string = 'Microsoft.Compute/virtualMachines'

@description('Target resource region for the metric alert scope.')
param metricTargetResourceRegion string = location

@description('Metric namespace, e.g. Microsoft.Compute/virtualMachines.')
param metricNamespace string = ''

@description('Metric name, e.g. Percentage CPU.')
param metricName string = ''

@description('Metric aggregation method.')
param metricTimeAggregation string = 'Average'

@description('Metric threshold operator.')
param metricOperator string = 'GreaterThan'

@description('Threshold value for metric alert.')
param metricThreshold int = 80

@description('Metric alert severity from 0 to 4.')
param metricAlertSeverity int = 2

@description('Evaluation frequency in ISO8601 duration format.')
param metricEvaluationFrequency string = 'PT1M'

@description('Evaluation window in ISO8601 duration format.')
param metricWindowSize string = 'PT5M'

@description('Enable common alert schema on action group receiver.')
param useCommonAlertSchema bool = true

@description('Enable automatic alert resolution.')
param metricAutoMitigate bool = true

@description('Enable or disable metric alert rule.')
param metricAlertEnabled bool = true

@description('Grant Logic App system-managed identity Reader access at subscription scope.')
param grantLogicAppSubscriptionReader bool = true

@description('Subscription ID used for constructing connection resource IDs and for the Reader role assignment scope. Defaults to the current deployment subscription.')
param subscriptionId string = subscription().subscriptionId

var workflowDefinition = loadJsonContent('../logic-app-config/workflow.definition.json')

// Construct the $connections workflow parameter dynamically from deployment context.
// armConnectionName is the resource name; 'arm' is the managed API type.
var armConnectionResourceName = '${namePrefix}${armConnectionName}'
var armConnectionId = '/subscriptions/${subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Web/connections/${armConnectionResourceName}'
var armManagedApiId = '/subscriptions/${subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/arm'
var workflowConnections = {
  '$connections': {
    value: {
      arm: {
        connectionId: armConnectionId
        connectionName: armConnectionResourceName
        connectionProperties: {
          authentication: {
            type: 'ManagedServiceIdentity'
          }
        }
        id: armManagedApiId
      }
    }
  }
}

module armConnection 'modules/apiConnection.bicep' = {
  name: 'armApiConnectionDeployment'
  params: {
    connectionName: armConnectionResourceName
    location: location
    managedApiName: 'arm'
    subscriptionId: subscriptionId
    tags: tags
  }
}

module logicApp 'modules/logicAppConsumption.bicep' = {
  name: 'logicAppDeployment'
  dependsOn: [
    armConnection
  ]
  params: {
    logicAppName: '${namePrefix}${logicAppName}'
    location: location
    workflowDefinition: workflowDefinition
    workflowParameters: workflowConnections
    requestTriggerName: logicAppRequestTriggerName
    tags: tags
  }
}

module actionGroup 'modules/actionGroup.bicep' = {
  name: 'actionGroupDeployment'
  params: {
    actionGroupName: '${namePrefix}${actionGroupName}'
    groupShortName: actionGroupShortName
    location: actionGroupLocation
    logicAppReceiverName: actionGroupLogicAppReceiverName
    logicAppResourceId: logicApp.outputs.logicAppId
    logicAppCallbackUrl: logicApp.outputs.requestTriggerCallbackUrl
    useCommonAlertSchema: useCommonAlertSchema
    tags: tags
  }
}

module metricAlert 'modules/metricAlert.bicep' = if (deployMetricAlert) {
  name: 'metricAlertDeployment'
  params: {
    metricAlertName: '${namePrefix}${metricAlertName}'
    targetScopeResourceId: metricTargetScopeResourceId
    targetResourceType: metricTargetResourceType
    targetResourceRegion: metricTargetResourceRegion
    metricNamespace: metricNamespace
    metricName: metricName
    threshold: metricThreshold
    timeAggregation: metricTimeAggregation
    operator: metricOperator
    severity: metricAlertSeverity
    evaluationFrequency: metricEvaluationFrequency
    windowSize: metricWindowSize
    actionGroupId: actionGroup.outputs.actionGroupId
    autoMitigate: metricAutoMitigate
    enabled: metricAlertEnabled
    tags: tags
  }
}

module logicAppSubscriptionReader 'modules/subscriptionReaderRoleAssignment.bicep' = if (grantLogicAppSubscriptionReader) {
  name: 'logicAppSubscriptionReaderRoleAssignment'
  scope: subscription(subscriptionId)
  params: {
    principalId: logicApp.outputs.logicAppPrincipalId
    principalType: 'ServicePrincipal'
  }
}

output logicAppResourceId string = logicApp.outputs.logicAppId
output actionGroupResourceId string = actionGroup.outputs.actionGroupId
output metricAlertResourceId string = deployMetricAlert ? metricAlert!.outputs.metricAlertId : ''
output logicAppPrincipalId string = logicApp.outputs.logicAppPrincipalId
output logicAppSubscriptionReaderRoleAssignmentId string = grantLogicAppSubscriptionReader ? logicAppSubscriptionReader!.outputs.roleAssignmentId : ''
