targetScope = 'subscription'

var originFQDN = 'cptdazfd.blob.core.windows.net'
var topLevelDomain = 'cptdev.com'
var rgName = 'cptdazfd2'

resource rg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: rgName
  location: deployment().location
}

module afdStandard 'afdStandard.bicep' = {
  scope: resourceGroup(rgName)
  name: 'afdStandard'
  params: {
    originFQDN: originFQDN
  }
  dependsOn: [
    rg
  ]
}

module afdDomainValidation 'afdDomainValidation.bicep' = {
  scope: resourceGroup('cptdomains')
  name: 'afdDomainValidation'
  params: {
    afdScriptGetValidationToken: afdStandard.outputs.afdValidationToken
    endpointSubdomain: 'blob'
    topLevelDomain: topLevelDomain
  }
  dependsOn: [
    afdStandard
  ]
}

module afdCNAME 'afdCname.bicep' = {
  scope: resourceGroup('cptdomains')
  name: 'afdCNAME'
  params: {
    endpointHostname: afdStandard.outputs.afdEndpointHostName
    endpointSubdomain: 'blob'
    topLevelDomain: topLevelDomain
  }
  dependsOn: [
    afdStandard
  ]
}

module afdWaf 'afdWafStandard.bicep' = {
  scope: resourceGroup(rgName)
  name: 'afdWaf'
}
