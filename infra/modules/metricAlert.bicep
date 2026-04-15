@description('Metric alert rule name.')
param metricAlertName string

@description('Azure region used for deployment metadata. For metric alerts this is typically global.')
param location string = 'global'

@description('Resource ID scope for the alert. Use subscription().id to target all resources of a given type in a subscription.')
param targetScopeResourceId string

@description('Target resource type when using broader scopes (for example Microsoft.Compute/virtualMachines).')
param targetResourceType string = 'Microsoft.Compute/virtualMachines'

@description('Target resource region when using broader scopes (for example denmarkeast).')
param targetResourceRegion string

@description('Metric namespace, for example Microsoft.Compute/virtualMachines.')
param metricNamespace string

@description('Metric name, for example Percentage CPU.')
param metricName string

@description('Time aggregation for metric evaluation.')
@allowed([
  'Average'
  'Minimum'
  'Maximum'
  'Total'
  'Count'
])
param timeAggregation string = 'Average'

@description('Comparison operator.')
@allowed([
  'GreaterThan'
  'GreaterThanOrEqual'
  'LessThan'
  'LessThanOrEqual'
  'Equals'
  'NotEquals'
])
param operator string = 'GreaterThan'

@description('Alert threshold value.')
param threshold int

@description('Alert severity from 0 (critical) to 4 (verbose).')
@minValue(0)
@maxValue(4)
param severity int = 2

@description('Evaluation frequency in ISO8601 duration format, e.g. PT1M.')
param evaluationFrequency string = 'PT1M'

@description('Window size in ISO8601 duration format, e.g. PT5M.')
param windowSize string = 'PT5M'

@description('Resource ID of the Action Group to invoke when alert fires.')
param actionGroupId string

@description('Enable or disable auto-mitigation.')
param autoMitigate bool = true

@description('Enable or disable the metric alert.')
param enabled bool = true

@description('Tags to apply to the metric alert rule.')
param tags object = {}

resource metricAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: metricAlertName
  location: location
  tags: tags
  properties: {
    description: 'Metric alert routed to action group and Logic App.'
    severity: severity
    enabled: enabled
    targetResourceType: targetResourceType
    targetResourceRegion: targetResourceRegion
    scopes: [
      targetScopeResourceId
    ]
    evaluationFrequency: evaluationFrequency
    windowSize: windowSize
    autoMitigate: autoMitigate
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'alert-condition-1'
          criterionType: 'StaticThresholdCriterion'
          metricName: metricName
          metricNamespace: metricNamespace
          operator: operator
          threshold: threshold
          timeAggregation: timeAggregation
        }
      ]
    }
    actions: [
      {
        actionGroupId: actionGroupId
      }
    ]
  }
}

output metricAlertId string = metricAlert.id
output metricAlertNameOut string = metricAlert.name
