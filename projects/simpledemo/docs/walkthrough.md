---
title: Historical notes - projects/simpledemo
description: Preserved repository guidance and scenario notes.
---

> [!WARNING]
> Historical working notes, not a verified deployment runbook. Commands can create or delete billable Azure resources. Review names, parameters and prerequisites before running them.

## Simple Frontdoor Demo

```bash
# Define some env variables
cd projects/simpledemo
prefix=cptdazfd2
location=germanywestcentral
myip=$(curl ifconfig.io) # Just in case we like to whitelist our own ip.
currentUserObjectId=$(az ad signed-in-user show --query id -o tsv)
# az group delete -n $prefix --yes
# Create base components
az deployment sub create -n ${prefix}-base -l $location --template-file main.bicep -w
# Retrieve the validation token of our custom domain
az afd custom-domain show --custom-domain-name afdCustomDomainBlob -g $prefix --profile-name afdProfile1 --query validationProperties.validationToken -o tsv
```Test
```bash
curl -v https://blob.cptdev.com/cptdazfd/test.txt
curl -v https://blob.cptdev.com/cptdazfd/test.txt?test=1
curl -v -H"X-Azure-DebugInfo: 1" https://blob.cptdev.com/cptdazfd/test.txt
```
