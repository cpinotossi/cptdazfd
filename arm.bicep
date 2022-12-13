param profiles_cptdazfd_name string = 'cptdazfd'
param bastionHosts_cptdazfd_name string = 'cptdazfd'
param dnszones_cptdazfd_org_name string = 'cptdazfd.org'
param sshPublicKeys_cptdazfd_name string = 'cptdazfd'
param loadBalancers_cptdazfd_name string = 'cptdazfd'
param virtualMachines_cptdazfd_name string = 'cptdazfd'
param virtualNetworks_cptdazfd_name string = 'cptdazfd'
param networkInterfaces_cptdazfd_name string = 'cptdazfd'
param privateLinkServices_cptdazfd_name string = 'cptdazfd'
param publicIPAddresses_cptdazfdbastion_name string = 'cptdazfdbastion'
param networkInterfaces_cptdazfd_nic_e736039f_c93e_4e26_bbd8_4f01b1104a12_name string = 'cptdazfd.nic.e736039f-c93e-4e26-bbd8-4f01b1104a12'
param dnszones_cptdev_com_externalid string = '/subscriptions/f474dec9-5bab-47a3-b4d3-e641dac87ddb/resourceGroups/ga-rg/providers/Microsoft.Network/dnszones/cptdev.com'
param dnsZones_cptdazfd_externalid string = '/subscriptions/f474dec9-5bab-47a3-b4d3-e641dac87ddb/resourceGroups/cptdazfd/providers/Microsoft.Network/dnsZones/cptdazfd'

resource profiles_cptdazfd_name_resource 'Microsoft.Cdn/profiles@2022-05-01-preview' = {
  name: profiles_cptdazfd_name
  location: 'Global'
  sku: {
    name: 'Premium_AzureFrontDoor'
  }
  kind: 'frontdoor'
  properties: {
    originResponseTimeoutSeconds: 60
    extendedProperties: {
    }
  }
}

resource sshPublicKeys_cptdazfd_name_resource 'Microsoft.Compute/sshPublicKeys@2022-08-01' = {
  name: sshPublicKeys_cptdazfd_name
  location: 'eastus'
  properties: {
    publicKey: 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDDtChxP+94nGXZ1M+C2iY18OCXIGlKPmP+E2n8sbk7uPs3bn7hqTL7cjFQNk43aluvYTpGUMyd4ZqTzb0SVNr3qy3zv0g6bummYR1nhUUEqSJOD0rNQ52HTu4b28siqemlEU4lvJqNmhX2P27+hSpGbid885EyY4FZtxc+5xvY5VvXidqFN+BLampvbxQ2fUQIVGyjkF0ulIzSCWUXic7CNSEoiXTtyvJUu3W95bsyaQsFBbS3wxykRQWbn03mahLPuAbYKrYXY52eFWni4Nxlqat+v9C/3WMPSEyYrQ8/Ki6DXg2RNAtH/4iwI4Ao2nC/+ezt9GsF4HtdbP3DPDVfqizN/kYpFekbXTj8UHl9d/YEsG7CangaocIcbNUShYHKTTOiasB91s0gur20/ozqqrA2m7GAnQ28Ofz3CITykOQL8+aLznFMXgIMq9IBmy+d/qj5JXz5KF+PmXegUDoPBPPNDiXSnP8Cd46fQJNfcZp8tGYFNfy4TCvACfWLcAA/nlO29YioACMYMXIKjWJYMd6jK7OdvjCcjtGo42/v8efAb0wO9UfLJysJmZFZa59SFb9J/JcHFnAbKOvwApmVhHPKQXyF0estassItpHFm5mle35MYHJEpi5AhlxTT1krO14dhzZBDlxLw881g23usJok1DLxM5Yy12dvmDBNyQ== azure chpinoto vm user 2022-01-28\n'
  }
}

resource dnszones_cptdazfd_org_name_resource 'Microsoft.Network/dnszones@2018-05-01' = {
  name: dnszones_cptdazfd_org_name
  location: 'global'
  tags: {
    env: 'cptdazfd'
  }
  properties: {
    zoneType: 'Public'
  }
}

