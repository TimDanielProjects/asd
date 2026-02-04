param dataFactoryName string
param linkedServiceName string

resource linkedService 'Microsoft.DataFactory/factories/linkedservices@2018-06-01' = {
  name: '${dataFactoryName}/${linkedServiceName}'
  properties: {
    type: '' // Replace with the appropriate type
    typeProperties:{
      
    }
  }
}