targetScope = 'resourceGroup'

param location string = resourceGroup().location
param prefix string = 'cptmtls'
@description('Object id of the human user who gets control- and data-plane access on all resources')
param userObjectId string
param adminSshPublicKey string
@description('Public PEM of the root CA that signs the allowed client certificates')
param caCertPem string
param mediaHost string = 'media.cptdaz.org'
param vmSize string = 'Standard_B2s'
@description('Change to re-run the storage seeding script on the VM')
param seedVersion string = 'v1'

var uniq = take(uniqueString(resourceGroup().id), 5)
var vmIlbIp = '10.0.0.10'
var roles = {
  keyVaultAdministrator: '00482a5a-887f-4fb3-b363-3b7fe8e74483'
  keyVaultSecretsUser: '4633458b-17de-408a-b874-0445c86b69e6'
  vmAdminLogin: '1c0163c0-47e6-4577-8991-ea5c82e286e4'
  logAnalyticsReader: '73c42c96-874c-492b-b04d-ab87d138a893'
  logAnalyticsContributor: '92aaf0da-9dab-42b6-94a3-d43ce8d16293'
}

// ---------------------------------------------------------------- monitoring
resource law 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: 'law-${prefix}'
  location: location
  properties: {
    sku: { name: 'PerGB2018' }
    retentionInDays: 30
  }
}

resource diagLaw 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: law
  name: 'to-law'
  properties: {
    workspaceId: law.id
    logs: [ { categoryGroup: 'allLogs', enabled: true } ]
    metrics: [ { category: 'AllMetrics', enabled: true } ]
  }
}

resource raUserLawContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: law
  name: guid(law.id, userObjectId, roles.logAnalyticsContributor)
  properties: {
    principalId: userObjectId
    principalType: 'User'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roles.logAnalyticsContributor)
  }
}

// ---------------------------------------------------------------- network
resource nsgVm 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: 'nsg-${prefix}-vm'
  location: location
  properties: {
    securityRules: [
      {
        name: 'allow-ssh-from-bastion'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: '10.0.3.0/26'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
        }
      }
      {
        name: 'allow-app-from-pls'
        properties: {
          priority: 110
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: '10.0.1.0/24'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '8080'
        }
      }
      {
        name: 'allow-app-from-lb-probe'
        properties: {
          priority: 120
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: 'AzureLoadBalancer'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '8080'
        }
      }
    ]
  }
}

resource nsgPe 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: 'nsg-${prefix}-pe'
  location: location
}

resource pipNat 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: 'pip-${prefix}-nat'
  location: location
  sku: { name: 'Standard' }
  properties: { publicIPAllocationMethod: 'Static' }
}

resource nat 'Microsoft.Network/natGateways@2024-05-01' = {
  name: 'nat-${prefix}'
  location: location
  sku: { name: 'Standard' }
  properties: {
    idleTimeoutInMinutes: 4
    publicIpAddresses: [ { id: pipNat.id } ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: 'vnet-${prefix}'
  location: location
  properties: {
    addressSpace: { addressPrefixes: [ '10.0.0.0/16' ] }
    subnets: [
      {
        name: 'snet-vm'
        properties: {
          addressPrefix: '10.0.0.0/24'
          networkSecurityGroup: { id: nsgVm.id }
          natGateway: { id: nat.id }
          defaultOutboundAccess: false
        }
      }
      {
        name: 'snet-pls'
        properties: {
          addressPrefix: '10.0.1.0/24'
          privateLinkServiceNetworkPolicies: 'Disabled'
          defaultOutboundAccess: false
        }
      }
      {
        name: 'snet-pe'
        properties: {
          addressPrefix: '10.0.2.0/24'
          networkSecurityGroup: { id: nsgPe.id }
          defaultOutboundAccess: false
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: { addressPrefix: '10.0.3.0/26' }
      }
    ]
  }
}

resource snetVm 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing = {
  parent: vnet
  name: 'snet-vm'
}
resource snetPls 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing = {
  parent: vnet
  name: 'snet-pls'
}
resource snetPe 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing = {
  parent: vnet
  name: 'snet-pe'
}
resource snetBastion 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing = {
  parent: vnet
  name: 'AzureBastionSubnet'
}

resource dnsBlob 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: 'privatelink.blob.${environment().suffixes.storage}'
  location: 'global'
}
resource dnsVault 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: 'privatelink.vaultcore.azure.net'
  location: 'global'
}
resource dnsBlobLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: dnsBlob
  name: 'link-${prefix}'
  location: 'global'
  properties: {
    virtualNetwork: { id: vnet.id }
    registrationEnabled: false
  }
}
resource dnsVaultLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: dnsVault
  name: 'link-${prefix}'
  location: 'global'
  properties: {
    virtualNetwork: { id: vnet.id }
    registrationEnabled: false
  }
}

