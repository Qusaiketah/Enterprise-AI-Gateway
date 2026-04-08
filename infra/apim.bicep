param location string
param apimName string
param publisherEmail string = 'mooom.0012@hotmail.com' 
param publisherName string = 'Qusai AI Gateway'

resource apim 'Microsoft.ApiManagement/service@2023-05-01-preview' = {
  name: apimName
  location: location
  sku: {
    name: 'Consumption'
    capacity: 0
  }
  properties: {
    publisherEmail: publisherEmail
    publisherName: publisherName
  }
  identity: {
    type: 'SystemAssigned' 
  }
}

output apimName string = apim.name
output apimIdentityPrincipalId string = apim.identity.principalId
