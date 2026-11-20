param profileName string
param endpointName string
param hostName string
param edgeActionName string = 'eacptmtlsupload'

resource profile 'Microsoft.Cdn/profiles@2026-07-01' existing = {
  name: profileName
}

resource endpoint 'Microsoft.Cdn/profiles/afdEndpoints@2026-07-01' existing = {
  parent: profile
  name: endpointName
}

resource domain 'Microsoft.Cdn/profiles/customDomains@2026-07-01' existing = {
  parent: profile
  name: replace(hostName, '.', '-')
}

resource originGroup 'Microsoft.Cdn/profiles/originGroups@2026-07-01' existing = {
  parent: profile
  name: 'og-uploadp-storage'
}

resource action 'Microsoft.Cdn/edgeActions@2026-10-01' existing = {
  name: edgeActionName
}

// Newer container API versions are rejected by the provider's deployment preflight.
resource ruleSet 'Microsoft.Cdn/profiles/ruleSets@2024-09-01' = {
  parent: profile
  name: 'uploadedge'
}

resource rule 'Microsoft.Cdn/profiles/ruleSets/rules@2026-10-01' = {
  parent: ruleSet
  name: 'uploadpolicy'
  properties: {
    order: 1
    conditions: []
    actions: [
      {
        name: 'EdgeAction'
        parameters: {
          typeName: 'DeliveryRuleEdgeActionParameters'
          edgeActionReference: { id: action.id }
          invocationPoint: 'ClientRequest'
        }
      }
    ]
    matchProcessingBehavior: 'Stop'
  }
}

resource route 'Microsoft.Cdn/profiles/afdEndpoints/routes@2026-07-01' = {
  parent: endpoint
  name: 'route-upload-edge'
  properties: {
    customDomains: [ { id: domain.id } ]
    originGroup: { id: originGroup.id }
    ruleSets: [ { id: ruleSet.id } ]
    supportedProtocols: [ 'Https' ]
    patternsToMatch: [ '/upload/edge/*' ]
    forwardingProtocol: 'HttpsOnly'
    linkToDefaultDomain: 'Disabled'
    httpsRedirect: 'Disabled'
    enabledState: 'Enabled'
  }
  dependsOn: [ rule ]
}
