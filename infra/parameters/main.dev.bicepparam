using '../main.bicep'

param location = 'denmarkeast'

param namePrefix = 'Dev-'

param logicAppName = 'Alert_Router'

param logicAppRequestTriggerName = 'When_an_HTTP_request_is_received'

param armConnectionName = 'arm'

param actionGroupName = 'Trigger Alert Router Logic App'

param actionGroupShortName = 'RouteAlert'

param actionGroupLocation = 'SwedenCentral'

param actionGroupLogicAppReceiverName = 'Trigger alert router'

param deployMetricAlert = true

param metricAlertName = 'Simple-Metric-Alert'

// Defaults in main.bicep already target current subscription and VM type.
// Override here only when needed.
// param metricTargetScopeResourceId = '/subscriptions/<subscription-id>'
// param metricTargetResourceType = 'Microsoft.Compute/virtualMachines'
// param metricTargetResourceRegion = 'denmarkeast'

param metricNamespace = 'Microsoft.Compute/virtualMachines'

param metricName = 'Percentage CPU'

param metricTimeAggregation = 'Average'

param metricOperator = 'GreaterThan'

param metricThreshold = 80

param metricAlertSeverity = 2

param metricEvaluationFrequency = 'PT1M'

param metricWindowSize = 'PT5M'

param useCommonAlertSchema = true

param metricAutoMitigate = true

param metricAlertEnabled = true

param grantLogicAppSubscriptionReader = true

// subscriptionId defaults to subscription().subscriptionId at deploy time;
// only set explicitly if deploying the role assignment to a different subscription.
// param subscriptionId = 'fc17f768-1dca-47c0-8f35-4e1d7ba501e3'

param tags = {
  Workload: 'AlertRouting'
  managedBy: 'bicep'
}