// ---------------------------------------------------------------- bastion
resource pipBastion 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: 'pip-${prefix}-bastion'
  location: location
  sku: { name: 'Standard' }
  properties: { publicIPAllocationMethod: 'Static' }
}

resource bastion 'Microsoft.Network/bastionHosts@2024-05-01' = {
  name: 'bas-${prefix}'
  location: location
  sku: { name: 'Standard' }
  properties: {
    enableTunneling: true
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          subnet: { id: snetBastion.id }
          publicIPAddress: { id: pipBastion.id }
        }
      }
    ]
  }
}

// ---------------------------------------------------------------- VM (Node.js) behind internal LB + Private Link Service
resource lb 'Microsoft.Network/loadBalancers@2024-05-01' = {
  name: 'ilb-${prefix}'
  location: location
  sku: { name: 'Standard' }
  properties: {
    frontendIPConfigurations: [
      {
        name: 'fe'
        properties: {
          subnet: { id: snetVm.id }
          privateIPAllocationMethod: 'Static'
          privateIPAddress: vmIlbIp
        }
      }
    ]
    backendAddressPools: [ { name: 'vm' } ]
    probes: [
      {
        name: 'node'
        properties: {
          protocol: 'Http'
          port: 8080
          requestPath: '/health'
          intervalInSeconds: 5
          numberOfProbes: 2
        }
      }
    ]
    loadBalancingRules: [
      {
        name: 'http'
        properties: {
          frontendIPConfiguration: { id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', 'ilb-${prefix}', 'fe') }
          backendAddressPool: { id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', 'ilb-${prefix}', 'vm') }
          probe: { id: resourceId('Microsoft.Network/loadBalancers/probes', 'ilb-${prefix}', 'node') }
          protocol: 'Tcp'
          frontendPort: 80
          backendPort: 8080
          enableTcpReset: true
          idleTimeoutInMinutes: 4
        }
      }
    ]
  }
}

resource pls 'Microsoft.Network/privateLinkServices@2024-05-01' = {
  name: 'pls-${prefix}'
  location: location
  properties: {
    enableProxyProtocol: false
    loadBalancerFrontendIpConfigurations: [ { id: lb.properties.frontendIPConfigurations[0].id } ]
    ipConfigurations: [
      {
        name: 'nat'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: { id: snetPls.id }
          primary: true
        }
      }
    ]
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2024-05-01' = {
  name: 'nic-${prefix}-vm'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          subnet: { id: snetVm.id }
          privateIPAllocationMethod: 'Dynamic'
          loadBalancerBackendAddressPools: [ { id: lb.properties.backendAddressPools[0].id } ]
        }
      }
    ]
  }
}

var cloudInit = replace(loadTextContent('cloud-init.yaml'), '__MEDIA_HOST__', mediaHost)

resource vm 'Microsoft.Compute/virtualMachines@2024-07-01' = {
  name: 'vm-${prefix}'
  location: location
  identity: { type: 'SystemAssigned' }
  properties: {
    hardwareProfile: { vmSize: vmSize }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'ubuntu-24_04-lts'
        sku: 'server'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: { storageAccountType: 'Standard_LRS' }
      }
    }
    osProfile: {
      computerName: 'vm-${prefix}'
      adminUsername: 'azureuser'
      customData: base64(cloudInit)
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/azureuser/.ssh/authorized_keys'
              keyData: adminSshPublicKey
            }
          ]
        }
      }
    }
    networkProfile: { networkInterfaces: [ { id: nic.id } ] }
    diagnosticsProfile: { bootDiagnostics: { enabled: true } }
  }
}