resource publicIPAddresses_cptdazfdbastion_name_resource 'Microsoft.Network/publicIPAddresses@2022-05-01' = {
  name: publicIPAddresses_cptdazfdbastion_name
  location: 'eastus'
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    ipAddress: '13.72.73.237'
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
    ipTags: []
  }
}

resource profiles_cptdazfd_name_profiles_cptdazfd_name 'Microsoft.Cdn/profiles/afdendpoints@2022-05-01-preview' = {
  parent: profiles_cptdazfd_name_resource
  name: '${profiles_cptdazfd_name}'
  location: 'Global'
  properties: {
    enabledState: 'Enabled'
  }
}

resource profiles_cptdazfd_name_www_profiles_cptdazfd_name_org 'Microsoft.Cdn/profiles/customdomains@2022-05-01-preview' = {
  parent: profiles_cptdazfd_name_resource
  name: 'www-${profiles_cptdazfd_name}-org'
  properties: {
    hostName: 'www.cptdazfd.org'
    tlsSettings: {
      certificateType: 'ManagedCertificate'
      minimumTlsVersion: 'TLS12'
      secret: {
      }
    }
    azureDnsZone: {
      id: dnsZones_cptdazfd_externalid
    }
  }
}

resource Microsoft_Cdn_profiles_origingroups_profiles_cptdazfd_name_profiles_cptdazfd_name 'Microsoft.Cdn/profiles/origingroups@2022-05-01-preview' = {
  parent: profiles_cptdazfd_name_resource
  name: '${profiles_cptdazfd_name}'
  properties: {
    loadBalancingSettings: {
      sampleSize: 4
      successfulSamplesRequired: 3
      additionalLatencyInMilliseconds: 50
    }
    healthProbeSettings: {
      probePath: '/'
      probeRequestType: 'HEAD'
      probeProtocol: 'Http'
      probeIntervalInSeconds: 100
    }
    sessionAffinityState: 'Disabled'
  }
}

resource profiles_cptdazfd_name_6713f825_eeee_4c28_abe6_9689642cfa79_profiles_cptdazfd_name_cptdev_com 'Microsoft.Cdn/profiles/secrets@2022-05-01-preview' = {
  parent: profiles_cptdazfd_name_resource
  name: '6713f825-eeee-4c28-abe6-9689642cfa79-${profiles_cptdazfd_name}-cptdev-com'
  properties: {
    parameters: {
      type: 'ManagedCertificate'
    }
  }
}

resource virtualMachines_cptdazfd_name_resource 'Microsoft.Compute/virtualMachines@2022-08-01' = {
  name: virtualMachines_cptdazfd_name
  location: 'eastus'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D2s_v3'
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '18.04-LTS'
        version: 'latest'
      }
      osDisk: {
        osType: 'Linux'
        name: virtualMachines_cptdazfd_name
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
          id: resourceId('Microsoft.Compute/disks', virtualMachines_cptdazfd_name)
        }
        deleteOption: 'Delete'
        diskSizeGB: 30
      }
      dataDisks: []
    }
    osProfile: {
      computerName: virtualMachines_cptdazfd_name
      adminUsername: 'chpinoto'
      linuxConfiguration: {
        disablePasswordAuthentication: false
        ssh: {
          publicKeys: [
            {
              path: '/home/chpinoto/.ssh/authorized_keys'
              keyData: 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDDtChxP+94nGXZ1M+C2iY18OCXIGlKPmP+E2n8sbk7uPs3bn7hqTL7cjFQNk43aluvYTpGUMyd4ZqTzb0SVNr3qy3zv0g6bummYR1nhUUEqSJOD0rNQ52HTu4b28siqemlEU4lvJqNmhX2P27+hSpGbid885EyY4FZtxc+5xvY5VvXidqFN+BLampvbxQ2fUQIVGyjkF0ulIzSCWUXic7CNSEoiXTtyvJUu3W95bsyaQsFBbS3wxykRQWbn03mahLPuAbYKrYXY52eFWni4Nxlqat+v9C/3WMPSEyYrQ8/Ki6DXg2RNAtH/4iwI4Ao2nC/+ezt9GsF4HtdbP3DPDVfqizN/kYpFekbXTj8UHl9d/YEsG7CangaocIcbNUShYHKTTOiasB91s0gur20/ozqqrA2m7GAnQ28Ofz3CITykOQL8+aLznFMXgIMq9IBmy+d/qj5JXz5KF+PmXegUDoPBPPNDiXSnP8Cd46fQJNfcZp8tGYFNfy4TCvACfWLcAA/nlO29YioACMYMXIKjWJYMd6jK7OdvjCcjtGo42/v8efAb0wO9UfLJysJmZFZa59SFb9J/JcHFnAbKOvwApmVhHPKQXyF0estassItpHFm5mle35MYHJEpi5AhlxTT1krO14dhzZBDlxLw881g23usJok1DLxM5Yy12dvmDBNyQ== azure chpinoto vm user 2022-01-28\n'
            }
          ]
        }
        provisionVMAgent: true
        patchSettings: {
          patchMode: 'ImageDefault'
          assessmentMode: 'ImageDefault'
        }
        enableVMAgentPlatformUpdates: false
      }
      secrets: []
      allowExtensionOperations: true
      requireGuestProvisionSignal: true
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterfaces_cptdazfd_name_resource.id
          properties: {
            deleteOption: 'Delete'
          }
        }
      ]
    }
  }
}

