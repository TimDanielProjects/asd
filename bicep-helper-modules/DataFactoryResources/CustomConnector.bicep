param connectorName string
param swaggerUrl string

resource connector 'Microsoft.Web/customApis@2018-07-01-preview' = {
  name: connectorName
  properties: {
    displayName: connectorName
    swagger: {
      url: swaggerUrl
    }
  }
}