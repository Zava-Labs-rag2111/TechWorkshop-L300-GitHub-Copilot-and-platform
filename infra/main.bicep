targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment (dev, staging, prod)')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

@description('Unique identifier for resource naming')
param resourceToken string = toLower(uniqueString(subscription().id, environmentName, location))

@description('Id of the user or app to assign application roles')
param principalId string = ''

// Tags to apply to all resources
var tags = {
  'azd-env-name': environmentName
  'app-name': 'zavastorefront'
}

// Resource group for all resources
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-${environmentName}-${resourceToken}'
  location: location
  tags: tags
}

// Log Analytics workspace for Application Insights
module logAnalytics './modules/logAnalytics.bicep' = {
  name: 'logAnalytics'
  scope: rg
  params: {
    name: 'log-${resourceToken}'
    location: location
    tags: tags
  }
}

// Application Insights for monitoring
module applicationInsights './modules/applicationInsights.bicep' = {
  name: 'applicationInsights'
  scope: rg
  params: {
    name: 'appi-${resourceToken}'
    location: location
    tags: tags
    logAnalyticsWorkspaceId: logAnalytics.outputs.id
  }
}

// Azure Container Registry
module containerRegistry './modules/containerRegistry.bicep' = {
  name: 'containerRegistry'
  scope: rg
  params: {
    name: 'cr${resourceToken}'
    location: location
    tags: tags
  }
}

// Storage Account (required for AI Foundry)
module storage './modules/storage.bicep' = {
  name: 'storage'
  scope: rg
  params: {
    name: 'st${resourceToken}'
    location: location
    tags: tags
  }
}

// Azure Key Vault
module keyVault './modules/keyVault.bicep' = {
  name: 'keyVault'
  scope: rg
  params: {
    name: 'kv-${resourceToken}'
    location: location
    tags: tags
    principalId: principalId
  }
}

// Microsoft Foundry (Azure AI Foundry)
module aiFoundry './modules/aiFoundry.bicep' = {
  name: 'aiFoundry'
  scope: rg
  params: {
    hubName: 'mlw-hub-${resourceToken}'
    projectName: 'mlw-proj-${resourceToken}'
    location: location
    tags: tags
    storageAccountId: storage.outputs.id
    keyVaultId: keyVault.outputs.id
    applicationInsightsId: applicationInsights.outputs.id
  }
}

// App Service Plan
module appServicePlan './modules/appServicePlan.bicep' = {
  name: 'appServicePlan'
  scope: rg
  params: {
    name: 'plan-${resourceToken}'
    location: location
    tags: tags
    sku: 'F1'
    kind: 'linux'
  }
}

// App Service (Web App)
module appService './modules/appService.bicep' = {
  name: 'appService'
  scope: rg
  params: {
    name: 'app-${resourceToken}'
    location: location
    tags: tags
    appServicePlanId: appServicePlan.outputs.id
    applicationInsightsConnectionString: applicationInsights.outputs.connectionString
    containerRegistryName: containerRegistry.outputs.name
    keyVaultName: keyVault.outputs.name
  }
}

// Role assignment: App Service managed identity -> ACR Pull
module acrPullRole './modules/roleAssignments.bicep' = {
  name: 'acrPullRole'
  scope: rg
  params: {
    principalId: appService.outputs.identityPrincipalId
    roleDefinitionId: '7f951dda-4ed3-4680-a7ca-43fe172d538d' // AcrPull role
    principalType: 'ServicePrincipal'
  }
}

// Role assignment: App Service managed identity -> Key Vault Secrets User
module keyVaultSecretsRole './modules/roleAssignments.bicep' = {
  name: 'keyVaultSecretsRole'
  scope: rg
  params: {
    principalId: appService.outputs.identityPrincipalId
    roleDefinitionId: '4633458b-17de-408a-b874-0445c86b69e6' // Key Vault Secrets User
    principalType: 'ServicePrincipal'
  }
}

// Outputs
output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
output AZURE_RESOURCE_GROUP string = rg.name

output AZURE_CONTAINER_REGISTRY_ENDPOINT string = containerRegistry.outputs.loginServer
output AZURE_CONTAINER_REGISTRY_NAME string = containerRegistry.outputs.name

output SERVICE_WEB_IDENTITY_PRINCIPAL_ID string = appService.outputs.identityPrincipalId
output SERVICE_WEB_NAME string = appService.outputs.name
output SERVICE_WEB_URI string = appService.outputs.uri

output APPLICATIONINSIGHTS_CONNECTION_STRING string = applicationInsights.outputs.connectionString
output AZURE_KEY_VAULT_ENDPOINT string = keyVault.outputs.endpoint
output AZURE_KEY_VAULT_NAME string = keyVault.outputs.name
