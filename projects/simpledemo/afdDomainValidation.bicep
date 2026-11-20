param afdScriptGetValidationToken string
param endpointSubdomain string
param topLevelDomain string

resource dnsZone 'Microsoft.Network/dnsZones@2023-07-01-preview' existing = {
  name: topLevelDomain
}

resource endpointDNS 'Microsoft.Network/dnsZones/TXT@2018-05-01' = {
  name: '_dnsauth.${endpointSubdomain}'
  parent: dnsZone

  properties: {
    TTL: 10
    TXTRecords: [
      {
        value: [
          afdScriptGetValidationToken
        ]
      }
    ]
    targetResource: {}
  }
}
