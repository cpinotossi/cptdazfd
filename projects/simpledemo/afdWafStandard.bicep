resource afdProfile1 'Microsoft.Cdn/profiles@2022-11-01-preview' existing = {
  name: 'afdProfile1'
}

// Maximum custom domain per profile	100
resource afdCustomDomainBlob 'Microsoft.Cdn/profiles/customdomains@2022-11-01-preview' existing = {
  parent: afdProfile1
  name: 'afdCustomDomainBlob'
}

resource afdWafSecurityPolicies 'Microsoft.Cdn/profiles/securitypolicies@2022-11-01-preview' = {
  parent: afdProfile1
  name: 'afdWafSecurityPolicies'
  properties: {
    parameters: {
      wafPolicy: {
        id: afdWafPolicies.id
      }
      associations: [
        {
          domains: [
            {
              id: afdCustomDomainBlob.id
            }
          ]
          patternsToMatch: [
            '/*'
          ]
        }
      ]
      type: 'WebApplicationFirewall'
    }
  }
}

resource afdWafPolicies 'Microsoft.Network/frontdoorwebapplicationfirewallpolicies@2022-05-01' = {
  name: 'afdWafPolicies'
  location: 'Global'
  sku: {
    name: 'Standard_AzureFrontDoor'
  }
  properties: {
    policySettings: {
      enabledState: 'Enabled'
      mode: 'Detection'
      requestBodyCheck: 'Enabled'
    }
    customRules: {
      rules: [
        {
          name: 'afdWafRule1'
          enabledState: 'Enabled'
          priority: 500
          ruleType: 'MatchRule'
          rateLimitDurationInMinutes: 1
          rateLimitThreshold: 100
          matchConditions: [
            {
              matchVariable: 'QueryString'
              operator: 'Contains'
              negateCondition: false
              matchValue: [
                'bad=1'
              ]
              transforms: []
            }
          ]
          action: 'Block'
        }
      ]
    }
    managedRules: {
      managedRuleSets: []
    }
  }
}
