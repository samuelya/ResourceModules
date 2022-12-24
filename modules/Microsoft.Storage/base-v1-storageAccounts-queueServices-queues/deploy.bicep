@maxLength(24)
@description('Conditional. The name of the parent Storage Account. Required if the template is used in a standalone deployment.')
param storageAccountName string

@description('Conditional. The name of the parent queue service. Required if the template is used in a standalone deployment.')
param queueServicesName string = 'default'

@description('Required. The name of the storage queue to deploy.')
param name string

@description('Required. A name-value pair that represents queue metadata.')
param metadata object = {}

@description('Optional. Enable telemetry via a Globally Unique Identifier (GUID).')
param enableDefaultTelemetry bool = true

resource defaultTelemetry 'Microsoft.Resources/deployments@2021-04-01' = if (enableDefaultTelemetry) {
  name: 'pid-47ed15a6-730a-4827-bcb4-0fd963ffbd82-${uniqueString(deployment().name)}'
  properties: {
    mode: 'Incremental'
    template: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: '1.0.0.0'
      resources: []
    }
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' existing = {
  name: storageAccountName

  resource queueServices 'queueServices@2021-09-01' existing = {
    name: queueServicesName
  }
}

resource queue 'Microsoft.Storage/storageAccounts/queueServices/queues@2021-09-01' = {
  name: name
  parent: storageAccount::queueServices
  properties: {
    metadata: metadata
  }
}

@description('The name of the deployed queue.')
output name string = queue.name

@description('The resource ID of the deployed queue.')
output resourceId string = queue.id

@description('The resource group of the deployed queue.')
output resourceGroupName string = resourceGroup().name
