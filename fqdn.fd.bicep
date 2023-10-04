// a CNAME record must already exist for name "cdn" which points to the equivalent of '${endpoint}.azureedge.net'

// if the record does not exist deployment will fail.  If the record does exist, the resource cannot be deleted

resource customDomain 'Microsoft.Cdn/profiles/endpoints/customdomains@2020-04-15' = {

  parent: profileEndpoint

  name: customDomainName

  properties: {

    hostName: customHostName //'cdn.yourcustomdomain.net'

    customHttpsProvisioningState: 'enabled'

    customHttpsParameters: {

      certificateSource: 'AzureKeyVault'

      minimumTlsVersion: 'TLS12'

      protocolType: 'ServerNameIndication'

      certificateSourceParameters: {

        '@odata.type': '#Microsoft.Azure.Cdn.Models.KeyVaultCertificateSourceParameters'

        subscriptionId: keyVaultSubscriptionId

        vaultName: keyVaultName

        resourceGroupName: keyVaultResourceGroupName

        secretName: keyVaultCertificateSecretName

        secretVersion: keyVaultCertificateVersion

        updateRule: 'NoAction'

        deleteRule: 'NoAction'

      }

    }

  }

}