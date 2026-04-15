targetScope = 'subscription'

@description('Object ID (principalId) for the managed identity that needs Reader role assignment.')
param principalId string

@description('Role definition ID to assign. Defaults to built-in Reader role.')
param roleDefinitionId string = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'acdd72a7-3385-48ef-bd42-f606fba81ae7')

@description('Principal type for the role assignment.')
@allowed([
  'ServicePrincipal'
  'User'
  'Group'
  'ForeignGroup'
  'Device'
])
param principalType string = 'ServicePrincipal'

resource readerRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, principalId, roleDefinitionId)
  properties: {
    roleDefinitionId: roleDefinitionId
    principalId: principalId
    principalType: principalType
  }
}

output roleAssignmentId string = readerRoleAssignment.id
