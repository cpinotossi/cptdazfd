param privateIPAddress string
param name string
param location string
param subscriptionId string = subscription().subscriptionId
// param remoteSubscriptionId string
param appEnvironmentManagedResourceGroupName string
param loadBalancerName string
param subnetId string

resource loadBalancer 'Microsoft.Network/loadBalancers@2023-04-01' existing = {
  name: loadBalancerName
 scope: resourceGroup(appEnvironmentManagedResourceGroupName)
}

resource privateLinkService 'Microsoft.Network/privateLinkServices@2023-04-01' = {
  name: name
  location: location
  properties: {
    autoApproval: {
      subscriptions: [
        subscriptionId
        //remoteSubscriptionId
      ]
    }
    visibility: {
      subscriptions: [
        subscriptionId
        //remoteSubscriptionId
      ]
    }
    fqdns: []
    enableProxyProtocol: false
    loadBalancerFrontendIpConfigurations: [
      {
        id: loadBalancer.properties.frontendIPConfigurations[0].id
      }
    ]
    ipConfigurations: [
      {
        name: '${name}pl'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: privateIPAddress
          subnet: {
            id: subnetId
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
  }
}

output id string = privateLinkService.id
output name string = privateLinkService.name