resource virtualMachines_cptdazfd_name_NetworkWatcherAgentLinux 'Microsoft.Compute/virtualMachines/extensions@2022-08-01' = {
  parent: virtualMachines_cptdazfd_name_resource
  name: 'NetworkWatcherAgentLinux'
  location: 'eastus'
  properties: {
    autoUpgradeMinorVersion: false
    publisher: 'Microsoft.Azure.NetworkWatcher'
    type: 'NetworkWatcherAgentLinux'
    typeHandlerVersion: '1.4'
  }
}

resource dnszones_cptdazfd_org_name_afdverify_www 'Microsoft.Network/dnszones/CNAME@2018-05-01' = {
  parent: dnszones_cptdazfd_org_name_resource
  name: 'afdverify.www'
  properties: {
    TTL: 10
    CNAMERecord: {
      cname: 'afdverify.cptdazfd.azurefd.net'
    }
    targetResource: {
    }
  }
}

resource dnszones_cptdazfd_org_name_www 'Microsoft.Network/dnszones/CNAME@2018-05-01' = {
  parent: dnszones_cptdazfd_org_name_resource
  name: 'www'
  properties: {
    TTL: 10
    CNAMERecord: {
      cname: 'cptdazfd.azurefd.net'
    }
    targetResource: {
    }
  }
}

resource Microsoft_Network_dnszones_NS_dnszones_cptdazfd_org_name 'Microsoft.Network/dnszones/NS@2018-05-01' = {
  parent: dnszones_cptdazfd_org_name_resource
  name: '@'
  properties: {
    TTL: 172800
    NSRecords: [
      {
        nsdname: 'ns1-04.azure-dns.com.'
      }
      {
        nsdname: 'ns2-04.azure-dns.net.'
      }
      {
        nsdname: 'ns3-04.azure-dns.org.'
      }
      {
        nsdname: 'ns4-04.azure-dns.info.'
      }
    ]
    targetResource: {
    }
  }
}

resource Microsoft_Network_dnszones_SOA_dnszones_cptdazfd_org_name 'Microsoft.Network/dnszones/SOA@2018-05-01' = {
  parent: dnszones_cptdazfd_org_name_resource
  name: '@'
  properties: {
    TTL: 3600
    SOARecord: {
      email: 'azuredns-hostmaster.microsoft.com'
      expireTime: 2419200
      host: 'ns1-04.azure-dns.com.'
      minimumTTL: 300
      refreshTime: 3600
      retryTime: 300
      serialNumber: 1
    }
    targetResource: {
    }
  }
}

resource loadBalancers_cptdazfd_name_loadBalancers_cptdazfd_name 'Microsoft.Network/loadBalancers/backendAddressPools@2022-05-01' = {
  name: '${loadBalancers_cptdazfd_name}/${loadBalancers_cptdazfd_name}'
  properties: {
    loadBalancerBackendAddresses: [
      {
        name: 'cptdazfd_cptdazfdcptdazfd'
        properties: {
        }
      }
    ]
  }
  dependsOn: [
    loadBalancers_cptdazfd_name_resource
  ]
}

