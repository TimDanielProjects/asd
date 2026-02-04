type roleAssignmentType = {
  @description('Required. The role to assign. You can provide either the display name of the role definition, the role definition GUID, or its fully qualified ID in the following format: \'/providers/Microsoft.Authorization/roleDefinitions/c2f4ef07-c644-48eb-af81-4b1b4947fb11\'.')
  roleDefinitionId: string

  @description('Required. The principal ID of the principal (user/group/identity) to assign the role to.')
  principalId: string
}[]?
param RBACSettings {
  serviceBusNamespaceSettings: {
    namespaceName: string
    roleAssignments: roleAssignmentType
  }?
  apimSettings: {
    name: string
    roleAssignments: roleAssignmentType
  }?
  keyVaultSettings: {
    keyVaultName: string
    roleAssignments: roleAssignmentType
  }?
  storageAccountSettings: {
    storageAccountName: string
    roleAssignments: roleAssignmentType
  }?
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-05-01' existing = if (RBACSettings.?storageAccountSettings != null) {
  name: RBACSettings.storageAccountSettings!.storageAccountName
}
resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2022-10-01-preview' existing = if (RBACSettings.?serviceBusNamespaceSettings != null) {
  name: RBACSettings.serviceBusNamespaceSettings!.namespaceName
}
resource apim 'Microsoft.ApiManagement/service@2023-05-01-preview' existing = if (RBACSettings.?apimSettings != null) {
  name: RBACSettings.apimSettings!.name
}
resource keyVault 'Microsoft.KeyVault/vaults@2021-10-01' existing = if (RBACSettings.?keyVaultSettings != null) {
  name: RBACSettings.keyVaultSettings!.keyVaultName
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
for (roleAssignment, index) in (RBACSettings.?storageAccountSettings.?roleAssignments ?? []): if (RBACSettings.?storageAccountSettings != null) {
  name: guid(storageAccount.id, roleAssignment.roleDefinitionId, roleAssignment.principalId)
  properties: {
    principalId: roleAssignment.principalId
    roleDefinitionId: roleAssignment.roleDefinitionId
  }
  scope: storageAccount
}]

resource serviceBusNamespace_roleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for (roleAssignment, index) in (RBACSettings.?serviceBusNamespaceSettings.?roleAssignments ?? []): if (RBACSettings.?serviceBusNamespaceSettings != null) {
    name: guid(serviceBusNamespace.id, roleAssignment.roleDefinitionId, roleAssignment.principalId)
    properties: {
      principalId: roleAssignment.principalId
      roleDefinitionId: roleAssignment.roleDefinitionId
    }
    scope: serviceBusNamespace
  }]
  
  resource apim_roleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for (roleAssignment, index) in (RBACSettings.?apimSettings.?roleAssignments ?? []): if (RBACSettings.?apimSettings != null) {
    name: guid(apim.id, roleAssignment.roleDefinitionId, roleAssignment.principalId)
    properties: {
      principalId: roleAssignment.principalId
      roleDefinitionId: roleAssignment.roleDefinitionId
    }
    scope: apim
  }]
  resource kv_roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for (roleAssignment, index) in (RBACSettings.?keyVaultSettings.?roleAssignments ?? []): if (RBACSettings.?keyVaultSettings != null) {
    name: guid(keyVault.id, roleAssignment.roleDefinitionId, roleAssignment.principalId)
    properties: {
      principalId: roleAssignment.principalId
      roleDefinitionId: roleAssignment.roleDefinitionId
    }
    scope: keyVault
  }]
  