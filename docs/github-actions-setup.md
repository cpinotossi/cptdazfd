---
title: GitHub Actions setup notes
description: Preserved repository guidance and scenario notes.
---

> [!WARNING]
> Historical working notes, not a verified deployment runbook. Commands can create or delete billable Azure resources. Review names, parameters and prerequisites before running them.

Run these commands from the repository root. The federation example is stored
in [credential.json](../.github/azure/credential.json).
Review its repository and environment subject before using it.
See the [workflows](../.github/workflows/) for the actual per-project identity
variables and GitHub environments; the old examples below are not universal defaults.

## Setup Github Actions

Setup azure credentials for github actions based on [Use GitHub Actions to connect to Azure](https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure) without secrets.

```bash
# define the prefix
appName=cptdazlz
# We already created the service principal
# az ad sp create-for-rbac -n $appName --role owner --query password -o tsv --scope /
# get service principal appid
appid=$(az ad sp list --display-name $appName --query [0].appId -o tsv)
# allow github to create tokens via inpersonation of the service principal
az ad app federated-credential create --id $appid --parameters ./.github/azure/credential.json
# verify federation setup
az ad app federated-credential list --id $appid
```

We are going to provide some secretes and variables via the github build in secrets and variables feature.
> NOTE: If it comes to secret, this is a best practices, but I am unsure if variable should go into github. It would be better to keep them all at one place. Maybe the bicep parameter files are a better place. But in this case we would need to store resource ids in clear text.
```bash
# create github secret via gh cli for repo cptdazlz
gh secret set AZURE_CLIENT_ID -b $appid -e production
tid=$(az account show --query tenantId -o tsv)
gh secret set AZURE_TENANT_ID -b $tid -e production
subid=$(az account show --query id -o tsv)
gh secret set AZURE_SUBSCRIPTION_ID -b $subid -e production
gh secret list --env production

gh variable set LOCATION_GWC -b "germanywestcentral" --env production
gh variable list --env production
```

```bash
az afd profile show -g $prefix --profile-name  afdProfile1
 --query id -o tsv

az afd endpoint show -g $prefix --profile-name afdProfile1 --endpoint-name afdEndpointBlob --query hostName -o tsv

az afd custom-domain show --custom-domain-name afdCustomDomainBlob -g $prefix --profile-name afdProfile1 --query validationProperties.validationToken -o tsv

```