resource privateLinkServices_cptdazfd_name_b11c1798_2e19_4065_8e84_03e9307d760a_59c79705_598f_40de_a84f_8822189edcf2 'Microsoft.Network/privateLinkServices/privateEndpointConnections@2022-05-01' = {
  name: '${privateLinkServices_cptdazfd_name}/b11c1798-2e19-4065-8e84-03e9307d760a.59c79705-598f-40de-a84f-8822189edcf2'
  properties: {
    privateLinkServiceConnectionState: {
      status: 'Approved'
      description: 'cptdazfd'
      actionsRequired: 'None'
    }
  }
  dependsOn: [
    privateLinkServices_cptdazfd_name_resource
  ]
}

resource virtualNetworks_cptdazfd_name_AzureBastionSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-05-01' = {
  name: '${virtualNetworks_cptdazfd_name}/AzureBastionSubnet'
  properties: {
    addressPrefix: '10.0.1.0/24'
    delegations: []
    privateEndpointNetworkPolicies: 'Enabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
  dependsOn: [
    virtualNetworks_cptdazfd_name_resource
  ]
}

resource virtualNetworks_cptdazfd_name_virtualNetworks_cptdazfd_name 'Microsoft.Network/virtualNetworks/subnets@2022-05-01' = {
  name: '${virtualNetworks_cptdazfd_name}/${virtualNetworks_cptdazfd_name}'
  properties: {
    addressPrefix: '10.0.0.0/24'
    serviceEndpoints: []
    delegations: []
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Disabled'
  }
  dependsOn: [
    virtualNetworks_cptdazfd_name_resource
  ]
}

resource profiles_cptdazfd_name_profiles_cptdazfd_name_cptdev_com 'Microsoft.Cdn/profiles/customdomains@2022-05-01-preview' = {
  parent: profiles_cptdazfd_name_resource
  name: '${profiles_cptdazfd_name}-cptdev-com'
  properties: {
    hostName: 'cptdazfd.cptdev.com'
    tlsSettings: {
      certificateType: 'ManagedCertificate'
      minimumTlsVersion: 'TLS12'
      secret: {
        id: profiles_cptdazfd_name_6713f825_eeee_4c28_abe6_9689642cfa79_profiles_cptdazfd_name_cptdev_com.id
      }
    }
    azureDnsZone: {
      id: dnszones_cptdev_com_externalid
    }
  }
}

resource bastionHosts_cptdazfd_name_resource 'Microsoft.Network/bastionHosts@2022-05-01' = {
  name: bastionHosts_cptdazfd_name
  location: 'eastus'
  sku: {
    name: 'Standard'
  }
  properties: {
    dnsName: 'bst-d6d82db8-54d4-449f-9aad-d5f158d9bb67.bastion.azure.com'
    scaleUnits: 2
    enableTunneling: true
    ipConfigurations: [
      {
        name: '${bastionHosts_cptdazfd_name}bastion'
        id: '${bastionHosts_cptdazfd_name_resource.id}/bastionHostIpConfigurations/${bastionHosts_cptdazfd_name}bastion'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddresses_cptdazfdbastion_name_resource.id
          }
          subnet: {
            id: virtualNetworks_cptdazfd_name_AzureBastionSubnet.id
          }
        }
      }
    ]
  }
}

