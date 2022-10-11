targetScope='resourceGroup'

param location string
var username = 'chpinoto'
var password = 'demo!pass123'
param prefix string
param myobjectid string
param myip string

// module nsgModule 'nsg.bicep' = {
//   name: 'nsgDeploy'
//   params: {
//     prefix: parameters.prefix
//     location: location
//   }
// }

// module vnetModule 'vnet.bicep' = {
//   name: 'vnetDeploy'
//   params: {
//     prefix: parameters.prefix
//     location: location
//   }
//   dependsOn:[
//     nsgModule
//   ]
// }

// module vmRedModule 'vm.bicep' = {
//   name: '${parameters.prefix}red'
//   params: {
//     prefix: parameters.prefix
//     location: location
//     username: parameters.username
//     password: parameters.password
//     myObjectId: myobjectid
//     postfix: 'red'
//     privateip: '10.0.0.4'
//     customdataBase64:loadFileAsBase64('vmred.yaml')
//   }
//   dependsOn:[
//     vnetModule
//   ]
// }

// module vmBlueModule 'vm.bicep' = {
//   name: '${parameters.prefix}blue'
//   params: {
//     prefix: parameters.prefix
//     location: location
//     username: parameters.username
//     password: parameters.password
//     myObjectId: myobjectid
//     postfix: 'blue'
//     privateip: '10.0.0.5'
//     customdataBase64:loadFileAsBase64('vmblue.yaml')
//   }
//   dependsOn:[
//     vnetModule
//   ]
// }

// module vmWhiteModule 'vm.bicep' = {
//   name: '${parameters.prefix}white'
//   params: {
//     prefix: parameters.prefix
//     location: location
//     username: parameters.username
//     password: parameters.password
//     myObjectId: myobjectid
//     postfix: 'white'
//     privateip: '10.0.0.6'
//     customdataBase64:loadFileAsBase64('vm.yaml')
//   }
//   dependsOn:[
//     vnetModule
//   ]
// }

module sabModule 'azbicep/bicep/sab.bicep' = {
  name: 'sabDeploy'
  params: {
    prefix: prefix
    location: location
    myObjectId: myobjectid
    postfix:''
  }
}

module dnsModule 'azbicep/bicep/dns.bicep' = {
  name: 'dnsDeploy'
  params: {
    prefix: prefix
  }
}

module afdModule 'azbicep/bicep/afd.bicep' = {
  name: 'afdDeploy'
  params: {
    prefix: prefix
    origin: '${prefix}.blob.core.windows.net'
  }
  dependsOn:[
    dnsModule
  ]
}

// module afdreModule 'afdre.bicep' = {
//   name: 'afdreDeploy'
//   params: {
//     prefix: parameters.prefix
//   }
//   dependsOn:[
//     afdModule
//   ]
// }

// module lawModule 'law.bicep' = {
//   name: 'lawDeploy'
//   params:{
//     prefix: parameters.prefix
//     location: location
//   }
//   dependsOn:[
//     afdModule
//   ]
// }
