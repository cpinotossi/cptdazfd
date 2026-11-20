param name string
param location string
param lawId string
@description('Disabled = only reachable through the private endpoint')
param publicNetworkAccess 'Enabled' | 'Disabled'
param allowAnonymousBlobAccess bool = false
@description('Adds the policy exclusion tag (SecurityControl=Ignore) so Modify policies do not revert the settings below')
param policyExempt bool = false
param containers array = []
param peSubnetId string = ''
param blobDnsZoneId string = ''
param privateEndpointName string = ''
param dataContributorPrincipalIds array = []
param userObjectId string

var tags = policyExempt ? { SecurityControl: 'Ignore' } : {}
var blobDataContributor = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
var blobDelegator = 'db58b8e5-c6ad-4a2a-8342-4190687cbf4a'
var createPe = !empty(peSubnetId)

resource sa 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: name
  location: location
  tags: tags
  kind: 'StorageV2'
  sku: { name: 'Standard_LRS' }
  properties: {
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    allowSharedKeyAccess: false
    defaultToOAuthAuthentication: true
    allowBlobPublicAccess: allowAnonymousBlobAccess
    publicNetworkAccess: publicNetworkAccess
    networkAcls: {
      defaultAction: publicNetworkAccess == 'Disabled' ? 'Deny' : 'Allow'
      bypass: 'AzureServices'
    }
  }
}

resource blob 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: sa
  name: 'default'
}

resource cont 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = [for c in containers: {
  parent: blob
  name: c.name
  properties: {
    publicAccess: c.?publicAccess ?? 'None'
  }
}]

resource pe 'Microsoft.Network/privateEndpoints@2024-05-01' = if (createPe) {
  name: privateEndpointName
  location: location
  properties: {
    subnet: { id: peSubnetId }
    privateLinkServiceConnections: [
      {
        name: 'blob'
        properties: {
          privateLinkServiceId: sa.id
          groupIds: [ 'blob' ]
        }
      }
    ]
  }
}

resource peDns 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = if (createPe) {
  parent: pe
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'blob'
        properties: { privateDnsZoneId: blobDnsZoneId }
      }
    ]
  }
}

resource raUserData 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: sa
  name: guid(sa.id, userObjectId, blobDataContributor)
  properties: {
    principalId: userObjectId
    principalType: 'User'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', blobDataContributor)
  }
}

resource raUserDelegator 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: sa
  name: guid(sa.id, userObjectId, blobDelegator)
  properties: {
    principalId: userObjectId
    principalType: 'User'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', blobDelegator)
  }
}

resource raPrincipalsData 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for p in dataContributorPrincipalIds: {
  scope: sa
  name: guid(sa.id, p, blobDataContributor)
  properties: {
    principalId: p
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', blobDataContributor)
  }
}]

resource raPrincipalsDelegator 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for p in dataContributorPrincipalIds: {
  scope: sa
  name: guid(sa.id, p, blobDelegator)
  properties: {
    principalId: p
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', blobDelegator)
  }
}]

resource diagAccount 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: sa
  name: 'to-law'
  properties: {
    workspaceId: lawId
    metrics: [ { category: 'Transaction', enabled: true } ]
  }
}

resource diagBlob 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: blob
  name: 'to-law'
  properties: {
    workspaceId: lawId
    logs: [ { categoryGroup: 'allLogs', enabled: true } ]
    metrics: [ { category: 'Transaction', enabled: true } ]
  }
}

resource diagPe 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (createPe) {
  scope: pe
  name: 'to-law'
  properties: {
    workspaceId: lawId
    metrics: [ { category: 'AllMetrics', enabled: true } ]
  }
}

output id string = sa.id
output name string = sa.name
output blobHost string = '${sa.name}.blob.${environment().suffixes.storage}'
