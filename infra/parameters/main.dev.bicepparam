using '../main.bicep'

param location = 'denmarkeast'

param namePrefix = 'Dev-'

param logicAppName = 'Alert_Router'

param logicAppRequestTriggerName = 'When_an_HTTP_request_is_received'

// armConnectionName defaults to 'arm' in main.bicep; set here only if your
// connection resource was created with a different name.
// param armConnectionName = 'arm'

param actionGroupName = 'Trigger Alert Router Logic App'

param actionGroupShortName = 'RouteAlert'

param actionGroupLocation = 'SwedenCentral'

param actionGroupLogicAppReceiverName = 'Trigger alert router'

param deployMetricAlert = false

param metricAlertName = 'simplealert-metric-alert'

param metricTargetResourceId = ''

param metricNamespace = ''

param metricName = ''

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