resource vmAadLogin 'Microsoft.Compute/virtualMachines/extensions@2024-07-01' = {
  parent: vm
  name: 'AADSSHLoginForLinux'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.ActiveDirectory'
    type: 'AADSSHLoginForLinux'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
  }
}

resource dcr 'Microsoft.Insights/dataCollectionRules@2023-03-11' = {
  name: 'dcr-${prefix}-vm'
  location: location
  kind: 'Linux'
  properties: {
    destinations: {
      logAnalytics: [ { name: 'law', workspaceResourceId: law.id } ]
    }
    dataSources: {
      syslog: [
        {
          name: 'syslog'
          streams: [ 'Microsoft-Syslog' ]
          facilityNames: [ 'auth', 'authpriv', 'cron', 'daemon', 'syslog' ]
          logLevels: [ 'Info', 'Notice', 'Warning', 'Error', 'Critical', 'Alert', 'Emergency' ]
        }
      ]
    }
    dataFlows: [
      {
        streams: [ 'Microsoft-Syslog' ]
        destinations: [ 'law' ]
      }
    ]
  }
}

resource vmAma 'Microsoft.Compute/virtualMachines/extensions@2024-07-01' = {
  parent: vm
  name: 'AzureMonitorLinuxAgent'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Monitor'
    type: 'AzureMonitorLinuxAgent'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
  }
}

resource dcrAssoc 'Microsoft.Insights/dataCollectionRuleAssociations@2023-03-11' = {
  scope: vm
  name: 'dcra-${prefix}'
  properties: { dataCollectionRuleId: dcr.id }
  dependsOn: [ vmAma ]
}

resource raUserVmLogin 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: vm
  name: guid(vm.id, userObjectId, roles.vmAdminLogin)
  properties: {
    principalId: userObjectId
    principalType: 'User'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roles.vmAdminLogin)
  }
}

// ---------------------------------------------------------------- identities for the upload AFD profile
resource idKv 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'id-${prefix}-afd-kv'
  location: location
}
resource idSt 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'id-${prefix}-afd-st'
  location: location
}

// ---------------------------------------------------------------- key vault (holds the mTLS CA)
resource kv 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: 'kv-${prefix}-${uniq}'
  location: location
  properties: {
    tenantId: subscription().tenantId
    sku: { family: 'A', name: 'standard' }
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    publicNetworkAccess: 'Disabled'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }
  }
}

resource kvSecretCa 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: kv
  name: 'mtls-ca'
  properties: {
    value: caCertPem
    contentType: 'application/x-pem-file'
  }
}

resource kvPe 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: 'pe-${prefix}-kv'
  location: location
  properties: {
    subnet: { id: snetPe.id }
    privateLinkServiceConnections: [
      {
        name: 'vault'
        properties: {
          privateLinkServiceId: kv.id
          groupIds: [ 'vault' ]
        }
      }
    ]
  }
}

resource kvPeDns 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = {
  parent: kvPe
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'vault'
        properties: { privateDnsZoneId: dnsVault.id }
      }
    ]
  }
}

resource raUserKv 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: kv
  name: guid(kv.id, userObjectId, roles.keyVaultAdministrator)
  properties: {
    principalId: userObjectId
    principalType: 'User'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roles.keyVaultAdministrator)
  }
}

resource raAfdKv 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: kv
  name: guid(kv.id, idKv.id, roles.keyVaultSecretsUser)
  properties: {
    principalId: idKv.properties.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roles.keyVaultSecretsUser)
  }
}

// ---------------------------------------------------------------- storage accounts
module stHello 'modules/storage.bicep' = {
  name: 'st-hello'
  params: {
    name: 'st${prefix}hello${uniq}'
    location: location
    lawId: law.id
    publicNetworkAccess: 'Disabled'
    allowAnonymousBlobAccess: true
    policyExempt: true
    containers: [ { name: '$root', publicAccess: 'Blob' } ]
    peSubnetId: snetPe.id
    blobDnsZoneId: dnsBlob.id
    privateEndpointName: 'pe-${prefix}-hello'
    dataContributorPrincipalIds: [ vm.identity.principalId ]
    userObjectId: userObjectId
  }
  dependsOn: [ dnsBlobLink ]
}

