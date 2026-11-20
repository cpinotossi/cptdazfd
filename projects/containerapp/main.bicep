param adminUsername string ='chpinoto'
@secure()
@description('Admin password variable')
param adminPassword string
param currentUserObjectId string
param location string = 'australiaeast'
param prefix string = 'contoso'
param workloadProfile bool = false
param imageName string = 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
param mTlsEnabled bool = false

var vnetName = prefix
var frontDoorName = prefix
var wafPolicyName = prefix
var workspaceName = prefix
var appName = prefix
var plsName = prefix
var appEnvironmentName = prefix
var originName = prefix
var originGroupName = prefix
var afdEndpointName = prefix
var loadBalancerName = 'kubernetes-internal'
var worloadProfileLoadBalancerName = 'capp-svc-lb'
var defaultDomainArr = split(appEnvironment.properties.defaultDomain, '.')
var appEnvironmentResourceGroupName = 'MC_${defaultDomainArr[0]}-rg_${defaultDomainArr[0]}_${defaultDomainArr[1]}'

var delegation = [
  {
    name: 'app-environment-delegation'
    properties: {
      serviceName: 'Microsoft.App/environments'
    }
  }
]

resource vnet 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.1.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'infrastructure-subnet'
        properties: {
          addressPrefix: '10.1.0.0/23'
          delegations: workloadProfile ? delegation : null
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'privatelinkservice-subnet'
        properties: {
          addressPrefix: '10.1.3.0/24'
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Disabled'
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: '10.1.4.0/24'
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Disabled'
        }
      }
      {
        name: prefix
        properties: {
          addressPrefix: '10.1.5.0/24'
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Disabled'
        }
      }
    ]
    enableDdosProtection: false
  }
}

resource bastionIp 'Microsoft.Network/publicIPAddresses@2022-05-01' = {
  name: '${prefix}bastion'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource bastion 'Microsoft.Network/bastionHosts@2023-05-01' = {
  name: prefix
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    enableTunneling: true
    enableIpConnect: true
    ipConfigurations: [
      {
        name: '${prefix}bastion'
        properties: {
          publicIPAddress: {
            id: bastionIp.id
          }
          subnet: {
            id: '${vnet.id}/subnets/AzureBastionSubnet'
          }
        }
      }
    ]
  }
}

module vm 'modules/vm.bicep' = {
  name: prefix
  params: {
    location: location
    vmName: prefix
    vnetName: vnet.name
    subnetName: prefix
    userObjectId: currentUserObjectId
    privateip: '10.1.5.4'
    adminPassword: adminPassword
    adminUsername: adminUsername
  }
  dependsOn:[
    vnet
  ]
}

resource wks 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: workspaceName
  location: location
  properties: {
    sku: {
      name: 'pergb2018'
    }
    retentionInDays: 30
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    workspaceCapping: {
      dailyQuotaGb: -1
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

resource appEnvironment 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: appEnvironmentName
  location: location
  properties: {
    // workloadProfiles: workloadProfile ? profiles : null
    peerAuthentication: {
      mtls: {
        enabled: mTlsEnabled
      }
    }
    vnetConfiguration: {
      internal: true
      // infrastructureSubnetId: vnet.properties.subnets[0].id
      infrastructureSubnetId: '${vnet.id}/subnets/infrastructure-subnet'
    }
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: wks.properties.customerId
        sharedKey: wks.listKeys().primarySharedKey
      }
    }
    zoneRedundant: false
  }
}

resource containerApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: appName
  location: location
  identity: {
    type: 'None'
  }
  properties: {
    environmentId: appEnvironment.id
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: {
        external: true
        targetPort: 80
        exposedPort: 0
        transport: 'Auto'
        traffic: [
          {
            weight: 100
            latestRevision: true
          }
        ]
        allowInsecure: false
        ipSecurityRestrictions: [
          {
            action: 'Allow'
            ipAddressRange: '10.1.3.4'
            name: appName
          }
        ]
      }
    }
    template: {
      containers: [
        {
          image: imageName
          name: appName
          resources: {
            cpu: '0.25'
            memory: '0.5Gi'
          }
        }
      ]
      scale: {
        maxReplicas: 10
      }
    }
  }
}

module privateLinkService './modules/pls.bicep' = {
  name: 'modules-private-link-service'
  params: {
    appEnvironmentManagedResourceGroupName: workloadProfile ? appEnvironment.properties.infrastructureResourceGroup : appEnvironmentResourceGroupName
    loadBalancerName: workloadProfile ? worloadProfileLoadBalancerName : loadBalancerName
    location: location
    name: plsName
    subnetId: '${vnet.id}/subnets/privatelinkservice-subnet'
    subscriptionId: subscription().subscriptionId
    privateIPAddress: '10.1.3.4'
  }
}

