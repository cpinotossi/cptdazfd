---
title: Historical notes - experiments/fdpipeline
description: Preserved repository guidance and scenario notes.
---

> [!WARNING]
> Historical working notes, not a verified deployment runbook. Commands can create or delete billable Azure resources. Review names, parameters and prerequisites before running them.

## Azure Front Door deployment via Github Workflow (Actions)

### CARML
Based on https://github.com/Azure/ResourceModules

- We uploaded the needed carml module to the azure container registry carml.azurecr.io.
- We do reference the module inside the experiments/fdpipeline/main.bicep file as follow: 'br:carml.azurecr.io/bicep/modules/cdn.profile:1.0.0'
- The module is cached on our local machine via the Bicep [restore](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/bicep-cli#restore) feature.
- Access to the azure container registry is granted via the [currently logged](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/bicep-config-modules#configure-profiles-and-credentials) in user.

```bash
cd experiments/fdpipeline
location=germanywestcentral
prefix=cptdazfd
az group delete -n ${prefix}-rg --yes
az deployment sub create -n $prefix -l $location --template-file main.bicep -p serviceShort=t1 namePrefix=$prefix resourceGroupName=$prefix

# list storage accounts under our resource group
az storage account list -g ${prefix}-rg --query [].name -o tsv
# upload local file to storage account
az storage blob upload --account-name $prefix -c $prefix -f test.txt -n test.txt

# Get details about our AFD profile
afdProfileName=$(az afd profile list -g ${prefix}-rg --query [].name -o tsv)
az afd profile show --profile-name $afdProfileName -g ${prefix}-rg
az afd origin-group list --profile-name $afdProfileName -g ${prefix}-rg
# retrieve afd endpoint hostname which contains the string "blob"
afdEndpointBlob=$(az afd endpoint list -g ${prefix}-rg --profile-name $afdProfileName --query "[?contains(hostName, 'blob')].hostName" -o tsv)
echo $afdEndpointBlob
# retrieve AFD custom domains
curl -v https://$afdEndpointBlob/$prefix/test.txt # expect 200 ok
curl -v -H"X-Azure-DebugInfo: 1" https://$afdEndpointBlob/$prefix/test.txt # expect 200 ok
# retrieve azure front door logs based on request id
az monitor activity-log list --correlation-id e47149c2-701e-00d5-34dd-4e67a5000000 -o table
```
### Azure Deployment Framework
Based on https://github.com/brwilkinson/AzureDeploymentFramework.git
