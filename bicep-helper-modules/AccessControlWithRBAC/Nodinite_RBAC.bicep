type roleAssignmentType = {
  @description('Required. The role to assign. You can provide either the display name of the role definition, the role definition GUID, or its fully qualified ID in the following format: \'/providers/Microsoft.Authorization/roleDefinitions/c2f4ef07-c644-48eb-af81-4b1b4947fb11\'.')
  roleDefinitionId: string

  @description('Required. The principal ID of the principal (user/group/identity) to assign the role to.')
  principalId: string

  @description('Optional. The principal type of the assigned principal ID. Required to handle replication delays for managed identities.')
  principalType: ('ServicePrincipal' | 'Group' | 'User')?
}[]?
param RBACSettings {
  NodiniteStorageAccountSettings: {
    storageAccountName: string
    roleAssignments: roleAssignmentType
  }
}

resource NodiniteStorageAccount 'Microsoft.Storage/storageAccounts@2022-05-01' existing = {
  name: RBACSettings.NodiniteStorageAccountSettings.storageAccountName
}

resource NodiniteStorageAccount_roleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for (roleAssignment, index) in (RBACSettings.NodiniteStorageAccountSettings.?roleAssignments ?? []): {
    name: guid(NodiniteStorageAccount.id, roleAssignment.roleDefinitionId, roleAssignment.principalId)
    properties: {
      principalId: roleAssignment.principalId
      roleDefinitionId: roleAssignment.roleDefinitionId
      principalType: roleAssignment.?principalType
    }
    scope: NodiniteStorageAccount
  }]
