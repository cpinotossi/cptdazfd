param edgeActionName string = 'eacptmtlsupload'

resource action 'Microsoft.Cdn/edgeActions@2026-10-01' = {
  name: edgeActionName
  location: 'global'
  sku: {
    name: 'Standard'
    tier: 'Standard'
  }
  properties: {}
}

output actionId string = action.id
