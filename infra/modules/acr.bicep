param location string
param tags object
param acrName string

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: acrName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    adminUserEnabled: false
  }
}

output name string = acr.name
output loginServer string = acr.properties.loginServer
output resourceId string = acr.id
