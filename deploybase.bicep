targetScope = 'resourceGroup'

//var parameters = json(loadTextContent('parameters.json'))
param location string
param username string = 'chpinoto'
var password = 'demo!pass123'
param prefix string
param myobjectid string
param myip string
var vmip = '10.0.0.4'
var cidervnet = '10.0.0.0/16'
var cidersubnet = '10.0.0.0/24'
var ciderbastion = '10.0.1.0/24'

resource vnet 'Microsoft.Network/virtualNetworks@2021-03-01' = {
  name: prefix
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        cidervnet
      ]
    }
    subnets: [
      {
        name: prefix
        properties: {
          addressPrefix: cidersubnet
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Disabled'
          networkSecurityGroup:{
            id: nsg.id
          }
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: ciderbastion
          delegations: []
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
  }
}

resource pubipbastion 'Microsoft.Network/publicIPAddresses@2021-03-01' = {
  name: '${prefix}bastion'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource bastion 'Microsoft.Network/bastionHosts@2021-03-01' = {
  name: prefix
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    dnsName: '${prefix}.bastion.azure.com'
    enableTunneling: true
    ipConfigurations: [
      {
        name: '${prefix}bastion'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: pubipbastion.id
          }
          subnet: {
            id: '${vnet.id}/subnets/AzureBastionSubnet'
          }
        }
      }
    ]
  }
}


resource pubipvm 'Microsoft.Network/publicIPAddresses@2021-03-01' = {
  name: '${prefix}vm'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource niclin 'Microsoft.Network/networkInterfaces@2023-05-01' = {
  name: '${prefix}lin'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: '${prefix}lin'
        properties: {
          subnet: {
            id: '${vnet.id}/subnets/${prefix}'
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
          publicIPAddress: {
            id: pubipvm.id
          }
          privateIPAddress: vmip
        }
      }
    ]
  }
}

resource vmlin 'Microsoft.Compute/virtualMachines@2023-07-01' = {
  name: '${prefix}lin'
  location: location
  identity: {
    type:'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D2ds_v5'
    }
    storageProfile: {
      osDisk: {
        name: '${prefix}lin'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '18.04-LTS'
        version: 'latest'
      }
    }
    osProfile: {
      computerName: '${prefix}lin'
      adminUsername: username
      adminPassword: password
      // customData: loadFileAsBase64('vmlin.yaml')
      linuxConfiguration: {
        disablePasswordAuthentication:false
        provisionVMAgent:true
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: niclin.id
        }
      ]
    }
  }
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
  name: prefix
  location: location
  properties:{
    securityRules:[
      {
        name:prefix
        properties:{
          access: 'Allow'
          direction: 'Inbound'
          priority: 100
          protocol: 'Tcp'
          sourceAddressPrefix: 'AzureFrontDoor.Backend'
          sourcePortRange: '*'
          destinationPortRange: '9000'
          destinationAddressPrefix: '10.0.0.4'
        }
      }
    ]
  }
}

// resource afd 'Microsoft.Network/frontDoors@2021-06-01' = {
//   name: prefix
//   location: 'Global'
//   properties: {
//     routingRules: [
//       {
//         name: prefix
//         properties: {
//           acceptedProtocols: [// Protocol of the left-hand side match
//             'Http'
//             'Https'
//           ]
//           frontendEndpoints: [// Domain of the left-hand side match
//             {
//               id: resourceId('Microsoft.Network/frontdoors/FrontendEndpoints', prefix, prefix)
//             }
//             // {
//             //   id: resourceId('Microsoft.Network/frontdoors/FrontendEndpoints',prefix,'www')
//             // }
//           ]
//           patternsToMatch: [// URL Path of the left-hand side match
//             '/index.html'
//             '/azure.html'
//           ]
//           routeConfiguration: {
//             forwardingProtocol: 'MatchRequest'
//             // cacheConfiguration: {
//             //   queryParameterStripDirective: 'StripNone'
//             //   dynamicCompression: 'Enabled'
//             //   cacheDuration: 'PT5M'
//             // }
//             backendPool: {
//               id: resourceId('Microsoft.Network/frontdoors/BackendPools', prefix, prefix)
//             }
//             '@odata.type': '#Microsoft.Azure.FrontDoor.Models.FrontdoorForwardingConfiguration'
//           }
//           enabledState: 'Enabled'
//           rulesEngine: {
//             id: resourceId('Microsoft.Network/frontdoors/rulesengines', prefix, prefix)
//           }
//         }
//       }
//     ]
//     loadBalancingSettings: [
//       {
//         name: prefix
//         properties: {
//           sampleSize: 4
//           successfulSamplesRequired: 2
//           additionalLatencyMilliseconds: 0
//         }
//       }
//     ]
//     healthProbeSettings: [
//       {
//         name: prefix
//         properties: {
//           path: '/azure.html'
//           protocol: 'Http'
//           intervalInSeconds: 30
//           enabledState: 'Enabled'
//           healthProbeMethod: 'HEAD'
//         }
//       }
//     ]
//     backendPools: [
//       {
//         name: prefix
//         properties: {
//           backends: [
//             {
//               address: pubipvm.properties.ipAddress
//               //address: 'cptdafdred.eastus.cloudapp.azure.com'
//               httpPort: 9000
//               // httpsPort: 443
//               priority: 1
//               weight: 50
//               enabledState: 'Enabled'
//             }
//           ]
//           loadBalancingSettings: {
//             id: resourceId('Microsoft.Network/frontdoors/LoadBalancingSettings', prefix, prefix)
//           }
//           healthProbeSettings: {
//             id: resourceId('Microsoft.Network/frontdoors/HealthProbeSettings', prefix, prefix)
//           }
//         }
//       }
//     ]
//     frontendEndpoints: [
//       {
//         name: prefix
//         properties: {
//           hostName: '${prefix}.azurefd.net'
//           sessionAffinityEnabledState: 'Enabled'
//           sessionAffinityTtlSeconds: 0
//         }
//       }
//       {
//         name: 'www'
//         properties: {
//           hostName: 'www.${prefix}.org'
//           sessionAffinityEnabledState: 'Enabled'
//           sessionAffinityTtlSeconds: 0
//         }
//       }
//     ]
//     backendPoolsSettings: {
//       enforceCertificateNameCheck: 'Disabled'
//       sendRecvTimeoutSeconds: 30
//     }
//     friendlyName: prefix
//   }
//   tags: {
//     env: prefix
//   }
//   dependsOn: [
//     vmlin
//   ]
// }

// // resource afdprofile 'Microsoft.Cdn/profiles@2022-05-01-preview' = {
// //   name: prefix
// //   location: 'Global'
// //   sku: {
// //     name: 'Standard_AzureFrontDoor'
// //   }
// //   properties: {
// //     originResponseTimeoutSeconds: 60
// //   }
// // }

// module dnsModule 'azbicep/bicep/dns.bicep' = {
//   name: 'dnsDeploy'
//   params: {
//     prefix: prefix
//   }
// }