resource loadBalancers_cptdazfd_name_resource 'Microsoft.Network/loadBalancers@2022-05-01' = {
  name: loadBalancers_cptdazfd_name
  location: 'eastus'
  tags: {
    env: 'cptdazfd'
  }
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: loadBalancers_cptdazfd_name
        id: '${loadBalancers_cptdazfd_name_resource.id}/frontendIPConfigurations/${loadBalancers_cptdazfd_name}'
        properties: {
          privateIPAddress: '10.0.0.5'
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: virtualNetworks_cptdazfd_name_virtualNetworks_cptdazfd_name.id
          }
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    backendAddressPools: [
      {
        name: loadBalancers_cptdazfd_name
        id: loadBalancers_cptdazfd_name_loadBalancers_cptdazfd_name.id
        properties: {
          loadBalancerBackendAddresses: [
            {
              name: '${loadBalancers_cptdazfd_name}_${loadBalancers_cptdazfd_name}${loadBalancers_cptdazfd_name}'
              properties: {
              }
            }
          ]
        }
      }
    ]
    loadBalancingRules: [
      {
        name: loadBalancers_cptdazfd_name
        id: '${loadBalancers_cptdazfd_name_resource.id}/loadBalancingRules/${loadBalancers_cptdazfd_name}'
        properties: {
          frontendIPConfiguration: {
            id: '${loadBalancers_cptdazfd_name_resource.id}/frontendIPConfigurations/${loadBalancers_cptdazfd_name}'
          }
          frontendPort: 80
          backendPort: 9000
          enableFloatingIP: false
          idleTimeoutInMinutes: 4
          protocol: 'Tcp'
          enableTcpReset: false
          loadDistribution: 'Default'
          disableOutboundSnat: true
          backendAddressPool: {
            id: loadBalancers_cptdazfd_name_loadBalancers_cptdazfd_name.id
          }
          backendAddressPools: [
            {
              id: loadBalancers_cptdazfd_name_loadBalancers_cptdazfd_name.id
            }
          ]
          probe: {
            id: '${loadBalancers_cptdazfd_name_resource.id}/probes/${loadBalancers_cptdazfd_name}'
          }
        }
      }
    ]
    probes: [
      {
        name: loadBalancers_cptdazfd_name
        id: '${loadBalancers_cptdazfd_name_resource.id}/probes/${loadBalancers_cptdazfd_name}'
        properties: {
          protocol: 'Http'
          port: 9000
          requestPath: '/index.html'
          intervalInSeconds: 5
          numberOfProbes: 1
          probeThreshold: 1
        }
      }
    ]
    inboundNatRules: []
    outboundRules: []
    inboundNatPools: []
  }
}

resource networkInterfaces_cptdazfd_name_resource 'Microsoft.Network/networkInterfaces@2022-05-01' = {
  name: networkInterfaces_cptdazfd_name
  location: 'eastus'
  kind: 'Regular'
  properties: {
    ipConfigurations: [
      {
        name: networkInterfaces_cptdazfd_name
        id: '${networkInterfaces_cptdazfd_name_resource.id}/ipConfigurations/${networkInterfaces_cptdazfd_name}'
        etag: 'W/"4880574b-8111-4d73-8a2d-594124f99f17"'
        type: 'Microsoft.Network/networkInterfaces/ipConfigurations'
        properties: {
          provisioningState: 'Succeeded'
          privateIPAddress: '10.0.0.4'
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: virtualNetworks_cptdazfd_name_virtualNetworks_cptdazfd_name.id
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
          loadBalancerBackendAddressPools: [
            {
              id: loadBalancers_cptdazfd_name_loadBalancers_cptdazfd_name.id
            }
          ]
        }
      }
    ]
    dnsSettings: {
      dnsServers: []
    }
    enableAcceleratedNetworking: false
    enableIPForwarding: false
    disableTcpStateTracking: false
    nicType: 'Standard'
  }
}

