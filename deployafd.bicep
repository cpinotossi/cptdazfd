targetScope = 'resourceGroup'

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

// param hostnamered string
// param hostnameblue string
param origin string
param tld string = 'org'
// param domain string

resource afd 'Microsoft.Network/frontDoors@2021-06-01' = {
  name: prefix
  location: 'Global'
  properties: {
    routingRules: [
      {
        name: prefix
        properties: {
          acceptedProtocols: [// Protocol of the left-hand side match
            'Http'
            'Https'
          ]
          frontendEndpoints: [// Domain of the left-hand side match
            {
              id: resourceId('Microsoft.Network/frontdoors/FrontendEndpoints', prefix, prefix)
            }
            // {
            //   id: resourceId('Microsoft.Network/frontdoors/FrontendEndpoints',prefix,'www')
            // }
          ]
          patternsToMatch: [// URL Path of the left-hand side match
            '/*'
          ]
          routeConfiguration: {
            forwardingProtocol: 'MatchRequest'
            // cacheConfiguration: {
            //   queryParameterStripDirective: 'StripNone'
            //   dynamicCompression: 'Enabled'
            //   cacheDuration: 'PT5M'
            // }
            backendPool: {
              id: resourceId('Microsoft.Network/frontdoors/BackendPools', prefix, prefix)
            }
            '@odata.type': '#Microsoft.Azure.FrontDoor.Models.FrontdoorForwardingConfiguration'
          }
          enabledState: 'Enabled'
          rulesEngine: {
            id: resourceId('Microsoft.Network/frontdoors/rulesengines', prefix, prefix)
          }
        }
      }
    ]
    loadBalancingSettings: [
      {
        name: prefix
        properties: {
          sampleSize: 4
          successfulSamplesRequired: 2
          additionalLatencyMilliseconds: 0
        }
      }
    ]
    healthProbeSettings: [
      {
        name: prefix
        properties: {
          path: '/'
          protocol: 'Http'
          intervalInSeconds: 30
          enabledState: 'Enabled'
          healthProbeMethod: 'HEAD'
        }
      }
    ]
    backendPools: [
      {
        name: prefix
        properties: {
          backends: [
            {
              address: origin
              //address: 'cptdafdred.eastus.cloudapp.azure.com'
              httpPort: 80
              httpsPort: 443
              priority: 1
              weight: 50
              enabledState: 'Enabled'
            }
          ]
          loadBalancingSettings: {
            id: resourceId('Microsoft.Network/frontdoors/LoadBalancingSettings', prefix, prefix)
          }
          healthProbeSettings: {
            id: resourceId('Microsoft.Network/frontdoors/HealthProbeSettings', prefix, prefix)
          }
        }
      }
      // {
      //   name: '${prefix}backpoolred'
      //   properties: {
      //     backends: [
      //       {
      //         address: hostnamered
      //         //address: 'cptdafdred.eastus.cloudapp.azure.com'
      //         httpPort: 80
      //         httpsPort: 443
      //         priority: 1
      //         weight: 50
      //         enabledState: 'Enabled'
      //       }
      //     ]
      //     loadBalancingSettings: {
      //       id: resourceId('Microsoft.Network/frontdoors/LoadBalancingSettings',prefix,'${prefix}lbs')
      //     }
      //     healthProbeSettings: {
      //       id: resourceId('Microsoft.Network/frontdoors/HealthProbeSettings',prefix,'${prefix}hprobe')
      //     }
      //   }
      // }
      // {
      //   name: '${prefix}backpoolblue'
      //   properties: {
      //     backends: [
      //       {
      //         address: hostnameblue
      //         //address: 'cptdafdblue.eastus.cloudapp.azure.com'
      //         httpPort: 80
      //         httpsPort: 443
      //         priority: 1
      //         weight: 50
      //         enabledState: 'Enabled'
      //       }
      //     ]
      //     loadBalancingSettings: {
      //       id: resourceId('Microsoft.Network/frontdoors/LoadBalancingSettings',prefix,'${prefix}lbs')
      //     }
      //     healthProbeSettings: {
      //       id: resourceId('Microsoft.Network/frontdoors/HealthProbeSettings',prefix,'${prefix}hprobe')
      //     }
      //   }
      // }
    ]
    frontendEndpoints: [
      {
        name: prefix
        properties: {
          hostName: '${prefix}.azurefd.net'
          sessionAffinityEnabledState: 'Enabled'
          sessionAffinityTtlSeconds: 0
          // webApplicationFirewallPolicyLink: {
          //   id: fwp.id
          // }
        }
      }
      {
        name: 'www'
        properties: {
          hostName: 'www.${prefix}.${tld}'
          sessionAffinityEnabledState: 'Enabled'
          sessionAffinityTtlSeconds: 0
        }
      }
    ]
    backendPoolsSettings: {
      enforceCertificateNameCheck: 'Disabled'
      sendRecvTimeoutSeconds: 30
    }
    friendlyName: prefix
  }
  tags: {
    env: prefix
  }
}

