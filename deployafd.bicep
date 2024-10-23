targetScope = 'resourceGroup'

//var parameters = json(loadTextContent('parameters.json'))
param prefix string

module afdModule 'azbicep/bicep/afdpremium.bicep' = {
  name: 'afdDeploy'
  params: {
    prefix: prefix
    originhost: 'origin.${prefix}.org'
  }
}

module domainModule 'azbicep/bicep/appDomain.bicep' = {
  name: 'dnsDeploy'
  params: {
    prefix: prefix
  }
}

