param endpointHostname string
param topLevelDomain string
param endpointSubdomain string

resource dnsZone 'Microsoft.Network/dnsZones@2018-05-01' existing = {
  name: topLevelDomain
}

resource endpointDNS 'Microsoft.Network/dnsZones/CNAME@2018-05-01' = {
  name: endpointSubdomain
  parent: dnsZone

  properties: {
    TTL: 10
    metadata: {}
    CNAMERecord: {
      cname: endpointHostname
    }
  }
}