resource afdprofile 'Microsoft.Cdn/profiles@2022-05-01-preview' = {
  name: prefix
  location: 'Global'
  sku: {
    name: 'Premium_AzureFrontDoor'
  }
  kind: 'frontdoor'
  properties: {
    originResponseTimeoutSeconds: 60
    extendedProperties: {}
  }
}

// resource profiles_cptdazfd_name_profiles_cptdazfd_name 'Microsoft.Cdn/profiles/afdendpoints@2022-05-01-preview' = {
//   parent: profiles_cptdazfd_name_resource
//   name: '${profiles_cptdazfd_name}'
//   location: 'Global'
//   properties: {
//     enabledState: 'Enabled'
//   }
// }

resource afdorigin 'Microsoft.Cdn/profiles/origingroups@2022-05-01-preview' = {
  parent: afdprofile
  name: prefix
  properties: {
    loadBalancingSettings: {
      sampleSize: 4
      successfulSamplesRequired: 3
      additionalLatencyInMilliseconds: 50
    }
    healthProbeSettings: {
      probePath: '/'
      probeRequestType: 'HEAD'
      probeProtocol: 'Http'
      probeIntervalInSeconds: 100
    }
    sessionAffinityState: 'Disabled'
  }
}

resource afdprofilesecret 'Microsoft.Cdn/profiles/secrets@2022-05-01-preview' = {
  parent: afdprofile
  name: '20e684e8-08cb-437a-aff5-53d4098e97fb-www-${prefix}-org'
  properties: {
    parameters: {
      type: 'ManagedCertificate'
    }
  }
}

// resource afdrules 'Microsoft.Network/frontdoors/rulesengines@2020-05-01' = {
//   name: '${prefix}/${prefix}rulesengine'
//   properties: {
//     rules: [
//       {
//         name: '${prefix}rule1'
//         priority: 0
//         action: {
//           routeConfigurationOverride: {
//             forwardingProtocol: 'MatchRequest'
//             backendPool: {
//               id: resourceId('Microsoft.Network/frontdoors/BackendPools',prefix,'${prefix}backpoolred')
//             }
//             '@odata.type': '#Microsoft.Azure.FrontDoor.Models.FrontdoorForwardingConfiguration'
//           }
//           requestHeaderActions: []
//           responseHeaderActions: []
//         }
//         matchConditions: [
//           {
//             rulesEngineMatchValue: [
//               'usa'
//             ]
//             negateCondition: false
//             rulesEngineMatchVariable: 'RequestPath'
//             rulesEngineOperator: 'Contains'
//             transforms: [
//               'Lowercase'
//             ]
//           }
//         ]
//         matchProcessingBehavior: 'Continue'
//       }
//     ]
//   }
// }

// resource fwp 'Microsoft.Network/frontdoorwebapplicationfirewallpolicies@2020-11-01' = {
//   name: prefix
//   location: 'Global'
//   sku: {
//     name: 'Classic_AzureFrontDoor'
//   }
//   properties: {
//     policySettings: {
//       enabledState: 'Enabled'
//       mode: 'Detection'
//       redirectUrl: 'https://paint2help.org/autsch'
//       customBlockResponseStatusCode: 200
//       customBlockResponseBody: 'QXV0c2No'
//       requestBodyCheck: 'Disabled'
//     }
//     customRules: {
//       rules: [
//         {
//           name: 'detectcpt'
//           enabledState: 'Enabled'
//           priority: 1
//           ruleType: 'MatchRule'
//           rateLimitDurationInMinutes: 1
//           rateLimitThreshold: 100
//           matchConditions: [
//             {
//               matchVariable: 'RequestHeader'
//               selector: 'x-attack'
//               operator: 'BeginsWith'
//               negateCondition: false
//               matchValue: [
//                 'turn-off'
//               ]
//               transforms: [
//                 'Lowercase'
//               ]
//             }
//           ]
//           action: 'Block'
//         }
//       ]
//     }
//     managedRules: {
//       managedRuleSets: [
//         {
//           ruleSetType: 'DefaultRuleSet'
//           ruleSetVersion: '1.0'
//           ruleGroupOverrides: []
//           exclusions: []
//         }
//         {
//           ruleSetType: 'Microsoft_BotManagerRuleSet'
//           ruleSetVersion: '1.0'
//           ruleGroupOverrides: []
//           exclusions: []
//         }
//       ]
//     }
//   }
// }
