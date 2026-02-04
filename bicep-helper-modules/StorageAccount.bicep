param location string = resourceGroup().location
param storageAccountName string


// Module for deploying a storage account with specified parameters
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
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
    defaultToOAuthAuthentication: true
    supportsHttpsTrafficOnly: true
    isHnsEnabled: true
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

// Variable defining file shares to be created in the storage account
var fileshares = {
  fileshare1: {
    name: 'fileshare'
    shareQuota: 1024
    enabledProtocols: 'SMB'
    accessTier: 'Cool'
  }
  // Uncomment to add another file share
  // fileshare2: {
  //   name: 'fileshare2'
  //   shareQuota: 1024
  //   enabledProtocols: 'SMB'
  //   accessTier: 'Cool'
  // }
}

// Variable defining containers to be created in the storage account
var containers = {
  container1: {
    name: 'claimcheck'
  }
  // Uncomment to add another container
  // container2: {
  //   name: 'container2'
  // }
}

// Uncomment to deploy the file share using the defined parameters
// module fileShare1 '../../../../bicep-registry-modules/avm/res/storage/storage-account/file-service/share/main.bicep' = {
//   name: 'FileShare1-${dateTime}'
//   params: {
//     name: fileshares.fileshare1.name
//     shareQuota: fileshares.fileshare1.shareQuota
//     enabledProtocols: fileshares.fileshare1.enabledProtocols
//     accessTier: fileshares.fileshare1.accessTier
//     storageAccountName: storageAccount.outputs.name
//   }
// }

// Uncomment to deploy the container using the defined parameters
// module container1 '../../../../bicep-registry-modules/avm/res/storage/storage-account/blob-service/container/main.bicep' = {
//   name: 'Container1-${dateTime}'
//   params: {
//     name: containers.container1.name
//     storageAccountName: storageAccount.outputs.name
//   }
// }

// Output the name of the storage account
output name string = storageAccount.name

// Output the resource ID of the storage account
output resourceId string = storageAccount.id
