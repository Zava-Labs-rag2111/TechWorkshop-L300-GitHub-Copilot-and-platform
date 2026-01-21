@description('Name of the App Service Plan')
param name string

@description('Location for the resource')
param location string = resourceGroup().location

@description('Tags to apply to the resource')
param tags object = {}

@description('App Service Plan SKU')
@allowed([
  'F1'
  'B1'
  'B2'
  'B3'
  'S1'
  'S2'
  'S3'
  'P1v2'
  'P2v2'
  'P3v2'
])
param sku string = 'F1'

@description('App Service Plan kind')
@allowed([
  'linux'
  'windows'
])
param kind string = 'linux'

resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: sku
  }
  kind: kind
  properties: {
    reserved: kind == 'linux'
  }
}

output id string = appServicePlan.id
output name string = appServicePlan.name