resource networkInterfaces_cptdazfd_nic_e736039f_c93e_4e26_bbd8_4f01b1104a12_name_resource 'Microsoft.Network/networkInterfaces@2022-05-01' = {
  name: networkInterfaces_cptdazfd_nic_e736039f_c93e_4e26_bbd8_4f01b1104a12_name
  location: 'eastus'
  kind: 'Regular'
  properties: {
    ipConfigurations: [
      {
        name: 'cptdazfd'
        id: '${networkInterfaces_cptdazfd_nic_e736039f_c93e_4e26_bbd8_4f01b1104a12_name_resource.id}/ipConfigurations/cptdazfd'
        etag: 'W/"2b58acab-71b6-4c36-a75c-44431e3676f9"'
        type: 'Microsoft.Network/networkInterfaces/ipConfigurations'
        properties: {
          provisioningState: 'Succeeded'
          privateIPAddress: '10.0.0.6'
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: virtualNetworks_cptdazfd_name_virtualNetworks_cptdazfd_name.id
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    dnsSettings: {
      dnsServers: []
    }
    enableAcceleratedNetworking: false
    enableIPForwarding: false
    disableTcpStateTracking: false
    privateLinkService: {
      id: privateLinkServices_cptdazfd_name_resource.id
    }
    nicType: 'Standard'
  }
}

resource privateLinkServices_cptdazfd_name_resource 'Microsoft.Network/privateLinkServices@2022-05-01' = {
  name: privateLinkServices_cptdazfd_name
  location: 'eastus'
  properties: {
    fqdns: []
    visibility: {
      subscriptions: []
    }
    autoApproval: {
      subscriptions: []
    }
    enableProxyProtocol: false
    loadBalancerFrontendIpConfigurations: [
      {
        id: '${loadBalancers_cptdazfd_name_resource.id}/frontendIPConfigurations/${privateLinkServices_cptdazfd_name}'
      }
    ]
    ipConfigurations: [
      {
        name: privateLinkServices_cptdazfd_name
        id: '${privateLinkServices_cptdazfd_name_resource.id}/ipConfigurations/${privateLinkServices_cptdazfd_name}'
        properties: {
          privateIPAddress: '10.0.0.6'
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: virtualNetworks_cptdazfd_name_virtualNetworks_cptdazfd_name.id
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
  }
}

resource virtualNetworks_cptdazfd_name_resource 'Microsoft.Network/virtualNetworks@2022-05-01' = {
  name: virtualNetworks_cptdazfd_name
  location: 'eastus'
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: virtualNetworks_cptdazfd_name
        id: virtualNetworks_cptdazfd_name_virtualNetworks_cptdazfd_name.id
        properties: {
          addressPrefix: '10.0.0.0/24'
          serviceEndpoints: []
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Disabled'
        }
        type: 'Microsoft.Network/virtualNetworks/subnets'
      }
      {
        name: 'AzureBastionSubnet'
        id: virtualNetworks_cptdazfd_name_AzureBastionSubnet.id
        properties: {
          addressPrefix: '10.0.1.0/24'
          delegations: []
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
        type: 'Microsoft.Network/virtualNetworks/subnets'
      }
    ]
    virtualNetworkPeerings: []
    enableDdosProtection: false
  }
}

resource profiles_cptdazfd_name_profiles_cptdazfd_name_profiles_cptdazfd_name 'Microsoft.Cdn/profiles/origingroups/origins@2022-05-01-preview' = {
  parent: Microsoft_Cdn_profiles_origingroups_profiles_cptdazfd_name_profiles_cptdazfd_name
  name: profiles_cptdazfd_name
  properties: {
    hostName: '10.0.0.6'
    httpPort: 80
    httpsPort: 443
    originHostHeader: 'www.cptdazfd.org'
    priority: 1
    weight: 1000
    enabledState: 'Enabled'
    sharedPrivateLinkResource: {
      privateLink: {
        id: privateLinkServices_cptdazfd_name_resource.id
      }
      privateLinkLocation: 'eastus'
      requestMessage: 'cptdazfd'
    }
    enforceCertificateNameCheck: true
  }
  dependsOn: [

    profiles_cptdazfd_name_resource

  ]
}

resource Microsoft_Cdn_profiles_afdendpoints_routes_profiles_cptdazfd_name_profiles_cptdazfd_name_profiles_cptdazfd_name 'Microsoft.Cdn/profiles/afdendpoints/routes@2022-05-01-preview' = {
  parent: profiles_cptdazfd_name_profiles_cptdazfd_name
  name: profiles_cptdazfd_name
  properties: {
    cacheConfiguration: {
      compressionSettings: {
        isCompressionEnabled: false
        contentTypesToCompress: []
      }
      queryStringCachingBehavior: 'IgnoreQueryString'
    }
    customDomains: [
      {
        id: profiles_cptdazfd_name_www_profiles_cptdazfd_name_org.id
      }
      {
        id: profiles_cptdazfd_name_profiles_cptdazfd_name_cptdev_com.id
      }
    ]
    originGroup: {
      id: Microsoft_Cdn_profiles_origingroups_profiles_cptdazfd_name_profiles_cptdazfd_name.id
    }
    ruleSets: []
    supportedProtocols: [
      'Http'
    ]
    patternsToMatch: [
      '/*'
    ]
    forwardingProtocol: 'HttpOnly'
    linkToDefaultDomain: 'Enabled'
    httpsRedirect: 'Disabled'
    enabledState: 'Enabled'
  }
  dependsOn: [

    profiles_cptdazfd_name_resource

  ]
}