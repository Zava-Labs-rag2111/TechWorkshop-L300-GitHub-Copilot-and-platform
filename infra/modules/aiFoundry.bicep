@description('Name of the AI Hub')
param hubName string

@description('Name of the AI Project')
param projectName string

@description('Location for the resources')
param location string = resourceGroup().location

@description('Tags to apply to the resources')
param tags object = {}

@description('Storage Account resource ID')
param storageAccountId string

@description('Key Vault resource ID')
param keyVaultId string

@description('Application Insights resource ID')
param applicationInsightsId string

// AI Hub (Workspace)
resource aiHub 'Microsoft.MachineLearningServices/workspaces@2024-04-01' = {
  name: hubName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
  kind: 'Hub'
  properties: {
    friendlyName: hubName
    storageAccount: storageAccountId
    keyVault: keyVaultId
    applicationInsights: applicationInsightsId
    publicNetworkAccess: 'Enabled'
    v1LegacyMode: false
  }
}

// AI Project
resource aiProject 'Microsoft.MachineLearningServices/workspaces@2024-04-01' = {
  name: projectName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
  kind: 'Project'
  properties: {
    friendlyName: projectName
    hubResourceId: aiHub.id
    publicNetworkAccess: 'Enabled'
  }
}

output hubId string = aiHub.id
output hubName string = aiHub.name
output projectId string = aiProject.id
output projectName string = aiProject.name
output hubPrincipalId string = aiHub.identity.principalId
output projectPrincipalId string = aiProject.identity.principalId
