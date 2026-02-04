param dataFactoryName string

resource pipelines 'Microsoft.DataFactory/factories/pipelines@2018-06-01' = {
  name: '${dataFactoryName}/integrationRuntimePipelines'
  properties: {
    
  }
}