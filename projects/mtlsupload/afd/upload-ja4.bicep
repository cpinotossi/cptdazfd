param profileName string
param hostName string
param wafPolicyName string
param securityPolicyName string

type FingerprintRule = {
  @minLength(36)
  @maxLength(36)
  fingerprint: string
  action: 'Log' | 'Block'
}

@description('Omit for discovery; pass an observed fingerprint with Log or Block for the targeted rule.')
param fingerprintRule FingerprintRule?

resource profile 'Microsoft.Cdn/profiles@2026-07-01' existing = {
  name: profileName
}

resource domain 'Microsoft.Cdn/profiles/customDomains@2026-07-01' existing = {
  parent: profile
  name: replace(hostName, '.', '-')
}

var uploadConditions = [
  {
    matchVariable: 'RequestMethod'
    operator: 'Equal'
    matchValue: [ 'PUT' ]
  }
  {
    matchVariable: 'RequestUri'
    operator: 'RegEx'
    // RequestUri can include the scheme and authority; never match a path inside a query string.
    matchValue: [ '^(https?://[^/?#]+)?/upload/ja4/' ]
    transforms: [ 'UrlDecode' ]
  }
]

resource waf 'Microsoft.Network/frontdoorWebApplicationFirewallPolicies@2026-04-01' = {
  name: wafPolicyName
  location: 'global'
  sku: {
    name: 'Premium_AzureFrontDoor'
  }
  properties: {
    policySettings: {
      enabledState: 'Enabled'
      mode: 'Prevention'
      requestBodyCheck: 'Disabled'
      customBlockResponseStatusCode: 403
      customBlockResponseBody: base64('{"error":"JA4_DEMO_BLOCKED"}')
    }
    managedRules: {
      managedRuleSets: []
    }
    customRules: {
      rules: concat(fingerprintRule == null ? [] : [
        {
          name: 'SelectedJa4Fingerprint'
          priority: 10
          enabledState: 'Enabled'
          ruleType: 'MatchRule'
          action: fingerprintRule!.action
          matchConditions: concat(uploadConditions, [
            {
              matchVariable: 'JA4'
              operator: 'ClientFingerprint'
              matchValue: [ fingerprintRule!.fingerprint ]
            }
          ])
        }
      ], [
        {
          name: 'ObserveJa4Uploads'
          priority: 100
          enabledState: 'Enabled'
          ruleType: 'MatchRule'
          action: 'Log'
          matchConditions: uploadConditions
        }
      ])
    }
  }
}

resource securityPolicy 'Microsoft.Cdn/profiles/securityPolicies@2026-07-01' = {
  parent: profile
  name: securityPolicyName
  properties: {
    parameters: {
      type: 'WebApplicationFirewall'
      wafPolicy: { id: waf.id }
      associations: [
        {
          domains: [ { id: domain.id } ]
          patternsToMatch: [ '/*' ]
        }
      ]
    }
  }
}

output wafPolicyId string = waf.id
output securityPolicyId string = securityPolicy.id