module stMedia 'modules/storage.bicep' = {
  name: 'st-media'
  params: {
    name: 'st${prefix}media${uniq}'
    location: location
    lawId: law.id
    publicNetworkAccess: 'Disabled'
    allowAnonymousBlobAccess: true
    policyExempt: true
    containers: [ { name: '$root', publicAccess: 'Blob' } ]
    peSubnetId: snetPe.id
    blobDnsZoneId: dnsBlob.id
    privateEndpointName: 'pe-${prefix}-media'
    dataContributorPrincipalIds: [ vm.identity.principalId ]
    userObjectId: userObjectId
  }
  dependsOn: [ dnsBlobLink ]
}

// upload via Private Link; the VM identity issues user delegation SAS tokens
module stUpload 'modules/storage.bicep' = {
  name: 'st-upload'
  params: {
    name: 'st${prefix}upload${uniq}'
    location: location
    lawId: law.id
    publicNetworkAccess: 'Disabled'
    containers: [ { name: 'upload' } ]
    peSubnetId: snetPe.id
    blobDnsZoneId: dnsBlob.id
    privateEndpointName: 'pe-${prefix}-upload'
    dataContributorPrincipalIds: [ vm.identity.principalId ]
    userObjectId: userObjectId
  }
  dependsOn: [ dnsBlobLink ]
}

// upload with Front Door managed identity (origin authentication is not available with Private Link)
module stUploadp 'modules/storage.bicep' = {
  name: 'st-uploadp'
  params: {
    name: 'st${prefix}uploadp${uniq}'
    location: location
    lawId: law.id
    publicNetworkAccess: 'Enabled'
    policyExempt: true
    containers: [ { name: 'upload' } ]
    dataContributorPrincipalIds: [ idSt.properties.principalId ]
    userObjectId: userObjectId
  }
}

resource seed 'Microsoft.Compute/virtualMachines/runCommands@2024-07-01' = {
  parent: vm
  name: 'seed-storage'
  location: location
  properties: {
    source: {
      script: replace(replace(loadTextContent('seed-storage.sh'), '__HELLO_HOST__', stHello.outputs.blobHost), '__MEDIA_HOST__', stMedia.outputs.blobHost)
    }
    timeoutInSeconds: 1500
    asyncExecution: false
    treatFailureAsDeploymentFailure: true
    parameters: [ { name: 'seedVersion', value: seedVersion } ]
  }
  dependsOn: [ dnsBlobLink, vmAma ]
}

resource tunnel 'Microsoft.Compute/virtualMachines/runCommands@2024-07-01' = {
  parent: vm
  name: 'vscode-tunnel'
  location: location
  properties: {
    source: {
      script: replace(loadTextContent('vscode-tunnel.sh'), '__TUNNEL_NAME__', vm.name)
    }
    timeoutInSeconds: 600
    asyncExecution: false
    treatFailureAsDeploymentFailure: true
  }
  dependsOn: [ seed ]
}

// ---------------------------------------------------------------- Front Door profiles (owned by this workflow)
resource afdPublic 'Microsoft.Cdn/profiles@2026-07-01' = {
  name: 'afd-${prefix}-public'
  location: 'global'
  sku: { name: 'Premium_AzureFrontDoor' }
  properties: { originResponseTimeoutSeconds: 60 }
}

resource afdUpload 'Microsoft.Cdn/profiles@2026-07-01' = {
  name: 'afd-${prefix}-upload'
  location: 'global'
  sku: { name: 'Premium_AzureFrontDoor' }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${idKv.id}': {}
      '${idSt.id}': {}
    }
  }
  properties: { originResponseTimeoutSeconds: 60 }
}

// mTLS trusted CA chain, shared by the upload and uploadp domains
resource afdMtlsSecret 'Microsoft.Cdn/profiles/secrets@2026-07-01' = {
  parent: afdUpload
  name: 'mtls-ca'
  properties: {
    parameters: {
      type: 'MtlsCertificateChain'
      secretSource: { id: kvSecretCa.id }
      secretVersion: last(split(kvSecretCa.properties.secretUriWithVersion, '/'))
    }
  }
  dependsOn: [ raAfdKv ]
}

