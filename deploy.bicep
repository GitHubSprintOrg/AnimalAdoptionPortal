param location string = 'australiaeast'
param tenantGuid string
param appServicePlanName string
param keyVaultName string
param webAppName string
param resourceGroupServicePrincipalManagedApplicationObjectId string

resource appServicePlan 'Microsoft.Web/serverfarms@2021-02-01' = {
  name: appServicePlanName
  location: location
  sku: {
    tier: 'Standard'
    name: 'S1'
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

resource webApp 'Microsoft.Web/sites@2021-02-01' = {
  name: webAppName
  location: location
  kind: 'app,linux'
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      appSettings: []
      linuxFxVersion: 'DOTNETCORE|3.1'
      alwaysOn: true
    }
  }
}

var yourAadUserObjectId = '26984cad-f6c9-4cf9-b47c-8ff3a355e896'
// var servicePrincipalObjectId = '47363b4f-e8bc-4d90-9554-b0d87f4e3cf1'

var userObjectIdsToGrantAccessPoliciesThatAllowFullControlForAllEntitiesInKeyVault = [
  yourAadUserObjectId
  // servicePrincipalObjectId
]

var identitiesThatRequiredSecretAccessPolicies = [
  resourceGroupServicePrincipalManagedApplicationObjectId
]

var fullControlForAllEntitiesInKeyVaultAccessPolicies = [for userObjectId in userObjectIdsToGrantAccessPoliciesThatAllowFullControlForAllEntitiesInKeyVault: {
  tenantId: tenantGuid
  objectId: userObjectId
  permissions: {
    keys: [
      'get'
      'list'
      'update'
      'create'
      'import'
      'delete'
      'recover'
      'backup'
      'restore'
    ]
    secrets: [
      'get'
      'list'
      'set'
      'delete'
      'recover'
      'backup'
      'restore'
    ]
    certificates: [
      'get'
      'list'
      'update'
      'create'
      'import'
      'delete'
      'recover'
      'backup'
      'restore'
      'managecontacts'
      'manageissuers'
      'getissuers'
      'listissuers'
      'setissuers'
      'deleteissuers'
    ]
  }
}]

var accessForSecretsInKeyVaultAccessPolicies = [for identityObjectId in identitiesThatRequiredSecretAccessPolicies: {
  tenantId: tenantGuid
  objectId: identityObjectId
  permissions: {
    keys: []
    secrets: [
      'get'
      'list'
      'set'
      'delete'
      'recover'
      'backup'
      'restore'
    ]
    certificates: []
  }
}]

var keyVaultAccessPolicies = union(fullControlForAllEntitiesInKeyVaultAccessPolicies, accessForSecretsInKeyVaultAccessPolicies)

resource keyVault 'Microsoft.KeyVault/vaults@2021-06-01-preview' = {
  name: keyVaultName
  location: location
  properties: {
    sku: {
      name: 'standard'
      family: 'A'
    }
    tenantId: tenantGuid
    softDeleteRetentionInDays: 90
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: false
    enableRbacAuthorization: false
    enableSoftDelete: true
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
      ipRules: []
      virtualNetworkRules: []
    }
    accessPolicies: keyVaultAccessPolicies
  }
}

resource webAppSlot 'Microsoft.Web/sites/slots@2021-02-01' = {
  name: 'dev'
  parent: webApp
  location: location
  properties: {
  }
}
