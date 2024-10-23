targetScope='resourceGroup'

//var parameters = json(loadTextContent('parameters.json'))
param location string
var username = 'chpinoto'
var password = 'demo!pass123'
param prefix string
param myobjectid string
// param myip string
var plip = '10.0.0.6'
var lbip = '10.0.0.5'
var vmip = '10.0.0.4'

module vnetmodule 'azbicep/bicep/vnethubbasic.bicep' = {
  name: 'vnetdeploy'
  params: {
    prefix: prefix
    location: location
    cidervnet: '10.0.0.0/16'
    cidersubnet: '10.0.0.0/24'
    ciderbastion: '10.0.1.0/24'
  }
}

module vmmodule 'azbicep/bicep/vm.bicep' = {
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

module lbmodule 'azbicep/bicep/slb.bicep' = {
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
        name: prefix
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: plip
          subnet: {
            id: vnetmodule.outputs.subnetid
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
  }
  dependsOn: [
    lbmodule
  ]
}
