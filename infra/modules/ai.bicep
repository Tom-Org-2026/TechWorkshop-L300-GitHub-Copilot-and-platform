param location string
param tags object
param aiServicesName string

@description('GPT-4 family model name to deploy.')
param gpt4ModelName string = 'gpt-4o'

@description('GPT-4 model version. Update if a newer version is available in westus3.')
param gpt4ModelVersion string = '2024-05-13'

@description('Phi family model name to deploy. Must be available under AIServices GlobalStandard in westus3.')
param phiModelName string = 'Phi-4-mini-instruct'

@description('Phi model version. Latest stable GlobalStandard version in westus3.')
param phiModelVersion string = '1'

resource aiServices 'Microsoft.CognitiveServices/accounts@2024-10-01' = {
  name: aiServicesName
  location: location
  tags: tags
  kind: 'AIServices'
  sku: {
    name: 'S0'
  }
  properties: {
    customSubDomainName: aiServicesName
    publicNetworkAccess: 'Enabled'
  }
}

resource gpt4Deployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = {
  parent: aiServices
  name: 'gpt-4'
  sku: {
    name: 'GlobalStandard'
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

resource phiDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = {
  parent: aiServices
  name: 'phi'
  dependsOn: [gpt4Deployment]
  sku: {
    name: 'GlobalStandard'
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
