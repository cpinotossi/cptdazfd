targetScope='resourceGroup'

@description('Name of the virtual machine')
param vmName string
@description('Name of the virtual network which will be used to host the virtual machine')
param vnetName string
@description('Name of the subnet which will be used to host the virtual machine')
param subnetName string
@description('Location of the virtual machine')
param location string
@description('Admin user variable')
param adminUsername string ='chpinoto'
@secure()
@description('Admin password variable')
param adminPassword string = 'demo!pass123'
param imageReference object = {
  publisher: 'Canonical'
  offer: 'UbuntuServer'
  sku: '18.04-LTS'
  version: 'latest'
}
@description('Private IP address of the virtual machine')
param privateip string
@description('cloud-init script to be executed on the virtual machine')
param customData string = ''
@description('object id of the user which will be assigned as virtual machine administrator role')
param userObjectId string

resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  name: vnetName
}

resource nic 'Microsoft.Network/networkInterfaces@2023-05-01' = {
  name: vmName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: vmName
        properties: {
          privateIPAddress:privateip
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: '${vnet.id}/subnets/${subnetName}'
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    dnsSettings: {
      dnsServers: []
    }
    enableAcceleratedNetworking: true
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2023-07-01' = {
  name: vmName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  // plan: imagePlan
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D2s_v5'
    }
    storageProfile: {
      osDisk: {
        name: vmName
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
          // id: disk.id //setting an external disk ID is not supported.
        }
        deleteOption:'Delete'

      }
      imageReference: imageReference
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
      customData: !empty(customData) ? base64(customData) : null
      linuxConfiguration: {
        disablePasswordAuthentication: false
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
          properties:{
            deleteOption: 'Delete'
          }
        }
      ]
    }
    diagnosticsProfile:{
      bootDiagnostics:{
        enabled: true
      }
    }
  }
}

// var principalId = '/subscriptions/${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/${identityName}'
// var principalId2 = '/subscriptions/4896a771-b1ab-4411-bd94-3c8467f1991e}/resourceGroups/cptdazdisk/providers/Microsoft.ManagedIdentity/userAssignedIdentities/cptdazdisk'
// var principalId = resourceId('Microsoft.ManagedIdentity/userAssignedIdentities', identityName)

// resource DenyAllNetworkForOSDiskResource 'Microsoft.Resources/deploymentScripts@2023-08-01' = {
//   name: '${vmName}DenyAllNetworkOSDisk'
//   location: location
//   kind: 'AzureCLI'
//   identity: {
//     type: 'UserAssigned'
//     userAssignedIdentities: {
//       '${identity.id}': {}
//     }
//   }
//   properties: {
//     azCliVersion: '2.53.0'
//     cleanupPreference: 'Always'
//     retentionInterval: 'PT1H'
//     scriptContent: 'az disk update -g ${resourceGroupName} -n ${vmName} --network-access-policy AllowPrivate --public-network-access Disabled --disk-access ${diskAccess.id}'
//   }
//   dependsOn: [
//     vm
//   ]
// }

// resource disk 'Microsoft.Compute/disks@2023-01-02' = {
//   name: vmName
//   location: location
//   sku: {
//     name: 'Standard_LRS'
//   }
//   properties: {
//     creationData: {
//       createOption: 'Empty'
//     }
//     diskSizeGB: 1024
//     networkAccessPolicy: 'AllowPrivate'
//     publicNetworkAccess: 'Enabled'
//     dataAccessAuthMode: 'None'
//     diskAccessId: diskAccess.id
//   }
// }

// resource vm_extension 'Microsoft.Compute/virtualMachines/extensions@2021-04-01' = {
//   name: 'CustomScript'
//   parent: vm
//   location: location
//   properties: {
//     publisher: 'Microsoft.Azure.Extensions'
//     type: 'CustomScript'
//     typeHandlerVersion: '2.1'
//     autoUpgradeMinorVersion: true
//     settings: {
//       commandToExecute: 'sudo systemctl stop firewalld && sudo systemctl disable firewalld'
//     }
//   }
// }

resource vmaadextension 'Microsoft.Compute/virtualMachines/extensions@2023-07-01' = {
  parent: vm
  name: 'AADSSHLoginForLinux'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.ActiveDirectory'
    type: 'AADSSHLoginForLinux'
    typeHandlerVersion: '1.0'
  }
}

// resource nwagentextension 'Microsoft.Compute/virtualMachines/extensions@2023-07-01' = {
//   parent: vm
//   name: 'NetworkWatcherAgentLinux'
//   location: location
//   properties: {
//     publisher: 'Microsoft.Azure.NetworkWatcher'
//     type: 'NetworkWatcherAgentLinux'
//     typeHandlerVersion: '1.4'
//   }
// }

var roleVirtualMachineAdministratorName = '1c0163c0-47e6-4577-8991-ea5c82e286e4' //Virtual Machine Administrator Login

resource raMe2VM 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id,vmName,'Virtual Machine Administrator Login')
  scope: vm
  properties: {
    principalId: userObjectId
    roleDefinitionId: tenantResourceId('Microsoft.Authorization/roleDefinitions',roleVirtualMachineAdministratorName)
  }
}


var builtInRoleNames = {
  Contributor: tenantResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
  'Data Operator for Managed Disks': tenantResourceId('Microsoft.Authorization/roleDefinitions', '959f8984-c045-4866-89c7-12bf9737be2e')
  'Disk Backup Reader': tenantResourceId('Microsoft.Authorization/roleDefinitions', '3e5e47e6-65f7-47ef-90b5-e5dd4d455f24')
  'Disk Pool Operator': tenantResourceId('Microsoft.Authorization/roleDefinitions', '60fc6e62-5479-42d4-8bf4-67625fcc2840')
  'Disk Restore Operator': tenantResourceId('Microsoft.Authorization/roleDefinitions', 'b50d9833-a0cb-478e-945f-707fcc997c13')
  'Disk Snapshot Contributor': tenantResourceId('Microsoft.Authorization/roleDefinitions', '7efff54f-a5b4-42b5-a1c5-5411624893ce')
  Owner: tenantResourceId('Microsoft.Authorization/roleDefinitions', '8e3af657-a8ff-443c-a75c-2fe8c4bcb635')
  Reader: tenantResourceId('Microsoft.Authorization/roleDefinitions', 'acdd72a7-3385-48ef-bd42-f606fba81ae7')
  'Role Based Access Control Administrator (Preview)': tenantResourceId('Microsoft.Authorization/roleDefinitions', 'f58310d9-a9f6-439a-9e8d-f62e7b41a168')
  'User Access Administrator': tenantResourceId('Microsoft.Authorization/roleDefinitions', '18d7d88d-d35e-4fb5-a5c3-7773c20a72d9')
}


resource raVM2DiskSnapshot 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id,vmName,vm.id,'Disk Snapshot Contributor')
  properties: {
    roleDefinitionId: builtInRoleNames['Disk Snapshot Contributor']
    principalId: vm.identity.principalId
    // description: roleAssignment.?description
    // principalType: roleAssignment.?principalType
    // condition: roleAssignment.?condition
    // conditionVersion: !empty(roleAssignment.?condition) ? (roleAssignment.?conditionVersion ?? '2.0') : null // Must only be set if condtion is set
    // delegatedManagedIdentityResourceId: roleAssignment.?delegatedManagedIdentityResourceId
  }
  scope: resourceGroup()
}

output vmId string = vm.id