resource frontDoor 'Microsoft.Cdn/profiles@2023-05-01' = {
  name: frontDoorName
  location: 'Global'
  sku: {
    name: 'Premium_AzureFrontDoor'
  }
  properties: {
    originResponseTimeoutSeconds: 30
  }
}

resource afdOriginGroup 'Microsoft.Cdn/profiles/originGroups@2023-05-01' = {
  parent: frontDoor
  name: originGroupName
  properties: {
    loadBalancingSettings: {
      sampleSize: 4
      successfulSamplesRequired: 3
      additionalLatencyInMilliseconds: 50
    }
    healthProbeSettings: {
      probePath: '/'
      probeRequestType: 'GET'
      probeProtocol: 'Https'
      probeIntervalInSeconds: 60
    }
    sessionAffinityState: 'Disabled'
  }
}

resource afdEndpoint 'Microsoft.Cdn/profiles/afdEndpoints@2023-05-01' = {
  parent: frontDoor
  name: afdEndpointName
  location: 'Global'
  properties: {
    autoGeneratedDomainNameLabelScope: 'TenantReuse'
    enabledState: 'Enabled'
  }
}

resource afdRoute 'Microsoft.Cdn/profiles/afdEndpoints/routes@2023-05-01' = {
  parent: afdEndpoint
  name: 'route'
  properties: {
    customDomains: []
    originGroup: {
      id: afdOriginGroup.id
    }
    originPath: '/'
    ruleSets: []
    supportedProtocols: [
      'Http'
      'Https'
    ]
    patternsToMatch: [
      '/*'
    ]
    forwardingProtocol: 'MatchRequest'
    linkToDefaultDomain: 'Enabled'
    httpsRedirect: 'Enabled'
    enabledState: 'Enabled'
  }
  dependsOn: [
    afdOrigin
  ]
}

resource afdOrigin 'Microsoft.Cdn/profiles/originGroups/origins@2023-05-01' = {
  parent: afdOriginGroup
  name: originName
  properties: {
    hostName: containerApp.properties.configuration.ingress.fqdn
    httpPort: 80
    httpsPort: 443
    originHostHeader: containerApp.properties.configuration.ingress.fqdn
    priority: 1
    weight: 1000
    enabledState: 'Enabled'
    sharedPrivateLinkResource: {
      privateLink: {
        id: privateLinkService.outputs.id
      }
      privateLinkLocation: location
      status: 'Approved'
      requestMessage: 'Please approve this request to allow Front Door to access the container app'
    }
    enforceCertificateNameCheck: true
  }
  dependsOn:[
    privateLinkService
  ]
}

resource wafPolicy 'Microsoft.Network/FrontDoorWebApplicationFirewallPolicies@2022-05-01' = {
  name: wafPolicyName
  location: 'Global'
  sku: {
    name: 'Premium_AzureFrontDoor'
  }
  properties: {
    policySettings: {
      enabledState: 'Enabled'
      mode: 'Prevention'
      requestBodyCheck: 'Enabled'
    }
    managedRules: {
      managedRuleSets: [
        {
          ruleSetType: 'Microsoft_DefaultRuleSet'
          ruleSetVersion: '1.1'
          ruleGroupOverrides: []
          exclusions: []
        }
        {
          ruleSetType: 'Microsoft_BotManagerRuleSet'
          ruleSetVersion: '1.0'
          ruleGroupOverrides: []
          exclusions: []
        }
      ]
    }
  }
}

resource afdSecurityPolicy 'Microsoft.Cdn/profiles/securityPolicies@2023-05-01' = {
  parent: frontDoor
  name: '${prefix}-default-security-policy'
  properties: {
    parameters: {
      wafPolicy: {
        id: wafPolicy.id
      }
      associations: [
        {
          domains: [
            {
              id: afdEndpoint.id
            }
          ]
          patternsToMatch: [
            '/*'
          ]
        }
      ]
      type: 'WebApplicationFirewall'
    }
  }
}

output afdFqdn string = afdEndpoint.properties.hostName
output privateLinkServiceName string = privateLinkService.outputs.name
output containerAppFqdn string = containerApp.properties.configuration.ingress.fqdn
output containerAppEnvironmentPrivateIpAddress string = appEnvironment.properties.staticIp
