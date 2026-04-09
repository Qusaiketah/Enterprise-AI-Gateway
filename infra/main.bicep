targetScope = 'subscription'

param location string = 'swedencentral'
param projectPrefix string = 'ai-gateway'

var uniqueId = uniqueString(subscription().subscriptionId, projectPrefix)
var rgName = 'rg-${projectPrefix}-prod'

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: rgName
  location: location
}

resource languageAccount 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = {
  name: 'lang-ai-gateway-smart' 
  scope: resourceGroup(rg.name)
}

module apim 'apim.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'apimDeployment'
  params: {
    location: location
    apimName: 'apim-${uniqueId}'
  }
}

module api 'api.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'apiDeployment'
  params: {
    apimName: 'apim-${uniqueId}'
    // FIX: Lägg till /openai i slutet här (utan sista snedstreck)
    openAiEndpoint: 'https://oai-${uniqueId}.openai.azure.com/openai' 
    languageEndpoint: 'https://lang-ai-gateway-smart.cognitiveservices.azure.com'
    languageKey: languageAccount.listKeys().key1
  }
  dependsOn: [ apim ]
}
