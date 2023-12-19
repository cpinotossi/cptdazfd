targetScope='resourceGroup'

//var parameters = json(loadTextContent('parameters.json'))
param location string
var username = 'chpinoto'
var password = 'demo!pass123'
param prefix string
param myobjectid string
param myip string
var plip = '10.0.0.6'
var lbip = '10.0.0.5'
var vmip = '10.0.0.4'


module afdModule 'azbicep/bicep/afdpremium.bicep' = {
  name: 'afdDeploy'
  params: {
    prefix: prefix
    originhost: '${prefix}.cptdev.com'
  }
}

