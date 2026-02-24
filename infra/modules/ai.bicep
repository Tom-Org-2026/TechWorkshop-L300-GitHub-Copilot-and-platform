param location string
param tags object
param aiServicesName string

@description('GPT-4 family model name to deploy.')
param gpt4ModelName string = 'gpt-4o'

@description('GPT-4 model version. Update if a newer version is available in westus3.')
param gpt4ModelVersion string = '2024-05-13'

@description('Phi family model name to deploy.')
param phiModelName string = 'Phi-3-mini-4k-instruct'

@description('Phi model version. Update if a newer version is available in westus3.')
param phiModelVersion string = '14'

resource aiServices 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: aiServicesName
  location: location
  tags: tags
  kind: 'OpenAI'
  sku: {
    name: 'S0'
  }
  properties: {
    customSubDomainName: aiServicesName
    publicNetworkAccess: 'Enabled'
  }
}

resource gpt4Deployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = {
  parent: aiServices
  name: 'gpt-4'
  sku: {
    name: 'Standard'
    capacity: 10
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: gpt4ModelName
      version: gpt4ModelVersion
    }
  }
}

resource phiDeployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = {
  parent: aiServices
  name: 'phi'
  sku: {
    name: 'Standard'
    capacity: 1
  }
  properties: {
    model: {
      format: 'Microsoft'
      name: phiModelName
      version: phiModelVersion
    }
  }
}

output endpoint string = aiServices.properties.endpoint
output gpt4DeploymentName string = gpt4Deployment.name
output phiDeploymentName string = phiDeployment.name