// ---------------------------------------------------------------- diagnostic settings
resource diagAfdPublic 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: afdPublic
  name: 'to-law'
  properties: {
    workspaceId: law.id
    logs: [ { categoryGroup: 'allLogs', enabled: true } ]
    metrics: [ { category: 'AllMetrics', enabled: true } ]
  }
}
resource diagAfdUpload 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: afdUpload
  name: 'to-law'
  properties: {
    workspaceId: law.id
    logs: [ { categoryGroup: 'allLogs', enabled: true } ]
    metrics: [ { category: 'AllMetrics', enabled: true } ]
  }
}
resource diagKv 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: kv
  name: 'to-law'
  properties: {
    workspaceId: law.id
    logs: [ { categoryGroup: 'allLogs', enabled: true } ]
    metrics: [ { category: 'AllMetrics', enabled: true } ]
  }
}
resource diagKvPe 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: kvPe
  name: 'to-law'
  properties: {
    workspaceId: law.id
    metrics: [ { category: 'AllMetrics', enabled: true } ]
  }
}
resource diagVnet 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: vnet
  name: 'to-law'
  properties: {
    workspaceId: law.id
    logs: [ { categoryGroup: 'allLogs', enabled: true } ]
    metrics: [ { category: 'AllMetrics', enabled: true } ]
  }
}
resource diagNsgVm 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: nsgVm
  name: 'to-law'
  properties: {
    workspaceId: law.id
    logs: [ { categoryGroup: 'allLogs', enabled: true } ]
  }
}
resource diagNsgPe 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: nsgPe
  name: 'to-law'
  properties: {
    workspaceId: law.id
    logs: [ { categoryGroup: 'allLogs', enabled: true } ]
  }
}
resource diagPipNat 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: pipNat
  name: 'to-law'
  properties: {
    workspaceId: law.id
    logs: [ { categoryGroup: 'allLogs', enabled: true } ]
    metrics: [ { category: 'AllMetrics', enabled: true } ]
  }
}
resource diagPipBastion 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: pipBastion
  name: 'to-law'
  properties: {
    workspaceId: law.id
    logs: [ { categoryGroup: 'allLogs', enabled: true } ]
    metrics: [ { category: 'AllMetrics', enabled: true } ]
  }
}
resource diagNat 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: nat
  name: 'to-law'
  properties: {
    workspaceId: law.id
    metrics: [ { category: 'AllMetrics', enabled: true } ]
  }
}
resource diagBastion 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: bastion
  name: 'to-law'
  properties: {
    workspaceId: law.id
    logs: [ { categoryGroup: 'allLogs', enabled: true } ]
    metrics: [ { category: 'AllMetrics', enabled: true } ]
  }
}
resource diagLb 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: lb
  name: 'to-law'
  properties: {
    workspaceId: law.id
    metrics: [ { category: 'AllMetrics', enabled: true } ]
  }
}
resource diagNic 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: nic
  name: 'to-law'
  properties: {
    workspaceId: law.id
    metrics: [ { category: 'AllMetrics', enabled: true } ]
  }
}
resource diagVm 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: vm
  name: 'to-law'
  properties: {
    workspaceId: law.id
    metrics: [ { category: 'AllMetrics', enabled: true } ]
  }
}

output lawId string = law.id
output kvName string = kv.name
output kvSecretName string = kvSecretCa.name
output vmName string = vm.name
output plsId string = pls.id
output vmOriginHost string = vmIlbIp
output helloStorage string = stHello.outputs.name
output helloStorageHost string = stHello.outputs.blobHost
output mediaStorage string = stMedia.outputs.name
output mediaStorageHost string = stMedia.outputs.blobHost
output uploadStorage string = stUpload.outputs.name
output uploadStorageHost string = stUpload.outputs.blobHost
output uploadpStorage string = stUploadp.outputs.name
output uploadpStorageHost string = stUploadp.outputs.blobHost
output afdPublicName string = afdPublic.name
output afdUploadName string = afdUpload.name
output idKvId string = idKv.id
output idStId string = idSt.id
