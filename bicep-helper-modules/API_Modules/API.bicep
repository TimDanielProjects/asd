param dateTime string = utcNow()
param environmentSuffix string
@description('Required. API settings.')
param api {
  description: string
  displayName: string
  name: string
  apiUrlSuffix: string
  productName: string
  allOperationsPolicyXml: string?
  operations: operationsType
  namedValues: namedValuesType
  webServiceUrl: string
  apiVersion: string
  backends: array?
  // openApiContent: string
  // version: string
}
@description('Required. API Management settings')
param apiManagement {
  name: string
  resourceGroupName: string
}

module apiV1 '../../bicep-registry-modules/avm/res/api-management/service/api/main.bicep' = {
  name: 'API-${dateTime}'
  scope: resourceGroup(apiManagement.resourceGroupName)
  dependsOn: [
    backendResource
    namedValuesModule 
  ]
  params: {
    apiManagementServiceName: apiManagement.name
    description: api.description
    displayName: api.displayName
    name: api.name
    path: api.apiUrlSuffix
    serviceUrl: api.webServiceUrl
    apiVersionSetName:  apiVersionSet.outputs.name
    apiVersion: api.apiVersion
    subscriptionRequired: environmentSuffix == 'dev' ? false : true
    //policy for all operations (not required)
    policies: contains(api, 'allOperationsPolicyXml') && !empty(api.?allOperationsPolicyXml) ? [
      {
        format: 'rawxml'
        value: api.allOperationsPolicyXml!
      }
    ] : []
  }
}
module apiVersionSet '../../bicep-registry-modules/avm/res/api-management/service/api-version-set/main.bicep' = {
  name: 'ApiVersionSet-${api.apiVersion}-${dateTime}'
  scope: resourceGroup(apiManagement.resourceGroupName)
  params: {
    apiManagementServiceName: apiManagement.name
    name: api.name
      displayName: api.displayName
      versioningScheme: 'Segment'
  }
}
module product '../../bicep-registry-modules/avm/res/api-management/service/product/api/main.bicep' = {
  name: 'Product-${dateTime}'
  dependsOn: [
    apiV1
  ]
  params: {
    name: api.name
    apiManagementServiceName: apiManagement.name
    productName: api.productName
  }
}
module apiOperations 'API_Operations.bicep' = [
  for (operation, index) in (api.?operations  ?? []): {
  name: 'API-Operations-${dateTime}-${index}'
  dependsOn: [
    product
  ]
  scope:(resourceGroup(apiManagement.resourceGroupName))
  params:{
    api: {
      name: api.name
    }
    apiManagement: {
      name: apiManagement.name
    }
    operation: operation
  }
}]

module backendResource '../../bicep-registry-modules/avm/res/api-management/service/backend/main.bicep' = [
  for (backend, index) in (api.?backends ?? []): {
    name: 'Backend-${dateTime}-${index}'
    scope: resourceGroup(apiManagement.resourceGroupName)
    params: {
      apiManagementServiceName: apiManagement.name
      name: backend.name
      url: backend.url
      // resourceId: '${environment().resourceManager}${substring(backend.resourceId, 1)}' // Remove the first / from the resourceId, otherwise the path will not be correct.
      tls: {
        validateCertificateChain: true
        validateCertificateName: true
      }
    }
  }
]


module namedValuesModule '../../bicep-registry-modules/avm/res/api-management/service/named-value/main.bicep'= [
  for (namedValue, index) in (api.?namedValues  ?? []):{
  name: 'API-NamedValue-${dateTime}-${index}'
  scope: resourceGroup(apiManagement.resourceGroupName)
  params: {
    apiManagementServiceName: apiManagement.name
    displayName: namedValue.displayName
    name: namedValue.name
    secret: true
    value: namedValue.value
  }
}]


type operationsType ={
  name: string
  description: string?
  operationPath: string
  method: string
  policyXml: string?
  queryParameters: array?
  headerParameters: array?
  responseParameters: array?
}[]?
type namedValuesType ={
  name: string
  displayName: string
  value: string
}[]?
type backendType = {
  name: string
  url: string
  resourceId: string?
}[]?
