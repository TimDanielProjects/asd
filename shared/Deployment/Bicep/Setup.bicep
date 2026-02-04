param environmentSuffix string
param regionSuffix string
param organisationSuffix string
param integrationId string

var resourceBaseName = toLower('${organisationSuffix}-int-${integrationId}')
var resourceEnding = toLower('${regionSuffix}-${environmentSuffix}')

//If the keyvault name is longer than 24 characters, it will be truncated to 24 characters
var keyVaultName = '${resourceBaseName}-kv-${resourceEnding}'
var fixedKeyVaultName = '${resourceBaseName}-kv-${toLower(environmentSuffix)}'

output storageAccountName string = 'st${uniqueString(organisationSuffix,integrationId,environmentSuffix)}'
output keyVaultName string = length(keyVaultName) > 24 ? fixedKeyVaultName : keyVaultName
output subscriptionId string = subscription().subscriptionId
