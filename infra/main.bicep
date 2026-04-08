targetScope = 'subscription'

param location string = 'swedencentral'
param projectPrefix string = 'ai-gateway'
var uniqueId = uniqueString(subscription().subscriptionId, 'ai-gateway')


resource rg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: 'rg-${projectPrefix}-prod'
  location: location
}


module vault 'keyvault.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'vaultDeployment'
  params: {
    location: location
    kvName: 'kv-${uniqueId}'
  }
}


module openai 'openai.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'openaiDeployment'
  params: {
    location: location
    aiServiceName: 'oai-${uniqueId}'
  }
}

module apim 'apim.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'apimDeployment'
  params: {
    location: location
    apimName: 'apim-${uniqueId}'
  }
}
