targetScope = 'subscription'

param location string = 'swedencentral' 
param projectPrefix string = 'ai-gateway'

resource rg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: 'rg-${projectPrefix}-prod'
  location: location
}

output rgName string = rg.name
