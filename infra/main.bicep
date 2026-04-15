targetScope = 'resourceGroup'

@description('Deployment location.')
param location string = resourceGroup().location

@description('Prefix for resource naming.')
param namePrefix string = 'alertmachine'

@description('Tags applied to all resources where supported.')
param tags object = {
  workload: 'monitoring'
  managedBy: 'bicep'
}

@description('Logic App workflow name.')
param logicAppName string = 'AlertMachine'

@description('Request trigger name from workflow definition used to derive callback URL.')
param logicAppRequestTriggerName string = 'When_an_HTTP_request_is_received'

@description('Workflow parameters map, typically containing the $connections configuration.')
param logicAppWorkflowParameters object = {}

@description('Action Group resource name.')
param actionGroupName string = 'TriggerLogicApp'

@description('Action Group short name (max 12 chars).')
param actionGroupShortName string = 'Tigger'

@description('Action Group deployment location.')
param actionGroupLocation string = 'SwedenCentral'

@description('Logic App receiver display name in the Action Group.')
param actionGroupLogicAppReceiverName string = 'MyTrigger'

@description('Metric Alert resource name.')
param metricAlertName string = '${namePrefix}-metric-alert'

@description('Deploy a metric alert rule. Set to true when you want IaC to create the alert rule.')
param deployMetricAlert bool = false

@description('Resource ID of monitored resource.')
param metricTargetResourceId string = ''

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

var workflowDefinition = loadJsonContent('../logic-app-config/workflow.definition.json')

module logicApp 'modules/logicAppConsumption.bicep' = {
  name: 'logicAppDeployment'
  params: {
    logicAppName: logicAppName
    location: location
    workflowDefinition: workflowDefinition
    workflowParameters: logicAppWorkflowParameters
    requestTriggerName: logicAppRequestTriggerName
    tags: tags
  }
}

module actionGroup 'modules/actionGroup.bicep' = {
  name: 'actionGroupDeployment'
  params: {
    actionGroupName: actionGroupName
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
    metricAlertName: metricAlertName
    targetResourceId: metricTargetResourceId
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

output logicAppResourceId string = logicApp.outputs.logicAppId
output actionGroupResourceId string = actionGroup.outputs.actionGroupId
output metricAlertResourceId string = deployMetricAlert ? metricAlert!.outputs.metricAlertId : ''
