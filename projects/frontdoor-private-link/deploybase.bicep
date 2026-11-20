targetScope = 'resourceGroup'

//var parameters = json(loadTextContent('parameters.json'))
param location string
param username string
@secure()
param password string
param prefix string
param myobjectid string
// param myip string
var plip = '10.0.0.6'
var lbip = '10.0.0.5'
var vmip = '10.0.0.4'

module vnetmodule '../../external/azbicep/bicep/vnethubbasic.bicep' = {
  name: 'vnetdeploy'
  params: {
    prefix: prefix
    location: location
    cidervnet: '10.0.0.0/16'
    cidersubnet: '10.0.0.0/24'
    ciderbastion: '10.0.1.0/24'
  }
}

module vmmodule '../../external/azbicep/bicep/vm.bicep' = {
  name: 'vmdeploy'
  params: {
    prefix: prefix
    vnetname: vnetmodule.outputs.vnetname
    location: location
    username: username
    password: password
    myObjectId: myobjectid
    privateip: vmip
    imageRef: 'linux'
    loadBalancerBackendId: lbmodule.outputs.beid
  }
  dependsOn:[
    lbmodule
  ]
}

module lbmodule '../../external/azbicep/bicep/slb.bicep' = {
  name: 'lbdeploy'
  params:{
    location:location
    prefix: prefix
    feip: lbip
    beport: 9000
    feport: 80
  }
  dependsOn:[
    vnetmodule
  ]
}

resource plsvc 'Microsoft.Network/privateLinkServices@2024-01-01' = {
  name: prefix
  location: location
  sku: {
    name: 'Standard'
  }
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
        id: lbmodule.outputs.feid
      }
    ]
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
  dependsOn: [
    lbmodule
  ]
}
