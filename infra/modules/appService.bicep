@description('Name of the App Service')
param name string

@description('Location for the resource')
param location string = resourceGroup().location

@description('Tags to apply to the resource')
param tags object = {}

@description('App Service Plan resource ID')
param appServicePlanId string

@description('Application Insights connection string')
param applicationInsightsConnectionString string

@description('Container Registry name')
param containerRegistryName string

@description('Key Vault name')
param keyVaultName string

resource appService 'Microsoft.Web/sites@2023-01-01' = {
  name: name
  location: location
  tags: union(tags, { 'azd-service-name': 'web' })
  kind: 'app,linux,container'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlanId
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOCKER|mcr.microsoft.com/appsvc/staticsite:latest'
      alwaysOn: false
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      http20Enabled: true
      acrUseManagedIdentityCreds: true
      appSettings: [
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: applicationInsightsConnectionString
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'XDT_MicrosoftApplicationInsights_Mode'
          value: 'recommended'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${containerRegistryName}.azurecr.io'
        }
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
      ]
    }
  }
}

output id string = appService.id
output name string = appService.name
output uri string = 'https://${appService.properties.defaultHostName}'
output identityPrincipalId string = appService.identity.principalId
