param nodiniteLogging_blobName string
param nodiniteLogging_FunctionBlobName string
param nodiniteLogging_EventHub_CheckpointCaptureContainerName string
param location string = resourceGroup().location
param storageAccountParams { name: string}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountParams.name
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: true
    allowSharedKeyAccess: true
    largeFileSharesState: 'Enabled'
    defaultToOAuthAuthentication: false
    supportsHttpsTrafficOnly: true
    networkAcls: {
      resourceAccessRules: []
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: 'Allow'
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
}
resource blobContainer_1 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-05-01' =  {
  name: '${storageAccount.name}/default/${nodiniteLogging_blobName}'
  properties: {}
}
resource blobContainer_2 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-05-01' =  {
  name: '${storageAccount.name}/default/${nodiniteLogging_FunctionBlobName}'
  properties: {}
}
resource blobContainer_3 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-05-01' =  {
  name: '${storageAccount.name}/default/${nodiniteLogging_EventHub_CheckpointCaptureContainerName}'
  properties: {}
}

output name string = storageAccount.name
output resourceId string = storageAccount.id
