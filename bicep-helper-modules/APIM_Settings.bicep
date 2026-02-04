@description('Optional. Used for naming the deployment of each resource. No need to pass this parameter.')
param dateTime string = utcNow()
param apimName string
param apimResourceId string
param product string
param keyVaultName string

module apimProduct '../bicep-registry-modules/avm/res/api-management/service/product/main.bicep' ={
  name: 'apimProduct-${product}-${dateTime}'
  params: {
    name: product
    displayName: product
    apiManagementServiceName: apimName
    state: 'published'
    subscriptionRequired: true
    approvalRequired: false
  }
}

module apimSubscription '../bicep-registry-modules/avm/res/api-management/service/subscription/main.bicep' = {
  name: 'apimSubscription-${product}-subscription-${dateTime}'
  params: {
    name: '${product}-subscription'
    displayName: '${product} Subscription'
    apiManagementServiceName: apimName
    allowTracing: true
    scope: apimProduct.outputs.resourceId
  }
}

module keyVaultSecret '../bicep-registry-modules/avm/res/key-vault/vault/secret/main.bicep' = {
  name: 'keyVaultSecret-${product}-${dateTime}'
  dependsOn: [
    apimSubscription
  ]
  params: {
    name: 'APIM-${product}-subscription-key'
    keyVaultName: keyVaultName
    value: listSecrets('${apimResourceId}/subscriptions/${product}-subscription', '2021-08-01').primaryKey
  }
}
