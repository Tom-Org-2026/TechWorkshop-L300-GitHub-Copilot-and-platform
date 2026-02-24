targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the AZD environment.')
param environmentName string

@minLength(1)
@description('Azure region for all resources.')
param location string = 'westus3'

var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = { 'azd-env-name': environmentName }

// Resource Group
resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}

// Monitoring: Log Analytics Workspace + Application Insights
module monitoring 'modules/monitoring.bicep' = {
  name: 'monitoring'
  scope: rg
  params: {
    location: location
    tags: tags
    logAnalyticsName: '${abbrs.operationalInsightsWorkspaces}${resourceToken}'
    appInsightsName: '${abbrs.insightsComponents}${resourceToken}'
  }
}

// Azure Container Registry
module acr 'modules/acr.bicep' = {
  name: 'acr'
  scope: rg
  params: {
    location: location
    tags: tags
    acrName: '${abbrs.containerRegistryRegistries}${resourceToken}'
  }
}

// Azure OpenAI (Microsoft Foundry-compatible) with GPT-4 and Phi model deployments
module ai 'modules/ai.bicep' = {
  name: 'ai'
  scope: rg
  params: {
    location: location
    tags: tags
    aiServicesName: '${abbrs.cognitiveServicesAccounts}${resourceToken}'
  }
}

// Linux App Service Plan + containerized Web App
module appService 'modules/appservice.bicep' = {
  name: 'appservice'
  scope: rg
  params: {
    location: location
    tags: tags
    environmentName: environmentName
    appServicePlanName: '${abbrs.webServerFarms}${resourceToken}'
    webAppName: '${abbrs.webSitesAppService}${resourceToken}'
    acrLoginServer: acr.outputs.loginServer
    appInsightsConnectionString: monitoring.outputs.appInsightsConnectionString
    appInsightsInstrumentationKey: monitoring.outputs.appInsightsInstrumentationKey
    aiEndpoint: ai.outputs.endpoint
    gpt4DeploymentName: ai.outputs.gpt4DeploymentName
    phiDeploymentName: ai.outputs.phiDeploymentName
  }
}

// AcrPull role assignment: Web App managed identity -> ACR
module acrPullRoleAssignment 'modules/roleassignment.bicep' = {
  name: 'acrPullRoleAssignment'
  scope: rg
  params: {
    acrName: acr.outputs.name
    principalId: appService.outputs.identityPrincipalId
  }
}

// Outputs consumed by AZD and downstream tooling
output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
output AZURE_RESOURCE_GROUP string = rg.name
output AZURE_CONTAINER_REGISTRY_NAME string = acr.outputs.name
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = acr.outputs.loginServer
output SERVICE_WEB_URI string = appService.outputs.webAppUri
output AZURE_AI_ENDPOINT string = ai.outputs.endpoint
output GPT4_DEPLOYMENT_NAME string = ai.outputs.gpt4DeploymentName
output PHI_DEPLOYMENT_NAME string = ai.outputs.phiDeploymentName
