param location string
param tags object
param environmentName string
param appServicePlanName string
param webAppName string
param acrLoginServer string
param appInsightsConnectionString string
param appInsightsInstrumentationKey string
param aiEndpoint string
param gpt4DeploymentName string
param phiDeploymentName string

var webServiceTag = union(tags, { 'azd-service-name': 'web' })

resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: appServicePlanName
  location: location
  tags: tags
  kind: 'linux'
  sku: {
    name: 'B1'
    tier: 'Basic'
  }
  properties: {
    reserved: true
  }
}

resource webApp 'Microsoft.Web/sites@2022-09-01' = {
  name: webAppName
  location: location
  tags: webServiceTag
  kind: 'app,linux,container'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOCKER|${acrLoginServer}/zavastorefront:latest'
      acrUseManagedIdentityCreds: true
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsightsInstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'AZURE_AI_ENDPOINT'
          value: aiEndpoint
        }
        {
          name: 'AZURE_GPT4_DEPLOYMENT_NAME'
          value: gpt4DeploymentName
        }
        {
          name: 'AZURE_PHI_DEPLOYMENT_NAME'
          value: phiDeploymentName
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${acrLoginServer}'
        }
        {
          name: 'ASPNETCORE_ENVIRONMENT'
          value: environmentName
        }
      ]
    }
  }
}

output webAppName string = webApp.name
output webAppUri string = 'https://${webApp.properties.defaultHostName}'
output identityPrincipalId string = webApp.identity.principalId
