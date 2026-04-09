param location string
param aiServiceName string

resource aiService 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: aiServiceName
  location: location
  kind: 'OpenAI'
  sku: {
    name: 'S0'
  }
  properties: {
    customSubDomainName: aiServiceName
    networkAcls: {
      defaultAction: 'Allow'
    }
  }
}

resource gptModel 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = {
  parent: aiService
  name: 'gpt-4o'
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-4o'
      version: '2024-11-20' 
    }
  }
  sku: {
    name: 'Standard'
    capacity: 10
  }
}

