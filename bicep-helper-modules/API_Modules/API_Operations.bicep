param operation {
  name: string
  description: string?
  operationPath: string
  method: string
  policyXml: string?
  queryParameters: array?
  headerParameters: array?
  responseParameters: array?
}
@description('Required. API Management settings')
param apiManagement {
  name: string
}
param api {
  name:string
}

resource service 'Microsoft.ApiManagement/service@2021-08-01' existing = {
  name: apiManagement.name
  resource existing_api 'apis@2021-08-01' existing = {
    name: api.name
  }
}
resource apiOperations 'Microsoft.ApiManagement/service/apis/operations@2024-06-01-preview' = {
  name: operation.name
  parent: service::existing_api
  properties:{
    displayName: operation.name
    description: operation.?description
    method: operation.method
    urlTemplate: operation.operationPath
    responses:operation.?responseParameters
    request: {
      queryParameters: operation.?queryParameters
      headers: operation.?headerParameters
      representations: contains(['GET', 'HEAD', 'OPTIONS'], operation.method) ? [] : [
      {
        contentType: 'application/json'
        examples: {
        example: {
          description: 'example description' 
          value: any({})
        }
        }
      }
      ]
    }
  }
  resource policy 'policies@2023-05-01-preview' = if (operation.?policyXml  != null) {
    name: 'policy'
    properties: {
      value: operation.?policyXml!
      format: 'rawxml'
    }
  }
}
