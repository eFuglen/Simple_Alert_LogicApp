@description('Action Group name.')
param actionGroupName string

@description('Short name visible in notifications (max 12 chars).')
@maxLength(12)
param groupShortName string

@description('Azure region for Action Group. Global is recommended for monitor action groups.')
param location string = 'SwedenCentral'

@description('Logic App receiver name in the Action Group.')
param logicAppReceiverName string = 'MyTrigger'

@description('Resource ID of the Logic App workflow to invoke.')
param logicAppResourceId string

@description('Callback URL for the Logic App request trigger.')
@secure()
param logicAppCallbackUrl string

@description('Enable Common Alert Schema payload.')
param useCommonAlertSchema bool = true

@description('Tags to apply to the Action Group.')
param tags object = {}

resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: actionGroupName
  location: location
  tags: tags
  properties: {
    enabled: true
    groupShortName: groupShortName
    logicAppReceivers: [
      {
        name: logicAppReceiverName
        resourceId: logicAppResourceId
        callbackUrl: logicAppCallbackUrl
        useCommonAlertSchema: useCommonAlertSchema
      }
    ]
  }
}

output actionGroupId string = actionGroup.id
output actionGroupNameOut string = actionGroup.name
